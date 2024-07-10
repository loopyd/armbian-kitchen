#!/usr/bin/env bash

extension_prepare_config__pingpong() {

	declare -g PINGPONG_DEVICE_ID=${PINGPONG_DEVICE_ID:-}
	declare -g PINGPONG_INSTALL_PREFIX=${PINGPONG_INSTALL_PREFIX-}
	
	add_packages_to_image curl
}

pre_customize_image__000_install_pingpong() {

	run_host_command_logged cp -v "${EXTENSION_DIR}/src/pingpong-mgr" "${SDCARD}/${PINGPONG_INSTALL_PREFIX}/bin/"
	chroot_sdcard chmod +x "${PINGPONG_INSTALL_PREFIX}/bin/pingpong-mgr"
	chroot_sdcard mkdir -p "/usr/lib/systemd/system" || true
	run_host_command_logged cp -v "${EXTENSION_DIR}/src/pingpong.service" "${SDCARD}/usr/lib/systemd/system/" || {
		exit_with_error "Failed to copy pingpong.service"
	}

}