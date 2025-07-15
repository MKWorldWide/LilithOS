#!/bin/bash

# LilithOS Voice Daemon Build Script
# ===================================
# Quantum-detailed build automation for voice synthesis system

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Build configuration
DAEMON_NAME="lilith_voice"
VERSION="1.0.0"
BUILD_DIR="build"
DIST_DIR="dist"
LOG_FILE="build.log"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[BUILD]${NC} $1"
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

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    print_status "$1"
}

# Function to check prerequisites
check_prerequisites() {
    log_message "Checking build prerequisites..."
    
    # Check Python version
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is required but not installed"
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    print_info "Python version: $PYTHON_VERSION"
    
    # Check pip
    if ! command -v pip3 &> /dev/null; then
        print_error "pip3 is required but not installed"
        exit 1
    fi
    
    # Check system dependencies
    local missing_deps=()
    
    # Check for espeak-ng
    if ! command -v espeak-ng &> /dev/null; then
        missing_deps+=("espeak-ng")
    fi
    
    # Check for portaudio (for pyaudio)
    if ! pkg-config --exists portaudio-2.0; then
        missing_deps+=("portaudio19-dev")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_warning "Missing system dependencies: ${missing_deps[*]}"
        print_info "Install with: sudo apt-get install ${missing_deps[*]}"
        print_info "Or on macOS: brew install espeak portaudio"
    fi
    
    print_success "Prerequisites check completed"
}

# Function to create build directories
create_directories() {
    log_message "Creating build directories..."
    
    mkdir -p "$BUILD_DIR"
    mkdir -p "$DIST_DIR"
    mkdir -p "$BUILD_DIR/tests"
    mkdir -p "$BUILD_DIR/config"
    mkdir -p "$BUILD_DIR/logs"
    
    print_success "Build directories created"
}

# Function to install Python dependencies
install_dependencies() {
    log_message "Installing Python dependencies..."
    
    # Upgrade pip
    python3 -m pip install --upgrade pip
    
    # Install core dependencies
    print_info "Installing core dependencies..."
    pip3 install -r requirements.txt
    
    # Install optional dependencies for testing
    print_info "Installing test dependencies..."
    pip3 install pytest pytest-asyncio pytest-cov black flake8
    
    # Verify installations
    print_info "Verifying installations..."
    python3 -c "import pyttsx3; print('pyttsx3: OK')"
    python3 -c "import gtts; print('gTTS: OK')"
    python3 -c "import pyaudio; print('pyaudio: OK')"
    python3 -c "import yaml; print('pyyaml: OK')"
    
    print_success "Dependencies installed successfully"
}

# Function to run code quality checks
run_quality_checks() {
    log_message "Running code quality checks..."
    
    # Run black code formatter
    print_info "Running black code formatter..."
    if command -v black &> /dev/null; then
        black --check --diff lilith_voice_daemon.py voice_manager.py whisperer_integration.py
        print_success "Black formatting check passed"
    else
        print_warning "Black not installed, skipping formatting check"
    fi
    
    # Run flake8 linting
    print_info "Running flake8 linting..."
    if command -v flake8 &> /dev/null; then
        flake8 lilith_voice_daemon.py voice_manager.py whisperer_integration.py --max-line-length=120
        print_success "Flake8 linting passed"
    else
        print_warning "Flake8 not installed, skipping linting check"
    fi
    
    # Run type checking (if mypy is available)
    print_info "Running type checking..."
    if command -v mypy &> /dev/null; then
        mypy lilith_voice_daemon.py voice_manager.py whisperer_integration.py --ignore-missing-imports
        print_success "Type checking passed"
    else
        print_warning "mypy not installed, skipping type checking"
    fi
}

# Function to run tests
run_tests() {
    log_message "Running tests..."
    
    # Create test directory if it doesn't exist
    mkdir -p tests
    
    # Create basic test file if it doesn't exist
    if [ ! -f "tests/test_voice_daemon.py" ]; then
        cat > tests/test_voice_daemon.py << 'EOF'
#!/usr/bin/env python3
"""
Basic tests for LilithOS Voice Daemon
"""

import pytest
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def test_import_voice_daemon():
    """Test that voice daemon can be imported."""
    try:
        from lilith_voice_daemon import LilithVoiceDaemon
        assert True
    except ImportError as e:
        pytest.fail(f"Failed to import LilithVoiceDaemon: {e}")

def test_import_voice_manager():
    """Test that voice manager can be imported."""
    try:
        from voice_manager import VoiceManager
        assert True
    except ImportError as e:
        pytest.fail(f"Failed to import VoiceManager: {e}")

def test_import_whisperer_integration():
    """Test that whisperer integration can be imported."""
    try:
        from whisperer_integration import WhispererIntegration
        assert True
    except ImportError as e:
        pytest.fail(f"Failed to import WhispererIntegration: {e}")

def test_voice_daemon_initialization():
    """Test voice daemon initialization."""
    try:
        from lilith_voice_daemon import LilithVoiceDaemon
        daemon = LilithVoiceDaemon()
        assert daemon is not None
        assert hasattr(daemon, 'running')
        assert hasattr(daemon, 'audio_queue')
    except Exception as e:
        pytest.fail(f"Voice daemon initialization failed: {e}")

def test_voice_manager_initialization():
    """Test voice manager initialization."""
    try:
        from voice_manager import VoiceManager
        vm = VoiceManager()
        assert vm is not None
        assert hasattr(vm, 'voice_profiles')
        assert hasattr(vm, 'is_initialized')
    except Exception as e:
        pytest.fail(f"Voice manager initialization failed: {e}")

def test_text_sanitization():
    """Test text sanitization functionality."""
    try:
        from voice_manager import VoiceManager
        vm = VoiceManager()
        
        # Test normal text
        result = vm.sanitize_text("Hello, world!")
        assert result == "Hello, world!"
        
        # Test text with dangerous characters
        result = vm.sanitize_text("Hello<script>alert('xss')</script>")
        assert "<script>" not in result
        assert "alert" not in result
        
        # Test empty text
        result = vm.sanitize_text("")
        assert result == ""
        
        # Test None
        result = vm.sanitize_text(None)
        assert result == ""
        
    except Exception as e:
        pytest.fail(f"Text sanitization test failed: {e}")

if __name__ == "__main__":
    pytest.main([__file__])
EOF
    fi
    
    # Run tests
    print_info "Running unit tests..."
    python3 -m pytest tests/ -v --tb=short
    
    print_success "Tests completed successfully"
}

# Function to create distribution package
create_distribution() {
    log_message "Creating distribution package..."
    
    # Create distribution directory
    DIST_NAME="${DAEMON_NAME}-${VERSION}"
    DIST_PATH="$DIST_DIR/$DIST_NAME"
    
    mkdir -p "$DIST_PATH"
    
    # Copy source files
    cp lilith_voice_daemon.py "$DIST_PATH/"
    cp voice_manager.py "$DIST_PATH/"
    cp whisperer_integration.py "$DIST_PATH/"
    
    # Copy configuration files
    cp voice_config.yaml "$DIST_PATH/"
    cp phrase_scripts.json "$DIST_PATH/"
    cp requirements.txt "$DIST_PATH/"
    
    # Copy documentation
    cp README.md "$DIST_PATH/"
    
    # Create installation script
    cat > "$DIST_PATH/install.sh" << 'EOF'
#!/bin/bash

# LilithOS Voice Daemon Installation Script

set -e

echo "Installing LilithOS Voice Daemon..."

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is required"
    exit 1
fi

# Install dependencies
echo "Installing dependencies..."
pip3 install -r requirements.txt

# Set permissions
chmod +x lilith_voice_daemon.py

echo "Installation completed successfully!"
echo "Run with: python3 lilith_voice_daemon.py"
EOF
    
    chmod +x "$DIST_PATH/install.sh"
    
    # Create systemd service file
    cat > "$DIST_PATH/lilith-voice.service" << EOF
[Unit]
Description=LilithOS Voice Daemon
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(pwd)
ExecStart=/usr/bin/python3 $(pwd)/lilith_voice_daemon.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Create startup script
    cat > "$DIST_PATH/start.sh" << 'EOF'
#!/bin/bash

# Start LilithOS Voice Daemon

echo "Starting LilithOS Voice Daemon..."

# Check if daemon is already running
if pgrep -f "lilith_voice_daemon.py" > /dev/null; then
    echo "Voice daemon is already running"
    exit 1
fi

# Start daemon
python3 lilith_voice_daemon.py &
DAEMON_PID=$!

echo "Voice daemon started with PID: $DAEMON_PID"
echo "Log file: lilith_voice.log"
EOF
    
    chmod +x "$DIST_PATH/start.sh"
    
    # Create stop script
    cat > "$DIST_PATH/stop.sh" << 'EOF'
#!/bin/bash

# Stop LilithOS Voice Daemon

echo "Stopping LilithOS Voice Daemon..."

# Find and kill daemon process
DAEMON_PID=$(pgrep -f "lilith_voice_daemon.py")

if [ -n "$DAEMON_PID" ]; then
    kill $DAEMON_PID
    echo "Voice daemon stopped (PID: $DAEMON_PID)"
else
    echo "Voice daemon is not running"
fi
EOF
    
    chmod +x "$DIST_PATH/stop.sh"
    
    # Create archive
    cd "$DIST_DIR"
    tar -czf "${DIST_NAME}.tar.gz" "$DIST_NAME"
    cd ..
    
    print_success "Distribution package created: $DIST_DIR/${DIST_NAME}.tar.gz"
}

# Function to run integration tests
run_integration_tests() {
    log_message "Running integration tests..."
    
    # Test TTS engine initialization
    print_info "Testing TTS engine initialization..."
    python3 -c "
from voice_manager import VoiceManager
vm = VoiceManager()
print('Voice manager initialized successfully')
print(f'Available profiles: {vm.get_voice_profiles()}')
print(f'Available devices: {len(vm.get_audio_devices())}')
"
    
    # Test phrase script loading
    print_info "Testing phrase script loading..."
    python3 -c "
import json
with open('phrase_scripts.json', 'r') as f:
    scripts = json.load(f)
print(f'Loaded {len(scripts)} phrase scripts')
for script in scripts[:3]:
    print(f'  - {script[\"trigger\"]}: {script[\"response\"][:50]}...')
"
    
    print_success "Integration tests completed"
}

# Function to display build summary
display_summary() {
    log_message "Build completed successfully!"
    
    echo
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    BUILD SUMMARY                             ║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  Daemon: ${CYAN}${DAEMON_NAME}${NC}${GREEN}                                    ║${NC}"
    echo -e "${GREEN}║  Version: ${CYAN}${VERSION}${NC}${GREEN}                                        ║${NC}"
    echo -e "${GREEN}║  Build Directory: ${CYAN}${BUILD_DIR}${NC}${GREEN}                              ║${NC}"
    echo -e "${GREEN}║  Distribution: ${CYAN}${DIST_DIR}/${DAEMON_NAME}-${VERSION}.tar.gz${NC}${GREEN}  ║${NC}"
    echo -e "${GREEN}║  Log File: ${CYAN}${LOG_FILE}${NC}${GREEN}                                      ║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  Next Steps:                                               ║${NC}"
    echo -e "${GREEN}║  1. Extract: tar -xzf ${DIST_DIR}/${DAEMON_NAME}-${VERSION}.tar.gz${NC}${GREEN} ║${NC}"
    echo -e "${GREEN}║  2. Install: cd ${DAEMON_NAME}-${VERSION} && ./install.sh${NC}${GREEN}        ║${NC}"
    echo -e "${GREEN}║  3. Start: ./start.sh${NC}${GREEN}                                            ║${NC}"
    echo -e "${GREEN}║  4. Test: python3 lilith_voice_daemon.py${NC}${GREEN}                        ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Main build function
main() {
    print_info "Starting LilithOS Voice Daemon build process..."
    print_info "Version: $VERSION"
    print_info "Build directory: $BUILD_DIR"
    
    # Initialize log file
    echo "LilithOS Voice Daemon Build Log" > "$LOG_FILE"
    echo "Version: $VERSION" >> "$LOG_FILE"
    echo "Build started: $(date)" >> "$LOG_FILE"
    echo "========================================" >> "$LOG_FILE"
    
    # Run build steps
    check_prerequisites
    create_directories
    install_dependencies
    run_quality_checks
    run_tests
    run_integration_tests
    create_distribution
    
    # Display summary
    display_summary
    
    echo "Build completed: $(date)" >> "$LOG_FILE"
}

# Handle command line arguments
case "${1:-}" in
    "clean")
        print_info "Cleaning build artifacts..."
        rm -rf "$BUILD_DIR" "$DIST_DIR" "$LOG_FILE"
        print_success "Clean completed"
        ;;
    "test")
        print_info "Running tests only..."
        run_tests
        run_integration_tests
        ;;
    "package")
        print_info "Creating package only..."
        create_distribution
        ;;
    "help"|"-h"|"--help")
        echo "LilithOS Voice Daemon Build Script"
        echo
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  (no args)  - Full build process"
        echo "  clean      - Clean build artifacts"
        echo "  test       - Run tests only"
        echo "  package    - Create distribution package only"
        echo "  help       - Show this help message"
        ;;
    *)
        main
        ;;
esac 