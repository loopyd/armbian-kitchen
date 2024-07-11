#!/usr/bin/env bash

prepare_config__docker() {

	add_packages_to_image ca-certificates curl gnupg2 software-properties-common apt-transport-https

}

pre_customize_image__install_docker() {

	display_alert "Installing docker" "${EXTENSION}" "info"
	chroot_sdcard install -m 0755 -d /etc/apt/keyrings
	chroot_sdcard_apt_get_update
	add_apt_sources "docker" "deb [arch=arm64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian buster stable"
	chroot_sdcard "curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
	chroot_sdcard 'chmod a+r /etc/apt/keyrings/docker.gpg'
	chroot_sdcard 'echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null'
	chroot_sdcard_apt_get_update
	chroot_sdcard_apt_get_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

}

post_customize_image__enable_docker() {

	display_alert "Enabling docker service" "${EXTENSION}" "info"
	chroot_sdcard systemctl enable docker.service || {
		exit_with_error "Failed to enable docker service"
	}

}