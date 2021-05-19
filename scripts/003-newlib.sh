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

NEWLIB_VER=3.1.0
SOURCE=http://mirrors.kernel.org/sourceware/newlib/newlib-$NEWLIB_VER.tar.gz

if [ ! -f stamps/newlib-download ]; then
	echo Downloading Newlib $NEWLIB_VER. Please wait.
	wget "${SOURCE}" -O "tarballs/$(basename ${SOURCE})"
	touch stamps/newlib-download
fi

if [ ! -f stamps/newlib-extract ]; then
	mkdir -p newlib-{build,source}
	tar -xf tarballs/$(basename${SOURCE}) -C newlib-source --strip1
	touch stamps/newlib-extract
fi

if [ ! -f stamps/newlib-configure ]; then
	pushd newlib-source
	RANLIB_FOR_TARGET="$N64/TARGET_ALIAS"/bin/mips-n64-ranlib \
	CC_FOR_TARGET="$N64/TARGET_ALIAS"/bin/mips-n64-gcc \
	CXX_FOR_TARGET="$N64/TARGET_ALIAS"/bin/mips-n64-g++ \
	AR_FOR_TARGET="$N64/TARGET_ALIAS"/bin/mips-n64-ar \
	CFLAGS_FOR_TARGET="-mabi=32 -ffreestanding -mfix4300 -G 0 -fno-PIC -O2" \
	CXXFLAGS_FOR_TARGET="-mabi=32 -ffreestanding -mfix4300 -G 0 -fno-PIC -O2" \
	../newlib-source/configure \
 	--target="$TARGET" \
 	--prefix="$N64/TARGET_ALIAS" \
	--with-cpu=mips64vr4300 \
	--disable-threads \
 	--disable-libssp \
 	--disable-werror \
 	$TARGET_XTRA_OPTS
    popd
    
    touch stamps/newlib-configure
fi

if [ ! -f stamps/newlib-build ]; then
	pushd newlib-build
	make -j${numproc}
	popd
	
	touch stamps/newlib-build
fi

if [ ! -f stamps/newlib-install ]; then
	pushd newlib-build
	sudo checkinstall --pkgname newlib-mips-64 --install=no make install strip
	cp *.deb ../
	popd
	
	touch stamps/newlib-install
fi

if [ ! -f stamps/newlib-clean]; then
	pushd newlib-build
	make distclean -j${numproc}
	popd
	
	touch stamps/newlib-clean
fi

exit 0


