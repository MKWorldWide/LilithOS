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
