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

APP_ABI=(armeabi-v7a arm64-v8a x86-64)

BASE_PATH=$(
	cd "$(dirname $0)"
	pwd
)
CURL_PATH="$BASE_PATH/jni/curl"
BUILD_PATH="$BASE_PATH/jni/build"

checkExitCode() {
	if [ $1 -ne 0 ]; then
		echo "Error building curl library"
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

# Clean build directory
rm -rf $BUILD_PATH
safeMakeDir $BUILD_PATH

## Build zlib static library (libz.a)
$BASE_PATH/jni/compile-zlib.sh
checkExitCode $?

## Build OpenSSL static library (libssl.a & libcrypto.a)
$BASE_PATH/jni/compile-openssl.sh
checkExitCode $?

## Build cURL

compatibleWithAndroid() {
	# options -V -qversion has removed from gcc-4.9
	sed 's/ -V -qversion//' $CURL_PATH/configure >$CURL_PATH/configure.temp
	mv $CURL_PATH/configure.temp $CURL_PATH/configure
	chmod 755 $CURL_PATH/configure
}

# compile $1 ABI $2 SYSROOT $3 TOOLCHAIN $4 TARGET $5 CFLAGS
compile() {
	cd $CURL_PATH
	ABI=$1
	SYSROOT=$2
	TOOLCHAIN=$3
	TARGET=$4
	CFLAGS=$5
	# https://android.googlesource.com/platform/ndk/+/ics-mr0/docs/STANDALONE-TOOLCHAIN.html
	export API=21
	export CC=$TOOLCHAIN/$TARGET$API-clang
	export CXX=$TOOLCHAIN/$TARGET$API-clang++
	export LD=$TOOLCHAIN/ld
	export AS=$TOOLCHAIN/llvm-as
	export AR=$TOOLCHAIN/llvm-ar
	export RANLIB=$TOOLCHAIN/llvm-ranlib
	export NM=$TOOLCHAIN/llvm-nm
	export STRIP=$TOOLCHAIN/llvm-strip
	export CFLAGS="--sysroot=$SYSROOT $CFLAGS"
	export CPPFLAGS="-I$SYSROOT/usr/include --sysroot=$SYSROOT"
	export LDFLAGS="-L$BUILD_PATH/openssl/$ABI/lib -L$BUILD_PATH/zlib/$ABI/lib"
	export LIBS="-lssl -lcrypto -lc++ -lz"
	#export PKG_CONFIG_PATH="$BUILD_PATH/openssl/$ABI/lib/pkgconfig"
	# config
	autoreconf -fi
	checkExitCode $?
	safeMakeDir $BUILD_PATH/curl/$ABI
	compatibleWithAndroid
	# https://stackoverflow.com/questions/12636536/install-curl-with-openssl
	# https://curl.se/docs/install.html#android
	./configure --host=$TARGET \
		--prefix=$BUILD_PATH/curl/$ABI \
		--with-ssl=$BUILD_PATH/openssl/$ABI \
		--with-zlib=$BUILD_PATH/zlib/$ABI \
		--enable-static \
		--enable-shared \
		--disable-verbose \
		--enable-threaded-resolver \
		--enable-ipv6
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
	# extract *.o from libcurl.a
	safeMakeDir $BASE_PATH/obj/$ABI/curl
	cd $BASE_PATH/obj/$ABI/curl
	$AR -x $BUILD_PATH/curl/$ABI/lib/libcurl.a
	checkExitCode $?
	# extract *.o from libssl.a & libcrypto.a
	safeMakeDir $BASE_PATH/obj/$ABI/openssl
	cd $BASE_PATH/obj/$ABI/openssl
	$AR -x $BUILD_PATH/openssl/$ABI/lib/libssl.a
	$AR -x $BUILD_PATH/openssl/$ABI/lib/libcrypto.a
	checkExitCode $?
	# extract *.o from libz.a
	safeMakeDir $BASE_PATH/obj/$ABI/zlib
	cd $BASE_PATH/obj/$ABI/zlib
	$AR -x $BUILD_PATH/zlib/$ABI/lib/libz.a
	checkExitCode $?
	# combine *.o to libcurl.a
	safeMakeDir $BASE_PATH/libs/$ABI
	cd $BASE_PATH
	$AR -cr $BASE_PATH/libs/$ABI/libcurl.a $BASE_PATH/obj/$ABI/curl/*.o $BASE_PATH/obj/$ABI/openssl/*.o $BASE_PATH/obj/$ABI/zlib/*.o
	checkExitCode $?
	# copy dylib
	cp -f $BUILD_PATH/curl/$ABI/lib/libcurl.so $BASE_PATH/libs/$ABI/libcurl.so
	checkExitCode $?
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
		compile $abi "$NDK_ROOT/toolchains/llvm/prebuilt/$host-x86_64/sysroot" "$NDK_ROOT/toolchains/llvm/prebuilt/$host-x86_64/bin" "armv7a-linux-androideabi" "-march=armv7-a -mfloat-abi=softfp -mfpu=neon -fPIC"
		;;
	x86)
		# http://gcc.gnu.org/onlinedocs/gcc/x86-Options.html
		compile $abi "$NDK_ROOT/toolchains/llvm/prebuilt/$host-x86_64/sysroot" "$NDK_ROOT/toolchains/llvm/prebuilt/$host-x86_64/bin" "i686-linux-android" "-march=i686 -fPIC"
		;;
	arm64-v8a)
		# https://gcc.gnu.org/onlinedocs/gcc/AArch64-Options.html#AArch64-Options
		compile $abi "$NDK_ROOT/toolchains/llvm/prebuilt/$host-x86_64/sysroot" "$NDK_ROOT/toolchains/llvm/prebuilt/$host-x86_64/bin" "aarch64-linux-android" "-march=armv8-a -fPIC"
		;;
	x86-64)
		# http://gcc.gnu.org/onlinedocs/gcc/x86-Options.html
		compile $abi "$NDK_ROOT/toolchains/llvm/prebuilt/$host-x86_64/sysroot" "$NDK_ROOT/toolchains/llvm/prebuilt/$host-x86_64/bin" "x86_64-linux-android" "-march=x86-64 -fPIC"
		;;
	*)
		echo "Error APP_ABI"
		;;
	esac
done

echo "== build success =="
echo "path: $BASE_PATH/libs"
rm -rf $BASE_PATH/obj

cd $BASE_PATH
exit 0
