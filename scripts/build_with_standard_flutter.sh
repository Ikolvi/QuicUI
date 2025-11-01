#!/bin/bash

# Test App - Build with Standard Flutter
# Builds the test app using standard Flutter SDK to verify no breakage

set -e

APP_DIR="/Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}>>> Building Test App with Standard Flutter${NC}"
echo ""

# Use system Flutter (not the fork)
unset FLUTTER_ROOT
export PATH="/usr/local/bin:$PATH"

# Verify Flutter
echo "Flutter version:"
flutter --version | head -1
echo ""

# Navigate to app
cd "$APP_DIR"

# Clean
echo -e "${BLUE}>>> Cleaning project...${NC}"
flutter clean

# Get dependencies
echo -e "${BLUE}>>> Getting dependencies...${NC}"
flutter pub get

# Build APK with standard Flutter
echo -e "${BLUE}>>> Building release APK with standard Flutter...${NC}"
flutter build apk --release

echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo ""
echo "APK location:"
ls -lh build/app/outputs/flutter-apk/app-release.apk
echo ""
echo "SDK Detection Test:"
echo "  This app was built with STANDARD Flutter"
echo "  On device, it should show: Flutter (Standard) ❌"
