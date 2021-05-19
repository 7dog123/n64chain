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

if [ ! -f stamps/gcc-stage2-download ]; then
	echo Downloading GCC $GCC_VER. Please wait.
	wget "${SOURCE}" -O "tarballs/$(basename ${SOURCE})"
	touch stamps/gcc-stage2-download
fi

if [ ! -f stamps/gcc-stage2-extract ]; then
	mkdir -p gcc-{build,source}
	tar -xf tarballs/$(basename${SOURCE}) -C newlib-source --strip1
	touch stamps/gcc-stage2-extract
fi

if [ ! -f stamps/gcc-stage2-configure ]; then
	pushd gcc-source
	--gcc-stage2-source/configure \
	--prefix="$N64/TARGET_ALIAS" \
	--with-lib-path="$N64/lib" \
	--target="$TARGET" --with-arch=vr4300 \
	--program-prefix="$TARGET-" \
	--enable-language=c,c++
	--with-headers=no \
	--with-newlib \
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
    
    touch stamps/gcc-stage2-configure
fi

if [ ! -f stamps/gcc-stage2-build ]; then
	pushd gcc-build
	make -j${numproc} all-target-libgcc CC_FOR_TARGET=${INSTALL_PATH}/bin/mips-n64-gcc CFLAGS_FOR_TARGET="-mabi=32 -ffreestanding -mfix4300 -G 0 -fno-PIC"
	popd
	
	touch stamps/gcc-stage2-build
fi

echo "" >> ./gcc-source/libgcc/config/mips/t-mips64

if [ ! -f stamps/gcc-stage2-install ]; then
	pushd gcc-stage2-build
	sudo checkinstall --pkgversion 11.1.0 --pkgname gcc-mips-n64 --install=no make install-strip-gcc
	cp *.deb ../
	popd
	
	touch stamps/gcc-stage2-install
fi

if [ ! -f stamps/gcc-stage2-clean]; then
	pushd gcc-stage2-build
	make distclean -j${numproc}
	popd
	
	touch stamps/gcc-stage2-clean
fi

exit 0
