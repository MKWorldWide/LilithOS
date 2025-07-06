#!/bin/bash

# 🚀 Enhanced AI Revenue Routing System - Deployment Script
# 
# Divine Architect Revenue Routing System with TrafficFlou Integration
# Complete deployment script for GitHub and AWS Amplify
# 
# @author Divine Architect + TrafficFlou Team
# @version 3.0.0
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
PROJECT_NAME="lilithos-divine-treasury-trafficflou"
VERSION="3.0.0"
DEPLOYMENT_TYPE="${1:-full}" # full, github, amplify, or test

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Header
echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    🚀 Enhanced AI Revenue Routing System     ║"
echo "║                Divine Architect + TrafficFlou Integration    ║"
echo "║                        Version $VERSION                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check prerequisites
check_prerequisites() {
    log "🔍 Checking prerequisites..."
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        error "Node.js is not installed. Please install Node.js 18+"
    fi
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        error "npm is not installed. Please install npm 9+"
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        error "Git is not installed. Please install Git"
    fi
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        warn "AWS CLI is not installed. Amplify deployment will be skipped."
    fi
    
    # Check Amplify CLI
    if ! command -v amplify &> /dev/null; then
        warn "Amplify CLI is not installed. Install with: npm install -g @aws-amplify/cli"
    fi
    
    log "✅ Prerequisites check completed"
}

# Clean and prepare
clean_and_prepare() {
    log "🧹 Cleaning and preparing build environment..."
    
    # Remove old build artifacts
    rm -rf dist/
    rm -rf build/
    rm -rf node_modules/
    rm -rf .amplify/
    
    # Clean npm cache
    npm cache clean --force
    
    log "✅ Clean and prepare completed"
}

# Install dependencies
install_dependencies() {
    log "📦 Installing dependencies..."
    
    # Install npm dependencies
    npm ci
    
    # Install Python dependencies if requirements file exists
    if [ -f "requirements_amplify.txt" ]; then
        log "🐍 Installing Python dependencies..."
        pip install -r requirements_amplify.txt
    fi
    
    log "✅ Dependencies installed"
}

# Build application
build_application() {
    log "🏗️ Building application..."
    
    # Build React application
    npm run build
    
    # Check if build was successful
    if [ ! -d "dist" ]; then
        error "Build failed - dist directory not found"
    fi
    
    log "✅ Application built successfully"
}

# Run tests
run_tests() {
    log "🧪 Running tests..."
    
    # Run npm tests
    npm test -- --passWithNoTests
    
    log "✅ Tests completed"
}

# Prepare for GitHub
prepare_github() {
    log "📚 Preparing for GitHub deployment..."
    
    # Create .gitignore if it doesn't exist
    if [ ! -f ".gitignore" ]; then
        cat > .gitignore << EOF
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Build outputs
dist/
build/
.next/
out/

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# IDE files
.vscode/
.idea/
*.swp
*.swo

# OS files
.DS_Store
Thumbs.db

# Logs
logs/
*.log

# Runtime data
pids/
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/

# Amplify
.amplify/

# AWS
.aws/
aws-exports.js

# Temporary files
tmp/
temp/
EOF
    fi
    
    # Create README if it doesn't exist
    if [ ! -f "README.md" ]; then
        cat > README.md << 'EOF'
# 🚀 Enhanced AI Revenue Routing System

**Divine Architect Revenue Routing System with TrafficFlou Integration**

## 🌟 Overview

This is the enhanced AI revenue routing system that combines the Divine Architect Revenue Routing System with TrafficFlou's advanced serverless infrastructure.

## 🚀 Features

- **Advanced Revenue Routing**: AI-powered revenue distribution
- **TrafficFlou Integration**: Serverless traffic generation and analytics
- **LilithOS Process Management**: Advanced optimization and monitoring
- **Primal Genesis Engine**: Audit and synchronization system
- **Real-time Dashboard**: Comprehensive monitoring interface

## 📦 Installation

```bash
npm install
npm run build
npm start
```

## 🚀 Deployment

```bash
./enhanced_deploy.sh full
```

## 📄 License

LilithOS License
EOF
    fi
    
    log "✅ GitHub preparation completed"
}

# Deploy to GitHub
deploy_github() {
    log "📤 Deploying to GitHub..."
    
    # Check if git repository exists
    if [ ! -d ".git" ]; then
        log "🔧 Initializing Git repository..."
        git init
        git add .
        git commit -m "🚀 Initial commit: Enhanced AI Revenue Routing System v$VERSION"
    else
        # Add all changes
        git add .
        
        # Check if there are changes to commit
        if git diff --staged --quiet; then
            log "📝 No changes to commit"
        else
            git commit -m "🚀 Update: Enhanced AI Revenue Routing System v$VERSION"
        fi
    fi
    
    # Check if remote exists
    if ! git remote get-url origin &> /dev/null; then
        warn "No remote repository configured. Please add your GitHub repository:"
        warn "git remote add origin https://github.com/yourusername/your-repo.git"
        return
    fi
    
    # Push to GitHub
    git push origin main || git push origin master
    
    log "✅ GitHub deployment completed"
}

# Prepare for Amplify
prepare_amplify() {
    log "☁️ Preparing for AWS Amplify deployment..."
    
    # Create aws-exports.js if it doesn't exist
    if [ ! -f "aws-exports.js" ]; then
        cat > aws-exports.js << 'EOF'
const awsmobile = {
    "aws_project_region": "us-east-1",
    "aws_cognito_identity_pool_id": "us-east-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "aws_cognito_region": "us-east-1",
    "aws_user_pools_id": "us-east-1_xxxxxxxxx",
    "aws_user_pools_web_client_id": "xxxxxxxxxxxxxxxxxxxxxxxxxx",
    "oauth": {},
    "aws_cognito_username_attributes": [],
    "aws_cognito_social_providers": [],
    "aws_cognito_signup_attributes": [],
    "aws_cognito_mfa_configuration": "OFF",
    "aws_cognito_mfa_types": [],
    "aws_cognito_password_protection_settings": {
        "passwordPolicyMinLength": 8,
        "passwordPolicyCharacters": []
    },
    "aws_cognito_verification_mechanisms": []
};

export default awsmobile;
EOF
        warn "Created placeholder aws-exports.js. Please configure with your actual AWS settings."
    fi
    
    log "✅ Amplify preparation completed"
}

# Deploy to Amplify
deploy_amplify() {
    log "☁️ Deploying to AWS Amplify..."
    
    # Check if Amplify CLI is available
    if ! command -v amplify &> /dev/null; then
        error "Amplify CLI is not installed. Install with: npm install -g @aws-amplify/cli"
    fi
    
    # Check if AWS CLI is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS CLI is not configured. Please run 'aws configure' first."
    fi
    
    # Initialize Amplify if not already initialized
    if [ ! -d ".amplify" ]; then
        log "🔧 Initializing Amplify..."
        amplify init --yes
    fi
    
    # Add hosting if not already added
    if ! amplify status | grep -q "Hosting"; then
        log "🌐 Adding hosting..."
        amplify add hosting --yes
    fi
    
    # Push to Amplify
    log "📤 Pushing to Amplify..."
    amplify push --yes
    
    # Publish
    log "🚀 Publishing to Amplify..."
    amplify publish --yes
    
    log "✅ Amplify deployment completed"
}

# Create deployment summary
create_summary() {
    log "📋 Creating deployment summary..."
    
    cat > DEPLOYMENT_SUMMARY.md << EOF
# 🚀 Enhanced AI Revenue Routing System - Deployment Summary

**Deployment Date:** $(date)
**Version:** $VERSION
**Deployment Type:** $DEPLOYMENT_TYPE

## ✅ Completed Steps

$(case $DEPLOYMENT_TYPE in
    "full")
        echo "- Prerequisites check"
        echo "- Clean and prepare"
        echo "- Dependencies installation"
        echo "- Application build"
        echo "- Tests execution"
        echo "- GitHub preparation"
        echo "- GitHub deployment"
        echo "- Amplify preparation"
        echo "- Amplify deployment"
        ;;
    "github")
        echo "- Prerequisites check"
        echo "- Clean and prepare"
        echo "- Dependencies installation"
        echo "- Application build"
        echo "- Tests execution"
        echo "- GitHub preparation"
        echo "- GitHub deployment"
        ;;
    "amplify")
        echo "- Prerequisites check"
        echo "- Clean and prepare"
        echo "- Dependencies installation"
        echo "- Application build"
        echo "- Tests execution"
        echo "- Amplify preparation"
        echo "- Amplify deployment"
        ;;
    "test")
        echo "- Prerequisites check"
        echo "- Clean and prepare"
        echo "- Dependencies installation"
        echo "- Application build"
        echo "- Tests execution"
        ;;
esac)

## 🎯 Next Steps

1. **Configure AWS Settings**: Update aws-exports.js with your actual AWS configuration
2. **Set Environment Variables**: Configure necessary environment variables
3. **Test Functionality**: Verify all features are working correctly
4. **Monitor Performance**: Set up monitoring and alerting
5. **Scale as Needed**: Adjust resources based on usage

## 🔧 Configuration Files

- **package.json**: Application dependencies and scripts
- **vite.config.ts**: Build configuration
- **tsconfig.json**: TypeScript configuration
- **amplify.yml**: Amplify build configuration
- **aws-exports.js**: AWS configuration (needs to be updated)

## 📊 System Status

- **Frontend**: React + TypeScript + Vite + Ant Design
- **Backend**: Node.js + Express + Socket.IO
- **Database**: DynamoDB (via AWS)
- **Hosting**: AWS Amplify
- **CI/CD**: GitHub Actions + Amplify

## 🚀 Quick Start

\`\`\`bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Deploy
./enhanced_deploy.sh full
\`\`\`

---
**Generated by Enhanced AI Revenue Routing System v$VERSION**
EOF
    
    log "✅ Deployment summary created"
}

# Main deployment function
main() {
    case $DEPLOYMENT_TYPE in
        "full")
            log "🚀 Starting full deployment (GitHub + Amplify)..."
            check_prerequisites
            clean_and_prepare
            install_dependencies
            build_application
            run_tests
            prepare_github
            deploy_github
            prepare_amplify
            deploy_amplify
            ;;
        "github")
            log "📚 Starting GitHub deployment..."
            check_prerequisites
            clean_and_prepare
            install_dependencies
            build_application
            run_tests
            prepare_github
            deploy_github
            ;;
        "amplify")
            log "☁️ Starting Amplify deployment..."
            check_prerequisites
            clean_and_prepare
            install_dependencies
            build_application
            run_tests
            prepare_amplify
            deploy_amplify
            ;;
        "test")
            log "🧪 Starting test deployment..."
            check_prerequisites
            clean_and_prepare
            install_dependencies
            build_application
            run_tests
            ;;
        *)
            error "Invalid deployment type. Use: full, github, amplify, or test"
            ;;
    esac
    
    create_summary
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    🎉 Deployment Completed!                  ║"
    echo "║                Enhanced AI Revenue Routing System            ║"
    echo "║                        Version $VERSION                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log "📋 Deployment summary saved to DEPLOYMENT_SUMMARY.md"
    log "🚀 System is ready for use!"
}

# Run main function
main "$@" 