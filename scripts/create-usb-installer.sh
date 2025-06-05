#!/bin/bash

# LilithOS USB Installer Creator
# This script creates a bootable USB installer for LilithOS

set -e

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Function to display usage
usage() {
    echo "Usage: $0 <iso_path> <usb_device>"
    echo "Example: $0 ./lilithos.iso /dev/sdb"
    exit 1
}

# Check arguments
if [ $# -ne 2 ]; then
    usage
fi

ISO_PATH="$1"
USB_DEVICE="$2"

# Verify ISO exists
if [ ! -f "$ISO_PATH" ]; then
    echo "Error: ISO file not found at $ISO_PATH"
    exit 1
fi

# Verify USB device exists
if [ ! -b "$USB_DEVICE" ]; then
    echo "Error: USB device not found at $USB_DEVICE"
    exit 1
fi

# Confirm before proceeding
echo "WARNING: This will erase all data on $USB_DEVICE"
echo "Are you sure you want to continue? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Operation cancelled"
    exit 1
fi

# Unmount any mounted partitions
echo "Unmounting any mounted partitions..."
umount "${USB_DEVICE}"* 2>/dev/null || true

# Create partition table and partitions
echo "Creating partition table and partitions..."
parted "$USB_DEVICE" mklabel gpt
parted "$USB_DEVICE" mkpart primary fat32 1MiB 512MiB
parted "$USB_DEVICE" set 1 boot on
parted "$USB_DEVICE" mkpart primary ext4 512MiB 100%

# Format partitions
echo "Formatting partitions..."
mkfs.fat -F32 "${USB_DEVICE}1"
mkfs.ext4 "${USB_DEVICE}2"

# Create mount points
echo "Creating mount points..."
TEMP_DIR=$(mktemp -d)
USB_MOUNT="${TEMP_DIR}/usb"
ISO_MOUNT="${TEMP_DIR}/iso"

mkdir -p "$USB_MOUNT" "$ISO_MOUNT"

# Mount ISO and USB
echo "Mounting ISO and USB..."
mount "$ISO_PATH" "$ISO_MOUNT"
mount "${USB_DEVICE}2" "$USB_MOUNT"

# Copy files
echo "Copying files..."
rsync -av --progress "$ISO_MOUNT/" "$USB_MOUNT/"

# Install GRUB
echo "Installing GRUB..."
grub-install --target=x86_64-efi --boot-directory="$USB_MOUNT/boot" --efi-directory="$USB_MOUNT" --removable

# Create GRUB configuration
echo "Creating GRUB configuration..."
cat > "$USB_MOUNT/boot/grub/grub.cfg" << EOF
set timeout=5
set default=0

menuentry "LilithOS Installer" {
    linux /casper/vmlinuz boot=casper quiet splash
    initrd /casper/initrd
}

menuentry "LilithOS Installer (Safe Graphics)" {
    linux /casper/vmlinuz boot=casper quiet splash nomodeset
    initrd /casper/initrd
}
EOF

# Cleanup
echo "Cleaning up..."
umount "$ISO_MOUNT"
umount "$USB_MOUNT"
rm -rf "$TEMP_DIR"

echo "USB installer creation complete!"
echo "You can now boot from this USB device to install LilithOS" 