#!/bin/bash

# Build script for LilithOS UpgradeNet
# Purpose: Build OTA + USB Update Daemon and BLE Whisperer Device Daemon VPK

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

PROJECT_NAME="LilithOS-UpgradeNet"
BUILD_DIR="build"
VITA_SDK="${VITASDK:-/usr/local/vitasdk}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

print_header() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    LilithOS UpgradeNet                       ║"
    echo "║              OTA + USB Update & BLE Whisperer                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
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

# ============================================================================
# ENVIRONMENT CHECK
# ============================================================================

check_environment() {
    print_step "Checking build environment..."
    
    # Check if VitaSDK is installed
    if [ ! -d "$VITA_SDK" ]; then
        print_error "VitaSDK not found at $VITA_SDK"
        print_info "Please install VitaSDK or set VITASDK environment variable"
        exit 1
    fi
    
    # Check if VitaSDK tools are available
    if [ ! -f "$VITA_SDK/bin/arm-vita-eabi-gcc" ]; then
        print_error "VitaSDK toolchain not found"
        print_info "Please ensure VitaSDK is properly installed"
        exit 1
    fi
    
    # Check if CMake is available
    if ! command -v cmake &> /dev/null; then
        print_error "CMake not found"
        print_info "Please install CMake (version 3.16 or higher)"
        exit 1
    fi
    
    # Check if Python is available for LiveArea asset generation
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 not found"
        print_info "Required for LiveArea asset generation"
        exit 1
    fi
    
    # Check if required source files exist
    local required_files=("main.c" "update_daemon.c" "ble_whisperer.c" "CMakeLists.txt")
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            print_error "Required file not found: $file"
            exit 1
        fi
    done
    
    print_success "Build environment check passed"
}

# ============================================================================
# LIVEAREA ASSET GENERATION
# ============================================================================

generate_livearea_assets() {
    print_step "Generating LiveArea assets with Lilybear theme..."
    
    # Check if asset generator exists
    if [ ! -f "generate_livearea_assets.py" ]; then
        print_error "LiveArea asset generator not found: generate_livearea_assets.py"
        exit 1
    fi
    
    # Check if virtual environment exists, create if not
    if [ ! -d "livearea_env" ]; then
        print_info "Creating Python virtual environment for asset generation..."
        python3 -m venv livearea_env
    fi
    
    # Activate virtual environment and install dependencies
    print_info "Installing Python dependencies..."
    source livearea_env/bin/activate
    pip install pillow numpy > /dev/null 2>&1 || {
        print_error "Failed to install Python dependencies"
        exit 1
    }
    
    # Generate assets
    print_info "Generating divine-black theme assets..."
    python3 generate_livearea_assets.py
    
    if [ $? -eq 0 ]; then
        print_success "LiveArea assets generated successfully"
        print_info "Assets created:"
        print_info "  - sce_sys/icon0.png (Lilybear emblem)"
        print_info "  - sce_sys/livearea/contents/bg.png (Matrix background)"
        print_info "  - sce_sys/livearea/contents/startup.png (Startup screen)"
        print_info "  - sce_sys/livearea/contents/start.png (Start button)"
        print_info "  - sce_sys/livearea/contents/template.xml (LiveArea template)"
    else
        print_error "LiveArea asset generation failed"
        exit 1
    fi
    
    # Deactivate virtual environment
    deactivate
}

# ============================================================================
# BUILD FUNCTIONS
# ============================================================================

clean_build() {
    print_step "Cleaning build directory..."
    
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        print_success "Build directory cleaned"
    else
        print_info "Build directory does not exist, skipping clean"
    fi
}

create_build_dir() {
    print_step "Creating build directory..."
    
    mkdir -p "$BUILD_DIR"
    print_success "Build directory created: $BUILD_DIR"
}

configure_build() {
    print_step "Configuring build with CMake..."
    
    cd "$BUILD_DIR"
    
    # Configure with CMake
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE="$VITA_SDK/share/vita.toolchain.cmake" \
        -DVITA_SDK="$VITA_SDK"
    
    if [ $? -eq 0 ]; then
        print_success "CMake configuration completed"
    else
        print_error "CMake configuration failed"
        exit 1
    fi
    
    cd ..
}

build_project() {
    print_step "Building project..."
    
    cd "$BUILD_DIR"
    
    # Build the project
    make -j$(nproc 2>/dev/null || echo 4)
    
    if [ $? -eq 0 ]; then
        print_success "Build completed successfully"
    else
        print_error "Build failed"
        exit 1
    fi
    
    cd ..
}

verify_build() {
    print_step "Verifying build artifacts..."
    
    local vpk_file="$BUILD_DIR/$PROJECT_NAME.vpk"
    local self_file="$BUILD_DIR/$PROJECT_NAME.self"
    local param_file="$BUILD_DIR/param.sfo"
    
    # Check if VPK was created
    if [ ! -f "$vpk_file" ]; then
        print_error "VPK file not found: $vpk_file"
        exit 1
    fi
    
    # Check if SELF file was created
    if [ ! -f "$self_file" ]; then
        print_error "SELF file not found: $self_file"
        exit 1
    fi
    
    # Check if param.sfo was created
    if [ ! -f "$param_file" ]; then
        print_error "param.sfo file not found: $param_file"
        exit 1
    fi
    
    # Check if LiveArea assets are included
    local livearea_assets=(
        "$BUILD_DIR/sce_sys/icon0.png"
        "$BUILD_DIR/sce_sys/livearea/contents/bg.png"
        "$BUILD_DIR/sce_sys/livearea/contents/startup.png"
        "$BUILD_DIR/sce_sys/livearea/contents/start.png"
        "$BUILD_DIR/sce_sys/livearea/contents/template.xml"
    )
    
    for asset in "${livearea_assets[@]}"; do
        if [ ! -f "$asset" ]; then
            print_warning "LiveArea asset not found: $asset"
        fi
    done
    
    # Get file sizes
    local vpk_size=$(du -h "$vpk_file" | cut -f1)
    local self_size=$(du -h "$self_file" | cut -f1)
    
    print_success "Build verification passed"
    print_info "VPK size: $vpk_size"
    print_info "SELF size: $self_size"
    print_info "LiveArea assets: Included with Lilybear theme"
}

# ============================================================================
# INSTALLATION
# ============================================================================

show_install_instructions() {
    print_step "Installation Instructions"
    
    local vpk_file="$BUILD_DIR/$PROJECT_NAME.vpk"
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    INSTALLATION GUIDE                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo "1. Copy the VPK file to your PS Vita:"
    echo "   $vpk_file"
    echo ""
    echo "2. Transfer to Vita using one of these methods:"
    echo "   - USB: Copy to ux0:/app/"
    echo "   - FTP: Upload to ux0:/app/"
    echo "   - SD2Vita: Copy to ux0:/app/"
    echo ""
    echo "3. Install on Vita:"
    echo "   - Use VitaShell Package Installer"
    echo "   - Or use Package Installer homebrew"
    echo ""
    echo "4. Launch the application from LiveArea"
    echo ""
    echo "🐾 Lilybear purrs: Your LilithOS UpgradeNet is ready! 💋"
}

# ============================================================================
# DEBUG BUILD
# ============================================================================

build_debug() {
    print_step "Building debug version..."
    
    clean_build
    create_build_dir
    
    cd "$BUILD_DIR"
    
    # Configure with debug flags
    cmake .. \
        -DCMAKE_BUILD_TYPE=Debug \
        -DCMAKE_TOOLCHAIN_FILE="$VITA_SDK/share/vita.toolchain.cmake" \
        -DVITA_SDK="$VITA_SDK"
    
    # Build debug version
    make -j$(nproc 2>/dev/null || echo 4)
    
    cd ..
    
    print_success "Debug build completed"
    print_info "Debug VPK: $BUILD_DIR/$PROJECT_NAME.vpk"
}

# ============================================================================
# CLEAN TARGET
# ============================================================================

clean_all() {
    print_step "Cleaning all build artifacts..."
    
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        print_success "All build artifacts cleaned"
    else
        print_info "No build artifacts to clean"
    fi
}

# ============================================================================
# HELP
# ============================================================================

show_help() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  build       Build the project (default)"
    echo "  debug       Build debug version"
    echo "  clean       Clean build artifacts"
    echo "  install     Show installation instructions"
    echo "  help        Show this help message"
    echo ""
    echo "Environment:"
    echo "  VITASDK     Path to VitaSDK installation (default: /usr/local/vitasdk)"
    echo ""
    echo "Examples:"
    echo "  $0 build"
    echo "  $0 debug"
    echo "  VITASDK=/path/to/vitasdk $0 build"
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

main() {
    print_header
    
    # Parse command line arguments
    case "${1:-build}" in
        "build")
            check_environment
            generate_livearea_assets
            clean_build
            create_build_dir
            configure_build
            build_project
            verify_build
            show_install_instructions
            ;;
        "debug")
            check_environment
            generate_livearea_assets
            build_debug
            show_install_instructions
            ;;
        "clean")
            clean_all
            ;;
        "install")
            show_install_instructions
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 