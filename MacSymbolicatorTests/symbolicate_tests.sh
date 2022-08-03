#!/usr/bin/env bash

cd ..
rm -rf build
rm -rf DerivedData
xcodebuild clean build -configuration Release -scheme MacSymbolicatorCLI
cd MacSymbolicatorTests

cli="../DerivedData/MacSymbolicator/Build/Products/Release/MacSymbolicatorCLI"

# Translate the .ips crashes to .crash files
$cli -t "./Resources/Crashes/single-target-crash.ips" -o "./Resources/Crashes/single-target-crash.crash"
$cli -t "./Resources/Crashes/multi-target-crash.ips" -o "./Resources/Crashes/multi-target-crash.crash"
$cli -t "./Resources/Crashes/ios-crash.ips" -o "./Resources/Crashes/ios-crash.crash"

# Symbolicate everything

# Single-target macOS app crash (.ips then .crash)
$cli "./Resources/Crashes/single-target-crash.ips" "./Resources/dSYMs/CrashingTest.dSYM" -o "./Resources/Crashes/single-target-crash_symbolicated.ips"
$cli "./Resources/Crashes/single-target-crash.crash" "./Resources/dSYMs/CrashingTest.dSYM" -o "./Resources/Crashes/single-target-crash_symbolicated.crash"

# Multi-target macOS app crash (.ips then .crash)
$cli "./Resources/Crashes/multi-target-crash.ips" "./Resources/dSYMs/CrashingInAnotherTargetTest.dSYM" "./Resources/dSYMs/AnotherTarget.framework.dSYM" -o "./Resources/Crashes/multi-target-crash_symbolicated.ips"
$cli "./Resources/Crashes/multi-target-crash.crash" "./Resources/dSYMs/CrashingInAnotherTargetTest.dSYM" "./Resources/dSYMs/AnotherTarget.framework.dSYM" -o "./Resources/Crashes/multi-target-crash_symbolicated.crash"

# iOS app crash (.ips then .crash)
$cli "./Resources/Crashes/ios-crash.ips" "./Resources/dSYMs/iOSCrashingTest.app.dSYM" -o "./Resources/Crashes/ios-crash_symbolicated.ips"
$cli "./Resources/Crashes/ios-crash.crash" "./Resources/dSYMs/iOSCrashingTest.app.dSYM" -o "./Resources/Crashes/ios-crash_symbolicated.crash"

# Single-thread sample
$cli "./Resources/Samples/singlethread-sample.txt" "./Resources/dSYMs/SingleThreadHangingTest.dSYM" -o "./Resources/Samples/singlethread-sample_symbolicated.txt"

# Multi-thread sample
$cli "./Resources/Samples/multithread-sample.txt" "./Resources/dSYMs/MultiThreadHangingTest.dSYM" -o "./Resources/Samples/multithread-sample_symbolicated.txt"

echo "Done creating the symbolicated output."
echo "Make sure to check the output files manually before using them as 'expected' output in tests."
