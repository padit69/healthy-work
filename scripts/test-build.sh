#!/bin/bash

# Test Build Script
# Quickly test if the app builds successfully

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "🔨 Testing Health Reminder Build..."
echo ""

# Navigate to HealthyWork directory
cd "$(dirname "$0")/../HealthyWork"

# Clean and build
echo -e "${BLUE}ℹ️  Cleaning previous builds...${NC}"
xcodebuild \
  -project HealthyWork.xcodeproj \
  -scheme HealthyWork \
  -configuration Release \
  -derivedDataPath ./build \
  clean

echo ""
echo -e "${BLUE}ℹ️  Building app...${NC}"
xcodebuild \
  -project HealthyWork.xcodeproj \
  -scheme HealthyWork \
  -configuration Release \
  -derivedDataPath ./build \
  build

# Check if build succeeded
if [ -d "build/Build/Products/Release/HealthyWork.app" ]; then
    echo ""
    echo -e "${GREEN}✅ Build successful!${NC}"
    echo ""
    echo "Build output:"
    ls -lh build/Build/Products/Release/HealthyWork.app
    echo ""
    echo "App size: $(du -sh build/Build/Products/Release/HealthyWork.app | cut -f1)"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Build failed!${NC}"
    exit 1
fi
