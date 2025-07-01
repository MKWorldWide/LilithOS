#!/bin/bash
# Quantum-detailed Automated Audio Injection Test Script for Yuzu/WSL
#
# 📋 Quantum Documentation: This script validates the LilithOS audio injection system in the Yuzu/WSL environment.
# 🧩 Feature Context: Ensures all unlock keys, signals, and patches are present and checks Yuzu logs for audio event triggers.
# 🧷 Dependency Listings: Requires bash, find, grep, and access to Yuzu config/logs and the LilithOS virtual SD card.
# 💡 Usage Example: ./test_audio_injection_yuzu.sh
# ⚡ Performance Considerations: Fast file checks, optional log parsing.
# 🔒 Security Implications: Read-only operations; no modifications.
# 📜 Changelog: Initial version 2025-06-30

set -e

# Paths
SD_ROOT="/home/lilithos/virtual_sd/switch/LilithOS/audio_injection"
YUZU_LOG_DIR="$HOME/.var/app/org.yuzu_emu.yuzu/data/yuzu/logs"

# Required files
KEYS=("primary_unlock.key" "secondary_unlock.key" "tertiary_unlock.key")
SIGNALS=("main_menu_signal.conf" "rain_sound_signal.conf" "bg_music_signal.conf")
PATCHES=("main_menu_patch.conf" "rain_sound_patch.conf" "bg_music_patch.conf")

# Check directory structure
function check_dir_structure() {
  echo "[INFO] Checking audio injection directory structure..."
  for sub in keys signals patches; do
    if [ ! -d "$SD_ROOT/$sub" ]; then
      echo "[ERROR] Missing directory: $SD_ROOT/$sub"; exit 1
    else
      echo "[OK] Found directory: $SD_ROOT/$sub"
    fi
  done
}

# Check required files
function check_files() {
  echo "[INFO] Checking unlock keys..."
  for key in "${KEYS[@]}"; do
    if [ ! -f "$SD_ROOT/keys/$key" ]; then
      echo "[ERROR] Missing unlock key: $key"; exit 1
    else
      echo "[OK] Found unlock key: $key"
    fi
  done
  echo "[INFO] Checking audio signals..."
  for sig in "${SIGNALS[@]}"; do
    if [ ! -f "$SD_ROOT/signals/$sig" ]; then
      echo "[ERROR] Missing audio signal: $sig"; exit 1
    else
      echo "[OK] Found audio signal: $sig"
    fi
  done
  echo "[INFO] Checking audio patches..."
  for patch in "${PATCHES[@]}"; do
    if [ ! -f "$SD_ROOT/patches/$patch" ]; then
      echo "[ERROR] Missing audio patch: $patch"; exit 1
    else
      echo "[OK] Found audio patch: $patch"
    fi
  done
}

# Parse Yuzu logs for audio event triggers
function parse_yuzu_logs() {
  echo "[INFO] Parsing Yuzu logs for audio event triggers..."
  if [ ! -d "$YUZU_LOG_DIR" ]; then
    echo "[WARN] Yuzu log directory not found: $YUZU_LOG_DIR"
    return
  fi
  found=0
  for log in "$YUZU_LOG_DIR"/*.log; do
    if [ -f "$log" ]; then
      echo "[INFO] Scanning $log..."
      grep -E "audio|sound|unlock|injection" "$log" && found=1
    fi
  done
  if [ $found -eq 0 ]; then
    echo "[WARN] No relevant audio/injection events found in Yuzu logs."
  else
    echo "[OK] Audio/injection events detected in Yuzu logs."
  fi
}

# Main
check_dir_structure
check_files
parse_yuzu_logs

echo "[SUMMARY] Audio injection system and Yuzu log checks complete." 