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

APP_ABI=(armeabi-v7a x86 arm64-v8a)

BASE_PATH=$(
	cd "$(dirname $0)"
	pwd
)
SSL_PATH="$BASE_PATH/openssl"
BUILD_PATH="$BASE_PATH/build"

checkExitCode() {
	if [ $1 -ne 0 ]; then
		echo "Error building openssl library"
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
rm -rf $BUILD_PATH/openssl
safeMakeDir $BUILD_PATH/openssl

## Build OpenSSL

# compile $1 ABI $2 SYSROOT $3 TOOLCHAIN $4 MACHINE $5 SYSTEM $6 ARCH $7 CROSS_COMPILE
# http://wiki.openssl.org/index.php/Android
# http://doc.qt.io/qt-5/opensslsupport.html
compile() {
	cd $SSL_PATH
	ABI=$1
	ARCH=$2
	TOOLCHAIN=$3
	TOOLCHAIN_2=$4
	# https://android.googlesource.com/platform/ndk/+/ics-mr0/docs/STANDALONE-TOOLCHAIN.html
	export API=23
	export PATH=$TOOLCHAIN:$TOOLCHAIN_2:$PATH
	safeMakeDir $BUILD_PATH/openssl/$ABI
	checkExitCode $?
	./Configure $ARCH --prefix=$BUILD_PATH/openssl/$ABI --openssldir=$BUILD_PATH/openssl/$ABI -D__ANDROID_API__=23
	checkExitCode $?
	# clean
	make clean
	checkExitCode $?
	# make
	make -j4 depend
	checkExitCode $?
	make -j4 all
	checkExitCode $?
	# install
	make install
	checkExitCode $?
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
		compile $abi "android-arm" "$NDK_ROOT/toolchains/llvm/prebuilt/$host-x86_64/bin" "$NDK_ROOT/toolchains/arm-linux-androideabi-4.9/prebuilt/$host-x86_64/bin"
		;;
	x86)
		compile $abi "android-x86" "$NDK_ROOT/toolchains/llvm/prebuilt/$host-x86_64/bin" "$NDK_ROOT/toolchains/x86-4.9/prebuilt/$host-x86_64/bin"
		;;
	arm64-v8a)
		compile $abi "android-arm64" "$NDK_ROOT/toolchains/llvm/prebuilt/$host-x86_64/bin" "$NDK_ROOT/toolchains/aarch64-linux-android-4.9/prebuilt/$host-x86_64/bin"
		;;
	*)
		echo "Error APP_ABI"
		exit 1
		;;
	esac
done

cd $BASE_PATH
exit 0
