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
