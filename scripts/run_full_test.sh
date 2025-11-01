#!/bin/bash

# QuicUI Code Push - Full Test Setup
# Runs backend server + builds APK with QuicUI Flutter SDK
# Tests local network code push at 192.168.20.100:8080

set -e

# Configuration
REPO_ROOT="/Users/admin/Documents/quicui2"
TEST_APP_DIR="$REPO_ROOT/test_apps/quicui_test_app_v1"
QUICUI_FLUTTER_SDK="$REPO_ROOT/forks/flutter-official"
BACKEND_DIR="$REPO_ROOT/packages/quicui_backend"
BACKEND_HOST="192.168.20.100"
BACKEND_PORT="8080"
BACKEND_URL="http://$BACKEND_HOST:$BACKEND_PORT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

log_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Cleanup on exit
cleanup() {
    echo ""
    log_warning "Cleaning up background processes..."
    jobs -p | xargs -r kill 2>/dev/null || true
    sleep 1
}

trap cleanup EXIT

# Main execution
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║     QuicUI Code Push - Full Test Setup & Execution       ║"
echo "║                                                            ║"
echo "║     Backend + APK Build + Local Network Testing           ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Date: $(date)"
echo "Backend: $BACKEND_URL"
echo ""

# Step 0: Verify prerequisites
log_step "Step 0: Verify Prerequisites"
echo "Checking required components..."

if [ ! -d "$QUICUI_FLUTTER_SDK" ]; then
    log_error "QuicUI Flutter SDK not found at $QUICUI_FLUTTER_SDK"
    exit 1
fi
log_success "QuicUI Flutter SDK found: $QUICUI_FLUTTER_SDK"

if [ ! -f "$BACKEND_DIR/lib/quicui_backend.dart" ]; then
    log_error "Backend entry point not found at $BACKEND_DIR/lib/quicui_backend.dart"
    exit 1
fi
log_success "Backend found: $BACKEND_DIR"

if [ ! -d "$TEST_APP_DIR" ]; then
    log_error "Test app not found at $TEST_APP_DIR"
    exit 1
fi
log_success "Test app found: $TEST_APP_DIR"

# Step 1: Start Backend Server
log_step "Step 1: Start Backend Server (Port $BACKEND_PORT)"
echo "Starting QuicUI Code Push Backend..."
echo ""

cd "$BACKEND_DIR"

# Get dependencies
log_info "Installing backend dependencies..."
dart pub get > /dev/null 2>&1
log_success "Dependencies installed"

# Start backend in background
log_info "Starting server on 0.0.0.0:$BACKEND_PORT (localhost will bind here)..."
SERVER_HOST="0.0.0.0" SERVER_PORT="$BACKEND_PORT" dart run lib/quicui_backend.dart &
BACKEND_PID=$!
log_success "Backend started (PID: $BACKEND_PID)"

# Wait for server to start
sleep 3

# Verify backend is running
log_info "Verifying backend health..."
if curl -s http://localhost:$BACKEND_PORT/health > /dev/null 2>&1; then
    log_success "✅ Backend is healthy and running"
else
    log_warning "⚠️  Backend may still be starting... continuing anyway"
fi

echo ""
echo "Backend Server Info:"
echo "  URL: http://localhost:$BACKEND_PORT"
echo "  Health: http://localhost:$BACKEND_PORT/health"
echo "  Metrics: http://localhost:$BACKEND_PORT/metrics/json"
echo "  API: http://localhost:$BACKEND_PORT/api/v1"
echo ""

# Step 2: Build APK with QuicUI SDK
log_step "Step 2: Build APK with QuicUI Flutter SDK"
echo ""

cd "$TEST_APP_DIR"

# Set Flutter SDK
export FLUTTER_ROOT="$QUICUI_FLUTTER_SDK"
export PATH="$QUICUI_FLUTTER_SDK/bin:$PATH"
log_success "FLUTTER_ROOT set to: $FLUTTER_ROOT"

# Verify Flutter SDK
flutter_version=$(flutter --version 2>&1 | head -1)
echo "Flutter: $flutter_version"

flutter_root=$(flutter config --list 2>/dev/null | grep "flutter-root" | awk '{print $NF}')
if [[ "$flutter_root" == *"forks/flutter-official"* ]]; then
    log_success "✅ Using QuicUI Flutter SDK from: $flutter_root"
else
    log_warning "⚠️  Flutter root: $flutter_root"
fi

echo ""
log_info "Cleaning build artifacts..."
flutter clean > /dev/null 2>&1
log_success "Build directory cleaned"

log_info "Installing dependencies..."
flutter pub get > /dev/null 2>&1
log_success "Dependencies installed"

# Verify configuration
echo ""
log_info "Verifying build configuration..."
if grep -q "192.168.20.100:8080" lib/main.dart; then
    log_success "✅ Endpoint configured: 192.168.20.100:8080"
else
    log_warning "⚠️  Endpoint not found in main.dart"
fi

if grep -q "quicui_code_push_client" pubspec.yaml; then
    log_success "✅ QuicUI Code Push client dependency found"
else
    log_error "❌ QuicUI Code Push client dependency not found"
    exit 1
fi

# Build APK
echo ""
log_info "Building Release APK with QuicUI Flutter SDK..."
echo "This may take 2-5 minutes..."
echo ""

if flutter build apk --release --no-obfuscate -v 2>&1 | tail -30; then
    log_success "APK build completed"
else
    log_error "APK build failed"
    exit 1
fi

# Verify APK
log_step "Step 3: Verify APK Output"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

if [ -f "$APK_PATH" ]; then
    apk_size=$(du -h "$APK_PATH" | cut -f1)
    apk_checksum=$(shasum -a 256 "$APK_PATH" | cut -d' ' -f1)
    log_success "APK generated: $APK_PATH"
    log_success "APK size: $apk_size"
    echo "SHA256: $apk_checksum"
else
    log_error "APK not found at $APK_PATH"
    exit 1
fi

# Step 4: Summary and next steps
echo ""
log_step "Step 4: Test Environment Ready"
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                   TEST ENVIRONMENT READY                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📦 APK Information:"
echo "  Path: $APK_PATH"
echo "  Size: $apk_size"
echo "  Checksum: $apk_checksum"
echo ""
echo "🚀 Backend Server:"
echo "  URL: http://localhost:$BACKEND_PORT"
echo "  PID: $BACKEND_PID"
echo "  Status: Running ✅"
echo ""
echo "🎯 Network Configuration:"
echo "  App endpoint: http://192.168.20.100:$BACKEND_PORT"
echo "  Local endpoint: http://localhost:$BACKEND_PORT"
echo ""
echo "📝 Next Steps:"
echo "  1. Keep this terminal open (backend running)"
echo "  2. Install APK on Android device:"
echo "     adb install -r \"$APK_PATH\""
echo "  3. Launch app and observe patch detection"
echo "  4. Check backend logs for API calls"
echo ""
echo "📊 Useful Commands (in new terminals):"
echo "  Backend Health:  curl http://localhost:$BACKEND_PORT/health"
echo "  API v1:          curl http://localhost:$BACKEND_PORT/api/v1/apps"
echo "  Metrics:         curl http://localhost:$BACKEND_PORT/metrics/json"
echo "  Logs:            kill $BACKEND_PID"
echo ""
echo "🛑 To stop backend: Press Ctrl+C in this terminal"
echo ""

# Keep backend running
wait $BACKEND_PID
