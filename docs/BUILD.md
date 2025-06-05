# Building LilithOS

## Prerequisites
- Debian-based Linux system (Ubuntu 20.04+ recommended)
- 50GB free disk space
- 8GB RAM minimum
- Internet connection
- Root access

## Required Packages
```bash
sudo apt-get update
sudo apt-get install -y \
    debootstrap \
    debian-archive-keyring \
    live-build \
    live-config \
    live-boot \
    xorriso \
    isolinux \
    syslinux-utils \
    squashfs-tools \
    grub-efi-amd64 \
    grub-pc-bin
```

## Build Process

### 1. Initialize Build Environment
```bash
mkdir -p lilithos-build
cd lilithos-build
lb config
```

### 2. Configure Build Settings
Edit `config/binary` to include:
- Kali Linux repositories
- Custom package lists
- Kernel configuration
- Boot parameters

### 3. Build Base System
```bash
sudo lb build
```

### 4. Create Bootable Image
```bash
sudo lb binary
```

## Customization

### Kernel Configuration
1. Clone Kali Linux kernel
2. Apply Mac Pro 2009 patches
3. Build custom kernel
4. Package for distribution

### Package Selection
Edit `config/package-lists/` to include:
- Base system packages
- Security tools
- Desktop environment
- Hardware drivers

## Testing
1. Create test VM
2. Verify boot process
3. Test hardware compatibility
4. Validate security features

## Distribution
1. Create ISO image
2. Generate checksums
3. Create installation media
4. Document installation process

## Troubleshooting
- Check build logs in `build.log`
- Verify package dependencies
- Test on actual hardware
- Review system logs

## Next Steps
- Create installation guide
- Develop update mechanism
- Set up package repository
- Establish testing procedures 