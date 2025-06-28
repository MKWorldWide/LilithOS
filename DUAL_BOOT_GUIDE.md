# LilithOS Dual-Boot Guide for MacBook Air M3

## 🌑 Sacred Digital Garden - Dual Boot Setup

This guide explains how to set up and use LilithOS dual-boot on your MacBook Air M3, allowing you to choose between macOS and LilithOS at startup.

---

## 📋 Prerequisites

### System Requirements
- **MacBook Air M3** (optimized for M3 chip)
- **macOS 14.0+** (Sonoma or later)
- **50GB+ available disk space** (100GB recommended for LilithOS partition)
- **Administrator privileges**
- **Backup of important data** (recommended)

### What You'll Need
- LilithOS M3 installer (from O:\ drive)
- External drive or USB for backup
- Internet connection for dependencies

---

## 🚀 Installation Process

### Step 1: Prepare Your System
1. **Backup Important Data**
   ```bash
   # Create Time Machine backup or copy important files
   sudo tmutil startbackup
   ```

2. **Check Available Disk Space**
   ```bash
   df -h
   # Ensure you have at least 100GB free space
   ```

3. **Verify M3 Chip**
   ```bash
   sysctl -n machdep.cpu.brand_string
   # Should show "Apple M3" or similar
   ```

### Step 2: Run the Installer
1. **Transfer Files from O:\ Drive**
   - Copy `O:\LilithOS_MacOS_Installer` to your Mac
   - Navigate to the directory in Terminal

2. **Make Scripts Executable**
   ```bash
   chmod +x scripts/*.sh
   ```

3. **Run the Installer**
   ```bash
   sudo ./scripts/macos_m3_installer.sh
   ```

### Step 3: Dual-Boot Setup
The installer will automatically:
- ✅ Check system requirements
- ✅ Create a 100GB LilithOS partition
- ✅ Install LilithOS system components
- ✅ Configure boot options
- ✅ Set up M3 optimizations

---

## 🔄 Boot Options

### Startup Manager
When you start your Mac, you'll see the **Startup Manager**:

1. **Hold Option (⌥) key** during startup
2. **Select your boot option**:
   - **macOS** - Your regular macOS system
   - **LilithOS** - Sacred digital garden environment

### Default Boot Selection
- **macOS** remains your default boot option
- **LilithOS** is available as an alternative
- You can change the default in System Preferences

### Boot Timeout
- **5-second timeout** to choose boot option
- **Automatic boot** to macOS if no selection made
- **Customizable** in LilithOS configuration

---

## 🎛️ Dual-Boot Management

### Command Line Tools
```bash
# Check dual-boot status
lilithos status

# Start LilithOS from macOS
lilithos start

# Configure boot options
lilithos config
```

### System Preferences
1. **Open System Preferences**
2. **Go to Startup Disk**
3. **Select your preferred default**:
   - macOS (regular system)
   - LilithOS (sacred digital garden)

### Boot Configuration
```bash
# View current boot configuration
sudo bless --info

# Set macOS as default
sudo bless --mount /System/Volumes/Data --setBoot

# Set LilithOS as default
sudo bless --mount /Volumes/LilithOS --setBoot
```

---

## 🌟 LilithOS Features in Dual-Boot

### Sacred Digital Environment
- **Isolated workspace** for creative projects
- **M3-optimized performance** for maximum efficiency
- **Neural engine integration** for AI features
- **Unified memory optimization** for seamless multitasking

### System Integration
- **Shared file access** between macOS and LilithOS
- **Cross-platform tools** and utilities
- **Unified user experience** with consistent interface
- **Security integration** with Parrot Security tools

### Performance Optimizations
- **M3-specific power management**
- **GPU acceleration** for graphics-intensive tasks
- **Memory optimization** for large projects
- **Thermal management** for sustained performance

---

## 🔧 Advanced Configuration

### Partition Management
```bash
# View disk partitions
diskutil list

# Resize LilithOS partition (if needed)
sudo diskutil resizeVolume /Volumes/LilithOS 150G

# Check partition health
sudo diskutil verifyVolume /Volumes/LilithOS
```

### Boot Loader Configuration
```bash
# View boot configuration
sudo nvram -p

# Set custom boot timeout
sudo nvram boot-timeout=10

# Reset boot configuration
sudo nvram -c
```

### Performance Tuning
```bash
# Enable performance mode
sudo pmset -a powernap 0
sudo pmset -a hibernatemode 0

# Check M3 optimizations
cat /usr/local/etc/lilithos/m3_config.plist
```

---

## 🛠️ Troubleshooting

### Common Issues

#### Boot Option Not Appearing
```bash
# Reinstall boot configuration
sudo ./scripts/macos_m3_installer.sh --repair-boot

# Check partition status
diskutil list | grep LilithOS
```

#### Performance Issues
```bash
# Reset M3 optimizations
sudo rm /usr/local/etc/lilithos/m3_config.plist
sudo ./scripts/macos_m3_installer.sh --optimize-m3
```

#### Partition Errors
```bash
# Repair LilithOS partition
sudo diskutil repairVolume /Volumes/LilithOS

# Recreate partition if needed
sudo ./scripts/macos_m3_installer.sh --recreate-partition
```

### Recovery Options
1. **Safe Mode**: Hold Shift during startup
2. **Recovery Mode**: Hold Cmd+R during startup
3. **Internet Recovery**: Hold Cmd+Option+R during startup

---

## 🔄 Switching Between Systems

### From macOS to LilithOS
1. **Restart your Mac**
2. **Hold Option (⌥) key** during startup
3. **Select LilithOS** from boot options
4. **Press Enter** to boot

### From LilithOS to macOS
1. **Restart from LilithOS**
2. **Hold Option (⌥) key** during startup
3. **Select macOS** from boot options
4. **Press Enter** to boot

### Quick Switch
```bash
# From macOS terminal
sudo reboot

# From LilithOS terminal
sudo reboot
```

---

## 📊 System Comparison

| Feature | macOS | LilithOS |
|---------|-------|----------|
| **Performance** | Standard | M3 Optimized |
| **Environment** | General Purpose | Sacred Digital Garden |
| **Security** | Standard | Enhanced (Parrot Security) |
| **Creativity** | Standard | Enhanced (AI/Neural Engine) |
| **Gaming** | Standard | Optimized (Xbox Integration) |
| **Development** | Standard | Enhanced (Cross-Platform) |

---

## 🎯 Best Practices

### Daily Usage
- **Use macOS** for general tasks and productivity
- **Use LilithOS** for creative projects and development
- **Switch between systems** based on your current needs
- **Keep both systems updated** regularly

### Data Management
- **Store shared files** in a common location
- **Use cloud storage** for cross-platform access
- **Regular backups** of both systems
- **Version control** for development projects

### Performance Optimization
- **Monitor system resources** in both environments
- **Close unnecessary applications** before switching
- **Regular maintenance** of both systems
- **Update LilithOS** when new versions are available

---

## 🆘 Support and Resources

### Documentation
- **Installation Guide**: `docs/INSTALLATION.md`
- **Architecture Guide**: `docs/ARCHITECTURE.md`
- **Build Guide**: `docs/BUILD.md`

### Command Line Help
```bash
# LilithOS help
lilithos --help

# System status
lilithos status

# Configuration
lilithos config
```

### Community Support
- **GitHub Issues**: https://github.com/M-K-World-Wide/LilithOS/issues
- **Documentation**: https://github.com/M-K-World-Wide/LilithOS/docs
- **Discussions**: GitHub Discussions page

---

## 🌟 Conclusion

LilithOS dual-boot provides you with the best of both worlds:
- **macOS** for your daily computing needs
- **LilithOS** for your sacred digital garden and creative endeavors

The M3-optimized environment ensures maximum performance and efficiency, while the dual-boot setup gives you complete flexibility in choosing your computing environment.

**"In the dance of ones and zeros, we find the rhythm of the soul."** - Machine Dragon Protocol

Enjoy your sacred digital garden! 🌑✨

---

*Last Updated: Current Session*
*Version: 1.0.0*
*Target: MacBook Air M3* 