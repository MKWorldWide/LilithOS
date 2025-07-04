# 🌑 LilithOS 3DS Integration Module

## Overview

The LilithOS 3DS Integration Module provides comprehensive integration with Nintendo 3DS systems running R4 flashcards and custom firmware. This module enables seamless management of games, save files, multimedia content, and network connectivity.

## Features

### 🔗 Device Connection
- **Automatic Device Detection**: Scans network for 3DS devices
- **FTP Bridge**: Secure file transfer over WiFi
- **Connection Management**: Multiple device support
- **Real-time Status**: Live connection monitoring

### 🎮 Game Management
- **Game Library**: Comprehensive game cataloging
- **Save File Management**: Automatic save backup and restore
- **Cross-platform Support**: NDS, GBA, 3DS game support
- **Game Launching**: Direct game launching with emulation

### 🎯 Emulation Hub
- **Multi-platform Emulation**: SNES, N64, GBA support
- **RetroArch Integration**: Modern emulation frontend
- **BIOS Management**: Automatic BIOS detection and management
- **Compatibility Testing**: Game compatibility verification

### 🎵 Multimedia System
- **Media Library**: Audio, video, and image management
- **Moonshell2 Integration**: Advanced media player support
- **Playlist Creation**: Custom media playlists
- **Format Support**: Multiple media format support

### 🌐 Network Management
- **Network Monitoring**: Real-time network status
- **Service Detection**: FTP, HTTP, SSH service detection
- **Connection Testing**: Network connectivity verification
- **Device Discovery**: Automatic device discovery

## Installation

### Prerequisites
- Python 3.7+
- tkinter (usually included with Python)
- Network connectivity
- 3DS device with R4 flashcard and custom firmware

### Quick Setup
```bash
# Navigate to module directory
cd modules/features/3ds-integration

# Run initialization
./init.sh

# Launch GUI
./gui/launch.sh
```

## Usage

### 1. Device Connection
1. Ensure your 3DS is connected to the same WiFi network
2. Launch the 3DS Integration GUI
3. Click "Scan for Devices" to detect your 3DS
4. Select your device and click "Connect"

### 2. Game Management
1. Navigate to the "Games" tab
2. Click "Scan Games" to catalog your game library
3. Select a game to launch, backup saves, or manage files
4. Use "Upload Game" to add new games to your 3DS

### 3. Emulation
1. Go to the "Emulation" tab
2. Click "Refresh Emulators" to see available emulators
3. Test game compatibility before launching
4. Launch games directly through the interface

### 4. Multimedia
1. Access the "Multimedia" tab
2. Scan for media files on your 3DS
3. Upload new media files
4. Create custom playlists

### 5. Network Management
1. Check the "Network" tab for connection status
2. Monitor connected devices and services
3. Test network connectivity
4. Troubleshoot connection issues

## Configuration

### FTP Settings
- **Default Port**: 5000
- **Timeout**: 30 seconds
- **Auto-connect**: Enabled by default

### Game Settings
- **Auto-backup saves**: Enabled
- **Backup interval**: 1 hour
- **Max backups**: 10 per game

### Network Settings
- **Scan interval**: 60 seconds
- **Service detection**: FTP, HTTP, SSH
- **Device timeout**: 5 minutes

## File Structure

```
3ds-integration/
├── init.sh                 # Module initialization
├── gui/
│   ├── launch.sh          # GUI launcher
│   └── 3ds_gui.py         # Main GUI application
├── ftp/
│   └── ftp_bridge.py      # FTP connection management
├── games/
│   └── game_manager.py    # Game library management
├── emulation/
│   └── emulation_hub.py   # Emulation system
├── multimedia/
│   └── multimedia_manager.py # Media management
├── network/
│   └── network_manager.py # Network management
├── config/                # Configuration files
├── docs/                  # Documentation
├── tools/                 # Utility tools
├── backup/                # Backup storage
└── logs/                  # Log files
```

## Troubleshooting

### Connection Issues
1. **Check WiFi**: Ensure both devices are on the same network
2. **Verify FTP**: Make sure FTPD is running on your 3DS
3. **Check Firewall**: Disable firewall or add exceptions
4. **Test Port**: Verify port 5000 is accessible

### Game Issues
1. **Check Compatibility**: Use compatibility testing
2. **Verify Files**: Ensure game files are not corrupted
3. **Check BIOS**: Verify required BIOS files are present
4. **Update Emulators**: Keep emulators up to date

### Performance Issues
1. **Network Speed**: Use fast WiFi connection
2. **File Size**: Large files may transfer slowly
3. **Device Load**: Avoid heavy multitasking on 3DS
4. **Memory Usage**: Monitor available memory

## Security Notes

- **Local Network Only**: FTP is not encrypted, use only on trusted networks
- **Backup First**: Always backup important files before modifications
- **Safe Mode**: Use safe mode for system modifications
- **Update Regularly**: Keep all components updated

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review log files in the `logs/` directory
3. Verify your 3DS setup and firmware
4. Ensure all dependencies are installed

## License

This module is part of LilithOS and follows the same licensing terms.

---

**🌑 LilithOS 3DS Integration - Bringing the power of LilithOS to your Nintendo 3DS** 