#!/bin/bash

# 🔐 Scrypt Mining Framework - Complete Startup Script
# Advanced Scrypt Cryptocurrency Mining Framework
# 
# @author M-K-World-Wide Scrypt Team
# @version 1.0.0
# @license MIT

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
FRONTEND_PORT=3000
BACKEND_PORT=3001
FRONTEND_URL="http://localhost:${FRONTEND_PORT}"
BACKEND_URL="http://localhost:${BACKEND_PORT}"

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Check if running on macOS
check_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log "✅ macOS detected - proceeding with setup"
    else
        warn "This script is optimized for macOS. Other systems may require manual adjustments."
    fi
}

# Check dependencies
check_dependencies() {
    log "🔍 Checking system dependencies..."
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        error "Node.js is not installed. Please install Node.js 18+ first."
        exit 1
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        error "npm is not installed. Please install npm first."
        exit 1
    fi
    
    # Check Node.js version
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        error "Node.js version 18+ is required. Current version: $(node -v)"
        exit 1
    fi
    
    log "✅ Node.js $(node -v) and npm $(npm -v) are available"
}

# Kill existing processes
kill_existing_processes() {
    log "🛑 Stopping existing processes..."
    
    # Kill Vite dev server
    pkill -f "vite" || true
    sleep 2
    
    # Kill mining controller
    pkill -f "mining-controller.js" || true
    sleep 2
    
    # Kill any processes on our ports
    lsof -ti:${FRONTEND_PORT} | xargs kill -9 2>/dev/null || true
    lsof -ti:${BACKEND_PORT} | xargs kill -9 2>/dev/null || true
    
    log "✅ Existing processes stopped"
}

# Install dependencies
install_dependencies() {
    log "📦 Installing/updating dependencies..."
    
    if [ ! -d "node_modules" ]; then
        log "Installing frontend dependencies..."
        npm install
    else
        log "Frontend dependencies already installed"
    fi
    
    if [ ! -d "backend/node_modules" ]; then
        log "Installing backend dependencies..."
        cd backend && npm install && cd ..
    else
        log "Backend dependencies already installed"
    fi
    
    log "✅ Dependencies installed"
}

# Start backend mining controller
start_backend() {
    log "🚀 Starting backend mining controller..."
    
    cd backend
    
    # Start mining controller in background
    nohup node mining-controller.js > ../mining-controller.log 2>&1 &
    BACKEND_PID=$!
    echo $BACKEND_PID > ../backend.pid
    
    cd ..
    
    # Wait for backend to start
    log "⏳ Waiting for backend to start..."
    for i in {1..30}; do
        if curl -s "${BACKEND_URL}/api/health" > /dev/null 2>&1; then
            log "✅ Backend mining controller started successfully (PID: $BACKEND_PID)"
            return 0
        fi
        sleep 1
    done
    
    error "Backend failed to start within 30 seconds"
    return 1
}

# Start frontend development server
start_frontend() {
    log "🌐 Starting frontend development server..."
    
    # Start Vite dev server in background
    nohup npm run dev > frontend.log 2>&1 &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > frontend.pid
    
    # Wait for frontend to start
    log "⏳ Waiting for frontend to start..."
    for i in {1..30}; do
        if curl -s "${FRONTEND_URL}" > /dev/null 2>&1; then
            log "✅ Frontend development server started successfully (PID: $FRONTEND_PID)"
            return 0
        fi
        sleep 1
    done
    
    error "Frontend failed to start within 30 seconds"
    return 1
}

# Health check
health_check() {
    log "🏥 Performing health check..."
    
    # Check backend
    if curl -s "${BACKEND_URL}/api/health" > /dev/null 2>&1; then
        log "✅ Backend is healthy"
    else
        error "❌ Backend health check failed"
        return 1
    fi
    
    # Check frontend
    if curl -s "${FRONTEND_URL}" > /dev/null 2>&1; then
        log "✅ Frontend is healthy"
    else
        error "❌ Frontend health check failed"
        return 1
    fi
    
    log "✅ All services are healthy"
    return 0
}

# Display status
show_status() {
    log "📊 Current Status:"
    
    # Check backend
    if [ -f "backend.pid" ] && kill -0 $(cat backend.pid) 2>/dev/null; then
        echo -e "  ${GREEN}✅ Backend (PID: $(cat backend.pid))${NC}"
    else
        echo -e "  ${RED}❌ Backend not running${NC}"
    fi
    
    # Check frontend
    if [ -f "frontend.pid" ] && kill -0 $(cat frontend.pid) 2>/dev/null; then
        echo -e "  ${GREEN}✅ Frontend (PID: $(cat frontend.pid))${NC}"
    else
        echo -e "  ${RED}❌ Frontend not running${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}🌐 Frontend URL: ${FRONTEND_URL}${NC}"
    echo -e "${CYAN}🔧 Backend URL: ${BACKEND_URL}${NC}"
    echo -e "${CYAN}📊 Health Check: ${BACKEND_URL}/api/health${NC}"
}

# Stop all services
stop_services() {
    log "🛑 Stopping all services..."
    
    # Stop frontend
    if [ -f "frontend.pid" ]; then
        kill $(cat frontend.pid) 2>/dev/null || true
        rm -f frontend.pid
        log "✅ Frontend stopped"
    fi
    
    # Stop backend
    if [ -f "backend.pid" ]; then
        kill $(cat backend.pid) 2>/dev/null || true
        rm -f backend.pid
        log "✅ Backend stopped"
    fi
    
    # Kill any remaining processes
    pkill -f "vite" || true
    pkill -f "mining-controller.js" || true
    
    log "✅ All services stopped"
}

# Show logs
show_logs() {
    log "📋 Recent logs:"
    echo ""
    echo -e "${YELLOW}=== Backend Logs ===${NC}"
    tail -20 mining-controller.log 2>/dev/null || echo "No backend logs found"
    echo ""
    echo -e "${YELLOW}=== Frontend Logs ===${NC}"
    tail -20 frontend.log 2>/dev/null || echo "No frontend logs found"
}

# Main function
main() {
    case "${1:-start}" in
        "start")
            log "🔐 Starting Scrypt Mining Framework..."
            check_os
            check_dependencies
            kill_existing_processes
            install_dependencies
            start_backend
            start_frontend
            sleep 3
            health_check
            show_status
            log "🎉 Scrypt Mining Framework is ready!"
            log "🌐 Open your browser to: ${FRONTEND_URL}"
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            stop_services
            sleep 2
            $0 start
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "health")
            health_check
            ;;
        "setup")
            log "🔧 Setting up Scrypt Mining Framework..."
            check_os
            check_dependencies
            install_dependencies
            log "✅ Setup completed"
            ;;
        *)
            echo "Usage: $0 {start|stop|restart|status|logs|health|setup}"
            echo ""
            echo "Commands:"
            echo "  start   - Start the mining framework (default)"
            echo "  stop    - Stop all services"
            echo "  restart - Restart all services"
            echo "  status  - Show current status"
            echo "  logs    - Show recent logs"
            echo "  health  - Perform health check"
            echo "  setup   - Initial setup"
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 