#!/bin/bash

# Test Patch Generation and Push
# Uses QuicUI compiler to generate and push a test patch

set -e

COMPILER_DIR="/Users/admin/Documents/quicui2/packages/quicui_compiler"
OUTPUT_DIR="/tmp/quicui_patches"
PATCH_VERSION="1.0.1"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     QuicUI Code Push - Test Patch Generation & Push       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Step 1: Create dummy kernel files for testing
echo -e "${BLUE}Step 1: Creating test kernel files...${NC}"
echo "old-kernel-data-v1.0.0" > "$OUTPUT_DIR/old.kernel"
echo "new-kernel-data-v1.0.1-with-improvements" > "$OUTPUT_DIR/new.kernel"
echo -e "${GREEN}✅ Test kernels created${NC}\n"

# Step 2: Generate patch using compiler
echo -e "${BLUE}Step 2: Generating patch with QuicUI compiler...${NC}"
cd "$COMPILER_DIR"

dart run bin/quicui_compiler.dart build \
  "$OUTPUT_DIR/old.kernel" \
  "$OUTPUT_DIR/new.kernel" \
  --version="$PATCH_VERSION" \
  --description="Test patch: Performance improvements and bug fixes" \
  --output-dir="$OUTPUT_DIR"

if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Patch generation failed${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Patch generated${NC}\n"

# Step 3: Check if patch files were created
echo -e "${BLUE}Step 3: Verifying generated files...${NC}"
if [ -f "$OUTPUT_DIR/$PATCH_VERSION.patch" ]; then
  PATCH_SIZE=$(du -h "$OUTPUT_DIR/$PATCH_VERSION.patch" | cut -f1)
  echo -e "${GREEN}✅ Patch file: $PATCH_SIZE${NC}"
else
  echo -e "${YELLOW}⚠️  Patch file not found (may be in compiler output)${NC}"
fi

if [ -f "$OUTPUT_DIR/$PATCH_VERSION.manifest.json" ]; then
  echo -e "${GREEN}✅ Manifest file found${NC}"
fi
echo ""

# Step 4: Push patch to server
echo -e "${BLUE}Step 4: Uploading patch to code push server...${NC}"
dart run bin/quicui_compiler.dart upload \
  "$PATCH_VERSION" \
  --service-url="http://localhost:8080" \
  --app-id="com.quicui.quicui_test_app" \
  --output-dir="$OUTPUT_DIR"

echo -e "${GREEN}✅ Patch uploaded${NC}\n"

# Step 5: Verify patch on server
echo -e "${BLUE}Step 5: Checking server for available patches...${NC}"
sleep 1

RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/patches/check \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-secret" \
  -d "{
    \"appId\": \"com.quicui.quicui_test_app\",
    \"version\": \"1.0.0\",
    \"platform\": \"flutter\"
  }")

echo -e "${YELLOW}Server response:${NC}"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Test Complete ✅                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}📱 Next steps:${NC}"
echo "1. On your device, open the QuicUI test app"
echo "2. The app should check for patches from the server"
echo "3. Patch v$PATCH_VERSION should be offered to download"
echo "4. Accept and apply the patch"
echo "5. Verify app updates without restart"
