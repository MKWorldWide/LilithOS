#!/bin/bash
# LilithOS Installation Completion Script
# This script finalizes the installation and verifies all components

set -e

# Configuration
LILITHOS_VOLUME="/Volumes/LilithOS"
LILITHOS_ROOT="$LILITHOS_VOLUME/lilithos"
BOOT_MANAGER_DIR="/Library/Application Support/LilithOS"

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
    echo -e "${CYAN}  LilithOS Installation Complete${NC}"
    echo -e "${CYAN}================================${NC}"
}

# Function to verify installation
verify_installation() {
    print_status "Verifying LilithOS installation..."
    
    local errors=0
    
    # Check if volume exists
    if [ ! -d "$LILITHOS_VOLUME" ]; then
        print_error "LilithOS volume not found"
        ((errors++))
    else
        print_status "✓ LilithOS volume found"
    fi
    
    # Check if root directory exists
    if [ ! -d "$LILITHOS_ROOT" ]; then
        print_error "LilithOS root directory not found"
        ((errors++))
    else
        print_status "✓ LilithOS root directory found"
    fi
    
    # Check essential directories
    local essential_dirs=("bin" "lib" "modules" "config" "scripts" "docs" "tools" "packages")
    for dir in "${essential_dirs[@]}"; do
        if [ ! -d "$LILITHOS_ROOT/$dir" ]; then
            print_error "Essential directory missing: $dir"
            ((errors++))
        else
            print_status "✓ Directory found: $dir"
        fi
    done
    
    # Check essential files
    local essential_files=("README.md" "boot.sh" "start.sh" "recovery-boot.sh")
    for file in "${essential_files[@]}"; do
        if [ ! -f "$LILITHOS_ROOT/$file" ]; then
            print_error "Essential file missing: $file"
            ((errors++))
        else
            print_status "✓ File found: $file"
        fi
    done
    
    # Check boot manager
    if [ ! -f "$BOOT_MANAGER_DIR/boot_manager.sh" ]; then
        print_error "Boot manager not found"
        ((errors++))
    else
        print_status "✓ Boot manager installed"
    fi
    
    # Check launch daemon
    if [ ! -f "/Library/LaunchDaemons/com.lilithos.bootmanager.plist" ]; then
        print_error "Launch daemon not found"
        ((errors++))
    else
        print_status "✓ Launch daemon installed"
    fi
    
    if [ $errors -eq 0 ]; then
        print_status "Installation verification completed successfully"
        return 0
    else
        print_error "Installation verification failed with $errors errors"
        return 1
    fi
}

# Function to create system information
create_system_info() {
    print_status "Creating system information..."
    
    # Use a temporary file in the user's home directory
    TEMP_FILE="$HOME/lilithos_system_info_temp.txt"
    
    cat > "$TEMP_FILE" << EOF
LilithOS System Information
==========================

Installation Date: $(date)
Volume Path: $LILITHOS_VOLUME
Root Path: $LILITHOS_ROOT
Boot Manager: $BOOT_MANAGER_DIR/boot_manager.sh

System Architecture: $(uname -m)
macOS Version: $(sw_vers -productVersion)
Kernel Version: $(uname -r)

Available Modules:
$(ls -1 "$LILITHOS_ROOT/modules" 2>/dev/null || echo "No modules found")

Available Scripts:
$(ls -1 "$LILITHOS_ROOT/scripts" 2>/dev/null || echo "No scripts found")

Boot Options:
1. macOS (default)
2. LilithOS
3. LilithOS Recovery

Recovery Options:
1. Emergency Recovery
2. System Repair
3. Diagnostic Mode
4. Safe Mode

To boot LilithOS:
1. Restart your Mac
2. Hold Option key during startup
3. Select 'LilithOS' from boot menu

To access recovery:
1. Boot into LilithOS
2. Select recovery option from boot menu
3. Choose recovery mode

For support and documentation:
- Check $LILITHOS_ROOT/docs/
- Read $LILITHOS_ROOT/README.md
- Review $LILITHOS_ROOT/DUAL_BOOT_GUIDE.md
EOF

    sudo cp "$TEMP_FILE" "$LILITHOS_ROOT/system_info.txt"
    rm -f "$TEMP_FILE"
    print_status "System information saved to $LILITHOS_ROOT/system_info.txt"
}

# Function to create desktop shortcut
create_desktop_shortcut() {
    print_status "Creating desktop shortcut..."
    
    # Create a simple launcher script
    TEMP_LAUNCHER="$HOME/LilithOS_Launcher_temp.command"
    
    cat > "$TEMP_LAUNCHER" << EOF
#!/bin/bash
# LilithOS Launcher

echo "LilithOS Launcher"
echo "================="
echo ""
echo "This will launch LilithOS in a new terminal window."
echo ""

# Check if LilithOS volume is mounted
if [ ! -d "/Volumes/LilithOS" ]; then
    echo "Error: LilithOS volume not mounted"
    echo "Please ensure LilithOS is properly installed"
    read -p "Press Enter to continue..."
    exit 1
fi

# Launch LilithOS
cd "/Volumes/LilithOS/lilithos"
echo "Starting LilithOS..."
./start.sh
EOF

    sudo cp "$TEMP_LAUNCHER" "$LILITHOS_ROOT/LilithOS_Launcher.command"
    sudo chmod +x "$LILITHOS_ROOT/LilithOS_Launcher.command"
    
    # Create Applications shortcut
    sudo cp "$LILITHOS_ROOT/LilithOS_Launcher.command" "/Applications/LilithOS Launcher.command"
    sudo chmod +x "/Applications/LilithOS Launcher.command"
    
    rm -f "$TEMP_LAUNCHER"
    print_status "Desktop shortcut created"
}

# Function to create installation summary
create_installation_summary() {
    print_status "Creating installation summary..."
    
    TEMP_SUMMARY="$HOME/installation_summary_temp.txt"
    
    cat > "$TEMP_SUMMARY" << EOF
LilithOS Installation Summary
============================

✅ Installation Status: COMPLETE
📅 Installation Date: $(date)
💾 Volume Size: $(df -h "$LILITHOS_VOLUME" | tail -1 | awk '{print $2}')
📁 Used Space: $(df -h "$LILITHOS_VOLUME" | tail -1 | awk '{print $3}')
🆓 Free Space: $(df -h "$LILITHOS_VOLUME" | tail -1 | awk '{print $4}')

📋 Installed Components:
- Core system files
- Modular architecture
- Boot manager
- Recovery system
- Documentation
- Development tools
- Security framework
- Performance monitoring

🚀 Boot Options:
1. macOS (default)
2. LilithOS
3. LilithOS Recovery

🔧 Recovery Options:
1. Emergency Recovery
2. System Repair
3. Diagnostic Mode
4. Safe Mode

📱 Available Modules:
$(ls -1 "$LILITHOS_ROOT/modules" 2>/dev/null | sed 's/^/- /' || echo "- No modules found")

🛠️ Available Scripts:
$(ls -1 "$LILITHOS_ROOT/scripts" 2>/dev/null | head -10 | sed 's/^/- /' || echo "- No scripts found")

📚 Documentation:
- README.md: Main documentation
- DUAL_BOOT_GUIDE.md: Dual boot instructions
- docs/: Detailed documentation
- system_info.txt: System information

🎯 Next Steps:
1. Restart your Mac
2. Hold Option key during startup
3. Select 'LilithOS' to boot
4. Explore the system and modules
5. Customize your configuration

🔗 Quick Access:
- Applications: LilithOS Launcher
- Volume: $LILITHOS_VOLUME
- Root: $LILITHOS_ROOT
- Boot Manager: $BOOT_MANAGER_DIR

✅ Installation completed successfully!
EOF

    sudo cp "$TEMP_SUMMARY" "$LILITHOS_ROOT/installation_summary.txt"
    rm -f "$TEMP_SUMMARY"
    print_status "Installation summary saved to $LILITHOS_ROOT/installation_summary.txt"
}

# Main execution
main() {
    print_header
    
    print_status "Completing LilithOS installation..."
    
    # Verify installation
    if ! verify_installation; then
        print_error "Installation verification failed"
        exit 1
    fi
    
    # Create system information
    create_system_info
    
    # Create desktop shortcut
    create_desktop_shortcut
    
    # Create installation summary
    create_installation_summary
    
    print_header
    print_status "LilithOS installation completed successfully!"
    print_status ""
    print_status "Installation Summary:"
    print_status "- Volume: $LILITHOS_VOLUME"
    print_status "- Root: $LILITHOS_ROOT"
    print_status "- Boot Manager: $BOOT_MANAGER_DIR"
    print_status "- Desktop Shortcut: /Applications/LilithOS Launcher.command"
    print_status ""
    print_status "To boot LilithOS:"
    print_status "1. Restart your Mac"
    print_status "2. Hold Option key during startup"
    print_status "3. Select 'LilithOS' from boot menu"
    print_status ""
    print_status "For documentation:"
    print_status "- $LILITHOS_ROOT/README.md"
    print_status "- $LILITHOS_ROOT/DUAL_BOOT_GUIDE.md"
    print_status "- $LILITHOS_ROOT/installation_summary.txt"
    print_status ""
    print_status "Installation complete! 🎉"
}

# Run main function
main "$@" 