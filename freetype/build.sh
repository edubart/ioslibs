#!/bin/sh

pkgversion=2.5.3
pkgname=freetype
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
    ../configure \
        --host=$HOST \
        --target=$1-apple-darwin11 \
        --disable-shared --enable-static \
        --without-bzip2
    make -j4 || exit

    mkdir -p $pkgdir/libs/
    mv $pkgdir/build/.libs/libfreetype.a $pkgdir/libs/libfreetype_$1.a
}

bundle() {
    echo "Lipoing libraries..."
    mkdir -p $iosoutdir/lib
    $ARM_DEV_CMD lipo -create $pkgdir/libs/libfreetype_*.a -output $iosoutdir/lib/libfreetype.a

    mkdir -p $iosoutdir/include
    cp -r $pkgdir/include $iosoutdir/include/freetype2
}

extract
compile_arch i386
compile_arch x86_64
compile_arch armv7s
compile_arch arm64
compile_arch armv7
bundle


