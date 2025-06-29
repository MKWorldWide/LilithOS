#!/bin/bash

# ============================================================================
# LilithOS Recovery Boot Script
# ----------------------------------------------------------------------------
# 📋 Quantum Documentation:
#   - This script provides direct recovery boot functionality for LilithOS
#   - Allows immediate boot into recovery mode from macOS without manual intervention
#   - Integrates with the boot manager and recovery partition
# 🧩 Feature Context:
#   - Part of the enhanced LilithOS installer with recovery capabilities
#   - Provides emergency access to recovery tools and system repair
# 🧷 Dependencies:
#   - bless command for boot management
#   - diskutil for partition management
#   - Recovery partition must be properly configured
# 💡 Usage Example:
#   sudo ./recovery-boot.sh
#   sudo ./recovery-boot.sh --emergency
#   sudo ./recovery-boot.sh --repair
# ⚡ Performance:
#   - Fast boot selection and immediate reboot
#   - Minimal system impact during boot transition
# 🔒 Security:
#   - Requires root privileges
#   - Validates recovery partition integrity
#   - Secure boot transition with proper authentication
# 📜 Changelog:
#   - 2024-06-10: Initial creation with quantum documentation
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_VERSION="2.0.0"
RECOVERY_PARTITION_NAME="LilithOS_Recovery"
TIMEOUT_SECONDS=10

# Logging
LOG_FILE="/var/log/lilithos_recovery_boot.log"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$LOG_FILE"
}

success() {
    echo -e "${PURPLE}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$LOG_FILE"
}

# Display usage information
usage() {
    cat << EOF
LilithOS Recovery Boot Script v$SCRIPT_VERSION
===============================================

Usage: $0 [OPTIONS]

OPTIONS:
    --emergency    Emergency recovery boot (immediate)
    --repair       Boot into repair mode
    --diagnostic   Boot into diagnostic mode
    --safe         Safe recovery boot
    --help         Display this help message
    --version      Display version information

EXAMPLES:
    sudo $0                    # Interactive recovery boot
    sudo $0 --emergency        # Immediate emergency boot
    sudo $0 --repair           # Boot into repair mode
    sudo $0 --diagnostic       # Boot into diagnostic mode

RECOVERY MODES:
    Emergency: Immediate boot with minimal services
    Repair: System repair and recovery tools
    Diagnostic: System diagnostics and testing
    Safe: Safe mode with basic functionality

EOF
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
    fi
}

# Check system requirements
check_system_requirements() {
    log "Checking system requirements..."
    
    # Check for bless command
    if ! command -v bless &> /dev/null; then
        error "bless command not found. This is required for boot management."
    fi
    
    # Check for diskutil command
    if ! command -v diskutil &> /dev/null; then
        error "diskutil command not found. This is required for partition management."
    fi
    
    log "System requirements check passed"
}

# Find recovery partition
find_recovery_partition() {
    log "Locating recovery partition..."
    
    # Look for LilithOS recovery partition
    RECOVERY_PARTITION=$(diskutil list | grep "$RECOVERY_PARTITION_NAME" | awk '{print $NF}')
    
    if [[ -z "$RECOVERY_PARTITION" ]]; then
        error "Recovery partition '$RECOVERY_PARTITION_NAME' not found"
    fi
    
    info "Found recovery partition: $RECOVERY_PARTITION"
    echo "$RECOVERY_PARTITION"
}

# Validate recovery partition
validate_recovery_partition() {
    local partition="$1"
    log "Validating recovery partition..."
    
    # Check if partition exists
    if ! diskutil info "$partition" &> /dev/null; then
        error "Recovery partition $partition does not exist"
    fi
    
    # Check partition type
    local partition_type=$(diskutil info "$partition" | grep "Type (Bundle)" | awk '{print $3}')
    if [[ "$partition_type" != "hfs" ]]; then
        warn "Recovery partition type is $partition_type (expected hfs)"
    fi
    
    # Check if partition is mountable
    if ! diskutil mount "$partition" &> /dev/null; then
        error "Cannot mount recovery partition $partition"
    fi
    
    # Get mount point
    local mount_point=$(diskutil info "$partition" | grep "Mount Point" | awk '{print $3}')
    
    # Check for recovery files
    if [[ ! -f "$mount_point/usr/local/bin/lilithos-recovery" ]]; then
        warn "Recovery tools not found on partition"
    fi
    
    # Unmount partition
    diskutil unmount "$partition" &> /dev/null
    
    log "Recovery partition validation completed"
}

# Emergency recovery boot
emergency_recovery_boot() {
    log "Initiating emergency recovery boot..."
    
    local partition=$(find_recovery_partition)
    validate_recovery_partition "$partition"
    
    info "Emergency recovery boot will reboot the system in $TIMEOUT_SECONDS seconds"
    info "Press Ctrl+C to cancel"
    
    # Countdown
    for i in $(seq $TIMEOUT_SECONDS -1 1); do
        echo -ne "\rRebooting in $i seconds... "
        sleep 1
    done
    echo
    
    # Set boot to recovery partition
    log "Setting boot to recovery partition..."
    bless --mount "/dev/$partition" --setBoot
    
    # Reboot
    log "Rebooting into recovery mode..."
    reboot
}

# Interactive recovery boot
interactive_recovery_boot() {
    log "Starting interactive recovery boot..."
    
    echo
    echo "LilithOS Recovery Boot Options"
    echo "=============================="
    echo "1. Emergency Recovery (immediate)"
    echo "2. Repair Mode"
    echo "3. Diagnostic Mode"
    echo "4. Safe Recovery Mode"
    echo "5. Cancel"
    echo
    
    read -p "Select recovery mode (1-5): " choice
    
    case $choice in
        1)
            emergency_recovery_boot
            ;;
        2)
            repair_mode_boot
            ;;
        3)
            diagnostic_mode_boot
            ;;
        4)
            safe_mode_boot
            ;;
        5)
            info "Recovery boot cancelled"
            exit 0
            ;;
        *)
            error "Invalid option selected"
            ;;
    esac
}

# Repair mode boot
repair_mode_boot() {
    log "Initiating repair mode boot..."
    
    local partition=$(find_recovery_partition)
    validate_recovery_partition "$partition"
    
    # Mount partition to add repair mode flag
    diskutil mount "$partition"
    local mount_point=$(diskutil info "$partition" | grep "Mount Point" | awk '{print $3}')
    
    # Create repair mode flag
    echo "REPAIR_MODE=true" > "$mount_point/usr/local/etc/repair_mode.flag"
    echo "BOOT_TIME=$(date)" >> "$mount_point/usr/local/etc/repair_mode.flag"
    
    diskutil unmount "$partition"
    
    info "Repair mode boot will reboot the system in $TIMEOUT_SECONDS seconds"
    info "Press Ctrl+C to cancel"
    
    # Countdown
    for i in $(seq $TIMEOUT_SECONDS -1 1); do
        echo -ne "\rRebooting in $i seconds... "
        sleep 1
    done
    echo
    
    # Set boot to recovery partition
    log "Setting boot to recovery partition (repair mode)..."
    bless --mount "/dev/$partition" --setBoot
    
    # Reboot
    log "Rebooting into repair mode..."
    reboot
}

# Diagnostic mode boot
diagnostic_mode_boot() {
    log "Initiating diagnostic mode boot..."
    
    local partition=$(find_recovery_partition)
    validate_recovery_partition "$partition"
    
    # Mount partition to add diagnostic mode flag
    diskutil mount "$partition"
    local mount_point=$(diskutil info "$partition" | grep "Mount Point" | awk '{print $3}')
    
    # Create diagnostic mode flag
    echo "DIAGNOSTIC_MODE=true" > "$mount_point/usr/local/etc/diagnostic_mode.flag"
    echo "BOOT_TIME=$(date)" >> "$mount_point/usr/local/etc/diagnostic_mode.flag"
    
    diskutil unmount "$partition"
    
    info "Diagnostic mode boot will reboot the system in $TIMEOUT_SECONDS seconds"
    info "Press Ctrl+C to cancel"
    
    # Countdown
    for i in $(seq $TIMEOUT_SECONDS -1 1); do
        echo -ne "\rRebooting in $i seconds... "
        sleep 1
    done
    echo
    
    # Set boot to recovery partition
    log "Setting boot to recovery partition (diagnostic mode)..."
    bless --mount "/dev/$partition" --setBoot
    
    # Reboot
    log "Rebooting into diagnostic mode..."
    reboot
}

# Safe mode boot
safe_mode_boot() {
    log "Initiating safe mode boot..."
    
    local partition=$(find_recovery_partition)
    validate_recovery_partition "$partition"
    
    # Mount partition to add safe mode flag
    diskutil mount "$partition"
    local mount_point=$(diskutil info "$partition" | grep "Mount Point" | awk '{print $3}')
    
    # Create safe mode flag
    echo "SAFE_MODE=true" > "$mount_point/usr/local/etc/safe_mode.flag"
    echo "BOOT_TIME=$(date)" >> "$mount_point/usr/local/etc/safe_mode.flag"
    
    diskutil unmount "$partition"
    
    info "Safe mode boot will reboot the system in $TIMEOUT_SECONDS seconds"
    info "Press Ctrl+C to cancel"
    
    # Countdown
    for i in $(seq $TIMEOUT_SECONDS -1 1); do
        echo -ne "\rRebooting in $i seconds... "
        sleep 1
    done
    echo
    
    # Set boot to recovery partition
    log "Setting boot to recovery partition (safe mode)..."
    bless --mount "/dev/$partition" --setBoot
    
    # Reboot
    log "Rebooting into safe mode..."
    reboot
}

# Show recovery partition status
show_status() {
    log "Checking recovery partition status..."
    
    local partition=$(find_recovery_partition)
    
    echo
    echo "Recovery Partition Status"
    echo "========================="
    echo "Partition: $partition"
    echo "Name: $RECOVERY_PARTITION_NAME"
    
    # Get partition info
    local size=$(diskutil info "$partition" | grep "Total Size" | awk '{print $3}')
    local type=$(diskutil info "$partition" | grep "Type (Bundle)" | awk '{print $3}')
    local mountable=$(diskutil info "$partition" | grep "Mountable" | awk '{print $2}')
    
    echo "Size: $size"
    echo "Type: $type"
    echo "Mountable: $mountable"
    
    # Check if currently mounted
    if diskutil info "$partition" | grep -q "Mounted: Yes"; then
        local mount_point=$(diskutil info "$partition" | grep "Mount Point" | awk '{print $3}')
        echo "Mounted: Yes ($mount_point)"
    else
        echo "Mounted: No"
    fi
    
    echo
}

# Main function
main() {
    echo "=========================================="
    echo "LilithOS Recovery Boot Script v$SCRIPT_VERSION"
    echo "=========================================="
    echo
    
    # Parse command line arguments
    case "${1:-}" in
        --emergency)
            check_root
            check_system_requirements
            emergency_recovery_boot
            ;;
        --repair)
            check_root
            check_system_requirements
            repair_mode_boot
            ;;
        --diagnostic)
            check_root
            check_system_requirements
            diagnostic_mode_boot
            ;;
        --safe)
            check_root
            check_system_requirements
            safe_mode_boot
            ;;
        --status)
            show_status
            exit 0
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        --version|-v)
            echo "LilithOS Recovery Boot Script v$SCRIPT_VERSION"
            exit 0
            ;;
        "")
            check_root
            check_system_requirements
            interactive_recovery_boot
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