#!/bin/bash

# QuicUI Code Push - Generate AOT Snapshot Patch (Shorebird-style)
# This script generates a patch by diffing libapp.so files from release builds

set -e

# Configuration
FLUTTER_ROOT="/Users/admin/Documents/quicui2/forks/flutter-official"
APP_DIR="/Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1"
PATCH_DIR="/tmp/quicui_aot_patch"
BACKEND_URL="http://localhost:8080"
TARGET_ARCH="arm64-v8a"  # Can be: arm64-v8a, armeabi-v7a, x86_64

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_step() { echo -e "${BLUE}>>> $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_info() { echo -e "${YELLOW}ℹ️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   QuicUI Code Push - AOT Snapshot Patch Generator       ║"
echo "║   (Shorebird-style Release Mode Patching)               ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Verify backend is running
log_step "Step 1: Verify Backend Server"
if ! curl -s "$BACKEND_URL/health" > /dev/null 2>&1; then
    log_error "Backend server not running at $BACKEND_URL"
    echo "Start backend with: cd packages/quicui_backend && dart run bin/server.dart &"
    exit 1
fi
log_success "Backend is running"

# Step 2: Create patch directory
log_step "Step 2: Prepare Patch Directory"
rm -rf "$PATCH_DIR"
mkdir -p "$PATCH_DIR"/{baseline,patched}
log_success "Patch directory ready: $PATCH_DIR"

# Step 3: Extract baseline libapp.so (v1.0.0)
log_step "Step 3: Extract v1.0.0 Baseline AOT Snapshot"
cd "$APP_DIR"

# Ensure QuicUI fork is being used
export PATH="$FLUTTER_ROOT/bin:$PATH"

BASELINE_APK="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$BASELINE_APK" ]; then
    log_error "v1.0.0 release APK not found. Build it first with:"
    echo "   bash /Users/admin/Documents/quicui2/scripts/build_with_quicui_fork.sh"
    exit 1
fi

# Extract libapp.so from baseline APK
log_info "Extracting libapp.so from v1.0.0 APK (arch: $TARGET_ARCH)..."
unzip -q "$BASELINE_APK" "lib/$TARGET_ARCH/libapp.so" -d "$PATCH_DIR/baseline" 2>/dev/null

BASELINE_SNAPSHOT="$PATCH_DIR/baseline/lib/$TARGET_ARCH/libapp.so"
if [ ! -f "$BASELINE_SNAPSHOT" ]; then
    log_error "Could not extract libapp.so from baseline APK"
    log_info "Available architectures in APK:"
    unzip -l "$BASELINE_APK" | grep "lib/.*\.so"
    exit 1
fi

BASELINE_SIZE=$(du -h "$BASELINE_SNAPSHOT" | cut -f1)
BASELINE_HASH=$(shasum -a 256 "$BASELINE_SNAPSHOT" | cut -d' ' -f1)
log_success "Baseline snapshot extracted: $BASELINE_SIZE"
log_info "Baseline hash: ${BASELINE_HASH:0:16}..."

# Step 4: Make code changes for v1.0.1
log_step "Step 4: Apply Changes for v1.0.1"
cd "$APP_DIR/lib"

# Create a backup
if [ ! -f main.dart.original ]; then
    cp main.dart main.dart.original
fi

# Make a visible change
log_info "Modifying code to show patch version..."
sed -i.bak "s/'Patch Version:', 'v1.0.1'/'Patch Version:', 'v1.0.1 - LIVE ✨'/g" main.dart

# Also update version in pubspec.yaml
cd "$APP_DIR"
sed -i.bak 's/version: 1.0.0+1/version: 1.0.1+2/g' pubspec.yaml

log_success "Code changes applied for v1.0.1"

# Step 5: Build v1.0.1 release APK
log_step "Step 5: Build v1.0.1 Release APK"
cd "$APP_DIR"

log_info "Running flutter clean..."
flutter clean > /dev/null 2>&1

log_info "Getting dependencies..."
flutter pub get > /dev/null 2>&1

log_info "Building v1.0.1 release APK..."
flutter build apk --release > "$PATCH_DIR/build.log" 2>&1

NEW_APK="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$NEW_APK" ]; then
    log_error "v1.0.1 build failed. Check: $PATCH_DIR/build.log"
    exit 1
fi

log_success "v1.0.1 APK built ($(du -h $NEW_APK | cut -f1))"

# Step 6: Extract patched libapp.so (v1.0.1)
log_step "Step 6: Extract v1.0.1 Patched AOT Snapshot"

log_info "Extracting libapp.so from v1.0.1 APK..."
unzip -q "$NEW_APK" "lib/$TARGET_ARCH/libapp.so" -d "$PATCH_DIR/patched" 2>/dev/null

PATCHED_SNAPSHOT="$PATCH_DIR/patched/lib/$TARGET_ARCH/libapp.so"
if [ ! -f "$PATCHED_SNAPSHOT" ]; then
    log_error "Could not extract libapp.so from patched APK"
    exit 1
fi

PATCHED_SIZE=$(du -h "$PATCHED_SNAPSHOT" | cut -f1)
PATCHED_HASH=$(shasum -a 256 "$PATCHED_SNAPSHOT" | cut -d' ' -f1)
log_success "Patched snapshot extracted: $PATCHED_SIZE"
log_info "Patched hash: ${PATCHED_HASH:0:16}..."

# Step 7: Generate patch (simple full snapshot replacement for Phase 1)
log_step "Step 7: Generate Patch Artifact"

log_info "Phase 1 Implementation: Full snapshot replacement"
log_info "Creating patch package..."

# For Phase 1, the "patch" is simply the new libapp.so
# In Phase 2, we'll implement a binary differ to create minimal patches
cp "$PATCHED_SNAPSHOT" "$PATCH_DIR/patch_1.0.1_$TARGET_ARCH.so"

PATCH_FILE="$PATCH_DIR/patch_1.0.1_$TARGET_ARCH.so"
PATCH_SIZE=$(du -h "$PATCH_FILE" | cut -f1)
log_success "Patch created: $PATCH_SIZE"

# Calculate size comparison
BASELINE_BYTES=$(stat -f%z "$BASELINE_SNAPSHOT")
PATCHED_BYTES=$(stat -f%z "$PATCHED_SNAPSHOT")
DIFF_BYTES=$((PATCHED_BYTES - BASELINE_BYTES))
DIFF_PERCENT=$(echo "scale=2; ($DIFF_BYTES * 100) / $BASELINE_BYTES" | bc)

log_info "Size comparison:"
echo "  Baseline: $BASELINE_SIZE ($BASELINE_BYTES bytes)"
echo "  Patched:  $PATCH_SIZE ($PATCHED_BYTES bytes)"
echo "  Diff:     ${DIFF_PERCENT}% ($DIFF_BYTES bytes)"

# Step 8: Create metadata
log_step "Step 8: Create Patch Metadata"

METADATA_FILE="$PATCH_DIR/metadata.json"
cat > "$METADATA_FILE" <<EOF
{
  "version": "1.0.1",
  "build_number": "2",
  "patch_format": "aot_snapshot",
  "architecture": "$TARGET_ARCH",
  "baseline_version": "1.0.0",
  "baseline_hash": "$BASELINE_HASH",
  "patch_hash": "$PATCHED_HASH",
  "patch_size": $PATCHED_BYTES,
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "implementation": "phase1_full_replacement"
}
EOF

log_success "Metadata created"
cat "$METADATA_FILE"

# Step 9: Upload patch to backend
log_step "Step 9: Upload Patch to Backend"

log_info "Uploading patch artifact..."
UPLOAD_RESPONSE=$(curl -s -X POST \
  -F "patchFile=@$PATCH_FILE" \
  -F "metadata=@$METADATA_FILE" \
  -F "appId=com.quicui.testapp" \
  -F "version=1.0.1" \
  -F "architecture=$TARGET_ARCH" \
  "$BACKEND_URL/api/v1/patches/upload" 2>&1)

if echo "$UPLOAD_RESPONSE" | grep -q "success\|uploaded"; then
    log_success "Patch uploaded successfully"
    echo "$UPLOAD_RESPONSE"
else
    log_error "Upload failed"
    echo "Response: $UPLOAD_RESPONSE"
fi

# Step 10: Restore original code
log_step "Step 10: Restore Original Code"
cd "$APP_DIR/lib"
if [ -f main.dart.original ]; then
    mv main.dart.original main.dart
fi
cd "$APP_DIR"
if [ -f pubspec.yaml.bak ]; then
    mv pubspec.yaml.bak pubspec.yaml
fi
log_success "Code restored to v1.0.0"

# Summary
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    Patch Generation Complete              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
log_success "Patch artifacts created in: $PATCH_DIR"
echo ""
echo "Files generated:"
echo "  📦 Patch: $PATCH_FILE"
echo "  📄 Metadata: $METADATA_FILE"
echo ""
echo "Next steps:"
echo "  1. Install baseline v1.0.0 APK on device"
echo "  2. App will detect and download the patch"
echo "  3. Patch will be applied on next app restart"
echo ""
log_info "Note: Phase 1 uses full snapshot replacement (~${PATCH_SIZE})"
log_info "Phase 2 will implement linker for minimal patches (~50KB)"
echo ""
