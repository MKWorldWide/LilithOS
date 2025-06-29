#!/bin/bash

# 🌑 LilithOS AWS Instance Check and Fix Script
# Check instance status and fix SSH access issues

set -e

# Configuration
INSTANCE_ID="i-062e9938473b9782e"
KEY_NAME="lilithos-key"
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
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Check instance status
check_instance() {
    log "🔍 Checking instance status..."
    
    # Get instance information
    INSTANCE_INFO=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$REGION" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        error "Failed to get instance information"
        return 1
    fi
    
    # Extract information
    STATE=$(echo "$INSTANCE_INFO" | grep -o '"State":{[^}]*}' | grep -o '"Name":"[^"]*"' | cut -d'"' -f4)
    PUBLIC_IP=$(echo "$INSTANCE_INFO" | grep -o '"PublicIpAddress":"[^"]*"' | cut -d'"' -f4)
    KEY_PAIR=$(echo "$INSTANCE_INFO" | grep -o '"KeyName":"[^"]*"' | cut -d'"' -f4)
    
    echo "Instance ID: $INSTANCE_ID"
    echo "State: $STATE"
    echo "Public IP: $PUBLIC_IP"
    echo "Key Pair: $KEY_PAIR"
    echo ""
    
    if [ "$STATE" = "running" ]; then
        log "✅ Instance is running"
        echo "$PUBLIC_IP" > .current_ip
        return 0
    else
        error "❌ Instance is not running (State: $STATE)"
        return 1
    fi
}

# Check key pair
check_key_pair() {
    log "🔑 Checking key pair..."
    
    if [ ! -f "$KEY_NAME.pem" ]; then
        error "❌ Key file $KEY_NAME.pem not found!"
        return 1
    fi
    
    # Check key pair in AWS
    if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" &>/dev/null; then
        log "✅ Key pair exists in AWS"
    else
        error "❌ Key pair does not exist in AWS"
        return 1
    fi
    
    # Check file permissions
    PERMS=$(stat -f "%Lp" "$KEY_NAME.pem")
    if [ "$PERMS" = "400" ]; then
        log "✅ Key file permissions are correct"
    else
        warning "⚠️  Fixing key file permissions..."
        chmod 400 "$KEY_NAME.pem"
        log "✅ Key file permissions fixed"
    fi
    
    return 0
}

# Test SSH connection
test_ssh() {
    if [ ! -f .current_ip ]; then
        error "❌ No IP address found. Run check_instance first."
        return 1
    fi
    
    PUBLIC_IP=$(cat .current_ip)
    log "🔍 Testing SSH connection to $PUBLIC_IP..."
    
    # Try SSH connection
    if timeout 30 ssh -i "$KEY_NAME.pem" -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes "ubuntu@$PUBLIC_IP" "echo 'SSH test successful'" 2>/dev/null; then
        log "✅ SSH connection successful!"
        return 0
    else
        error "❌ SSH connection failed!"
        return 1
    fi
}

# Create new key pair if needed
create_new_key() {
    log "🔑 Creating new key pair..."
    
    # Delete old key pair
    if aws ec2 describe-key-pairs --key-names "$KEY_NAME" --region "$REGION" &>/dev/null; then
        log "🗑️  Deleting old key pair..."
        aws ec2 delete-key-pair --key-name "$KEY_NAME" --region "$REGION"
        rm -f "$KEY_NAME.pem"
    fi
    
    # Create new key pair
    log "🔑 Creating new key pair: $KEY_NAME"
    aws ec2 create-key-pair \
        --key-name "$KEY_NAME" \
        --region "$REGION" \
        --query 'KeyMaterial' \
        --output text > "$KEY_NAME.pem"
    
    # Set permissions
    chmod 400 "$KEY_NAME.pem"
    
    log "✅ New key pair created: $KEY_NAME.pem"
}

# Reboot instance
reboot_instance() {
    log "🔄 Rebooting instance..."
    
    aws ec2 reboot-instances --instance-ids "$INSTANCE_ID" --region "$REGION"
    
    log "⏳ Waiting for instance to be ready..."
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$REGION"
    aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_ID" --region "$REGION"
    
    log "✅ Instance rebooted and ready"
}

# Main execution
main() {
    log "🌑 LilithOS AWS Instance Check and Fix"
    log "======================================"
    
    # Check instance status
    if ! check_instance; then
        error "Instance check failed"
        exit 1
    fi
    
    # Check key pair
    if ! check_key_pair; then
        warning "Key pair issues detected"
        read -p "Create new key pair? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            create_new_key
            reboot_instance
        else
            error "Cannot proceed without valid key pair"
            exit 1
        fi
    fi
    
    # Test SSH
    if ! test_ssh; then
        warning "SSH connection failed"
        read -p "Reboot instance and retry? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            reboot_instance
            sleep 30
            if test_ssh; then
                log "✅ SSH connection successful after reboot"
            else
                error "❌ SSH still failing after reboot"
                exit 1
            fi
        else
            error "Cannot proceed without SSH access"
            exit 1
        fi
    fi
    
    log "🎉 Instance is ready for deployment!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Run: ./scripts/deploy_to_aws.sh"
    echo "2. Or SSH manually: ssh -i $KEY_NAME.pem ubuntu@$(cat .current_ip)"
}

# Execute main function
main "$@" 