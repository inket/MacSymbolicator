#!/usr/bin/env bash
cd TestProject
rm -rf build
xcodebuild clean archive -configuration Release -alltargets
cd ..

rm -rf Resources/dSYMs/
mkdir -p Resources/dSYMs/
mv TestProject/build/Release/*.dSYM Resources/dSYMs/
mv TestProject/build/Release-iphoneos/*.dSYM Resources/dSYMs/
cp -r Embedded.app.dSYM Resources/dSYMs/

rm -rf Binaries
mkdir -p Binaries
mv /tmp/TestProject.dst/usr/local/bin/* Binaries/
mv /tmp/TestProject.dst/Applications/* Binaries/

rm -rf build

echo "Done!"
echo "Use the binaries in Binaries/ to create your crash logs & samples on macOS."
echo "For iOS, install the .app on your device using Xcode."
echo "The dSYMs are in Resources/dSYMs/"
echo
echo "(Current crash logs & samples will not symbolicate due to the difference in UUIDs)"
