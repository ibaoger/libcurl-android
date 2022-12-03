# cURL for Android

使用 Android NDK 编译 curl, openssl, zlib。

支持在以下系统中编译:
+ Mac OS X
+ Linux 64-bit

## 编译前的准备工作

从 [这里](https://developer.android.com/ndk/downloads/) 下载 android ndk-r22b 或以上版本，然后在你的编译系统中做以下设置

设置 NDK_ROOT 变量，例如：

```
export NDK_ROOT=android ndk 在你的编译系统中的绝对路径
```

安装编译依赖：

+ **autoconf** >= 2.57
+ **automake** >= 1.7
+ **libtool**  >= 1.4.2
+ GNU m4
+ nroff
+ perl

## 编译

* 克隆项目并更新子模块
```
git clone https://github.com/shishuo365/libcurl-android.git
cd libcurl-android
git submodule init && git submodule update
```

* 编译
```
chmod 755 build_for_android.sh
./build_for_android.sh
```

* 增量编译（用于修改部分代码后的快速编译）
```
sed -i'' 's/make clean/#make clean/' jni/compile-zlib.sh
sed -i'' 's/make clean/#make clean/' jni/compile-openssl.sh
sed -i'' 's/make clean/#make clean/' build_for_android.sh
sed -i'' 's/rm -rf $BUILD_PATH/#rm -rf $BUILD_PATH/' build_for_android.sh
./build_for_android.sh
```

## 可运行程序和动态静态库

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

## 许可

[GPL-2.0](./LICENSE)  
[cURL](https://github.com/curl/curl/blob/master/COPYING)  
[OpenSSL](https://github.com/openssl/openssl/blob/master/LICENSE)  
[zlib](https://github.com/madler/zlib/blob/master/README)  
