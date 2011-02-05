#!/bin/sh
set -ex
git clean -dfx

rm -rf output
mkdir -p output

xcodebuild -activetarget build

cp -r $WORKSPACE/build/Release-iphoneos output/libDecafNinja
zip -r output/libDecafNinja.zip output/libDecafNinja
rm -rf output/libDecafNinja

doxygen doxygen.config
