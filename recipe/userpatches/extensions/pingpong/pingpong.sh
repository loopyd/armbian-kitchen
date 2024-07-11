#!/usr/bin/env bash

enable_extension "docker"

extension_prepare_config__pingpong() {

	declare -g PINGPONG_INSTALL_PREFIX=${PINGPONG_INSTALL_PREFIX-}
	declare -g PINGPONG_DEVICE_KEY=${PINGPONG_DEVICE_KEY:-}
	declare -g PINGPONG_AIOZ_TOKEN=${PINGPONG_AIOZ_TOKEN:-}
	declare -g PINGPONG_AIOG_TOKEN=${PINGPONG_AIOG_TOKEN:-}
	declare -g PINGPONG_GRASS_TOKEN=${PINGPONG_GRASS_TOKEN:-}
	
	add_packages_to_image curl

}

pre_customize_image__install_pingpong() {

	display_alert "Installing pingpong" "${EXTENSION}" "info"
	run_host_command_logged cp -v "${EXTENSION_DIR}/src/pingpong-mgr" "${SDCARD}/${PINGPONG_INSTALL_PREFIX}/bin/"
	chroot_sdcard chmod +x "${PINGPONG_INSTALL_PREFIX}/bin/pingpong-mgr"
	chroot_sdcard mkdir -p "/usr/lib/systemd/system" || true
	run_host_command_logged cp -v "${EXTENSION_DIR}/src/pingpong.service" "${SDCARD}/usr/lib/systemd/system/" || {
		exit_with_error "Failed to copy pingpong.service"
	}
	chroot_sdcard mkdir -p "/etc/pingpong" || true
	declare -a PINGPONG_CONFIG_ARGS=()
	[[ -n "${PINGPONG_DEVICE_KEY}" && "x${PINGPONG_DEVICE_KEY}x" != "xx" ]] && PINGPONG_CONFIG_ARGS+=("--device-key" "${PINGPONG_DEVICE_KEY}")
	[[ -n "${PINGPONG_AIOZ_TOKEN}" && "x${PINGPONG_AIOZ_TOKEN}x" != "xx" ]] && PINGPONG_CONFIG_ARGS+=("--aioz-token" "${PINGPONG_AIOZ_TOKEN}")
	[[ -n "${PINGPONG_AIOG_TOKEN}" && "x${PINGPONG_AIOG_TOKEN}x" != "xx" ]] && PINGPONG_CONFIG_ARGS+=("--aiog-token" "${PINGPONG_AIOG_TOKEN}")
	[[ -n "${PINGPONG_GRASS_TOKEN}" && "x${PINGPONG_GRASS_TOKEN}x" != "xx" ]] && PINGPONG_CONFIG_ARGS+=("--grass-token" "${PINGPONG_GRASS_TOKEN}")
	chroot_sdcard pingpong-mgr configure --config-file "/etc/pingpong/config.json" ${PINGPONG_CONFIG_ARGS[@]} || {
		exit_with_error "Failed to configure pingpong"
	}

}

post_customize_image__enable_pingpong() {

	display_alert "Enabling pingpong service" "${EXTENSION}" "info"
	chroot_sdcard systemctl enable pingpong.service || {
		exit_with_error "Failed to enable pingpong service"
	}

}