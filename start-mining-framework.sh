#!/bin/bash

# 🔐 Scrypt Mining Framework - Complete Startup Script
# Sets up and starts the entire Scrypt Mining Framework

set -e

echo "🔐 Starting Scrypt Mining Framework..."

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

print_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_warning "This script should not be run as root"
   exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if port is available
port_available() {
    ! nc -z localhost $1 2>/dev/null
}

# Function to wait for service
wait_for_service() {
    local url=$1
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for service at $url..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$url" >/dev/null 2>&1; then
            print_success "Service is ready!"
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts - Service not ready yet..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "Service failed to start within expected time"
    return 1
}

# Function to setup environment
setup_environment() {
    print_header "Setting up Environment"
    
    # Check Node.js
    if ! command_exists node; then
        print_error "Node.js is not installed. Please install Node.js 16+ first."
        exit 1
    fi
    
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 16 ]; then
        print_error "Node.js version 16+ is required. Current version: $(node -v)"
        exit 1
    fi
    
    print_success "Node.js version: $(node -v)"
    
    # Check npm
    if ! command_exists npm; then
        print_error "npm is not installed"
        exit 1
    fi
    
    print_success "npm version: $(npm -v)"
    
    # Check if backend directory exists
    if [ ! -d "backend" ]; then
        print_error "Backend directory not found. Please run this script from the project root."
        exit 1
    fi
    
    # Check if frontend directory exists
    if [ ! -d "src" ]; then
        print_error "Frontend source directory not found. Please run this script from the project root."
        exit 1
    fi
}

# Function to setup backend
setup_backend() {
    print_header "Setting up Backend Mining Controller"
    
    cd backend
    
    # Install dependencies
    print_status "Installing backend dependencies..."
    npm install
    
    # Setup miners
    print_status "Setting up mining binaries..."
    if [ -f "setup-miners.sh" ]; then
        chmod +x setup-miners.sh
        ./setup-miners.sh
    else
        print_warning "setup-miners.sh not found, skipping miner setup"
    fi
    
    # Create .env file if it doesn't exist
    if [ ! -f ".env" ]; then
        print_status "Creating .env file from template..."
        cp .env.example .env
        print_warning "Please edit backend/.env with your wallet addresses and pool settings"
    fi
    
    cd ..
}

# Function to setup frontend
setup_frontend() {
    print_header "Setting up Frontend"
    
    # Install dependencies
    print_status "Installing frontend dependencies..."
    npm install
    
    # Create .env file for frontend if it doesn't exist
    if [ ! -f ".env" ]; then
        print_status "Creating frontend .env file..."
        cat > .env << EOF
# Scrypt Mining Framework - Frontend Environment
REACT_APP_API_URL=http://localhost:3001/api
REACT_APP_WS_URL=ws://localhost:3002
REACT_APP_TITLE=Scrypt Mining Framework
EOF
    fi
}

# Function to start backend
start_backend() {
    print_header "Starting Backend Mining Controller"
    
    cd backend
    
    # Check if ports are available
    if ! port_available 3001; then
        print_error "Port 3001 is already in use. Please stop the service using that port."
        exit 1
    fi
    
    if ! port_available 3002; then
        print_error "Port 3002 is already in use. Please stop the service using that port."
        exit 1
    fi
    
    # Start the mining controller
    print_status "Starting mining controller on port 3001..."
    print_status "WebSocket server will run on port 3002..."
    
    # Start in background
    nohup node mining-controller.js > mining-controller.log 2>&1 &
    BACKEND_PID=$!
    
    # Wait for backend to start
    if wait_for_service "http://localhost:3001/api/health"; then
        print_success "Backend mining controller started successfully (PID: $BACKEND_PID)"
    else
        print_error "Failed to start backend mining controller"
        exit 1
    fi
    
    cd ..
}

# Function to start frontend
start_frontend() {
    print_header "Starting Frontend"
    
    # Check if port 3000 is available
    if ! port_available 3000; then
        print_error "Port 3000 is already in use. Please stop the service using that port."
        exit 1
    fi
    
    print_status "Starting frontend development server on port 3000..."
    
    # Start in background
    nohup npm start > frontend.log 2>&1 &
    FRONTEND_PID=$!
    
    # Wait for frontend to start
    if wait_for_service "http://localhost:3000"; then
        print_success "Frontend started successfully (PID: $FRONTEND_PID)"
    else
        print_error "Failed to start frontend"
        exit 1
    fi
}

# Function to show status
show_status() {
    print_header "Service Status"
    
    echo ""
    echo -e "${CYAN}Backend Mining Controller:${NC}"
    if curl -s "http://localhost:3001/api/health" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Running on http://localhost:3001${NC}"
        echo -e "  ${GREEN}✓ WebSocket on ws://localhost:3002${NC}"
    else
        echo -e "  ${RED}✗ Not running${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}Frontend:${NC}"
    if curl -s "http://localhost:3000" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Running on http://localhost:3000${NC}"
    else
        echo -e "  ${RED}✗ Not running${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}Mining Status:${NC}"
    if command_exists curl; then
        curl -s "http://localhost:3001/api/mining/status" | python3 -m json.tool 2>/dev/null || echo "  Unable to fetch mining status"
    fi
}

# Function to stop services
stop_services() {
    print_header "Stopping Services"
    
    # Stop backend
    if [ ! -z "$BACKEND_PID" ]; then
        print_status "Stopping backend (PID: $BACKEND_PID)..."
        kill $BACKEND_PID 2>/dev/null || true
    fi
    
    # Stop frontend
    if [ ! -z "$FRONTEND_PID" ]; then
        print_status "Stopping frontend (PID: $FRONTEND_PID)..."
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    
    # Kill any remaining processes
    pkill -f "mining-controller.js" 2>/dev/null || true
    pkill -f "npm start" 2>/dev/null || true
    
    print_success "Services stopped"
}

# Function to show help
show_help() {
    echo "🔐 Scrypt Mining Framework - Startup Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  start     Start the complete Scrypt Mining Framework"
    echo "  stop      Stop all running services"
    echo "  status    Show status of running services"
    echo "  setup     Setup environment and dependencies"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start    # Start the complete framework"
    echo "  $0 stop     # Stop all services"
    echo "  $0 status   # Check service status"
    echo ""
    echo "The framework includes:"
    echo "  - Backend mining controller (port 3001)"
    echo "  - WebSocket server (port 3002)"
    echo "  - Frontend UI (port 3000)"
    echo "  - Mining binaries and configuration"
}

# Main execution
case "${1:-start}" in
    "start")
        print_header "Starting Scrypt Mining Framework"
        setup_environment
        setup_backend
        setup_frontend
        start_backend
        start_frontend
        
        echo ""
        print_header "🎉 Scrypt Mining Framework Started Successfully!"
        echo ""
        echo -e "${GREEN}Frontend UI:${NC} http://localhost:3000"
        echo -e "${GREEN}Backend API:${NC} http://localhost:3001/api"
        echo -e "${GREEN}WebSocket:${NC} ws://localhost:3002"
        echo ""
        echo -e "${YELLOW}Next Steps:${NC}"
        echo "1. Open http://localhost:3000 in your browser"
        echo "2. Configure your wallet address in backend/.env"
        echo "3. Start your first mining operation"
        echo ""
        echo -e "${CYAN}To stop the framework:${NC} $0 stop"
        echo -e "${CYAN}To check status:${NC} $0 status"
        echo ""
        
        # Keep script running and handle signals
        trap stop_services EXIT INT TERM
        wait
        ;;
        
    "stop")
        stop_services
        ;;
        
    "status")
        show_status
        ;;
        
    "setup")
        print_header "Setting up Scrypt Mining Framework"
        setup_environment
        setup_backend
        setup_frontend
        print_success "Setup completed successfully!"
        ;;
        
    "help"|"-h"|"--help")
        show_help
        ;;
        
    *)
        print_error "Unknown option: $1"
        echo ""
        show_help
        exit 1
        ;;
esac 