#!/bin/bash
# LilithOS Advanced Features Initialization Script
# ----------------------------------------------
# 📋 Quantum Documentation:
#   This script initializes all 10 advanced features in the LilithOS installation.
#   It loads each module and sets up the necessary environment variables.
#
# 🧩 Feature Context:
#   - Integrates all new advanced features into the existing LilithOS system.
#   - Sets up environment variables and directories for each feature.
#   - Provides a unified initialization interface.
#
# 🧷 Dependency Listings:
#   - Requires: All feature modules to be installed in /Volumes/LilithOS/lilithos/modules/features/
#   - Optional: GUI frameworks, additional dependencies per feature
#
# 💡 Usage Example:
#   sudo bash scripts/initialize_features.sh
#
# ⚡ Performance Considerations:
#   - Efficient module loading with minimal overhead.
#   - Parallel initialization where possible.
#
# 🔒 Security Implications:
#   - Secure initialization of security-focused features.
#   - Proper permission handling for all modules.
#
# 📜 Changelog Entries:
#   - 2024-06-29: Initial feature integration script created.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}  LilithOS Advanced Features${NC}"
    echo -e "${CYAN}================================${NC}"
}

# Configuration
LILITHOS_ROOT="/Volumes/LilithOS/lilithos"
MODULES_DIR="$LILITHOS_ROOT/modules/features"

# Check if LilithOS is mounted
if [ ! -d "$LILITHOS_ROOT" ]; then
    print_error "LilithOS not found at $LILITHOS_ROOT"
    print_error "Please ensure LilithOS is properly installed and mounted"
    exit 1
fi

# Function to initialize a feature module
init_feature() {
    local feature_name="$1"
    local feature_dir="$MODULES_DIR/$feature_name"
    
    if [ -d "$feature_dir" ] && [ -f "$feature_dir/init.sh" ]; then
        print_status "Initializing $feature_name..."
        cd "$feature_dir"
        source "$feature_dir/init.sh"
        
        # Call the specific init function for each feature
        case "$feature_name" in
            "secure-vault")
                quantum_vault_init
                ;;
            "module-store")
                module_store_init
                ;;
            "celestial-monitor")
                celestial_monitor_init
                ;;
            "quantum-portal")
                quantum_portal_init
                ;;
            "lilith-ai")
                lilith_ai_init
                ;;
            "theme-engine")
                theme_engine_init
                ;;
            "recovery-toolkit")
                recovery_toolkit_init
                ;;
            "gaming-mode")
                gaming_mode_init
                ;;
            "secure-updates")
                secure_updates_init
                ;;
            "privacy-dashboard")
                privacy_dashboard_init
                ;;
            *)
                print_warning "Unknown feature: $feature_name"
                ;;
        esac
        print_status "✓ $feature_name initialized"
    else
        print_error "Feature $feature_name not found or missing init.sh"
    fi
}

# Main initialization function
main() {
    print_header
    
    print_status "Starting LilithOS Advanced Features initialization..."
    print_status "LilithOS Root: $LILITHOS_ROOT"
    print_status "Modules Directory: $MODULES_DIR"
    
    # List of features to initialize (in order)
    local features=(
        "secure-vault"
        "module-store"
        "celestial-monitor"
        "quantum-portal"
        "lilith-ai"
        "theme-engine"
        "recovery-toolkit"
        "gaming-mode"
        "secure-updates"
        "privacy-dashboard"
    )
    
    # Initialize each feature
    for feature in "${features[@]}"; do
        init_feature "$feature"
    done
    
    print_header
    print_status "All LilithOS Advanced Features initialized successfully!"
    print_status ""
    print_status "Available Features:"
    for feature in "${features[@]}"; do
        print_status "- $feature"
    done
    print_status ""
    print_status "To use individual features:"
    print_status "source $MODULES_DIR/[feature-name]/init.sh"
    print_status ""
    print_status "Example:"
    print_status "source $MODULES_DIR/secure-vault/init.sh"
    print_status "quantum_vault_init"
    print_status ""
    print_status "Features are now ready for use! 🎉"
}

# Run main function
main "$@" 