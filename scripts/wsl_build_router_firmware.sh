#!/bin/bash
# LilithOS Router OS - WSL Automated Build Script
# Builds DD-WRT-based custom firmware for Netgear Nighthawk R7000P
# Author: LilithOS Development Team
# Version: 1.0.0

set -e

# ===============================
# 1. Update and Install Dependencies
# ===============================
echo "[STEP] Updating package lists and installing dependencies..."
sudo apt update
sudo apt install -y git make gcc g++ flex bison pkg-config wget patch build-essential libncurses5-dev libssl-dev bc xz-utils p7zip-full

echo "[SUCCESS] Dependencies installed."

# ===============================
# 2. Set Working Directory
# ===============================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/routerOS/build"

cd "$BUILD_DIR"
echo "[INFO] Working directory: $BUILD_DIR"

# ===============================
# 3. Ensure Build Script is Executable
# ===============================
chmod +x build_script.sh

echo "[SUCCESS] Build script is executable."

# ===============================
# 4. Run the Build Script
# ===============================
echo "[STEP] Starting firmware build..."
./build_script.sh

# ===============================
# 5. Output Location
# ===============================
echo "[SUCCESS] Build complete!"
echo "[INFO] Firmware output: $BUILD_DIR/build_output/output/lilithos_router_r7000p_1.0.0.bin"
echo "[INFO] Package info: $BUILD_DIR/build_output/output/package_info.txt" 