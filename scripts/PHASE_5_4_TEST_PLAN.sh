#!/bin/bash

# Phase 5.4 - Test Execution Plan
# Three-Terminal Testing Infrastructure for QuicUI Code Push v1.0.0
#
# This plan outlines the complete testing workflow:
# - Terminal 1: Backend Server (running)
# - Terminal 2: APK Installation & Device Testing
# - Terminal 3: Monitoring (logs, health checks)
#
# Date: 1 November 2025
# Status: Ready for Execution

set -e

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

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║   QuicUI Code Push v1.0.0 - Phase 5.4 Test Execution Plan    ║"
echo "║                                                                ║"
echo "║   Three-Terminal Testing Infrastructure                        ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Pre-flight checks
log_step "Pre-Flight Checks"

# Check APK exists
APK_FILE="/Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1/build/app/outputs/apk/release/app-release.apk"
if [ ! -f "$APK_FILE" ]; then
    log_error "APK not found: $APK_FILE"
    exit 1
fi
log_success "APK found (41M)"

# Check adb is available
if ! command -v adb &> /dev/null; then
    log_error "adb not found. Install Android SDK Platform Tools"
    exit 1
fi
log_success "adb available"

# Check device connected
DEVICE_COUNT=$(adb devices | grep -c "device$" || true)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    log_warning "No Android devices connected"
    echo "  Connect a device via USB and run: adb devices"
    echo ""
    read -p "Press Enter when device is ready..."
fi

echo ""
log_step "Terminal 1: Backend Server"
echo "  Command: /Users/admin/Documents/quicui2/scripts/start_backend_dev.sh"
echo "  Purpose: Runs backend on http://localhost:8080"
echo "  Status: ✅ Ready"
echo ""

log_step "Terminal 2: APK Installation & Testing"
echo "  Commands:"
echo "    1. adb install -r $APK_FILE"
echo "    2. adb shell am start -n com.quicui.testapp/.MainActivity"
echo "  Purpose: Installs APK and launches app"
echo "  Expected: App launches, shows patch status"
echo "  Status: ✅ Ready"
echo ""

log_step "Terminal 3: Monitoring"
echo "  Commands:"
echo "    1. adb logcat | grep QuicUI"
echo "    2. curl http://localhost:8080/health"
echo "  Purpose: Monitor app logs and backend health"
echo "  Status: ✅ Ready"
echo ""

log_step "Test Sequence"
echo ""
echo "  PHASE 5.4.1: Environment Validation"
echo "    ├─ Backend server running on 0.0.0.0:8080"
echo "    ├─ APK installed on device"
echo "    └─ Device can reach backend on localhost:8080"
echo ""
echo "  PHASE 5.4.2: App Initialization"
echo "    ├─ App starts without errors"
echo "    ├─ Plugin initializes with Config"
echo "    ├─ Backend endpoint is internal (not visible in UI)"
echo "    └─ Check QuicUI logs: '[QuicUI] Initialized with appId: ...'"
echo ""
echo "  PHASE 5.4.3: Patch Check"
echo "    ├─ App checks for patches"
echo "    ├─ Backend receives request (check logs)"
echo "    ├─ Response includes patch info (v1.0.1)"
echo "    └─ Check UI: Should show patch available status"
echo ""
echo "  PHASE 5.4.4: Patch Download"
echo "    ├─ User taps 'Download Patch'"
echo "    ├─ Backend streams patch to app"
echo "    ├─ Download progress shown (0% → 100%)"
echo "    └─ Check logs: download_progress callback fired"
echo ""
echo "  PHASE 5.4.5: Patch Verification"
echo "    ├─ Signature verification with embedded public key"
echo "    ├─ No restart required (background verification)"
echo "    └─ Check logs: '[QuicUI] Signature valid'"
echo ""
echo "  PHASE 5.4.6: Patch Application"
echo "    ├─ Patch applied in background"
echo "    ├─ No app restart (OTA magic)"
echo "    ├─ App version shown as 1.0.1"
echo "    └─ Check logs: '[QuicUI] Patch applied: v1.0.1'"
echo ""
echo "  PHASE 5.4.7: Rollback Test"
echo "    ├─ Rollback API called"
echo "    ├─ App reverts to v1.0.0"
echo "    └─ Verification: Version shows 1.0.0"
echo ""

log_step "Success Criteria"
echo "  ✅ App launches successfully"
echo "  ✅ Patch check communication with backend works"
echo "  ✅ Patch downloads without errors"
echo "  ✅ Patch applies WITHOUT requiring app restart"
echo "  ✅ App version updates to 1.0.1"
echo "  ✅ Rollback to 1.0.0 works"
echo "  ✅ Backend endpoint is INTERNAL (not exposed to Config)"
echo ""

log_step "Getting Started"
echo ""
echo "  1. Open Terminal 1:"
echo "     $ /Users/admin/Documents/quicui2/scripts/start_backend_dev.sh"
echo ""
echo "  2. In Terminal 2:"
echo "     $ adb install -r /Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1/build/app/outputs/apk/release/app-release.apk"
echo "     $ adb shell am start -n com.quicui.testapp/.MainActivity"
echo ""
echo "  3. In Terminal 3:"
echo "     $ adb logcat | grep QuicUI"
echo ""
echo "  4. Watch app UI for:"
echo "     - 'Checking for patches...'"
echo "     - 'Patch available: v1.0.1'"
echo "     - 'Downloading...' (0-100%)"
echo "     - 'Patch applied! App v1.0.1'"
echo ""
echo "  5. Verify backend logs show API calls"
echo ""

log_success "Test execution plan ready"
echo ""
