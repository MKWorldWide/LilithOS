#!/bin/bash

# Colors for output
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🌑 Building LilithOS...${NC}"

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed. Please install Xcode from the App Store."
    exit 1
fi

# Check if we're in the right directory
if [ ! -d "LilithOS.xcodeproj" ]; then
    echo "❌ Please run this script from the LilithOS directory."
    exit 1
fi

# Generate app icons
echo -e "${PURPLE}🎨 Generating app icons...${NC}"
./scripts/generate_icons.sh

# Build the project
echo -e "${PURPLE}⚡ Building project...${NC}"
xcodebuild -scheme LilithOS -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 14' build

# Check if build was successful
if [ $? -eq 0 ]; then
    echo -e "${PURPLE}✨ Build successful!${NC}"
    echo -e "${PURPLE}🚀 To run the app:${NC}"
    echo "1. Open LilithOS.xcodeproj in Xcode"
    echo "2. Select your target device (iPhone or Simulator)"
    echo "3. Click the Run button (▶️) or press Cmd+R"
    echo ""
    echo -e "${PURPLE}🌌 Welcome to LilithOS${NC}"
else
    echo "❌ Build failed. Please check the error messages above."
    exit 1
fi 