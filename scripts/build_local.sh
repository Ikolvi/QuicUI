#!/bin/bash

# QuicUI Code Push - Local Build & Test Script
# Builds APK with QuicUI Flutter SDK for local testing

set -e

echo "================================"
echo "QuicUI Code Push - Local Build"
echo "================================"
echo "Date: $(date)"
echo ""

# Configuration
TEST_APP_DIR="/Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1"
QUICUI_FLUTTER_SDK="/Users/admin/Documents/quicui2/forks/flutter-official"
BUILD_OUTPUT_DIR="$TEST_APP_DIR/build/app/outputs/apk"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Functions
log_step() {
    echo -e "${BLUE}>>> $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Step 1: Verify Flutter SDK
log_step "Step 1: Configure QuicUI Flutter SDK"

if [ ! -d "$QUICUI_FLUTTER_SDK" ]; then
    log_error "QuicUI Flutter SDK not found at $QUICUI_FLUTTER_SDK"
    exit 1
fi

# Export Flutter environment to use QuicUI fork
export FLUTTER_ROOT="$QUICUI_FLUTTER_SDK"
export PATH="$QUICUI_FLUTTER_SDK/bin:$PATH"
export FLUTTER_SKIP_DOWNLOAD_BINARIES=true

log_success "FLUTTER_ROOT set to: $FLUTTER_ROOT"

# Verify Flutter version
flutter_info=$(flutter --version 2>&1 | head -3)
echo "$flutter_info"

# Step 2: Navigate to test app
log_step "Step 2: Navigate to Test App"

if [ ! -d "$TEST_APP_DIR" ]; then
    log_error "Test app directory not found at $TEST_APP_DIR"
    exit 1
fi

cd "$TEST_APP_DIR"
log_success "Working directory: $(pwd)"

# Step 3: Get dependencies
log_step "Step 3: Get Dependencies"
echo "Running 'flutter pub get'..."
flutter pub get
log_success "Dependencies obtained"

# Step 4: Build APK
log_step "Step 4: Build APK"
echo "Building release APK..."
echo ""

flutter build apk --release 2>&1 | tail -50

# Check if build succeeded
if [ $? -eq 0 ]; then
    log_success "APK build completed"
    
    # Find the APK file
    APK_FILE="$BUILD_OUTPUT_DIR/release/app-release.apk"
    
    if [ -f "$APK_FILE" ]; then
        APK_SIZE=$(du -h "$APK_FILE" | cut -f1)
        log_success "APK generated: $APK_FILE"
        log_success "APK size: $APK_SIZE"
        
        echo ""
        echo "✅ Build Complete!"
        echo ""
        echo "Next steps:"
        echo "1. Connect Android device via USB"
        echo "2. Run: adb install -r $APK_FILE"
        echo "3. Run: adb shell am start -n com.quicui.testapp/.MainActivity"
    else
        log_error "APK file not found at expected location: $APK_FILE"
        exit 1
    fi
else
    log_error "APK build failed"
    exit 1
fi
