#!/bin/sh
#

: ${LUAJIT_VERSION:=2.0.3}
: ${IPHONE_SDKVERSION:=`xcodebuild -showsdks | grep iphoneos | egrep "[[:digit:]]+\.[[:digit:]]+" -o | tail -1`}
: ${XCODE_ROOT:=`xcode-select -print-path`}

: ${SRCDIR:=`pwd`/LuaJIT-$LUAJIT_VERSION}
: ${IOSBUILDDIR:=`pwd`/ios/build}
: ${OSXBUILDDIR:=`pwd`/osx/build}
: ${PREFIXDIR:=`pwd`/ios/prefix}
: ${IOSFRAMEWORKDIR:=`pwd`/ios/framework}
: ${OSXFRAMEWORKDIR:=`pwd`/osx/framework}
: ${COMPILER:="clang"}

: ${LUA_VERSION:=5.1.5}

#===============================================================================

ARM_DEV_CMD="xcrun --sdk iphoneos"
SIM_DEV_CMD="xcrun --sdk iphonesimulator"

ARMV6_LIB=$IOSBUILDDIR/lib_luajit_armv6.a
ARMV7_LIB=$IOSBUILDDIR/lib_luajit_armv7.a
ARMV7S_LIB=$IOSBUILDDIR/lib_luajit_armv7s.a
I386_LIB=$IOSBUILDDIR/lib_luajit_i386.a
X86_64_LIB=$IOSBUILDDIR/lib_luajit_x86_64.a

IOSSYSROOT=$XCODE_ROOT/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$IPHONE_SDKVERSION.sdk
IOSSIMSYSROOT=$XCODE_ROOT/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator$IPHONE_SDKVERSION.sdk

FILES_INC="$SRCDIR/src/lua.h $SRCDIR/src/lualib.h $SRCDIR/src/lauxlib.h $SRCDIR/src/luaconf.h $SRCDIR/src/lua.hpp $SRCDIR/src/luajit.h"

EXTRA_CFLAGS="-DLUA_USE_DLOPEN"

compile_framework() {
	FRAMEWORK_BUNDLE=$1/luajit.framework
	FRAMEWORK_VERSION=A
	FRAMEWORK_NAME=luajit

	shift;

	rm -rf $FRAMEWORK_BUNDLE

	mkdir -p $FRAMEWORK_BUNDLE
	mkdir -p $FRAMEWORK_BUNDLE/Versions
	mkdir -p $FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION
	mkdir -p $FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION/Resources
	mkdir -p $FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION/Headers
	mkdir -p $FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION/Documentation

	ln -s $FRAMEWORK_VERSION               $FRAMEWORK_BUNDLE/Versions/Current
	ln -s Versions/Current/Headers         $FRAMEWORK_BUNDLE/Headers
	ln -s Versions/Current/Resources       $FRAMEWORK_BUNDLE/Resources
	ln -s Versions/Current/Documentation   $FRAMEWORK_BUNDLE/Documentation
	ln -s Versions/Current/$FRAMEWORK_NAME $FRAMEWORK_BUNDLE/$FRAMEWORK_NAME

	FRAMEWORK_INSTALL_NAME=$FRAMEWORK_BUNDLE/Versions/$FRAMEWORK_VERSION/$FRAMEWORK_NAME

	echo "Lipoing library into $FRAMEWORK_INSTALL_NAME..."
	$ARM_DEV_CMD lipo -create $@ -output "$FRAMEWORK_INSTALL_NAME" || exit

	echo "Framework: Copying includes..."
	cp -r $FILES_INC $FRAMEWORK_BUNDLE/Headers/

	echo "Framework: Creating plist..."
	cat > $FRAMEWORK_BUNDLE/Resources/Info.plist <<EOF
		<?xml version="1.0" encoding="UTF-8"?>
		<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
		<plist version="1.0">
		<dict>
		<key>CFBundleDevelopmentRegion</key>
		<string>English</string>
		<key>CFBundleExecutable</key>
		<string>${FRAMEWORK_NAME}</string>
		<key>CFBundleIdentifier</key>
		<string>org.luajit</string>
		<key>CFBundleInfoDictionaryVersion</key>
		<string>6.0</string>
		<key>CFBundlePackageType</key>
		<string>FMWK</string>
		<key>CFBundleSignature</key>
		<string>????</string>
		<key>CFBundleVersion</key>
		<string>${FRAMEWORK_CURRENT_VERSION}</string>
		</dict>
		</plist>
EOF
}


mkdir -p $IOSBUILDDIR


compile_arch() {
	echo compiling $1 ...
	ISDKF="-arch $1 -isysroot $IOSSYSROOT $EXTRA_CFLAGS"
	make -C $SRCDIR/src clean libluajit.a HOST_CC="$COMPILER -m32 -arch i386" CROSS="$ARM_DEV_CMD " TARGET_FLAGS="$ISDKF" TARGET_SYS=iOS
	cp $SRCDIR/src/libluajit.a $IOSBUILDDIR/lib_luajit_$1.a
}

compile_sim() {
	echo compiling sim $1 ...
	ISDKF="-arch $1 -isysroot $IOSSIMSYSROOT $EXTRA_CFLAGS"
	make -C $SRCDIR/src clean libluajit.a HOST_CC="$COMPILER -m32 -arch $1" CROSS="$SIM_DEV_CMD " TARGET_FLAGS="$ISDKF" TARGET_SYS=iOS
	cp $SRCDIR/src/libluajit.a $IOSBUILDDIR/lib_luajit_$1.a
}

compile_sim i386
compile_arch armv7
compile_arch armv7s

#compile_arch arm64
#compile_sim x86_64

echo build ios framework ...
compile_framework $IOSFRAMEWORKDIR $ARMV6_LIB $ARMV7_LIB $ARMV7S_LIB $I386_LIB $X86_64_LIB

echo framework will be at $IOSFRAMEWORKDIR
echo success!
