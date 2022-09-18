#!/usr/bin/env bash

# Prepare the zip to send to a second computer
# (becauses crashes and samples will be automatically symbolicated if the dSYMs exist in the system)
rm -rf Payload
mkdir Payload
cp -r Binaries/* Payload/
cp create_crashes_samples_spindumps.sh Payload/
zip -1 -r Payload.zip Payload
rm -rf Payload
