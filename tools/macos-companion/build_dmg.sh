#!/bin/bash
set -e

cd "$(dirname "$0")"

# Install dependencies
pip3 install -r requirements.txt

# Build .app with PyInstaller
pyinstaller pyinstaller.spec --noconfirm

# Create DMG (requires create-dmg: brew install create-dmg)
if ! command -v create-dmg &> /dev/null; then
  echo "Please install create-dmg: brew install create-dmg"
  exit 1
fi

create-dmg --volname "LilithOS Mac" --window-pos 200 120 --window-size 600 400 \
  --icon-size 120 --app-drop-link 400 200 \
  dist/LilithOS_Mac.app LilithOS_Mac.dmg

echo "LilithOS Mac DMG created: LilithOS_Mac.dmg" 