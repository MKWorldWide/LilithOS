# 🔧 Scrypt Mining Framework - Troubleshooting Guide

This guide helps you resolve common issues with the Scrypt Mining Framework.

## 🚨 Quick Fixes

### **Frontend Not Loading**
```bash
# Stop all services
./start-mining-framework.sh stop

# Clear cache and restart
rm -rf node_modules/.vite
./start-mining-framework.sh start
```

### **Backend Not Responding**
```bash
# Check backend logs
./start-mining-framework.sh logs

# Restart backend only
./start-mining-framework.sh restart
```

### **Port Already in Use**
```bash
# Kill processes on ports
lsof -ti:3000 | xargs kill -9
lsof -ti:3001 | xargs kill -9
lsof -ti:3002 | xargs kill -9

# Restart framework
./start-mining-framework.sh start
```

---

## 🔍 Common Issues & Solutions

### **1. Ant Design Icons Import Errors**

**Error:** `SyntaxError: The requested module doesn't provide an export named: 'TrendingUpOutlined'`

**Solution:**
```bash
# Replace invalid icon imports with valid ones
# TrendingUpOutlined → ArrowUpOutlined
# TrendingDownOutlined → ArrowDownOutlined
```

**Fixed in:** `src/pages/MiningAnalytics.tsx`

### **2. TypeScript Compilation Errors**

**Error:** `TS6133: 'variable' is declared but its value is never read`

**Solution:**
```bash
# Remove unused imports and variables
npm run type-check
# Fix the reported issues by removing unused code
```

### **3. Vite Not Found**

**Error:** `sh: vite: command not found`

**Solution:**
```bash
# Install dependencies
npm install

# Or install Vite globally
npm install -g vite
```

### **4. Express Module Not Found**

**Error:** `Cannot find module 'express'`

**Solution:**
```bash
# Install backend dependencies
cd backend && npm install
```

### **5. Mining Controller Not Found**

**Error:** `Cannot find module '/path/to/mining-controller.js'`

**Solution:**
```bash
# Ensure you're in the correct directory
cd /Users/sovereign/Projects/LilithOS

# Check if mining-controller.js exists
ls -la backend/mining-controller.js
```

### **6. Browser Console Errors**

#### **SES/Lockdown Warnings**
```
SES The 'dateTaming' option is deprecated...
```

**Cause:** Browser extension (MetaMask, etc.)
**Solution:** Ignore - not from your app

#### **Service Worker Registration Error**
```
SW registration failed: DOMException: The operation is insecure
```

**Cause:** Browser security on localhost
**Solution:** Ignore for development

#### **Source Map Errors**
```
Source map error: Error: JSON.parse: unexpected character
```

**Cause:** DevTools extension
**Solution:** Ignore - not critical

---

## 🛠️ Advanced Troubleshooting

### **1. Performance Issues**

**Symptoms:** Slow loading, high CPU usage

**Solutions:**
```bash
# Check system resources
top
htop

# Monitor memory usage
free -h

# Check disk space
df -h

# Restart with reduced threads
export DEFAULT_THREADS=2
./start-mining-framework.sh restart
```

### **2. Network Connectivity Issues**

**Symptoms:** Can't connect to mining pools, API timeouts

**Solutions:**
```bash
# Test internet connectivity
ping google.com

# Check DNS resolution
nslookup prohashing.com

# Test specific ports
telnet prohashing.com 3333

# Check firewall settings
sudo ufw status
```

### **3. Database Issues**

**Symptoms:** Data not persisting, database errors

**Solutions:**
```bash
# Check database file
ls -la data/mining.db

# Recreate database
rm data/mining.db
./start-mining-framework.sh restart
```

### **4. Log Analysis**

**View logs:**
```bash
# All logs
./start-mining-framework.sh logs

# Backend logs only
tail -f mining-controller.log

# Frontend logs only
tail -f frontend.log

# Real-time monitoring
tail -f mining-controller.log | grep -E "(ERROR|WARN|INFO)"
```

**Common log patterns:**
- `ERROR`: Critical issues requiring immediate attention
- `WARN`: Potential issues that should be monitored
- `INFO`: Normal operation information

---

## 🔧 System-Specific Issues

### **macOS Issues**

#### **Permission Denied**
```bash
# Fix script permissions
chmod +x start-mining-framework.sh

# Fix directory permissions
sudo chown -R $(whoami) /Users/sovereign/Projects/LilithOS
```

#### **Port Already in Use**
```bash
# Find process using port
lsof -i :3000
lsof -i :3001

# Kill process
kill -9 <PID>
```

### **Linux Issues**

#### **Missing Dependencies**
```bash
# Install system dependencies
sudo apt update
sudo apt install nodejs npm git curl

# Or for CentOS/RHEL
sudo yum install nodejs npm git curl
```

#### **Firewall Issues**
```bash
# Allow ports through firewall
sudo ufw allow 3000
sudo ufw allow 3001
sudo ufw allow 3002
```

### **Windows Issues**

#### **Path Issues**
```bash
# Use Windows Subsystem for Linux (WSL)
# Or ensure paths use correct separators
```

#### **Permission Issues**
```bash
# Run as Administrator
# Or adjust folder permissions
```

---

## 🚀 Performance Optimization

### **1. Frontend Optimization**

**Enable production build:**
```bash
npm run build
npm run preview
```

**Optimize Vite configuration:**
```javascript
// vite.config.ts
export default defineConfig({
  build: {
    minify: 'terser',
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          antd: ['antd']
        }
      }
    }
  }
})
```

### **2. Backend Optimization**

**Enable compression:**
```javascript
// backend/mining-controller.js
app.use(compression());
```

**Optimize database queries:**
```javascript
// Use connection pooling
// Implement caching
// Add database indexes
```

### **3. System Optimization**

**Increase file descriptors:**
```bash
# macOS
ulimit -n 65536

# Linux
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf
```

**Optimize Node.js:**
```bash
# Use Node.js 18+ for better performance
# Enable garbage collection optimization
export NODE_OPTIONS="--max-old-space-size=4096"
```

---

## 📞 Getting Help

### **1. Self-Diagnosis**

**Check system status:**
```bash
./start-mining-framework.sh status
./start-mining-framework.sh health
```

**Verify installation:**
```bash
# Check Node.js version
node --version

# Check npm version
npm --version

# Check dependencies
npm list --depth=0
```

### **2. Debug Mode**

**Enable debug logging:**
```bash
# Set debug environment variable
export DEBUG=*
./start-mining-framework.sh start
```

**Enable verbose logging:**
```bash
# Edit .env file
LOG_LEVEL=debug
DEBUG=true
```

### **3. Community Support**

**GitHub Issues:**
- Search existing issues
- Create new issue with detailed information
- Include logs and error messages

**Discord/Telegram:**
- Join community channels
- Share error logs
- Ask for help with specific issues

---

## 📋 Troubleshooting Checklist

### **Before Starting**
- [ ] Node.js 18+ installed
- [ ] npm 9+ installed
- [ ] Git repository cloned
- [ ] Dependencies installed
- [ ] Environment configured

### **Startup Issues**
- [ ] Check system requirements
- [ ] Verify port availability
- [ ] Check file permissions
- [ ] Review startup logs
- [ ] Test individual services

### **Runtime Issues**
- [ ] Monitor system resources
- [ ] Check network connectivity
- [ ] Review application logs
- [ ] Test API endpoints
- [ ] Verify database connections

### **Performance Issues**
- [ ] Monitor CPU usage
- [ ] Check memory consumption
- [ ] Review disk I/O
- [ ] Analyze network traffic
- [ ] Optimize configuration

---

## 🔄 Recovery Procedures

### **1. Complete Reset**

```bash
# Stop all services
./start-mining-framework.sh stop

# Clear all data
rm -rf node_modules
rm -rf backend/node_modules
rm -f *.log
rm -f *.pid

# Reinstall everything
./start-mining-framework.sh setup
./start-mining-framework.sh start
```

### **2. Database Recovery**

```bash
# Backup current database
cp data/mining.db data/mining.db.backup

# Restore from backup
cp data/mining.db.backup data/mining.db

# Or start fresh
rm data/mining.db
./start-mining-framework.sh restart
```

### **3. Configuration Recovery**

```bash
# Reset to defaults
cp .env.example .env

# Restart with default config
./start-mining-framework.sh restart
```

---

**💡 Pro Tip:** Always check the logs first! Most issues can be diagnosed by reviewing the application logs.

**🔐 Scrypt Mining Framework v1.0.0** - Advanced Troubleshooting Made Simple 