#!/bin/bash

# QuicUI iOS Test App - Build with Fork
# Builds the iOS test app using the QuicUI-forked Flutter SDK

set -e

FLUTTER_ROOT="/Users/admin/Documents/quicui2/forks/flutter-quicui"
APP_DIR="/Users/admin/Documents/quicui2/test_apps/quicui_production_test"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}>>> Building QuicUI iOS Test App with forked Flutter${NC}"
echo ""

# Verify fork exists
if [ ! -d "$FLUTTER_ROOT" ]; then
    echo -e "${RED}Error: Flutter fork not found at $FLUTTER_ROOT${NC}"
    exit 1
fi

# Set environment to use QuicUI fork
export FLUTTER_ROOT="$FLUTTER_ROOT"
export PATH="$FLUTTER_ROOT/bin:$PATH"

# Verify Flutter
echo "Flutter version:"
flutter --version
echo ""

# Check for iOS engines
echo -e "${BLUE}>>> Checking for iOS engine artifacts...${NC}"
if [ ! -d "$FLUTTER_ROOT/bin/cache/artifacts/engine/ios-release" ]; then
    echo "Downloading iOS engine artifacts..."
    flutter precache --ios
fi

# Navigate to app
cd "$APP_DIR"

# Clean
echo -e "${BLUE}>>> Cleaning project...${NC}"
flutter clean

# Get dependencies
echo -e "${BLUE}>>> Getting dependencies...${NC}"
PUB_HOSTED_URL=https://pub.dev flutter pub get || {
    echo -e "${RED}Failed to get dependencies. Trying without version check...${NC}"
    # Temporarily bypass version check if needed
    flutter pub get --no-version-check 2>&1 || true
}

# Install CocoaPods dependencies
echo -e "${BLUE}>>> Installing iOS dependencies...${NC}"
cd ios
pod install
cd ..

# Build iOS app - uses QuicUI fork with patching support
# Use --release mode for AOT compilation (Shorebird-style patching)
echo -e "${BLUE}>>> Building release iOS app (AOT for production patching)...${NC}"
flutter build ios --release

echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo ""
echo "App location:"
ls -lh build/ios/iphoneos/Runner.app
echo ""
echo "Next step: Install on device"
echo "  flutter install --device-id=<DEVICE_ID>"
echo "or"
echo "  open ios/Runner.xcworkspace"

