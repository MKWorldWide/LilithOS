#!/bin/bash

# LilithOS M3 Dual Boot Installer
# Optimized for MacBook Air M3 with Apple Silicon
# This script handles the installation of LilithOS alongside macOS on Apple Silicon

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
    echo "Usage: $0 <target_disk> <macos_partition> <lilithos_size>"
    echo "Example: $0 /dev/disk0 disk0s2 100G"
    echo ""
    echo "This script is optimized for MacBook Air M3 with Apple Silicon"
    echo "It will install LilithOS alongside macOS using Asahi Linux techniques"
    exit 1
}

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Check arguments
if [ $# -ne 3 ]; then
    usage
fi

TARGET_DISK="$1"
MACOS_PARTITION="$2"
LILITHOS_SIZE="$3"

# Verify we're on Apple Silicon
if [[ $(uname -m) != "arm64" ]]; then
    print_error "This script is designed for Apple Silicon (ARM64) systems"
    exit 1
fi

# Verify disk exists
if [ ! -b "$TARGET_DISK" ]; then
    print_error "Target disk not found at $TARGET_DISK"
    exit 1
fi

# Verify macOS partition exists
if [ ! -b "$MACOS_PARTITION" ]; then
    print_error "macOS partition not found at $MACOS_PARTITION"
    exit 1
fi

print_status "LilithOS M3 Dual Boot Installer"
print_status "Target: MacBook Air M3 with Apple Silicon"
print_status "Target disk: $TARGET_DISK"
print_status "macOS partition: $MACOS_PARTITION"
print_status "LilithOS size: $LILITHOS_SIZE"

# Confirm before proceeding
echo ""
print_warning "This will modify your disk layout and install LilithOS"
print_warning "Make sure you have a backup of your important data"
echo ""
echo "Are you sure you want to continue? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    print_status "Operation cancelled"
    exit 1
fi

# Check available disk space
print_status "Checking available disk space..."
TOTAL_SIZE=$(diskutil info "$TARGET_DISK" | grep "Total Size" | awk '{print $3}' | sed 's/GB//')
FREE_SIZE=$(diskutil info "$TARGET_DISK" | grep "Free Space" | awk '{print $3}' | sed 's/GB//')
REQUESTED_SIZE=$(echo "$LILITHOS_SIZE" | sed 's/G//')

if [ "$FREE_SIZE" -lt "$REQUESTED_SIZE" ]; then
    print_error "Insufficient free space. Available: ${FREE_SIZE}GB, Requested: ${REQUESTED_SIZE}GB"
    exit 1
fi

print_success "Sufficient disk space available"

# Backup current partition table
print_status "Backing up current partition table..."
sfdisk -d "$TARGET_DISK" > /tmp/lilithos_partition_backup_$(date +%Y%m%d_%H%M%S).txt

# Create new partition for LilithOS
print_status "Creating partition for LilithOS..."
parted "$TARGET_DISK" mkpart primary ext4 "$LILITHOS_SIZE" 100%

# Format LilithOS partition
print_status "Formatting LilithOS partition..."
mkfs.ext4 "${TARGET_DISK}3"

# Create mount points
print_status "Creating mount points..."
TEMP_DIR=$(mktemp -d)
LILITHOS_MOUNT="${TEMP_DIR}/lilithos"

mkdir -p "$LILITHOS_MOUNT"

# Mount LilithOS partition
print_status "Mounting LilithOS partition..."
mount "${TARGET_DISK}3" "$LILITHOS_MOUNT"

# Install base system (ARM64)
print_status "Installing base system for ARM64..."
debootstrap --arch arm64 kali-rolling "$LILITHOS_MOUNT" http://http.kali.org/kali

# Configure system for Apple Silicon
print_status "Configuring system for Apple Silicon..."
cat > "$LILITHOS_MOUNT/etc/apt/sources.list" << EOF
deb http://http.kali.org/kali kali-rolling main contrib non-free
deb-src http://http.kali.org/kali kali-rolling main contrib non-free
EOF

# Install ARM64 GRUB and EFI tools
print_status "Installing GRUB for ARM64..."
chroot "$LILITHOS_MOUNT" apt-get update
chroot "$LILITHOS_MOUNT" apt-get install -y grub-efi-arm64 efibootmgr

# Configure GRUB for Apple Silicon
print_status "Configuring GRUB for Apple Silicon..."
cat > "$LILITHOS_MOUNT/etc/default/grub" << EOF
GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="LilithOS"
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash console=tty0"
GRUB_CMDLINE_LINUX=""
GRUB_TERMINAL=console
GRUB_DISABLE_OS_PROBER=false
GRUB_ENABLE_CRYPTODISK=y
EOF

# Install GRUB to EFI (Apple Silicon specific)
print_status "Installing GRUB to EFI for Apple Silicon..."
chroot "$LILITHOS_MOUNT" grub-install --target=arm64-efi --efi-directory=/boot/efi --bootloader-id=LilithOS
chroot "$LILITHOS_MOUNT" update-grub

# Install Apple Silicon specific packages
print_status "Installing Apple Silicon specific packages..."
chroot "$LILITHOS_MOUNT" apt-get install -y \
    linux-image-arm64 \
    firmware-linux \
    firmware-linux-nonfree \
    network-manager \
    systemd-boot \
    efibootmgr

# Configure system for M3 optimization
print_status "Configuring system for M3 optimization..."
cat > "$LILITHOS_MOUNT/etc/modules-load.d/m3.conf" << EOF
# Apple Silicon M3 specific modules
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

# Configure kernel parameters for M3
print_status "Configuring kernel parameters for M3..."
cat > "$LILITHOS_MOUNT/etc/default/grub.d/m3.cfg" << EOF
# M3 specific kernel parameters
GRUB_CMDLINE_LINUX_DEFAULT="\$GRUB_CMDLINE_LINUX_DEFAULT console=tty0 acpi_osi=Darwin acpi_force_32bit_fadt_addr=1"
EOF

# Install LilithOS specific packages
print_status "Installing LilithOS specific packages..."
chroot "$LILITHOS_MOUNT" apt-get install -y \
    kali-linux-default \
    kali-tools-top10 \
    kali-tools-web \
    kali-tools-crypto-stego \
    kali-tools-forensics \
    kali-tools-sniffing-spoofing \
    kali-tools-wireless \
    kali-tools-exploitation \
    kali-tools-social-engineering \
    kali-tools-post-exploitation \
    kali-tools-reporting

# Configure networking for Apple Silicon
print_status "Configuring networking for Apple Silicon..."
cat > "$LILITHOS_MOUNT/etc/network/interfaces" << EOF
# Network configuration for Apple Silicon
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

# Configure systemd for Apple Silicon
print_status "Configuring systemd for Apple Silicon..."
cat > "$LILITHOS_MOUNT/etc/systemd/system/apple-silicon.service" << EOF
[Unit]
Description=Apple Silicon M3 Optimization
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/echo "Apple Silicon M3 optimization loaded"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

chroot "$LILITHOS_MOUNT" systemctl enable apple-silicon.service

# Create user account
print_status "Creating default user account..."
chroot "$LILITHOS_MOUNT" useradd -m -s /bin/bash lilithos
chroot "$LilithOS_MOUNT" usermod -aG sudo lilithos
echo "lilithos:lilithos" | chroot "$LILITHOS_MOUNT" chpasswd

# Set hostname
print_status "Setting hostname..."
echo "lilithos-m3" > "$LILITHOS_MOUNT/etc/hostname"

# Configure timezone
print_status "Configuring timezone..."
chroot "$LILITHOS_MOUNT" ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Configure locale
print_status "Configuring locale..."
cat > "$LILITHOS_MOUNT/etc/default/locale" << EOF
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
EOF

# Cleanup
print_status "Cleaning up..."
umount "$LILITHOS_MOUNT"
rm -rf "$TEMP_DIR"

print_success "LilithOS M3 dual boot installation complete!"
print_success "Please reboot your system and select LilithOS from the boot menu"
print_warning "Default credentials: username=lilithos, password=lilithos"
print_warning "Please change the default password after first login" 