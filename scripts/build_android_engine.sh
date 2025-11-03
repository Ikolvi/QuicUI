#!/bin/bash

# Build Flutter Engine - Android Release (ARM64)
# This script builds the Android engine with QuicUI Code Push support

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Flutter Engine Android Build Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Configuration
ENGINE_SRC="/Volumes/DoWonder2/quicui_engine_build/engine_full/src"
DEPOT_TOOLS="/Volumes/DoWonder2/quicui_engine_build/depot_tools"
BUILD_DIR="out/android_release_arm64"
LOG_FILE="/tmp/android_build_$(date +%Y%m%d_%H%M%S).log"
PARALLEL_JOBS=4

# Verify directories exist
if [ ! -d "$ENGINE_SRC" ]; then
    echo -e "${RED}Error: Engine source directory not found: $ENGINE_SRC${NC}"
    exit 1
fi

if [ ! -d "$DEPOT_TOOLS" ]; then
    echo -e "${RED}Error: depot_tools directory not found: $DEPOT_TOOLS${NC}"
    exit 1
fi

# Change to engine source directory
cd "$ENGINE_SRC"
echo -e "${YELLOW}Working directory: $(pwd)${NC}"
echo ""

# Export required environment variables
echo -e "${YELLOW}Setting up environment...${NC}"
export PATH="$DEPOT_TOOLS:$PATH"
export DEPOT_TOOLS_UPDATE=0  # Prevent depot_tools auto-update during build

# Verify required tools are available
echo -e "${YELLOW}Verifying build tools...${NC}"
if ! command -v ninja &> /dev/null; then
    echo -e "${RED}Error: ninja not found in PATH${NC}"
    exit 1
fi
echo -e "${GREEN}✓ ninja found: $(which ninja)${NC}"

# Check if build directory exists and is configured
if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${YELLOW}Build directory doesn't exist. Running GN to configure...${NC}"
    ./flutter/tools/gn --android --android-cpu arm64 --runtime-mode release
    echo -e "${GREEN}✓ GN configuration complete${NC}"
    echo ""
else
    echo -e "${GREEN}✓ Build directory exists: $BUILD_DIR${NC}"
    echo ""
fi

# Verify QuicUI modifications are present
echo -e "${YELLOW}Verifying QuicUI modifications...${NC}"
if [ -f "flutter/shell/platform/android/flutter_main.cc" ]; then
    if grep -q "ConfigureQuicUI" "flutter/shell/platform/android/flutter_main.cc"; then
        echo -e "${GREEN}✓ ConfigureQuicUI found in flutter_main.cc${NC}"
    else
        echo -e "${RED}Warning: ConfigureQuicUI not found in flutter_main.cc${NC}"
        echo -e "${YELLOW}The engine may not have QuicUI Code Push support${NC}"
    fi
else
    echo -e "${RED}Warning: flutter_main.cc not found${NC}"
fi
echo ""

# Start the build
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Starting Ninja Build${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}Configuration:${NC}"
echo "  Target: Android ARM64"
echo "  Build mode: Release"
echo "  Build directory: $BUILD_DIR"
echo "  Parallel jobs: $PARALLEL_JOBS"
echo "  Log file: $LOG_FILE"
echo ""
echo -e "${YELLOW}This will take 1-2 hours. You can monitor progress in another terminal:${NC}"
echo "  tail -f $LOG_FILE"
echo ""
echo -e "${YELLOW}Or check current progress:${NC}"
echo "  tail -1 $LOG_FILE | grep -o '^\[[0-9]*/[0-9]*\]'"
echo ""

# Confirm before starting
read -p "Press Enter to start the build (or Ctrl+C to cancel)..."
echo ""

# Start build with progress output
echo -e "${GREEN}Building...${NC}"
ninja -C "$BUILD_DIR" -j"$PARALLEL_JOBS" 2>&1 | tee "$LOG_FILE"

# Check build result
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ Build completed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Build artifacts:${NC}"
    ls -lh "$BUILD_DIR/flutter.jar" "$BUILD_DIR/libflutter.so" 2>/dev/null || echo "Artifacts not found"
    echo ""
    echo -e "${YELLOW}Verifying QuicUI in built artifacts:${NC}"
    if strings "$BUILD_DIR/libflutter.so" | grep -q "ConfigureQuicUI"; then
        echo -e "${GREEN}✓ ConfigureQuicUI found in libflutter.so${NC}"
        echo -e "${GREEN}✓ QuicUI Code Push support is included!${NC}"
    else
        echo -e "${RED}✗ ConfigureQuicUI NOT found in libflutter.so${NC}"
        echo -e "${RED}✗ QuicUI Code Push support may not be working${NC}"
    fi
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Build host engine (if not already done):"
    echo "     ./build_host_engine.sh"
    echo ""
    echo "  2. Build test app with local engine:"
    echo "     cd /Users/admin/Documents/quicui2/test_apps/test_app_fresh"
    echo "     ./build_with_local_engine.sh"
    echo ""
    exit 0
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ Build failed!${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo -e "${YELLOW}Check the log file for errors:${NC}"
    echo "  tail -100 $LOG_FILE | grep -E 'FAILED|ERROR'"
    echo ""
    exit 1
fi
