#!/bin/sh

pkgversion=6.2.1
pkgname=Chipmunk
pkgdir=`pwd`/$pkgname-$pkgversion
pkgfile=`pwd`/$pkgname-$pkgversion.tgz
iosoutdir=`pwd`/ios

rm -rf $iosoutdir $pkgdir
tar xzf $pkgfile
cd $pkgdir
patch -Np1 < ../mybuild.patch
cd xcode
./iphonestatic.command

mkdir -p $iosoutdir/include/chipmunk
mkdir -p $iosoutdir/lib
cp Chipmunk-iPhone/libChipmunk-iPhone.a $iosoutdir/lib/libchipmunk.a
cp -R Chipmunk-iPhone/*.h $iosoutdir/include/chipmunk/
cp -R Chipmunk-iPhone/constraints $iosoutdir/include/chipmunk/
