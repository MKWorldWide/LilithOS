#!/bin/bash

# 🔐 Scrypt Mining Framework - Miner Setup Script
# Downloads and configures mining binaries for different platforms

set -e

echo "🔐 Setting up Scrypt Mining Framework miners..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

# Create miner directory
MINER_DIR="$(dirname "$0")/miner"
mkdir -p "$MINER_DIR"
cd "$MINER_DIR"

print_status "Created miner directory: $MINER_DIR"

# Detect platform
PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

print_status "Detected platform: $PLATFORM ($ARCH)"

# Function to download file
download_file() {
    local url=$1
    local filename=$2
    
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$filename" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$filename" "$url"
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
}

# Function to make binary executable
make_executable() {
    local filename=$1
    chmod +x "$filename"
    print_success "Made $filename executable"
}

# Download mining binaries based on platform
case $PLATFORM in
    "darwin")
        print_status "Setting up miners for macOS..."
        
        # cpuminer-multi for macOS
        if [ ! -f "cpuminer-multi-mac" ]; then
            print_status "Downloading cpuminer-multi for macOS..."
            download_file "https://github.com/tpruvot/cpuminer-multi/releases/download/v1.3.5/cpuminer-multi-mac" "cpuminer-multi-mac"
            make_executable "cpuminer-multi-mac"
        else
            print_warning "cpuminer-multi-mac already exists"
        fi
        
        # Alternative: XMRig for CPU mining
        if [ ! -f "xmrig-mac" ]; then
            print_status "Downloading XMRig for macOS..."
            download_file "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-macos-x64.tar.gz" "xmrig-mac.tar.gz"
            tar -xzf "xmrig-mac.tar.gz"
            mv xmrig-6.21.0/xmrig "xmrig-mac"
            rm -rf xmrig-6.21.0 "xmrig-mac.tar.gz"
            make_executable "xmrig-mac"
        fi
        ;;
        
    "linux")
        print_status "Setting up miners for Linux..."
        
        # cpuminer-multi for Linux
        if [ ! -f "cpuminer-multi-linux" ]; then
            print_status "Downloading cpuminer-multi for Linux..."
            download_file "https://github.com/tpruvot/cpuminer-multi/releases/download/v1.3.5/cpuminer-multi-linux" "cpuminer-multi-linux"
            make_executable "cpuminer-multi-linux"
        else
            print_warning "cpuminer-multi-linux already exists"
        fi
        
        # XMRig for Linux
        if [ ! -f "xmrig-linux" ]; then
            print_status "Downloading XMRig for Linux..."
            download_file "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-linux-x64.tar.gz" "xmrig-linux.tar.gz"
            tar -xzf "xmrig-linux.tar.gz"
            mv xmrig-6.21.0/xmrig "xmrig-linux"
            rm -rf xmrig-6.21.0 "xmrig-linux.tar.gz"
            make_executable "xmrig-linux"
        fi
        
        # Install dependencies
        print_status "Installing Linux dependencies..."
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update
            sudo apt-get install -y build-essential libssl-dev libgmp-dev
        elif command -v yum >/dev/null 2>&1; then
            sudo yum groupinstall -y "Development Tools"
            sudo yum install -y openssl-devel gmp-devel
        fi
        ;;
        
    "mingw64_nt"|"msys_nt"|"cygwin_nt")
        print_status "Setting up miners for Windows..."
        
        # cpuminer-multi for Windows
        if [ ! -f "cpuminer-multi-win.exe" ]; then
            print_status "Downloading cpuminer-multi for Windows..."
            download_file "https://github.com/tpruvot/cpuminer-multi/releases/download/v1.3.5/cpuminer-multi-win64.zip" "cpuminer-multi-win64.zip"
            unzip -o "cpuminer-multi-win64.zip"
            mv cpuminer-multi-win64/cpuminer-multi.exe "cpuminer-multi-win.exe"
            rm -rf cpuminer-multi-win64 "cpuminer-multi-win64.zip"
        else
            print_warning "cpuminer-multi-win.exe already exists"
        fi
        
        # XMRig for Windows
        if [ ! -f "xmrig-win.exe" ]; then
            print_status "Downloading XMRig for Windows..."
            download_file "https://github.com/xmrig/xmrig/releases/download/v6.21.0/xmrig-6.21.0-msvc-win64.zip" "xmrig-win.zip"
            unzip -o "xmrig-win.zip"
            mv xmrig-6.21.0/xmrig.exe "xmrig-win.exe"
            rm -rf xmrig-6.21.0 "xmrig-win.zip"
        fi
        ;;
        
    *)
        print_error "Unsupported platform: $PLATFORM"
        exit 1
        ;;
esac

# Create configuration files
print_status "Creating configuration files..."

# Create pool configuration
cat > pools.json << EOF
{
  "pools": {
    "prohashing": {
      "name": "ProHashing Pool",
      "url": "stratum+tcp://us.mining.prohashing.com:3333",
      "algorithm": "scrypt",
      "description": "Professional multi-coin mining pool (Recommended)"
    },
    "litecoin": {
      "name": "Litecoin Pool",
      "url": "stratum+tcp://litecoinpool.org:3333",
      "algorithm": "scrypt",
      "description": "Popular Litecoin mining pool"
    },
    "dogecoin": {
      "name": "Dogecoin Pool",
      "url": "stratum+tcp://prohashing.com:3333",
      "algorithm": "scrypt",
      "description": "Multi-coin mining pool"
    },
    "aikapool": {
      "name": "Aikapool",
      "url": "stratum+tcp://aikapool.com:3333",
      "algorithm": "scrypt",
      "description": "Alternative Scrypt pool"
    }
  }
}
EOF

# Create miner configuration
cat > miner-config.json << EOF
{
  "defaults": {
    "algorithm": "scrypt",
    "threads": 4,
    "intensity": 8,
    "worker_name": "worker1"
  },
  "algorithms": {
    "scrypt": {
      "miner": "cpuminer-multi",
      "supported_pools": ["litecoin", "dogecoin", "aikapool"],
      "description": "Scrypt algorithm for Litecoin/Dogecoin"
    },
    "randomx": {
      "miner": "xmrig",
      "supported_pools": ["monero"],
      "description": "RandomX algorithm for Monero"
    }
  }
}
EOF

# Create startup script
cat > start-mining.sh << 'EOF'
#!/bin/bash

# Scrypt Mining Framework - Quick Start Script

echo "🔐 Starting Scrypt Mining Framework..."

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found. Please copy .env.example to .env and configure your settings."
    exit 1
fi

# Start the mining controller
echo "🚀 Starting mining controller..."
node mining-controller.js
EOF

chmod +x start-mining.sh

# Create test script
cat > test-mining.sh << 'EOF'
#!/bin/bash

# Scrypt Mining Framework - Test Script

echo "🧪 Testing mining setup..."

# Test miner binaries
echo "Testing miner binaries..."

if [ -f "cpuminer-multi-mac" ] || [ -f "cpuminer-multi-linux" ] || [ -f "cpuminer-multi-win.exe" ]; then
    echo "✅ cpuminer-multi found"
else
    echo "❌ cpuminer-multi not found"
fi

if [ -f "xmrig-mac" ] || [ -f "xmrig-linux" ] || [ -f "xmrig-win.exe" ]; then
    echo "✅ XMRig found"
else
    echo "❌ XMRig not found"
fi

# Test configuration files
echo "Testing configuration files..."

if [ -f "pools.json" ]; then
    echo "✅ pools.json found"
else
    echo "❌ pools.json not found"
fi

if [ -f "miner-config.json" ]; then
    echo "✅ miner-config.json found"
else
    echo "❌ miner-config.json not found"
fi

echo "🧪 Test completed!"
EOF

chmod +x test-mining.sh

print_success "Mining setup completed successfully!"

# Display next steps
echo ""
echo "🎯 Next Steps:"
echo "1. Copy .env.example to .env and configure your wallet addresses"
echo "2. Run: ./test-mining.sh to verify the setup"
echo "3. Run: ./start-mining.sh to start the mining controller"
echo "4. Open the Scrypt Mining Framework UI to control mining operations"
echo ""
echo "📚 For more information, see the README.md file"
echo "🔐 Happy mining!" 