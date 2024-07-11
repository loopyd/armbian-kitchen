#!/usr/bin/env bash

prepare_config__docker() {

	add_packages_to_image ca-certificates curl gnupg2 software-properties-common apt-transport-https

}

pre_customize_image__docker() {

	display_alert "Installing docker" "${EXTENSION}" "info"
	chroot_sdcard install -m 0755 -d /etc/apt/keyrings
	chroot_sdcard_apt_get_update
	chroot_sdcard "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && chmod a+r /etc/apt/keyrings/docker.gpg"
	local _guest_arch _guest_version _guest_distrobution _guest_version_codename
	_guest_arch=$(chroot_sdcard_with_stdout /bin/bash -c 'dpkg --print-architecture')
	_guest_version=$(chroot_sdcard_with_stdout /bin/bash -c '. /etc/os-release && echo "$VERSION_CODENAME"')
	_guest_distrobution=$(chroot_sdcard_with_stdout /bin/bash -c '. /etc/os-release && echo "$ID"')
	case "${_guest_distrobution}" in
		ubuntu)
			_guest_distrobution="ubuntu"
			_guest_version_codename="${_guest_version}"
			;;
		debian)
			_guest_distrobution="debian"
			_guest_version_codename="${_guest_version}"
			;;
		linuxmint|armbian|raspbian)
			_guest_version_codename=$(chroot_sdcard_with_stdout /bin/bash -c '. /etc/os-release && echo "$UBUNTU_CODENAME"')
			declare -a _guest_distrobutions=($(chroot_sdcard_with_stdout /bin/bash -c '. /etc/os-release && echo "$ID_LIKE"'))
			_guest_distrobution=${_guest_distrobutions[0]}
			;;
		*)
			exit_with_error "Unsupported distribution: ${_guest_distrobution}"
			;;
	esac
	echo "deb [arch=${_guest_arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${_guest_distrobution} ${_guest_version_codename} stable" | tee ${SDCARD}/etc/apt/sources.list.d/docker.list >/dev/null
	chroot_sdcard_apt_get_update
	chroot_sdcard_apt_get_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

}

post_customize_image__docker() {

	display_alert "Enabling docker service" "${EXTENSION}" "info"
	chroot_sdcard systemctl enable docker.service || {
		exit_with_error "Failed to enable docker service"
	}

}