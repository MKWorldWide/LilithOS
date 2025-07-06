# 🚀 AWS Amplify Deployment Guide

## 📋 **Table of Contents**
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Deployment](#quick-deployment)
- [Detailed Setup](#detailed-setup)
- [Frontend Configuration](#frontend-configuration)
- [Backend Configuration](#backend-configuration)
- [Environment Variables](#environment-variables)
- [Custom Domain Setup](#custom-domain-setup)
- [Monitoring & Analytics](#monitoring--analytics)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)

---

## 🌑 **Overview**

This guide provides comprehensive instructions for deploying LilithOS to AWS Amplify, including both frontend and backend components. The deployment includes:

- **Frontend**: React + TypeScript + Vite + Ant Design
- **Backend**: Node.js + Express + Socket.IO + AWS Lambda
- **Database**: DynamoDB + AWS RDS
- **Authentication**: AWS Cognito
- **Storage**: AWS S3
- **CDN**: CloudFront
- **Monitoring**: CloudWatch + X-Ray

### 🎯 **Deployment Architecture**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Infrastructure │
│   (Amplify)     │◄──►│   (Lambda)      │◄──►│   (AWS Services) │
│                 │    │                 │    │                 │
│ • React App     │    │ • API Gateway   │    │ • DynamoDB      │
│ • Static Assets │    │ • Lambda Funcs  │    │ • S3 Storage    │
│ • CDN Cache     │    │ • Socket.IO     │    │ • CloudWatch    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## ✅ **Prerequisites**

### **AWS Account Setup**
1. **AWS Account**: Active AWS account with billing enabled
2. **IAM User**: User with appropriate permissions
3. **AWS CLI**: Installed and configured
4. **Amplify CLI**: Installed globally

### **Required Permissions**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "amplify:*",
        "lambda:*",
        "apigateway:*",
        "dynamodb:*",
        "s3:*",
        "cloudfront:*",
        "cognito:*",
        "cloudwatch:*",
        "iam:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### **Local Environment**
```bash
# Install Node.js (v18+)
node --version

# Install AWS CLI
aws --version

# Install Amplify CLI
npm install -g @aws-amplify/cli

# Configure AWS
aws configure
```

---

## 🚀 **Quick Deployment**

### **One-Command Deployment**
```bash
# Navigate to Amplify module
cd modules/features/ai-revenue-routing/amplify

# Run enhanced deployment script
./enhanced_deploy.sh full
```

### **Step-by-Step Quick Deploy**
```bash
# 1. Clone and setup
git clone https://github.com/lilithos/lilithos.git
cd lilithos/modules/features/ai-revenue-routing/amplify

# 2. Install dependencies
npm install

# 3. Configure environment
cp .env.example .env
# Edit .env with your AWS configuration

# 4. Deploy
npm run deploy

# 5. Access your app
# Frontend: https://main.d1234567890.amplifyapp.com
# Backend: https://api.lilithos.dev
```

---

## 🔧 **Detailed Setup**

### **1. Project Structure**
```
amplify/
├── src/                    # Frontend source code
│   ├── components/         # React components
│   ├── pages/             # Page components
│   ├── hooks/             # Custom hooks
│   ├── store/             # State management
│   ├── utils/             # Utility functions
│   └── types/             # TypeScript types
├── amplify/               # Amplify configuration
│   ├── backend/           # Backend resources
│   └── .config/           # Amplify config
├── public/                # Static assets
├── dist/                  # Build output
├── package.json           # Dependencies
├── amplify.yml           # Build configuration
└── aws-exports.js        # AWS configuration
```

### **2. Initialize Amplify Project**
```bash
# Initialize Amplify
amplify init

# Add authentication
amplify add auth

# Add API
amplify add api

# Add storage
amplify add storage

# Push to cloud
amplify push
```

### **3. Configure Build Settings**
```yaml
# amplify.yml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - npm ci
        - npm install -g @aws-amplify/cli
    build:
      commands:
        - npm run build
    postBuild:
      commands:
        - echo "Build completed successfully"
  artifacts:
    baseDirectory: dist
    files:
      - '**/*'
  cache:
    paths:
      - node_modules/**/*
```

---

## 🎨 **Frontend Configuration**

### **React App Setup**
```typescript
// src/App.tsx
import React from 'react';
import { Amplify } from 'aws-amplify';
import awsExports from './aws-exports';
import { BrowserRouter as Router } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

Amplify.configure(awsExports);

const queryClient = new QueryClient();

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Router>
        {/* Your app components */}
      </Router>
    </QueryClientProvider>
  );
}

export default App;
```

### **Vite Configuration**
```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          aws: ['aws-amplify'],
        },
      },
    },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
});
```

### **Environment Configuration**
```javascript
// src/config/environment.ts
export const config = {
  apiUrl: process.env.REACT_APP_API_URL || 'https://api.lilithos.dev',
  websocketUrl: process.env.REACT_APP_WEBSOCKET_URL || 'wss://api.lilithos.dev',
  environment: process.env.NODE_ENV || 'development',
  version: process.env.REACT_APP_VERSION || '3.0.0',
};
```

---

## ⚙️ **Backend Configuration**

### **Lambda Functions**
```javascript
// src/lambda/api-handler.js
const AWS = require('aws-sdk');
const { PrimalGenesisEngine } = require('./primal-genesis');

exports.handler = async (event) => {
  try {
    const engine = new PrimalGenesisEngine();
    const result = await engine.processRequest(event);
    
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify(result),
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: JSON.stringify({ error: error.message }),
    };
  }
};
```

### **API Gateway Configuration**
```yaml
# amplify/backend/api/lilithos-api/api-params.json
{
  "paths": {
    "/api/*": {
      "name": "/api/{proxy+}",
      "lambdaFunction": "lilithos-api-handler",
      "permissions": {
        "setting": "open"
      }
    }
  }
}
```

### **DynamoDB Tables**
```javascript
// src/models/User.js
const { DataTypes } = require('@aws-amplify/datastore');

const UserSchema = {
  id: {
    type: DataTypes.STRING,
    primaryKey: true,
  },
  username: {
    type: DataTypes.STRING,
    required: true,
  },
  email: {
    type: DataTypes.STRING,
    required: true,
  },
  createdAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
};

module.exports = UserSchema;
```

---

## 🔐 **Environment Variables**

### **Frontend Environment**
```bash
# .env.production
REACT_APP_API_URL=https://api.lilithos.dev
REACT_APP_WEBSOCKET_URL=wss://api.lilithos.dev
REACT_APP_AWS_REGION=us-east-1
REACT_APP_USER_POOLS_ID=us-east-1_xxxxxxxxx
REACT_APP_USER_POOLS_WEB_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
REACT_APP_OAUTH_DOMAIN=lilithos.auth.us-east-1.amazoncognito.com
```

### **Backend Environment**
```bash
# Lambda environment variables
DATABASE_URL=postgresql://user:pass@host:5432/lilithos
REDIS_URL=redis://host:6379
JWT_SECRET=your-jwt-secret
AWS_REGION=us-east-1
LOG_LEVEL=info
```

### **Amplify Environment Variables**
```bash
# Set in Amplify Console
amplify env add prod
amplify env checkout prod

# Or via CLI
aws amplify update-app --app-id d1234567890 --environment-variables '{"API_URL":"https://api.lilithos.dev"}'
```

---

## 🌐 **Custom Domain Setup**

### **1. Domain Configuration**
```bash
# Add custom domain
amplify domain add

# Configure DNS
aws amplify create-domain-association \
  --app-id d1234567890 \
  --domain-name api.lilithos.dev \
  --sub-domains api
```

### **2. SSL Certificate**
```bash
# Request SSL certificate
aws acm request-certificate \
  --domain-name *.lilithos.dev \
  --validation-method DNS
```

### **3. Route53 Configuration**
```yaml
# route53-config.yml
HostedZones:
  - Name: lilithos.dev
    ResourceRecordSets:
      - Name: api.lilithos.dev
        Type: A
        AliasTarget:
          DNSName: d1234567890.amplifyapp.com
          HostedZoneId: Z2O1EMRO9K5GLX
```

---

## 📊 **Monitoring & Analytics**

### **CloudWatch Setup**
```javascript
// src/utils/monitoring.js
const AWS = require('aws-sdk');
const cloudwatch = new AWS.CloudWatch();

class Monitoring {
  static async logMetric(namespace, metricName, value, unit = 'Count') {
    const params = {
      Namespace: namespace,
      MetricData: [{
        MetricName: metricName,
        Value: value,
        Unit: unit,
        Timestamp: new Date(),
      }],
    };
    
    return cloudwatch.putMetricData(params).promise();
  }
  
  static async logError(error, context = {}) {
    console.error('Error:', error, context);
    await this.logMetric('LilithOS/Errors', 'ErrorCount', 1);
  }
}

module.exports = Monitoring;
```

### **X-Ray Tracing**
```javascript
// src/utils/tracing.js
const AWSXRay = require('aws-xray-sdk');

AWSXRay.captureAWS(require('aws-sdk'));

const segment = new AWSXRay.Segment('LilithOS-API');

// Wrap your functions
const tracedFunction = AWSXRay.captureAsyncFunc('my-function', async () => {
  // Your function logic
});
```

### **Performance Monitoring**
```javascript
// src/components/PerformanceMonitor.jsx
import { useEffect } from 'react';

export const PerformanceMonitor = () => {
  useEffect(() => {
    // Monitor Core Web Vitals
    if ('web-vital' in window) {
      import('web-vitals').then(({ getCLS, getFID, getFCP, getLCP, getTTFB }) => {
        getCLS(console.log);
        getFID(console.log);
        getFCP(console.log);
        getLCP(console.log);
        getTTFB(console.log);
      });
    }
  }, []);
  
  return null;
};
```

---

## 🔧 **Troubleshooting**

### **Common Issues**

#### **1. Build Failures**
```bash
# Check build logs
amplify console

# Clear cache and rebuild
rm -rf node_modules package-lock.json
npm install
npm run build
```

#### **2. Lambda Timeout**
```javascript
// Increase timeout in amplify/backend/function/function-name/function-parameters.json
{
  "lambdaLayers": [],
  "timeout": 30
}
```

#### **3. CORS Issues**
```javascript
// Add CORS headers to Lambda response
return {
  statusCode: 200,
  headers: {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
  },
  body: JSON.stringify(result),
};
```

#### **4. Environment Variables Not Loading**
```bash
# Check environment variables
amplify env list

# Update environment variables
amplify env checkout prod
amplify push
```

### **Debug Commands**
```bash
# Check Amplify status
amplify status

# View logs
amplify console

# Check AWS resources
aws amplify list-apps
aws lambda list-functions
aws apigateway get-rest-apis
```

---

## 🚀 **Advanced Configuration**

### **Multi-Environment Setup**
```bash
# Create environments
amplify env add dev
amplify env add staging
amplify env add prod

# Switch environments
amplify env checkout dev
amplify push
```

### **CI/CD Pipeline**
```yaml
# .github/workflows/deploy.yml
name: Deploy to Amplify
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run build
      - uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      - run: aws amplify start-job --app-id ${{ secrets.AMPLIFY_APP_ID }} --branch-name main --job-type RELEASE
```

### **Custom Build Commands**
```bash
# scripts/build.sh
#!/bin/bash
echo "🚀 Starting LilithOS build process..."

# Install dependencies
npm ci

# Run tests
npm run test

# Build application
npm run build

# Optimize assets
npm run optimize

# Deploy to Amplify
amplify push

echo "✅ Build completed successfully!"
```

---

## 📞 **Support**

### **Resources**
- [AWS Amplify Documentation](https://docs.aws.amazon.com/amplify/)
- [Amplify CLI Reference](https://docs.amplify.aws/cli/)
- [React + Amplify Tutorial](https://docs.amplify.aws/start/q/integration/react/)

### **Community**
- [Amplify Discord](https://discord.gg/amplify)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/aws-amplify)
- [GitHub Issues](https://github.com/aws-amplify/amplify-js/issues)

---

**🌑 LilithOS** - *Advanced Operating System Framework with AWS Amplify Integration*

*Deployment Guide v3.0.0 - Ready for Production* 