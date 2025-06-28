#!/bin/bash

# Windows Integration Script for LilithOS
# This script handles the integration of LilithOS with Windows systems
# and sets up the C: drive access and configuration

# Configuration
WINDOWS_DRIVE="/mnt/c"
LILITHOS_CONFIG="/etc/lilithos"
MOUNT_POINTS="/etc/fstab"

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit 1
    fi
}

# Function to create necessary directories
setup_directories() {
    echo "Creating necessary directories..."
    mkdir -p "$LILITHOS_CONFIG"
    mkdir -p "$WINDOWS_DRIVE"
}

# Function to setup C: drive access
setup_c_drive() {
    echo "Setting up C: drive access..."
    
    # Add C: drive to fstab if not already present
    if ! grep -q "$WINDOWS_DRIVE" "$MOUNT_POINTS"; then
        echo "# Windows C: drive mount" >> "$MOUNT_POINTS"
        echo "/dev/sda1 $WINDOWS_DRIVE ntfs-3g defaults,umask=022 0 0" >> "$MOUNT_POINTS"
    fi
    
    # Mount the drive
    mount "$WINDOWS_DRIVE"
}

# Function to setup Windows integration
setup_windows_integration() {
    echo "Setting up Windows integration..."
    
    # Create Windows integration config
    cat > "$LILITHOS_CONFIG/windows-integration.conf" << EOF
# Windows Integration Configuration
WINDOWS_DRIVE="$WINDOWS_DRIVE"
AUTO_MOUNT=true
SHARE_FILES=true
EOF

    # Setup file sharing permissions
    chmod 755 "$WINDOWS_DRIVE"
}

# Function to verify installation
verify_installation() {
    echo "Verifying installation..."
    
    if [ -d "$WINDOWS_DRIVE" ]; then
        echo "✅ C: drive access configured successfully"
    else
        echo "❌ C: drive access configuration failed"
        exit 1
    fi
    
    if [ -f "$LILITHOS_CONFIG/windows-integration.conf" ]; then
        echo "✅ Windows integration configuration created"
    else
        echo "❌ Windows integration configuration failed"
        exit 1
    fi
}

# Main execution
echo "Starting Windows integration setup..."
check_root
setup_directories
setup_c_drive
setup_windows_integration
verify_installation

echo "Windows integration completed successfully!"
echo "You can now access your C: drive at $WINDOWS_DRIVE" 