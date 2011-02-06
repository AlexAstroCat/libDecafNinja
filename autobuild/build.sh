#!/bin/sh
set -ex

rm -rf libDecafNinja libDecafNinja.zip
mkdir libDecafNinja

xcodebuild -activetarget build -sdk iphoneos
xcodebuild -activetarget build -sdk iphonesimulator

lipo -create -output libDecafNinja/libDecafNinja.a build/Release-iphoneos/libDecafNinja.a build/Release-iphonesimulator/libDecafNinja.a 
cp -r Headers libDecafNinja
zip -r libDecafNinja.zip libDecafNinja

$DOXYGEN_PATH doxygen.config
