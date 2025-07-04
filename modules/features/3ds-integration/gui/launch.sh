#!/bin/bash

# 🌑 LilithOS 3DS Integration GUI Launcher
# Enhanced with TWiLight Menu++ Support

echo "🌑 LilithOS 3DS Integration - Advanced GUI"
echo "=========================================="

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is required but not installed."
    echo "Please install Python3 to run the GUI."
    exit 1
fi

# Check for required Python packages
echo "🔍 Checking dependencies..."

# Function to check and install package
check_package() {
    python3 -c "import $1" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "⚠️  Package '$1' not found. Installing..."
        pip3 install $1
    else
        echo "✅ $1 - OK"
    fi
}

# Check required packages
check_package "tkinter"
check_package "yaml"
check_package "requests"
check_package "ftplib"

# Set up environment
export PYTHONPATH="${PYTHONPATH}:$(pwd)/.."

# Determine which GUI to launch
if [ -f "advanced_3ds_gui.py" ]; then
    echo "🚀 Launching Advanced 3DS GUI with TWiLight Menu++ Support..."
    python3 advanced_3ds_gui.py
elif [ -f "lilithos_3ds_gui.py" ]; then
    echo "🚀 Launching Standard 3DS GUI..."
    python3 lilithos_3ds_gui.py
else
    echo "❌ No GUI file found."
    echo "Available options:"
    echo "  - advanced_3ds_gui.py (TWiLight Menu++ support)"
    echo "  - lilithos_3ds_gui.py (Standard R4 support)"
    exit 1
fi 