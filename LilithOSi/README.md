# LilithOS - iOS 9.3.6 Custom Firmware for iPhone 4S

## Project Overview
LilithOS is a custom firmware project targeting iOS 9.3.6 for iPhone 4S devices. This project aims to create a signed IPSW that can be directly installed on compatible devices.

## Requirements
- macOS development environment
- Xcode 7.3.1 (compatible with iOS 9.3.6)
- iOS 9.3.6 IPSW for iPhone 4S
- Apple Developer Account for signing
- Required tools:
  - idevicerestore
  - libimobiledevice
  - libplist
  - libusbmuxd

## Project Structure
```
LilithOS/
├── @docs/                    # Documentation
├── @.cursor/                 # Cursor IDE specific files
├── src/                      # Source code
│   ├── kernel/              # Kernel modifications
│   ├── system/              # System modifications
│   └── patches/             # iOS patches
├── tools/                    # Build and signing tools
├── resources/               # Resources and assets
└── scripts/                 # Build and deployment scripts
```

## Building the IPSW
1. Download the base iOS 9.3.6 IPSW for iPhone 4S
2. Extract the IPSW contents
3. Apply LilithOS modifications
4. Repack the IPSW
5. Sign the IPSW with valid certificates

## Installation
1. Put iPhone 4S in DFU mode
2. Use idevicerestore to flash the signed IPSW
3. Follow on-screen instructions

## Development Status
🚧 Project is currently in beta development phase

## Security Notice
This project involves modifying iOS system files. Use at your own risk. Always maintain a backup of your device before attempting installation.

## License
[License information to be added]

## Contributing
[Contribution guidelines to be added] 