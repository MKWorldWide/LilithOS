# 🚀 LilithOS M3 Installation Guide
## MacBook Air M3 Dual Boot Setup

### 📋 **Current Status**
- ✅ **System Analysis:** Complete
- ✅ **Prerequisites:** All met
- ✅ **Scripts:** Ready
- 🔄 **ISO Download:** In progress
- 🔄 **USB Preparation:** Pending

### 🍎 **Your System Status**
```
Hardware: MacBook Air M3 (Apple Silicon)
Memory: 24 GB ✅
Storage: 1.0 TB (616GB available) ✅
SIP Status: DISABLED ✅
Architecture: ARM64 ✅
```

### 🎯 **Installation Options**

#### **Option 1: Use Kali Linux ARM64 (Recommended)**
```bash
# Download Kali Linux ARM64
curl -L -o downloads/kali-arm64.iso \
  https://cdimage.kali.org/kali-2024.1/kali-linux-2024.1-installer-arm64.iso

# Customize for M3
./scripts/customize-kali-for-m3.sh downloads/kali-arm64.iso downloads/lilithos-m3-arm64.iso

# Create USB installer
sudo ./scripts/create-m3-usb-installer.sh downloads/lilithos-m3-arm64.iso /dev/diskX
```

#### **Option 2: Manual Installation**
```bash
# Download base Kali Linux
curl -L -o downloads/kali-arm64.iso \
  https://cdimage.kali.org/kali-2024.1/kali-linux-2024.1-installer-arm64.iso

# Create bootable USB manually
diskutil eraseDisk FAT32 LILITHOS /dev/diskX
hdiutil attach downloads/kali-arm64.iso -mountpoint /tmp/iso
cp -r /tmp/iso/* /Volumes/LILITHOS/
hdiutil detach /tmp/iso
```

#### **Option 3: Direct Dual Boot Installation**
```bash
# Install directly using our M3 script
sudo ./scripts/m3-dual-boot-installer.sh /dev/disk0 disk0s2 100G
```

### 🔧 **Step-by-Step Installation**

#### **Phase 1: Preparation**
1. **Backup your data** (important!)
2. **Disable SIP** (already done ✅)
3. **Download ISO** (choose option above)
4. **Prepare USB drive** (8GB+ recommended)

#### **Phase 2: USB Creation**
```bash
# Identify your USB drive
diskutil list

# Create bootable USB (replace /dev/diskX with your USB)
sudo ./scripts/create-m3-usb-installer.sh downloads/lilithos-m3-arm64.iso /dev/diskX
```

#### **Phase 3: Boot and Install**
1. **Insert USB drive**
2. **Restart MacBook Air M3**
3. **Hold Option (⌥) key** during startup
4. **Select "EFI Boot"** from boot menu
5. **Choose "LilithOS M3 Installer"** from GRUB menu

#### **Phase 4: Installation Process**
1. **Language & Region:** Select preferences
2. **Installation Type:** Choose "Dual Boot with macOS"
3. **Disk Selection:** 
   - Select `/dev/disk0` (your internal SSD)
   - Choose partition size: **100GB** (recommended)
4. **User Account:** Create LilithOS user
5. **System Configuration:** Review settings
6. **Installation:** Wait for completion

#### **Phase 5: Post-Installation**
```bash
# First boot - login with your credentials
# Update system
sudo apt update && sudo apt upgrade

# Install M3-specific packages
sudo apt install -y \
    linux-image-arm64 \
    firmware-linux \
    firmware-linux-nonfree \
    network-manager \
    systemd-boot \
    efibootmgr

# Load M3 kernel modules
sudo modprobe apple-gmux apple-ibridge apple-ib-als apple-ib-tb
sudo modprobe apple-ib-ridge apple-ib-dart apple-ib-pmu apple-ib-rtc
sudo modprobe apple-ib-sart apple-ib-smu apple-ib-tmu apple-ib-uart
sudo modprobe apple-ib-wdt apple-ib-gpio apple-ib-i2c apple-ib-spi
sudo modprobe apple-ib-pcie apple-ib-usb apple-ib-thunderbolt
sudo modprobe apple-ib-audio apple-ib-video apple-ib-camera
sudo modprobe apple-ib-sensors apple-ib-battery apple-ib-charger
sudo modprobe apple-ib-display apple-ib-keyboard apple-ib-trackpad
sudo modprobe apple-ib-touchbar apple-ib-touchid apple-ib-secure-enclave
sudo modprobe apple-ib-t2 apple-ib-m3
```

### 🛠️ **Configuration**

#### **Network Setup**
```bash
# Configure NetworkManager
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

# Connect to WiFi
nmcli device wifi connect "YourWiFiSSID" password "YourPassword"
```

#### **Security Setup**
```bash
# Enable firewall
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
```

#### **Kali Tools Installation**
```bash
# Install security tools
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

#### **Boot Issues**
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

#### **Graphics Issues**
```bash
# Boot with safe graphics mode
# Add to kernel parameters: nomodeset

# Install additional graphics drivers
sudo apt install -y firmware-linux-nonfree
```

#### **Network Issues**
```bash
# Check network status
sudo systemctl status NetworkManager

# Restart network service
sudo systemctl restart NetworkManager

# Check network interfaces
ip addr show
```

### 🎉 **Success Indicators**
- ✅ Dual boot menu appears on startup
- ✅ LilithOS boots successfully
- ✅ All M3 hardware detected
- ✅ Network connectivity working
- ✅ Kali tools accessible
- ✅ macOS still boots normally

### 📞 **Support**
- **System Logs:** `dmesg | less`
- **Installation Logs:** `cat /var/log/installer/syslog`
- **GitHub Issues:** https://github.com/M-K-World-Wide/LilithOS/issues

### 🚀 **Ready to Install!**

Your system is **perfectly prepared** for LilithOS M3 installation! Choose your preferred installation option and let's get started! 💪 