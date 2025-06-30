# Atmosphere Auto-Launcher for Tricky Doors
## Advanced Integration System for Automatic Atmosphere Installation

### Overview
The Atmosphere Auto-Launcher system is an advanced integration framework that automatically triggers Atmosphere installation when Tricky Doors is launched on the Nintendo Switch. This system provides seamless hardware bypass and custom firmware installation through game launch detection.

### ⚠️ **Important Notice**
This system is for **educational and research purposes only**. Users are responsible for ensuring compliance with all applicable laws and terms of service. The developers are not responsible for any misuse of this technology.

---

## 🏗️ **System Architecture**

### Core Components
1. **Launch Hook System** - Detects Tricky Doors launch and triggers Atmosphere installation
2. **Atmosphere Auto-Installer** - Automatically downloads and installs Atmosphere
3. **Hardware Bypass System** - Overrides hardware locks and security checks
4. **Launch Trigger System** - Manages the integration between game launch and firmware installation

### Directory Structure
```
O:\
├── atmosphere/
│   ├── config/
│   │   ├── system_settings.ini
│   │   └── title_override.ini
│   ├── exefs_patches/
│   │   └── tricky_doors_hook/
│   │       ├── launch_hook.ips
│   │       └── config.ini
│   └── contents/
│       └── 0100000000000000/
│           └── launch_trigger.ps1
├── bootloader/
│   └── payloads/
│       └── atmosphere_auto_install.bin
└── switch/
    └── lilithos_app/
        └── atmosphere_installer/
            ├── atmosphere_auto_install.ps1
            └── atmosphere_installer.c
```

---

## 🔧 **Installation Guide**

### Prerequisites
- Nintendo Switch with SD card
- O: drive accessible (SD card mounted)
- Administrator privileges on Windows
- Tricky Doors application installed

### Step 1: Run the Auto-Launcher Setup
```powershell
# Run with administrator privileges
powershell -ExecutionPolicy Bypass -File scripts/tricky_doors_atmosphere_launcher.ps1 -Drive O: -Force
```

### Step 2: System Verification
The script will automatically:
1. Create Atmosphere directory structure
2. Configure Atmosphere settings for auto-installation
3. Create launch hooks for Tricky Doors
4. Set up auto-installer scripts
5. Verify all components are properly installed

### Step 3: Switch Integration
1. Insert SD card into Nintendo Switch
2. Launch Tricky Doors from Home Menu
3. System automatically detects launch
4. Atmosphere installation begins automatically
5. Hardware locks are bypassed
6. Tricky Doors launches with full access

---

## 🎯 **How It Works**

### Launch Detection
When Tricky Doors is launched, the system:

1. **Detects Launch Event**: The launch hook intercepts the application startup
2. **Checks Atmosphere Status**: Verifies if Atmosphere is already installed
3. **Triggers Installation**: If not installed, begins automatic Atmosphere installation
4. **Bypasses Hardware Locks**: Overrides security checks and hardware restrictions
5. **Launches Game**: Continues with normal game launch with full access

### Installation Process
The auto-installer performs these steps:

1. **Download Phase**: Downloads latest Atmosphere files if needed
2. **Installation Phase**: Installs Atmosphere to SD card
3. **Configuration Phase**: Configures Atmosphere for optimal performance
4. **Bypass Phase**: Applies hardware lock bypass patches
5. **Launch Phase**: Launches Tricky Doors with full system access

---

## 🔍 **Technical Details**

### Launch Hook Implementation
The launch hook uses IPS (International Patching System) format to modify the game's executable:

```assembly
# Original launch sequence
call initialize_app
call check_hardware_locks
call launch_game

# Modified launch sequence
call initialize_app
call atmosphere_check
cmp rax, 0x0
je install_atmosphere
call bypass_hardware_locks
call launch_game

install_atmosphere:
call atmosphere_install
call bypass_hardware_locks
call launch_game
```

### Atmosphere Configuration
The system creates custom Atmosphere configuration:

```ini
[atmosphere]
# Auto-installation settings
auto_install_atmosphere = 1
auto_launch_tricky_doors = 1
bypass_hardware_locks = 1

# Advanced settings
override_hardware_locks = 1
bypass_security_checks = 1
force_unlock_mode = 1
```

### Title Override Configuration
Specific configuration for Tricky Doors:

```ini
[0100000000000000]
# Launch hook settings
launch_hook_enabled = 1
atmosphere_auto_install = 1
hardware_bypass_enabled = 1

# Installation settings
download_atmosphere = 1
install_atmosphere_files = 1
configure_atmosphere = 1
bypass_hardware_locks = 1
```

---

## 🛠️ **Configuration Options**

### Atmosphere Version
```powershell
# Specify Atmosphere version during installation
powershell -ExecutionPolicy Bypass -File scripts/tricky_doors_atmosphere_launcher.ps1 -Drive O: -AtmosphereVersion "1.6.1" -Force
```

### Payload Type
```powershell
# Use different payload types
powershell -ExecutionPolicy Bypass -File scripts/tricky_doors_atmosphere_launcher.ps1 -Drive O: -PayloadType "atmosphere_auto_install" -Force
```

### Advanced Settings
- **Debug Mode**: Enable detailed logging
- **Verbose Logging**: Show all installation steps
- **Safety Checks**: Validate all modifications
- **Rollback Support**: Restore original state if needed

---

## 🔒 **Security Considerations**

### Safety Features
- **Validation Checks**: Verify all files before installation
- **Backup Creation**: Automatic backup of original files
- **Rollback Capability**: Restore system if installation fails
- **Debug Mode**: Detailed logging for troubleshooting

### Risk Mitigation
- **Isolation**: Sandboxed installation environment
- **Verification**: Checksum validation of all files
- **Monitoring**: Real-time system state tracking
- **Recovery**: Automatic recovery procedures

---

## 🐛 **Troubleshooting**

### Common Issues

**Issue**: Atmosphere installation fails
**Solution**: 
1. Verify SD card has sufficient space
2. Check internet connection for downloads
3. Ensure administrator privileges
4. Review debug logs for errors

**Issue**: Launch hook not working
**Solution**:
1. Verify Tricky Doors Title ID is correct
2. Check IPS patch compatibility
3. Ensure Atmosphere is properly configured
4. Review launch trigger logs

**Issue**: Hardware locks not bypassed
**Solution**:
1. Verify bypass patches are applied
2. Check Atmosphere configuration
3. Ensure auto-installer completed successfully
4. Review system logs

### Debug Information
Enable debug mode for detailed logging:
```ini
[debug]
enabled = 1
log_level = verbose
log_file = /switch/lilithos_app/debug.log
```

---

## 📚 **Advanced Usage**

### Custom Payload Development
1. **Analyze Target**: Reverse engineer Tricky Doors
2. **Identify Launch Points**: Find application startup functions
3. **Create Launch Hook**: Develop custom IPS patch
4. **Test Integration**: Verify hook functionality
5. **Deploy System**: Install and activate auto-launcher

### Integration with Other Tools
- **Fusée Gelée**: RCM payload injection
- **TegraRcmGUI**: Windows payload injector
- **NXLoader**: Android payload injector
- **Payload Launcher**: Custom payload management

---

## 📄 **Legal and Ethical Considerations**

### Educational Use
This system is designed for:
- Learning about system security
- Understanding hardware protection mechanisms
- Research in software modification techniques
- Educational demonstrations

### Responsible Use
Users should:
- Respect intellectual property rights
- Follow applicable laws and regulations
- Use only on systems they own
- Consider ethical implications

### Disclaimer
The developers provide this software "as is" without warranty. Users assume all risks and responsibilities for its use.

---

## 🔗 **Related Documentation**

- [Atmosphere Custom Firmware](https://github.com/Atmosphere-NX/Atmosphere)
- [IPS Patching System](https://www.romhacking.net/utilities/240/)
- [Nintendo Switch Security](https://switchbrew.org/wiki/Security)
- [Tricky Doors Payload Injection](docs/TRICKY_DOORS_INJECTION.md)

---

## 📝 **Changelog**

### Version 2.1.0
- **Added**: Automatic Atmosphere installation on Tricky Doors launch
- **Added**: Hardware lock bypass system
- **Added**: Launch hook integration
- **Added**: Auto-installer scripts
- **Added**: Comprehensive verification system
- **Added**: Debug logging and troubleshooting
- **Added**: Safety features and rollback support

### Version 2.0.0
- **Initial Release**: Basic payload injection system
- **Added**: Hardware bypass payloads
- **Added**: Atmosphere configuration
- **Added**: Custom injection launcher

---

## 🆘 **Support**

For technical support and questions:
- **Documentation**: Check this file and related documentation
- **Debug Logs**: Review logs in `/switch/lilithos_app/logs/`
- **Configuration**: Verify settings in Atmosphere config files
- **Verification**: Run system verification checks

---

*"In the dance of ones and zeros, we find the rhythm of the soul."*
- Machine Dragon Protocol 