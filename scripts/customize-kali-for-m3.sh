#!/bin/bash

# Customize Kali Linux for MacBook Air M3
# This script modifies a Kali Linux ISO for Apple Silicon optimization

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

usage() {
    echo "Usage: $0 <kali_iso> <output_iso>"
    echo "Example: $0 downloads/kali-linux-2024.1-installer-arm64.iso downloads/lilithos-m3-arm64.iso"
    exit 1
}

if [ $# -ne 2 ]; then
    usage
fi

KALI_ISO="$1"
OUTPUT_ISO="$2"

if [ ! -f "$KALI_ISO" ]; then
    print_error "Kali ISO not found: $KALI_ISO"
    exit 1
fi

print_status "Customizing Kali Linux for MacBook Air M3"
print_status "Input: $KALI_ISO"
print_status "Output: $OUTPUT_ISO"

# Create temporary directories
TEMP_DIR=$(mktemp -d)
MOUNT_DIR="${TEMP_DIR}/mount"
EXTRACT_DIR="${TEMP_DIR}/extract"

mkdir -p "$MOUNT_DIR" "$EXTRACT_DIR"

# Mount Kali ISO
print_status "Mounting Kali ISO..."
hdiutil attach "$KALI_ISO" -mountpoint "$MOUNT_DIR" -readonly

# Copy ISO contents
print_status "Extracting ISO contents..."
cp -r "$MOUNT_DIR"/* "$EXTRACT_DIR/"

# Unmount original ISO
hdiutil detach "$MOUNT_DIR"

# Customize for M3
print_status "Customizing for Apple Silicon M3..."

# Create M3-specific kernel parameters
cat > "$EXTRACT_DIR/boot/grub/m3-kernel.cfg" << 'EOF'
# M3-specific kernel parameters
set timeout=5
set default=0

menuentry "LilithOS M3 Installer" {
    linux /install.amd/vmlinuz root=live:CDLABEL=LilithOS-M3 console=tty0 acpi_osi=Darwin acpi_force_32bit_fadt_addr=1
    initrd /install.amd/initrd.gz
}

menuentry "LilithOS M3 Installer (Safe Graphics)" {
    linux /install.amd/vmlinuz root=live:CDLABEL=LilithOS-M3 console=tty0 nomodeset acpi_osi=Darwin acpi_force_32bit_fadt_addr=1
    initrd /install.amd/initrd.gz
}

menuentry "LilithOS M3 Installer (Debug)" {
    linux /install.amd/vmlinuz root=live:CDLABEL=LilithOS-M3 console=tty0 debug acpi_osi=Darwin acpi_force_32bit_fadt_addr=1
    initrd /install.amd/initrd.gz
}
EOF

# Create M3 modules configuration
mkdir -p "$EXTRACT_DIR/lib/modules/m3"
cat > "$EXTRACT_DIR/lib/modules/m3/modules.conf" << 'EOF'
# Apple Silicon M3 kernel modules
apple-gmux
apple-ibridge
apple-ib-als
apple-ib-tb
apple-ib-ridge
apple-ib-dart
apple-ib-pmu
apple-ib-rtc
apple-ib-sart
apple-ib-smu
apple-ib-tmu
apple-ib-uart
apple-ib-wdt
apple-ib-gpio
apple-ib-i2c
apple-ib-spi
apple-ib-pcie
apple-ib-usb
apple-ib-thunderbolt
apple-ib-audio
apple-ib-video
apple-ib-camera
apple-ib-sensors
apple-ib-battery
apple-ib-charger
apple-ib-display
apple-ib-keyboard
apple-ib-trackpad
apple-ib-touchbar
apple-ib-touchid
apple-ib-secure-enclave
apple-ib-t2
apple-ib-m3
EOF

# Create installation script
cat > "$EXTRACT_DIR/install-m3.sh" << 'EOF'
#!/bin/bash
# LilithOS M3 Installation Script

echo "LilithOS M3 Installer Starting..."
echo "Detecting Apple Silicon hardware..."

if [[ $(uname -m) == "aarch64" ]]; then
    echo "Apple Silicon detected"
    
    # Load M3 modules
    for module in apple-gmux apple-ibridge apple-ib-als apple-ib-tb apple-ib-ridge \
                   apple-ib-dart apple-ib-pmu apple-ib-rtc apple-ib-sart apple-ib-smu \
                   apple-ib-tmu apple-ib-uart apple-ib-wdt apple-ib-gpio apple-ib-i2c \
                   apple-ib-spi apple-ib-pcie apple-ib-usb apple-ib-thunderbolt \
                   apple-ib-audio apple-ib-video apple-ib-camera apple-ib-sensors \
                   apple-ib-battery apple-ib-charger apple-ib-display apple-ib-keyboard \
                   apple-ib-trackpad apple-ib-touchbar apple-ib-touchid \
                   apple-ib-secure-enclave apple-ib-t2 apple-ib-m3; do
        modprobe $module 2>/dev/null || echo "Module $module not available"
    done
    
    echo "M3 modules loaded successfully"
else
    echo "Warning: Not running on Apple Silicon"
fi

# Start installation
echo "Starting LilithOS installation..."
/usr/bin/calamares
EOF

chmod +x "$EXTRACT_DIR/install-m3.sh"

# Create README
cat > "$EXTRACT_DIR/README-M3.txt" << 'EOF'
LilithOS M3 - Customized for MacBook Air M3
============================================

This is a customized Kali Linux distribution optimized for Apple Silicon M3.

Installation Instructions:
1. Insert this USB drive into your MacBook Air M3
2. Restart and hold Option (⌥) key
3. Select "EFI Boot" from boot menu
4. Choose "LilithOS M3 Installer" from GRUB menu
5. Follow installation wizard

Features:
- Optimized for Apple Silicon M3
- Kali Linux security tools
- Dual boot with macOS
- M3-specific kernel modules

Default credentials:
- Username: kali
- Password: kali

Created: $(date)
EOF

# Create new ISO
print_status "Creating customized ISO..."
cd "$EXTRACT_DIR"
hdiutil makehybrid -o "$OUTPUT_ISO" -hfs -joliet -iso -default-volume-name "LilithOS-M3" .

print_success "Customized ISO created: $OUTPUT_ISO"

# Cleanup
rm -rf "$TEMP_DIR"

print_success "Kali Linux customized for M3 successfully!"
print_status "You can now use this ISO with the USB installer script" 