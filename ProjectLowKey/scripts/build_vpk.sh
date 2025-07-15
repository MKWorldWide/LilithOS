#!/bin/bash
# Build ProjectLowKey VPK using VitaSDK/CMake

set -e
mkdir -p build
cd build
cmake ..
make
cd ..
echo "VPK built at build/ProjectLowKey.vpk"