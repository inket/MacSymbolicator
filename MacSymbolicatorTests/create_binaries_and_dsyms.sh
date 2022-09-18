#!/usr/bin/env bash
cd TestProject
rm -rf build
xcodebuild clean

if ! command -v xcbeautify &> /dev/null; then
    xcodebuild archive -configuration Release -target CrashingTest -target CrashingInAnotherTargetTest
    xcodebuild archive -configuration Release -target SingleThreadHangingTest -target MultiThreadHangingTest -target MultiTargetHangingTest
    xcodebuild archive -configuration Release -target iOSCrashingTest
else
    xcodebuild archive -configuration Release -target CrashingTest -target CrashingInAnotherTargetTest | xcbeautify
    xcodebuild archive -configuration Release -target SingleThreadHangingTest -target MultiThreadHangingTest -target MultiTargetHangingTest | xcbeautify
    xcodebuild archive -configuration Release -target iOSCrashingTest | xcbeautify
fi

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

rm -rf TestProject/build
rm -rf TestProject/DerivedData

./create_payload.sh

echo "Done!"
echo "Use the script and binaries in Payload.zip to automatically create your crash logs, samples and spindumps on macOS."
echo "For iOS, install the .app on your device using Xcode."
echo "The dSYMs are in Resources/dSYMs/"
echo
echo "(Current crash logs & samples will not symbolicate due to the difference in UUIDs)"
