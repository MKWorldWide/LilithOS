#!/bin/bash

# Exit on error
set -e

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

echo "🚀 Starting LilithOS service installation..."

# Create system user and group if they don't exist
if ! id -u lilith >/dev/null 2>&1; then
    echo "👤 Creating 'lilith' user and group..."
    useradd -r -s /usr/sbin/nologin lilith
fi

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p /opt/lilithos/logs
mkdir -p /etc/lilithos
mkdir -p /var/backups/lilithos

# Set ownership and permissions
echo "🔒 Setting permissions..."
chown -R lilith:lilith /opt/lilithos
chmod 750 /opt/lilithos
chmod 750 /var/backups/lilithos

# Install systemd services
echo "⚙️  Installing systemd services..."
cp systemd/*.service /etc/systemd/system/
chmod 644 /etc/systemd/system/lilith-*.service

# Reload systemd to pick up new services
echo "🔄 Reloading systemd daemon..."
systemctl daemon-reload

# Enable services to start on boot
echo "🔌 Enabling services to start on boot..."
systemctl enable lilithkit.service
systemctl enable lilith-update-daemon.service
systemctl enable lilith-ble-whisperer.service
systemctl enable lilith-backup-daemon.service

# Start services
echo "🚀 Starting LilithOS services..."
systemctl start lilithkit.service
systemctl start lilith-update-daemon.service
systemctl start lilith-ble-whisperer.service
systemctl start lilith-backup-daemon.service

echo "✅ Installation complete!"
echo ""
echo "📋 Service status:"
systemctl status lilithkit.service --no-pager
systemctl status lilith-update-daemon.service --no-pager
systemctl status lilith-ble-whisperer.service --no-pager
systemctl status lilith-backup-daemon.service --no-pager

echo ""
echo "🌐 To view logs:"
echo "   journalctl -u lilithkit.service -f"
echo "   journalctl -u lilith-update-daemon.service -f"
echo "   journalctl -u lilith-ble-whisperer.service -f"
echo "   journalctl -u lilith-backup-daemon.service -f"

exit 0
