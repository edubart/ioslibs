#!/bin/sh

pkgversion=5.1.5
pkgname=lua
pkgdir=`pwd`/$pkgname-$pkgversion
pkgfile=`pwd`/$pkgname-$pkgversion.tar.gz
iosoutdir=`pwd`/ios
XCODE_ROOT=`xcode-select -print-path`
IPHONE_SDKVERSION=`xcodebuild -showsdks | grep iphoneos | egrep "[[:digit:]]+\.[[:digit:]]+" -o | tail -1`
ARM_DEV_CMD="xcrun --sdk iphoneos"
SIM_DEV_CMD="xcrun --sdk iphonesimulator"
HOST=x86_64-apple-darwin13

EXTRA_FLAGS="-miphoneos-version-min=6.0"

extract() {
    rm -rf $iosoutdir $pkgdir
    tar xzf $pkgfile
}

configure_exports() {
    if [[ $1 = arm* ]]; then
        DEV_CMD=$ARM_DEV_CMD
    else
        DEV_CMD=$SIM_DEV_CMD
    fi
    export CXX="$DEV_CMD clang++ -arch $1 $EXTRA_FLAGS"
    export CC="$DEV_CMD clang -arch $1 $EXTRA_FLAGS"
    export CXXPP="$CXX -E"
    export CPP="$CC -E"
    export LD="$DEV_CMD ld"
    export AR="$DEV_CMD ar"
    export AS="$DEV_CMD as"
    export NM="$DEV_CMD nm"
    export RANLIB="$DEV_CMD ranlib"
    export STRIP="$DEV_CMD strip"
}

compile_arch() {
    echo "Compiling for $1 ..."
    configure_exports $1
    make -j1 -C $pkgdir/src \
        CC="$CC" \
        AR="$AR rcu" \
        RANLIB="$RANLIB" \
        STRIP="$STRIP" \
        clean liblua.a

    mkdir -p $pkgdir/libs/
    mv $pkgdir/src/liblua.a $pkgdir/libs/liblua_$1.a
}

bundle() {
    echo "Lipoing libraries..."
    mkdir -p $iosoutdir/lib
    $ARM_DEV_CMD lipo -create $pkgdir/libs/liblua_*.a -output $iosoutdir/lib/liblua.a
    headers="$pkgdir/src/lua.h $pkgdir/src/lualib.h $pkgdir/src/lauxlib.h $pkgdir/src/luaconf.h $pkgdir/etc/lua.hpp"
    mkdir -p $iosoutdir/include
    cp -r $headers $iosoutdir/include/
}

extract
compile_arch i386
compile_arch x86_64
compile_arch armv7s
compile_arch arm64
compile_arch armv7
bundle


