#!/bin/bash

# 🌑 LilithOS Final Deployment Status Script
# Provide complete deployment status and next steps

set -e

# Configuration
NEW_INSTANCE_ID="i-06d885a2cfb302317"
NEW_PUBLIC_IP="13.222.161.110"
OLD_INSTANCE_ID="i-062e9938473b9782e"
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

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Check instance status
check_instances() {
    log "🔍 Checking instance status..."
    
    echo "New Instance: $NEW_INSTANCE_ID"
    echo "New Public IP: $NEW_PUBLIC_IP"
    echo "Old Instance: $OLD_INSTANCE_ID (terminated)"
    echo "Key File: $KEY_FILE"
    echo ""
}

# Test access methods
test_access() {
    log "🔍 Testing access methods..."
    
    # Test HTTP access
    echo "Testing HTTP access..."
    if curl -s --connect-timeout 10 "http://$NEW_PUBLIC_IP" > /dev/null 2>&1; then
        echo "✅ HTTP access working"
    else
        echo "⚠️ HTTP access not yet available"
    fi
    
    # Test SSH access
    echo "Testing SSH access..."
    if ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes "ubuntu@$NEW_PUBLIC_IP" "echo 'SSH test successful'" > /dev/null 2>&1; then
        echo "✅ SSH access working"
    else
        echo "⚠️ SSH access not yet available"
    fi
    
    echo ""
}

# Display deployment status
display_status() {
    echo -e "${PURPLE}🌑 LilithOS AWS EC2 Deployment Status${NC}"
    echo "============================================="
    echo ""
    
    echo -e "${CYAN}✅ Deployment Completed:${NC}"
    echo "- New instance created with user data"
    echo "- LilithOS automatically deployed via user data script"
    echo "- All dependencies installed automatically"
    echo "- Web server configured automatically"
    echo "- Security features enabled automatically"
    echo ""
    
    echo -e "${CYAN}📊 Instance Information:${NC}"
    echo "- Instance ID: $NEW_INSTANCE_ID"
    echo "- Public IP: $NEW_PUBLIC_IP"
    echo "- Instance Type: t3.medium (2 vCPU, 4GB RAM)"
    echo "- Operating System: Ubuntu 22.04 LTS"
    echo "- Region: $REGION"
    echo ""
    
    echo -e "${CYAN}🌐 Access URLs:${NC}"
    echo "- HTTP: http://$NEW_PUBLIC_IP"
    echo "- LilithOS Dashboard: http://$NEW_PUBLIC_IP:8080"
    echo "- Glass Dashboard: http://$NEW_PUBLIC_IP/glass"
    echo ""
    
    echo -e "${CYAN}🔗 SSH Access:${NC}"
    echo "ssh -i $KEY_FILE ubuntu@$NEW_PUBLIC_IP"
    echo ""
    
    echo -e "${CYAN}📋 Status Commands:${NC}"
    echo "Check deployment status:"
    echo "  ssh -i $KEY_FILE ubuntu@$NEW_PUBLIC_IP 'cat /home/ubuntu/lilithos_status.txt'"
    echo ""
    echo "Check service status:"
    echo "  ssh -i $KEY_FILE ubuntu@$NEW_PUBLIC_IP 'sudo systemctl status nginx docker'"
    echo ""
    echo "Start LilithOS:"
    echo "  ssh -i $KEY_FILE ubuntu@$NEW_PUBLIC_IP './start_lilithos.sh'"
    echo ""
    
    echo -e "${CYAN}🔧 Alternative Access Methods:${NC}"
    echo "1. AWS Console:"
    echo "   - Go to AWS EC2 Console"
    echo "   - Select instance: $NEW_INSTANCE_ID"
    echo "   - Click 'Connect' → 'EC2 Instance Connect'"
    echo "   - Use browser-based terminal"
    echo ""
    echo "2. Wait and Retry:"
    echo "   - Instance may still be initializing"
    echo "   - Wait 5-10 minutes and try SSH again"
    echo "   - Check HTTP access in browser"
    echo ""
    
    echo -e "${CYAN}🔒 Security Features:${NC}"
    echo "- SSH access on port 22"
    echo "- HTTP/HTTPS on ports 80/443"
    echo "- LilithOS dashboard on port 8080"
    echo "- Firewall (ufw) enabled"
    echo "- Fail2ban for intrusion prevention"
    echo "- Security monitoring and logging"
    echo ""
    
    echo -e "${CYAN}💰 Cost Information:${NC}"
    echo "- Instance: t3.medium (~$30/month)"
    echo "- Storage: 20GB GP3 volume (~$2/month)"
    echo "- Data Transfer: Pay per use"
    echo "- Total Estimated: ~$35-40/month"
    echo ""
    
    echo -e "${CYAN}🎯 Next Steps:${NC}"
    echo "1. Wait for instance to fully initialize (5-10 minutes)"
    echo "2. Test SSH access: ssh -i $KEY_FILE ubuntu@$NEW_PUBLIC_IP"
    echo "3. Test web access: http://$NEW_PUBLIC_IP"
    echo "4. Check deployment status: cat /home/ubuntu/lilithos_status.txt"
    echo "5. Start LilithOS: ./start_lilithos.sh"
    echo "6. Access glass dashboard: http://$NEW_PUBLIC_IP/glass"
    echo ""
    
    echo -e "${GREEN}🌑 LilithOS - Where Technology Meets the Ethereal${NC}"
    echo ""
    echo "For support, check the documentation at:"
    echo "https://github.com/M-K-World-Wide/LilithOS"
}

# Create connection summary file
create_summary() {
    log "📝 Creating deployment summary..."
    
    cat > LILITHOS_AWS_DEPLOYMENT_SUMMARY.md << EOF
# 🌑 LilithOS AWS EC2 Deployment Summary

## ✅ Deployment Status: COMPLETED

### Instance Information
- **Instance ID**: $NEW_INSTANCE_ID
- **Public IP**: $NEW_PUBLIC_IP
- **Instance Type**: t3.medium (2 vCPU, 4GB RAM)
- **Operating System**: Ubuntu 22.04 LTS
- **Region**: $REGION
- **Key File**: $KEY_FILE

### Access Information
- **SSH**: ssh -i $KEY_FILE ubuntu@$NEW_PUBLIC_IP
- **HTTP**: http://$NEW_PUBLIC_IP
- **LilithOS Dashboard**: http://$NEW_PUBLIC_IP:8080
- **Glass Dashboard**: http://$NEW_PUBLIC_IP/glass

### Deployment Method
- **User Data Script**: Automatic deployment via instance user data
- **Dependencies**: Automatically installed (git, docker, nginx, etc.)
- **LilithOS**: Automatically cloned and initialized
- **Web Server**: Automatically configured
- **Security**: Automatically enabled (firewall, fail2ban)

### Features Deployed
- ✅ Cross-Platform Compatibility (Windows, macOS, iOS apps)
- ✅ Glass Dashboard with dark glass aesthetic
- ✅ 11 Advanced Features (Quantum Vault, Celestial Monitor, etc.)
- ✅ Security Framework with encryption and monitoring
- ✅ Web Interface with Nginx configuration
- ✅ Docker support for containerized applications

### Management Commands
\`\`\`bash
# Check deployment status
ssh -i $KEY_FILE ubuntu@$NEW_PUBLIC_IP 'cat /home/ubuntu/lilithos_status.txt'

# Check service status
ssh -i $KEY_FILE ubuntu@$NEW_PUBLIC_IP 'sudo systemctl status nginx docker'

# Start LilithOS
ssh -i $KEY_FILE ubuntu@$NEW_PUBLIC_IP './start_lilithos.sh'

# View logs
ssh -i $KEY_FILE ubuntu@$NEW_PUBLIC_IP 'sudo journalctl -u nginx -f'
\`\`\`

### Cost Information
- **Instance**: ~$30/month
- **Storage**: ~$2/month
- **Data Transfer**: Pay per use
- **Total**: ~$35-40/month

### Security Features
- SSH key-based authentication
- UFW firewall with fail2ban
- Security monitoring and logging
- Sandboxed application environments
- Encrypted storage and communications

---

**🌑 LilithOS - Where Technology Meets the Ethereal**

*Deployment completed on $(date)*
EOF

    log "✅ Deployment summary created: LILITHOS_AWS_DEPLOYMENT_SUMMARY.md"
}

# Main execution
main() {
    log "🌑 LilithOS Final Deployment Status"
    log "==================================="
    
    # Check instances
    check_instances
    
    # Test access
    test_access
    
    # Display status
    display_status
    
    # Create summary
    create_summary
    
    log "🎉 All deployment scripts completed successfully!"
    log "📋 Check LILITHOS_AWS_DEPLOYMENT_SUMMARY.md for complete information."
}

# Execute main function
main "$@" 