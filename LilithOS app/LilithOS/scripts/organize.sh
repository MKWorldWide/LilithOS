#!/bin/bash

# Colors for output
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🌑 Reorganizing LilithOS...${NC}"

# Create temporary directory
TEMP_DIR="temp_lilithos"
mkdir -p $TEMP_DIR

# Move all files from nested LilithOS directory if it exists
if [ -d "LilithOS" ]; then
    echo -e "${PURPLE}📦 Moving files from nested directory...${NC}"
    mv LilithOS/* $TEMP_DIR/ 2>/dev/null
    rm -rf LilithOS
fi

# Create proper directory structure
echo -e "${PURPLE}📁 Creating directory structure...${NC}"
mkdir -p Sources/{App,Models,Views,Utils}
mkdir -p Resources/Assets.xcassets/AppIcon.appiconset
mkdir -p Tests

# Move files to their proper locations
echo -e "${PURPLE}🔄 Organizing files...${NC}"

# Move Swift files
mv $TEMP_DIR/Sources/App/* Sources/App/ 2>/dev/null
mv $TEMP_DIR/Sources/Models/* Sources/Models/ 2>/dev/null
mv $TEMP_DIR/Sources/Views/* Sources/Views/ 2>/dev/null
mv $TEMP_DIR/Sources/Utils/* Sources/Utils/ 2>/dev/null

# Move resources
mv $TEMP_DIR/Resources/* Resources/ 2>/dev/null

# Move project files
mv $TEMP_DIR/LilithOS.xcodeproj . 2>/dev/null
mv $TEMP_DIR/Package.swift . 2>/dev/null
mv $TEMP_DIR/README.md . 2>/dev/null

# Move scripts
mv $TEMP_DIR/scripts/* scripts/ 2>/dev/null

# Clean up
echo -e "${PURPLE}🧹 Cleaning up...${NC}"
rm -rf $TEMP_DIR

# Ensure proper permissions
chmod +x scripts/*.sh

echo -e "${PURPLE}✨ Reorganization complete!${NC}"
echo -e "${PURPLE}📱 Project structure:${NC}"
tree -L 3 