#!/usr/bin/env bash

mkdir Crashes
mkdir Samples
mkdir Spindumps

rm ~/Library/Logs/DiagnosticReports/CrashingTest*
./CrashingTest
sleep 3 # give the system some time to create the crash report
cp ~/Library/Logs/DiagnosticReports/CrashingTest* Crashes/
mv Crashes/CrashingTest* Crashes/single-target-crash.ips

rm ~/Library/Logs/DiagnosticReports/CrashingInAnotherTargetTest*
./CrashingInAnotherTargetTest
sleep 3 # give the system some time to create the crash report
cp ~/Library/Logs/DiagnosticReports/CrashingInAnotherTargetTest* Crashes/
mv Crashes/CrashingInAnotherTargetTest* Crashes/multi-target-crash.ips

./SingleThreadHangingTest&
pid=$!
sleep 1 # give the process some time to start up and hang
sudo sample $pid -f ./Samples/singlethread-sample.txt
sudo spindump $pid -o ./Spindumps/singlethread-spindump.txt
kill -9 $pid

./MultiThreadHangingTest&
pid=$!
sleep 1 # give the process some time to start up and hang
sudo sample $pid -f ./Samples/multithread-sample.txt
sudo spindump $pid -o ./Spindumps/multithread-spindump.txt
kill -9 $pid

./MultiTargetHangingTest&
pid=$!
sleep 1 # give the process some time to start up and hang
sudo sample $pid -f ./Samples/multitarget-sample.txt
sudo spindump $pid -o ./Spindumps/multitarget-spindump.txt
kill -9 $pid

# Create a zip file of the results to send back
zip -1 -r Result.zip Crashes Samples Spindumps
