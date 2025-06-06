#!/bin/bash

# LilithOS IPSW Builder Script
# This script automates the process of creating a custom IPSW for iPhone 4S

# Configuration
BASE_IPSW="iPhone4,1_9.3.6_13G37_Restore.ipsw"
OUTPUT_DIR="build"
WORK_DIR="work"
TOOLS_DIR="tools"
SRC_DIR="src"
RESOURCES_DIR="resources"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print status messages
print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

# Function to print error messages
print_error() {
    echo -e "${RED}[!]${NC} $1"
}

# Function to print warning messages
print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check for required tools
check_requirements() {
    print_status "Checking requirements..."
    
    # Check for Python dependencies
    if ! python3 -c "import PIL, imageio" &> /dev/null; then
        print_error "Required Python packages not found. Installing..."
        pip3 install Pillow imageio
    fi
    
    # Check for Homebrew
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew not found. Please install Homebrew first."
        exit 1
    fi
    
    # Check and install required tools
    local tools=(
        "unzip"
        "zip"
        "plutil"
        "idevicerestore"
        "libimobiledevice"
        "libusbmuxd"
        "libplist"
        "libimobiledevice-glue"
    )
    
    for tool in "${tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            print_warning "$tool not found. Attempting to install..."
            case $tool in
                "idevicerestore")
                    brew install --HEAD libimobiledevice
                    ;;
                "libimobiledevice"|"libusbmuxd"|"libplist"|"libimobiledevice-glue")
                    brew install --HEAD $tool
                    ;;
                *)
                    brew install $tool
                    ;;
            esac
            
            # Verify installation
            if ! command -v $tool &> /dev/null; then
                print_error "Failed to install $tool. Please install manually."
                exit 1
            fi
        fi
    done
    
    print_status "All requirements satisfied."
}

# Create necessary directories
setup_directories() {
    print_status "Setting up directories..."
    mkdir -p "$OUTPUT_DIR" "$WORK_DIR" "$RESOURCES_DIR"
}

# Extract base IPSW
extract_ipsw() {
    print_status "Extracting base IPSW..."
    if [ ! -f "$BASE_IPSW" ]; then
        print_error "Base IPSW not found: $BASE_IPSW"
        exit 1
    fi
    
    unzip -q "$BASE_IPSW" -d "$WORK_DIR"
}

# Apply kernel patches
apply_kernel_patches() {
    print_status "Applying kernel patches..."
    # Compile kernel patches
    gcc -o "$TOOLS_DIR/kernel_patcher" "$SRC_DIR/kernel/patches.c"
    
    # Apply patches
    "$TOOLS_DIR/kernel_patcher" "$WORK_DIR/kernelcache"
}

# Apply system modifications
apply_system_modifications() {
    print_status "Applying system modifications..."
    
    # Copy system modifications
    cp "$SRC_DIR/system/modifications.plist" "$WORK_DIR/System/Library/LaunchDaemons/"
    
    # Create boot animation
    python3 "$SRC_DIR/system/boot_animation.py" "$RESOURCES_DIR"
    cp "$OUTPUT_DIR/boot_animation.gif" "$WORK_DIR/System/Library/CoreServices/"
    cp "$OUTPUT_DIR/BootAnimation.plist" "$WORK_DIR/System/Library/CoreServices/"
    
    # Add LilithOS branding
    echo "LilithOS 9.3.6" > "$WORK_DIR/System/Library/CoreServices/SystemVersion.plist"
}

# Sign IPSW
sign_ipsw() {
    print_status "Signing IPSW..."
    python3 "$TOOLS_DIR/sign_ipsw.py" \
        "$WORK_DIR" \
        "$RESOURCES_DIR/certificate.p12" \
        "$RESOURCES_DIR/private.key"
}

# Repack IPSW
repack_ipsw() {
    print_status "Repacking IPSW..."
    cd "$WORK_DIR"
    zip -r "../$OUTPUT_DIR/LilithOS_9.3.6.ipsw" .
    cd ..
}

# Cleanup
cleanup() {
    print_status "Cleaning up..."
    rm -rf "$WORK_DIR"
}

# Main execution
main() {
    print_status "Starting LilithOS IPSW build process..."
    
    check_requirements
    setup_directories
    extract_ipsw
    apply_kernel_patches
    apply_system_modifications
    sign_ipsw
    repack_ipsw
    cleanup
    
    print_status "Build process completed!"
    print_status "Output IPSW: $OUTPUT_DIR/LilithOS_9.3.6.ipsw"
}

# Run main function
main 