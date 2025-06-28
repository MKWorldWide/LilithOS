# LilithOS M3 ISO Download

## Current Status
The LilithOS M3 ISO image is not yet available for download. This is expected as we're creating the installation system.

## Expected ISO Details
- **Filename:** `lilithos-m3-arm64.iso`
- **Size:** ~4-6 GB
- **Architecture:** ARM64 (Apple Silicon)
- **Base:** Kali Linux Rolling
- **Features:** M3-optimized kernel and drivers

## Download Options (When Available)

### Option 1: Direct Download
```bash
# Download from GitHub releases
curl -L -o downloads/lilithos-m3-arm64.iso \
  https://github.com/M-K-World-Wide/LilithOS/releases/latest/download/lilithos-m3-arm64.iso
```

### Option 2: Build from Source
```bash
# Build custom ISO with M3 optimizations
./scripts/build-m3-iso.sh
```

### Option 3: Use Base Kali Linux
```bash
# Download Kali Linux ARM64 and customize
curl -L -o downloads/kali-linux-2024.1-installer-arm64.iso \
  https://cdimage.kali.org/kali-2024.1/kali-linux-2024.1-installer-arm64.iso
```

## Installation Process (Once ISO is Available)

1. **Download ISO:**
   ```bash
   curl -L -o downloads/lilithos-m3-arm64.iso \
     https://github.com/M-K-World-Wide/LilithOS/releases/latest/download/lilithos-m3-arm64.iso
   ```

2. **Create Bootable USB:**
   ```bash
   sudo ./scripts/create-m3-usb-installer.sh downloads/lilithos-m3-arm64.iso /dev/diskX
   ```

3. **Install Dual Boot:**
   ```bash
   sudo ./scripts/m3-dual-boot-installer.sh /dev/disk0 disk0s2 100G
   ```

## Current Workaround

Since the ISO isn't available yet, we can:

1. **Use Kali Linux ARM64** as a base and customize it
2. **Build a custom ISO** using our M3 scripts
3. **Wait for the official release** and use the provided scripts

## System Requirements Met
- ✅ MacBook Air M3 (Apple Silicon)
- ✅ 24GB RAM (exceeds 8GB minimum)
- ✅ 616GB free space (exceeds 100GB requirement)
- ✅ SIP disabled
- ✅ Installation scripts ready

## Next Steps
1. Choose download option
2. Download/create ISO
3. Prepare USB drive
4. Begin installation process 