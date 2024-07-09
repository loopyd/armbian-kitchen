#!/usr/bin/env bash
declare -ra CARGS=($@)
cscript_dir=$(dirname $0)
pushd ${cscript_dir}
./bootstrap
./configure
make -j$(nproc)
make install
popd