#!/bin/bash

# Scrypt Mining Framework - Quick Start Script

echo "🔐 Starting Scrypt Mining Framework..."

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "⚠️  .env file not found. Please copy .env.example to .env and configure your settings."
    exit 1
fi

# Start the mining controller
echo "🚀 Starting mining controller..."
node mining-controller.js
