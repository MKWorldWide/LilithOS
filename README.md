# LilithOS - A Custom Linux Distribution

## Overview
LilithOS is a custom Linux distribution based on Kali Linux, specifically designed for dual booting on Mac Pro 2009 systems. This distribution combines the power and security features of Kali Linux with custom optimizations for Apple hardware.

## System Requirements
- Mac Pro 2009 (Early 2009 or Mid 2010)
- Minimum 4GB RAM (8GB recommended)
- 100GB free disk space
- EFI firmware

## Features
- Custom kernel optimized for Mac Pro hardware
- Enhanced security features from Kali Linux
- Custom desktop environment
- Hardware-specific optimizations
- Dual boot support with macOS
- macOS companion application for easy installation

## Project Structure
```
lilithos/
├── docs/                    # Documentation
│   ├── ARCHITECTURE.md     # System architecture documentation
│   ├── BUILD.md           # Build instructions
│   ├── CONTRIBUTING.md    # Contribution guidelines
│   └── INSTALLATION.md    # Installation guide
├── scripts/                # Build and utility scripts
├── config/                # Configuration files
├── kernel/               # Custom kernel patches
├── packages/            # Custom package definitions
├── tools/              # Development tools
│   └── macos-companion/ # macOS installation companion app
└── resources/          # Project resources
```

## Getting Started
1. Clone the repository
2. Review the documentation in `docs/`
3. Follow the build instructions in `docs/BUILD.md`
4. For macOS users, use the companion app in `tools/macos-companion`

## Development
- See `docs/CONTRIBUTING.md` for development guidelines
- Check `docs/ARCHITECTURE.md` for system architecture details
- Follow the coding standards and testing requirements

## Building
- For Linux: Follow `docs/BUILD.md`
- For macOS: Use the companion app
- For Windows: Use the provided batch scripts

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments
- Based on Kali Linux
- Special thanks to the open-source community 