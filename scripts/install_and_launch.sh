#!/bin/bash

# QuicUI Code Push - Auto Install & Launch APK
# Detects connected Android device, installs APK, and launches app
# Requires Android SDK at /Users/admin/Library/Android/sdk

set -e

# Configuration
ANDROID_SDK="/Users/admin/Library/Android/sdk"
FLUTTER_ROOT="/Users/admin/Documents/quicui2/forks/flutter-official"
APK_FILE="/Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1/build/app/outputs/flutter-apk/app-release.apk"
PACKAGE_NAME="com.quicui.quicui_test_app"
MAIN_ACTIVITY="com.quicui.quicui_test_app.MainActivity"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Functions
log_step() { echo -e "${BLUE}>>> $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║     QuicUI Code Push - Auto Install & Launch APK      ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Verify Android SDK
log_step "Step 1: Verify Android SDK"
if [ ! -d "$ANDROID_SDK" ]; then
    log_error "Android SDK not found at: $ANDROID_SDK"
    exit 1
fi
log_success "Android SDK found: $ANDROID_SDK"

# Add Android SDK tools to PATH
export PATH="$ANDROID_SDK/platform-tools:$ANDROID_SDK/tools:$PATH"

# Verify adb
if ! command -v adb &> /dev/null; then
    log_error "adb not found in PATH"
    exit 1
fi
log_success "adb available"

# Step 2: Check for connected devices
log_step "Step 2: Detect Connected Devices"
DEVICE_LIST=$(adb devices | grep -v "List of attached" | grep "device$" | awk '{print $1}')
DEVICE_COUNT=$(echo "$DEVICE_LIST" | wc -l | tr -d ' ')

if [ -z "$DEVICE_LIST" ] || [ "$DEVICE_LIST" == "" ]; then
    log_error "No Android devices detected"
    log_info "Ensure device is connected via USB"
    log_info "Enable USB Debugging in device settings"
    exit 1
fi

DEVICE_ID=$(echo "$DEVICE_LIST" | head -1)
log_success "Found device: $DEVICE_ID"

# Step 3: Verify APK exists
log_step "Step 3: Verify APK File"
if [ ! -f "$APK_FILE" ]; then
    log_error "APK not found: $APK_FILE"
    log_info "Run: /Users/admin/Documents/quicui2/scripts/build_local.sh"
    exit 1
fi

APK_SIZE=$(du -h "$APK_FILE" | cut -f1)
log_success "APK found: $APK_SIZE"

# Step 4: Uninstall previous version (if exists)
log_step "Step 4: Uninstall Previous Version (if exists)"
if adb -s "$DEVICE_ID" shell pm list packages | grep -q "^package:$PACKAGE_NAME"; then
    log_info "Uninstalling previous version..."
    adb -s "$DEVICE_ID" uninstall "$PACKAGE_NAME" || true
    sleep 2
    log_success "Previous version removed"
else
    log_info "No previous version found"
fi

# Step 5: Install APK
log_step "Step 5: Install APK on Device"
log_info "Installing $APK_SIZE APK..."
if adb -s "$DEVICE_ID" install -r "$APK_FILE"; then
    log_success "APK installed successfully"
else
    log_error "APK installation failed"
    exit 1
fi

# Step 6: Clear app data (fresh start)
log_step "Step 6: Clear App Data (Fresh Start)"
adb -s "$DEVICE_ID" shell pm clear "$PACKAGE_NAME" || true
sleep 1
log_success "App data cleared"

# Step 7: Launch app
log_step "Step 7: Launch App"
log_info "Starting: $MAIN_ACTIVITY"
if adb -s "$DEVICE_ID" shell am start -n "$PACKAGE_NAME/$MAIN_ACTIVITY"; then
    log_success "App launched on device"
    log_info "Device: $DEVICE_ID"
    log_info "Package: $PACKAGE_NAME"
else
    log_error "Failed to launch app"
    exit 1
fi

# Step 8: Show real-time logs
log_step "Step 8: Streaming App Logs (Press Ctrl+C to stop)"
echo ""
log_info "Filtering for QuicUI debug messages..."
sleep 2
adb -s "$DEVICE_ID" logcat | grep --line-buffered "QuicUI\|patch\|Patch"

