#!/bin/bash

# LilithOS Installation Script
# This script handles the installation of LilithOS on iPhone 4S

# Configuration
IPSW_PATH="build/LilithOS_9.3.6.ipsw"
DEVICE_TYPE="iPhone4,1"  # iPhone 4S

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
    
    # Check for idevicerestore
    if ! command -v idevicerestore &> /dev/null; then
        print_error "idevicerestore not found. Please install libimobiledevice."
        exit 1
    fi
    
    # Check for other required tools
    for tool in "ideviceinfo" "idevice_id"; do
        if ! command -v $tool &> /dev/null; then
            print_error "$tool not found. Please install libimobiledevice."
            exit 1
        fi
    done
}

# Check device connection
check_device() {
    print_status "Checking device connection..."
    
    # Get connected devices
    devices=($(idevice_id -l))
    
    if [ ${#devices[@]} -eq 0 ]; then
        print_error "No devices found. Please connect your iPhone 4S."
        exit 1
    fi
    
    # Check if device is iPhone 4S
    for device in "${devices[@]}"; do
        device_type=$(ideviceinfo -s ProductType -u "$device")
        if [ "$device_type" = "$DEVICE_TYPE" ]; then
            print_status "Found iPhone 4S: $device"
            return 0
        fi
    done
    
    print_error "No iPhone 4S found. Please connect the correct device."
    exit 1
}

# Put device in DFU mode
enter_dfu_mode() {
    print_status "Preparing to enter DFU mode..."
    print_warning "Please follow these steps:"
    echo "1. Press and hold the Power button for 3 seconds"
    echo "2. While holding Power, press and hold the Home button"
    echo "3. Keep both buttons held for 10 seconds"
    echo "4. Release the Power button but keep holding Home"
    echo "5. Keep holding Home until the device enters DFU mode"
    
    read -p "Press Enter when the device is in DFU mode..."
}

# Install IPSW
install_ipsw() {
    print_status "Installing LilithOS..."
    
    if [ ! -f "$IPSW_PATH" ]; then
        print_error "IPSW file not found: $IPSW_PATH"
        exit 1
    fi
    
    # Use idevicerestore to flash the IPSW
    idevicerestore -d "$IPSW_PATH"
    
    if [ $? -eq 0 ]; then
        print_status "Installation completed successfully!"
    else
        print_error "Installation failed. Please check the device and try again."
        exit 1
    fi
}

# Main execution
main() {
    print_status "Starting LilithOS installation..."
    
    check_requirements
    check_device
    enter_dfu_mode
    install_ipsw
    
    print_status "Installation process completed!"
    print_status "Your iPhone 4S should now be running LilithOS!"
}

# Run main function
main 