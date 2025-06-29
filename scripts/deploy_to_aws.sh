#!/bin/bash

# 🌑 LilithOS AWS Deployment Script
# Deploy LilithOS to AWS EC2 instance

set -e

# Configuration
INSTANCE_IP="54.165.89.110"
KEY_FILE="lilithos-key.pem"
REMOTE_USER="ubuntu"
REMOTE_DIR="/home/ubuntu/LilithOS"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Test SSH connection
test_ssh() {
    log "🔍 Testing SSH connection to $INSTANCE_IP..."
    
    if ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$REMOTE_USER@$INSTANCE_IP" "echo 'SSH connection successful!'" &> /dev/null; then
        log "✅ SSH connection successful!"
        return 0
    else
        error "❌ SSH connection failed! Please ensure the instance is ready and try again."
    fi
}

# Deploy LilithOS
deploy_lilithos() {
    log "🚀 Deploying LilithOS to AWS EC2..."
    
    # Test SSH first
    test_ssh
    
    # Create remote directory
    log "📁 Creating remote directory..."
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$REMOTE_USER@$INSTANCE_IP" "mkdir -p $REMOTE_DIR"
    
    # Copy LilithOS files
    log "📦 Copying LilithOS files to AWS instance..."
    rsync -avz -e "ssh -i $KEY_FILE -o StrictHostKeyChecking=no" \
        --exclude='.git' \
        --exclude='*.log' \
        --exclude='.DS_Store' \
        --exclude='node_modules' \
        --exclude='__pycache__' \
        ./ "$REMOTE_USER@$INSTANCE_IP:$REMOTE_DIR/"
    
    # Set proper permissions
    log "🔐 Setting proper permissions..."
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$REMOTE_USER@$INSTANCE_IP" "chmod +x $REMOTE_DIR/scripts/*.sh"
    
    # Install dependencies
    log "📦 Installing dependencies..."
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$REMOTE_USER@$INSTANCE_IP" "cd $REMOTE_DIR && sudo apt-get update && sudo apt-get install -y git curl wget build-essential python3 python3-pip nodejs npm docker.io docker-compose nginx ufw fail2ban"
    
    # Initialize LilithOS
    log "⚙️ Initializing LilithOS..."
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$REMOTE_USER@$INSTANCE_IP" "cd $REMOTE_DIR && ./scripts/install.sh"
    
    # Initialize features
    log "🔧 Initializing LilithOS features..."
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$REMOTE_USER@$INSTANCE_IP" "cd $REMOTE_DIR && ./scripts/initialize_features.sh"
    
    # Set up cross-platform compatibility
    log "🌐 Setting up cross-platform compatibility..."
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$REMOTE_USER@$INSTANCE_IP" "cd $REMOTE_DIR && ./modules/features/cross-platform-compatibility/init.sh"
    
    # Configure glass dashboard
    log "🎨 Configuring glass dashboard..."
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$REMOTE_USER@$INSTANCE_IP" "cd $REMOTE_DIR && ./scripts/glass_dashboard.sh"
    
    # Set up web server
    log "🌐 Setting up web server..."
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$REMOTE_USER@$INSTANCE_IP" "cd $REMOTE_DIR && sudo cp scripts/nginx_lilithos.conf /etc/nginx/sites-available/lilithos && sudo ln -sf /etc/nginx/sites-available/lilithos /etc/nginx/sites-enabled/ && sudo systemctl reload nginx"
    
    log "✅ LilithOS deployment completed!"
}

# Display connection information
display_info() {
    log "📊 LilithOS AWS EC2 Deployment Complete!"
    echo "=========================================="
    echo "Instance IP: $INSTANCE_IP"
    echo "SSH Access: ssh -i $KEY_FILE $REMOTE_USER@$INSTANCE_IP"
    echo ""
    echo "🌐 Web Access:"
    echo "- HTTP: http://$INSTANCE_IP"
    echo "- LilithOS Dashboard: http://$INSTANCE_IP:8080"
    echo "- Glass Dashboard: http://$INSTANCE_IP/glass"
    echo ""
    echo "📱 Remote Access:"
    echo "- VNC: $INSTANCE_IP:5900"
    echo ""
    echo "🔧 Management:"
    echo "- SSH into instance: ssh -i $KEY_FILE $REMOTE_USER@$INSTANCE_IP"
    echo "- View logs: tail -f /var/log/lilithos.log"
    echo "- Restart services: sudo systemctl restart lilithos"
    echo ""
    echo "🌑 LilithOS - Where Technology Meets the Ethereal"
}

# Main execution
main() {
    log "🌑 LilithOS AWS EC2 Deployment Script"
    log "====================================="
    
    # Check if key file exists
    if [ ! -f "$KEY_FILE" ]; then
        error "Key file $KEY_FILE not found!"
    fi
    
    # Set proper permissions
    chmod 400 "$KEY_FILE"
    
    # Deploy LilithOS
    deploy_lilithos
    
    # Display information
    display_info
    
    log "🎉 Deployment completed successfully!"
}

# Execute main function
main "$@" 