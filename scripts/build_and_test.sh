#!/bin/bash

# QuicUI Code Push - Build & Test Script
# Local Network Testing at 192.168.20.100:8080
# Build with QuicUI Flutter SDK only

set -e

echo "================================"
echo "QuicUI Code Push - Build & Test"
echo "================================"
echo "Date: $(date)"
echo "Backend: 192.168.20.100:8080"
echo ""

# Configuration
TEST_APP_DIR="/Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1"
QUICUI_FLUTTER_SDK="/Users/admin/Documents/quicui2/forks/flutter-official"
BACKEND_HOST="192.168.20.100"
BACKEND_PORT="8080"
BACKEND_URL="http://$BACKEND_HOST:$BACKEND_PORT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
log_step "Step 1: Configure & Verify QuicUI Flutter SDK"
echo "Setting up QuicUI Flutter SDK from: $QUICUI_FLUTTER_SDK"

if [ ! -d "$QUICUI_FLUTTER_SDK" ]; then
    log_error "QuicUI Flutter SDK not found at $QUICUI_FLUTTER_SDK"
    exit 1
fi

# Export Flutter environment to use QuicUI fork
export FLUTTER_ROOT="$QUICUI_FLUTTER_SDK"
export PATH="$QUICUI_FLUTTER_SDK/bin:$PATH"
log_success "FLUTTER_ROOT set to: $FLUTTER_ROOT"

# Verify Flutter version
echo "Checking Flutter version..."
flutter_version=$(flutter --version 2>&1 | head -1)
echo "  $flutter_version"

# Verify we're using the correct SDK
flutter_root=$(flutter config --list 2>/dev/null | grep "flutter-root" | awk '{print $NF}')
if [[ "$flutter_root" == *"forks/flutter-official"* ]]; then
    log_success "✅ Confirmed: Using QuicUI Flutter SDK from: $flutter_root"
else
    log_warning "⚠️  Flutter root doesn't match expected path"
    log_warning "Expected: *forks/flutter-official*"
    log_warning "Actual: $flutter_root"
    log_warning "Continuing anyway..."
fi

# Step 2: Verify network connectivity
log_step "Step 2: Verify Network Connectivity"
echo "Testing connection to $BACKEND_HOST:$BACKEND_PORT..."

if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$BACKEND_HOST/$BACKEND_PORT" 2>/dev/null; then
    log_success "Backend is reachable at $BACKEND_URL"
else
    log_warning "Backend not reachable at $BACKEND_URL"
    log_warning "Make sure the server is running on the PC"
    log_warning "Continuing with build anyway..."
fi

# Step 3: Prepare build environment
log_step "Step 3: Prepare Build Environment"
cd "$TEST_APP_DIR"
log_success "Working directory: $TEST_APP_DIR"

echo "Cleaning previous builds..."
flutter clean > /dev/null 2>&1
log_success "Build directory cleaned"

echo "Getting dependencies..."
flutter pub get > /dev/null 2>&1
log_success "Dependencies installed"

# Step 4: Verify build configuration
log_step "Step 4: Verify Build Configuration"
echo "Checking pubspec.yaml..."
if grep -q "quicui_code_push_client" pubspec.yaml; then
    log_success "QuicUI Code Push client dependency found"
else
    log_error "QuicUI Code Push client dependency not found in pubspec.yaml"
    exit 1
fi

echo "Checking API endpoint configuration..."
if grep -q "192.168.20.100:8080" lib/main.dart; then
    log_success "Local network endpoint configured (192.168.20.100:8080)"
else
    log_warning "API endpoint might not be configured correctly"
fi

# Step 5: Build APK
log_step "Step 5: Build Release APK"
echo "Building with QuicUI Flutter SDK..."
echo "This may take 2-5 minutes..."
echo ""

if flutter build apk --release --no-obfuscate -v 2>&1 | tail -20; then
    log_success "APK build completed"
else
    log_error "APK build failed"
    exit 1
fi

# Step 6: Verify APK
log_step "Step 6: Verify APK"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ -f "$APK_PATH" ]; then
    apk_size=$(du -h "$APK_PATH" | cut -f1)
    log_success "APK generated: $APK_PATH"
    log_success "APK size: $apk_size"
    
    # Calculate checksum
    apk_checksum=$(shasum -a 256 "$APK_PATH" | cut -d' ' -f1)
    echo "SHA256: $apk_checksum"
else
    log_error "APK not found at $APK_PATH"
    exit 1
fi

# Step 7: Test Information
log_step "Step 7: Testing Information"
echo ""
echo "📱 Test Configuration:"
echo "  Device App Version: 1.0.0"
echo "  Target Patch Version: 1.0.1"
echo "  Backend: $BACKEND_URL"
echo ""
echo "📦 APK Location:"
echo "  $APK_PATH"
echo ""
echo "📊 APK Details:"
echo "  Size: $apk_size"
echo "  Checksum: $apk_checksum"
echo ""
echo "🔧 Install Command:"
echo "  adb install -r \"$APK_PATH\""
echo ""
echo "📝 Next Steps:"
echo "  1. Connect Android device via ADB"
echo "  2. Install APK: adb install -r \"$APK_PATH\""
echo "  3. Launch app on device"
echo "  4. App will check for patches at $BACKEND_URL"
echo "  5. Follow on-device testing instructions"
echo ""

# Step 8: Generate Test Summary
log_step "Step 8: Generate Test Summary"

cat > /tmp/quicui_build_summary.txt <<EOF
===================================
QuicUI Code Push - Build Summary
===================================
Date: $(date)
Backend: $BACKEND_URL
Flutter Version: $flutter_version

Build Status: ✅ SUCCESS

APK Details:
  Path: $APK_PATH
  Size: $apk_size
  Checksum (SHA256): $apk_checksum

Configuration:
  Local Network: 192.168.20.100:8080
  App Version: 1.0.0
  Target Version: 1.0.1

Next Steps:
  1. Connect Android device
  2. Install APK
  3. Launch app
  4. Test patch detection and application

===================================
EOF

log_success "Build summary saved to /tmp/quicui_build_summary.txt"

# Final Success Message
echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║        ✅ BUILD SUCCESSFUL                    ║"
echo "║                                                ║"
echo "║  APK ready for testing at:                    ║"
echo "║  $APK_PATH"
echo "║                                                ║"
echo "║  Backend configured: $BACKEND_URL"
echo "╚════════════════════════════════════════════════╝"
echo ""

exit 0
