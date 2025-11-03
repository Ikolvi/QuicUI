#!/bin/bash

# Master Build Script - QuicUI Code Push
# This script orchestrates the complete build process for testing OTA updates

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

clear
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}QuicUI Code Push - Master Build Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "This script will guide you through:"
echo "  1. Building Flutter Engine (Android + Host)"
echo "  2. Building test app with local engine"
echo "  3. Testing OTA updates"
echo ""

# Configuration
ENGINE_SRC="/Volumes/DoWonder2/quicui_engine_build/engine_full/src"
TEST_APP="/Users/admin/Documents/quicui2/test_apps/test_app_fresh"

# Check if engines are already built
ANDROID_BUILT=false
HOST_BUILT=false

if [ -f "$ENGINE_SRC/out/android_release_arm64/flutter.jar" ] && \
   [ -f "$ENGINE_SRC/out/android_release_arm64/libflutter.so" ]; then
    echo -e "${GREEN}✓ Android engine already built${NC}"
    ANDROID_BUILT=true
else
    echo -e "${YELLOW}○ Android engine needs to be built${NC}"
fi

if [ -f "$ENGINE_SRC/out/host_release/gen_snapshot" ] || \
   [ -d "$ENGINE_SRC/out/host_release/dart-sdk" ]; then
    echo -e "${GREEN}✓ Host engine already built${NC}"
    HOST_BUILT=true
else
    echo -e "${YELLOW}○ Host engine needs to be built${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Build Steps${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Build Android Engine
if [ "$ANDROID_BUILT" = false ]; then
    echo -e "${YELLOW}Step 1: Build Android Engine${NC}"
    echo "This will take 1-2 hours..."
    echo ""
    read -p "Build Android engine now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./build_android_engine.sh
        ANDROID_BUILT=true
    else
        echo -e "${RED}Skipping Android engine build${NC}"
        echo "You can build it later with: ./build_android_engine.sh"
        echo ""
    fi
else
    echo -e "${GREEN}Step 1: Android Engine ✓ (already built)${NC}"
fi

# Step 2: Build Host Engine
if [ "$HOST_BUILT" = false ]; then
    echo ""
    echo -e "${YELLOW}Step 2: Build Host Engine${NC}"
    echo "This will take 1-2 hours..."
    echo ""
    
    # Check if build is already running
    if ps aux | grep -q "[n]inja.*host_release"; then
        echo -e "${YELLOW}Host engine build is already running!${NC}"
        echo ""
        echo "You can monitor progress with:"
        echo "  ./monitor_host_build.sh"
        echo ""
        read -p "Wait for it to complete? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Waiting for build to complete..."
            while ps aux | grep -q "[n]inja.*host_release"; do
                PROGRESS=$(tail -1 /tmp/host_build_proper.log 2>/dev/null | grep -o "^\[[0-9]*/[0-9]*\]" || echo "Building...")
                echo -ne "\rProgress: $PROGRESS   "
                sleep 5
            done
            echo ""
            echo -e "${GREEN}✓ Build completed${NC}"
            HOST_BUILT=true
        fi
    else
        read -p "Build host engine now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ./build_host_engine.sh
            HOST_BUILT=true
        else
            echo -e "${RED}Skipping host engine build${NC}"
            echo "You can build it later with: ./build_host_engine.sh"
            echo ""
        fi
    fi
else
    echo -e "${GREEN}Step 2: Host Engine ✓ (already built)${NC}"
fi

# Step 3: Build Test App
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 3: Build Test App${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ "$ANDROID_BUILT" = true ] && [ "$HOST_BUILT" = true ]; then
    echo -e "${GREEN}✓ Both engines are ready!${NC}"
    echo ""
    echo "Ready to build test app with local engine."
    echo "This will use:"
    echo "  --local-engine=android_release_arm64"
    echo "  --local-engine-host=host_release"
    echo ""
    read -p "Build test app now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$TEST_APP"
        ./build_with_local_engine.sh
        
        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}Build Complete!${NC}"
        echo -e "${GREEN}========================================${NC}"
        echo ""
        echo -e "${YELLOW}Next steps:${NC}"
        echo "  1. Start backend server:"
        echo "     cd packages/quicui_backend"
        echo "     dart run bin/server.dart"
        echo ""
        echo "  2. Install app on device:"
        echo "     cd $TEST_APP"
        echo "     adb install -r build/app/outputs/flutter-apk/app-release.apk"
        echo ""
        echo "  3. Test OTA update:"
        echo "     - Launch app (should show v1.0.0, no counter)"
        echo "     - Tap 'Test Code Push' button"
        echo "     - Patch will download and install"
        echo "     - Restart app"
        echo "     - Counter should appear (v1.0.1) 🎉"
        echo ""
    fi
else
    echo -e "${RED}Cannot build test app yet.${NC}"
    echo "Please complete engine builds first:"
    if [ "$ANDROID_BUILT" = false ]; then
        echo "  - Android engine: ./build_android_engine.sh"
    fi
    if [ "$HOST_BUILT" = false ]; then
        echo "  - Host engine: ./build_host_engine.sh"
    fi
    echo ""
    exit 1
fi
