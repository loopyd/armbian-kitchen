#!/usr/bin/env bash
XRDP_INSTALL_PREFIX=${XRDP_INSTALL_PREFIX:-/usr/local}
PULSE_DIR=${PULSE_DIR:-${XRDP_INSTALL_PREFIX}/src/pulseaudio}
if [ ! -d "$PULSE_DIR" ]; then
	echo "E: Pulseaudio source directory not found at: $PULSE_DIR" >&2
	exit 1
fi
cscript_dir=$(dirname $0)
pushd ${cscript_dir}
./bootstrap
./configure PULSE_DIR=${PULSE_DIR}
make -j$(nproc)
make install
popd