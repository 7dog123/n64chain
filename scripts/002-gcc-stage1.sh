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


## Apple needs to pretend to be linux
if [ ${OSVER:0:6} == Darwin ]; then
	TARG_XTRA_OPTS="--build=i386-linux-gnu --host=i386-linux-gnu"
elif [ ${OSVER:0:10} == MINGW64_NT ]; then
	export lt_cv_sys_max_cmd_len=8000
	export CC=x86_64-w64-mingw32-gcc
	TARG_XTRA_OPTS="--host=x86_64-w64-mingw32"
elif [ ${OSVER:0:10} == MINGW32_NT ]; then
	export lt_cv_sys_max_cmd_len=8000
	export CC=i686-w64-mingw32-gcc
	TARG_XTRA_OPTS="--host=i686-w64-mingw32"
fi

GCC_VER=11.1.0
SOURCE=http://ftpmirror.gnu.org/gcc/gcc-$GCC_VER/gcc-$GCC_VER.tar.gz

if [ ! -f stamps/gcc-stage1-download ]; then
	echo Downloading GCC $GCC_VER. Please wait.
	wget "${SOURCE}" -O "tarballs/$(basename ${SOURCE})"
	touch stamps/gcc-stage1-download
fi

if [ ! -f stamps/gcc-stage1-extract ]; then
	mkdir -p gcc-{build,source}
	tar -xf tarballs/$(basename${SOURCE}) -C gcc-source --strip1
	touch stamps/gcc-extract
fi

if [ ! -f stamps/gcc-stage1-configure ]; then
	pushd gcc-stage1-source
	--gcc-source/configure \
	--prefix="$N64/TARGET_ALIAS" \
	--with-lib-path="$N64/lib" \
	--target="$TARGET" --with-arch=vr4300 \
	--program-prefix="$TARGET"- \
	--enable-language="c, c++"
	--with-headers=no \
	--without-newlib \
    --with-gnu-as=$"N64/TARGET_ALIAS"/bin/mips-n64-as \
    --with-gnu-ld=$"N64/TARGET_ALIAS"/bin/mips-n64-ld \
    --enable-checking=release \
    --enable-shared \
    --enable-shared-libgcc \
    --disable-decimal-float \
    --disable-gold \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libitm \
    --disable-libquadmath \
    --disable-libquadmath-support \
    --disable-libsanitizer \
    --disable-libssp \
    --disable-libunwind-exceptions \
    --disable-libvtv \
    --disable-multilib \
    --disable-nls \
    --disable-rpath \
    --disable-static \
    --disable-threads \
    --disable-win32-registry \
    --enable-lto \
    --enable-plugin \
    --enable-static \
    --without-included-gettext \
    $TARG_XTRA_OPTS
    popd
    
    touch stamps/gcc-stage1-configure
fi

if [ ! -f stamps/gcc-stage1-build ]; then
	pushd gcc-stage1-build
	make -j${numproc}
	popd
	
	touch stamps/gcc-stage1-build
fi

if [ ! -f stamps/gcc-stage1-install ]; then
	pushd gcc-build
	sudo checkinstall --pkgversion 11.1.0 --pkgname gcc-mips-n64 --install=no make install-strip-gcc
	cp *.deb ../
	popd
	
	touch stamps/gcc-stage1-install
fi

if [ ! -f stamps/gcc-stage1-clean]; then
	pushd gcc-build
	make distclean -j${numproc}
	popd
	
	touch stamps/gcc-stage1-clean
fi

exit 0
