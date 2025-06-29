#!/bin/bash

# 🌑 LilithOS Simple AWS Deployment Script
# Deploy using AWS Systems Manager (no SSH required)

set -e

# Configuration
INSTANCE_ID="i-062e9938473b9782e"
REGION="us-east-1"

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

# Check if instance is running
check_instance() {
    log "🔍 Checking instance status..."
    
    # Simple check using AWS CLI
    if aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$REGION" --query 'Reservations[0].Instances[0].State.Name' --output text | grep -q "running"; then
        log "✅ Instance is running"
        return 0
    else
        error "❌ Instance is not running"
    fi
}

# Install SSM agent and dependencies
install_dependencies() {
    log "📦 Installing dependencies via AWS Systems Manager..."
    
    # Install basic packages
    aws ssm send-command \
        --instance-ids "$INSTANCE_ID" \
        --region "$REGION" \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=[
            "sudo apt-get update",
            "sudo apt-get install -y git curl wget build-essential python3 python3-pip nodejs npm docker.io docker-compose nginx ufw fail2ban",
            "sudo systemctl enable docker",
            "sudo systemctl start docker",
            "sudo systemctl enable nginx",
            "sudo systemctl start nginx",
            "sudo systemctl enable fail2ban",
            "sudo systemctl start fail2ban"
        ]' \
        --output-s3-bucket-name "lilithos-deployment" \
        --output-s3-key-prefix "logs"
    
    log "✅ Dependencies installation command sent"
}

# Clone LilithOS repository
clone_repository() {
    log "📥 Cloning LilithOS repository..."
    
    aws ssm send-command \
        --instance-ids "$INSTANCE_ID" \
        --region "$REGION" \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=[
            "cd /home/ubuntu",
            "git clone https://github.com/M-K-World-Wide/LilithOS.git",
            "chmod +x LilithOS/scripts/*.sh"
        ]' \
        --output-s3-bucket-name "lilithos-deployment" \
        --output-s3-key-prefix "logs"
    
    log "✅ Repository clone command sent"
}

# Initialize LilithOS
initialize_lilithos() {
    log "⚙️ Initializing LilithOS..."
    
    aws ssm send-command \
        --instance-ids "$INSTANCE_ID" \
        --region "$REGION" \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=[
            "cd /home/ubuntu/LilithOS",
            "./scripts/install.sh",
            "./scripts/initialize_features.sh",
            "./modules/features/cross-platform-compatibility/init.sh"
        ]' \
        --output-s3-bucket-name "lilithos-deployment" \
        --output-s3-key-prefix "logs"
    
    log "✅ LilithOS initialization command sent"
}

# Set up web server
setup_webserver() {
    log "🌐 Setting up web server..."
    
    aws ssm send-command \
        --instance-ids "$INSTANCE_ID" \
        --region "$REGION" \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=[
            "cd /home/ubuntu/LilithOS",
            "sudo cp scripts/nginx_lilithos.conf /etc/nginx/sites-available/lilithos",
            "sudo ln -sf /etc/nginx/sites-available/lilithos /etc/nginx/sites-enabled/",
            "sudo rm -f /etc/nginx/sites-enabled/default",
            "sudo systemctl reload nginx"
        ]' \
        --output-s3-bucket-name "lilithos-deployment" \
        --output-s3-key-prefix "logs"
    
    log "✅ Web server setup command sent"
}

# Get instance information
get_instance_info() {
    log "📊 Getting instance information..."
    
    PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$REGION" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    
    echo "🌑 LilithOS AWS EC2 Deployment Complete!"
    echo "=========================================="
    echo "Instance ID: $INSTANCE_ID"
    echo "Public IP: $PUBLIC_IP"
    echo ""
    echo "🌐 Web Access:"
    echo "- HTTP: http://$PUBLIC_IP"
    echo "- LilithOS Dashboard: http://$PUBLIC_IP:8080"
    echo "- Glass Dashboard: http://$PUBLIC_IP/glass"
    echo ""
    echo "📋 Deployment Status:"
    echo "- Dependencies: Installing..."
    echo "- Repository: Cloning..."
    echo "- LilithOS: Initializing..."
    echo "- Web Server: Configuring..."
    echo ""
    echo "⏳ Commands are being executed on the instance."
    echo "Check AWS Systems Manager console for detailed logs."
    echo ""
    echo "🌑 LilithOS - Where Technology Meets the Ethereal"
}

# Main execution
main() {
    log "🌑 LilithOS Simple AWS Deployment"
    log "================================="
    
    # Check instance
    check_instance
    
    # Install dependencies
    install_dependencies
    
    # Clone repository
    clone_repository
    
    # Initialize LilithOS
    initialize_lilithos
    
    # Setup web server
    setup_webserver
    
    # Display information
    get_instance_info
    
    log "🎉 Deployment commands sent successfully!"
    log "📋 Check AWS Systems Manager console for execution status."
}

# Execute main function
main "$@" 