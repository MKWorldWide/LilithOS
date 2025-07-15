# LilithOS PSP Daemons

**Modular PSP EBOOT, PRX Daemons, and Vita Bridge for LilithOS**

A comprehensive PSP-mode daemon system that provides modular signal scanning, Bluetooth communication, sensor echo processing, and seamless Vita↔PSP bridge functionality for the LilithOS ecosystem.

## 🐾 Overview

The LilithOS PSP Daemons provide a complete modular architecture for running daemon services within PSP mode on PS Vita, with seamless integration to Vita mode through dual-mode transfer capabilities.

### Key Features

- **Modular PSP EBOOT**: Main executable that loads and manages PRX modules
- **SignalScanner PRX**: Real-time signal scanning (BLE, Wi-Fi, NFC)
- **Bluetooth Communication PRX**: BLE device communication (stub)
- **Sensor Echo PRX**: Sensor data collection and processing (stub)
- **Vita↔PSP Bridge**: Dual-mode transfer with OTA and USB fallback
- **Comprehensive Logging**: Detailed logging and status tracking
- **Build System**: Complete PSPDEV and VitaSDK build integration

## 🏗️ Architecture

```
psp_daemons/
├── src/
│   ├── psp_eboot.c          # Main PSP EBOOT executable
│   └── vita_psp_bridge.c    # Vita-side bridge binary
├── modules/
│   ├── signal_scan.prx.c    # Signal scanning PRX
│   ├── bt_comm.prx.c        # Bluetooth communication PRX
│   └── sensor_echo.prx.c    # Sensor echo PRX
├── build/
│   ├── Makefile.psp         # PSP build system
│   ├── Makefile.vita        # Vita build system
│   └── scripts/
│       ├── ota_sync.sh      # OTA synchronization script
│       └── usb_sync.sh      # USB synchronization script
├── include/                 # Header files
└── config/                  # Configuration files
```

## 📋 Requirements

### PSP Development
- **PSPDEV Toolchain**: PSP development environment
- **PSP SDK**: PSP software development kit
- **PRX Development Tools**: PRX module development utilities

### Vita Development
- **VitaSDK**: Vita software development kit
- **Vita Toolchain**: Vita development environment

### System Requirements
- **macOS/Linux**: Development environment
- **USB Access**: For PSPEMU mounting and file transfer
- **Network Access**: For OTA transfer capabilities

## 🚀 Installation

### 1. Clone the Repository
```bash
git clone <repository-url>
cd LilithOS/psp_daemons
```

### 2. Install Dependencies

#### PSPDEV Installation
```bash
# macOS (using Homebrew)
brew install pspdev

# Linux
sudo apt-get install pspdev

# Manual installation
git clone https://github.com/pspdev/pspdev.git
cd pspdev
./bootstrap
./configure --prefix=/usr/local/pspdev
make
sudo make install
```

#### VitaSDK Installation
```bash
# macOS (using Homebrew)
brew install vitasdk

# Linux
git clone https://github.com/vitasdk/vitasdk.git
cd vitasdk
./bootstrap
./configure --prefix=/usr/local/vitasdk
make
sudo make install
```

### 3. Build the Project

#### Build PSP Components
```bash
cd build
make -f Makefile.psp all
```

#### Build Vita Components
```bash
cd build
make -f Makefile.vita all
```

#### Build Everything
```bash
cd build
make -f Makefile.psp all
make -f Makefile.vita all
```

## 🔧 Configuration

### PSP Configuration

The PSP daemons use the following directory structure:

```
ms0:/LILIDAEMON/
├── EBOOT.PBP              # Main PSP executable
├── modules/
│   ├── signal_scan.prx    # Signal scanning module
│   ├── bt_comm.prx        # Bluetooth module
│   └── sensor_echo.prx    # Sensor module
├── OUT/                   # Output directory
│   ├── signal_dump.txt    # Signal scan output
│   ├── scanner_log.txt    # Scanner logs
│   ├── bt_comm_log.txt    # Bluetooth logs
│   ├── sensor_data.txt    # Sensor data
│   └── daemon_log.txt     # Main daemon logs
├── status.txt             # Current status
└── RELAY_READY            # Vita relay signal
```

### Vita Configuration

The Vita bridge uses the following directory structure:

```
ux0:/data/lilith/
├── relay/                 # Relay directory
│   ├── signal_dump.txt    # Received signal data
│   ├── bridge_status.txt  # Bridge status
│   └── sync_status.txt    # Sync status
├── net/                   # OTA network directory
├── relay_status.log       # Bridge logs
└── vita_psp_bridge        # Bridge binary
```

## 🎮 Usage

### Running PSP Daemons

1. **Install to PSPEMU**:
   ```bash
   cd build
   make -f Makefile.psp install
   ```

2. **Launch in Adrenaline**:
   - Open Adrenaline on PS Vita
   - Navigate to PSP/GAME/LILIDAEMON
   - Launch the EBOOT.PBP

3. **Monitor Output**:
   - Check `ms0:/LILIDAEMON/OUT/` for logs and data
   - Monitor `ms0:/LILIDAEMON/status.txt` for current status

### Running Vita Bridge

1. **Install Bridge Binary**:
   ```bash
   cd build
   make -f Makefile.vita install
   ```

2. **Start Bridge Service**:
   ```bash
   # On Vita or via USB mount
   cd /Volumes/Untitled/ux0/data/lilith
   ./vita_psp_bridge
   ```

### Using Sync Scripts

#### OTA Sync
```bash
cd build/scripts
./ota_sync.sh -i 10  # Sync every 10 seconds
```

#### USB Sync
```bash
cd build/scripts
./usb_sync.sh -i 5   # Sync every 5 seconds
```

## 📊 Monitoring and Logging

### PSP Logs
- **Main Daemon**: `ms0:/LILIDAEMON/daemon_log.txt`
- **Signal Scanner**: `ms0:/LILIDAEMON/OUT/scanner_log.txt`
- **Bluetooth**: `ms0:/LILIDAEMON/OUT/bt_comm_log.txt`
- **Sensors**: `ms0:/LILIDAEMON/OUT/sensor_echo_log.txt`

### Vita Logs
- **Bridge Status**: `ux0:/data/lilith/bridge_status.txt`
- **Relay Logs**: `ux0:/data/lilith/relay_status.log`
- **Sync Status**: `ux0:/data/lilith/relay/sync_status.txt`

### Status Files
- **PSP Status**: `ms0:/LILIDAEMON/status.txt`
- **Bridge Status**: `ux0:/data/lilith/bridge_status.txt`
- **Relay Ready**: `ms0:/LILIDAEMON/RELAY_READY`

## 🔍 Troubleshooting

### Common Issues

#### PSPDEV Not Found
```bash
# Set PSPDEV path
export PSPDEV=/path/to/pspdev
make -f Makefile.psp all
```

#### VitaSDK Not Found
```bash
# Set VitaSDK path
export VITASDK=/path/to/vitasdk
make -f Makefile.vita all
```

#### USB Mount Issues
```bash
# Check mount points
ls -la /Volumes/Untitled/pspemu/LILIDAEMON/
ls -la /Volumes/Untitled/ux0/data/lilith/
```

#### PRX Loading Errors
- Check PRX file permissions
- Verify PSPDEV installation
- Review daemon logs for specific errors

### Debug Mode

#### PSP Debug Build
```bash
cd build
make -f Makefile.psp debug
```

#### Vita Debug Build
```bash
cd build
make -f Makefile.vita debug
```

## 🛠️ Development

### Adding New PRX Modules

1. **Create Module Source**:
   ```c
   // modules/new_module.prx.c
   #include <pspkernel.h>
   
   PSP_MODULE_INFO("NewModule", 0x1000, 1, 0);
   
   int module_start(SceSize args, void *argp) {
       // Module initialization
       return 0;
   }
   
   int module_stop(SceSize args, void *argp) {
       // Module cleanup
       return 0;
   }
   ```

2. **Update PSP Makefile**:
   ```makefile
   # Add to Makefile.psp
   NEW_MODULE_SRC = $(MODULEDIR)/new_module.prx.c
   NEW_MODULE_OBJ = $(BUILDDIR)/new_module.o
   NEW_MODULE_PRX = $(BUILDDIR)/new_module.prx
   
   new_module.prx: $(NEW_MODULE_PRX)
   
   $(NEW_MODULE_PRX): $(NEW_MODULE_OBJ)
       $(PSPPRXGEN) $< $@
   
   $(NEW_MODULE_OBJ): $(NEW_MODULE_SRC)
       $(PSPCC) $(PRXFLAGS) -c $< -o $@
   ```

3. **Register in PSP EBOOT**:
   ```c
   // Add to modules array in psp_eboot.c
   {"new_module", MODULES_PATH "/new_module.prx", -1, 0},
   ```

### Extending Bridge Functionality

1. **Add New Transfer Types**:
   ```c
   // In vita_psp_bridge.c
   int attempt_custom_transfer() {
       // Custom transfer logic
       return 0;
   }
   ```

2. **Update Transfer Strategy**:
   ```c
   void initiate_dual_transfer() {
       // Try OTA transfer first
       if (attempt_ota_transfer() == 0) {
           return;
       }
       
       // Try custom transfer
       if (attempt_custom_transfer() == 0) {
           return;
       }
       
       // Fallback to USB transfer
       attempt_usb_transfer();
   }
   ```

## 🔒 Security Considerations

### File Permissions
- Ensure proper file permissions on sensitive data
- Use secure file transfer protocols
- Implement data validation and sanitization

### Network Security
- Use encrypted communication for OTA transfers
- Implement authentication for network access
- Monitor for unauthorized access attempts

### Data Privacy
- Minimize data collection to necessary information
- Implement data retention policies
- Provide user control over data sharing

## 📈 Performance Optimization

### PSP Optimization
- Use efficient memory management
- Implement proper thread synchronization
- Optimize file I/O operations

### Vita Optimization
- Minimize bridge overhead
- Use efficient transfer protocols
- Implement caching strategies

### Network Optimization
- Use compression for large data transfers
- Implement connection pooling
- Optimize transfer intervals

## 🤝 Contributing

### Development Guidelines
1. Follow existing code style and conventions
2. Add comprehensive documentation
3. Include error handling and logging
4. Test thoroughly before submitting

### Testing
- Test on actual PSP/Vita hardware
- Verify USB mount functionality
- Test network transfer capabilities
- Validate error recovery mechanisms

### Documentation
- Update README for new features
- Document API changes
- Include usage examples
- Maintain troubleshooting guides

## 📄 License

This project is part of the LilithOS ecosystem and follows the same licensing terms.

## 🙏 Acknowledgments

- **PSPDEV Community**: For PSP development tools
- **VitaSDK Team**: For Vita development framework
- **Adrenaline Team**: For PSP emulation on Vita
- **LilithOS Community**: For continuous support and feedback

## 🐾 Lilybear's Notes

*"Purring with delight at the modular architecture! The PSP daemons provide a solid foundation for LilithOS's dual-mode capabilities. The bridge system ensures seamless communication between PSP and Vita modes, while the comprehensive logging helps track system health. The build system makes development a breeze, and the sync scripts provide reliable data transfer. This is exactly what LilithOS needed for robust PSP integration! 💋"*

---

**LilithOS PSP Daemons** - *Modular, Reliable, Powerful* 