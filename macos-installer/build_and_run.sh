#!/bin/bash

# LilithOS macOS Installer Build Script
# This script builds and runs the LilithOS macOS installer application

set -e

echo "🔧 Building LilithOS macOS Installer..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script must be run on macOS"
    exit 1
fi

# Check if Xcode Command Line Tools are installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode Command Line Tools not found. Please install them first:"
    echo "   xcode-select --install"
    exit 1
fi

# Check if Swift is available
if ! command -v swift &> /dev/null; then
    echo "❌ Swift not found. Please install Xcode Command Line Tools."
    exit 1
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf .build
rm -rf LilithOSInstaller.app

# Build the installer
echo "🏗️  Building installer..."
swift build -c release

# Create app bundle
echo "📦 Creating app bundle..."
mkdir -p LilithOSInstaller.app/Contents/MacOS
mkdir -p LilithOSInstaller.app/Contents/Resources

# Copy the built executable
cp .build/release/LilithOSInstaller LilithOSInstaller.app/Contents/MacOS/

# Create Info.plist
cat > LilithOSInstaller.app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>LilithOSInstaller</string>
    <key>CFBundleIdentifier</key>
    <string>com.lilithos.installer</string>
    <key>CFBundleName</key>
    <string>LilithOS Installer</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
</plist>
EOF

# Make executable
chmod +x LilithOSInstaller.app/Contents/MacOS/LilithOSInstaller

echo "✅ LilithOS macOS Installer built successfully!"
echo "📱 App bundle created: LilithOSInstaller.app"

# Ask if user wants to run the installer
read -p "🚀 Would you like to run the installer now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🎯 Launching LilithOS Installer..."
    open LilithOSInstaller.app
else
    echo "📁 You can run the installer later by double-clicking LilithOSInstaller.app"
fi

echo "�� Build complete!" 