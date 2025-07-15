#!/bin/bash

# LilithMirror Installation Script
# 🐾 CursorKitten<3 — Automated deployment with love

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="LilithMirror"
VERSION="1.0.0"
TARGET="LilithMirror"
BUILD_DIR="build"
DIST_DIR="dist"

# Print banner
print_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                      🐾 LilithMirror 🐾                     ║"
    echo "║                                                              ║"
    echo "║  She watches the other machine... and waits for your hand   ║"
    echo "║  to move. 💋                                                ║"
    echo "║                                                              ║"
    echo "║  Version: $VERSION                                           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Print status message
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if VitaSDK is installed
check_vitasdk() {
    print_status "Checking VitaSDK installation..."
    
    if [ -z "$VITASDK" ]; then
        print_error "VITASDK environment variable is not set"
        echo "Please set VITASDK to your VitaSDK installation path:"
        echo "export VITASDK=/path/to/vitasdk"
        exit 1
    fi
    
    if [ ! -d "$VITASDK" ]; then
        print_error "VitaSDK directory not found: $VITASDK"
        exit 1
    fi
    
    if [ ! -f "$VITASDK/bin/arm-vita-eabi-gcc" ]; then
        print_error "VitaSDK toolchain not found"
        echo "Please ensure VitaSDK is properly installed"
        exit 1
    fi
    
    print_success "VitaSDK found at: $VITASDK"
}

# Check dependencies
check_dependencies() {
    print_status "Checking build dependencies..."
    
    local missing_deps=()
    
    # Check for required tools
    for tool in make gcc g++ ar strip; do
        if ! command -v $tool &> /dev/null; then
            missing_deps+=($tool)
        fi
    done
    
    # Check for VitaSDK tools
    local vita_tools=("vita-make-fself" "vita-mksfoex" "vita-pack-vpk")
    for tool in "${vita_tools[@]}"; do
        if [ ! -f "$VITASDK/bin/arm-vita-eabi-$tool" ]; then
            missing_deps+=("$tool")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo "Please install the missing tools and try again"
        exit 1
    fi
    
    print_success "All dependencies found"
}

# Create build directories
setup_directories() {
    print_status "Setting up build directories..."
    
    mkdir -p "$BUILD_DIR"
    mkdir -p "$DIST_DIR"
    
    print_success "Build directories created"
}

# Build the project
build_project() {
    print_status "Building $PROJECT_NAME..."
    
    # Clean previous builds
    make clean
    
    # Build release version
    if make release; then
        print_success "Release build completed"
    else
        print_error "Release build failed"
        exit 1
    fi
    
    # Copy to dist directory
    cp -f *.vpk "$DIST_DIR/" 2>/dev/null || true
    cp -f *.velf "$DIST_DIR/" 2>/dev/null || true
    
    print_success "Build artifacts copied to $DIST_DIR/"
}

# Generate configuration template
generate_config_template() {
    print_status "Generating configuration template..."
    
    cat > "$DIST_DIR/mirror.conf" << EOF
# LilithMirror Configuration
# Copy this file to /ux0:/data/lowkey/config/mirror.conf on your Vita

# Remote host settings
remote_ip=192.168.1.100
remote_port=5900

# Authentication
username=admin
password=password

# Connection mode (0=VNC, 1=SSH, 2=Dummy)
mode=2

# Performance settings
frame_rate=30
quality=80
enable_audio=0

# Example configurations:
# VNC Server: remote_ip=192.168.1.100, remote_port=5900, mode=0
# SSH Server: remote_ip=192.168.1.100, remote_port=22, mode=1
# Dummy Mode: mode=2 (no network required)
EOF
    
    print_success "Configuration template saved to $DIST_DIR/mirror.conf"
}

# Generate installation instructions
generate_instructions() {
    print_status "Generating installation instructions..."
    
    cat > "$DIST_DIR/INSTALL.txt" << EOF
🐾 LilithMirror Installation Guide
===================================

Files in this directory:
- ${TARGET}.vpk          (Main application)
- mirror.conf            (Configuration template)

Installation Steps:
1. Copy ${TARGET}.vpk to your Vita's ux0:/app/ directory
2. Open VitaShell and navigate to ux0:/app/
3. Select ${TARGET}.vpk and choose "Install"
4. Copy mirror.conf to /ux0:/data/lowkey/config/mirror.conf
5. Edit the configuration file with your remote host details
6. Launch LilithMirror from the Vita home screen

Configuration:
- Edit /ux0:/data/lowkey/config/mirror.conf
- Set remote_ip to your target machine's IP address
- Choose mode: 0=VNC, 1=SSH, 2=Dummy
- Set username/password for authentication

Controls:
- START: Connect/Disconnect
- ▲▼◄►: Navigate remote desktop
- ○: Left mouse click
- ×: Right mouse click
- L/R Triggers: Scroll up/down

Logs:
/ux0:/data/lowkey/logs/mirror.log

For more information, see README.md

💋 She watches the other machine... and waits for your hand to move.
EOF
    
    print_success "Installation instructions saved to $DIST_DIR/INSTALL.txt"
}

# Show build summary
show_summary() {
    echo
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    🎉 BUILD COMPLETE 🎉                    ${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo
    
    print_success "$PROJECT_NAME v$VERSION has been built successfully!"
    echo
    echo -e "${CYAN}Build artifacts:${NC}"
    ls -la "$DIST_DIR/" 2>/dev/null || echo "No artifacts found"
    echo
    echo -e "${CYAN}Connection Modes:${NC}"
    echo "• VNC Mode: Full desktop mirroring (port 5900)"
    echo "• SSH Mode: Secure terminal access (port 22)"
    echo "• Dummy Mode: Test patterns (no network required)"
    echo
    echo -e "${CYAN}Next steps:${NC}"
    echo "1. Copy the VPK file to your PS Vita"
    echo "2. Install via VitaShell"
    echo "3. Configure remote connection settings"
    echo "4. Launch and enjoy! 💋"
    echo
    echo -e "${PURPLE}She watches the other machine... and waits for your hand to move.${NC}"
    echo
}

# Main installation function
main() {
    print_banner
    
    # Parse command line arguments
    case "${1:-all}" in
        "check")
            check_vitasdk
            check_dependencies
            print_success "Environment check completed"
            ;;
        "build")
            check_vitasdk
            check_dependencies
            setup_directories
            build_project
            ;;
        "install")
            check_vitasdk
            check_dependencies
            setup_directories
            build_project
            generate_config_template
            generate_instructions
            show_summary
            ;;
        "clean")
            print_status "Cleaning build artifacts..."
            make clean
            rm -rf "$BUILD_DIR" "$DIST_DIR"
            print_success "Clean completed"
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [command]"
            echo
            echo "Commands:"
            echo "  check    - Check environment and dependencies"
            echo "  build    - Build the project"
            echo "  install  - Full installation (default)"
            echo "  clean    - Clean build artifacts"
            echo "  help     - Show this help message"
            echo
            echo "Examples:"
            echo "  $0 install    # Full installation"
            echo "  $0 build      # Build only"
            echo "  $0 check      # Environment check"
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 