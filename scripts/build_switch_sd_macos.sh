#!/bin/bash

# =============================================================================
# LilithOS Nintendo Switch SD Card Builder - macOS Edition
# =============================================================================
# This script creates a complete LilithOS image for Nintendo Switch
# optimized for macOS systems using hdiutil and macOS-specific tools.
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
LILITHOS_VERSION="2.0.0"
SWITCH_IMAGE_NAME="lilithos-switch-v${LILITHOS_VERSION}"
SWITCH_IMAGE_SIZE="8GB"
BUILD_DIR="build/switch"

# Switch-specific configuration
SWITCH_ARCH="arm64"
SWITCH_CHIP="nintendo-switch"
SWITCH_PLATFORM="handheld"

# =============================================================================
# PREREQUISITE CHECKING
# =============================================================================

check_prerequisites() {
    log "🔍 Checking prerequisites..."
    
    # Check if running as root (not required on macOS)
    if [[ $EUID -eq 0 ]]; then
        info "Running as root - some operations may require elevated privileges"
    fi
    
    # Check required macOS tools
    local required_tools=("hdiutil" "diskutil" "mount" "umount" "tar" "gzip")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error "Required tool not found: $tool"
            exit 1
        fi
    done
    
    # Check for sufficient disk space
    local available_space=$(df . | awk 'NR==2 {print $4}')
    local required_space=$((8 * 1024 * 1024))  # 8GB in KB
    
    if [ "$available_space" -lt "$required_space" ]; then
        error "Insufficient disk space. Need at least 8GB, available: $((available_space / 1024 / 1024))GB"
        exit 1
    fi
    
    success "Prerequisites check passed"
}

# =============================================================================
# IMAGE CREATION
# =============================================================================

create_switch_image() {
    log "🎮 Creating Nintendo Switch SD card image..."
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Create empty image file using hdiutil
    log "📁 Creating ${SWITCH_IMAGE_SIZE} image file..."
    hdiutil create -size 8g -fs "MS-DOS FAT32" -volname "LILITHOS_SWITCH" -attach "${SWITCH_IMAGE_NAME}.dmg"
    
    # Get the mounted volume path - handle both volume names
    local mounted_volume=""
    if [ -d "/Volumes/LILITHOS_SWITCH" ]; then
        mounted_volume="/Volumes/LILITHOS_SWITCH"
    elif [ -d "/Volumes/NO NAME" ]; then
        mounted_volume="/Volumes/NO NAME"
    else
        error "Failed to find mounted volume"
        exit 1
    fi
    
    log "🔗 Mounted volume: $mounted_volume"
    
    success "Switch image created and mounted"
}

# =============================================================================
# LILITHOS INSTALLATION
# =============================================================================

install_lilithos_core() {
    log "🔧 Installing LilithOS core system..."
    
    # Get the mounted volume path
    local mounted_volume=""
    if [ -d "/Volumes/LILITHOS_SWITCH" ]; then
        mounted_volume="/Volumes/LILITHOS_SWITCH"
    elif [ -d "/Volumes/NO NAME" ]; then
        mounted_volume="/Volumes/NO NAME"
    else
        error "Failed to find mounted volume"
        exit 1
    fi
    
    # Create LilithOS directory structure
    mkdir -p "$mounted_volume/lilithos"
    mkdir -p "$mounted_volume/lilithos/modules"
    mkdir -p "$mounted_volume/lilithos/config"
    mkdir -p "$mounted_volume/lilithos/bin"
    mkdir -p "$mounted_volume/lilithos/lib"
    mkdir -p "$mounted_volume/lilithos/share"
    
    # Copy core system files
    if [ -d "../../core" ]; then
        cp -r ../../core/* "$mounted_volume/lilithos/"
    else
        create_minimal_core "$mounted_volume"
    fi
    
    # Make executables
    chmod +x "$mounted_volume/lilithos/bin"/*
    
    success "Core system installed"
}

create_minimal_core() {
    local mount_point="$1"
    log "🔧 Creating minimal core system for Switch..."
    
    # Create main launcher
    cat > "$mount_point/lilithos/bin/lilithos" << 'EOF'
#!/bin/bash
# LilithOS Nintendo Switch Launcher

echo "🌑 LilithOS v2.0.0 - Nintendo Switch Edition"
echo "🎮 Tegra X1 Optimized"
echo ""

# Load Switch-specific modules
source /lilithos/modules/chips/nintendo-switch/init.sh

# Initialize LilithOS
initialize_lilithos_switch

echo "✅ LilithOS Switch Edition ready!"
echo "🎮 Use Joy-Con controllers for navigation"
echo ""

initialize_lilithos_switch() {
    # Load core modules
    load_core_modules
    
    # Load Switch-specific modules
    load_switch_modules
    
    # Start Switch interface
    start_switch_interface
}

load_core_modules() {
    echo "🔧 Loading core modules..."
    # Load essential system modules
}

load_switch_modules() {
    echo "🎮 Loading Switch modules..."
    # Load Joy-Con, display, power management
}

start_switch_interface() {
    echo "🖥️ Starting Switch interface..."
    # Start graphical interface optimized for Switch
}
EOF
    
    chmod +x "$mount_point/lilithos/bin/lilithos"
}

install_switch_modules() {
    log "🎮 Installing Nintendo Switch modules..."
    
    # Get the mounted volume path
    local mounted_volume=""
    if [ -d "/Volumes/LILITHOS_SWITCH" ]; then
        mounted_volume="/Volumes/LILITHOS_SWITCH"
    elif [ -d "/Volumes/NO NAME" ]; then
        mounted_volume="/Volumes/NO NAME"
    else
        error "Failed to find mounted volume"
        exit 1
    fi
    
    # Create module directories
    mkdir -p "$mounted_volume/lilithos/modules/chips/nintendo-switch"
    mkdir -p "$mounted_volume/lilithos/modules/features/joycon"
    mkdir -p "$mounted_volume/lilithos/modules/features/switch_display"
    mkdir -p "$mounted_volume/lilithos/modules/features/switch_power"
    
    # Copy Switch chip module
    if [ -d "../../../modules/chips/nintendo-switch" ]; then
        cp -r ../../../modules/chips/nintendo-switch/* "$mounted_volume/lilithos/modules/chips/nintendo-switch/"
    fi
    
    # Copy Joy-Con module
    if [ -d "../../../modules/features/joycon" ]; then
        cp -r ../../../modules/features/joycon/* "$mounted_volume/lilithos/modules/features/joycon/"
    fi
    
    # Create Switch display module
    create_switch_display_module "$mounted_volume"
    
    # Create Switch power module
    create_switch_power_module "$mounted_volume"
    
    # Make all scripts executable
    find "$mounted_volume/lilithos/modules" -name "*.sh" -exec chmod +x {} \;
    
    success "Switch modules installed"
}

create_switch_display_module() {
    local mount_point="$1"
    log "🖥️ Creating Switch display module..."
    
    cat > "$mount_point/lilithos/modules/features/switch_display/init.sh" << 'EOF'
#!/bin/bash
# LilithOS Switch Display Module

echo "🖥️ Initializing Switch display..."

# Switch display configuration
configure_switch_display() {
    # Detect display mode (handheld vs docked)
    if [ -f /sys/class/drm/card0/status ] && [ "$(cat /sys/class/drm/card0/status)" = "connected" ]; then
        export LILITHOS_DISPLAY_MODE="docked"
        export LILITHOS_DISPLAY_RESOLUTION="1920x1080"
        echo "🖥️ Docked mode: 1920x1080"
    else
        export LILITHOS_DISPLAY_MODE="handheld"
        export LILITHOS_DISPLAY_RESOLUTION="1280x720"
        echo "🖥️ Handheld mode: 1280x720"
    fi
    
    # Set display refresh rate
    export LILITHOS_REFRESH_RATE="60"
    
    # Configure X11 for Switch display
    configure_x11_display
}

configure_x11_display() {
    # Create X11 configuration for Switch
    mkdir -p /etc/X11
    cat > /etc/X11/xorg.conf.d/10-switch.conf << 'X11CONF'
Section "Device"
    Identifier "Tegra X1"
    Driver "modesetting"
    Option "AccelMethod" "glamor"
EndSection

Section "Monitor"
    Identifier "Switch Display"
    Option "PreferredMode" "1280x720"
EndSection

Section "Screen"
    Identifier "Default Screen"
    Device "Tegra X1"
    Monitor "Switch Display"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1280x720" "1920x1080"
    EndSubSection
EndSection
X11CONF
}

# Initialize display
configure_switch_display
EOF
    
    chmod +x "$mount_point/lilithos/modules/features/switch_display/init.sh"
}

create_switch_power_module() {
    local mount_point="$1"
    log "🔋 Creating Switch power module..."
    
    cat > "$mount_point/lilithos/modules/features/switch_power/init.sh" << 'EOF'
#!/bin/bash
# LilithOS Switch Power Module

echo "🔋 Initializing Switch power management..."

# Switch power configuration
configure_switch_power() {
    # Battery optimization
    export LILITHOS_BATTERY_OPTIMIZED="true"
    export LILITHOS_POWER_SAVE="enabled"
    
    # CPU frequency scaling
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors ]; then
        echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1 || true
    fi
    
    # GPU power management
    export LILITHOS_GPU_POWER_SAVE="enabled"
    
    # Thermal management
    export LILITHOS_THERMAL_MANAGEMENT="enabled"
    export LILITHOS_TEMP_THRESHOLD="85C"
    
    # Battery monitoring
    setup_battery_monitoring
}

setup_battery_monitoring() {
    # Create battery monitoring script
    cat > /usr/local/bin/switch-battery << 'BATTERY'
#!/bin/bash
# Switch Battery Monitor

echo "🔋 Switch Battery Status"
echo "========================"

# Check battery level
if [ -f /sys/class/power_supply/battery/capacity ]; then
    BATTERY_LEVEL=$(cat /sys/class/power_supply/battery/capacity)
    echo "Battery Level: ${BATTERY_LEVEL}%"
else
    echo "Battery Level: Unknown"
fi

# Check charging status
if [ -f /sys/class/power_supply/battery/status ]; then
    BATTERY_STATUS=$(cat /sys/class/power_supply/battery/status)
    echo "Charging Status: $BATTERY_STATUS"
else
    echo "Charging Status: Unknown"
fi

# Check temperature
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
    echo "Temperature: ${TEMP}°C"
else
    echo "Temperature: Unknown"
fi
BATTERY
    
    chmod +x /usr/local/bin/switch-battery
}

# Initialize power management
configure_switch_power
EOF
    
    chmod +x "$mount_point/lilithos/modules/features/switch_power/init.sh"
}

# =============================================================================
# SWITCH-SPECIFIC FILES
# =============================================================================

create_switch_boot_files() {
    log "🚀 Creating Switch boot files..."
    
    # Get the mounted volume path
    local mounted_volume=""
    if [ -d "/Volumes/LILITHOS_SWITCH" ]; then
        mounted_volume="/Volumes/LILITHOS_SWITCH"
    elif [ -d "/Volumes/NO NAME" ]; then
        mounted_volume="/Volumes/NO NAME"
    else
        error "Failed to find mounted volume"
        exit 1
    fi
    
    # Create boot configuration
    cat > "$mounted_volume/boot.ini" << 'EOF'
# LilithOS Nintendo Switch Boot Configuration

# Boot options
setenv bootargs "console=ttyS0,115200 root=/dev/mmcblk0p1 rw rootwait video=HDMI-A-1:1280x720-32@60"
setenv bootcmd "fatload mmc 0:1 0x90000000 lilithos-switch.elf; bootelf 0x90000000"

# Display configuration
setenv display_mode "handheld"
setenv display_resolution "1280x720"

# Power management
setenv power_save "enabled"
setenv thermal_management "enabled"

# Joy-Con configuration
setenv joycon_enabled "true"
setenv joycon_pairing "auto"
EOF
    
    # Create Switch payload
    create_switch_payload "$mounted_volume"
    
    # Create Hekate configuration
    create_hekate_config "$mounted_volume"
    
    success "Switch boot files created"
}

create_switch_payload() {
    local mount_point="$1"
    log "📦 Creating Switch payload..."
    
    # Create a simple payload stub (this would be replaced with actual payload)
    cat > "$mount_point/lilithos-switch.elf" << 'EOF'
# LilithOS Nintendo Switch Payload
# This is a placeholder for the actual ARM64 payload binary
# The real payload would be compiled from the LilithOS kernel and initramfs

# Payload header
LILITHOS_SWITCH_PAYLOAD
VERSION: 2.0.0
ARCH: ARM64
CHIP: Tegra X1
PLATFORM: Nintendo Switch

# Boot configuration
BOOT_MODE: SD_CARD
DISPLAY: 1280x720
CONTROLLER: Joy-Con
POWER: OPTIMIZED

# This file would be replaced with the actual compiled payload
EOF
    
    # Make it executable
    chmod +x "$mount_point/lilithos-switch.elf"
}

create_hekate_config() {
    local mount_point="$1"
    log "⚙️ Creating Hekate configuration..."
    
    # Create Hekate configuration file
    cat > "$mount_point/hekate_ipl.ini" << 'EOF'
[config]
autoboot=0
autoboot_list=0
bootwait=3
backlight=100
autohosoff=0
autonogc=1
updater2p=0
bootprotect=0

[LilithOS Switch]
payload=bootloader/payloads/lilithos-switch.elf
icon=bootloader/res/icon_lilithos.bmp

[LilithOS Switch - Docked]
payload=bootloader/payloads/lilithos-switch.elf
icon=bootloader/res/icon_lilithos.bmp
kip1patch=nosigchk
kip1=atmosphere/kips/*
emummc_force_disable=1

[LilithOS Switch - Handheld]
payload=bootloader/payloads/lilithos-switch.elf
icon=bootloader/res/icon_lilithos.bmp
kip1patch=nosigchk
kip1=atmosphere/kips/*
emummc_force_disable=1
EOF
}

# =============================================================================
# THEME AND UI
# =============================================================================

install_switch_theme() {
    log "🎨 Installing Switch-optimized theme..."
    
    # Get the mounted volume path
    local mounted_volume=""
    if [ -d "/Volumes/LILITHOS_SWITCH" ]; then
        mounted_volume="/Volumes/LILITHOS_SWITCH"
    elif [ -d "/Volumes/NO NAME" ]; then
        mounted_volume="/Volumes/NO NAME"
    else
        error "Failed to find mounted volume"
        exit 1
    fi
    
    # Create theme directory
    mkdir -p "$mounted_volume/lilithos/modules/themes/dark-glass"
    
    # Create Switch-optimized theme
    cat > "$mounted_volume/lilithos/modules/themes/dark-glass/theme.css" << 'EOF'
/* LilithOS Switch Dark Glass Theme */
/* Optimized for 1280x720 and 1920x1080 displays */

:root {
  --lilithos-bg-primary: rgba(0, 0, 0, 0.9);
  --lilithos-bg-secondary: rgba(139, 0, 0, 0.4);
  --lilithos-accent-gold: #FFD700;
  --lilithos-accent-red: #8B0000;
  --lilithos-text-primary: #FFD700;
  --lilithos-border: #8B0000;
  --lilithos-highlight: rgba(255, 215, 0, 0.3);
}

/* Switch-optimized elements */
.lilithos-switch-theme {
  background: var(--lilithos-bg-primary);
  color: var(--lilithos-text-primary);
  border: 2px solid var(--lilithos-border);
  border-radius: 8px;
  font-size: 16px;
  line-height: 1.4;
}

/* Joy-Con button styling */
.joycon-button {
  background: linear-gradient(135deg, rgba(139,0,0,0.8), rgba(0,0,0,0.9));
  border: 2px solid var(--lilithos-accent-gold);
  color: var(--lilithos-accent-gold);
  border-radius: 6px;
  padding: 12px 20px;
  font-weight: bold;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.joycon-button:hover {
  background: linear-gradient(135deg, rgba(255,215,0,0.2), rgba(139,0,0,0.8));
  transform: scale(1.05);
  transition: all 0.2s ease;
}

/* Switch display optimizations */
@media (max-width: 1280px) {
  .lilithos-switch-theme {
    font-size: 14px;
  }
  
  .joycon-button {
    padding: 10px 16px;
  }
}

@media (min-width: 1920px) {
  .lilithos-switch-theme {
    font-size: 18px;
  }
  
  .joycon-button {
    padding: 14px 24px;
  }
}
EOF
    
    # Create theme initialization script
    cat > "$mounted_volume/lilithos/modules/themes/dark-glass/init.sh" << 'EOF'
#!/bin/bash
# LilithOS Switch Dark Glass Theme

echo "🎨 Applying Switch Dark Glass theme..."

# Apply theme to system
export LILITHOS_THEME="dark-glass"
export GTK_THEME="LilithOS-Switch-Dark"
export QT_STYLE_OVERRIDE="LilithOS-Switch-Dark"

# Set Switch-specific theme variables
export LILITHOS_SWITCH_THEME="enabled"
export LILITHOS_JOYCON_STYLING="enabled"

echo "✅ Switch Dark Glass theme applied"
EOF
    
    chmod +x "$mounted_volume/lilithos/modules/themes/dark-glass/init.sh"
    
    success "Switch theme installed"
}

# =============================================================================
# DOCUMENTATION
# =============================================================================

create_switch_documentation() {
    log "📚 Creating Switch documentation..."
    
    # Get the mounted volume path
    local mounted_volume=""
    if [ -d "/Volumes/LILITHOS_SWITCH" ]; then
        mounted_volume="/Volumes/LILITHOS_SWITCH"
    elif [ -d "/Volumes/NO NAME" ]; then
        mounted_volume="/Volumes/NO NAME"
    else
        error "Failed to find mounted volume"
        exit 1
    fi
    
    # Create README for Switch
    cat > "$mounted_volume/README_SWITCH.md" << 'EOF'
# LilithOS Nintendo Switch Edition

## Overview
LilithOS Nintendo Switch Edition is a custom operating system optimized for the Nintendo Switch hardware, featuring Tegra X1 optimizations and Joy-Con controller support.

## Features
- **Tegra X1 Optimized**: Custom optimizations for NVIDIA Tegra X1 chip
- **Joy-Con Support**: Full Joy-Con controller integration
- **Dual Display Modes**: Handheld (720p) and Docked (1080p)
- **Power Management**: Optimized battery life and thermal management
- **Dark Glass Theme**: Beautiful dark glass aesthetic
- **Switch-Specific UI**: Interface optimized for Switch display

## Installation

### Requirements
- Nintendo Switch (any model)
- SD Card (8GB minimum, 32GB recommended)
- RCM jig or modchip for payload injection
- USB-C cable for payload injection

### Installation Steps

1. **Prepare SD Card**
   - Format SD card as FAT32
   - Copy all files from this image to SD card root

2. **Install Custom Firmware**
   - Install Atmosphere, ReiNX, or SXOS
   - Place Hekate bootloader on SD card

3. **Inject Payload**
   - Boot Switch into RCM mode
   - Inject Hekate payload
   - Select "LilithOS Switch" from boot menu

4. **First Boot**
   - System will initialize Tegra X1 optimizations
   - Joy-Con controllers will be detected automatically
   - Dark Glass theme will be applied

## Usage

### Joy-Con Controls
- **Left Stick**: Navigate menus
- **Right Stick**: Mouse cursor (when available)
- **A Button**: Select/Confirm
- **B Button**: Back/Cancel
- **X Button**: Context menu
- **Y Button**: Quick actions
- **L/R**: Page navigation
- **ZL/ZR**: Zoom in/out
- **+/-**: System menu
- **Home**: Return to main menu
- **Capture**: Screenshot

### Display Modes
- **Handheld Mode**: 1280x720 @ 60Hz
- **Docked Mode**: 1920x1080 @ 60Hz
- **Auto-detection**: Automatically switches based on dock status

### Power Management
- **Battery Optimization**: Extended battery life
- **Thermal Management**: Prevents overheating
- **Performance Modes**: Balanced and Performance options

## System Information

### Hardware Specifications
- **CPU**: NVIDIA Tegra X1 (ARM Cortex-A57 + ARM Cortex-A53)
- **GPU**: Maxwell (256 CUDA cores)
- **Memory**: 4GB LPDDR4
- **Storage**: 32GB eMMC + SD Card
- **Display**: 6.2" LCD (1280x720)

### Performance
- **CPU Frequency**: Up to 1.785GHz
- **GPU Frequency**: Up to 768MHz
- **Memory Bandwidth**: 25.6GB/s
- **Battery Life**: 2.5-6.5 hours (depending on usage)

## Troubleshooting

### Common Issues

1. **Joy-Con Not Detected**
   - Ensure Joy-Con are properly attached
   - Try re-pairing Joy-Con
   - Check USB connections

2. **Display Issues**
   - Verify HDMI cable connection in docked mode
   - Check display resolution settings
   - Restart system if needed

3. **Performance Issues**
   - Check thermal management
   - Reduce background processes
   - Use performance mode if needed

4. **Battery Issues**
   - Check power management settings
   - Reduce screen brightness
   - Close unnecessary applications

### Support
- **GitHub**: https://github.com/M-K-World-Wide/LilithOS
- **Documentation**: Check /lilithos/docs/ for detailed guides
- **Community**: Join our Discord for support

## Legal Notice
This software is provided as-is for educational and development purposes. Users are responsible for compliance with local laws and Nintendo's terms of service.

---

*LilithOS Nintendo Switch Edition v2.0.0*
*"In the dance of ones and zeros, we find the rhythm of the soul."*
EOF
    
    success "Switch documentation created"
}

# =============================================================================
# FINALIZATION
# =============================================================================

finalize_switch_image() {
    log "🔧 Finalizing Switch image..."
    
    # Get the mounted volume path
    local mounted_volume=""
    if [ -d "/Volumes/LILITHOS_SWITCH" ]; then
        mounted_volume="/Volumes/LILITHOS_SWITCH"
    elif [ -d "/Volumes/NO NAME" ]; then
        mounted_volume="/Volumes/NO NAME"
    else
        error "Failed to find mounted volume"
        exit 1
    fi
    
    # Set proper permissions
    chmod -R 755 "$mounted_volume"
    
    # Create version file
    cat > "$mounted_volume/lilithos/VERSION" << EOF
LilithOS Nintendo Switch Edition
Version: $LILITHOS_VERSION
Build Date: $(date)
Architecture: $SWITCH_ARCH
Chip: $SWITCH_CHIP
Platform: $SWITCH_PLATFORM
EOF
    
    # Create installation script
    cat > "$mounted_volume/install_lilithos_switch.sh" << 'EOF'
#!/bin/bash
# LilithOS Switch Installation Script

echo "🌑 LilithOS Nintendo Switch Installation"
echo "========================================"

# Check if running on Switch
if ! grep -q "Nintendo Switch" /proc/device-tree/model 2>/dev/null; then
    echo "❌ This script must be run on a Nintendo Switch"
    exit 1
fi

echo "✅ Nintendo Switch detected"
echo "🔧 Installing LilithOS..."

# Copy files to system
cp -r /lilithos /usr/local/
chmod +x /usr/local/lilithos/bin/*

# Create system links
ln -sf /usr/local/lilithos/bin/lilithos /usr/local/bin/lilithos

# Initialize modules
/usr/local/lilithos/modules/chips/nintendo-switch/init.sh

echo "✅ LilithOS Switch installation complete!"
echo "🎮 You can now boot into LilithOS"
EOF
    
    chmod +x "$mounted_volume/install_lilithos_switch.sh"
    
    success "Switch image finalized"
}

cleanup_and_convert() {
    log "🧹 Cleaning up and converting..."
    
    # Get the mounted volume path
    local mounted_volume=""
    if [ -d "/Volumes/LILITHOS_SWITCH" ]; then
        mounted_volume="/Volumes/LILITHOS_SWITCH"
    elif [ -d "/Volumes/NO NAME" ]; then
        mounted_volume="/Volumes/NO NAME"
    else
        error "Failed to find mounted volume"
        exit 1
    fi
    
    # Unmount the DMG
    hdiutil detach "$mounted_volume"
    
    # Convert DMG to IMG format for Switch compatibility
    log "📦 Converting DMG to IMG format..."
    hdiutil convert "${SWITCH_IMAGE_NAME}.dmg" -format UDTO -o "${SWITCH_IMAGE_NAME}.cdr"
    mv "${SWITCH_IMAGE_NAME}.cdr" "${SWITCH_IMAGE_NAME}.img"
    
    # Compress image
    log "📦 Compressing Switch image..."
    gzip "${SWITCH_IMAGE_NAME}.img"
    
    # Create checksum
    shasum -a 256 "${SWITCH_IMAGE_NAME}.img.gz" > "${SWITCH_IMAGE_NAME}.img.gz.sha256"
    
    # Clean up DMG file
    rm "${SWITCH_IMAGE_NAME}.dmg"
    
    success "Switch image converted and compressed"
}

# =============================================================================
# MAIN BUILD PROCESS
# =============================================================================

main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║            LilithOS Nintendo Switch Builder - macOS          ║"
    echo "║                    Tegra X1 Optimized                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Create Switch image
    create_switch_image
    
    # Install LilithOS
    install_lilithos_core
    install_switch_modules
    install_switch_theme
    
    # Create Switch-specific files
    create_switch_boot_files
    create_switch_documentation
    
    # Finalize image
    finalize_switch_image
    cleanup_and_convert
    
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Switch Build Complete!                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "🎮 Nintendo Switch SD Card Image Created!"
    echo "📁 Image: $BUILD_DIR/${SWITCH_IMAGE_NAME}.img.gz"
    echo "🔍 Checksum: $BUILD_DIR/${SWITCH_IMAGE_NAME}.img.gz.sha256"
    echo ""
    echo "📋 Installation Instructions:"
    echo "1. Extract the .img.gz file"
    echo "2. Write the .img file to your SD card using:"
    echo "   sudo dd if=${SWITCH_IMAGE_NAME}.img of=/dev/diskX bs=1m"
    echo "3. Insert SD card into Switch"
    echo "4. Boot into RCM mode"
    echo "5. Inject Hekate payload"
    echo "6. Select 'LilithOS Switch' from boot menu"
    echo ""
    echo "🎮 Enjoy your sacred digital garden on Switch!"
    echo ""
}

# Run main function
main "$@" 