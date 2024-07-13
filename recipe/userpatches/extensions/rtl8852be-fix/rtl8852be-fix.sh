#!/usr/bin/env bash

# This extension is meant to build the RTW89 drivers from source and install it on the image.
# This is useful for loading RTW89 drivers on the image.

extension_prepare_config__rtl8852be_fix() {

	declare -g RTW89_INSTALL_PREFIX=${RTW89_INSTALL_PREFIX-}
	declare -gra RTW89_RUNTIME=(build-essential make gcc git)
	declare -gra RTW89_DEPS=(llibelf-dev)

	add_packages_to_image "${RTW89_RUNTIME[@]}"
}


pre_customize_image__000_rtw89_init() {

	display alert "Installing rtw89 build dependencies" "${EXTENSION}" "info"
	chroot_sdcard_apt_get_install --yes --no-install-recommends "${RTW89_DEPS[@]}" || {
		exit_with_error "Failed to install rtw89 build dependencies"
	}
	display_alert "Installing rtw89 management script" "${EXTENSION}" "info"
	chroot_sdcard mkdir -p "/usr/lib/scripts" || {
		exit_with_error "Failed to create /usr/lib/scripts directory"
	}
	run_host_command_logged cp -v "${EXTENSION_DIR}/src/rtw89-mgr" "${SDCARD}/usr/lib/scripts/" || {
		exit_with_error "Failed to copy rtw89-mgr script"
	}
	chroot_sdcard chmod +x "/usr/lib/scripts/rtw89-mgr" || {
		exit_with_error "Failed to set execute permissions on rtw89-mgr script"
	}

}

pre_customize_image__001_rtw89_build() {

	export LANG=C LC_ALL="en_US.UTF-8"
	export DEBIAN_FRONTEND=noninteractive
	export APT_LISTCHANGES_FRONTEND=none

	chroot_sdcard /usr/bin/env rtw89-mgr install --install-prefix "${RTW89_INSTALL_PREFIX}/src" || {
		exit_with_error "Failed to build rtw89 drivers"
	}

}

pre_customize_image__rtw89_clean() {

	display_alert "Cleaning up rtw89 build environment..." "${EXTENSION}" "info"
	chroot_sdcard_apt_get -qqy autoremove
	chroot_sdcard_apt_get -qqy clean
	chroot_sdcard rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
	
}

function post_customize_image__rtl8852be_enable() {

	display_alert "Installing RTL8852BE service..." "${EXTENSION}" "info"
	chroot_sdcard mkdir -p "/usr/lib/systemd/system" || true
	run_host_command_logged cp -v "${EXTENSION_DIR}/src/rtl8852be-reload.service" "${SDCARD}/usr/lib/systemd/system/" || {
		exit_with_error "Failed to copy rtl8852be.service"
	}
	display_alert "Enabling RTL8852BE service..." "${EXTENSION}" "info"
	chroot_sdcard systemctl enable rtl8852be-reload.service || {
		exit_with_error "Failed to enable RTL8852BE reload service"
	}

}