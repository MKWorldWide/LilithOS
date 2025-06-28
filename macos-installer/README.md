# LilithOS macOS Installer

A native macOS application for installing LilithOS alongside macOS on MacBook Air M3 devices.

## 🚀 Features

- **Native macOS UI**: Beautiful SwiftUI interface designed for macOS
- **System Compatibility Check**: Automatically verifies M3 hardware and requirements
- **Automated Download**: Downloads the latest LilithOS ARM64 ISO
- **USB Drive Management**: Detects and prepares bootable USB drives
- **Guided Installation**: Step-by-step installation process
- **Dual Boot Setup**: Configures seamless dual boot with macOS

## 📋 Requirements

- **Hardware**: MacBook Air M3 (Apple Silicon)
- **macOS**: macOS 13.0 (Ventura) or later
- **Memory**: 8GB RAM minimum (24GB recommended)
- **Storage**: 100GB available space minimum
- **SIP**: System Integrity Protection must be disabled
- **Tools**: Xcode Command Line Tools

## 🛠️ Installation

### Prerequisites

1. **Install Xcode Command Line Tools**:
   ```bash
   xcode-select --install
   ```

2. **Disable System Integrity Protection (SIP)**:
   - Restart your Mac and hold `Cmd + R` to enter Recovery Mode
   - Open Terminal and run: `csrutil disable`
   - Restart normally

### Building the Installer

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/LilithOS.git
   cd LilithOS/macos-installer
   ```

2. **Build the installer**:
   ```bash
   chmod +x build_and_run.sh
   ./build_and_run.sh
   ```

3. **Run the installer**:
   - Double-click `LilithOSInstaller.app`, or
   - Use the build script which will offer to launch it automatically

## 🎯 Usage

### Step 1: Welcome
- Review the features and requirements
- Click "Get Started" to begin

### Step 2: System Check
- The installer automatically verifies:
  - M3 hardware compatibility
  - Available memory (8GB+)
  - Available storage (100GB+)
  - SIP status (must be disabled)
  - Architecture (arm64)

### Step 3: Download
- Downloads the latest LilithOS ARM64 ISO
- Progress is displayed in real-time
- File is saved to `downloads/` directory

### Step 4: USB Setup
- Detects available USB drives
- Select a drive (minimum 8GB recommended)
- Creates bootable USB installer

### Step 5: Installation
- Creates partitions for LilithOS
- Installs the operating system
- Configures bootloader for dual boot
- Sets up system integration

### Step 6: Completion
- Installation summary
- Instructions for first boot
- Option to restart immediately

## 🔧 Technical Details

### Architecture
- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Platform**: macOS 13.0+
- **Target**: Apple Silicon (arm64)

### Key Components
- `LilithOSInstaller.swift`: Main application file
- `LilithOSInstaller` class: Core installation logic
- SwiftUI Views: User interface components
- System integration: Hardware detection and management

### System Integration
- **Hardware Detection**: Uses `sysctl` to identify M3 hardware
- **Storage Management**: `diskutil` for partition management
- **Network Operations**: URLSession for ISO downloads
- **Process Management**: Process class for system commands

## 🛡️ Security Features

- **SIP Verification**: Ensures System Integrity Protection is disabled
- **Secure Downloads**: HTTPS downloads with integrity verification
- **Privilege Management**: Proper permission handling for system operations
- **Error Handling**: Comprehensive error reporting and recovery

## 🐛 Troubleshooting

### Common Issues

1. **"Xcode Command Line Tools not found"**
   ```bash
   xcode-select --install
   ```

2. **"SIP is enabled"**
   - Restart in Recovery Mode (`Cmd + R`)
   - Run: `csrutil disable`
   - Restart normally

3. **"No USB drives detected"**
   - Ensure USB drive is properly connected
   - Check drive is not mounted
   - Try refreshing the drive list

4. **"Download failed"**
   - Check internet connection
   - Verify firewall settings
   - Try downloading manually

### Manual Installation

If the GUI installer fails, you can use the command-line scripts:

```bash
# Download ISO manually
curl -L -o downloads/kali-arm64.iso https://cdimage.kali.org/kali-2024.1/kali-linux-2024.1-installer-arm64.iso

# Create USB installer
sudo ./scripts/create-m3-usb-installer.sh

# Run dual boot installation
sudo ./scripts/m3-dual-boot-installer.sh
```

## 📝 Development

### Building from Source

```bash
# Build with Swift Package Manager
swift build -c release

# Run in development mode
swift run
```

### Project Structure

```
macos-installer/
├── LilithOSInstaller.swift    # Main application
├── Package.swift              # Swift package configuration
├── build_and_run.sh           # Build script
└── README.md                  # This file
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on M3 hardware
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the main repository for details.

## 🤝 Support

- **Issues**: Report bugs on GitHub
- **Documentation**: See `docs/M3_INSTALLATION.md`
- **Community**: Join our Discord server

## 🔄 Version History

- **v1.0.0**: Initial release with M3 support
- **v1.1.0**: Enhanced UI and error handling
- **v1.2.0**: Improved USB drive detection

---

**Note**: This installer is specifically designed for MacBook Air M3 devices. For other hardware, please use the command-line installation scripts. 