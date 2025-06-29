# LilithOS Recovery Boot Guide

## 📋 Overview

The LilithOS Recovery Boot System provides direct access to recovery mode from macOS without requiring manual boot selection or external media. This system is specifically designed for MacBook Air M3 and other Apple Silicon Macs.

## 🧩 Features

### Recovery Boot Capabilities
- **Direct Recovery Boot**: Boot into recovery mode directly from macOS
- **Multiple Recovery Modes**: Emergency, Repair, Diagnostic, and Safe modes
- **Boot Manager Integration**: Seamless integration with system boot manager
- **M3 Optimization**: Optimized for Apple Silicon performance
- **Secure Boot**: Secure boot transitions with proper authentication

### Recovery Modes
1. **Emergency Mode**: Immediate boot with minimal services
2. **Repair Mode**: System repair and recovery tools
3. **Diagnostic Mode**: System diagnostics and testing
4. **Safe Mode**: Safe mode with basic functionality

## 🧷 Prerequisites

### System Requirements
- macOS 14.0+ (Sonoma)
- MacBook Air M3 or compatible Apple Silicon Mac
- Root privileges (sudo access)
- Minimum 80GB available disk space
- Xcode Command Line Tools installed

### Required Commands
- `bless` (for boot management)
- `diskutil` (for partition management)
- `sudo` (for administrative access)

## 💡 Installation

### Step 1: Run the Enhanced Installer
```bash
# Make installer executable
chmod +x macos_m3_installer.sh

# Run the installer
sudo ./macos_m3_installer.sh
```

### Step 2: Verify Installation
```bash
# Check if recovery tools are installed
ls -la /usr/local/bin/lilithos*
ls -la scripts/recovery-boot.sh
ls -la scripts/quick-recovery.sh

# Check recovery partition
diskutil list | grep LilithOS
```

## ⚡ Usage

### Quick Recovery Access

#### Method 1: Quick Recovery Script
```bash
# Interactive recovery options
sudo ./scripts/quick-recovery.sh

# Emergency recovery boot
sudo ./scripts/quick-recovery.sh emergency

# Repair mode boot
sudo ./scripts/quick-recovery.sh repair

# Diagnostic mode boot
sudo ./scripts/quick-recovery.sh diagnostic

# Safe mode boot
sudo ./scripts/quick-recovery.sh safe
```

#### Method 2: Full Recovery Boot Script
```bash
# Interactive recovery options
sudo ./scripts/recovery-boot.sh

# Emergency recovery boot
sudo ./scripts/recovery-boot.sh --emergency

# Repair mode boot
sudo ./scripts/recovery-boot.sh --repair

# Diagnostic mode boot
sudo ./scripts/recovery-boot.sh --diagnostic

# Safe mode boot
sudo ./scripts/recovery-boot.sh --safe

# Check recovery partition status
sudo ./scripts/recovery-boot.sh --status
```

#### Method 3: LilithOS CLI
```bash
# Access recovery boot options
lilithos recovery

# Access boot manager
lilithos boot-options

# Direct boot manager access
lilithos-boot-manager
```

#### Method 4: Manual Boot Selection
1. **Hold Option Key**: During system startup, hold the Option (⌥) key
2. **Select Recovery**: Choose "LilithOS_Recovery" from the boot options
3. **Enter Recovery Mode**: System will boot into recovery mode

## 🔒 Security Features

### Authentication
- All recovery boot operations require root privileges
- Secure boot transitions with proper validation
- Recovery partition integrity verification

### Boot Security
- Secure boot manager integration
- Partition validation before boot
- Recovery mode flags for different boot types

## 📁 File Structure

### Recovery Partition Layout
```
/Volumes/LilithOS_Recovery/
├── System/
│   └── Library/
│       └── CoreServices/
│           └── boot.efi
├── usr/
│   ├── local/
│   │   ├── bin/
│   │   │   └── lilithos-recovery
│   │   ├── etc/
│   │   │   ├── recovery.conf
│   │   │   ├── repair_mode.flag
│   │   │   ├── diagnostic_mode.flag
│   │   │   └── safe_mode.flag
│   │   └── share/
└── recovery_tools/
```

### System Integration
```
/usr/local/
├── bin/
│   ├── lilithos (CLI tool)
│   ├── lilithos-boot-manager
│   └── lilithos-startup-options
├── etc/
│   └── lilithos/
│       ├── config.plist
│       └── m3_config.plist
└── share/
    └── lilithos/
        └── install.log
```

## 🔧 Troubleshooting

### Common Issues

#### Recovery Partition Not Found
```bash
# Check if recovery partition exists
diskutil list | grep LilithOS

# If not found, reinstall LilithOS
sudo ./macos_m3_installer.sh
```

#### Boot Manager Not Working
```bash
# Check boot manager installation
ls -la /usr/local/bin/lilithos-boot-manager

# Reinstall boot manager
sudo ./macos_m3_installer.sh
```

#### Permission Denied
```bash
# Ensure script is executable
chmod +x scripts/recovery-boot.sh
chmod +x scripts/quick-recovery.sh

# Run with sudo
sudo ./scripts/recovery-boot.sh
```

#### Recovery Tools Missing
```bash
# Check recovery partition
sudo ./scripts/recovery-boot.sh --status

# Reinstall if tools are missing
sudo ./macos_m3_installer.sh
```

### Recovery Partition Repair
```bash
# Mount recovery partition
RECOVERY_PARTITION=$(diskutil list | grep "LilithOS_Recovery" | awk '{print $NF}')
diskutil mount "$RECOVERY_PARTITION"

# Check partition integrity
diskutil verifyVolume "$RECOVERY_PARTITION"

# Repair if needed
diskutil repairVolume "$RECOVERY_PARTITION"
```

## 📊 Performance Optimization

### M3-Specific Optimizations
- **Unified Memory**: Optimized for M3's unified memory architecture
- **Neural Engine**: Enhanced recovery tools with neural engine support
- **GPU Optimization**: Graphics acceleration in recovery mode
- **Fast Boot**: Optimized boot times for recovery mode

### Boot Time Optimization
- **Minimal Services**: Recovery mode loads only essential services
- **Fast Partition Access**: Optimized partition mounting
- **Efficient Boot Manager**: Streamlined boot selection process

## 🔄 Recovery Workflows

### Emergency Recovery
1. **Identify Issue**: Determine the nature of the system problem
2. **Choose Mode**: Select appropriate recovery mode
3. **Boot Recovery**: Use emergency recovery boot
4. **Diagnose**: Use recovery tools to diagnose issues
5. **Repair**: Apply necessary repairs
6. **Reboot**: Return to normal operation

### System Repair
1. **Boot Repair Mode**: Use repair mode boot
2. **Run Diagnostics**: Execute system diagnostics
3. **Identify Problems**: Locate system issues
4. **Apply Fixes**: Use repair tools to fix issues
5. **Verify Repair**: Confirm repairs are successful
6. **Return to Normal**: Boot back to macOS

### Diagnostic Testing
1. **Boot Diagnostic Mode**: Use diagnostic mode boot
2. **Run Tests**: Execute comprehensive system tests
3. **Collect Data**: Gather diagnostic information
4. **Analyze Results**: Review test results
5. **Generate Report**: Create diagnostic report
6. **Plan Actions**: Determine necessary actions

## 📝 Logging and Monitoring

### Log Files
- **Installation Log**: `/usr/local/share/lilithos/install.log`
- **Recovery Boot Log**: `/var/log/lilithos_recovery_boot.log`
- **System Log**: `/var/log/system.log`

### Monitoring Commands
```bash
# Check recovery boot logs
tail -f /var/log/lilithos_recovery_boot.log

# Check system logs for recovery activity
log show --predicate 'process == "lilithos"' --last 1h

# Monitor recovery partition status
sudo ./scripts/recovery-boot.sh --status
```

## 🚀 Advanced Usage

### Custom Recovery Scripts
```bash
# Create custom recovery script
cat > /usr/local/bin/custom-recovery << 'EOF'
#!/bin/bash
echo "Custom recovery script"
# Add custom recovery logic here
EOF

chmod +x /usr/local/bin/custom-recovery
```

### Automated Recovery
```bash
# Create automated recovery script
cat > /usr/local/bin/auto-recovery << 'EOF'
#!/bin/bash
# Automated recovery script
sudo ./scripts/recovery-boot.sh --repair
EOF

chmod +x /usr/local/bin/auto-recovery
```

### Recovery Scheduling
```bash
# Schedule regular recovery checks
crontab -e

# Add entry for weekly recovery check
0 2 * * 0 /usr/local/bin/lilithos-boot-manager
```

## 🔮 Future Enhancements

### Planned Features
- **Network Recovery**: Remote recovery capabilities
- **Cloud Integration**: Cloud-based recovery tools
- **Advanced Diagnostics**: Enhanced diagnostic capabilities
- **Automated Repair**: Intelligent automated repair system
- **Recovery Snapshots**: System state snapshots for recovery

### Development Roadmap
1. **Phase 1**: Basic recovery boot functionality ✅
2. **Phase 2**: Advanced recovery tools
3. **Phase 3**: Network and cloud integration
4. **Phase 4**: AI-powered recovery assistance

## 📞 Support

### Getting Help
- **Documentation**: Check this guide for common issues
- **Logs**: Review log files for error information
- **Community**: Join LilithOS community for support
- **Issues**: Report issues through the project repository

### Emergency Contacts
- **Critical Issues**: Use emergency recovery boot immediately
- **Data Recovery**: Contact data recovery specialists if needed
- **Hardware Issues**: Contact Apple Support for hardware problems

---

## 📜 Changelog

### Version 2.0.0 (Current)
- ✅ Enhanced installer with recovery boot support
- ✅ Recovery partition creation and management
- ✅ Boot manager integration
- ✅ Multiple recovery modes (Emergency, Repair, Diagnostic, Safe)
- ✅ M3 optimization for recovery boot
- ✅ Comprehensive documentation and guides

### Version 1.0.0 (Previous)
- ✅ Basic dual-boot functionality
- ✅ M3 optimization
- ✅ System integration

---

**Note**: This recovery boot system is specifically designed for LilithOS and Apple Silicon Macs. Always backup your data before using recovery tools, and ensure you understand the implications of recovery operations. 