#!/bin/bash
# QuicUI iOS Patch Generator
# Generates bsdiff patches for iOS apps

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="${APP_NAME:-QuicUIIOSTest}"
BASE_VERSION="${BASE_VERSION:-1.0.0}"
NEW_VERSION="${NEW_VERSION:-1.0.1}"
BACKEND_URL="${BACKEND_URL:-http://localhost:8080}"
ARCHITECTURE="${ARCHITECTURE:-arm64}"

# Paths
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_APP_DIR="$PROJECT_DIR/test_apps/quicui_ios_test"
BUILD_DIR="$TEST_APP_DIR/build/ios/Release-iphoneos"
PATCHES_DIR="$PROJECT_DIR/patches/ios"

echo -e "${BLUE}🍎 QuicUI iOS Patch Generator${NC}"
echo "========================================"
echo ""
echo "Configuration:"
echo "  App Name:     $APP_NAME"
echo "  Base Version: $BASE_VERSION"
echo "  New Version:  $NEW_VERSION"
echo "  Backend:      $BACKEND_URL"
echo "  Architecture: $ARCHITECTURE"
echo ""

# Create patches directory
mkdir -p "$PATCHES_DIR"

# Step 1: Build base version
echo -e "${YELLOW}📦 Step 1: Building base version $BASE_VERSION...${NC}"
cd "$TEST_APP_DIR"

if [ ! -d "$BUILD_DIR" ]; then
    echo "Building iOS release..."
    flutter build ios --release --no-codesign
else
    echo "Using existing build..."
fi

# Find App.framework/App file (this is the AOT snapshot)
APP_FRAMEWORK="$BUILD_DIR/Runner.app/Frameworks/App.framework"
BASE_AOT="$APP_FRAMEWORK/App"

if [ ! -f "$BASE_AOT" ]; then
    echo -e "${RED}❌ Error: App executable not found at: $BASE_AOT${NC}"
    echo "Build the app first: flutter build ios --release --no-codesign"
    exit 1
fi

# Save base version
BASE_LIBAPP="$PATCHES_DIR/libapp_base_${BASE_VERSION}.so"
cp "$BASE_AOT" "$BASE_LIBAPP"
echo -e "${GREEN}✅ Base version saved: $BASE_LIBAPP${NC}"

# Display base file info
BASE_SIZE=$(stat -f%z "$BASE_LIBAPP")
echo "  Size: $(numfmt --to=iec-i --suffix=B $BASE_SIZE 2>/dev/null || echo "$BASE_SIZE bytes")"
echo ""

# Step 2: Prompt for code changes
echo -e "${YELLOW}✏️  Step 2: Make your code changes${NC}"
echo "  1. Edit lib/main.dart"
echo "  2. Change colors, text, add features, etc."
echo "  3. Press Enter when ready to build new version"
echo ""
read -p "Press Enter to continue..."
echo ""

# Step 3: Build new version
echo -e "${YELLOW}📦 Step 3: Building new version $NEW_VERSION...${NC}"
flutter build ios --release --no-codesign

# Get new AOT
NEW_AOT="$APP_FRAMEWORK/App"

if [ ! -f "$NEW_AOT" ]; then
    echo -e "${RED}❌ Error: New App executable not found${NC}"
    exit 1
fi

# Save new version
NEW_LIBAPP="$PATCHES_DIR/libapp_new_${NEW_VERSION}.so"
cp "$NEW_AOT" "$NEW_LIBAPP"
echo -e "${GREEN}✅ New version saved: $NEW_LIBAPP${NC}"

# Display new file info
NEW_SIZE=$(stat -f%z "$NEW_LIBAPP")
echo "  Size: $(numfmt --to=iec-i --suffix=B $NEW_SIZE 2>/dev/null || echo "$NEW_SIZE bytes")"
echo ""

# Step 4: Generate bsdiff patch
echo -e "${YELLOW}🔧 Step 4: Generating bsdiff patch...${NC}"

PATCH_NAME="${APP_NAME}_${BASE_VERSION}_to_${NEW_VERSION}_${ARCHITECTURE}"
PATCH_FILE="$PATCHES_DIR/${PATCH_NAME}.patch"

# Check if bsdiff is installed
if ! command -v bsdiff &> /dev/null; then
    echo -e "${RED}❌ Error: bsdiff not found${NC}"
    echo "Install it with: brew install bsdiff"
    exit 1
fi

bsdiff "$BASE_LIBAPP" "$NEW_LIBAPP" "$PATCH_FILE"
echo -e "${GREEN}✅ Patch generated: $PATCH_FILE${NC}"

# Get patch size
PATCH_SIZE=$(stat -f%z "$PATCH_FILE")
echo "  Size: $(numfmt --to=iec-i --suffix=B $PATCH_SIZE 2>/dev/null || echo "$PATCH_SIZE bytes")"
echo ""

# Step 5: Compress with xz
echo -e "${YELLOW}🗜️  Step 5: Compressing with xz...${NC}"

# Check if xz is installed
if ! command -v xz &> /dev/null; then
    echo -e "${RED}❌ Error: xz not found${NC}"
    echo "Install it with: brew install xz"
    exit 1
fi

xz -z -9 -k "$PATCH_FILE"  # -k to keep original
PATCH_FILE_XZ="${PATCH_FILE}.xz"

echo -e "${GREEN}✅ Compressed patch: $PATCH_FILE_XZ${NC}"

# Get compressed size
COMPRESSED_SIZE=$(stat -f%z "$PATCH_FILE_XZ")
echo "  Size: $(numfmt --to=iec-i --suffix=B $COMPRESSED_SIZE 2>/dev/null || echo "$COMPRESSED_SIZE bytes")"
echo ""

# Step 6: Generate checksum
echo -e "${YELLOW}🔐 Step 6: Generating checksum...${NC}"
CHECKSUM=$(shasum -a 256 "$PATCH_FILE_XZ" | awk '{print $1}')
echo "$CHECKSUM" > "${PATCH_FILE_XZ}.sha256"
echo -e "${GREEN}✅ Checksum: $CHECKSUM${NC}"
echo ""

# Step 7: Statistics
echo -e "${BLUE}📊 Statistics:${NC}"
echo "========================================"
printf "  Base size:       %10s\n" "$(numfmt --to=iec-i --suffix=B $BASE_SIZE 2>/dev/null || echo "$BASE_SIZE bytes")"
printf "  New size:        %10s\n" "$(numfmt --to=iec-i --suffix=B $NEW_SIZE 2>/dev/null || echo "$NEW_SIZE bytes")"
printf "  Patch size:      %10s\n" "$(numfmt --to=iec-i --suffix=B $PATCH_SIZE 2>/dev/null || echo "$PATCH_SIZE bytes")"
printf "  Compressed:      %10s\n" "$(numfmt --to=iec-i --suffix=B $COMPRESSED_SIZE 2>/dev/null || echo "$COMPRESSED_SIZE bytes")"

REDUCTION=$((100 - COMPRESSED_SIZE * 100 / NEW_SIZE))
printf "  Reduction:       %10s%%\n" "$REDUCTION"
echo ""

# Step 8: Upload to backend
echo -e "${YELLOW}📤 Step 8: Uploading to backend...${NC}"
echo "  URL: $BACKEND_URL/api/v1/patches"
echo ""

curl -X POST "$BACKEND_URL/api/v1/patches" \
  -F "file=@$PATCH_FILE_XZ" \
  -F "appId=$APP_NAME" \
  -F "baseVersion=$BASE_VERSION" \
  -F "newVersion=$NEW_VERSION" \
  -F "platform=ios" \
  -F "architecture=$ARCHITECTURE" \
  -F "checksum=$CHECKSUM"

echo ""
echo ""
echo -e "${GREEN}✅ Patch uploaded successfully!${NC}"
echo ""

# Summary
echo -e "${BLUE}🎉 iOS Patch Generation Complete!${NC}"
echo "========================================"
echo ""
echo "Files created:"
echo "  • $BASE_LIBAPP"
echo "  • $NEW_LIBAPP"
echo "  • $PATCH_FILE"
echo "  • $PATCH_FILE_XZ"
echo "  • ${PATCH_FILE_XZ}.sha256"
echo ""
echo "Next steps:"
echo "  1. Test patch on device"
echo "  2. Run app and check for updates"
echo "  3. Verify patch application"
echo "  4. Monitor crash analytics"
echo ""
echo -e "${GREEN}Done!${NC}"
