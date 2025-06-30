#!/bin/bash
# Tricky Doors Launch Hook
# Automatically triggered when Tricky Doors app is launched

echo "Tricky Doors Launch Hook Activated"
echo "=================================="
echo "Switch Model: SN hac-001(-01)"
echo "Tegra Chip: Tegra X1"
echo "Atmosphere Version: 1.7.1"
echo ""

# Check if Atmosphere is already installed
if [ -d "/atmosphere" ]; then
    echo "Atmosphere is already installed."
    echo "Checking for updates..."
    
    # Update Atmosphere files
    cp -r /switch/TrickyDoors/atmosphere/* /atmosphere/
    echo "Atmosphere updated successfully."
else
    echo "Atmosphere not found. Starting installation..."
    
    # Create Atmosphere directories
    mkdir -p /atmosphere
    mkdir -p /bootloader
    mkdir -p /switch
    mkdir -p /config
    
    # Copy Atmosphere files
    cp -r /switch/TrickyDoors/atmosphere/* /atmosphere/
    cp -r /switch/TrickyDoors/bootloader/* /bootloader/
    
    echo "Atmosphere installed successfully."
fi

# Install Hekate
echo "Installing Hekate..."
cp /switch/TrickyDoors/bootloader/hekate_ctcaer_6.1.1.bin /bootloader/hekate.bin

# Create payloads directory
mkdir -p /bootloader/payloads

# Copy payloads
cp /switch/TrickyDoors/payloads/* /bootloader/payloads/

# Configure auto-boot
echo "Configuring auto-boot..."
cp /switch/TrickyDoors/config/auto_boot.conf /bootloader/auto_boot.conf

echo "Installation completed successfully!"
echo "Rebooting into Atmosphere..."

# Reboot into Atmosphere
reboot
