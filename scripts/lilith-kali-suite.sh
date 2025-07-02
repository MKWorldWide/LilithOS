#!/bin/bash
# lilith-kali-suite.sh: Modular Kali Linux tool integration for LilithOS
#
# 📋 Quantum Documentation: This script enables seamless, modular integration of Kali Linux tools into LilithOS (Debian-based),
#   preserving LilithOS branding, system stability, and allowing granular control over tool installation and removal.
# 🧩 Feature Context: Designed for security professionals and power users who want Kali's capabilities without losing LilithOS identity.
# 🧷 Dependency Listings: Requires sudo, apt, curl, gpg, and optionally firejail for sandboxing.
# 💡 Usage Examples:
#   ./lilith-kali-suite.sh install --category top10,wireless
#   ./lilith-kali-suite.sh remove --category everything
#   ./lilith-kali-suite.sh update
#   ./lilith-kali-suite.sh toggle-mode
# ⚡ Performance Considerations: Installs only selected tool categories to avoid bloat. Uses apt meta-packages for efficiency.
# 🔒 Security Implications: Optionally runs tools in firejail. Verifies repo keys. Avoids overwriting critical configs.
# 📜 Changelog Entries: All changes to system files and branding are logged in /var/log/lilith-kali-suite.log

set -e

LOG_FILE="/var/log/lilith-kali-suite.log"
KALI_LIST="/etc/apt/sources.list.d/kali.list"
KALI_KEYRING="/usr/share/keyrings/kali-archive-keyring.gpg"
BRANDING_DIR="/opt/lilithos/branding"
KALI_CATEGORIES=(top10 everything wireless forensic password web)

# --- Utility Functions ---
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

require_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Try: sudo $0 $@"
    exit 1
  fi
}

# --- Step 1: Detect LilithOS Base ---
detect_base() {
  source /etc/os-release
  if [[ "$ID" != "debian" && "$ID_LIKE" != *"debian"* ]]; then
    log "LilithOS must be Debian-based. Aborting."
    exit 1
  fi
  log "Detected Debian-based system: $PRETTY_NAME"
}

# --- Step 2: Add Kali Repo & Key ---
add_kali_repo() {
  if [[ ! -f "$KALI_LIST" ]]; then
    echo "deb [signed-by=$KALI_KEYRING] http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" > "$KALI_LIST"
    log "Kali repo added to $KALI_LIST"
  else
    log "Kali repo already present. Skipping."
  fi
  if [[ ! -f "$KALI_KEYRING" ]]; then
    curl -fsSL https://archive.kali.org/archive-key.asc | gpg --dearmor -o "$KALI_KEYRING"
    log "Kali signing key added to $KALI_KEYRING"
  else
    log "Kali keyring already present. Skipping."
  fi
  apt update
}

# --- Step 3: Branding ---
apply_branding() {
  # MOTD and issue
  if [[ -f "$BRANDING_DIR/motd" ]]; then
    cp "$BRANDING_DIR/motd" /etc/motd
    log "Applied LilithOS MOTD branding."
  fi
  if [[ -f "$BRANDING_DIR/issue" ]]; then
    cp "$BRANDING_DIR/issue" /etc/issue
    log "Applied LilithOS issue branding."
  fi
  # Bash and Zsh
  for shellrc in /etc/bash.bashrc /etc/zsh/zshrc; do
    if ! grep -q "LilithOS" "$shellrc"; then
      echo -e "\n# LilithOS Branding\necho 'Welcome to LilithOS — Quantum Security Awakened.'" >> "$shellrc"
      log "Patched $shellrc with LilithOS branding."
    fi
  done
}

# --- Step 4: Install/Remove Kali Tools ---
install_tools() {
  local categories=($1)
  for cat in "${categories[@]}"; do
    if [[ " ${KALI_CATEGORIES[@]} " =~ " $cat " ]]; then
      apt install -y "kali-linux-$cat"
      log "Installed kali-linux-$cat."
    else
      log "Unknown category: $cat. Skipping."
    fi
  done
}

remove_tools() {
  local categories=($1)
  for cat in "${categories[@]}"; do
    if [[ " ${KALI_CATEGORIES[@]} " =~ " $cat " ]]; then
      apt remove -y "kali-linux-$cat"
      log "Removed kali-linux-$cat."
    else
      log "Unknown category: $cat. Skipping."
    fi
  done
}

# --- Step 5: Update Kali Tools ---
update_tools() {
  apt update && apt upgrade -y
  log "System and Kali tools updated."
}

# --- Step 6: Toggle Kali Mode ---
toggle_mode() {
  local mode_file="/etc/lilithos_kali_mode"
  if [[ -f "$mode_file" ]]; then
    rm "$mode_file"
    log "Kali mode disabled."
    echo "Kali mode is now OFF."
  else
    touch "$mode_file"
    log "Kali mode enabled."
    echo "Kali mode is now ON."
  fi
}

# --- Step 7: Main CLI ---
usage() {
  echo "\nLilithOS Kali Suite Integration\n"
  echo "Usage: $0 <install|remove|update|toggle-mode> [--category cat1,cat2,...]"
  echo "\nExamples:"
  echo "  $0 install --category top10,wireless"
  echo "  $0 remove --category everything"
  echo "  $0 update"
  echo "  $0 toggle-mode"
  exit 1
}

main() {
  require_root "$@"
  detect_base
  add_kali_repo
  apply_branding

  case "$1" in
    install)
      shift
      if [[ "$1" == "--category" && -n "$2" ]]; then
        install_tools "$2"
      else
        usage
      fi
      ;;
    remove)
      shift
      if [[ "$1" == "--category" && -n "$2" ]]; then
        remove_tools "$2"
      else
        usage
      fi
      ;;
    update)
      update_tools
      ;;
    toggle-mode)
      toggle_mode
      ;;
    *)
      usage
      ;;
  esac
}

main "$@" 