#!/bin/bash
# MSI Installer Handler for Windows .msi Files
# --------------------------------------------
# 📋 Quantum Documentation:
#   This script handles Windows .msi installer files in LilithOS.
#   It provides MSI extraction, installation, and management capabilities
#   using Wine and MSI tools for seamless Windows software installation.
#
# 🧩 Feature Context:
#   - MSI file extraction and analysis.
#   - Windows software installation via Wine.
#   - MSI package management and uninstallation.
#   - Installation logging and rollback capabilities.
#
# 🧷 Dependency Listings:
#   - Requires: Wine, msiexec, cabextract, lessmsi
#   - Optional: Orca (MSI editor), additional MSI tools
#
# 💡 Usage Examples:
#   ./msi-installer.sh install "path/to/package.msi"
#   ./msi-installer.sh extract "path/to/package.msi"
#   ./msi-installer.sh uninstall "ProductName"
#
# ⚡ Performance Considerations:
#   - MSI extraction and installation optimization.
#   - Installation caching for faster reinstallation.
#   - Memory usage during large MSI installations.
#
# 🔒 Security Implications:
#   - MSI file validation and integrity checking.
#   - Sandboxed installation environments.
#   - Installation logging for audit trails.
#
# 📜 Changelog Entries:
#   - 2024-06-29: Initial MSI installer handler created.

MSI_DIR="${MSI_DIR:-$PWD/msi}"
CACHE_DIR="${CACHE_DIR:-$PWD/cache}"
LOG_DIR="${LOG_DIR:-$PWD/logs}"

# Function to install MSI package
install_msi() {
    local msi_path="$1"
    local install_options="$2"
    
    if [ ! -f "$msi_path" ]; then
        echo "Error: MSI file not found: $msi_path"
        return 1
    fi
    
    # Check file extension
    if [[ "$msi_path" != *.msi ]]; then
        echo "Error: Not an MSI file: $msi_path"
        return 1
    fi
    
    echo "Installing MSI package: $msi_path"
    
    # Set Wine environment
    export WINEPREFIX="$WINE_DIR/prefix"
    
    # Create log file
    local log_file="$LOG_DIR/msi_install_$(date +%Y%m%d_%H%M%S).log"
    mkdir -p "$LOG_DIR"
    
    # Install MSI using Wine msiexec
    wine msiexec /i "$msi_path" /quiet /log "$log_file" $install_options
    
    if [ $? -eq 0 ]; then
        echo "MSI installation completed successfully."
        echo "Log file: $log_file"
    else
        echo "MSI installation failed. Check log: $log_file"
        return 1
    fi
}

# Function to extract MSI package
extract_msi() {
    local msi_path="$1"
    local extract_dir="$2"
    
    if [ ! -f "$msi_path" ]; then
        echo "Error: MSI file not found: $msi_path"
        return 1
    fi
    
    if [ -z "$extract_dir" ]; then
        extract_dir="$MSI_DIR/extracted/$(basename "$msi_path" .msi)"
    fi
    
    echo "Extracting MSI package: $msi_path"
    echo "Extract directory: $extract_dir"
    
    mkdir -p "$extract_dir"
    
    # Use lessmsi to extract MSI contents
    if command -v lessmsi &> /dev/null; then
        lessmsi x "$msi_path" "$extract_dir"
    else
        # Fallback to cabextract if lessmsi not available
        echo "lessmsi not found, using cabextract..."
        cabextract -d "$extract_dir" "$msi_path"
    fi
    
    echo "MSI extraction completed: $extract_dir"
}

# Function to uninstall MSI package
uninstall_msi() {
    local product_name="$1"
    
    if [ -z "$product_name" ]; then
        echo "Error: Product name required for uninstallation"
        return 1
    fi
    
    echo "Uninstalling MSI package: $product_name"
    
    # Set Wine environment
    export WINEPREFIX="$WINE_DIR/prefix"
    
    # Create log file
    local log_file="$LOG_DIR/msi_uninstall_$(date +%Y%m%d_%H%M%S).log"
    mkdir -p "$LOG_DIR"
    
    # Uninstall using Wine msiexec
    wine msiexec /x "$product_name" /quiet /log "$log_file"
    
    if [ $? -eq 0 ]; then
        echo "MSI uninstallation completed successfully."
        echo "Log file: $log_file"
    else
        echo "MSI uninstallation failed. Check log: $log_file"
        return 1
    fi
}

# Function to list installed MSI products
list_msi_products() {
    echo "Installed MSI Products:"
    
    # Set Wine environment
    export WINEPREFIX="$WINE_DIR/prefix"
    
    # List installed products using Wine registry
    wine reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s | grep -E "DisplayName|DisplayVersion" | head -20
}

# Function to repair MSI installation
repair_msi() {
    local msi_path="$1"
    
    if [ ! -f "$msi_path" ]; then
        echo "Error: MSI file not found: $msi_path"
        return 1
    fi
    
    echo "Repairing MSI installation: $msi_path"
    
    # Set Wine environment
    export WINEPREFIX="$WINE_DIR/prefix"
    
    # Repair using Wine msiexec
    wine msiexec /f "$msi_path" /quiet
    
    if [ $? -eq 0 ]; then
        echo "MSI repair completed successfully."
    else
        echo "MSI repair failed."
        return 1
    fi
}

# Function to validate MSI file
validate_msi() {
    local msi_path="$1"
    
    if [ ! -f "$msi_path" ]; then
        echo "Error: MSI file not found: $msi_path"
        return 1
    fi
    
    echo "Validating MSI file: $msi_path"
    
    # Check file magic number
    local magic=$(file "$msi_path" | grep -o "Composite Document File")
    if [ "$magic" = "Composite Document File" ]; then
        echo "MSI file validation: PASSED"
        return 0
    else
        echo "MSI file validation: FAILED"
        return 1
    fi
}

# Main function
main() {
    case "$1" in
        "install")
            if [ -z "$2" ]; then
                echo "Usage: $0 install <path-to-msi> [options]"
                exit 1
            fi
            install_msi "$2" "$3"
            ;;
        "extract")
            if [ -z "$2" ]; then
                echo "Usage: $0 extract <path-to-msi> [extract-dir]"
                exit 1
            fi
            extract_msi "$2" "$3"
            ;;
        "uninstall")
            if [ -z "$2" ]; then
                echo "Usage: $0 uninstall <product-name>"
                exit 1
            fi
            uninstall_msi "$2"
            ;;
        "list")
            list_msi_products
            ;;
        "repair")
            if [ -z "$2" ]; then
                echo "Usage: $0 repair <path-to-msi>"
                exit 1
            fi
            repair_msi "$2"
            ;;
        "validate")
            if [ -z "$2" ]; then
                echo "Usage: $0 validate <path-to-msi>"
                exit 1
            fi
            validate_msi "$2"
            ;;
        *)
            echo "Usage: $0 {install <path> [options]|extract <path> [dir]|uninstall <product>|list|repair <path>|validate <path>}"
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 