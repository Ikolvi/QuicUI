#!/bin/bash

# QuicUI Code Push - Create & Upload Patch v1.0.1
# Creates a patch file and uploads it to backend server
# Backend must be running on http://localhost:8080

set -e

# Configuration
BACKEND_URL="http://localhost:8080"
PATCH_VERSION="1.0.1"
APP_ID="com.quicui.testapp"
PATCH_DIR="/tmp/quicui_patch"
PATCH_FILE="$PATCH_DIR/patch_v${PATCH_VERSION}.zip"
PATCH_METADATA="$PATCH_DIR/patch_metadata.json"

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
echo "║    QuicUI Code Push - Create & Upload Patch v1.0.1    ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Verify backend is running
log_step "Step 1: Verify Backend Server"
if ! curl -s "$BACKEND_URL/health" > /dev/null 2>&1; then
    log_error "Backend server not running at $BACKEND_URL"
    log_info "Start backend with: /Users/admin/Documents/quicui2/scripts/start_backend_dev.sh"
    exit 1
fi
log_success "Backend is running on $BACKEND_URL"

# Step 2: Create patch directory
log_step "Step 2: Create Patch Directory"
mkdir -p "$PATCH_DIR"
rm -f "$PATCH_FILE" "$PATCH_METADATA"
log_success "Patch directory ready: $PATCH_DIR"

# Step 3: Create mock patch content
log_step "Step 3: Create Patch Content"
mkdir -p "$PATCH_DIR/content/lib"

# Create a simple Dart file that represents the patch
cat > "$PATCH_DIR/content/lib/patch_v1_0_1.dart" << 'EOF'
/// Patch v1.0.1 - Bug fixes and improvements
/// 
/// Changes:
/// - Fixed patch download progress reporting
/// - Improved signature verification
/// - Enhanced error handling
/// - Added better logging for debugging

const String PATCH_VERSION = '1.0.1';

void applyPatchFixes() {
  // Mock patch implementation
  // In real scenario, this would contain actual code changes
  print('[Patch v1.0.1] Fixes applied successfully');
}
EOF

# Create patch metadata
cat > "$PATCH_METADATA" << EOF
{
  "patchId": "patch_v1_0_1_$(date +%s)",
  "version": "1.0.1",
  "baseVersion": "1.0.0",
  "description": "Bug fixes and improvements",
  "changes": [
    "Fixed patch download progress reporting",
    "Improved signature verification",
    "Enhanced error handling",
    "Added better logging"
  ],
  "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "size": 0,
  "checksum": "",
  "releaseNotes": "QuicUI Code Push v1.0.1 - Patch Update\n\nImprovements:\n- Enhanced stability\n- Better error messages\n- Improved patch handling\n\nThis patch applies without requiring an app restart."
}
EOF

log_success "Patch content created"

# Step 4: Create patch archive
log_step "Step 4: Create Patch Archive"
cd "$PATCH_DIR/content"
zip -r "$PATCH_FILE" . > /dev/null 2>&1
cd - > /dev/null

PATCH_SIZE=$(du -h "$PATCH_FILE" | cut -f1)
log_success "Patch archive created: $PATCH_SIZE"

# Step 5: Calculate checksum
log_step "Step 5: Calculate Patch Checksum"
CHECKSUM=$(shasum -a 256 "$PATCH_FILE" | awk '{print $1}')
log_success "Checksum: $CHECKSUM"

# Update metadata with actual size and checksum
sed -i '' "s/\"size\": 0/\"size\": $(stat -f%z "$PATCH_FILE")/" "$PATCH_METADATA"
sed -i '' "s/\"checksum\": \"\"/\"checksum\": \"$CHECKSUM\"/" "$PATCH_METADATA"

# Step 6: Upload patch to backend
log_step "Step 6: Upload Patch to Backend"
log_info "Uploading $PATCH_FILE to $BACKEND_URL/api/v1/patches/upload"

UPLOAD_RESPONSE=$(curl -s -X POST \
  -F "patchFile=@$PATCH_FILE" \
  -F "metadata=@$PATCH_METADATA" \
  "$BACKEND_URL/api/v1/patches/upload" 2>&1)

log_success "Patch uploaded to backend"
log_info "Response: $UPLOAD_RESPONSE"

# Step 7: Create patch info file for reference
log_step "Step 7: Create Local Patch Reference"
cat > "$PATCH_DIR/PATCH_INFO.txt" << EOF
Patch Information
═════════════════

Version: $PATCH_VERSION
Base Version: 1.0.0
Patch ID: patch_v1_0_1_$(date +%s)
File: $PATCH_FILE
Size: $PATCH_SIZE
Checksum (SHA256): $CHECKSUM

Backend URL: $BACKEND_URL
App ID: $APP_ID

Status: ✅ Uploaded to Backend
Next: Client will detect and pull patch

To notify client of patch availability, run:
  /Users/admin/Documents/quicui2/scripts/notify_patch_available.sh
EOF

log_success "Patch reference created: $PATCH_DIR/PATCH_INFO.txt"

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║             ✅ PATCH READY FOR DEPLOYMENT             ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
log_info "Patch Information:"
cat "$PATCH_DIR/PATCH_INFO.txt"
echo ""
log_info "Next steps:"
echo "  1. Ensure app is running on device"
echo "  2. Run: /Users/admin/Documents/quicui2/scripts/notify_patch_available.sh"
echo "  3. Watch device logs for patch download and application"
echo ""

