#!/bin/bash

# LilithOS Voice Daemon VPK Builder
# ==================================
# Creates Vita VPK package for voice synthesis system

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# VPK configuration
VPK_NAME="LilithVoice"
VPK_VERSION="1.0.0"
VPK_TITLE="LilithOS Voice Daemon"
VPK_TITLE_ID="LILITHVOICE"
VPK_CATEGORY="application"
VPK_ICON="icon.png"
VPK_BG="bg.png"
VPK_LIVEAREA="livearea.xml"

# Build directories
BUILD_DIR="build_vpk"
VPK_DIR="$BUILD_DIR/vpk"
EBIN_DIR="$VPK_DIR/eboot"
LIVEAREA_DIR="$VPK_DIR/livearea"
ASSETS_DIR="$LIVEAREA_DIR/assets"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[VPK]${NC} $1"
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

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Function to create VPK structure
create_vpk_structure() {
    print_status "Creating VPK directory structure..."
    
    # Create main directories
    mkdir -p "$VPK_DIR"
    mkdir -p "$EBIN_DIR"
    mkdir -p "$LIVEAREA_DIR"
    mkdir -p "$ASSETS_DIR"
    
    print_success "VPK structure created"
}

# Function to create LiveArea assets
create_livearea_assets() {
    print_status "Creating LiveArea assets..."
    
    # Create icon (64x64 PNG)
    cat > "$ASSETS_DIR/icon.png" << 'EOF'
# This would be a 64x64 PNG icon
# For now, creating placeholder
EOF
    
    # Create background (960x544 PNG)
    cat > "$ASSETS_DIR/bg.png" << 'EOF'
# This would be a 960x544 PNG background
# For now, creating placeholder
EOF
    
    # Create LiveArea XML
    cat > "$LIVEAREA_DIR/livearea.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<livearea>
    <bg>
        <image>assets/bg.png</image>
    </bg>
    <icon>
        <image>assets/icon.png</image>
    </icon>
    <title>
        <text>LilithOS Voice Daemon</text>
    </title>
    <description>
        <text>Quantum-detailed voice synthesis system for LilithOS</text>
    </description>
    <info>
        <text>Version 1.0.0</text>
    </info>
</livearea>
EOF
    
    print_success "LiveArea assets created"
}

# Function to create Python runtime
create_python_runtime() {
    print_status "Creating Python runtime environment..."
    
    # Create main Python script
    cat > "$EBIN_DIR/main.py" << 'EOF'
#!/usr/bin/env python3
"""
LilithOS Voice Daemon - VPK Entry Point
========================================
Main entry point for Vita VPK package
"""

import sys
import os
import logging

# Add current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Configure logging for Vita
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('lilith_voice.log'),
        logging.StreamHandler()
    ]
)

def main():
    """Main entry point for VPK."""
    try:
        # Import and start voice daemon
        from lilith_voice_daemon import LilithVoiceDaemon
        
        print("🎤 Starting LilithOS Voice Daemon...")
        print("📱 Running on PlayStation Vita")
        print("🔧 Initializing TTS engine...")
        
        # Create and start daemon
        daemon = LilithVoiceDaemon()
        daemon.run_daemon()
        
    except ImportError as e:
        print(f"❌ Import error: {e}")
        print("🔧 Please ensure all dependencies are installed")
        return 1
    except Exception as e:
        print(f"❌ Error starting voice daemon: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
EOF
    
    # Copy voice daemon files
    cp lilith_voice_daemon.py "$EBIN_DIR/"
    cp voice_manager.py "$EBIN_DIR/"
    cp whisperer_integration.py "$EBIN_DIR/"
    cp voice_config.yaml "$EBIN_DIR/"
    cp phrase_scripts.json "$EBIN_DIR/"
    
    print_success "Python runtime created"
}

# Function to create Vita-specific launcher
create_vita_launcher() {
    print_status "Creating Vita launcher..."
    
    # Create shell launcher
    cat > "$EBIN_DIR/launch.sh" << 'EOF'
#!/bin/bash

# LilithOS Voice Daemon Vita Launcher
# ====================================

echo "🎤 LilithOS Voice Daemon"
echo "📱 PlayStation Vita Edition"
echo "================================"

# Set up environment
export PYTHONPATH="$(dirname "$0")"
export LILITHOS_PLATFORM="vita"

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found"
    echo "🔧 Please install Python 3 for Vita"
    exit 1
fi

# Start voice daemon
echo "🚀 Starting voice daemon..."
python3 "$(dirname "$0")/main.py"

# Check exit code
if [ $? -eq 0 ]; then
    echo "✅ Voice daemon completed successfully"
else
    echo "❌ Voice daemon encountered an error"
fi
EOF
    
    chmod +x "$EBIN_DIR/launch.sh"
    
    print_success "Vita launcher created"
}

# Function to create VPK manifest
create_vpk_manifest() {
    print_status "Creating VPK manifest..."
    
    cat > "$VPK_DIR/manifest.txt" << EOF
LilithOS Voice Daemon VPK
=========================

Title: $VPK_TITLE
Title ID: $VPK_TITLE_ID
Version: $VPK_VERSION
Category: $VPK_CATEGORY

Description:
Quantum-detailed voice synthesis system for LilithOS.
Provides TTS, signal-to-speech mapping, and event whisperer integration.

Features:
- Text-to-Speech synthesis with multiple backends
- Signal-to-speech mapping for system events
- Event whisperer integration for real-time feedback
- Audio output management with voice profiles
- Phrase scripting for customizable responses

Requirements:
- Python 3.6+
- Audio output capability
- Network connectivity for whisperer integration

Installation:
1. Copy VPK to ux0:/VPKS/
2. Install via VitaShell
3. Run from LiveArea

Usage:
- Voice daemon starts automatically
- Responds to system events via whisperer
- Customizable via voice_config.yaml
- Phrase scripts in phrase_scripts.json

Author: LilithOS Development Team
License: MIT
EOF
    
    print_success "VPK manifest created"
}

# Function to create VPK package
create_vpk_package() {
    print_status "Creating VPK package..."
    
    # Create VPK archive
    cd "$BUILD_DIR"
    
    # Create VPK structure
    mkdir -p "vpk_package"
    cp -r vpk/* vpk_package/
    
    # Create VPK archive
    tar -czf "${VPK_NAME}_v${VPK_VERSION}.vpk" -C vpk_package .
    
    # Move to parent directory
    mv "${VPK_NAME}_v${VPK_VERSION}.vpk" ../
    
    cd ..
    
    print_success "VPK package created: ${VPK_NAME}_v${VPK_VERSION}.vpk"
}

# Function to create installation script
create_install_script() {
    print_status "Creating installation script..."
    
    cat > "$BUILD_DIR/install_vpk.sh" << 'EOF'
#!/bin/bash

# LilithOS Voice Daemon VPK Installer
# ====================================

set -e

VPK_NAME="LilithVoice_v1.0.0.vpk"
VITA_IP="192.168.1.180"
VITA_PORT="1337"
VITA_PATH="ux0:/VPKS/"

echo "🎤 LilithOS Voice Daemon VPK Installer"
echo "======================================"

# Check if VPK exists
if [ ! -f "$VPK_NAME" ]; then
    echo "❌ VPK file not found: $VPK_NAME"
    echo "🔧 Please run build_vpk.sh first"
    exit 1
fi

echo "📦 VPK found: $VPK_NAME"
echo "📱 Target Vita: $VITA_IP:$VITA_PORT"
echo "📂 Install path: $VITA_PATH"

# Try different transfer methods
echo "🚀 Attempting VPK transfer..."

# Method 1: FTP
echo "📤 Trying FTP transfer..."
if command -v curl &> /dev/null; then
    if curl -T "$VPK_NAME" "ftp://$VITA_IP:$VITA_PORT$VITA_PATH" --user anonymous:anonymous; then
        echo "✅ FTP transfer successful"
        echo "🎉 VPK installed successfully!"
        echo "📱 Install via VitaShell: $VITA_PATH$VPK_NAME"
        exit 0
    fi
fi

# Method 2: SCP
echo "📤 Trying SCP transfer..."
if command -v scp &> /dev/null; then
    if scp "$VPK_NAME" "anonymous@$VITA_IP:$VITA_PATH"; then
        echo "✅ SCP transfer successful"
        echo "🎉 VPK installed successfully!"
        echo "📱 Install via VitaShell: $VITA_PATH$VPK_NAME"
        exit 0
    fi
fi

# Method 3: Netcat
echo "📤 Trying Netcat transfer..."
if command -v nc &> /dev/null; then
    if nc "$VITA_IP" "$VITA_PORT" < "$VPK_NAME"; then
        echo "✅ Netcat transfer successful"
        echo "🎉 VPK installed successfully!"
        echo "📱 Install via VitaShell: $VITA_PATH$VPK_NAME"
        exit 0
    fi
fi

echo "❌ All transfer methods failed"
echo "🔧 Manual installation required:"
echo "   1. Copy $VPK_NAME to Vita"
echo "   2. Place in $VITA_PATH"
echo "   3. Install via VitaShell"

exit 1
EOF
    
    chmod +x "$BUILD_DIR/install_vpk.sh"
    
    print_success "Installation script created"
}

# Function to display build summary
display_summary() {
    print_status "VPK build completed successfully!"
    
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    VPK BUILD SUMMARY                         ║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  VPK Name: ${CYAN}${VPK_NAME}_v${VPK_VERSION}.vpk${NC}${GREEN}                    ║${NC}"
    echo -e "${GREEN}║  Title: ${CYAN}${VPK_TITLE}${NC}${GREEN}                              ║${NC}"
    echo -e "${GREEN}║  Title ID: ${CYAN}${VPK_TITLE_ID}${NC}${GREEN}                                ║${NC}"
    echo -e "${GREEN}║  Category: ${CYAN}${VPK_CATEGORY}${NC}${GREEN}                              ║${NC}"
    echo -e "${GREEN}║  Build Directory: ${CYAN}${BUILD_DIR}${NC}${GREEN}                          ║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  Next Steps:                                               ║${NC}"
    echo -e "${GREEN}║  1. Install: ./${BUILD_DIR}/install_vpk.sh${NC}${GREEN}                    ║${NC}"
    echo -e "${GREEN}║  2. Manual: Copy VPK to ux0:/VPKS/ on Vita${NC}${GREEN}                    ║${NC}"
    echo -e "${GREEN}║  3. Install: Use VitaShell to install VPK${NC}${GREEN}                     ║${NC}"
    echo -e "${GREEN}║  4. Run: Launch from Vita LiveArea${NC}${GREEN}                            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Main build function
main() {
    print_info "Starting LilithOS Voice Daemon VPK build..."
    print_info "VPK Name: $VPK_NAME"
    print_info "Version: $VPK_VERSION"
    print_info "Build directory: $BUILD_DIR"
    
    # Clean previous build
    rm -rf "$BUILD_DIR"
    
    # Run build steps
    create_vpk_structure
    create_livearea_assets
    create_python_runtime
    create_vita_launcher
    create_vpk_manifest
    create_vpk_package
    create_install_script
    
    # Display summary
    display_summary
}

# Handle command line arguments
case "${1:-}" in
    "clean")
        print_info "Cleaning VPK build artifacts..."
        rm -rf "$BUILD_DIR" "${VPK_NAME}_v${VPK_VERSION}.vpk"
        print_success "Clean completed"
        ;;
    "install")
        print_info "Installing VPK to Vita..."
        if [ -f "${VPK_NAME}_v${VPK_VERSION}.vpk" ]; then
            ./"$BUILD_DIR"/install_vpk.sh
        else
            print_error "VPK not found. Run build first."
            exit 1
        fi
        ;;
    "help"|"-h"|"--help")
        echo "LilithOS Voice Daemon VPK Builder"
        echo
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  (no args)  - Build VPK package"
        echo "  clean      - Clean build artifacts"
        echo "  install    - Install VPK to Vita"
        echo "  help       - Show this help message"
        ;;
    *)
        main
        ;;
esac 