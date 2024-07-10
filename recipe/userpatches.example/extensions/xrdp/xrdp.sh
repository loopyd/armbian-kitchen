#!/usr/bin/env bash

extension_prepare_config__prepare_xrdp_config() {

	declare -g XRDP_PULSEAUDIO_VERSION="${XRDP_PULSEAUDIO_VERSION:-}"
	declare -g XRDP_XORGXRDP_VERSION="${XORGXRDP_VERSION:-0.10.1}"
	declare -g XRDP_VERSION="${XRDP_VERSION:-0.10.0}"
	declare -g XRDP_PULSEAUDIO_MODULE_VERSION="${XRDP_PULSEAUDIO_MODULE_VERSION:-0.7}"
	declare -g XRDP_INSTALL_PREFIX="${XRDP_INSTALL_PREFIX:-/usr/local}"
	declare -ga XRDP_BUILD_DEPS=()
	XRDP_BUILD_DEPS+=(build-essential make autoconf libtool intltool bison flex autopoint pkg-config nasm ninja-build meson yasm cmake check xutils xsltproc dbus-x11 doxygen gcovr valgrind libglib2.0-dev libcmocka-dev libcmocka0 libxfixes-dev libxrandr-dev libgbm-dev libepoxy-dev libexecs-dev libdbus-1-dev libsystemd-dev libx11-xcb-dev libseat1 xserver-xorg-dev libssl-dev libpam0g-dev libx11-dev libxfixes-dev libxrandr-dev xutils-dev libxml2-dev python3-libxml2 libfuse-dev libcap-dev libgtk-3-dev libltdl-dev libtdb-dev libimlib2-dev libfreetype-dev liblirc-dev liblirc-client0 liblirc0 libudev-dev libudev1 libjson-c-dev liborc-0.4-dev libibus-1.0-dev libxkbfile-dev)
	XRDP_BUILD_DEPS+=(libjpeg-dev libopus-dev libmp3lame-dev libegl1-mesa-dev libsamplerate0-dev libsamplerate0 libresample1-dev libresample1 libsndfile1-dev libspeex-dev libpulse-dev libpulse0 libfdk-aac-dev libturbojpeg0-dev libjpeg-turbo8-dev libfftw3-dev libasyncns-dev libasound2-dev libspeexdsp-dev libspeexdsp1 libsoxr-dev libsoxr0 libwebrtc-audio-processing-dev libwebrtc-audio-processing1 libx264-dev libavahi-client-dev libavahi-client3 libsbc-dev libsbc1 bluez libbluetooth-dev libbluetooth3 libjack-jackd2-dev)
	XRDP_BUILD_DEPS+=(libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-dev libgstreamer-plugins-bad1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-alsa gstreamer1.0-tools gstreamer1.0-plugins-rtp gstreamer1.0-plugins-base-apps gstreamer1.0-plugins-bad-apps ubuntu-restricted-extras)
}

pre_customize_image__000_xrdp_tools() {

	chroot_sdcard mkdir -p ${XRDP_INSTALL_PREFIX}/src/{xrdp,xorgxrdp,pulseaudio-module-xrdp,pulseaudio}
	display_alert "Adding XRDP build dependencies..." "${EXTENSION}: tools" "info"
	chroot_sdcard_apt_get_install --yes --no-install-recommends --mark-auto ${XRDP_BUILD_DEPS[*]} || {
		exit_with_error "Failed to install XRDP build dependencies"
	}
	display_alert "Adding XRDP scripts..." "${EXTENSION}" "info"
	run_host_command_logged cp -v "${EXTENSION_DIR}/scripts/"* "${SDCARD}${XRDP_INSTALL_PREFIX}/bin/" || {
		exit_with_error "Failed to copy xrdp-build script"
	}
	chroot_sdcard chmod +x "${XRDP_INSTALL_PREFIX}/bin/xrdp-"* || {
		exit_with_error "Failed to set execute permissions on xrdp scripts"
	}

}

pre_customize_image__001_xrdp_build() {

	export LANG=C LC_ALL="en_US.UTF-8"
	export DEBIAN_FRONTEND=noninteractive
	export APT_LISTCHANGES_FRONTEND=none

	display_alert "Building XRDP..." "${EXTENSION}: build" "info"
	chroot_sdcard ${XRDP_INSTALL_PREFIX}/bin/xrdp-build xrdp --build-dir "${XRDP_INSTALL_PREFIX}/src/xrdp" --ref "tag:v${XRDP_VERSION}" || {
		exit_with_error "Failed to build XRDP"
	}
	display_alert "Building XORGXRDP..." "${EXTENSION}: build" "info"
	chroot_sdcard ${XRDP_INSTALL_PREFIX}/bin/xrdp-build xorgxrdp --build-dir "${XRDP_INSTALL_PREFIX}/src/xorgxrdp" --ref "tag:v${XRDP_XORGXRDP_VERSION}" || {
		exit_with_error "Failed to build XORGXRDP"
	}
	display_alert "Building Pulseaudio..." "${EXTENSION}: build" "info"
	if [[ -z "$XRDP_PULSEAUDIO_VERSION" ]]; then
		display_alert "${EXTENSION}: tools" "Pulseaudio version not set, detecting latest version..." "warning"
		XRDP_PULSEAUDIO_VERSION=$(chroot_sdcard_with_stdout pulseaudio --version | awk '{print $2}')
		display_alert "${EXTENSION}: tools" "Detected Pulseaudio version: $XRDP_PULSEAUDIO_VERSION" "warning"
	fi
	chroot_sdcard ${XRDP_INSTALL_PREFIX}/bin/xrdp-build pulseaudio --build-dir "${XRDP_INSTALL_PREFIX}/src/pulseaudio" --version "${XRDP_PULSEAUDIO_VERSION}" || {
		exit_with_error "Failed to build Pulseaudio"
	}
	display_alert "Building Pulseaudio Module..." "${EXTENSION}: build" "info"
	chroot_sdcard ${XRDP_INSTALL_PREFIX}/bin/xrdp-build pulseaudio-module-xrdp --build-dir "${XRDP_INSTALL_PREFIX}/src/pulseaudio-module-xrdp" --pulse-dir "${XRDP_INSTALL_PREFIX}/src/pulseaudio" --ref "tag:v${XRDP_PULSEAUDIO_MODULE_VERSION}" || {
		exit_with_error "Failed to build Pulseaudio XRDP Module"
	}
	display_alert "XRDP build completed successfully" "${EXTENSION}: build" "info"

}

pre_customize_image__002_xrdp_clean() {

	display_alert "Cleaning up XRDP build environment..." "${EXTENSION}: clean" "info"
	chroot_sdcard_apt_get -qqy autoremove
	chroot_sdcard_apt_get -qqy clean
	chroot_sdcard rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

}

post_customize_image__000_xrdp_activate() {

	# Enable XRDP Service
	display_alert "Enabling XRDP service..." "${EXTENSION}: build" "info"
	chroot_sdcard systemctl enable xrdp.service || {
		exit_with_error "Failed to enable XRDP service"
	}

}
