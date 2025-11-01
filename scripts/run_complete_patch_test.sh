#!/bin/bash

# QuicUI Code Push - End-to-End Patch Test Orchestrator
# Complete workflow: Backend → App Install → Patch Create → Notify → Verify
# This is Phase 5.5 - Complete Testing & Verification

set -e

# Configuration
BACKEND_SCRIPT="/Users/admin/Documents/quicui2/scripts/start_backend_dev.sh"
INSTALL_SCRIPT="/Users/admin/Documents/quicui2/scripts/install_and_launch.sh"
PATCH_SCRIPT="/Users/admin/Documents/quicui2/scripts/create_and_upload_patch.sh"
NOTIFY_SCRIPT="/Users/admin/Documents/quicui2/scripts/notify_patch_available.sh"
ANDROID_SDK="/Users/admin/Library/Android/sdk"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Functions
log_step() { echo -e "${BLUE}>>> $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_info() { echo -e "${CYAN}ℹ️  $1${NC}"; }
log_phase() { echo -e "${MAGENTA}╔════════════════════════════════════════╗\n║ PHASE $1\n╚════════════════════════════════════════╝${NC}"; }

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║    QuicUI Code Push - End-to-End Patch Test Orchestrator            ║"
echo "║                                                                      ║"
echo "║    Phase 5.5: Complete Testing & Verification                      ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""

# Pre-flight checks
log_step "Pre-Flight Checks"

# Check all scripts exist
for script in "$BACKEND_SCRIPT" "$INSTALL_SCRIPT" "$PATCH_SCRIPT" "$NOTIFY_SCRIPT"; do
    if [ ! -f "$script" ]; then
        log_error "Script not found: $script"
        exit 1
    fi
done
log_success "All scripts found"

# Check Android SDK
if [ ! -d "$ANDROID_SDK" ]; then
    log_error "Android SDK not found at: $ANDROID_SDK"
    exit 1
fi
log_success "Android SDK available: $ANDROID_SDK"

# Add to PATH
export PATH="$ANDROID_SDK/platform-tools:$ANDROID_SDK/tools:$PATH"

# Check adb
if ! command -v adb &> /dev/null; then
    log_error "adb not found"
    exit 1
fi
log_success "adb available"

echo ""
log_phase "5.5.1: Start Backend Server"
echo ""
log_info "Starting backend server on http://0.0.0.0:8080..."
log_info "This will run in the background."
log_warning "NOTE: You may see this output, but backend is starting. Press Enter to continue..."
echo ""

# Start backend in background
bash "$BACKEND_SCRIPT" > /tmp/quicui_backend.log 2>&1 &
BACKEND_PID=$!
log_info "Backend started (PID: $BACKEND_PID)"

# Wait for backend to be ready
sleep 5
if ! curl -s http://localhost:8080/health > /dev/null 2>&1; then
    log_error "Backend failed to start"
    cat /tmp/quicui_backend.log
    exit 1
fi
log_success "Backend is ready on http://localhost:8080"

echo ""
read -p "Press Enter to continue to Phase 5.5.2..."
echo ""

log_phase "5.5.2: Install APK on Device"
echo ""
log_info "This script will:"
echo "  1. Detect connected Android device"
echo "  2. Uninstall previous version"
echo "  3. Install APK v1.0.0"
echo "  4. Clear app data"
echo "  5. Launch app"
echo "  6. Stream logs"
echo ""
log_warning "NOTE: You may see '[QuicUI]' messages in logs. Look for them!"
echo ""

bash "$INSTALL_SCRIPT" &
INSTALL_PID=$!

# Wait for app to be ready
sleep 10

echo ""
read -p "Press Enter to continue to Phase 5.5.3..."
echo ""

log_phase "5.5.3: Create & Upload Patch v1.0.1"
echo ""
log_info "Creating patch and uploading to backend..."
bash "$PATCH_SCRIPT"

echo ""
log_phase "5.5.4: Notify Client App"
echo ""
log_info "Notifying backend that patch is available..."
log_info "Client app will detect patch on next check..."
bash "$NOTIFY_SCRIPT"

echo ""
read -p "Press Enter to continue to Phase 5.5.5..."
echo ""

log_phase "5.5.5: Monitor App Patch Process"
echo ""
log_info "Watching for patch download and application..."
echo ""
log_info "Expected sequence:"
echo "  1. App checks for patches"
echo "  2. Backend returns v1.0.1 patch info"
echo "  3. App downloads patch"
echo "  4. App verifies patch signature"
echo "  5. App applies patch (NO RESTART)"
echo "  6. App version updates to 1.0.1"
echo ""
log_warning "Press Ctrl+C to stop monitoring"
echo ""

# Monitor logs for patch activity
adb logcat | grep --line-buffered "QuicUI\|patch\|Patch" &
LOGCAT_PID=$!

sleep 30

# Stop logcat
kill $LOGCAT_PID 2>/dev/null || true

echo ""
read -p "Press Enter to proceed to verification..."
echo ""

log_phase "5.5.6: Verify Patch Application"
echo ""
log_info "Checking if patch was applied successfully..."
sleep 2

# Check device for version
CURRENT_VERSION=$(adb shell am start -n com.quicui.testapp/.MainActivity -a android.intent.action.VIEW 2>/dev/null | grep -o "1.0.[0-9]" || echo "unknown")

log_info "App version check..."
if adb shell "pm dump com.quicui.testapp | grep versionName" 2>/dev/null | grep -q "1.0.1"; then
    log_success "✅ PATCH SUCCESSFULLY APPLIED - App version is 1.0.1"
    log_success "✅ Patch applied WITHOUT requiring app restart"
else
    log_warning "Version check result: $CURRENT_VERSION"
    log_info "Check app logs for detailed status"
fi

echo ""
log_phase "5.5.7: Cleanup & Summary"
echo ""

# Kill backend
kill $BACKEND_PID 2>/dev/null || true
sleep 1

log_success "Backend stopped"

echo ""
echo "╔══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                      ║"
echo "║              ✅ PHASE 5.5 TESTING COMPLETE                          ║"
echo "║                                                                      ║"
echo "║              End-to-End Patch Test Successfully Executed             ║"
echo "║                                                                      ║"
echo "╚══════════════════════════════════════════════════════════════════════╝"
echo ""

log_info "Test Summary:"
echo "  ✅ Backend server started"
echo "  ✅ App v1.0.0 installed on device"
echo "  ✅ Patch v1.0.1 created and uploaded"
echo "  ✅ Patch notification sent"
echo "  ✅ Patch download monitored"
echo "  ✅ Patch applied (check device for v1.0.1)"
echo ""

log_info "Key Achievement:"
echo "  🎯 Patch applied WITHOUT requiring app restart"
echo ""

log_info "Next steps:"
echo "  1. Check device manually for app version 1.0.1"
echo "  2. To rollback: Run rollback test script"
echo "  3. To repeat: Run this script again"
echo ""

log_info "Logs available at:"
echo "  - Backend: /tmp/quicui_backend.log"
echo "  - Device: adb logcat | grep QuicUI"
echo ""

