#!/usr/bin/env bash

extension_prepare_config__prepare_xrdp_config() {

	declare -g XRDP_PULSEAUDIO_VERSION="${XRDP_PULSEAUDIO_VERSION:-}"
	declare -g XRDP_XORGXRDP_VERSION="${XORGXRDP_VERSION:-0.10.1}"
	declare -g XRDP_VERSION="${XRDP_VERSION:-0.10.0}"
	declare -g XRDP_PULSEAUDIO_MODULE_VERSION="${XRDP_PULSEAUDIO_MODULE_VERSION:-0.7}"
	declare -g XRDP_INSTALL_PREFIX="${XRDP_INSTALL_PREFIX:-/usr/local}"
	declare -ga XRDP_BUILD_DEPS=(build-essential make autoconf libtool intltool pkg-config nasm ninja-build meson yasm cmake check doxygen gcovr valgrind libglib2.0-dev libcmocka-dev libglib2.0-dev libcmocka0)
	XRDP_BUILD_DEPS+=(xserver-xorg-dev libssl-dev libpam0g-dev libx11-dev libjpeg-dev libfuse-dev libopus-dev libmp3lame-dev libxfixes-dev libxrandr-dev libgbm-dev libepoxy-dev libegl1-mesa-dev libcap-dev libsamplerate0-dev libsamplerate0 libresample1-dev libresample1 libsndfile1-dev libspeex-dev libpulse-dev libfdk-aac-dev pulseaudio libturbojpeg0-dev libjpeg-turbo8-dev libexecs-dev libdbus-1-dev libsystemd-dev libx11-xcb-dev libfftw3-dev libasyncns-dev libgtk-3-dev libltdl-dev libtdb-dev libimlib2-dev libfreetype-dev libasound2-dev liborc-0.4-dev libspeexdsp-dev libspeexdsp1 libsoxr-dev libsoxr0 libwebrtc-audio-processing-dev libwebrtc-audio-processing1 libx264-dev libseat1 libavahi-client-dev libavahi-client3 libsbc-dev libsbc1 bluez libbluetooth-dev libbluetooth3 libjack-jackd2-dev liblirc-dev liblirc-client0 liblirc0 libudev-dev libudev1)
	XRDP_BUILD_DEPS+=(libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-good1.0-dev libgstreamer-plugins-bad1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-alsa gstreamer1.0-tools gstreamer1.0-plugins-rtp gstreamer1.0-plugins-base-apps gstreamer1.0-plugins-bad-apps ubuntu-restricted-extras)

}

pre_customize_image__000_xrdp_tools() {

	if [[ -z "$XRDP_PULSEAUDIO_VERSION" ]]; then
		display_alert "${EXTENSION}: tools" "Pulseaudio version not set, detecting latest version..." "warning"
		XRDP_PULSEAUDIO_VERSION=$(chroot_sdcard_with_stdout pulseaudio --version | awk '{print $2}')
		display_alert "${EXTENSION}: tools" "Detected Pulseaudio version: $XRDP_PULSEAUDIO_VERSION" "warning"
	fi

	chroot_sdcard mkdir -p ${XRDP_INSTALL_PREFIX}/src/{xrdp,xorgxrdp,pulseaudio-module-xrdp,pulseaudio}

	display_alert "Downloading XRDP source code..." "${EXTENSION}: tools" "info"
	wget -qO - "https://github.com/neutrinolabs/xrdp/releases/download/v$XRDP_VERSION/xrdp-$XRDP_VERSION.tar.gz" | tar xzf - -C ${SDCARD}${XRDP_INSTALL_PREFIX}/src/xrdp --strip-components=1 || {
		exit_with_error "Failed to download XRDP source code"
	}

	display_alert "Downloading XORGXRDP source code..." "${EXTENSION}: tools" "info"
	wget -qO - "https://github.com/neutrinolabs/xorgxrdp/releases/download/v$XRDP_XORGXRDP_VERSION/xorgxrdp-$XRDP_XORGXRDP_VERSION.tar.gz" | tar xzf - -C ${SDCARD}${XRDP_INSTALL_PREFIX}/src/xorgxrdp --strip-components=1 || {
		exit_with_error "Failed to download XORGXRDP source code"
	}

	display_alert "Downloading Pulseaudio source code..." "${EXTENSION}: tools" "info"
	wget -qO - "https://freedesktop.org/software/pulseaudio/releases/pulseaudio-${XRDP_PULSEAUDIO_VERSION}.tar.xz" | tar xJf - -C ${SDCARD}${XRDP_INSTALL_PREFIX}/src/pulseaudio --strip-components=1 || {
		exit_with_error "Failed to download Pulseaudio source code"
	}

	display_alert "Downloading XRDP Pulseaudio Module source code..." "${EXTENSION}: tools" "info"
	wget -qO - "https://github.com/neutrinolabs/pulseaudio-module-xrdp/archive/v${XRDP_PULSEAUDIO_MODULE_VERSION}.tar.gz" | tar xzf - -C ${SDCARD}${XRDP_INSTALL_PREFIX}/src/pulseaudio-module-xrdp --strip-components=1 || {
		exit_with_error "Failed to download XRDP Pulseaudio Module source code"
	}

	display_alert "Adding XRDP build dependencies..." "${EXTENSION}: tools" "info"
	chroot_sdcard_apt_get_install --yes --no-install-recommends --mark-auto ${XRDP_BUILD_DEPS[*]} || {
		exit_with_error "Failed to install XRDP build dependencies"
	}

	display_alert "Adding XRDP build scripts..." "${EXTENSION}" "info"
	run_host_command_logged cp -v "${EXTENSION_DIR}/scripts/build_xrdp.sh" "${SDCARD}${XRDP_INSTALL_PREFIX}/src/xrdp/"
	chroot_sdcard chmod +x ${XRDP_INSTALL_PREFIX}/src/xrdp/build_xrdp.sh
	run_host_command_logged cp -v "${EXTENSION_DIR}/scripts/build_xorgxrdp.sh" "${SDCARD}${XRDP_INSTALL_PREFIX}/src/xorgxrdp/"
	chroot_sdcard chmod +x ${XRDP_INSTALL_PREFIX}/src/xorgxrdp/build_xorgxrdp.sh
	run_host_command_logged cp -v "${EXTENSION_DIR}/scripts/build_pulseaudio.sh" "${SDCARD}${XRDP_INSTALL_PREFIX}/src/pulseaudio/"
	chroot_sdcard chmod +x ${XRDP_INSTALL_PREFIX}/src/pulseaudio/build_pulseaudio.sh
	run_host_command_logged cp -v "${EXTENSION_DIR}/scripts/build_pulseaudio_module_xrdp.sh" "${SDCARD}${XRDP_INSTALL_PREFIX}/src/pulseaudio-module-xrdp/"
	chroot_sdcard chmod +x ${XRDP_INSTALL_PREFIX}/src/pulseaudio-module-xrdp/build_pulseaudio_module_xrdp.sh
	display_alert "XRDP tools installed sucessfully" "${EXTENSION}: tools" "info"

}

pre_customize_image__001_xrdp_build() {

	export LANG=C LC_ALL="en_US.UTF-8"
	export DEBIAN_FRONTEND=noninteractive
	export APT_LISTCHANGES_FRONTEND=none

	display_alert "Building XRDP..." "${EXTENSION}: build" "info"
	chroot_sdcard ${XRDP_INSTALL_PREFIX}/src/xrdp/build_xrdp.sh || {
		exit_with_error "Failed to build XRDP"
	}

	display_alert "Building XORGXRDP..." "${EXTENSION}: build" "info"
	chroot_sdcard ${XRDP_INSTALL_PREFIX}/src/xorgxrdp/build_xorgxrdp.sh || {
		exit_with_error "Failed to build XORGXRDP"
	}

	display_alert "Building Pulseaudio..." "${EXTENSION}: build" "info"
	chroot_sdcard ${XRDP_INSTALL_PREFIX}/src/pulseaudio/build_pulseaudio.sh || {
		exit_with_error "Failed to build Pulseaudio"
	}

	display_alert "Building Pulseaudio Module..." "${EXTENSION}: build" "info"
	chroot_sdcard XRDP_INSTALL_PREFIX=${XRDP_INSTALL_PREFIX} ${XRDP_INSTALL_PREFIX}/src/pulseaudio-module-xrdp/build_pulseaudio_module_xrdp.sh || {
		exit_with_error "Failed to build Pulseaudio Module"
	}

	display_alert "XRDP build completed successfully" "${EXTENSION}: build" "info"

}

pre_customize_image__002_xrdp_clean() {

	display_alert "Cleaning up XRDP build environment..." "${EXTENSION}: clean" "info"
	chroot_sdcard rm -f ${XRDP_INSTALL_PREFIX}/src/xrdp/build_xrdp.sh ${XRDP_INSTALL_PREFIX}/src/xorgxrdp/build_xorgxrdp.sh ${XRDP_INSTALL_PREFIX}/src/pulseaudio/build_pulseaudio.sh ${XRDP_INSTALL_PREFIX}/src/pulseaudio_module/build_pulseaudio_module.sh
	chroot_sdcard_apt_get -qqy autoremove
	chroot_sdcard_apt_get -qqy clean
	chroot_sdcard rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

}

post_customize_image__000_xrdp_activate() {

	# Enable XRDP Service
	display_alert "Enabling XRDP service..." "${EXTENSION}: build" "info"
	chroot_sdcard systemctl enable xrdp
	chroot_sdcard systemctl start xrdp

}
