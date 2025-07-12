#!/bin/bash

# Scrypt Mining Framework - Test Script

echo "🧪 Testing mining setup..."

# Test miner binaries
echo "Testing miner binaries..."

if [ -f "cpuminer-multi-mac" ] || [ -f "cpuminer-multi-linux" ] || [ -f "cpuminer-multi-win.exe" ]; then
    echo "✅ cpuminer-multi found"
else
    echo "❌ cpuminer-multi not found"
fi

if [ -f "xmrig-mac" ] || [ -f "xmrig-linux" ] || [ -f "xmrig-win.exe" ]; then
    echo "✅ XMRig found"
else
    echo "❌ XMRig not found"
fi

# Test configuration files
echo "Testing configuration files..."

if [ -f "pools.json" ]; then
    echo "✅ pools.json found"
else
    echo "❌ pools.json not found"
fi

if [ -f "miner-config.json" ]; then
    echo "✅ miner-config.json found"
else
    echo "❌ miner-config.json not found"
fi

echo "🧪 Test completed!"
