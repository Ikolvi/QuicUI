#!/bin/bash

# QuicUI Code Push - Generate Real Patch from App Builds
# This script generates a real binary patch from v1.0.0 to v1.0.1

set -e

# Configuration
FLUTTER_ROOT="/Users/admin/Documents/quicui2/forks/flutter-official"
APP_DIR="/Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1"
COMPILER_DIR="/Users/admin/Documents/quicui2/packages/quicui_compiler"
PATCH_DIR="/tmp/quicui_real_patch"
BACKEND_URL="http://localhost:8080"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_step() { echo -e "${BLUE}>>> $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_info() { echo -e "${YELLOW}ℹ️  $1${NC}"; }

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║     QuicUI Code Push - Generate Real Patch System     ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Verify backend is running
log_step "Step 1: Verify Backend Server"
if ! curl -s "$BACKEND_URL/health" > /dev/null 2>&1; then
    echo "❌ Backend server not running at $BACKEND_URL"
    echo "Start backend with: bash /Users/admin/Documents/quicui2/scripts/start_backend_dev.sh"
    exit 1
fi
log_success "Backend is running"

# Step 2: Create patch directory
log_step "Step 2: Prepare Patch Directory"
rm -rf "$PATCH_DIR"
mkdir -p "$PATCH_DIR"
log_success "Patch directory ready: $PATCH_DIR"

# Step 3: Save v1.0.0 kernel (baseline)
log_step "Step 3: Extract v1.0.0 Baseline Kernel"
cd "$APP_DIR"

# Ensure QuicUI fork is being used
export PATH="$FLUTTER_ROOT/bin:$PATH"

# Extract kernel from current build (profile mode for code push)
OLD_APK="$APP_DIR/build/app/outputs/flutter-apk/app-profile.apk"
if [ ! -f "$OLD_APK" ]; then
    echo "❌ v1.0.0 profile APK not found. Build it first with:"
    echo "   bash /Users/admin/Documents/quicui2/scripts/build_with_quicui_fork.sh"
    exit 1
fi

# Extract kernel from APK
log_info "Extracting kernel from v1.0.0 APK..."
unzip -q "$OLD_APK" "assets/flutter_assets/kernel_blob.bin" -d "$PATCH_DIR/old_build" 2>/dev/null || true

if [ ! -f "$PATCH_DIR/old_build/assets/flutter_assets/kernel_blob.bin" ]; then
    echo "❌ Could not extract kernel from v1.0.0 APK"
    exit 1
fi

cp "$PATCH_DIR/old_build/assets/flutter_assets/kernel_blob.bin" "$PATCH_DIR/old.kernel"
log_success "v1.0.0 kernel extracted ($(du -h $PATCH_DIR/old.kernel | cut -f1))"

# Step 4: Make a visual change for v1.0.1
log_step "Step 4: Apply Changes for v1.0.1"
cd "$APP_DIR/lib"

# Create a backup
cp main.dart main.dart.bak

# Make a visible change
sed -i '' "s/'Patch Version:', 'v1.0.1'/'Patch Version:', 'v1.0.1 - LIVE ✨'/g" main.dart

log_success "Code changes applied for v1.0.1"

# Step 5: Build v1.0.1
log_step "Step 5: Build v1.0.1 APK"
cd "$APP_DIR"

flutter clean > /dev/null 2>&1
flutter pub get > /dev/null 2>&1

log_info "Building v1.0.1..."
flutter build apk --release > "$PATCH_DIR/build.log" 2>&1

NEW_APK="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$NEW_APK" ]; then
    echo "❌ v1.0.1 build failed. Check: $PATCH_DIR/build.log"
    exit 1
fi

log_success "v1.0.1 APK built ($(du -h $NEW_APK | cut -f1))"

# Step 6: Extract v1.0.1 kernel
log_step "Step 6: Extract v1.0.1 Kernel"
unzip -q "$NEW_APK" "assets/flutter_assets/kernel_blob.bin" -d "$PATCH_DIR/new_build" 2>/dev/null || true

if [ ! -f "$PATCH_DIR/new_build/assets/flutter_assets/kernel_blob.bin" ]; then
    echo "❌ Could not extract kernel from v1.0.1 APK"
    exit 1
fi

cp "$PATCH_DIR/new_build/assets/flutter_assets/kernel_blob.bin" "$PATCH_DIR/new.kernel"
log_success "v1.0.1 kernel extracted ($(du -h $PATCH_DIR/new.kernel | cut -f1))"

# Step 7: Generate patch using compiler
log_step "Step 7: Generate Binary Patch"
cd "$COMPILER_DIR"

log_info "Running QuicUI compiler..."
dart run bin/quicui_compiler.dart build \
  "$PATCH_DIR/old.kernel" \
  "$PATCH_DIR/new.kernel" \
  --version=1.0.1 \
  --description="Real patch: UI improvements and live indicator" \
  --output-dir="$PATCH_DIR" > "$PATCH_DIR/compiler.log" 2>&1

if [ $? -ne 0 ]; then
    echo "❌ Patch compilation failed. Check: $PATCH_DIR/compiler.log"
    cat "$PATCH_DIR/compiler.log"
    exit 1
fi

PATCH_FILE="$PATCH_DIR/patch_1.0.1.bin"
if [ ! -f "$PATCH_FILE" ]; then
    echo "❌ Patch file not generated"
    exit 1
fi

log_success "Patch generated ($(du -h $PATCH_FILE | cut -f1))"

# Step 8: Create metadata
log_step "Step 8: Create Patch Metadata"
CHECKSUM=$(shasum -a 256 "$PATCH_FILE" | awk '{print $1}')
PATCH_SIZE=$(stat -f%z "$PATCH_FILE")

cat > "$PATCH_DIR/metadata.json" << EOF
{
  "patchId": "patch_v1_0_1_$(date +%s)",
  "version": "1.0.1",
  "baseVersion": "1.0.0",
  "description": "Real binary patch: UI improvements",
  "changes": [
    "Added live indicator to patch version",
    "Real kernel-level binary diff"
  ],
  "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "size": $PATCH_SIZE,
  "checksum": "$CHECKSUM",
  "releaseNotes": "QuicUI Code Push v1.0.1 - Real Patch\\n\\nChanges:\\n- UI improvements\\n- Live patch indicator\\n\\nThis is a real binary patch."
}
EOF

log_success "Metadata created"

# Step 9: Upload to backend
log_step "Step 9: Upload to Backend"
log_info "Uploading to $BACKEND_URL/api/v1/patches/upload"

UPLOAD_RESPONSE=$(curl -s -X POST \
  -F "patchFile=@$PATCH_FILE" \
  -F "metadata=@$PATCH_DIR/metadata.json" \
  "$BACKEND_URL/api/v1/patches/upload" 2>&1)

log_success "Patch uploaded to backend"
log_info "Response: $UPLOAD_RESPONSE"

# Step 10: Restore original main.dart
log_step "Step 10: Cleanup"
cd "$APP_DIR/lib"
mv main.dart.bak main.dart
log_success "Original code restored"

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║          ✅ REAL PATCH READY FOR TESTING               ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Patch Information:"
echo "  Version: 1.0.1"
echo "  Size: $(du -h $PATCH_FILE | cut -f1)"
echo "  Checksum: $CHECKSUM"
echo "  Location: $PATCH_FILE"
echo ""
echo "Next steps:"
echo "  1. Ensure v1.0.0 app is running on device"
echo "  2. App will auto-detect patch from backend"
echo "  3. Watch device logs for patch download and application"
echo ""
echo "To install v1.0.0 baseline:"
echo "  bash /Users/admin/Documents/quicui2/scripts/install_and_launch.sh"
echo ""
