#!/bin/bash

shopt -s dotglob nullglob
CSCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${CSCRIPT_DIR}/lib.sh"

CARGS=($@)

# Display program usage information
function usage() {
	case $ACTION in
	armbian)
		echo "Usage: $0 armbian [OPTIONS]"
		echo "Options:"
		echo "  -h, --help              Display this help message"
		echo "  -i, --install-dir DIR   Install Armbian source code to DIR (default: /opt/armbian)"
		echo "  -o, --overwrite         Overwrite existing Armbian source code, if present"
		;;
	rkdeveloptool)
		echo "Usage: $0 rkdeveloptool [OPTIONS]"
		echo "Options:"
		echo "  -h, --help              Display this help message"
		echo "  -i, --install-dir DIR   Install rkdeveloptool to DIR (default: /opt/rkdeveloptool)"
		echo "  -o, --overwrite         Overwrite existing rkdeveloptool, if present"
		;;
	ezflash)
		echo "Usage: $0 ezflash [OPTIONS]"
		echo "Options:"
		echo "  -h, --help              Display this help message"
		echo "  -i, --install-dir DIR   Install ezflash loader bins to DIR (default: /opt/ezflash)"
		echo "  -o, --overwrite         Overwrite existing ezflash loader bins, if present"
		;;
	*)
		echo "Usage: $0 [ACTION] [OPTIONS]"
		echo "Actions:"
		echo "  armbian                 Download Armbian source code"
		echo "  rkdeveloptool           Download Rockchip rkdeveloptool"
		echo "  ezflash                 Download ezflash loader bins"
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
	ACTION="${ARGS[0]}"
	if [ -z $ACTION ]; then
		error "No action specified"
		usage
	fi
	ARGS=(${ARGS[@]:1})
	case "$ACTION" in
	armbian)
		while [ ${#ARGS[@]} -gt 0 ]; do
			case ${ARGS[0]} in
			-h | --help)
				usage
				;;
			-i | --install-dir)
				ARMBIAN_INSTALL_DIR=${ARGS[1]}
				ARGS=(${ARGS[@]:2})
				;;
			-o | --overwrite)
				FILE_OVERWRITE=true
				ARGS=(${ARGS[@]:1})
				;;
			*)
				error "Unknown argument: ${ARGS[0]}"
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
			-i | --install-dir)
				RKDEVELOPTOOL_INSTALL_DIR=${ARGS[1]}
				ARGS=(${ARGS[@]:2})
				;;
			-o | --overwrite)
				FILE_OVERWRITE=true
				ARGS=(${ARGS[@]:1})
				;;
			*)
				error "Unknown argument: ${ARGS[0]}"
				usage
				;;
			esac
		done
		;;
	ezflash)	
		while [ ${#ARGS[@]} -gt 0 ]; do
			case ${ARGS[0]} in
			-h | --help)
				usage
				;;
			-i | --install-dir)
				EZFLASH_INSTALL_DIR=${ARGS[1]}
				ARGS=(${ARGS[@]:2})
				;;
			-o | --overwrite)
				FILE_OVERWRITE=true
				ARGS=(${ARGS[@]:1})
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

# Install Armbian source code
function install_armbian() {
	temp_file=$(mktemp)
	temp_folder=$(mktemp -d)
	if [[ -d "$ARMBIAN_INSTALL_DIR" ]]; then
		warning "Armbian source code already exists in $ARMBIAN_INSTALL_DIR"
		if [[ $FILE_OVERWRITE == false ]]; then
			read -p "Do you want to overwrite it? [y/N]: " -r
			if [[ ! $REPLY =~ ^[Yy]$ ]]; then
				return 0
			fi
		else
			printf "Removing existing Armbian source code..."
			sudo rm -rf "$ARMBIAN_INSTALL_DIR" || {
				printf "${C_BOLD}${C_RED}failed${C_RESET}\n"
				rm -rf "$temp_file" "$temp_folder"
				return 1
			}
			printf "${C_BOLD}${C_GREEN}OK${C_RESET}\n"
		fi
	fi
	printf "Downloading Armbian source code..."
	wget -qO "$temp_file" "https://github.com/armbian/build/archive/refs/heads/main.zip" || {
		printf "${C_BOLD}${C_RED}failed${C_RESET}\n"
		rm -rf "$temp_file" "$temp_folder"
		return 1
	}
	printf "${C_BOLD}${C_GREEN}OK${C_RESET}\n"
	printf "Unzipping Armbian source code..."
	bsdtar --strip-components=1 -xf "$temp_file" -C "$temp_folder" || {
		printf "${C_BOLD}${C_RED}failed${C_RESET}\n"
		rm -rf "$temp_file" "$temp_folder"
		return 1
	}
	printf "${C_BOLD}${C_GREEN}OK${C_RESET}\n"
	printf "Installing Armbian source code to $ARMBIAN_INSTALL_DIR..."
	sudo mkdir -p "$ARMBIAN_INSTALL_DIR" || {
		printf "${C_BOLD}${C_RED}failed${C_RESET}\n"
		rm -rf "$temp_file" "$temp_folder"
		return 1
	}
	sudo mv -f "$temp_folder"/* "$ARMBIAN_INSTALL_DIR" || {
		printf "${C_BOLD}${C_RED}failed${C_RESET}\n"
		rm -rf "$temp_file" "$temp_folder"
		return 1
	}
	sudo chown -R "$USER:$USER" "$ARMBIAN_INSTALL_DIR" || {
		printf "${C_BOLD}${C_RED}failed${C_RESET}\n"
		rm -rf "$temp_file" "$temp_folder"
		return 1
	}
	rm -rf "$temp_file" "$temp_folder" || {
		printf "${C_BOLD}${C_RED}failed${C_RESET}\n"
		return 1
	}
	printf "${C_BOLD}${C_GREEN}OK${C_RESET}\n"
	success "Armbian source code installed to $ARMBIAN_INSTALL_DIR"
	return 0
}

# Install rkdeveloptool
function install_rkdeveloptool() {
	temp_file=$(mktemp)
	temp_folder=$(mktemp -d)
	if [[ -d "$RKDEVELOPTOOL_INSTALL_DIR" ]]; then
		warning "rkdeveloptool already exists in $RKDEVELOPTOOL_INSTALL_DIR"
		if [[ $FILE_OVERWRITE == false ]]; then
			read -p "Do you want to overwrite it? [y/N]: " -r
			if [[ ! $REPLY =~ ^[Yy]$ ]]; then
				return 0
			fi
		else
			info "Removing existing rkdeveloptool..."
			sudo rm -rf "$RKDEVELOPTOOL_INSTALL_DIR"
			success "Existing rkdeveloptool removed"
		fi
	fi
	printf "Downloading rkdeveloptool..."
	wget -qO "$temp_file" "https://github.com/rockchip-linux/rkdeveloptool/archive/refs/heads/master.zip" || {
		printf "${C_BOLD}${C_RED}failed${C_RESET}\n"
		rm -rf "$temp_file" "$temp_folder"
		return 1
	}
	printf "${C_BOLD}${C_GREEN}OK${C_RESET}\n"
	printf "Unzipping rkdeveloptool..."
	bsdtar --strip-components=1 -xf "$temp_file" -C "$temp_folder" || {
		printf "${C_BOLD}${C_RED}failed${C_RESET}\n"
		rm -rf "$temp_file" "$temp_folder"
		return 1
	}
	printf "${C_BOLD}${C_GREEN}OK${C_RESET}\n"
	printf "Installing rkdeveloptool to $RKDEVELOPTOOL_INSTALL_DIR..."
	sudo mkdir -p "$RKDEVELOPTOOL_INSTALL_DIR" || {
		printf "${C_BOLD}${C_RED}failed${C_RESET}\n"
		rm -rf "$temp_file" "$temp_folder"
		return 1
	}
	sudo mv -f "$temp_folder"/* "$RKDEVELOPTOOL_INSTALL_DIR" || {
		printf "${C_BOLD}${C_RED}failed${C_RESET}\n"
		rm -rf "$temp_file" "$temp_folder"
		return 1
	}
	sudo chown -R "$USER:$USER" "$RKDEVELOPTOOL_INSTALL_DIR" || {
		printf "${C_BOLD}${C_RED}failed${C_RESET}\n"
		rm -rf "$temp_file" "$temp_folder"
		return 1
	}
	rm -rf "$temp_file" "$temp_folder" || {
		printf "${C_BOLD}${C_RED}failed${C_RESET}\n"
		return 1
	}
	printf "${C_BOLD}${C_GREEN}OK${C_RESET}\n"
	success "rkdeveloptool installed to $RKDEVELOPTOOL_INSTALL_DIR"
	return 0
}

function install_ezflash() {
	temp_file=$(mktemp)
	temp_folder=$(mktemp -d)
	if [[ -d "$EZFLASH_INSTALL_DIR" ]]; then
		warning "ezflash loader bins already exists in $EZFLASH_INSTALL_DIR"
		if [[ $FILE_OVERWRITE == false ]]; then
			read -p "Do you want to overwrite it? [y/N]: " -r
			if [[ ! $REPLY =~ ^[Yy]$ ]]; then
				return 0
			fi
		else
			info "Removing existing ezflash loader bins..."
			sudo rm -rf "$EZFLASH_INSTALL_DIR"
			success "Existing ezflash loader bins removed"
		fi
	fi
	printf "Downloading miniloader bins..."
	wget -qO "${temp_file}" "https://github.com/loopyd/board-miniloaders/archive/refs/heads/master.zip" || {
		printf "${C_BOLD}${C_RED}failed${C_RESET}\n"
		rm -rf "${temp_file}" "${temp_folder}"
		return 1
	}
	printf "${C_BOLD}${C_GREEN}OK${C_RESET}\n"
	printf "Unzipping miniloader bins from ${temp_file} to ${temp_folder}..."
	eval "bsdtar --strip-components=1 -xf \"$temp_file\" -C \"$temp_folder\"
" || {
		printf "${C_BOLD}${C_RED}failed${C_RESET}\n"
		rm -rf "$temp_file" "$temp_folder"
		return 1
	}
	printf "${C_BOLD}${C_GREEN}OK${C_RESET}\n"
	printf "Installing miniloader bins to ${EZFLASH_INSTALL_DIR}..."
	sudo mkdir -p "${EZFLASH_INSTALL_DIR}" || {
		printf "${C_BOLD}${C_RED}failed${C_RESET}\n"
		rm -rf "${temp_file}" "${temp_folder}"
		return 1
	}
	sudo mv -f "${temp_folder}"/* "${EZFLASH_INSTALL_DIR}" || {
		printf "${C_BOLD}${C_RED}failed${C_RESET}\n"
		rm -rf "${temp_file}" "${temp_folder}"
		return 1
	}
	sudo chown -R "${USER}:${USER}" "${EZFLASH_INSTALL_DIR}" || {
		printf "${C_BOLD}${C_RED}failed${C_RESET}\n"
		rm -rf "${temp_file}" "${temp_folder}"
		return 1
	}
	rm -rf "${temp_file}" "${temp_folder}" || {
		printf "${C_BOLD}${C_RED}failed${C_RESET}\n"
		return 1
	}
	printf "${C_BOLD}${C_GREEN}OK${C_RESET}\n"
	success "ezflash loader bins installed to ${EZFLASH_INSTALL_DIR}"
	return 0
}

# Main
parse_args ${CARGS[*]}
case "$ACTION" in
armbian)
	install_armbian
	;;
rkdeveloptool)
	install_rkdeveloptool
	;;
ezflash)
	install_ezflash
	;;
*)
	error "Unknown action: $ACTION"
	usage
	;;
esac
