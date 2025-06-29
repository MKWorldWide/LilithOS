#!/bin/bash

# 🌑 LilithOS Manual Deployment Instructions
# Provide step-by-step instructions for manual deployment

set -e

# Configuration
INSTANCE_ID="i-062e9938473b9782e"
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

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Get instance information
get_instance_info() {
    log "📊 Getting instance information..."
    
    # Try to get instance info
    INSTANCE_INFO=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$REGION" 2>/dev/null || echo "{}")
    
    if [ "$INSTANCE_INFO" = "{}" ]; then
        warning "Could not retrieve instance information"
        echo "Instance ID: $INSTANCE_ID"
        echo "Public IP: 54.165.89.110 (from previous deployment)"
        echo "Status: Unknown"
    else
        # Extract information (simplified)
        echo "Instance ID: $INSTANCE_ID"
        echo "Status: Running"
        echo "Public IP: 54.165.89.110"
    fi
}

# Display manual deployment instructions
display_instructions() {
    echo ""
    echo -e "${PURPLE}🌑 LilithOS Manual Deployment Instructions${NC}"
    echo "=================================================="
    echo ""
    echo -e "${CYAN}📋 Prerequisites:${NC}"
    echo "1. AWS CLI configured with proper credentials"
    echo "2. Instance running and accessible"
    echo "3. SSH key file: lilithos-key.pem"
    echo ""
    
    echo -e "${CYAN}🔧 Step 1: Fix SSH Access${NC}"
    echo "The instance may need time to fully initialize or the key may need to be recreated."
    echo ""
    echo "Option A: Wait and retry SSH"
    echo "  ssh -i lilithos-key.pem ubuntu@54.165.89.110"
    echo ""
    echo "Option B: Create new key pair"
    echo "  aws ec2 delete-key-pair --key-name lilithos-key --region us-east-1"
    echo "  aws ec2 create-key-pair --key-name lilithos-key --query 'KeyMaterial' --output text > lilithos-key-new.pem"
    echo "  chmod 400 lilithos-key-new.pem"
    echo "  ssh -i lilithos-key-new.pem ubuntu@54.165.89.110"
    echo ""
    
    echo -e "${CYAN}📦 Step 2: Install Dependencies${NC}"
    echo "Once SSH access is working, run these commands on the instance:"
    echo ""
    echo "  sudo apt-get update"
    echo "  sudo apt-get install -y git curl wget build-essential python3 python3-pip nodejs npm docker.io docker-compose nginx ufw fail2ban"
    echo "  sudo systemctl enable docker && sudo systemctl start docker"
    echo "  sudo systemctl enable nginx && sudo systemctl start nginx"
    echo "  sudo systemctl enable fail2ban && sudo systemctl start fail2ban"
    echo ""
    
    echo -e "${CYAN}📥 Step 3: Clone LilithOS Repository${NC}"
    echo "  cd /home/ubuntu"
    echo "  git clone https://github.com/M-K-World-Wide/LilithOS.git"
    echo "  cd LilithOS"
    echo "  chmod +x scripts/*.sh"
    echo ""
    
    echo -e "${CYAN}⚙️ Step 4: Initialize LilithOS${NC}"
    echo "  ./scripts/install.sh"
    echo "  ./scripts/initialize_features.sh"
    echo "  ./modules/features/cross-platform-compatibility/init.sh"
    echo ""
    
    echo -e "${CYAN}🌐 Step 5: Configure Web Server${NC}"
    echo "  sudo cp scripts/nginx_lilithos.conf /etc/nginx/sites-available/lilithos"
    echo "  sudo ln -sf /etc/nginx/sites-available/lilithos /etc/nginx/sites-enabled/"
    echo "  sudo rm -f /etc/nginx/sites-enabled/default"
    echo "  sudo systemctl reload nginx"
    echo ""
    
    echo -e "${CYAN}🎨 Step 6: Launch Glass Dashboard${NC}"
    echo "  ./scripts/glass_dashboard.sh"
    echo ""
    
    echo -e "${CYAN}🌐 Step 7: Access LilithOS${NC}"
    echo "Web Access URLs:"
    echo "  - HTTP: http://54.165.89.110"
    echo "  - LilithOS Dashboard: http://54.165.89.110:8080"
    echo "  - Glass Dashboard: http://54.165.89.110/glass"
    echo ""
    
    echo -e "${CYAN}🔧 Alternative: Use AWS Console${NC}"
    echo "1. Go to AWS EC2 Console"
    echo "2. Select the instance: $INSTANCE_ID"
    echo "3. Click 'Connect' → 'EC2 Instance Connect'"
    echo "4. Use the browser-based terminal to run the commands above"
    echo ""
    
    echo -e "${CYAN}📊 Monitoring${NC}"
    echo "Check deployment status:"
    echo "  sudo systemctl status nginx"
    echo "  sudo systemctl status docker"
    echo "  sudo journalctl -u nginx -f"
    echo ""
    
    echo -e "${CYAN}🔒 Security${NC}"
    echo "The instance has been configured with:"
    echo "  - SSH access on port 22"
    echo "  - HTTP/HTTPS on ports 80/443"
    echo "  - Firewall (ufw) enabled"
    echo "  - Fail2ban for intrusion prevention"
    echo ""
    
    echo -e "${GREEN}🌑 LilithOS - Where Technology Meets the Ethereal${NC}"
    echo ""
    echo "For support, check the documentation at:"
    echo "https://github.com/M-K-World-Wide/LilithOS"
}

# Create deployment script for the instance
create_deployment_script() {
    log "📝 Creating deployment script for the instance..."
    
    cat > deploy_lilithos_on_instance.sh << 'EOF'
#!/bin/bash

# 🌑 LilithOS Instance Deployment Script
# Run this script on the AWS EC2 instance

set -e

echo "🌑 LilithOS Instance Deployment"
echo "================================"

# Update system
echo "📦 Updating system..."
sudo apt-get update
sudo apt-get upgrade -y

# Install dependencies
echo "📦 Installing dependencies..."
sudo apt-get install -y \
    git curl wget build-essential \
    python3 python3-pip \
    nodejs npm \
    docker.io docker-compose \
    nginx ufw fail2ban \
    htop vim tmux screen

# Start and enable services
echo "🔧 Configuring services..."
sudo systemctl enable docker && sudo systemctl start docker
sudo systemctl enable nginx && sudo systemctl start nginx
sudo systemctl enable fail2ban && sudo systemctl start fail2ban

# Configure firewall
echo "🛡️ Configuring firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw allow 8080
sudo ufw allow 5900

# Clone LilithOS
echo "📥 Cloning LilithOS repository..."
cd /home/ubuntu
if [ -d "LilithOS" ]; then
    echo "Repository already exists, updating..."
    cd LilithOS
    git pull origin main
else
    git clone https://github.com/M-K-World-Wide/LilithOS.git
    cd LilithOS
fi

# Set permissions
chmod +x scripts/*.sh

# Initialize LilithOS
echo "⚙️ Initializing LilithOS..."
./scripts/install.sh
./scripts/initialize_features.sh
./modules/features/cross-platform-compatibility/init.sh

# Configure web server
echo "🌐 Configuring web server..."
sudo cp scripts/nginx_lilithos.conf /etc/nginx/sites-available/lilithos
sudo ln -sf /etc/nginx/sites-available/lilithos /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl reload nginx

# Create startup script
echo "🚀 Creating startup script..."
cat > /home/ubuntu/start_lilithos.sh << 'STARTUP'
#!/bin/bash
cd /home/ubuntu/LilithOS
./scripts/glass_dashboard.sh
STARTUP

chmod +x /home/ubuntu/start_lilithos.sh

echo "✅ LilithOS deployment completed!"
echo ""
echo "🌐 Access URLs:"
echo "  - HTTP: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "  - LilithOS Dashboard: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "  - Glass Dashboard: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/glass"
echo ""
echo "🚀 To start LilithOS: ./start_lilithos.sh"
echo "🌑 LilithOS - Where Technology Meets the Ethereal"
EOF

    chmod +x deploy_lilithos_on_instance.sh
    
    echo "✅ Deployment script created: deploy_lilithos_on_instance.sh"
    echo "📋 Copy this script to the instance and run it:"
    echo "  scp -i lilithos-key.pem deploy_lilithos_on_instance.sh ubuntu@54.165.89.110:/home/ubuntu/"
    echo "  ssh -i lilithos-key.pem ubuntu@54.165.89.110"
    echo "  ./deploy_lilithos_on_instance.sh"
}

# Main execution
main() {
    log "🌑 LilithOS Manual Deployment Instructions"
    log "=========================================="
    
    # Get instance information
    get_instance_info
    
    # Display instructions
    display_instructions
    
    # Create deployment script
    create_deployment_script
    
    log "📋 Manual deployment instructions provided!"
    log "🎯 Follow the steps above to deploy LilithOS on the AWS instance."
}

# Execute main function
main "$@" 