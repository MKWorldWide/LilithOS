#!/bin/bash
set -e

# Find the latest built LilithOSCompanion.app in DerivedData
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -type d -name 'LilithOSCompanion.app' | sort -r | head -n 1)

if [ ! -d "$APP_PATH" ]; then
  echo "LilithOSCompanion.app not found. Please build the app in Xcode first."
  exit 1
fi

echo "Found app at: $APP_PATH"

# Create DMG (requires create-dmg: brew install create-dmg)
if ! command -v create-dmg &> /dev/null; then
  echo "Please install create-dmg: brew install create-dmg"
  exit 1
fi

create-dmg --volname "LilithOS Companion" --window-pos 200 120 --window-size 600 400 \
  --icon-size 120 --app-drop-link 400 200 \
  "$APP_PATH" LilithOSCompanion.dmg

echo "LilithOSCompanion.dmg created!" 