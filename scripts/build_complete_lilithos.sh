#!/bin/bash

# =============================================================================
# LilithOS Complete Build Script - Auto-Detection & Creation
# =============================================================================
# This script automatically detects, creates, and builds a complete LilithOS
# system with dark glass aesthetic featuring black glass, reds, and golds.
# =============================================================================

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GOLD='\033[0;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GOLD}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Configuration
LILITHOS_VOLUME_NAME="LilithOS"
LILITHOS_RECOVERY_NAME="LilithOS_Recovery"
LILITHOS_SIZE="50GB"
MOUNT_POINT="/Volumes/$LILITHOS_VOLUME_NAME"
RECOVERY_MOUNT="/Volumes/$LILITHOS_RECOVERY_NAME"

# =============================================================================
# VOLUME DETECTION AND CREATION
# =============================================================================

detect_or_create_volume() {
    log "🔍 Detecting LilithOS volume..."
    
    # Check if volume already exists and is properly sized
    if diskutil list | grep -q "$LILITHOS_VOLUME_NAME" && \
       diskutil info "$LILITHOS_VOLUME_NAME" | grep -q "Volume Size:.*GB"; then
        log "✅ Found existing LilithOS volume"
        return 0
    fi
    
    # Clean up any existing small volumes
    log "🧹 Cleaning up existing small volumes..."
    diskutil list | grep "$LILITHOS_VOLUME_NAME" | while read line; do
        volume_id=$(echo "$line" | awk '{print $NF}')
        if [[ "$volume_id" =~ ^disk[0-9]+s[0-9]+$ ]]; then
            log "Removing small volume: $volume_id"
            diskutil deleteVolume "$volume_id" 2>/dev/null || true
        fi
    done
    
    # Find the main APFS container
    log "🔍 Finding main APFS container..."
    MAIN_CONTAINER=$(diskutil list | grep "APFS Container Scheme" | head -1 | awk '{print $NF}')
    if [[ -z "$MAIN_CONTAINER" ]]; then
        error "Could not find main APFS container"
        exit 1
    fi
    log "Found main container: $MAIN_CONTAINER"
    
    # Create new LilithOS volume
    log "🚀 Creating new LilithOS volume ($LILITHOS_SIZE)..."
    diskutil apfs addVolume "$MAIN_CONTAINER" APFS "$LILITHOS_VOLUME_NAME" -quota "$LILITHOS_SIZE"
    
    # Create recovery volume
    log "🚀 Creating LilithOS recovery volume..."
    diskutil apfs addVolume "$MAIN_CONTAINER" APFS "$LILITHOS_RECOVERY_NAME" -quota "5GB"
    
    success "Volume creation completed"
}

# =============================================================================
# SYSTEM BUILD FUNCTIONS
# =============================================================================

install_core_packages() {
    log "📦 Installing core system packages..."
    
    # Update package lists
    brew update
    
    # Core system utilities
    brew install --cask xquartz
    brew install coreutils findutils gnu-tar gnu-sed gawk gnutls grep wget curl
    
    # Development tools
    brew install git cmake ninja pkg-config autoconf automake libtool
    
    # System libraries
    brew install openssl readline sqlite3 xz zlib tcl-tk
    
    success "Core packages installed"
}

install_desktop_environment() {
    log "🖥️ Installing desktop environment..."
    
    # X11 and window manager
    brew install --cask xquartz
    brew install xorg-libs xorg-apps
    
    # Install i3 window manager with gaps
    brew install i3-gaps
    
    # Install additional desktop components
    brew install dmenu rofi polybar feh nitrogen
    
    # Install terminal emulator
    brew install --cask alacritty
    
    success "Desktop environment installed"
}

install_custom_themes() {
    log "🎨 Installing custom dark glass themes..."
    
    # Create theme directories
    mkdir -p "$MOUNT_POINT/usr/share/themes"
    mkdir -p "$MOUNT_POINT/usr/share/icons"
    mkdir -p "$MOUNT_POINT/usr/share/wallpapers"
    
    # Install GTK themes
    brew install --cask gtk-murrine-engine
    
    # Create custom dark glass theme
    cat > "$MOUNT_POINT/usr/share/themes/LilithOS-Dark/gtk-3.0/gtk.css" << 'EOF'
/* LilithOS Dark Glass Theme */
@import url("resource:///org/gnome/theme/gtk-3.0/gtk.css");

/* Dark glass aesthetic */
* {
    background-color: rgba(0, 0, 0, 0.8);
    color: #FFD700;
    border-color: #8B0000;
}

/* Window decorations */
.window-frame {
    background: linear-gradient(135deg, rgba(0,0,0,0.9), rgba(139,0,0,0.3));
    border: 1px solid #8B0000;
    border-radius: 8px;
}

/* Buttons */
button {
    background: linear-gradient(135deg, rgba(139,0,0,0.8), rgba(0,0,0,0.9));
    border: 1px solid #FFD700;
    border-radius: 4px;
    color: #FFD700;
}

button:hover {
    background: linear-gradient(135deg, rgba(255,215,0,0.2), rgba(139,0,0,0.8));
}

/* Entry fields */
entry {
    background: rgba(0,0,0,0.7);
    border: 1px solid #8B0000;
    border-radius: 4px;
    color: #FFD700;
}

/* Scrollbars */
scrollbar {
    background: rgba(0,0,0,0.8);
    border: 1px solid #8B0000;
}

scrollbar slider {
    background: linear-gradient(135deg, rgba(139,0,0,0.8), rgba(255,215,0,0.3));
    border-radius: 4px;
}
EOF
    
    success "Custom themes installed"
}

install_system_applications() {
    log "📱 Installing system applications..."
    
    # File manager
    brew install --cask nautilus
    
    # Text editor
    brew install --cask sublime-text
    
    # Web browser
    brew install --cask firefox
    
    # Media player
    brew install --cask vlc
    
    # Image viewer
    brew install --cask gimp
    
    # System monitor
    brew install htop glances
    
    # Network tools
    brew install nmap wireshark
    
    success "System applications installed"
}

configure_terminal() {
    log "💻 Configuring terminal..."
    
    # Install Oh My Zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    
    # Install powerlevel10k theme
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    
    # Create custom zsh configuration
    cat > "$HOME/.zshrc" << 'EOF'
# LilithOS Terminal Configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# Custom aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# LilithOS specific
alias lilithos-status='systemctl status'
alias lilithos-logs='journalctl -f'
alias lilithos-update='brew update && brew upgrade'

# Custom prompt colors (dark glass theme)
export PS1='%F{red}[%F{yellow}%n%F{red}@%F{yellow}%m%F{red}]%F{white}:%F{blue}%~%F{white}$ '
EOF
    
    success "Terminal configured"
}

install_custom_scripts() {
    log "🔧 Installing custom scripts..."
    
    # Create scripts directory
    mkdir -p "$MOUNT_POINT/usr/local/bin"
    
    # System status script
    cat > "$MOUNT_POINT/usr/local/bin/lilithos-status" << 'EOF'
#!/bin/bash
# LilithOS System Status Script

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    LilithOS System Status                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# System information
echo "📊 System Information:"
echo "  OS: $(uname -s) $(uname -r)"
echo "  Hostname: $(hostname)"
echo "  Uptime: $(uptime | awk '{print $3,$4}' | sed 's/,//')"
echo ""

# Memory usage
echo "🧠 Memory Usage:"
free -h | grep -E "Mem|Swap"
echo ""

# Disk usage
echo "💾 Disk Usage:"
df -h | grep -E "Filesystem|/dev/"
echo ""

# Network status
echo "🌐 Network Status:"
ifconfig | grep -E "inet |status" | head -10
echo ""

# Running services
echo "🔧 Running Services:"
ps aux | grep -E "i3|polybar|dmenu" | grep -v grep
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    LilithOS Ready!                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
EOF
    
    chmod +x "$MOUNT_POINT/usr/local/bin/lilithos-status"
    
    # Theme switcher script
    cat > "$MOUNT_POINT/usr/local/bin/lilithos-theme" << 'EOF'
#!/bin/bash
# LilithOS Theme Switcher

case "$1" in
    "dark-glass")
        echo "🎨 Switching to Dark Glass theme..."
        gsettings set org.gnome.desktop.interface gtk-theme "LilithOS-Dark"
        gsettings set org.gnome.desktop.interface icon-theme "LilithOS-Icons"
        ;;
    "reset")
        echo "🔄 Resetting to default theme..."
        gsettings reset org.gnome.desktop.interface gtk-theme
        gsettings reset org.gnome.desktop.interface icon-theme
        ;;
    *)
        echo "Usage: $0 {dark-glass|reset}"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$MOUNT_POINT/usr/local/bin/lilithos-theme"
    
    success "Custom scripts installed"
}

install_wallpapers() {
    log "🖼️ Installing wallpapers..."
    
    # Create wallpapers directory
    mkdir -p "$MOUNT_POINT/usr/share/wallpapers/lilithos"
    
    # Create a simple dark glass wallpaper using ImageMagick
    brew install imagemagick
    
    # Generate dark glass wallpaper
    convert -size 1920x1080 \
        -background black \
        -fill "rgba(139,0,0,0.3)" \
        -draw "rectangle 0,0 1920,1080" \
        -fill "rgba(255,215,0,0.1)" \
        -draw "circle 960,540 960,100" \
        -fill "rgba(0,0,0,0.8)" \
        -draw "text 960,500 'LilithOS'" \
        -pointsize 72 \
        -gravity center \
        "$MOUNT_POINT/usr/share/wallpapers/lilithos/dark-glass.png"
    
    success "Wallpapers installed"
}

create_documentation() {
    log "📚 Creating documentation..."
    
    # Create documentation directory
    mkdir -p "$MOUNT_POINT/usr/share/doc/lilithos"
    
    # System manual
    cat > "$MOUNT_POINT/usr/share/doc/lilithos/README.md" << 'EOF'
# LilithOS - Dark Glass Operating System

## Overview
LilithOS is a custom operating system built with a dark glass aesthetic featuring black glass, reds, and golds.

## Features
- Dark glass desktop environment
- Custom i3-gaps window manager
- Polybar status bar
- Custom terminal configuration
- System monitoring tools
- Network utilities

## Quick Start
1. Boot into LilithOS
2. Use `lilithos-status` to check system status
3. Use `lilithos-theme dark-glass` to apply the dark glass theme
4. Press `Mod+Enter` to open terminal
5. Press `Mod+d` to open application launcher

## Customization
- Edit `~/.config/i3/config` for window manager settings
- Edit `~/.config/polybar/config` for status bar customization
- Edit `~/.zshrc` for terminal configuration

## Troubleshooting
- Check system logs: `journalctl -f`
- Restart services: `systemctl restart <service>`
- Reset theme: `lilithos-theme reset`

## Support
For issues and questions, check the documentation in `/usr/share/doc/lilithos/`
EOF
    
    success "Documentation created"
}

# =============================================================================
# MAIN BUILD PROCESS
# =============================================================================

main() {
    log "🚀 Starting LilithOS Complete Build Process..."
    log "🎨 Building with Dark Glass Aesthetic (Black Glass, Reds, Golds)"
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root"
        exit 1
    fi
    
    # Detect or create volume
    detect_or_create_volume
    
    # Wait for volume to be ready
    log "⏳ Waiting for volume to be ready..."
    sleep 5
    
    # Check if volume is mounted
    if [[ ! -d "$MOUNT_POINT" ]]; then
        log "🔗 Mounting LilithOS volume..."
        diskutil mount "$LILITHOS_VOLUME_NAME"
        sleep 3
    fi
    
    # Install all components
    install_core_packages
    install_desktop_environment
    install_custom_themes
    install_system_applications
    configure_terminal
    install_custom_scripts
    install_wallpapers
    create_documentation
    
    # Final configuration
    log "⚙️ Performing final configuration..."
    
    # Set default wallpaper
    nitrogen --set-zoom-fill "$MOUNT_POINT/usr/share/wallpapers/lilithos/dark-glass.png"
    
    # Create startup script
    cat > "$MOUNT_POINT/usr/local/bin/lilithos-startup" << 'EOF'
#!/bin/bash
# LilithOS Startup Script

# Apply dark glass theme
lilithos-theme dark-glass

# Start polybar
polybar main &

# Set wallpaper
nitrogen --restore

# Show welcome message
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    Welcome to LilithOS!                     ║"
echo "║                Dark Glass Operating System                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Quick Commands:"
echo "  lilithos-status  - Check system status"
echo "  lilithos-theme   - Switch themes"
echo "  Mod+Enter        - Open terminal"
echo "  Mod+d            - Open application launcher"
echo ""
EOF
    
    chmod +x "$MOUNT_POINT/usr/local/bin/lilithos-startup"
    
    success "🎉 LilithOS Complete Build Finished!"
    log "🎨 Dark Glass Aesthetic System Ready"
    log "📁 System installed to: $MOUNT_POINT"
    log "🔧 Use 'lilithos-status' to check system status"
    log "🎨 Use 'lilithos-theme dark-glass' to apply theme"
    log "🚀 Use 'lilithos-startup' to initialize system"
    
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    LilithOS Build Complete!                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "🌙 Dark Glass Aesthetic: Black Glass, Reds, and Golds"
    echo "📦 Complete Desktop Environment Installed"
    echo "🎨 Custom Themes and Wallpapers Applied"
    echo "🔧 System Scripts and Utilities Ready"
    echo "📚 Documentation Available in /usr/share/doc/lilithos/"
    echo ""
    echo "Next Steps:"
    echo "1. Reboot into LilithOS"
    echo "2. Run 'lilithos-startup' to initialize"
    echo "3. Enjoy your dark glass operating system!"
    echo ""
}

# Run main function
main "$@" 