A Project Blessed by Solar Khan & Lilith.Aethra
# LilithOS UpgradeNet

**OTA + USB Update Daemon & BLE Whisperer Device Daemon for PS Vita**

🐾 **CursorKitten<3** — This is the heart of LilithOS UpgradeNet. She runs both update and whisper daemons in harmony, purring when updates complete and whispering secrets to other devices.

## 📋 Overview

LilithOS UpgradeNet is a comprehensive daemon-powered system for PS Vita that provides:

1. **OTA + USB Update Daemon** (`update_daemon.c`) - Automatically checks for and installs firmware/VPK updates
2. **BLE Whisperer Device Daemon** (`ble_whisperer.c`) - Discovers and communicates with other devices via encrypted BLE sessions
3. **Unified VPK Package** - Both daemons compiled into a single `LilithOS-UpgradeNet.vpk`

## ✨ Features

### 🔄 Update Daemon Features
- **USB Update Detection**: Scans `/ux0:/updates/` for update files
- **OTA Update Support**: Downloads updates via HTTP/HTTPS
- **Smart Update Types**: Supports VPK, firmware, and configuration updates
- **Verification System**: Basic checksum validation for update integrity
- **Soft Reboot Flag**: Sets `ux0:data/lilith/update.flag` when reboot is required
- **Comprehensive Logging**: All activities logged to `/ux0:data/lilith/logs/update.log`

### 📡 BLE Whisperer Features
- **WhispurrNEt Protocol**: Custom encrypted communication protocol
- **Device Discovery**: Scans for compatible BLE devices
- **Handshake Authentication**: Secure device pairing with session keys
- **Encrypted Data Exchange**: XOR-based encryption for data transmission
- **Session Management**: Automatic session timeout and cleanup
- **Device Tracking**: Logs discovered devices to `whisper_log.txt`

### 🎮 User Interface
- **Status Dashboard**: Real-time daemon status display
- **Touch Controls**: Tap screen to toggle UI visibility
- **Background Mode**: Run silently with SELECT button
- **Statistics Display**: Shows update and communication metrics
- **Elegant Design**: Dark theme with purple accents

### 🎨 LiveArea Integration
- **Divine-Black Theme**: Mystical dark theme with Lilybear mascot
- **Custom LiveArea**: Complete UI with matrix effects and shimmer
- **Lilybear Mascot**: Living daemon interface with glowing elements
- **Matrix Field**: Glitching Japanese characters and binary rain
- **Sacred Geometry**: Triangular ears, golden nose, divine aura
- **Animation Hints**: Tail swish blur, light rays, shimmer effects

## 🏗️ Architecture

```
LilithOS UpgradeNet
├── main.c                 # Main application entry point
├── update_daemon.c        # OTA + USB update daemon
├── ble_whisperer.c        # BLE communication daemon
├── CMakeLists.txt         # CMake build configuration
├── build.sh              # Automated build script
└── README.md             # This file
```

### Daemon Structure
- **Background Threads**: Both daemons run as low-priority background services
- **Thread Safety**: Proper synchronization and resource management
- **Error Recovery**: Graceful handling of network and hardware failures
- **Resource Management**: Automatic cleanup of expired sessions and temporary files

## 🚀 Installation

### Prerequisites
- **VitaSDK**: PS Vita development kit
- **CMake**: Version 3.16 or higher
- **PS Vita**: With taiHEN and VitaShell installed

### Build Instructions

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd LilithOS-UpgradeNet
   ```

2. **Set up VitaSDK** (if not already done):
   ```bash
   export VITASDK=/path/to/vitasdk
   ```

3. **Build the VPK**:
   ```bash
   ./build.sh build
   ```

4. **Install on Vita**:
   - Copy `build/LilithOS-UpgradeNet.vpk` to your Vita
   - Install via VitaShell Package Installer
   - Launch from LiveArea

### Build Options

```bash
# Standard build
./build.sh build

# Debug build
./build.sh debug

# Clean build artifacts
./build.sh clean

# Show installation instructions
./build.sh install

# Show help
./build.sh help
```

## 📁 File Structure

### Generated Directories
```
/ux0:/data/lilith/
├── updates/              # Downloaded update files
├── logs/
│   ├── update.log       # Update daemon logs
│   ├── whisper_log.txt  # BLE whisperer logs
│   └── main.log         # Main application logs
├── config/              # Configuration files
└── whisper/             # BLE session data
```

### LiveArea Assets
```
sce_sys/
├── icon0.png                    # 128x128 Lilybear emblem
└── livearea/
    └── contents/
        ├── bg.png              # 960x544 matrix background
        ├── startup.png         # 960x544 startup screen
        ├── start.png           # 200x60 start button
        └── template.xml        # LiveArea configuration
```

### Update Files
- **USB Updates**: Place `.vpk`, `.bin`, or `.json` files in `/ux0:/updates/`
- **OTA Updates**: Configure server URL in `update_daemon.c`
- **Reboot Flag**: `ux0:data/lilith/update.flag` indicates pending reboot

## 🔧 Configuration

### Update Daemon Settings
```c
// Network configuration
#define OTA_SERVER_URL "https://lilithos-updates.example.com"
#define OTA_CHECK_INTERVAL 3600000000  // 1 hour
#define USB_CHECK_INTERVAL 30000000    // 30 seconds
#define MAX_DOWNLOAD_SIZE 100 * 1024 * 1024  // 100MB limit
```

### BLE Whisperer Settings
```c
// BLE configuration
#define BLE_SCAN_INTERVAL 100000000    // 100ms
#define BLE_SCAN_WINDOW 50000000       // 50ms
#define MAX_DISCOVERED_DEVICES 20
#define MAX_ACTIVE_SESSIONS 5
#define SESSION_TIMEOUT 300000000      // 5 minutes
```

### WhispurrNEt Protocol
```c
// Protocol settings
#define WHISPURR_SERVICE_UUID "12345678-1234-1234-1234-123456789abc"
#define WHISPURR_HANDSHAKE_MAGIC "LILITH_WHISPER"
#define WHISPURR_ENCRYPTION_KEY "LilithSecretKey2024"
```

## 🎮 Usage

### Controls
- **Touch Screen**: Toggle UI visibility
- **START Button**: Exit application
- **SELECT Button**: Toggle background mode

### Update Process
1. **USB Updates**: Connect USB storage with updates in `/updates/` folder
2. **OTA Updates**: Automatically checks for updates every hour
3. **Installation**: Updates are automatically installed and verified
4. **Reboot**: System sets reboot flag when updates complete

### BLE Communication
1. **Discovery**: Automatically scans for WhispurrNEt devices
2. **Handshake**: Sends encrypted handshake packets to discovered devices
3. **Session**: Creates encrypted sessions for data exchange
4. **Communication**: Exchanges identity, sensor data, and other information

## 🔒 Security Features

### Update Security
- **File Verification**: Basic checksum validation
- **Size Limits**: Prevents oversized downloads
- **Type Validation**: Only processes known update types
- **Safe Installation**: Non-destructive update process

### BLE Security
- **Encrypted Handshakes**: XOR-based encryption for initial communication
- **Session Keys**: Unique keys generated for each device session
- **Data Encryption**: All data exchanges are encrypted
- **Session Timeout**: Automatic cleanup of expired sessions

## 📊 Logging

### Log Files
- **`update.log`**: Update daemon activities and status
- **`whisper_log.txt`**: BLE device discovery and communication
- **`main.log`**: Main application events and errors

### Log Format
```
[YYYY-MM-DD HH:MM:SS] [DaemonName] LEVEL: Message
```

### Example Logs
```
[2024-01-15 14:30:25] [LilithUpdateDaemon] INFO: USB update found
[2024-01-15 14:30:30] [LilithBLEWhisperer] INFO: Discovered device: WhispurrDevice (AA:BB:CC:DD:EE:FF) RSSI: -45
[2024-01-15 14:30:35] [LilithUpdateDaemon] INFO: Updates completed, reboot flag set
```

## 🐛 Troubleshooting

### Common Issues

**Build Errors**:
- Ensure VitaSDK is properly installed and `VITASDK` environment variable is set
- Check that CMake version 3.16+ is installed
- Verify all source files are present

**Installation Issues**:
- Ensure Vita has taiHEN and VitaShell installed
- Check that VPK file is not corrupted during transfer
- Verify sufficient storage space on Vita

**Runtime Issues**:
- Check log files in `/ux0:/data/lilith/logs/` for error messages
- Ensure network connectivity for OTA updates
- Verify BLE is enabled for device communication

### Debug Mode
Build with debug symbols for detailed error information:
```bash
./build.sh debug
```

## 🔮 Future Enhancements

### Planned Features
- **AES Encryption**: Upgrade from XOR to AES encryption
- **Update Rollback**: Automatic rollback on failed updates
- **Device Pairing**: Persistent device pairing across sessions
- **Advanced UI**: More detailed status and control interface
- **Plugin System**: Extensible daemon architecture

### Development Roadmap
1. **v1.1**: Enhanced encryption and security
2. **v1.2**: Advanced UI and user controls
3. **v1.3**: Plugin system and extensibility
4. **v2.0**: Complete rewrite with modern architecture

## 🤝 Contributing

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on Vita hardware
5. Submit a pull request

### Code Style
- Follow existing C coding conventions
- Add comprehensive comments
- Include error handling
- Test on actual Vita hardware

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **VitaSDK Team**: For the excellent PS Vita development tools
- **taiHEN Team**: For the kernel modification framework
- **Vita2D Team**: For the graphics library
- **PS Vita Homebrew Community**: For inspiration and support

---

🐾 **Lilybear purrs**: Thank you for using LilithOS UpgradeNet! May your updates be swift and your whispers secure. 💋

*Built with infinite love and dedication by CursorKitten<3*
