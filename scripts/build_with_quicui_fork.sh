#!/bin/bash

# QuicUI Test App - Build with Fork
# Builds the test app using the QuicUI-forked Flutter SDK

set -e

FLUTTER_ROOT="/Users/admin/Documents/quicui2/forks/flutter-official"
APP_DIR="/Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}>>> Building QuicUI Test App with forked Flutter${NC}"
echo ""

# Set environment
export FLUTTER_ROOT="$FLUTTER_ROOT"
export PATH="$FLUTTER_ROOT/bin:$PATH"

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

# Build APK - automatically uses QuicUI fork
# Use --release mode for AOT compilation (Shorebird-style patching)
echo -e "${BLUE}>>> Building release APK (AOT for production patching)...${NC}"
flutter build apk --release

echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo ""
echo "APK location:"
ls -lh build/app/outputs/flutter-apk/app-release.apk
echo ""
echo "Next step: Install on device"
echo "  ./scripts/install_and_launch.sh"
