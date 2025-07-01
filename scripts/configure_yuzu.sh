#!/bin/bash
# Quantum-detailed Yuzu configuration script for LilithOS Switch Mod Testing
#
# 📋 Quantum Documentation: This script configures Yuzu to use the LilithOS virtual SD card for Switch OS mod testing in WSL.
# 🧩 Feature Context: Ensures Yuzu emulator recognizes the modded SD card structure for advanced mod and CFW testing.
# 🧷 Dependency Listings: Requires Yuzu (Flatpak), WSL, and the LilithOS virtual SD card structure.
# 💡 Usage Example: ./configure_yuzu.sh (run from /home/lilithos/)
# ⚡ Performance Considerations: Symlinks for fast access; no file duplication.
# 🔒 Security Implications: No host system changes; all actions are user-local.
# 📜 Changelog: Initial version 2025-06-30

set -e

# Set environment variables
export LILITHOS_PATH="/home/lilithos"
export VIRTUAL_SD_PATH="$LILITHOS_PATH/virtual_sd"

# Find Yuzu Flatpak config directory
YUZU_CONFIG_DIR="$HOME/.var/app/org.yuzu_emu.yuzu/config/yuzu"

# Create config directory if missing
mkdir -p "$YUZU_CONFIG_DIR"

# Symlink or copy virtual SD card to Yuzu's NAND path
YUZU_NAND_PATH="$YUZU_CONFIG_DIR/nand/user"
mkdir -p "$YUZU_NAND_PATH"

# Symlink SD card root (if not already linked)
if [ ! -L "$YUZU_NAND_PATH/sdmc" ]; then
    ln -sfn "$VIRTUAL_SD_PATH" "$YUZU_NAND_PATH/sdmc"
fi

echo "[INFO] Yuzu configured to use LilithOS virtual SD card."
echo "[INFO] To launch Yuzu, run: flatpak run org.yuzu_emu.yuzu"
echo "[INFO] Your modded SD card is available in the emulator."

echo "[NOTE] Run this script from /home/lilithos/ for correct path resolution."

# Usage instructions
cat <<EOF

---
Quantum Usage Guide:
1. Launch Yuzu: flatpak run org.yuzu_emu.yuzu
2. Add Switch game ROMs via Yuzu GUI.
3. The virtual SD card (with LilithOS/Atmosphere mods) is auto-mounted as /sdmc.
4. Test audio injection and CFW integration in emulated environment.
---
EOF 