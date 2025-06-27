# LilithOS M3 Installation Guide
## MacBook Air M3 with Apple Silicon

### 🍎 **System Requirements**
- **Hardware:** MacBook Air M3 (Apple Silicon)
- **RAM:** 8GB minimum (24GB recommended)
- **Storage:** 100GB free disk space for LilithOS
- **USB:** 8GB+ USB 3.0 drive for installer
- **Network:** Internet connection for updates

### 📋 **Prerequisites**
1. **Backup your data** - Always backup important files before dual boot
2. **Disable SIP** (System Integrity Protection):
   - Restart and hold `Command + R` to enter Recovery Mode
   - Open Terminal
   - Run: `csrutil disable`
   - Restart normally

### 🔧 **Step 1: Create Bootable USB**

#### Option A: Using Provided Script
```bash
# Download LilithOS M3 ISO
wget https://github.com/M-K-World-Wide/LilithOS/releases/latest/download/lilithos-m3-arm64.iso

# Create bootable USB (replace /dev/disk2 with your USB device)
sudo ./scripts/create-m3-usb-installer.sh lilithos-m3-arm64.iso /dev/disk2
```

#### Option B: Manual USB Creation
```bash
# Format USB drive as FAT32
diskutil eraseDisk FAT32 LILITHOS /dev/disk2

# Mount ISO and copy files
hdiutil attach lilithos-m3-arm64.iso -mountpoint /tmp/iso
cp -r /tmp/iso/* /Volumes/LILITHOS/
hdiutil detach /tmp/iso
```

### 🚀 **Step 2: Boot from USB**
1. Insert the bootable USB drive
2. Restart your MacBook Air M3
3. Hold the `Option (⌥)` key during startup
4. Select "EFI Boot" from the boot menu
5. Choose "LilithOS M3 Installer" from GRUB menu

### 💾 **Step 3: Install LilithOS**

#### Live System Options:
- **LilithOS M3 Installer** - Standard installation
- **LilithOS M3 Installer (Safe Graphics)** - If graphics issues occur
- **LilithOS M3 Installer (Debug)** - For troubleshooting

#### Installation Process:
1. **Language & Region:** Select your preferences
2. **Installation Type:** Choose "Dual Boot with macOS"
3. **Disk Selection:** 
   - Select your internal SSD
   - Choose partition size (recommended: 100GB+)
4. **User Account:** Create your LilithOS user
5. **System Configuration:** Review settings
6. **Installation:** Wait for completion

### 🔄 **Step 4: Post-Installation**

#### First Boot:
1. Restart and hold `Option (⌥)` key
2. Select "LilithOS" from boot menu
3. Login with your credentials

#### System Updates:
```bash
# Update package list
sudo apt update

# Upgrade system
sudo apt upgrade

# Install additional M3-specific packages
sudo apt install -y \
    linux-image-arm64 \
    firmware-linux \
    firmware-linux-nonfree \
    network-manager \
    systemd-boot \
    efibootmgr
```

#### M3 Optimization:
```bash
# Load M3-specific kernel modules
sudo modprobe apple-gmux
sudo modprobe apple-ibridge
sudo modprobe apple-ib-als
sudo modprobe apple-ib-tb
sudo modprobe apple-ib-ridge
sudo modprobe apple-ib-dart
sudo modprobe apple-ib-pmu
sudo modprobe apple-ib-rtc
sudo modprobe apple-ib-sart
sudo modprobe apple-ib-smu
sudo modprobe apple-ib-tmu
sudo modprobe apple-ib-uart
sudo modprobe apple-ib-wdt
sudo modprobe apple-ib-gpio
sudo modprobe apple-ib-i2c
sudo modprobe apple-ib-spi
sudo modprobe apple-ib-pcie
sudo modprobe apple-ib-usb
sudo modprobe apple-ib-thunderbolt
sudo modprobe apple-ib-audio
sudo modprobe apple-ib-video
sudo modprobe apple-ib-camera
sudo modprobe apple-ib-sensors
sudo modprobe apple-ib-battery
sudo modprobe apple-ib-charger
sudo modprobe apple-ib-display
sudo modprobe apple-ib-keyboard
sudo modprobe apple-ib-trackpad
sudo modprobe apple-ib-touchbar
sudo modprobe apple-ib-touchid
sudo modprobe apple-ib-secure-enclave
sudo modprobe apple-ib-t2
sudo modprobe apple-ib-m3
```

### 🛠️ **Step 5: Configuration**

#### Network Setup:
```bash
# Configure NetworkManager
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

# Connect to WiFi
nmcli device wifi connect "YourWiFiSSID" password "YourPassword"
```

#### Security Configuration:
```bash
# Enable firewall
sudo ufw enable

# Configure firewall rules
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 22
```

#### Kali Tools Installation:
```bash
# Install Kali Linux security tools
sudo apt install -y \
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
```

### 🔧 **Troubleshooting**

#### Boot Issues:
```bash
# If GRUB doesn't appear
sudo update-grub

# If macOS doesn't appear in GRUB
sudo os-prober
sudo update-grub

# Reinstall GRUB
sudo grub-install --target=arm64-efi --efi-directory=/boot/efi --bootloader-id=LilithOS
sudo update-grub
```

#### Graphics Issues:
```bash
# Boot with safe graphics mode
# Add to kernel parameters: nomodeset

# Install additional graphics drivers
sudo apt install -y firmware-linux-nonfree
```

#### Network Issues:
```bash
# Check network status
sudo systemctl status NetworkManager

# Restart network service
sudo systemctl restart NetworkManager

# Check network interfaces
ip addr show
```

#### Performance Issues:
```bash
# Check system resources
htop
free -h
df -h

# Check kernel modules
lsmod | grep apple

# Check system logs
dmesg | less
journalctl -xe
```

### 🔒 **Security Features**

#### Full Disk Encryption:
- Enable during installation
- Use strong passphrase
- Store recovery key safely

#### Firewall Configuration:
```bash
# Advanced firewall rules
sudo ufw allow from 192.168.1.0/24
sudo ufw deny from 10.0.0.0/8
sudo ufw logging on
```

#### System Hardening:
```bash
# Install security tools
sudo apt install -y \
    fail2ban \
    rkhunter \
    chkrootkit \
    lynis

# Configure fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 📱 **macOS Integration**

#### Boot Manager:
- Hold `Option (⌥)` during startup to choose OS
- Default timeout: 5 seconds
- Can be changed in GRUB configuration

#### File Sharing:
```bash
# Mount macOS partition (read-only for safety)
sudo mkdir /mnt/macos
sudo mount -t hfsplus /dev/sda2 /mnt/macos -o ro
```

#### Time Sync:
```bash
# Sync time with macOS
sudo timedatectl set-local-rtc 1
sudo hwclock --systohc
```

### 🎯 **M3-Specific Optimizations**

#### Kernel Parameters:
```bash
# Add to /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 acpi_osi=Darwin acpi_force_32bit_fadt_addr=1"
```

#### Power Management:
```bash
# Optimize for M3 power efficiency
echo 'GOVERNOR="powersave"' | sudo tee /etc/default/cpufrequtils
sudo systemctl enable cpufrequtils
```

#### Thermal Management:
```bash
# Monitor M3 temperature
sudo apt install -y lm-sensors
sudo sensors-detect --auto
sensors
```

### 📞 **Support**

#### Getting Help:
1. Check system logs: `dmesg | less`
2. Review installation logs: `cat /var/log/installer/syslog`
3. Visit GitHub issues: https://github.com/M-K-World-Wide/LilithOS/issues
4. Join community forum: [Link to be added]

#### Useful Commands:
```bash
# System information
uname -a
lscpu
lspci
lsusb

# Disk information
lsblk
fdisk -l
df -h

# Network information
ip addr show
ip route show
nmcli device status

# Boot information
efibootmgr
grub-install --version
```

### 🎉 **Congratulations!**

You now have LilithOS running on your MacBook Air M3! 

**Default Credentials:**
- Username: `lilithos`
- Password: `lilithos`

**Remember to:**
- Change default password
- Keep system updated
- Enable security features
- Backup important data regularly

**Enjoy your secure, powerful LilithOS system!** 🚀 