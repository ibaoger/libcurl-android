# cURL for Android

Compile curl, openssl, zlib with Android NDK.

Support for compilation on these systems:
+ Mac OS X
+ Linux 64-bit

## Before build

Download android ndk-r22b or above from [here](https://developer.android.com/ndk/downloads/),
and set NDK_ROOT in your system environment variable.

For example:

```
export NDK_ROOT=your_ndk_path
```

Install dependent:

+ **autoconf** >= 2.57
+ **automake** >= 1.7
+ **libtool**  >= 1.4.2
+ GNU m4
+ nroff
+ perl

## Building

* Clone this repo and submodules
```
git clone https://github.com/ibaoger/libcurl-android.git
cd libcurl-android
git submodule init && git submodule update
```

* Build
```
chmod 755 build_for_android.sh
./build_for_android.sh
```

* Incremental build
```
sed -i'' 's/make clean/#make clean/' jni/compile-zlib.sh
sed -i'' 's/make clean/#make clean/' jni/compile-openssl.sh
sed -i'' 's/make clean/#make clean/' build_for_android.sh
sed -i'' 's/rm -rf $BUILD_PATH/#rm -rf $BUILD_PATH/' build_for_android.sh
./build_for_android.sh
```

## Binary and Library

```
# cURL
jni/build/curl/*/curl
libs/*/libcurl.a
libs/*/libcurl.so

# OpenSSL
jni/build/openssl/*/bin/openssl
jni/build/openssl/*/lib/libssl.a
jni/build/openssl/*/lib/libcrypto.a

# zlib
jni/build/zlib/*/lib/libz.a
jni/build/zlib/*/lib/libz.so
```

## License

[GPL-2.0](./LICENSE)  
[cURL](https://github.com/curl/curl/blob/master/COPYING)  
[OpenSSL](https://github.com/openssl/openssl/blob/master/LICENSE)  
[zlib](https://github.com/madler/zlib/blob/master/README)  
