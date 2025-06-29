#!/bin/bash

# 🌑 LilithOS AWS EC2 SSH Fix Script
# Fix SSH access and get connection information

set -e

# Instance information from deployment
INSTANCE_ID="i-062e9938473b9782e"
KEY_NAME="lilithos-key"
PUBLIC_IP="54.165.89.110"

echo "🌑 LilithOS AWS EC2 Instance Information"
echo "=========================================="
echo "Instance ID: $INSTANCE_ID"
echo "Public IP: $PUBLIC_IP"
echo "Key File: $KEY_NAME.pem"
echo ""

# Check if key file exists
if [ ! -f "$KEY_NAME.pem" ]; then
    echo "❌ Key file $KEY_NAME.pem not found!"
    exit 1
fi

# Set proper permissions
chmod 400 "$KEY_NAME.pem"

echo "🔧 Testing SSH connection..."
echo "SSH Command: ssh -i $KEY_NAME.pem ubuntu@$PUBLIC_IP"
echo ""

# Test SSH connection
if ssh -i "$KEY_NAME.pem" -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@"$PUBLIC_IP" "echo 'SSH connection successful!'"; then
    echo "✅ SSH connection successful!"
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
    echo "1. SSH into the instance: ssh -i $KEY_NAME.pem ubuntu@$PUBLIC_IP"
    echo "2. Clone LilithOS repository"
    echo "3. Run installation script"
    echo "4. Configure glass dashboard"
    echo "5. Set up cross-platform compatibility"
    echo ""
    echo "🌑 LilithOS - Where Technology Meets the Ethereal"
else
    echo "❌ SSH connection failed!"
    echo "Please check:"
    echo "1. Key file permissions (should be 400)"
    echo "2. Security group allows SSH (port 22)"
    echo "3. Instance is running"
    echo "4. Network connectivity"
fi 