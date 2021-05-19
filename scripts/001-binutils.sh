#!/bin/bash
set -eu

#
# tools/build-linux64-toolchain.sh: Linux toolchain build script.
#
# n64chain: A (free) open-source N64 development toolchain.
# Copyright 2014-16 Tyler J. Stachecki <stachecki.tyler@gmail.com>
#
# This file is subject to the terms and conditions defined in
# 'LICENSE', which is part of this source code package.
#

getnumproc() {
which getconf >/dev/null 2>/dev/null && {
	getconf _NPROCESSORS_ONLN 2>/dev/null || getconf NPROCESSORS_ONLN 2>/dev/null || echo 1;
} || echo 1;
};

numproc=`getnumproc`

TARGET_ALIAS="crashsdk"
TARGET="mips64-elf"
TARG_XTRA_OPTS=""
OSVER=$(uname)

if [ ${OSVER:0:10} == MINGW64_NT ]; then
	export lt_cv_sys_max_cmd_len=8000
	export CC=x86_64-w64-mingw32-gcc
	TARG_XTRA_OPTS="--host=x86_64-w64-mingw32"
elif [ ${OSVER:0:10} == MINGW32_NT ]; then
	export lt_cv_sys_max_cmd_len=8000
	export CC=i686-w64-mingw32-gcc
	TARG_XTRA_OPTS="--host=i686-w64-mingw32"
fi

BINUTILS_VER=2.30
SOURCE=http://ftpmirror.gnu.org/binutils/binutils-$BINUTILS_VER.tar.bz2

if [ ! -f stamps/binutils-download ]; then
	echo Downloading Binutils $BINUTILS_VER. Please wait.
	wget "${SOURCE}" -O "tarballs/$(basename ${SOURCE})"
	touch stamps/binutils-download
fi

if [ ! -f stamps/binutils-extract ]; then
	mkdir -p binutils-{build,source}
	tar -xf tarballs/$(basename${SOURCE}) -C binutils-source --strip1
	touch stamps/binutils-extract
fi

if [ ! -f stamps/binutils-configure ]; then
	pushd binutils-source
	..binutils-source/configure \
	--prefix="$N64/TARGET_ALIAS" \
	--with-lib-path="$N64/lib" \
	--target="$TARGET" --with-arch=vr4300 \
	--program-prefix="$TARGET-" \
	--enable-64-bit-bfd \
    --enable-plugins \
    --enable-shared \
    --disable-gold \
    --disable-multilib \
    --disable-nls \
    --disable-rpath \
    --disable-static \
    --disable-werror\
    $TARG_XTRA_OPTS
    popd
    
    touch stamps/binutils-configure
fi

if [ ! -f stamps/binutils-build ]; then
	pushd binutils-build
	make -j${numproc}
	popd
	
	touch stamps/binutils-build
fi

if [ ! -f stamps/binutils-install ]; then
	pushd binutild-build
	sudo checkinstall --pkgversion 2.30 --pkgname binutils-mips-n64 --install=no make install strip
	cp *.deb ../
	popd
	
	touch stamps/binutils-install
fi

if [ ! -f stamps/binutils-clean]; then
	pushd binutils-build
	make distclean -j${numproc}
	popd
	
	touch stamps/binutils-clean
fi

exit 0
