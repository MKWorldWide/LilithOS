#!/bin/bash
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# build_freshtomato.sh – Automated FreshTomato Build for Netgear R7000P
# Quantum-detailed, production-grade automation script
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# 📋 Quantum Documentation:
#   - Automates the full build process for FreshTomato firmware (R7000P)
#   - Designed for use inside the provided Docker container
#   - Outputs firmware to /home/builder/firmware_build/freshtomato/bin
#
# 🧩 Feature Context:
#   - Used for reproducible, hands-off firmware builds
#   - Can be extended for CI/CD or other routers
#
# 🧷 Dependency Listings:
#   - Requires Dockerfile-provided build environment
#   - Relies on git, make, and all build-essential tools
#
# 💡 Usage Example:
#   $ ./build_freshtomato.sh
#
# ⚡ Performance Considerations:
#   - Uses all available CPU cores for fastest build
#
# 🔒 Security Implications:
#   - Runs as non-root inside container
#   - No network access after clone (unless menuconfig is used)
#
# 📜 Changelog:
#   - 2024-06-30: Initial quantum-detailed automation script
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set -euo pipefail

# ━━━━━ VARIABLES ━━━━━
DEVICE="netgear_r7000p"
FIRMWARE="freshtomato"
WORKDIR="$HOME/firmware_build"
REPO="https://github.com/Jackysi/AdvancedTomato.git"

# ━━━━━ PREPARE BUILD DIR ━━━━━
echo "[INFO] Creating build directory: $WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# ━━━━━ CLONE REPO ━━━━━
if [ ! -d "$FIRMWARE" ]; then
  echo "[INFO] Cloning FreshTomato repo..."
  git clone "$REPO" "$FIRMWARE"
else
  echo "[INFO] Repo already cloned. Pulling latest changes..."
  cd "$FIRMWARE"
  git pull
  cd ..
fi
cd "$FIRMWARE"

# ━━━━━ CONFIGURE FEATURES ━━━━━
# If a default config exists, use it. Otherwise, run menuconfig interactively.
if [ -f ".config.$DEVICE" ]; then
  echo "[INFO] Using default config for $DEVICE"
  cp ".config.$DEVICE" .config
else
  echo "[INFO] No default config found. Launching menuconfig (interactive)..."
  make menuconfig
fi

# ━━━━━ BUILD FIRMWARE ━━━━━
echo "[INFO] Starting firmware build..."
make -j$(nproc)

# ━━━━━ OUTPUT ━━━━━
OUTPUT_DIR="$(pwd)/bin"
echo "[SUCCESS] Firmware build complete!"
echo "[INFO] Check output files in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"

# ━━━━━ FLASHING INSTRUCTIONS ━━━━━
echo "\n[INFO] To flash, use Netgear web UI or TFTP recovery."
echo "      Rename output file to firmware.chk if needed."
echo "      See project documentation for post-flash steps." 