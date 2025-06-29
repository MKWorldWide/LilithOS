#!/bin/bash

# 🌑 LilithOS Comprehensive AWS Deployment Script
# Complete deployment process with all necessary steps

set -e

# Configuration
INSTANCE_ID="i-062e9938473b9782e"
PUBLIC_IP="54.165.89.110"
KEY_FILE="lilithos-key-new.pem"
REGION="us-east-1"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

# Check instance status
check_instance() {
    log "🔍 Checking instance status..."
    
    # Simple check
    if aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$REGION" --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null | grep -q "running"; then
        log "✅ Instance is running"
        return 0
    else
        error "❌ Instance is not running"
    fi
}

# Test SSH connection
test_ssh() {
    log "🔍 Testing SSH connection..."
    
    if ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes "ubuntu@$PUBLIC_IP" "echo 'SSH test successful'" 2>/dev/null; then
        log "✅ SSH connection successful!"
        return 0
    else
        warning "⚠️ SSH connection failed"
        return 1
    fi
}

# Deploy using SSH
deploy_via_ssh() {
    log "🚀 Deploying via SSH..."
    
    # Copy deployment script
    log "📦 Copying deployment script..."
    if scp -i "$KEY_FILE" -o StrictHostKeyChecking=no deploy_lilithos_on_instance.sh "ubuntu@$PUBLIC_IP:/home/ubuntu/" 2>/dev/null; then
        log "✅ Deployment script copied"
    else
        error "❌ Failed to copy deployment script"
    fi
    
    # Execute deployment
    log "⚙️ Executing deployment on instance..."
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "ubuntu@$PUBLIC_IP" "chmod +x /home/ubuntu/deploy_lilithos_on_instance.sh && /home/ubuntu/deploy_lilithos_on_instance.sh"
    
    log "✅ SSH deployment completed!"
}

# Create user data script for new instance
create_user_data_script() {
    log "📝 Creating user data script for new instance..."
    
    cat > user_data_lilithos.sh << 'EOF'
#!/bin/bash

# 🌑 LilithOS User Data Script
# Run automatically when instance starts

set -e

# Update system
apt-get update
apt-get upgrade -y

# Install dependencies
apt-get install -y \
    git curl wget build-essential \
    python3 python3-pip \
    nodejs npm \
    docker.io docker-compose \
    nginx ufw fail2ban \
    htop vim tmux screen

# Start and enable services
systemctl enable docker
systemctl start docker
systemctl enable nginx
systemctl start nginx
systemctl enable fail2ban
systemctl start fail2ban

# Configure firewall
ufw --force enable
ufw allow ssh
ufw allow 'Nginx Full'
ufw allow 8080
ufw allow 5900

# Clone LilithOS
cd /home/ubuntu
git clone https://github.com/M-K-World-Wide/LilithOS.git
cd LilithOS
chmod +x scripts/*.sh

# Initialize LilithOS
./scripts/install.sh
./scripts/initialize_features.sh
./modules/features/cross-platform-compatibility/init.sh

# Configure web server
cp scripts/nginx_lilithos.conf /etc/nginx/sites-available/lilithos
ln -sf /etc/nginx/sites-available/lilithos /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl reload nginx

# Create startup script
cat > /home/ubuntu/start_lilithos.sh << 'STARTUP'
#!/bin/bash
cd /home/ubuntu/LilithOS
./scripts/glass_dashboard.sh
STARTUP

chmod +x /home/ubuntu/start_lilithos.sh

# Create status file
cat > /home/ubuntu/lilithos_status.txt << 'STATUS'
🌑 LilithOS Deployment Complete!

Instance Information:
- Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)
- Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
- Region: $(curl -s http://169.254.169.254/latest/meta-data/placement/region)

Access URLs:
- HTTP: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
- LilithOS Dashboard: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080
- Glass Dashboard: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/glass

To start LilithOS: ./start_lilithos.sh
🌑 LilithOS - Where Technology Meets the Ethereal
STATUS

echo "🌑 LilithOS deployment completed successfully!"
EOF

    log "✅ User data script created"
}

# Create new instance with user data
create_new_instance() {
    log "🔄 Creating new instance with user data..."
    
    # Get security group ID
    SG_ID=$(aws ec2 describe-security-groups --group-names "lilithos-sg" --region "$REGION" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)
    
    if [ -z "$SG_ID" ]; then
        error "❌ Security group not found"
    fi
    
    # Terminate old instance
    log "🗑️ Terminating old instance..."
    aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" --region "$REGION"
    
    # Wait for termination
    aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID" --region "$REGION"
    
    # Launch new instance with user data
    log "🚀 Launching new instance with user data..."
    NEW_INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "ami-0c02fb55956c7d316" \
        --count 1 \
        --instance-type "t3.medium" \
        --key-name "lilithos-key" \
        --security-group-ids "$SG_ID" \
        --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":20,\"VolumeType\":\"gp3\",\"DeleteOnTermination\":true}}]" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=lilithos-server},{Key=Project,Value=LilithOS}]" \
        --user-data file://user_data_lilithos.sh \
        --query 'Instances[0].InstanceId' \
        --output text)
    
    log "✅ New instance launched: $NEW_INSTANCE_ID"
    
    # Wait for instance to be ready
    log "⏳ Waiting for instance to be ready..."
    aws ec2 wait instance-running --instance-ids "$NEW_INSTANCE_ID" --region "$REGION"
    aws ec2 wait instance-status-ok --instance-ids "$NEW_INSTANCE_ID" --region "$REGION"
    
    # Get new public IP
    NEW_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$NEW_INSTANCE_ID" --region "$REGION" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    
    log "✅ New instance ready. Public IP: $NEW_PUBLIC_IP"
    
    # Update configuration
    echo "$NEW_INSTANCE_ID" > .current_instance_id
    echo "$NEW_PUBLIC_IP" > .current_public_ip
    
    # Wait for deployment to complete
    log "⏳ Waiting for LilithOS deployment to complete (this may take 5-10 minutes)..."
    sleep 300
    
    # Test access
    test_new_instance_access "$NEW_PUBLIC_IP"
}

# Test new instance access
test_new_instance_access() {
    local ip="$1"
    log "🔍 Testing new instance access..."
    
    # Test HTTP access
    if curl -s --connect-timeout 10 "http://$ip" > /dev/null; then
        log "✅ HTTP access working"
    else
        warning "⚠️ HTTP access not yet available"
    fi
    
    # Test SSH access
    if ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes "ubuntu@$ip" "echo 'SSH test successful'" 2>/dev/null; then
        log "✅ SSH access working"
    else
        warning "⚠️ SSH access not yet available"
    fi
    
    # Display access information
    display_access_info "$ip"
}

# Display access information
display_access_info() {
    local ip="$1"
    
    echo ""
    echo -e "${PURPLE}🌑 LilithOS AWS EC2 Deployment Complete!${NC}"
    echo "=========================================="
    echo "Instance IP: $ip"
    echo "Key File: $KEY_FILE"
    echo ""
    echo -e "${CYAN}🌐 Web Access:${NC}"
    echo "- HTTP: http://$ip"
    echo "- LilithOS Dashboard: http://$ip:8080"
    echo "- Glass Dashboard: http://$ip/glass"
    echo ""
    echo -e "${CYAN}🔗 SSH Access:${NC}"
    echo "ssh -i $KEY_FILE ubuntu@$ip"
    echo ""
    echo -e "${CYAN}📊 Status Check:${NC}"
    echo "ssh -i $KEY_FILE ubuntu@$ip 'cat /home/ubuntu/lilithos_status.txt'"
    echo ""
    echo -e "${CYAN}🚀 Start LilithOS:${NC}"
    echo "ssh -i $KEY_FILE ubuntu@$ip './start_lilithos.sh'"
    echo ""
    echo -e "${GREEN}🌑 LilithOS - Where Technology Meets the Ethereal${NC}"
}

# Main execution
main() {
    log "🌑 LilithOS Comprehensive AWS Deployment"
    log "========================================"
    
    # Check instance
    check_instance
    
    # Test SSH
    if test_ssh; then
        # Deploy via SSH
        deploy_via_ssh
    else
        warning "SSH not available, creating new instance with user data"
        
        # Create user data script
        create_user_data_script
        
        # Create new instance
        create_new_instance
    fi
    
    log "🎉 Comprehensive deployment completed!"
}

# Execute main function
main "$@" 