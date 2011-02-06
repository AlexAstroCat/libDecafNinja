#!/bin/sh
set -ex

rm -rf output
mkdir -p output/libDecafNinja

xcodebuild -activetarget build -sdk iphoneos
xcodebuild -activetarget build -sdk iphonesimulator

lipo -create -output output/libDecafNinja/libDecafNinja.a build/Release-iphoneos/libDecafNinja.a build/Release-iphonesimulator/libDecafNinja.a 
cp -r Headers output/libDecafNinja
zip -r output/libDecafNinja.zip output/libDecafNinja

$DOXYGEN_PATH doxygen.config
