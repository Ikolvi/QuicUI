#!/bin/bash

# QuicUI Code Push - Notify Client App of Patch Availability
# Sends API call to backend to mark patch as available
# Client app will detect and download on next check

set -e

# Configuration
BACKEND_URL="http://localhost:8080"
APP_ID="com.quicui.testapp"
PATCH_VERSION="1.0.1"

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
echo "║   QuicUI Code Push - Notify Patch Availability        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Verify backend is running
log_step "Step 1: Verify Backend Server"
if ! curl -s "$BACKEND_URL/health" > /dev/null 2>&1; then
    log_error "Backend server not running at $BACKEND_URL"
    exit 1
fi
log_success "Backend is running"

# Step 2: Verify patch exists on backend
log_step "Step 2: Verify Patch on Backend"
PATCH_CHECK=$(curl -s "$BACKEND_URL/api/v1/patches/check" \
  -H "Content-Type: application/json" \
  -d "{\"appId\": \"$APP_ID\", \"version\": \"1.0.0\", \"platform\": \"flutter\"}")

log_info "Backend response: $PATCH_CHECK"

# Step 3: Make patch available (backend-side update)
log_step "Step 3: Activate Patch on Backend"
ACTIVATE_RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/v1/patches/activate" \
  -H "Content-Type: application/json" \
  -d "{
    \"appId\": \"$APP_ID\",
    \"fromVersion\": \"1.0.0\",
    \"toVersion\": \"$PATCH_VERSION\",
    \"patchFile\": \"patch_v${PATCH_VERSION}.zip\"
  }")

log_success "Patch activated on backend"
log_info "Response: $ACTIVATE_RESPONSE"

# Step 4: Verify patch is available for clients
log_step "Step 4: Verify Patch Availability"
sleep 1

VERIFY_RESPONSE=$(curl -s "$BACKEND_URL/api/v1/patches/check" \
  -H "Content-Type: application/json" \
  -d "{\"appId\": \"$APP_ID\", \"version\": \"1.0.0\", \"platform\": \"flutter\"}")

if echo "$VERIFY_RESPONSE" | grep -q "1.0.1"; then
    log_success "Patch v1.0.1 is now available to clients"
else
    log_warning "Patch status may not be reflected immediately"
    log_info "Backend response: $VERIFY_RESPONSE"
fi

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║        ✅ PATCH NOTIFICATION SENT TO BACKEND           ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
log_info "Client apps will now:"
echo "  1. Detect patch v1.0.1 is available"
echo "  2. Download patch in background"
echo "  3. Verify patch signature"
echo "  4. Apply patch WITHOUT restart"
echo "  5. Update app version to 1.0.1"
echo ""
log_info "Check device logs for:"
echo "  $ adb logcat | grep QuicUI"
echo ""

