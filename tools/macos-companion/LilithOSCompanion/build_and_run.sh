#!/bin/bash
set -e

# Navigate to the project directory
cd "$(dirname "$0")"

# Clean previous build
xcodebuild clean -scheme LilithOSCompanion || true

# Build the app for Mac (Mac Catalyst)
xcodebuild -scheme LilithOSCompanion -destination 'platform=macOS' build

# Find the built .app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -type d -name 'LilithOSCompanion.app' | sort -r | head -n 1)

if [ -d "$APP_PATH" ]; then
  echo "Launching $APP_PATH..."
  open "$APP_PATH"
else
  echo "Build succeeded but .app not found. Please check Xcode build logs."
fi 