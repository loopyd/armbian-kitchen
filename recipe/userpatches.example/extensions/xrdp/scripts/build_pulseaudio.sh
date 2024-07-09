#!/usr/bin/env bash
cscript_dir=$(dirname $0)
pushd ${cscript_dir}
meson build
ninja -C build
ldconfig
popd