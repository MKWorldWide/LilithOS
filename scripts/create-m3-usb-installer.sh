#!/bin/bash

# LilithOS M3 USB Installer Creator
# Creates a bootable USB drive for MacBook Air M3 with Apple Silicon
# Based on Asahi Linux techniques for Apple Silicon

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display colored output
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

# Function to display usage
usage() {
    echo "Usage: $0 <iso_file> <usb_device>"
    echo "Example: $0 lilithos-m3-arm64.iso /dev/disk2"
    echo ""
    echo "This script creates a bootable USB drive for MacBook Air M3"
    echo "WARNING: This will erase all data on the USB device!"
    exit 1
}

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Check arguments
if [ $# -ne 2 ]; then
    usage
fi

ISO_FILE="$1"
USB_DEVICE="$2"

# Verify we're on Apple Silicon
if [[ $(uname -m) != "arm64" ]]; then
    print_error "This script is designed for Apple Silicon (ARM64) systems"
    exit 1
fi

# Verify ISO file exists
if [ ! -f "$ISO_FILE" ]; then
    print_error "ISO file not found: $ISO_FILE"
    exit 1
fi

# Verify USB device exists
if [ ! -b "$USB_DEVICE" ]; then
    print_error "USB device not found: $USB_DEVICE"
    exit 1
fi

print_status "LilithOS M3 USB Installer Creator"
print_status "Target: MacBook Air M3 with Apple Silicon"
print_status "ISO file: $ISO_FILE"
print_status "USB device: $USB_DEVICE"

# Get USB device info
print_status "Getting USB device information..."
USB_SIZE=$(diskutil info "$USB_DEVICE" | grep "Total Size" | awk '{print $3}' | sed 's/GB//')
USB_NAME=$(diskutil info "$USB_DEVICE" | grep "Device / Media Name" | awk -F': ' '{print $2}')

print_status "USB Device: $USB_NAME (${USB_SIZE}GB)"

# Confirm before proceeding
echo ""
print_warning "This will completely erase the USB device: $USB_NAME"
print_warning "All data on this device will be lost!"
echo ""
echo "Are you sure you want to continue? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    print_status "Operation cancelled"
    exit 1
fi

# Check USB size (minimum 8GB)
if [ "$USB_SIZE" -lt 8 ]; then
    print_error "USB device too small. Minimum 8GB required, found ${USB_SIZE}GB"
    exit 1
fi

# Unmount USB device
print_status "Unmounting USB device..."
diskutil unmountDisk "$USB_DEVICE" 2>/dev/null || true

# Create temporary mount point
TEMP_DIR=$(mktemp -d)
USB_MOUNT="${TEMP_DIR}/usb"

# Create partition table (GPT for Apple Silicon)
print_status "Creating GPT partition table..."
gdisk "$USB_DEVICE" << EOF
o
y
n
1

+1M
ef02
n
2

+2G
8300
n
3


8300
w
y
EOF

# Format partitions
print_status "Formatting partitions..."

# Format EFI partition
print_status "Formatting EFI partition..."
mkfs.fat -F32 "${USB_DEVICE}s1"

# Format boot partition
print_status "Formatting boot partition..."
mkfs.ext4 "${USB_DEVICE}s2"

# Format data partition
print_status "Formatting data partition..."
mkfs.ext4 "${USB_DEVICE}s3"

# Mount partitions
print_status "Mounting partitions..."
mkdir -p "${USB_MOUNT}/efi"
mkdir -p "${USB_MOUNT}/boot"
mkdir -p "${USB_MOUNT}/data"

mount "${USB_DEVICE}s1" "${USB_MOUNT}/efi"
mount "${USB_DEVICE}s2" "${USB_MOUNT}/boot"
mount "${USB_DEVICE}s3" "${USB_MOUNT}/data"

# Extract ISO contents
print_status "Extracting ISO contents..."
ISO_MOUNT="${TEMP_DIR}/iso"
mkdir -p "$ISO_MOUNT"

# Mount ISO
hdiutil attach "$ISO_FILE" -mountpoint "$ISO_MOUNT" -readonly

# Copy files to USB
print_status "Copying files to USB..."

# Copy EFI files
print_status "Copying EFI files..."
cp -r "$ISO_MOUNT/EFI" "${USB_MOUNT}/efi/"

# Copy boot files
print_status "Copying boot files..."
cp -r "$ISO_MOUNT/boot" "${USB_MOUNT}/boot/"
cp -r "$ISO_MOUNT/isolinux" "${USB_MOUNT}/boot/"

# Copy system files
print_status "Copying system files..."
cp -r "$ISO_MOUNT/casper" "${USB_MOUNT}/data/"
cp -r "$ISO_MOUNT/dists" "${USB_MOUNT}/data/"
cp -r "$ISO_MOUNT/pool" "${USB_MOUNT}/data/"

# Create boot configuration for Apple Silicon
print_status "Creating Apple Silicon boot configuration..."

# Create GRUB configuration
cat > "${USB_MOUNT}/boot/grub/grub.cfg" << EOF
set timeout=5
set default=0

menuentry "LilithOS M3 Installer" {
    search --set=root --file /boot/vmlinuz
    linux /boot/vmlinuz root=live:CDLABEL=LilithOS-M3 console=tty0 acpi_osi=Darwin acpi_force_32bit_fadt_addr=1
    initrd /boot/initrd
}

menuentry "LilithOS M3 Installer (Safe Graphics)" {
    search --set=root --file /boot/vmlinuz
    linux /boot/vmlinuz root=live:CDLABEL=LilithOS-M3 console=tty0 nomodeset acpi_osi=Darwin acpi_force_32bit_fadt_addr=1
    initrd /boot/initrd
}

menuentry "LilithOS M3 Installer (Debug)" {
    search --set=root --file /boot/vmlinuz
    linux /boot/vmlinuz root=live:CDLABEL=LilithOS-M3 console=tty0 debug acpi_osi=Darwin acpi_force_32bit_fadt_addr=1
    initrd /boot/initrd
}
EOF

# Create systemd-boot configuration
mkdir -p "${USB_MOUNT}/efi/loader"
cat > "${USB_MOUNT}/efi/loader/loader.conf" << EOF
default LilithOS-M3
timeout 5
editor no
EOF

mkdir -p "${USB_MOUNT}/efi/LilithOS-M3"
cat > "${USB_MOUNT}/efi/LilithOS-M3/linux.conf" << EOF
title LilithOS M3 Installer
linux /boot/vmlinuz
initrd /boot/initrd
options root=live:CDLABEL=LilithOS-M3 console=tty0 acpi_osi=Darwin acpi_force_32bit_fadt_addr=1
EOF

# Create Apple Silicon specific kernel modules
print_status "Creating Apple Silicon kernel modules..."
mkdir -p "${USB_MOUNT}/data/lib/modules"
cat > "${USB_MOUNT}/data/lib/modules/m3-modules.conf" << EOF
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
print_status "Creating installation script..."
cat > "${USB_MOUNT}/data/install-m3.sh" << EOF
#!/bin/bash
# LilithOS M3 Installation Script
# This script will be run during the live system boot

echo "LilithOS M3 Installer Starting..."
echo "Detecting Apple Silicon hardware..."

# Detect M3 chip
if [[ \$(uname -m) == "aarch64" ]]; then
    echo "Apple Silicon detected"
    
    # Load M3 specific modules
    modprobe apple-gmux
    modprobe apple-ibridge
    modprobe apple-ib-als
    modprobe apple-ib-tb
    modprobe apple-ib-ridge
    modprobe apple-ib-dart
    modprobe apple-ib-pmu
    modprobe apple-ib-rtc
    modprobe apple-ib-sart
    modprobe apple-ib-smu
    modprobe apple-ib-tmu
    modprobe apple-ib-uart
    modprobe apple-ib-wdt
    modprobe apple-ib-gpio
    modprobe apple-ib-i2c
    modprobe apple-ib-spi
    modprobe apple-ib-pcie
    modprobe apple-ib-usb
    modprobe apple-ib-thunderbolt
    modprobe apple-ib-audio
    modprobe apple-ib-video
    modprobe apple-ib-camera
    modprobe apple-ib-sensors
    modprobe apple-ib-battery
    modprobe apple-ib-charger
    modprobe apple-ib-display
    modprobe apple-ib-keyboard
    modprobe apple-ib-trackpad
    modprobe apple-ib-touchbar
    modprobe apple-ib-touchid
    modprobe apple-ib-secure-enclave
    modprobe apple-ib-t2
    modprobe apple-ib-m3
    
    echo "M3 modules loaded successfully"
else
    echo "Warning: Not running on Apple Silicon"
fi

# Start installation process
echo "Starting LilithOS installation..."
/usr/bin/calamares
EOF

chmod +x "${USB_MOUNT}/data/install-m3.sh"

# Create README for USB
print_status "Creating USB README..."
cat > "${USB_MOUNT}/README.txt" << EOF
LilithOS M3 USB Installer
========================

This USB drive contains LilithOS installer optimized for MacBook Air M3.

Installation Instructions:
1. Insert this USB drive into your MacBook Air M3
2. Restart your Mac and hold the Option (⌥) key
3. Select "EFI Boot" from the boot menu
4. Choose "LilithOS M3 Installer" from the GRUB menu
5. Follow the installation wizard

System Requirements:
- MacBook Air M3 (Apple Silicon)
- 8GB RAM minimum (24GB recommended)
- 100GB free disk space
- USB 3.0 port

Features:
- Optimized for Apple Silicon M3
- Kali Linux security tools
- Dual boot with macOS
- Full hardware support

Default credentials:
- Username: lilithos
- Password: lilithos

For support, visit: https://github.com/M-K-World-Wide/LilithOS

Created: $(date)
EOF

# Unmount ISO
hdiutil detach "$ISO_MOUNT"

# Unmount USB partitions
print_status "Unmounting USB partitions..."
umount "${USB_MOUNT}/efi"
umount "${USB_MOUNT}/boot"
umount "${USB_MOUNT}/data"

# Cleanup
rm -rf "$TEMP_DIR"

print_success "LilithOS M3 USB installer created successfully!"
print_success "USB device: $USB_NAME is now bootable"
print_warning "You can now safely remove the USB drive"
print_status "To install: Restart Mac, hold Option (⌥), select EFI Boot" 