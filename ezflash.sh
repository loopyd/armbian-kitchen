#!/bin/bash

shopt -s dotglob nullglob
CSCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${CSCRIPT_DIR}/lib.sh"

CARGS=($@)
ACTION=""

RKDEVELOPTOOL_INSTALL_DIR=${RKDEVELOPTOOL_INSTALL_DIR:-/opt/rkdeveloptool}
IMAGE_PATH=${IMAGE_PATH:-}
LOADER_PATH=${LOADER_PATH:-}
FLASH_OFFSET=${FLASH_OFFSET:-0}
ERASE_EMMC_SIZE=${ERASE_EMMC_SIZE:-0}
WAIT_DEVICE=${WAIT_DEVICE:-false}
WAIT_DEVICE_TIMEOUT=${WAIT_DEVICE_TIMEOUT:-30}
AUTO_REBOOT=${AUTO_REBOOT:-false}

# block non-root execution
if [ "$(id -u)" -ne 0 ]; then
	error "This script must be run as root"
	exit 1
fi

# check if the device is connected
function is_device_connected() {
	if ! ${RKDEVELOPTOOL_INSTALL_DIR}/rkdeveloptool ld 2>&1 | grep -q "Maskrom"; then
		return 1
	fi
	return 0
}

# test if the device is connected
function test_device() {
	printf "Testing device..."
	if ${RKDEVELOPTOOL_INSTALL_DIR}/rkdeveloptool td 2>&1 | grep -q "failed"; then
		printf "${C_BOLD}${C_RED}Failed${C_RESET}\n"
		return 1
	fi
	printf "${C_BOLD}${C_GREEN}OK${C_RESET}\n"
	return 0
}

function check_chip() {
	printf "Checking chip info..."
	if ${RKDEVELOPTOOL_INSTALL_DIR}/rkdeveloptool rci 2>&1 | grep -q "failed"; then
		printf "${C_BOLD}${C_RED}Failed${C_RESET}\n"
		return 1
	fi
	printf "${C_BOLD}${C_GREEN}OK${C_RESET}\n"
	return 0
}

function read_flash_info() {
	printf "Reading flash info..."
	if ${RKDEVELOPTOOL_INSTALL_DIR}/rkdeveloptool rfi | grep -q "failed"; then
		printf "${C_BOLD}${C_RED}Failed${C_RESET}\n"
		return 1
	fi
	printf "${C_BOLD}${C_GREEN}OK${C_RESET}\n"
	return 0
}

# Sideload loader bin
function sideload_loader() {
	local loader=$1
	if [ ! -f "$loader" ]; then
		error "Loader file not found"
		return 1
	fi
	printf "Sideload bootloader..."
	eval "${RKDEVELOPTOOL_INSTALL_DIR}/rkdeveloptool db ${loader} >/dev/null 2>&1 " || {
		printf "${C_BOLD}${C_RED}Failed${C_RESET}\n"
		return 1
	}
	printf "${C_BOLD}${C_GREEN}OK${C_RESET}\n"
	test_device  || return $?
	check_chip || return $?
	read_flash_info || return $?
	return 0
}

# Clear the emmc with zero image
function erase_emmc() {
	local size
	size=$1
	tmpfile=$(mktemp -f /tmp/zero.img.XXXXXX)
	printf "Creating zero image..."
	eval "dd if=/dev/zero of=${tmpfile} bs=1M count=${size} >/dev/null 2>&1 " || {
		printf "${C_BOLD}${C_RED}Failed${C_RESET}\n"
		return 1
	}
	printf "OK\n"
	printf "Erasing emmc..."
	eval "${RKDEVELOPTOOL_INSTALL_DIR}/rkdeveloptool wl 0 ${tmpfile} >/dev/null 2>&1" || {
		printf "${C_BOLD}${C_RED}Failed${C_RESET}\n"
		return 1
	}
	rm -f $tmpfile || {
		printf "${C_BOLD}${C_RED}Failed${C_RESET}\n"
		return 1
	}
	printf "${C_BOLD}${C_GREEN}OK${C_RESET}\n"
	return 0
}

# Reboot the device
function reboot_device() {
	printf "Rebooting device..."
	eval "${RKDEVELOPTOOL_INSTALL_DIR}/rkdeveloptool rd >/dev/null 2>&1" || {
		printf "${C_BOLD}${C_RED}Failed${C_RESET}\n"
		return 1
	}
	printf "${C_BOLD}${C_GREEN}OK${C_RESET}\n"
	return 0
}

# Flash the image
function flash_image() {
	local image=$1
	if [ ! -f "$image" ]; then
		error "Image file not found"
		return 1
	fi
	shift 1
	local offset
	offset=$1
	if [ -z "$offset" ]; then
		warning "Offset not provided, using 0"
		offset=0
	fi
	eval "${RKDEVELOPTOOL_INSTALL_DIR}/rkdeveloptool wl 0 $image" || {
		error "Failed to write image"
		return 1
	}
	success "Image flashed successfully"
	return 0
}

# Wait for device to connect
function wait_connect() {
	local timeout
	timeout=$1
	if [ -z "$timeout" ]; then
		warning "Timeout not provided, using 30 seconds"
		timeout=30
	fi
	while [ $timeout -gt 0 ]; do
		printf "Waiting for device to connect (%d seconds) \r" $timeout
		if is_device_connected; then
			printf "\n\rDevice connected!\n"
			return 0
		fi
		sleep 1
		timeout=$((timeout - 1))
	done
	return 1
}

# Print program usage information
function usage() {
	case $1 in
	flash)
		echo "EzRkFlash - Rockchip Flashing Tool (v1.0)"
		echo "by: loopyd <loopyd@github.com> (GPL3.0 permassive - 2024)"
		echo ""
		echo "Usage: $0 flash [OPTIONS]"
		echo ""
		echo "Flash Options:"
		echo "  -i, --image <path>    Path to the image file"
		echo "  -l, --loader <path>   Path to the loader file"
		echo "  -o, --offset <offset> Offset to write the image"
		echo ""
		echo "Device Options:"
		echo "  -w, --wait-device      Wait for device to connect"
		echo "  -t, --timeout <time>   Timeout to wait for device"
		echo "  -r, --reboot           Reboot device after flashing"
		echo ""
		echo "Core Options:"
		echo "  -h, --help             Display this help message"
		echo "  -d, --install-dir DIR  Install directory for rkdeveloptool"
		;;
	erase)
		echo "Usage: $0 erase [OPTIONS]"
		echo ""
		echo "Erase Options:"
		echo "  -e, --erase-emmc-size <size>   Size in MB to erase"
		echo ""
		echo "Device Options:"
		echo "  -w, --wait-device      Wait for device to connect"
		echo "  -t, --timeout <time>   Timeout to wait for device"
		echo "  -r, --reboot           Reboot device after erasing"
		echo ""
		echo "Core Options:"
		echo "  -h, --help             Display this help message"
		echo "  -d, --install-dir DIR  Install directory for rkdeveloptool"
		;;
	*)
		echo "Usage: $0 <action> [OPTIONS]" 1>&2
		echo ""
		echo "Tool Actions:"
		echo "  flash   Flash the image"
		echo "  erase   Erase the emmc"
		echo ""
		;;
	esac
	exit 1
}

# Parse command line arguments
function parse_args() {
	local ARGS=($*)
	if [ ${#ARGS} -lt 2 ]; then
		error "No arguments provided"
		usage
	fi
	ACTION=${ARGS[0]}
	if [ -z "$ACTION" ]; then
		error "No action provided"
		usage
	fi
	ARGS=(${ARGS[@]:1})
	case "$ACTION" in
	flash)
		while [ ${#ARGS[@]} -gt 0 ]; do
			case ${ARGS[0]} in
			-h | --help)
				usage $ACTION
				;;
			-i | --image)
				IMAGE_PATH=${ARGS[1]}
				ARGS=(${ARGS[@]:2})
				;;
			-l | --loader)
				LOADER_PATH=${ARGS[1]}
				ARGS=(${ARGS[@]:2})
				;;
			-o | --offset)
				FLASH_OFFSET=${ARGS[1]}
				ARGS=(${ARGS[@]:2})
				;;
			-w | --wait-device)
				WAIT_DEVICE=true
				ARGS=(${ARGS[@]:1})
				;;
			-t | --timeout)
				WAIT_DEVICE_TIMEOUT=${ARGS[1]}
				ARGS=(${ARGS[@]:2})
				;;
			-r | --reboot)
				AUTO_REBOOT=true
				ARGS=(${ARGS[@]:1})
				;;
			-d | --install-dir)
				RKDEVELOPTOOL_INSTALL_DIR=${ARGS[1]}
				ARGS=(${ARGS[@]:2})
				;;
			*)
				error "Unknown argument: ${ARGS[0]}"
				usage $ACTION
				;;
			esac
		done
		;;
	erase)
		while [ ${#ARGS[@]} -gt 0 ]; do
			case ${ARGS[0]} in
			-h | --help)
				usage $ACTION
				;;
			-e | --erase-emmc-size)
				ERASE_EMMC_SIZE=${ARGS[1]}
				ARGS=(${ARGS[@]:2})
				;;
			-w | --wait-device)
				WAIT_DEVICE=true
				ARGS=(${ARGS[@]:1})
				;;
			-t | --timeout)
				WAIT_DEVICE_TIMEOUT=${ARGS[1]}
				ARGS=(${ARGS[@]:2})
				;;
			-r | --reboot)
				AUTO_REBOOT=true
				ARGS=(${ARGS[@]:1})
				;;
			-d | --install-dir)
				RKDEVELOPTOOL_INSTALL_DIR=${ARGS[1]}
				ARGS=(${ARGS[@]:2})
				;;
			*)
				error "Unknown argument: ${ARGS[0]}"
				usage $ACTION
				;;
			esac
		done
		;;
	*)
		error "Unknown action: $ACTION"
		usage
		;;
	esac
}

### Main
parse_args ${CARGS[*]}
RKDEVELOPTOOL_INSTALL_DIR=$(cd $RKDEVELOPTOOL_INSTALL_DIR && pwd)
RKDEVELOPTOOL_INSTALL_DIR=${RKDEVELOPTOOL_INSTALL_DIR%/}

case "$ACTION" in
flash)
	if [ -z "$IMAGE_PATH" ]; then
		error "Image path not provided"
		usage $ACTION
	fi
	if [ -z "$LOADER_PATH" ]; then
		error "Loader path not provided"
		usage $ACTION
	fi
	if ! shell_cmd_exists ${RKDEVELOPTOOL_INSTALL_DIR}/rkdeveloptool; then
		error "rkdeveloptool not found on PATH, please compile/install it."
		exit 1
	fi
	info "Flash Parameters:"
	info "  Sideload loader: $LOADER_PATH"
	info "  Image: $IMAGE_PATH"
	info "  Byte Offset: $FLASH_OFFSET"
	if [ "$WAIT_DEVICE" = true ]; then
		wait_connect $WAIT_DEVICE_TIMEOUT || {
			error "Maskrom Device not connected"
			exit 1
		}
	else
		if ! is_device_connected; then
			error "Maskrom Device not connected"
			exit 1
		fi
	fi
	sideload_loader $LOADER_PATH || exit $?
	flash_image $IMAGE_PATH $FLASH_OFFSET || exit $?
	if [ "$AUTO_REBOOT" = true ]; then
		reboot_device || exit $?
	fi
	;;
erase)
	if [ $ERASE_EMMC_SIZE -eq 0 ]; then
		error "Erase size not provided"
		usage $ACTION
	fi
	if ! shell_cmd_exists ${RKDEVELOPTOOL_INSTALL_DIR}/rkdeveloptool; then
		error "rkdeveloptool not found at: ${RKDEVELOPTOOL_INSTALL_DIR}"
		exit 1
	fi
	info "Erase Parameters:"
	info "  Erase size: $ERASE_EMMC_SIZE"
	if [ "$WAIT_DEVICE" = true ]; then
		wait_connect $WAIT_DEVICE_TIMEOUT || {
			error "Maskrom Device did not connect within the specified timeframe."
			exit 1
		}
	else
		if ! is_device_connected; then
			error "Maskrom Device not connected"
			exit 1
		fi
	fi
	erase_emmc $ERASE_EMMC_SIZE || exit $?
	if [ "$AUTO_REBOOT" = true ]; then
		reboot_device || exit $?
	fi
	;;
*)
	usage
	;;
esac
