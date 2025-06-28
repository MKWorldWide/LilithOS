#!/bin/bash

# Create icons directory if it doesn't exist
mkdir -p LilithOS/Resources/Assets.xcassets/AppIcon.appiconset

# Install required tools if not present
if ! command -v convert &> /dev/null; then
    echo "Installing ImageMagick..."
    brew install imagemagick
fi

if ! command -v rsvg-convert &> /dev/null; then
    echo "Installing librsvg..."
    brew install librsvg
fi

# Convert SVG to PNG with different sizes
echo "Generating app icons..."

# iPhone icons
rsvg-convert -w 40 -h 40 LilithOS/Resources/Assets.xcassets/AppIcon.appiconset/Icon.svg > LilithOS/Resources/Assets.xcassets/AppIcon.appiconset/Icon-40.png
rsvg-convert -w 60 -h 60 LilithOS/Resources/Assets.xcassets/AppIcon.appiconset/Icon.svg > LilithOS/Resources/Assets.xcassets/AppIcon.appiconset/Icon-60.png
rsvg-convert -w 58 -h 58 LilithOS/Resources/Assets.xcassets/AppIcon.appiconset/Icon.svg > LilithOS/Resources/Assets.xcassets/AppIcon.appiconset/Icon-58.png
rsvg-convert -w 87 -h 87 LilithOS/Resources/Assets.xcassets/AppIcon.appiconset/Icon.svg > LilithOS/Resources/Assets.xcassets/AppIcon.appiconset/Icon-87.png
rsvg-convert -w 80 -h 80 LilithOS/Resources/Assets.xcassets/AppIcon.appiconset/Icon.svg > LilithOS/Resources/Assets.xcassets/AppIcon.appiconset/Icon-80.png
rsvg-convert -w 120 -h 120 LilithOS/Resources/Assets.xcassets/AppIcon.appiconset/Icon.svg > LilithOS/Resources/Assets.xcassets/AppIcon.appiconset/Icon-120.png
rsvg-convert -w 180 -h 180 LilithOS/Resources/Assets.xcassets/AppIcon.appiconset/Icon.svg > LilithOS/Resources/Assets.xcassets/AppIcon.appiconset/Icon-180.png

# App Store icon
rsvg-convert -w 1024 -h 1024 LilithOS/Resources/Assets.xcassets/AppIcon.appiconset/Icon.svg > LilithOS/Resources/Assets.xcassets/AppIcon.appiconset/Icon-1024.png

echo "App icons generated successfully!" 