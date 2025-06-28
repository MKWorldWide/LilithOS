#!/bin/bash
set -e

cd "$(dirname "$0")/../LilithOS"

# Prefer the connected iPhone if available
IPHONE_UDID="00008110-001E60E03644801E"

if xcrun xctrace list devices | grep -q "$IPHONE_UDID"; then
  echo "Building and launching on connected iPhone ($IPHONE_UDID)"
  xcodebuild -scheme LilithOS -project LilithOS.xcodeproj -destination "id=$IPHONE_UDID" clean build
  APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -type d -name "*.app" | grep LilithOS | head -n1)
  if [ -z "$APP_PATH" ]; then
    echo "App build not found."
    exit 1
  fi
  xcrun simctl install "$IPHONE_UDID" "$APP_PATH" || true
  xcrun simctl launch "$IPHONE_UDID" com.MKWW.LilithOS || true
  echo "App should now be running on your iPhone."
  exit 0
fi

# Fallback to first available iOS Simulator device (iPhone preferred)
DEVICE=$(xcrun simctl list devices available | grep -m1 "iPhone" | awk -F '[()]' '{print $2}')

if [ -z "$DEVICE" ]; then
  echo "No available iOS Simulator device found."
  exit 1
fi

echo "Building and launching on simulator device: $DEVICE"

xcodebuild -scheme LilithOS -project LilithOS.xcodeproj -destination "id=$DEVICE" clean build

# Boot the simulator and install the app
xcrun simctl boot "$DEVICE" || true
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -type d -name "*.app" | grep LilithOS | head -n1)
if [ -z "$APP_PATH" ]; then
  echo "App build not found."
  exit 1
fi
xcrun simctl install "$DEVICE" "$APP_PATH"
xcrun simctl launch "$DEVICE" com.MKWW.LilithOS 