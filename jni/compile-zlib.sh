#!/bin/bash
# Compile curl & openssl & zlib for android with NDK.
# Copyright (C) 2018  shishuo <shishuo365@126.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

APP_ABI=(armeabi-v7a x86 arm64-v8a x86-64)

BASE_PATH=$(
	cd "$(dirname $0)"
	pwd
)
ZLIB_PATH="$BASE_PATH/zlib"
BUILD_PATH="$BASE_PATH/build"

checkExitCode() {
	if [ $1 -ne 0 ]; then
		echo "Error building zlib library"
		cd $BASE_PATH
		exit $1
	fi
}
safeMakeDir() {
	if [ ! -x "$1" ]; then
		mkdir -p "$1"
	fi
}

## Android NDK
export NDK_ROOT="$NDK_ROOT"

if [ -z "$NDK_ROOT" ]; then
	echo "Please set your NDK_ROOT environment variable first"
	exit 1
fi

## Clean build directory
rm -rf $BUILD_PATH/zlib
safeMakeDir $BUILD_PATH/zlib

## Build zlib

# backup config
cp $ZLIB_PATH/configure $ZLIB_PATH/configure.bak
checkExitCode $?

compatibleWithAndroid() {
	sed 's/case \"$uname\" in/case "_" in/' $ZLIB_PATH/configure >$ZLIB_PATH/configure.temp
	mv $ZLIB_PATH/configure.temp $ZLIB_PATH/configure
	chmod 755 $ZLIB_PATH/configure
}

# compile $1 ABI $2 SYSROOT $3 TOOLCHAIN $4 TARGET $5 CFLAGS
compile() {
	cd $ZLIB_PATH
	ABI=$1
	SYSROOT=$2
	TOOLCHAIN=$3
	TARGET=$4
	CFLAGS=$5
	# https://android.googlesource.com/platform/ndk/+/ics-mr0/docs/STANDALONE-TOOLCHAIN.html
	export API=23
	export CC=$TOOLCHAIN/$TARGET$API-clang
	export AS=$CC
	export AR=$TOOLCHAIN/llvm-ar
	export LD=$TOOLCHAIN/ld
	export RANLIB=$TOOLCHAIN/llvm-ranlib
	export STRIP=$TOOLCHAIN/llvm-strip
	export CFLAGS="-I$SYSROOT/usr/include --sysroot=$SYSROOT $CFLAGS"
	# zlib configure
	export CROSS_PREFIX="$TOOLCHAIN/$TARGET-"
	# config
	safeMakeDir $BUILD_PATH/zlib/$ABI
	compatibleWithAndroid
	./configure --prefix=$BUILD_PATH/zlib/$ABI
	checkExitCode $?
	# clean
	make clean
	checkExitCode $?
	# make
	make -j4
	checkExitCode $?
	# install
	make install
	checkExitCode $?
	make clean
	cd $BASE_PATH
}

# check system
host=$(uname | tr 'A-Z' 'a-z')
if [ $host = "darwin" ] || [ $host = "linux" ]; then
	echo "system: $host"
else
	echo "unsupport system, only support Mac OS X and Linux now."
	exit 1
fi

for abi in ${APP_ABI[*]}; do
	case $abi in
	armeabi-v7a)
		# https://gcc.gnu.org/onlinedocs/gcc/ARM-Options.html#ARM-Options
		compile $abi "$NDK_ROOT/toolchains/llvm/prebuilt/$host-x86_64/sysroot" "$NDK_ROOT/toolchains/llvm/prebuilt/$host-x86_64/bin" "armv7a-linux-androideabi" "-march=armv7-a -mfloat-abi=softfp -mfpu=neon"
		;;
	x86)
		# http://gcc.gnu.org/onlinedocs/gcc/x86-Options.html
		compile $abi "$NDK_ROOT/toolchains/llvm/prebuilt/$host-x86_64/sysroot" "$NDK_ROOT/toolchains/llvm/prebuilt/$host-x86_64/bin" "i686-linux-android" "-march=i686"
		;;
	arm64-v8a)
		# https://gcc.gnu.org/onlinedocs/gcc/AArch64-Options.html#AArch64-Options
		compile $abi "$NDK_ROOT/toolchains/llvm/prebuilt/$host-x86_64/sysroot" "$NDK_ROOT/toolchains/llvm/prebuilt/$host-x86_64/bin" "aarch64-linux-android" "-march=armv8-a"
		;;
	x86-64)
		# http://gcc.gnu.org/onlinedocs/gcc/x86-Options.html
		compile $abi "$NDK_ROOT/toolchains/llvm/prebuilt/$host-x86_64/sysroot" "$NDK_ROOT/toolchains/llvm/prebuilt/$host-x86_64/bin" "x86_64-linux-android" "-march=x86-64"
		;;
	*)
		echo "Error APP_ABI"
		exit 1
		;;
	esac
done

# resume config
mv $ZLIB_PATH/configure.bak $ZLIB_PATH/configure
checkExitCode $?

cd $BASE_PATH
exit 0
