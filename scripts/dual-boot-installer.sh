#!/bin/bash

# LilithOS Dual Boot Installer
# This script handles the installation of LilithOS alongside macOS

set -e

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Function to display usage
usage() {
    echo "Usage: $0 <target_disk> <macos_partition> <lilithos_size>"
    echo "Example: $0 /dev/disk0 disk0s2 100G"
    exit 1
}

# Check arguments
if [ $# -ne 3 ]; then
    usage
fi

TARGET_DISK="$1"
MACOS_PARTITION="$2"
LILITHOS_SIZE="$3"

# Verify disk exists
if [ ! -b "$TARGET_DISK" ]; then
    echo "Error: Target disk not found at $TARGET_DISK"
    exit 1
fi

# Verify macOS partition exists
if [ ! -b "$MACOS_PARTITION" ]; then
    echo "Error: macOS partition not found at $MACOS_PARTITION"
    exit 1
fi

# Confirm before proceeding
echo "WARNING: This will modify your disk layout"
echo "Target disk: $TARGET_DISK"
echo "macOS partition: $MACOS_PARTITION"
echo "LilithOS size: $LILITHOS_SIZE"
echo "Are you sure you want to continue? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Operation cancelled"
    exit 1
fi

# Backup current partition table
echo "Backing up current partition table..."
sfdisk -d "$TARGET_DISK" > /tmp/partition_backup.txt

# Create new partition for LilithOS
echo "Creating partition for LilithOS..."
parted "$TARGET_DISK" mkpart primary ext4 "$LILITHOS_SIZE" 100%

# Format LilithOS partition
echo "Formatting LilithOS partition..."
mkfs.ext4 "${TARGET_DISK}3"

# Create mount points
echo "Creating mount points..."
TEMP_DIR=$(mktemp -d)
LILITHOS_MOUNT="${TEMP_DIR}/lilithos"

mkdir -p "$LILITHOS_MOUNT"

# Mount LilithOS partition
echo "Mounting LilithOS partition..."
mount "${TARGET_DISK}3" "$LILITHOS_MOUNT"

# Install base system
echo "Installing base system..."
debootstrap --arch amd64 kali-rolling "$LILITHOS_MOUNT" http://http.kali.org/kali

# Configure system
echo "Configuring system..."
cat > "$LILITHOS_MOUNT/etc/apt/sources.list" << EOF
deb http://http.kali.org/kali kali-rolling main contrib non-free
deb-src http://http.kali.org/kali kali-rolling main contrib non-free
EOF

# Install GRUB
echo "Installing GRUB..."
chroot "$LILITHOS_MOUNT" apt-get update
chroot "$LILITHOS_MOUNT" apt-get install -y grub-efi-amd64

# Configure GRUB
echo "Configuring GRUB..."
cat > "$LILITHOS_MOUNT/etc/default/grub" << EOF
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="LilithOS"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX=""
GRUB_TERMINAL=console
GRUB_DISABLE_OS_PROBER=false
EOF

# Install GRUB to EFI
echo "Installing GRUB to EFI..."
chroot "$LILITHOS_MOUNT" grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=LilithOS
chroot "$LILITHOS_MOUNT" update-grub

# Cleanup
echo "Cleaning up..."
umount "$LILITHOS_MOUNT"
rm -rf "$TEMP_DIR"

echo "Dual boot installation complete!"
echo "Please reboot your system and select LilithOS from the boot menu" 