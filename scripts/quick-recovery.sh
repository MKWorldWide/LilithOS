#!/bin/bash

# ============================================================================
# LilithOS Quick Recovery Access
# ----------------------------------------------------------------------------
# 📋 Quantum Documentation:
#   - Quick access script for immediate recovery boot
#   - Provides simplified interface for emergency recovery
#   - Integrates with the main recovery boot system
# 🧩 Feature Context:
#   - Part of the enhanced LilithOS recovery system
#   - Designed for quick emergency access without complex options
# 🧷 Dependencies:
#   - recovery-boot.sh script
#   - Root privileges for boot management
# 💡 Usage Example:
#   sudo ./quick-recovery.sh
#   sudo ./quick-recovery.sh emergency
# ⚡ Performance:
#   - Immediate execution with minimal overhead
#   - Fast boot transition to recovery mode
# 🔒 Security:
#   - Requires root privileges
#   - Validates system before boot transition
# 📜 Changelog:
#   - 2024-06-10: Initial creation for quick recovery access
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_VERSION="2.0.0"
RECOVERY_SCRIPT="$(dirname "$0")/recovery-boot.sh"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
    fi
}

# Check if recovery script exists
check_recovery_script() {
    if [[ ! -f "$RECOVERY_SCRIPT" ]]; then
        error "Recovery script not found at: $RECOVERY_SCRIPT"
    fi
    
    if [[ ! -x "$RECOVERY_SCRIPT" ]]; then
        error "Recovery script is not executable: $RECOVERY_SCRIPT"
    fi
}

# Display usage
usage() {
    cat << EOF
LilithOS Quick Recovery v$SCRIPT_VERSION
=======================================

Usage: $0 [OPTION]

OPTIONS:
    emergency    Immediate emergency recovery boot
    repair       Boot into repair mode
    diagnostic   Boot into diagnostic mode
    safe         Boot into safe mode
    help         Show this help message

EXAMPLES:
    sudo $0              # Interactive recovery options
    sudo $0 emergency    # Immediate emergency boot
    sudo $0 repair       # Boot into repair mode

EOF
}

# Main function
main() {
    echo "=========================================="
    echo "LilithOS Quick Recovery v$SCRIPT_VERSION"
    echo "=========================================="
    echo
    
    # Check requirements
    check_root
    check_recovery_script
    
    # Parse arguments
    case "${1:-}" in
        emergency)
            info "Initiating emergency recovery boot..."
            "$RECOVERY_SCRIPT" --emergency
            ;;
        repair)
            info "Initiating repair mode boot..."
            "$RECOVERY_SCRIPT" --repair
            ;;
        diagnostic)
            info "Initiating diagnostic mode boot..."
            "$RECOVERY_SCRIPT" --diagnostic
            ;;
        safe)
            info "Initiating safe mode boot..."
            "$RECOVERY_SCRIPT" --safe
            ;;
        help|--help|-h)
            usage
            exit 0
            ;;
        "")
            info "Starting interactive recovery boot..."
            "$RECOVERY_SCRIPT"
            ;;
        *)
            error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 