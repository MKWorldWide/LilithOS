#!/bin/bash

# 🌑 LilithOS AWS EC2 Deployment Script
# Quantum-documented deployment script for hosting LilithOS on AWS EC2

set -e  # Exit on any error

# 🎯 Configuration Variables
PROJECT_NAME="LilithOS"
INSTANCE_NAME="lilithos-server"
INSTANCE_TYPE="t3.medium"  # 2 vCPU, 4GB RAM - suitable for LilithOS
AMI_ID="ami-0c02fb55956c7d316"  # Ubuntu 22.04 LTS (us-east-1)
KEY_NAME="lilithos-key"
SECURITY_GROUP_NAME="lilithos-sg"
REGION="us-east-1"
VOLUME_SIZE="20"  # GB

# 🎨 Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 📋 Logging function
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

# 🚀 Main deployment function
deploy_lilithos() {
    log "🚀 Starting LilithOS AWS EC2 deployment..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        error "AWS CLI is not installed. Please install it first."
    fi
    
    # Test AWS credentials
    log "🔐 Testing AWS credentials..."
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS credentials are not configured properly."
    fi
    
    # Create key pair
    create_key_pair
    
    # Create security group
    create_security_group
    
    # Launch EC2 instance
    launch_instance
    
    # Wait for instance to be ready
    wait_for_instance
    
    # Configure instance
    configure_instance
    
    # Display connection information
    display_connection_info
    
    log "✅ LilithOS deployment completed successfully!"
}

# 🔑 Create key pair
create_key_pair() {
    log "🔑 Creating key pair: $KEY_NAME"
    
    # Check if key pair already exists
    if aws ec2 describe-key-pairs --key-names "$KEY_NAME" &> /dev/null; then
        warning "Key pair $KEY_NAME already exists. Using existing key pair."
        return 0
    fi
    
    # Create new key pair
    aws ec2 create-key-pair \
        --key-name "$KEY_NAME" \
        --query 'KeyMaterial' \
        --output text > "$KEY_NAME.pem"
    
    # Set proper permissions
    chmod 400 "$KEY_NAME.pem"
    
    log "✅ Key pair created: $KEY_NAME.pem"
}

# 🛡️ Create security group
create_security_group() {
    log "🛡️ Creating security group: $SECURITY_GROUP_NAME"
    
    # Check if security group already exists
    if aws ec2 describe-security-groups --group-names "$SECURITY_GROUP_NAME" &> /dev/null; then
        warning "Security group $SECURITY_GROUP_NAME already exists. Using existing security group."
        return 0
    fi
    
    # Create security group
    SG_ID=$(aws ec2 create-security-group \
        --group-name "$SECURITY_GROUP_NAME" \
        --description "Security group for LilithOS server" \
        --query 'GroupId' \
        --output text)
    
    # Add SSH rule
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 22 \
        --cidr 0.0.0.0/0
    
    # Add HTTP rule
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 80 \
        --cidr 0.0.0.0/0
    
    # Add HTTPS rule
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 443 \
        --cidr 0.0.0.0/0
    
    # Add LilithOS specific ports
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 8080 \
        --cidr 0.0.0.0/0
    
    # Add VNC port for remote desktop
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 5900 \
        --cidr 0.0.0.0/0
    
    log "✅ Security group created: $SG_ID"
    echo "$SG_ID" > .security_group_id
}

# 🖥️ Launch EC2 instance
launch_instance() {
    log "🖥️ Launching EC2 instance..."
    
    # Get security group ID
    if [ -f .security_group_id ]; then
        SG_ID=$(cat .security_group_id)
    else
        SG_ID=$(aws ec2 describe-security-groups \
            --group-names "$SECURITY_GROUP_NAME" \
            --query 'SecurityGroups[0].GroupId' \
            --output text)
    fi
    
    # Launch instance
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --count 1 \
        --instance-type "$INSTANCE_TYPE" \
        --key-name "$KEY_NAME" \
        --security-group-ids "$SG_ID" \
        --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":$VOLUME_SIZE,\"VolumeType\":\"gp3\",\"DeleteOnTermination\":true}}]" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME},{Key=Project,Value=$PROJECT_NAME}]" \
        --query 'Instances[0].InstanceId' \
        --output text)
    
    log "✅ Instance launched: $INSTANCE_ID"
    echo "$INSTANCE_ID" > .instance_id
}

# ⏳ Wait for instance to be ready
wait_for_instance() {
    log "⏳ Waiting for instance to be ready..."
    
    INSTANCE_ID=$(cat .instance_id)
    
    # Wait for instance to be running
    aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
    
    # Wait for status checks to pass
    aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_ID"
    
    # Get public IP
    PUBLIC_IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)
    
    echo "$PUBLIC_IP" > .public_ip
    
    log "✅ Instance is ready. Public IP: $PUBLIC_IP"
}

# ⚙️ Configure instance
configure_instance() {
    log "⚙️ Configuring LilithOS on the instance..."
    
    PUBLIC_IP=$(cat .public_ip)
    
    # Wait for SSH to be available
    log "🔍 Waiting for SSH to be available..."
    while ! nc -z "$PUBLIC_IP" 22; do
        sleep 5
    done
    
    # Create user data script for initial setup
    cat > user_data.sh << 'EOF'
#!/bin/bash
# LilithOS initial setup script

# Update system
apt-get update
apt-get upgrade -y

# Install essential packages
apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-pip \
    nodejs \
    npm \
    docker.io \
    docker-compose \
    nginx \
    ufw \
    fail2ban \
    htop \
    vim \
    tmux \
    screen

# Configure firewall
ufw --force enable
ufw allow ssh
ufw allow 'Nginx Full'
ufw allow 8080
ufw allow 5900

# Start and enable services
systemctl enable docker
systemctl start docker
systemctl enable nginx
systemctl start nginx
systemctl enable fail2ban
systemctl start fail2ban

# Create lilithos user
useradd -m -s /bin/bash lilithos
usermod -aG sudo lilithos
usermod -aG docker lilithos

# Set up SSH key for lilithos user
mkdir -p /home/lilithos/.ssh
chmod 700 /home/lilithos/.ssh

# Create welcome message
cat > /home/lilithos/welcome.txt << 'WELCOME'
🌑 Welcome to LilithOS on AWS EC2!

Your LilithOS instance is now running and ready for deployment.

Next steps:
1. Clone the LilithOS repository
2. Run the installation script
3. Configure the glass dashboard
4. Set up cross-platform compatibility

For support, check the documentation at:
https://github.com/M-K-World-Wide/LilithOS

🌑 LilithOS - Where Technology Meets the Ethereal
WELCOME

chown -R lilithos:lilithos /home/lilithos

# Install additional security tools
apt-get install -y \
    rkhunter \
    chkrootkit \
    lynis \
    auditd

# Configure auditd
systemctl enable auditd
systemctl start auditd

# Set up log monitoring
apt-get install -y logwatch
echo "logwatch --output mail --mailto root --detail high" | crontab -

# Create system monitoring script
cat > /usr/local/bin/system-monitor.sh << 'MONITOR'
#!/bin/bash
# LilithOS system monitoring script

echo "=== LilithOS System Status ==="
echo "Date: $(date)"
echo "Uptime: $(uptime)"
echo "Load Average: $(cat /proc/loadavg)"
echo "Memory Usage: $(free -h)"
echo "Disk Usage: $(df -h /)"
echo "Docker Status: $(systemctl is-active docker)"
echo "Nginx Status: $(systemctl is-active nginx)"
echo "Fail2ban Status: $(systemctl is-active fail2ban)"
MONITOR

chmod +x /usr/local/bin/system-monitor.sh

# Set up daily system report
echo "0 6 * * * /usr/local/bin/system-monitor.sh | mail -s 'LilithOS Daily Report' root" | crontab -

echo "🌑 LilithOS initial setup completed!"
EOF
    
    # Copy user data script to instance
    scp -i "$KEY_NAME.pem" -o StrictHostKeyChecking=no user_data.sh ubuntu@"$PUBLIC_IP":/tmp/
    
    # Execute user data script
    ssh -i "$KEY_NAME.pem" -o StrictHostKeyChecking=no ubuntu@"$PUBLIC_IP" "sudo bash /tmp/user_data.sh"
    
    log "✅ Instance configuration completed"
}

# 📊 Display connection information
display_connection_info() {
    log "📊 LilithOS AWS EC2 Instance Information"
    echo "=========================================="
    
    INSTANCE_ID=$(cat .instance_id)
    PUBLIC_IP=$(cat .public_ip)
    
    echo "Instance ID: $INSTANCE_ID"
    echo "Public IP: $PUBLIC_IP"
    echo "Key File: $KEY_NAME.pem"
    echo "Security Group: $SECURITY_GROUP_NAME"
    echo ""
    echo "🔗 Connection Commands:"
    echo "SSH: ssh -i $KEY_NAME.pem ubuntu@$PUBLIC_IP"
    echo "SCP: scp -i $KEY_NAME.pem file ubuntu@$PUBLIC_IP:/path/"
    echo ""
    echo "🌐 Web Access:"
    echo "HTTP: http://$PUBLIC_IP"
    echo "HTTPS: https://$PUBLIC_IP (after SSL setup)"
    echo "LilithOS Dashboard: http://$PUBLIC_IP:8080"
    echo ""
    echo "📱 VNC Access:"
    echo "VNC: $PUBLIC_IP:5900 (after VNC setup)"
    echo ""
    echo "🔧 Management Commands:"
    echo "Stop Instance: aws ec2 stop-instances --instance-ids $INSTANCE_ID"
    echo "Start Instance: aws ec2 start-instances --instance-ids $INSTANCE_ID"
    echo "Terminate Instance: aws ec2 terminate-instances --instance-ids $INSTANCE_ID"
    echo ""
    echo "📋 Next Steps:"
    echo "1. SSH into the instance"
    echo "2. Clone LilithOS repository"
    echo "3. Run installation script"
    echo "4. Configure glass dashboard"
    echo "5. Set up cross-platform compatibility"
    
    # Save connection info to file
    cat > lilithos_aws_info.txt << EOF
🌑 LilithOS AWS EC2 Instance Information
==========================================

Instance ID: $INSTANCE_ID
Public IP: $PUBLIC_IP
Key File: $KEY_NAME.pem
Security Group: $SECURITY_GROUP_NAME

Connection Commands:
SSH: ssh -i $KEY_NAME.pem ubuntu@$PUBLIC_IP
SCP: scp -i $KEY_NAME.pem file ubuntu@$PUBLIC_IP:/path/

Web Access:
HTTP: http://$PUBLIC_IP
HTTPS: https://$PUBLIC_IP (after SSL setup)
LilithOS Dashboard: http://$PUBLIC_IP:8080

VNC Access:
VNC: $PUBLIC_IP:5900 (after VNC setup)

Management Commands:
Stop Instance: aws ec2 stop-instances --instance-ids $INSTANCE_ID
Start Instance: aws ec2 start-instances --instance-ids $INSTANCE_ID
Terminate Instance: aws ec2 terminate-instances --instance-ids $INSTANCE_ID

Next Steps:
1. SSH into the instance
2. Clone LilithOS repository
3. Run installation script
4. Configure glass dashboard
5. Set up cross-platform compatibility

🌑 LilithOS - Where Technology Meets the Ethereal
EOF
    
    log "✅ Connection information saved to: lilithos_aws_info.txt"
}

# 🧹 Cleanup function
cleanup() {
    log "🧹 Cleaning up temporary files..."
    rm -f user_data.sh
    log "✅ Cleanup completed"
}

# 🚨 Error handling
trap 'error "Deployment failed. Check the logs above for details."' ERR

# 🎯 Main execution
main() {
    log "🌑 LilithOS AWS EC2 Deployment Script"
    log "====================================="
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        error "Please do not run this script as root."
    fi
    
    # Check dependencies
    if ! command -v nc &> /dev/null; then
        error "netcat is required but not installed. Please install it first."
    fi
    
    # Run deployment
    deploy_lilithos
    
    # Cleanup
    cleanup
    
    log "🎉 LilithOS AWS EC2 deployment completed successfully!"
    log "📋 Check lilithos_aws_info.txt for connection details."
}

# 🚀 Execute main function
main "$@" 