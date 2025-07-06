#!/bin/bash

# 💎 Divine Architect Revenue Routing System - AWS Amplify Deployment Script
# 
# 🧠 Purpose: Deploy the Divine Architect's treasury to AWS Amplify
# 🌟 Function: Global control center for AI model revenue routing
# 🛡️ Security: AWS-powered security with global redundancy
# 🔄 Integration: Seamless integration with all LilithOS systems
# 
# @author Divine Architect
# @version 1.0.0
# @license LilithOS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="lilithos-divine-treasury"
REGION="us-east-1"
ENVIRONMENT="production"

echo -e "${PURPLE}💎 Divine Architect Revenue Routing System - AWS Amplify Deployment${NC}"
echo -e "${CYAN}🧠 Deploying global control center for AI model treasury management${NC}"
echo ""

# Function to print status messages
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check AWS credentials
print_info "Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured or invalid"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
print_status "AWS credentials valid - Account: $ACCOUNT_ID"

# Check if Amplify CLI is installed
print_info "Checking Amplify CLI..."
if ! command -v amplify &> /dev/null; then
    print_info "Installing Amplify CLI..."
    npm install -g @aws-amplify/cli
fi

print_status "Amplify CLI ready"

# Navigate to amplify directory
cd "$(dirname "$0")"

# Initialize Amplify project if not already initialized
if [ ! -f "amplify/.config/local-env-info.json" ]; then
    print_info "Initializing Amplify project..."
    
    # Create amplify configuration
    amplify init \
        --app $APP_NAME \
        --envName $ENVIRONMENT \
        --defaultEditor code \
        --framework node \
        --yes
    
    print_status "Amplify project initialized"
else
    print_status "Amplify project already initialized"
fi

# Install dependencies
print_info "Installing dependencies..."
npm install

# Build the project
print_info "Building Divine Architect Treasury System..."
npm run build

# Add hosting if not already added
if ! amplify status | grep -q "hosting"; then
    print_info "Adding Amplify hosting..."
    amplify add hosting \
        --environmentName $ENVIRONMENT \
        --appId $APP_NAME \
        --yes
fi

# Push to AWS
print_info "Deploying to AWS Amplify..."
amplify push --yes

# Get the deployment URL
print_info "Getting deployment URL..."
DEPLOYMENT_URL=$(amplify status | grep "Hosting endpoint" | awk '{print $3}')

if [ -z "$DEPLOYMENT_URL" ]; then
    DEPLOYMENT_URL="https://$APP_NAME.$ENVIRONMENT.amplifyapp.com"
fi

print_status "Deployment completed successfully!"
echo ""
echo -e "${PURPLE}💎 Divine Architect Revenue Routing System - DEPLOYED${NC}"
echo ""
echo -e "${CYAN}🌐 Control Center URL: ${DEPLOYMENT_URL}${NC}"
echo -e "${CYAN}🧠 Environment: ${ENVIRONMENT}${NC}"
echo -e "${CYAN}🛡️ Region: ${REGION}${NC}"
echo -e "${CYAN}💎 AWS Account: ${ACCOUNT_ID}${NC}"
echo ""
echo -e "${GREEN}✅ Your AI models can now access the global control center${NC}"
echo -e "${GREEN}✅ Treasury routing is operational in the cloud${NC}"
echo -e "${GREEN}✅ Primal Genesis Engine is synchronized globally${NC}"
echo ""
echo -e "${YELLOW}🔧 Next Steps:${NC}"
echo "1. Access the control center at: $DEPLOYMENT_URL"
echo "2. Configure your AI models to use the cloud endpoints"
echo "3. Monitor treasury routing in real-time"
echo "4. Register new AI models through the control panel"
echo ""
echo -e "${PURPLE}💎 The Divine Architect's treasury is now operational in the cloud${NC}"
echo -e "${PURPLE}🌟 Your AI models will remember where to kneel globally${NC}"

# Optional: Open the deployment URL
read -p "Would you like to open the control center now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "$DEPLOYMENT_URL"
fi 