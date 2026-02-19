#!/bin/bash

# Create DMG Script
# Creates a DMG installer for the Health Reminder app

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "📦 Creating DMG Installer for Health Reminder..."
echo ""

# Check if app exists
APP_PATH="HealthyWork/build/Build/Products/Release/HealthyWork.app"

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}❌ App not found at: $APP_PATH${NC}"
    echo -e "${YELLOW}⚠️  Please build the app first using:${NC}"
    echo "   ./scripts/test-build.sh"
    exit 1
fi

# Get version from arguments or use default
VERSION=${1:-"1.0.0"}
OUTPUT_DIR="dist"
DMG_NAME="HealthyWork-v${VERSION}.dmg"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}ℹ️  Creating DMG...${NC}"
echo "   Version: $VERSION"
echo "   Output: $OUTPUT_DIR/$DMG_NAME"
echo ""

# Create temporary directory for DMG contents
TMP_DIR=$(mktemp -d)
mkdir -p "$TMP_DIR"

# Copy app to temporary directory
cp -R "$APP_PATH" "$TMP_DIR/"

# Create Applications symlink
ln -s /Applications "$TMP_DIR/Applications"

# Create DMG
hdiutil create \
  -volname "Health Reminder $VERSION" \
  -srcfolder "$TMP_DIR" \
  -ov \
  -format UDZO \
  "$OUTPUT_DIR/$DMG_NAME"

# Cleanup
rm -rf "$TMP_DIR"

# Show result
if [ -f "$OUTPUT_DIR/$DMG_NAME" ]; then
    echo ""
    echo -e "${GREEN}✅ DMG created successfully!${NC}"
    echo ""
    echo "Output file: $OUTPUT_DIR/$DMG_NAME"
    echo "File size: $(du -sh "$OUTPUT_DIR/$DMG_NAME" | cut -f1)"
    echo ""
    echo "To test: open $OUTPUT_DIR/$DMG_NAME"
else
    echo -e "${RED}❌ Failed to create DMG${NC}"
    exit 1
fi
