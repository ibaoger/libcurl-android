# cURL for Android

Compile curl, openssl, zlib with Android NDK.

Support system:
+ Mac OS X
+ Linux 64-bit

## Before build

Download android ndk-r13b from [here](https://developer.android.com/ndk/downloads/),
and set NDK_ROOT in your system environment variable.

For example:

```
export NDK_ROOT=your_ndk_path
```

Install dependent:

```
autoconf >= 2.57
automake >= 1.7
libtool  >= 1.4.2
GNU m4
nroff
perl
```

## Building

* Clone this repo `git clone https://github.com/shishuo365/libcurl-android.git`
* `cd libcurl-android` and clone submodules `git submodule init && git submodule update`

```
chmod 755 build_for_android.sh
./build_for_android.sh
```

## Binary and Library

```
# cURL
jni/build/curl/*/curl
jni/libs/*/libcurl.a
jni/libs/*/libcurl.so

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
