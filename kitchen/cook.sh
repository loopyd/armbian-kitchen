#!/bin/bash

shopt -s dotglob nullglob
CSCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${CSCRIPT_DIR}/lib.sh"

CARGS=($@)
ACTION=""

# Display program usage information
function usage() {
	case $ACTION in
	armbian)
		echo "Usage: $0 armbian [OPTIONS]"
		echo "Options:"
		echo "  -h, --help              Display this help message"
		echo "  -d, --install-dir DIR   Armbian source code directory (default: /opt/armbian)"
		echo "  -c, --config-file FILE  Armbian configuration file"
		echo "  -u, --userpatches-dir DIR  Armbian userpatches directory"
		;;
	rkdeveloptool)
		echo "Usage: $0 rkdeveloptool [OPTIONS]"
		echo "Options:"
		echo "  -h, --help              Display this help message"
		echo "  -d, --install-dir DIR   rkdeveloptool source code directory (default: /opt/rkdeveloptool)"
		;;
	*)
		echo "Usage: $0 [ACTION] [OPTIONS]"
		echo "Actions:"
		echo "  armbian                 Compile Armbian"
		echo "  rkdeveloptool           Install Rockchip rkdeveloptool"
		echo "Options:"
		echo "  -h, --help              Display this help message"
		;;
	esac
	exit 1
}

# Parse arguments
function parse_args() {
	local ARGS
	ARGS=($@)
	ACTION=${ARGS[0]}
	if [[ -z $ACTION ]]; then
		error "No action specified"
		usage
	fi
	ARGS=(${ARGS[@]:1})
	case "$ACTION" in
	armbian)
		while [ ${#ARGS[@]} -gt 0 ]; do
			case ${ARGS[0]} in
			-h|--help)
				usage
				;;
			-d|--install-dir)
				ARMBIAN_INSTALL_DIR=${ARGS[1]}
				ARGS=(${ARGS[@]:2})
				;;
			-c|--config-file)
				ARMBIAN_CONFIG_FILE=${ARGS[1]}
				ARGS=(${ARGS[@]:2})
				;;
			-u|--userpatches-dir)
				ARMBIAN_USERPATCHES_DIR=${ARGS[1]}
				ARGS=(${ARGS[@]:2})
				;;
			*)
				error "Unknown argument: ${ARGS[0]}" 1>&2
				usage
				;;
			esac
		done
		;;
	rkdeveloptool)
		while [ ${#ARGS[@]} -gt 0 ]; do
			case ${ARGS[0]} in
			-h | --help)
				usage
				;;
			-d | --install-dir)
				RKDEVELOPTOOL_INSTALL_DIR=${ARGS[1]}
				ARGS=(${ARGS[@]:2})
				;;
			*)
				error "Unknown argument: ${ARGS[0]}"
				usage
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

# Output Armbian configuration parameters
function armbian_config_str() {
	local config_file=$1
	if [[ -z $config_file ]]; then
		error "Armbian configuration file not provided"
		return 1
	fi
	if [[ ! -f $config_file ]]; then
		error "Armbian configuration file not found: $config_file"
		return 1
	fi
	local config_str=""
	while IFS= read -r line; do
		config_str+=" ${line}"
	done < "${config_file}"
	echo $config_str
}

# Compile Armbian
function compile_armbian() {
	info "Compiling Armbian..."
	pushd "$ARMBIAN_INSTALL_DIR" >/dev/null 2>&1 || {
		error "Armbian directory not found: $ARMBIAN_INSTALL_DIR"
		return 1
	}
	if [ ! -f $ARMBIAN_CONFIG_FILE ]; then
		error "Armbian configuration file not found: $ARMBIAN_CONFIG_FILE"
		return 1
	fi
	if [[ -f "compile.sh" ]]; then
		info "Injecting Armbian user patches..."
		rm -rf "$ARMBIAN_INSTALL_DIR/userpatches" 2>/dev/null || true
		cp -rf "$ARMBIAN_USERPATCHES_DIR" "$ARMBIAN_INSTALL_DIR/" || {
			error "Failed to inject Armbian user patches"
			return 1
		}
		info "Running Armbian compile script..."
		eval "./compile.sh $(armbian_config_str ${ARMBIAN_CONFIG_FILE})" || {
			error "Failed to compile Armbian"
			return 1
		}
		success "Armbian compiled successfully"
		pushd "./output/images" >/dev/null 2>&1 || {
			error "Armbian images output directory not found"
			return 1
		}
		info "Armbian images in $(pwd):"
		ls -lh ./*.img 2>/dev/null
		popd >/dev/null 2>&1 || return $?
	else
		error "Armbian compile script not found"
		return 1
	fi
	popd >/dev/null 2>&1 || return $?
}

function compile_rkdeveloptool() {
	pushd "$RKDEVELOPTOOL_INSTALL_DIR" >/dev/null 2>&1 || {
		error "rkdeveloptool directory not found: $RKDEVELOPTOOL_INSTALL_DIR"
		return 1
	}
	if [[ ! -f "rkdeveloptool" ]]; then
		info "Installing dependencies for Rockchip rkdeveloptool..."
		sudo apt-get install libusb-1.0-0-dev || {
			error "Failed to install libusb-1.0-0-dev"
			return 1
		}
		# Patch line in Makefile.am AM_CPPFLAGS to fix build error
		info "Patching Makefile.am for Rockchip rkdeveloptool..."
		sed -i 's/^AM_CPPFLAGS\ \=.*$/AM_CPPFLAGS\ \=\ \-Wall\ \-Werror\ \-Wextra\ \-Wreturn-type\ \-Wno-format-truncation\ \-fno-strict-aliasing\ \-D_FILE_OFFSET_BITS\=64\ \-D_LARGE_FILE\ \$\(LIBUSB1_CFLAGS\)/g' Makefile.am || {
			error "Failed to patch Makefile.am"
			return 1
		}
		info "Compiling Rockchip rkdeveloptool..."
		autoreconf -i || {
			error "Failed to autoreconf rkdeveloptool"
			return 1
		}
		PKG_CONFIG_LIBDIR=/usr/lib/x86_64-linux-gnu/pkgconfig ./configure --prefix=/usr/local || {
			error "Failed to configure rkdeveloptool"
			return 1
		}
		make || {
			error "Failed to compile rkdeveloptool"
			return 1
		}
		success "rkdeveloptool compiled successfully"
	else
		error "Rockchip rkdeveloptool already exists"
		return 0
	fi
	popd >/dev/null 2>&1 || return $?
}

# Main
parse_args ${CARGS[*]}
ARMBIAN_CONFIG_FILE=$(cd "$(dirname "${ARMBIAN_CONFIG_FILE}")" && pwd)/$(basename "${ARMBIAN_CONFIG_FILE}")
ARMBIAN_INSTALL_DIR=$(cd "$ARMBIAN_INSTALL_DIR" && pwd)
ARMBIAN_INSTALL_DIR=${ARMBIAN_INSTALL_DIR%/}
ARMBIAN_USERPATCHES_DIR=$(cd "$ARMBIAN_USERPATCHES_DIR" && pwd)
ARMBIAN_USERPATCHES_DIR=${ARMBIAN_USERPATCHES_DIR%/}
RKDEVELOPTOOL_INSTALL_DIR=$(cd "$RKDEVELOPTOOL_INSTALL_DIR" && pwd)
RKDEVELOPTOOL_INSTALL_DIR=${RKDEVELOPTOOL_INSTALL_DIR%/}
case $ACTION in
armbian)
	compile_armbian || exit $?
	;;
rkdeveloptool)
	compile_rkdeveloptool || exit $?
	;;
*)
	error "Unknown action: $ACTION"
	usage
	;;
esac