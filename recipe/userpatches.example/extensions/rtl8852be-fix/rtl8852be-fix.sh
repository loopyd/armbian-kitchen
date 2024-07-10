#!/usr/bin/env bash

# This extension is meant to fix the RTL8852BE driver not loading on boot and not searching for
# wifi networks. The fix is to reload the driver on boot with a one-shot service.  This also
# fixes bad naming of the wifi interface by ordering the driver to be loaded correctly.
#
# The common reason the issue tracker is filled with RTL8852BE issues is because the vendor
# kernel itself is a mess.  This brings order to the chaos, and your issue trackers.  :-)

extension_prepare_config__prepare_rtl8852be_fix() {

	add_packages_to_image armbian-firmware-full

}

pre_customize_image__rtl8852be_fix() {

	display_alert "Installing RTL8852BE service..." "${EXTENSION}" "info"
	run_host_command_logged cp -v "${EXTENSION_DIR}/src/rtl8852be-reload.sh" "${SDCARD}/usr/lib/scripts/" || {
		exit_with_error "Failed to copy rtl8852be-reload.sh script"
	}
	chroot_sdcard chmod +x "/usr/lib/scripts/rtl8852be-reload.sh" || {
		exit_with_error "Failed to set execute permissions on rtl8852be-reload.sh"
	}
	run_host_command_logged cp -v "${EXTENSION_DIR}/src/rtl8852be.service" "${SDCARD}/usr/lib/systemd/system/" || {
		exit_with_error "Failed to copy rtl8852be.service"
	}

}

post_customize_image__rtl8852be_fix() {

	display_alert "Enabling RTL8852BE service..." "${EXTENSION}" "info"
	chroot_sdcard systemctl enable rtl8852be.service || {
		exit_with_error "Failed to enable RTL8852BE reload service"
	}

}