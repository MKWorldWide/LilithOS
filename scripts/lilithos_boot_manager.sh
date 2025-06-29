#!/bin/bash
# LilithOS Boot Manager for macOS
# This script manages dual boot between macOS and LilithOS

set -e

# Configuration
LILITHOS_VOLUME="/Volumes/LilithOS"
LILITHOS_ROOT="$LILITHOS_VOLUME/lilithos"
BOOT_MANAGER_DIR="/Library/Application Support/LilithOS"
BOOT_MANAGER_SCRIPT="$BOOT_MANAGER_DIR/boot_manager.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}    LilithOS Boot Manager${NC}"
    echo -e "${CYAN}================================${NC}"
}

# Function to check if LilithOS volume exists
check_lilithos_volume() {
    if [ ! -d "$LILITHOS_VOLUME" ]; then
        print_error "LilithOS volume not found at $LILITHOS_VOLUME"
        return 1
    fi
    print_status "LilithOS volume found at $LILITHOS_VOLUME"
    return 0
}

# Function to install boot manager
install_boot_manager() {
    print_status "Installing LilithOS Boot Manager..."
    
    # Create boot manager directory
    sudo mkdir -p "$BOOT_MANAGER_DIR"
    
    # Create boot manager script
    cat > /tmp/boot_manager.sh << 'EOF'
#!/bin/bash
# LilithOS Boot Manager Script

LILITHOS_VOLUME="/Volumes/LilithOS"
LILITHOS_ROOT="$LILITHOS_VOLUME/lilithos"

# Function to boot LilithOS
boot_lilithos() {
    echo "Booting LilithOS..."
    if [ -d "$LILITHOS_ROOT" ]; then
        cd "$LILITHOS_ROOT"
        if [ -f "scripts/boot.sh" ]; then
            exec "$LILITHOS_ROOT/scripts/boot.sh"
        else
            echo "LilithOS boot script not found"
            exit 1
        fi
    else
        echo "LilithOS not found"
        exit 1
    fi
}

# Function to boot macOS
boot_macos() {
    echo "Booting macOS..."
    # This will be handled by the system bootloader
    exit 0
}

# Main boot selection
echo "LilithOS Boot Manager"
echo "1. Boot macOS"
echo "2. Boot LilithOS"
echo "3. Boot LilithOS Recovery"
read -p "Select boot option (1-3): " choice

case $choice in
    1)
        boot_macos
        ;;
    2)
        boot_lilithos
        ;;
    3)
        if [ -f "$LILITHOS_ROOT/scripts/recovery-boot.sh" ]; then
            exec "$LILITHOS_ROOT/scripts/recovery-boot.sh"
        else
            echo "Recovery boot not available"
            boot_lilithos
        fi
        ;;
    *)
        echo "Invalid choice, booting macOS"
        boot_macos
        ;;
esac
EOF

    # Copy boot manager script
    sudo cp /tmp/boot_manager.sh "$BOOT_MANAGER_SCRIPT"
    sudo chmod +x "$BOOT_MANAGER_SCRIPT"
    
    # Create launch agent for boot manager
    cat > /tmp/com.lilithos.bootmanager.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.lilithos.bootmanager</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BOOT_MANAGER_SCRIPT</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
EOF

    # Install launch agent
    sudo cp /tmp/com.lilithos.bootmanager.plist /Library/LaunchDaemons/
    sudo chown root:wheel /Library/LaunchDaemons/com.lilithos.bootmanager.plist
    sudo chmod 644 /Library/LaunchDaemons/com.lilithos.bootmanager.plist
    
    # Load launch agent
    sudo launchctl load /Library/LaunchDaemons/com.lilithos.bootmanager.plist
    
    print_status "Boot manager installed successfully"
}

# Function to create boot entry
create_boot_entry() {
    print_status "Creating boot entry for LilithOS..."
    
    # Create a simple boot entry script
    cat > /tmp/lilithos_boot_entry.sh << 'EOF'
#!/bin/bash
# LilithOS Boot Entry

LILITHOS_VOLUME="/Volumes/LilithOS"
LILITHOS_ROOT="$LILITHOS_VOLUME/lilithos"

echo "Starting LilithOS..."
echo "Volume: $LILITHOS_VOLUME"
echo "Root: $LILITHOS_ROOT"

if [ -d "$LILITHOS_ROOT" ]; then
    cd "$LILITHOS_ROOT"
    echo "LilithOS found, starting system..."
    
    # Set environment variables
    export LILITHOS_HOME="$LILITHOS_ROOT"
    export PATH="$LILITHOS_ROOT/bin:$PATH"
    export LD_LIBRARY_PATH="$LILITHOS_ROOT/lib:$LD_LIBRARY_PATH"
    
    # Start LilithOS
    if [ -f "scripts/start.sh" ]; then
        exec "scripts/start.sh"
    else
        echo "LilithOS start script not found"
        echo "Available scripts:"
        ls -la scripts/
        exit 1
    fi
else
    echo "LilithOS not found at $LILITHOS_ROOT"
    exit 1
fi
EOF

    # Copy boot entry to LilithOS volume
    sudo cp /tmp/lilithos_boot_entry.sh "$LILITHOS_ROOT/boot.sh"
    sudo chmod +x "$LILITHOS_ROOT/boot.sh"
    
    print_status "Boot entry created at $LILITHOS_ROOT/boot.sh"
}

# Function to setup startup disk
setup_startup_disk() {
    print_status "Setting up startup disk options..."
    
    # Create startup disk configuration
    cat > /tmp/startup_disk_config.sh << 'EOF'
#!/bin/bash
# Startup Disk Configuration for LilithOS

echo "LilithOS Startup Disk Configuration"
echo "=================================="
echo ""
echo "Available boot options:"
echo "1. macOS (default)"
echo "2. LilithOS"
echo "3. LilithOS Recovery"
echo ""
echo "To change boot options:"
echo "- Hold Option key during startup"
echo "- Use System Preferences > Startup Disk"
echo "- Use 'bless' command in Terminal"
echo ""
echo "Current startup disk:"
bless --info --getBoot
EOF

    sudo cp /tmp/startup_disk_config.sh "$LILITHOS_ROOT/startup_config.sh"
    sudo chmod +x "$LILITHOS_ROOT/startup_config.sh"
    
    print_status "Startup disk configuration created"
}

# Function to create recovery boot
create_recovery_boot() {
    print_status "Creating recovery boot option..."
    
    # Create recovery boot script
    cat > /tmp/recovery_boot.sh << 'EOF'
#!/bin/bash
# LilithOS Recovery Boot

LILITHOS_VOLUME="/Volumes/LilithOS"
LILITHOS_ROOT="$LILITHOS_VOLUME/lilithos"

echo "LilithOS Recovery Mode"
echo "====================="

# Recovery options
echo "Recovery Options:"
echo "1. Emergency Recovery"
echo "2. System Repair"
echo "3. Diagnostic Mode"
echo "4. Safe Mode"
echo "5. Return to Boot Menu"

read -p "Select recovery option (1-5): " choice

case $choice in
    1)
        echo "Starting Emergency Recovery..."
        if [ -f "$LILITHOS_ROOT/scripts/emergency-recovery.sh" ]; then
            exec "$LILITHOS_ROOT/scripts/emergency-recovery.sh"
        else
            echo "Emergency recovery not available"
        fi
        ;;
    2)
        echo "Starting System Repair..."
        if [ -f "$LILITHOS_ROOT/scripts/system-repair.sh" ]; then
            exec "$LILITHOS_ROOT/scripts/system-repair.sh"
        else
            echo "System repair not available"
        fi
        ;;
    3)
        echo "Starting Diagnostic Mode..."
        if [ -f "$LILITHOS_ROOT/scripts/diagnostic.sh" ]; then
            exec "$LILITHOS_ROOT/scripts/diagnostic.sh"
        else
            echo "Diagnostic mode not available"
        fi
        ;;
    4)
        echo "Starting Safe Mode..."
        if [ -f "$LILITHOS_ROOT/scripts/safe-mode.sh" ]; then
            exec "$LILITHOS_ROOT/scripts/safe-mode.sh"
        else
            echo "Safe mode not available"
        fi
        ;;
    5)
        echo "Returning to boot menu..."
        exec "$0"
        ;;
    *)
        echo "Invalid choice"
        exec "$0"
        ;;
esac
EOF

    # Copy recovery boot script
    sudo cp /tmp/recovery_boot.sh "$LILITHOS_ROOT/recovery-boot.sh"
    sudo chmod +x "$LILITHOS_ROOT/recovery-boot.sh"
    
    print_status "Recovery boot option created"
}

# Function to create startup script
create_startup_script() {
    print_status "Creating LilithOS startup script..."
    
    # Create startup script
    cat > /tmp/start.sh << 'EOF'
#!/bin/bash
# LilithOS Startup Script

LILITHOS_ROOT="$PWD"

echo "LilithOS v1.0 Starting..."
echo "========================="

# Set environment
export LILITHOS_HOME="$LILITHOS_ROOT"
export PATH="$LILITHOS_ROOT/bin:$PATH"
export LD_LIBRARY_PATH="$LILITHOS_ROOT/lib:$LD_LIBRARY_PATH"

# Load modules
if [ -d "modules" ]; then
    echo "Loading modules..."
    for module in modules/*/; do
        if [ -f "${module}init.sh" ]; then
            echo "Loading module: $(basename "$module")"
            source "${module}init.sh"
        fi
    done
fi

# Start system services
echo "Starting system services..."
if [ -f "scripts/start-services.sh" ]; then
    source "scripts/start-services.sh"
fi

# Start desktop environment
echo "Starting desktop environment..."
if [ -f "scripts/start-desktop.sh" ]; then
    source "scripts/start-desktop.sh"
else
    echo "Desktop environment not found, starting shell..."
    exec bash
fi
EOF

    # Copy startup script
    sudo cp /tmp/start.sh "$LILITHOS_ROOT/scripts/start.sh"
    sudo chmod +x "$LILITHOS_ROOT/scripts/start.sh"
    
    print_status "Startup script created"
}

# Main function
main() {
    print_header
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
    
    # Check LilithOS volume
    if ! check_lilithos_volume; then
        print_error "LilithOS volume not found. Please ensure LilithOS is installed."
        exit 1
    fi
    
    # Install components
    install_boot_manager
    create_boot_entry
    setup_startup_disk
    create_recovery_boot
    create_startup_script
    
    print_status "LilithOS dual boot setup complete!"
    echo ""
    echo "To boot LilithOS:"
    echo "1. Restart your Mac"
    echo "2. Hold the Option key during startup"
    echo "3. Select 'LilithOS' from the boot menu"
    echo ""
    echo "Or use the boot manager:"
    echo "sudo $BOOT_MANAGER_SCRIPT"
}

# Run main function
main "$@" 