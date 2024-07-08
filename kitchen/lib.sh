#!/bin/bash

# ensure script is only source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	echo "This script must be sourced, not executed"
	exit 1
fi

# Colors
C_RED=$(tput setaf 1)
C_GREEN=$(tput setaf 2)
C_YELLOW=$(tput setaf 3)
C_BLUE=$(tput setaf 4)
C_MAGENTA=$(tput setaf 5)
C_CYAN=$(tput setaf 6)
C_WHITE=$(tput setaf 7)
C_BOLD=$(tput bold)
C_RESET=$(tput sgr0)

# Core environment variables
DEBUG=${DEBUG:-false}
FILE_OVERWRITE=${FILE_OVERWRITE:-false}

# Armbian environment variables
ARMBIAN_INSTALL_DIR=${ARMBIAN_INSTALL_DIR:-./build/armbian}
ARMBIAN_CONFIG_FILE=${ARMBIAN_CONFIG_FILE:-./recipe/armbian.conf}
ARMBIAN_USERPATCHES_DIR=${ARMBIAN_USERPATCHES_DIR:-./recipe/userpatches}

# rkdeveloptool environment variables
RKDEVELOPTOOL_INSTALL_DIR=${RKDEVELOPTOOL_INSTALL_DIR:-./build/rkdeveloptool}

# Ezflash loader environment variables
EZFLASH_INSTALL_DIR=${EZFLASH_INSTALL_DIR:-./build/ezflash}
EZFLASH_IMAGE_FILE=${EZFLASH_IMAGE_FILE:-}
EZFLASH_LOADER_FILE=${EZFLASH_LOADER_FILE:-}
EZFLASH_FLASH_OFFSET=${EZFLASH_FLASH_OFFSET:-0}
EZFLASH_ERASE_EMMC_SIZE=${EZFLASH_ERASE_EMMC_SIZE:-0}
EZFLASH_WAIT_DEVICE=${EZFLASH_WAIT_DEVICE:-true}
EZFLASH_WAIT_DEVICE_TIMEOUT=${EZFLASH_WAIT_DEVICE_TIMEOUT:-60}
EZFLASH_AUTO_REBOOT=${EZFLASH_AUTO_REBOOT:true}

# Display information message
function info() {
	echo "${C_BOLD}${C_BLUE}INFO: ${C_RESET}${C_BLUE}$1${C_RESET}"
}

# Display success message
function success() {
	echo "${C_BOLD}${C_GREEN}SUCCESS: ${C_RESET}${C_GREEN}$1${C_RESET}"
}

# Display warning message
function warning() {
	echo "${C_BOLD}${C_YELLOW}WARNING: ${C_RESET}${C_YELLOW}$1${C_RESET}" >&2
}

# Display error message
function error() {
	echo "${C_BOLD}${C_RED}ERROR: ${C_RESET}${C_RED}$1${C_RESET}" >&2
}

# check if shell command exists
function shell_cmd_exists() {
	local cmd=$1
	if [ -z "$cmd" ]; then
		error "Command not provided"
		return 2
	fi
	command -v $cmd >/dev/null 2>&1 || {
		return 1
	}
	return 0
}

function error_trap() {
	local LASTEXITCODE=$?
	if [ $LASTEXITCODE -ne 0 ]; then
		error "Script exited with failure status code: $LASTEXITCODE" 1>&2
		exit $LASTEXITCODE
	fi
	exit 0
}
trap error_trap ERR SIGINT SIGTERM SIGHUP SIGQUIT SIGTSTP EXIT