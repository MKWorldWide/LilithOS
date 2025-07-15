#!/bin/bash
# ============================================================================
# build_all_vpks.sh - Quantum-Documented Build Script for LilithOS PS Vita VPKs
#
# This script builds all VPKs in build_all_vpks/ using the native Vitasdk toolchain.
# - Runs CMake and make for all subprojects
# - Collects all .vpk files in dist_vpks/
#
# Usage:
#   ./build_all_vpks.sh
#
# Dependencies: Vitasdk, CMake >= 3.16, make
# Performance: Parallel build supported (edit -j flag as needed)
# Security: No network access required
# ============================================================================
set -e

BUILD_DIR="$(pwd)/build_vpks_native"
DIST_DIR="$(pwd)/dist_vpks"

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$DIST_DIR"

# Configure and build with Vitasdk toolchain
cd "$BUILD_DIR"
echo "[INFO] Configuring CMake for all VPKs with Vitasdk toolchain..."
cmake -DCMAKE_TOOLCHAIN_FILE=../vitasdk-toolchain.cmake ../../
echo "[INFO] Building all VPKs..."
make -j$(sysctl -n hw.ncpu)

# Collect VPKs
find . -name '*.vpk' -exec cp {} "$DIST_DIR" \;
echo "[SUCCESS] All VPKs built and collected in $DIST_DIR" 