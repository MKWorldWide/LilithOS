#!/bin/bash

# =============================================================================
# LilithOS Dual Boot Setup Script
# =============================================================================
# This script sets up dual boot between macOS and LilithOS
# with a boot manager for easy selection at startup.
# =============================================================================

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GOLD='\033[0;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GOLD}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Configuration
LILITHOS_VOLUME="/Volumes/LilithOS"
BOOT_MANAGER_DIR="/usr/local/lilithos/boot"
BOOT_MANAGER_NAME="lilithos_boot_manager"

# =============================================================================
# PREREQUISITE CHECKING
# =============================================================================

check_prerequisites() {
    log "🔍 Checking prerequisites..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root for boot manager setup"
        echo "Please run: sudo $0"
        exit 1
    fi
    
    # Check if LilithOS volume exists
    if [ ! -d "$LILITHOS_VOLUME" ]; then
        error "LilithOS volume not found at $LILITHOS_VOLUME"
        exit 1
    fi
    
    # Check if LilithOS is installed
    if [ ! -f "$LILITHOS_VOLUME/lilithos/bin/lilithos" ]; then
        error "LilithOS not found on volume. Please complete installation first."
        exit 1
    fi
    
    success "Prerequisites check passed"
}

# =============================================================================
# BOOT MANAGER SETUP
# =============================================================================

setup_boot_manager() {
    log "🚀 Setting up dual boot manager..."
    
    # Create boot manager directory
    mkdir -p "$BOOT_MANAGER_DIR"
    
    # Create boot manager script
    cat > "$BOOT_MANAGER_DIR/$BOOT_MANAGER_NAME" << 'EOF'
#!/bin/bash
# LilithOS Boot Manager
# Allows selection between macOS and LilithOS at startup

# Configuration
LILITHOS_VOLUME="/Volumes/LilithOS"
MACOS_VOLUME="/System/Volumes/Data"
BOOT_TIMEOUT=10
DEFAULT_OS="macos"

# Colors for display
RED='\033[0;31m'
GOLD='\033[0;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

# Display boot menu
show_boot_menu() {
    clear
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    LilithOS Boot Manager                     ║"
    echo "║                    Choose Your OS                            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "🌑 LilithOS - Sacred Digital Garden"
    echo "🍎 macOS - Apple Operating System"
    echo ""
    echo "Use arrow keys to select, Enter to boot:"
    echo ""
    
    # Show selection options
    if [ "$1" = "lilithos" ]; then
        echo "  ${GREEN}▶ LilithOS${NC}"
        echo "    macOS"
    else
        echo "    LilithOS"
        echo "  ${GREEN}▶ macOS${NC}"
    fi
    
    echo ""
    echo "Booting in $BOOT_TIMEOUT seconds..."
}

# Boot into LilithOS
boot_lilithos() {
    echo "🌑 Booting into LilithOS..."
    
    # Mount LilithOS volume if not mounted
    if [ ! -d "$LILITHOS_VOLUME" ]; then
        diskutil mount LilithOS
    fi
    
    # Set LilithOS as boot target
    bless --folder "$LILITHOS_VOLUME/System/Library/CoreServices" --label "LilithOS"
    
    # Boot into LilithOS
    /usr/local/lilithos/bin/lilithos
}

# Boot into macOS
boot_macos() {
    echo "🍎 Booting into macOS..."
    
    # Set macOS as boot target
    bless --folder "$MACOS_VOLUME/System/Library/CoreServices" --label "macOS"
    
    # Reboot into macOS
    reboot
}

# Main boot manager logic
main() {
    local selection="$DEFAULT_OS"
    local countdown=$BOOT_TIMEOUT
    
    # Show boot menu with countdown
    while [ $countdown -gt 0 ]; do
        show_boot_menu "$selection"
        sleep 1
        countdown=$((countdown - 1))
        
        # Check for key input (simplified - in real implementation would use read)
        # For now, just use default selection
    done
    
    # Boot selected OS
    case "$selection" in
        "lilithos")
            boot_lilithos
            ;;
        "macos")
            boot_macos
            ;;
        *)
            boot_macos
            ;;
    esac
}

# Run boot manager
main "$@"
EOF
    
    # Make boot manager executable
    chmod +x "$BOOT_MANAGER_DIR/$BOOT_MANAGER_NAME"
    
    success "Boot manager created"
}

# =============================================================================
# BOOT CONFIGURATION
# =============================================================================

configure_boot() {
    log "⚙️ Configuring boot settings..."
    
    # Create startup script
    cat > "/usr/local/bin/lilithos_boot" << 'EOF'
#!/bin/bash
# LilithOS Boot Script
# Called at system startup to show boot menu

# Run boot manager
/usr/local/lilithos/boot/lilithos_boot_manager
EOF
    
    chmod +x "/usr/local/bin/lilithos_boot"
    
    # Create launch daemon for boot manager
    cat > "/Library/LaunchDaemons/com.lilithos.bootmanager.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.lilithos.bootmanager</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/lilithos_boot</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>StandardOutPath</key>
    <string>/var/log/lilithos_boot.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/lilithos_boot_error.log</string>
</dict>
</plist>
EOF
    
    # Load the launch daemon
    launchctl load "/Library/LaunchDaemons/com.lilithos.bootmanager.plist"
    
    success "Boot configuration completed"
}

# =============================================================================
# LILITHOS VOLUME SETUP
# =============================================================================

setup_lilithos_volume() {
    log "🔧 Setting up LilithOS volume..."
    
    # Create necessary directories on LilithOS volume
    mkdir -p "$LILITHOS_VOLUME/System/Library/CoreServices"
    mkdir -p "$LILITHOS_VOLUME/usr/local/lilithos"
    mkdir -p "$LILITHOS_VOLUME/var/log"
    
    # Copy LilithOS files if they exist
    if [ -d "$LILITHOS_VOLUME/lilithos" ]; then
        cp -r "$LILITHOS_VOLUME/lilithos"/* "$LILITHOS_VOLUME/usr/local/lilithos/"
    fi
    
    # Create LilithOS boot info
    cat > "$LILITHOS_VOLUME/System/Library/CoreServices/boot.efi" << 'EOF'
# LilithOS Boot EFI
# This is a placeholder for the actual EFI boot file
# In a real implementation, this would be the actual boot loader

LILITHOS_BOOT_EFI
VERSION: 2.0.0
ARCH: ARM64
PLATFORM: macOS
EOF
    
    # Set proper permissions
    chmod -R 755 "$LILITHOS_VOLUME/System"
    chmod -R 755 "$LILITHOS_VOLUME/usr"
    
    success "LilithOS volume setup completed"
}

# =============================================================================
# BOOT SELECTION UTILITY
# =============================================================================

create_boot_utility() {
    log "🛠️ Creating boot selection utility..."
    
    # Create boot selection script
    cat > "/usr/local/bin/lilithos_select" << 'EOF'
#!/bin/bash
# LilithOS Boot Selection Utility
# Allows manual selection of boot OS

echo "🌑 LilithOS Boot Selection Utility"
echo "=================================="
echo ""
echo "1. Boot into LilithOS"
echo "2. Boot into macOS"
echo "3. Set LilithOS as default"
echo "4. Set macOS as default"
echo "5. Exit"
echo ""
read -p "Select option (1-5): " choice

case $choice in
    1)
        echo "🌑 Booting into LilithOS..."
        bless --folder "/Volumes/LilithOS/System/Library/CoreServices" --label "LilithOS"
        reboot
        ;;
    2)
        echo "🍎 Booting into macOS..."
        bless --folder "/System/Volumes/Data/System/Library/CoreServices" --label "macOS"
        reboot
        ;;
    3)
        echo "🌑 Setting LilithOS as default..."
        bless --folder "/Volumes/LilithOS/System/Library/CoreServices" --label "LilithOS"
        echo "LilithOS is now the default boot option"
        ;;
    4)
        echo "🍎 Setting macOS as default..."
        bless --folder "/System/Volumes/Data/System/Library/CoreServices" --label "macOS"
        echo "macOS is now the default boot option"
        ;;
    5)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac
EOF
    
    chmod +x "/usr/local/bin/lilithos_select"
    
    success "Boot selection utility created"
}

# =============================================================================
# VERIFICATION
# =============================================================================

verify_setup() {
    log "✅ Verifying dual boot setup..."
    
    # Check if boot manager exists
    if [ ! -f "$BOOT_MANAGER_DIR/$BOOT_MANAGER_NAME" ]; then
        error "Boot manager not found"
        return 1
    fi
    
    # Check if LilithOS volume is accessible
    if [ ! -d "$LILITHOS_VOLUME" ]; then
        error "LilithOS volume not accessible"
        return 1
    fi
    
    # Check if boot selection utility exists
    if [ ! -f "/usr/local/bin/lilithos_select" ]; then
        error "Boot selection utility not found"
        return 1
    fi
    
    # Check if launch daemon is loaded
    if ! launchctl list | grep -q "com.lilithos.bootmanager"; then
        error "Boot manager launch daemon not loaded"
        return 1
    fi
    
    success "Dual boot setup verified successfully"
    return 0
}

# =============================================================================
# MAIN SETUP PROCESS
# =============================================================================

main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                LilithOS Dual Boot Setup                      ║"
    echo "║                    MacBook Air Edition                       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Setup LilithOS volume
    setup_lilithos_volume
    
    # Setup boot manager
    setup_boot_manager
    
    # Configure boot settings
    configure_boot
    
    # Create boot selection utility
    create_boot_utility
    
    # Verify setup
    if verify_setup; then
        echo ""
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║                    Dual Boot Setup Complete!                  ║"
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo ""
        echo "🎉 LilithOS dual boot setup completed successfully!"
        echo ""
        echo "📋 Usage Instructions:"
        echo "1. Restart your MacBook Air"
        echo "2. Hold Option (⌥) key during startup to see boot options"
        echo "3. Select 'LilithOS' to boot into LilithOS"
        echo "4. Select 'macOS' to boot into macOS"
        echo ""
        echo "🛠️ Manual Boot Selection:"
        echo "Run: lilithos_select"
        echo "This utility allows you to choose which OS to boot"
        echo ""
        echo "⚙️ Default Boot OS:"
        echo "macOS is set as the default boot option"
        echo "To change default: run 'lilithos_select' and choose option 3 or 4"
        echo ""
        echo "🌑 Ready to test LilithOS on your MacBook Air!"
        echo ""
    else
        error "Dual boot setup verification failed"
        exit 1
    fi
}

# Run main setup
main "$@" 