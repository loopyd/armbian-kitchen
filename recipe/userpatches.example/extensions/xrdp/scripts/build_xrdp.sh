#!/usr/bin/env bash
declare -ra CARGS=($@)
cscript_dir=$(dirname $0)
pushd ${cscript_dir}
./bootstrap
./configure \
	--with-systemdsystemunitdir=/usr/lib/systemd/system \
	--enable-vsock \
	--enable-glamor \
	--enable-rfxcodec \
	--enable-mp3lame \
	--enable-fdkaac \
	--enable-opus \
	--enable-pixman \
	--enable-fuse \
	--enable-jpeg \
	--enable-tjpeg \
	--enable-ipv6 \
	--enable-x264 \
	--enable-ulalaca \
	--enable-rdpsndaudin \
	--with-freetype2=yes \
	--with-imlib2=yes
make -j$(nproc)
make install
popd