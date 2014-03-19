#!/bin/sh

pkgversion=hg
pkgname=physfs
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

    rm -rf $pkgdir/build
    mkdir $pkgdir/build
    cd $pkgdir/build
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DPHYSFS_BUILD_TEST=OFF \
        -DPHYSFS_BUILD_SHARED=OFF \
        -DMACOSX=FALSE \
        ..
    make -j4 || exit

    mkdir -p $pkgdir/libs/
    mv $pkgdir/build/libphysfs.a $pkgdir/libs/libphysfs_$1.a
}

bundle() {
    echo "Lipoing libraries..."
    mkdir -p $iosoutdir/lib
    $ARM_DEV_CMD lipo -create $pkgdir/libs/libphysfs_*.a -output $iosoutdir/lib/libphysfs.a

    headers="$pkgdir/src/physfs.h"
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


