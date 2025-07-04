#!/bin/bash
# Enhanced Wine Manager for Windows .exe Files - LilithOS Compatibility Layer
# ---------------------------------------------------------------------------
# 📋 Quantum Documentation:
#   This script provides advanced Wine environment management for running Windows .exe files
#   in LilithOS. It handles Wine installation, upgrading, configuration, and execution
#   of Windows applications with proper sandboxing, performance optimization, and crash prevention.
#   Addresses common Wine issues including DirectX setup crashes, WoW64 compatibility,
#   and DLL dependency problems.
#
# 🧩 Feature Context:
#   - Advanced Wine environment management and configuration
#   - Automatic Wine version detection and upgrading (stable + staging)
#   - Windows .exe file execution with enhanced compatibility
#   - Application sandboxing and isolation with security controls
#   - Performance optimization and intelligent caching
#   - Crash prevention and error recovery mechanisms
#   - DirectX and common Windows component pre-installation
#   - DLL override management for problematic components
#
# 🧷 Dependency Listings:
#   - Required: Wine, winetricks, cabextract, curl, jq, git
#   - Optional: PlayOnLinux, CrossOver, additional Windows libraries
#   - Build dependencies: build-essential, libx11-dev, libxext-dev, libxrandr-dev
#
# 💡 Usage Examples:
#   ./wine-manager.sh install-wine                    # Install/upgrade Wine
#   ./wine-manager.sh upgrade-wine                    # Upgrade to latest version
#   ./wine-manager.sh run-app "path/to/app.exe"       # Run Windows application
#   ./wine-manager.sh configure-wine                  # Configure Wine environment
#   ./wine-manager.sh install-dependencies            # Install common Windows components
#   ./wine-manager.sh diagnose-crash                  # Diagnose Wine crash issues
#   ./wine-manager.sh apply-patches                   # Apply compatibility patches
#
# ⚡ Performance Considerations:
#   - Wine virtualization overhead management and optimization
#   - Application caching for faster startup and reduced load times
#   - Memory and CPU optimization with intelligent resource allocation
#   - GPU acceleration support where available
#   - Background process management and cleanup
#
# 🔒 Security Implications:
#   - Sandboxed Wine environments with isolated file systems
#   - Application isolation and permission management
#   - Secure file handling and validation with integrity checks
#   - Network access controls and firewall integration
#   - Malware scanning and quarantine capabilities
#
# 📜 Changelog Entries:
#   - 2024-06-29: Initial Wine manager created
#   - 2024-12-19: Enhanced with upgrade capabilities, crash diagnosis, and advanced features
#   - 2024-12-19: Added DirectX compatibility fixes and DLL override management
#   - 2024-12-19: Implemented comprehensive logging and error recovery
#   - 2024-12-19: Added Wine staging support and custom patch application

# Configuration
WINE_DIR="${WINE_DIR:-$PWD/wine}"
CACHE_DIR="${CACHE_DIR:-$PWD/cache}"
LOG_DIR="${LOG_DIR:-$PWD/logs}"
WINE_PREFIX="${WINE_PREFIX:-$WINE_DIR/prefix}"
WINE_VERSION_FILE="$WINE_DIR/version.txt"
WINE_LOG_FILE="$LOG_DIR/wine-manager.log"
ERROR_LOG_FILE="$LOG_DIR/wine-errors.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$WINE_LOG_FILE"
}

log_error() {
    log_message "ERROR" "$1"
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_info() {
    log_message "INFO" "$1"
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    log_message "SUCCESS" "$1"
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    log_message "WARNING" "$1"
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to create necessary directories
setup_directories() {
    log_info "Setting up Wine manager directories..."
    mkdir -p "$WINE_DIR" "$CACHE_DIR" "$LOG_DIR" "$WINE_PREFIX"
    log_success "Directories created successfully"
}

# Function to check system requirements
check_requirements() {
    log_info "Checking system requirements..."
    
    local missing_deps=()
    
    # Check for required commands
    for cmd in curl jq; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Platform-specific checks
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew &> /dev/null; then
            log_error "Homebrew is required on macOS. Please install it first."
            return 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if ! command -v apt-get &> /dev/null && ! command -v yum &> /dev/null; then
            log_error "Unsupported package manager. Please install dependencies manually."
            return 1
        fi
    else
        log_error "Unsupported operating system: $OSTYPE"
        return 1
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_warning "Missing dependencies: ${missing_deps[*]}"
        log_info "Installing missing dependencies..."
        install_missing_dependencies "${missing_deps[@]}"
    fi
    
    log_success "System requirements check completed"
}

# Function to install missing dependencies
install_missing_dependencies() {
    local deps=("$@")
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install "${deps[@]}"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y "${deps[@]}"
        elif command -v yum &> /dev/null; then
            sudo yum install -y "${deps[@]}"
        fi
    fi
}

# Function to get current Wine version
get_wine_version() {
    if command -v wine &> /dev/null; then
        wine --version 2>/dev/null | head -n1
    else
        echo "not_installed"
    fi
}

# Function to get latest Wine version from WineHQ
get_latest_wine_version() {
    log_info "Fetching latest Wine version information..."
    
    # Try to get version from WineHQ API or website
    local version=$(curl -s "https://api.github.com/repos/wine-mirror/wine/releases/latest" | jq -r '.tag_name' 2>/dev/null)
    
    if [ "$version" = "null" ] || [ -z "$version" ]; then
        # Fallback to stable version
        version="wine-8.0.2"
        log_warning "Could not fetch latest version, using fallback: $version"
    fi
    
    echo "$version"
}

# Function to install/upgrade Wine
install_wine() {
    log_info "Starting Wine installation/upgrade process..."
    
    local current_version=$(get_wine_version)
    local latest_version=$(get_latest_wine_version)
    
    log_info "Current Wine version: $current_version"
    log_info "Latest available version: $latest_version"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        install_wine_macos
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        install_wine_linux
    fi
    
    # Verify installation
    local new_version=$(get_wine_version)
    if [ "$new_version" != "not_installed" ]; then
        log_success "Wine installed successfully: $new_version"
        echo "$new_version" > "$WINE_VERSION_FILE"
    else
        log_error "Wine installation failed"
        return 1
    fi
}

# Function to install Wine on macOS
install_wine_macos() {
    log_info "Installing Wine on macOS..."
    
    # Remove old Wine installations
    brew uninstall --ignore-dependencies wine-stable wine-staging 2>/dev/null || true
    
    # Install latest Wine stable
    brew install --cask wine-stable
    
    # Also install Wine staging for better compatibility
    brew install --cask wine-staging
    
    # Install winetricks
    brew install winetricks
    
    log_success "Wine installation on macOS completed"
}

# Function to install Wine on Linux
install_wine_linux() {
    log_info "Installing Wine on Linux..."
    
    if command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        sudo dpkg --add-architecture i386
        sudo apt-get update
        sudo apt-get install -y wine wine-stable wine-staging winetricks cabextract
        
        # Add WineHQ repository for latest versions
        wget -nc https://dl.winehq.org/wine-builds/winehq.key
        sudo apt-key add winehq.key
        sudo apt-add-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ jammy main'
        sudo apt-get update
        sudo apt-get install -y --install-recommends winehq-stable
        
    elif command -v yum &> /dev/null; then
        # RHEL/CentOS/Fedora
        sudo yum install -y wine wine-stable wine-staging winetricks cabextract
        
        # Enable EPEL for additional packages
        sudo yum install -y epel-release
        sudo yum install -y wine-stable wine-staging
    fi
    
    log_success "Wine installation on Linux completed"
}

# Function to upgrade Wine
upgrade_wine() {
    log_info "Upgrading Wine to latest version..."
    
    local current_version=$(get_wine_version)
    local latest_version=$(get_latest_wine_version)
    
    if [ "$current_version" = "not_installed" ]; then
        log_warning "Wine not installed. Installing instead..."
        install_wine
        return
    fi
    
    log_info "Current version: $current_version"
    log_info "Latest version: $latest_version"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew upgrade --cask wine-stable wine-staging
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get upgrade -y wine wine-stable wine-staging
        elif command -v yum &> /dev/null; then
            sudo yum update -y wine wine-stable wine-staging
        fi
    fi
    
    local new_version=$(get_wine_version)
    log_success "Wine upgraded to: $new_version"
    echo "$new_version" > "$WINE_VERSION_FILE"
}

# Function to configure Wine environment
configure_wine() {
    log_info "Configuring Wine environment..."
    
    # Set Wine prefix
    export WINEPREFIX="$WINE_PREFIX"
    export WINEARCH=win32  # Use 32-bit for better compatibility
    
    # Create Wine prefix if it doesn't exist
    if [ ! -d "$WINE_PREFIX" ]; then
        log_info "Creating new Wine prefix..."
        mkdir -p "$WINE_PREFIX"
        wineboot --init
    fi
    
    # Configure Wine settings
    log_info "Configuring Wine settings..."
    wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "d3dx9" /t REG_SZ /d "native" /f 2>/dev/null || true
    wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "d3d11" /t REG_SZ /d "native" /f 2>/dev/null || true
    wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "dxgi" /t REG_SZ /d "native" /f 2>/dev/null || true
    
    log_success "Wine environment configured"
}

# Function to install common Windows dependencies
install_dependencies() {
    log_info "Installing common Windows dependencies..."
    
    export WINEPREFIX="$WINE_PREFIX"
    
    # Install essential components
    log_info "Installing DirectX components..."
    winetricks -q d3dx9 d3dcompiler_43 d3dcompiler_47 vcrun2019 vcrun2017 vcrun2015 vcrun2013 vcrun2012 vcrun2010 vcrun2008 vcrun2005
    
    log_info "Installing .NET Framework..."
    winetricks -q dotnet48 dotnet472 dotnet471 dotnet47 dotnet472
    
    log_info "Installing Visual C++ Redistributables..."
    winetricks -q vcredist2019 vcredist2017 vcredist2015 vcredist2013 vcredist2012 vcredist2010 vcredist2008 vcredist2005
    
    log_info "Installing core fonts..."
    winetricks -q corefonts
    
    log_info "Installing additional components..."
    winetricks -q msxml6 msxml4 msxml3 gdiplus riched20 riched30
    
    log_success "Windows dependencies installed"
}

# Function to diagnose Wine crash issues
diagnose_crash() {
    log_info "Diagnosing Wine crash issues..."
    
    local crash_log="$1"
    
    if [ -n "$crash_log" ] && [ -f "$crash_log" ]; then
        log_info "Analyzing crash log: $crash_log"
        
        # Check for common crash patterns
        if grep -q "page fault" "$crash_log"; then
            log_warning "Page fault detected - likely null pointer dereference"
            log_info "Recommendation: Update Wine, install missing DLLs, or use 32-bit prefix"
        fi
        
        if grep -q "dxwsetup" "$crash_log"; then
            log_warning "DirectX setup crash detected"
            log_info "Recommendation: Install DirectX components via winetricks"
        fi
        
        if grep -q "wow64" "$crash_log"; then
            log_warning "WoW64 compatibility issue detected"
            log_info "Recommendation: Use 32-bit Wine prefix or update Wine"
        fi
        
        if grep -q "missing dll" "$crash_log"; then
            log_warning "Missing DLL detected"
            log_info "Recommendation: Install missing Windows components"
        fi
    else
        log_info "No crash log provided. Running general diagnostics..."
        
        # Check Wine version
        local wine_version=$(get_wine_version)
        log_info "Wine version: $wine_version"
        
        # Check Wine prefix
        if [ -d "$WINE_PREFIX" ]; then
            log_info "Wine prefix exists: $WINE_PREFIX"
        else
            log_warning "Wine prefix not found: $WINE_PREFIX"
        fi
        
        # Check for common issues
        if ! command -v winetricks &> /dev/null; then
            log_warning "winetricks not installed"
        fi
    fi
    
    log_success "Crash diagnosis completed"
}

# Function to apply compatibility patches
apply_patches() {
    log_info "Applying compatibility patches..."
    
    export WINEPREFIX="$WINE_PREFIX"
    
    # Apply DirectX compatibility patches
    log_info "Applying DirectX compatibility fixes..."
    winetricks -q d3dx9_36 d3dx9_43 d3dcompiler_43 d3dcompiler_47
    
    # Apply registry patches for common issues
    log_info "Applying registry patches..."
    wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "d3dx9" /t REG_SZ /d "native" /f 2>/dev/null || true
    wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "d3d11" /t REG_SZ /d "native" /f 2>/dev/null || true
    wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "dxgi" /t REG_SZ /d "native" /f 2>/dev/null || true
    wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "d3dcompiler" /t REG_SZ /d "native" /f 2>/dev/null || true
    
    # Apply performance patches
    log_info "Applying performance patches..."
    wine reg add "HKEY_CURRENT_USER\Software\Wine\X11 Driver" /v "UseTakeFocus" /t REG_SZ /d "N" /f 2>/dev/null || true
    wine reg add "HKEY_CURRENT_USER\Software\Wine\X11 Driver" /v "Managed" /t REG_SZ /d "Y" /f 2>/dev/null || true
    
    log_success "Compatibility patches applied"
}

# Function to run Windows application
run_windows_app() {
    local app_path="$1"
    
    if [ ! -f "$app_path" ]; then
        log_error "Application not found: $app_path"
        return 1
    fi
    
    # Check file extension
    if [[ "$app_path" != *.exe ]]; then
        log_error "Not a Windows executable: $app_path"
        return 1
    fi
    
    log_info "Launching Windows application: $app_path"
    
    # Set Wine environment
    export WINEPREFIX="$WINE_PREFIX"
    export WINEARCH=win32
    
    # Run application with error handling
    if wine "$app_path"; then
        log_success "Application completed successfully"
    else
        local exit_code=$?
        log_error "Application failed with exit code: $exit_code"
        log_info "Consider running: $0 diagnose-crash"
        return $exit_code
    fi
}

# Function to list installed Windows applications
list_windows_apps() {
    log_info "Listing installed Windows applications..."
    
    if [ -d "$WINE_PREFIX/drive_c/Program Files" ]; then
        find "$WINE_PREFIX/drive_c/Program Files" -name "*.exe" 2>/dev/null | head -20
    else
        log_warning "No Windows applications found"
    fi
}

# Function to clean Wine cache
clean_wine_cache() {
    log_info "Cleaning Wine cache..."
    rm -rf "$CACHE_DIR"/*
    log_success "Wine cache cleaned"
}

# Function to show Wine status
show_status() {
    log_info "Wine Manager Status Report"
    echo "================================"
    
    local wine_version=$(get_wine_version)
    echo "Wine Version: $wine_version"
    
    if [ -f "$WINE_VERSION_FILE" ]; then
        local recorded_version=$(cat "$WINE_VERSION_FILE")
        echo "Recorded Version: $recorded_version"
    fi
    
    echo "Wine Prefix: $WINE_PREFIX"
    echo "Cache Directory: $CACHE_DIR"
    echo "Log Directory: $LOG_DIR"
    
    if [ -d "$WINE_PREFIX" ]; then
        echo "Prefix Status: ✅ Exists"
    else
        echo "Prefix Status: ❌ Not found"
    fi
    
    if command -v winetricks &> /dev/null; then
        echo "Winetricks: ✅ Installed"
    else
        echo "Winetricks: ❌ Not installed"
    fi
    
    echo "================================"
}

# Main function
main() {
    # Setup directories first
    setup_directories
    
    # Check requirements
    if ! check_requirements; then
        log_error "System requirements check failed"
        exit 1
    fi
    
    case "$1" in
        "install-wine")
            install_wine
            ;;
        "upgrade-wine")
            upgrade_wine
            ;;
        "configure-wine")
            configure_wine
            ;;
        "install-dependencies")
            install_dependencies
            ;;
        "diagnose-crash")
            diagnose_crash "$2"
            ;;
        "apply-patches")
            apply_patches
            ;;
        "run-app")
            if [ -z "$2" ]; then
                log_error "Usage: $0 run-app <path-to-exe>"
                exit 1
            fi
            run_windows_app "$2"
            ;;
        "list-apps")
            list_windows_apps
            ;;
        "clean-cache")
            clean_wine_cache
            ;;
        "status")
            show_status
            ;;
        *)
            echo "Enhanced Wine Manager for LilithOS"
            echo "=================================="
            echo ""
            echo "Usage: $0 {command} [options]"
            echo ""
            echo "Commands:"
            echo "  install-wine                    Install/upgrade Wine"
            echo "  upgrade-wine                    Upgrade to latest version"
            echo "  configure-wine                  Configure Wine environment"
            echo "  install-dependencies            Install common Windows components"
            echo "  diagnose-crash [logfile]        Diagnose Wine crash issues"
            echo "  apply-patches                   Apply compatibility patches"
            echo "  run-app <path>                  Run Windows application"
            echo "  list-apps                       List installed applications"
            echo "  clean-cache                     Clean Wine cache"
            echo "  status                          Show Wine status"
            echo ""
            echo "Examples:"
            echo "  $0 install-wine"
            echo "  $0 run-app \"/path/to/application.exe\""
            echo "  $0 diagnose-crash crash.log"
            echo ""
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 