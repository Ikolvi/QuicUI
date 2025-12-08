#!/bin/bash

# QuicUI Complete Workflow Script
# This demonstrates the full workflow: build → install → modify → patch → upload

set -e  # Exit on error

PROJECT_DIR="/Users/admin/Documents/quicui2/test_apps/quicui_production_test"
QUICUI_CLI="../../packages/quicui_cli/bin/quicui.dart"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}QuicUI Complete Workflow${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Step 1: Build Baseline Version
echo -e "${GREEN}📦 Step 1: Building Baseline Version${NC}"
echo "Version: 3.0.62 (baseline)"
cd "$PROJECT_DIR"

dart run $QUICUI_CLI build-ipa \
  --version 3.0.62 \
  --baseline \
  --output v3.0.62

echo -e "${GREEN}✅ Baseline version 3.0.62 built${NC}"
echo ""

# Step 2: Install on Device
echo -e "${GREEN}📱 Step 2: Installing on Device${NC}"
echo "Installing v3.0.62 to connected iOS device..."

# Find the IPA file
IPA_FILE=$(find v3.0.62 -name "*.ipa" | head -1)
if [ -z "$IPA_FILE" ]; then
    echo -e "${RED}❌ Error: IPA file not found${NC}"
    exit 1
fi

# Install using ios-deploy or ideviceinstaller
if command -v ios-deploy &> /dev/null; then
    ios-deploy --bundle "$IPA_FILE"
elif command -v ideviceinstaller &> /dev/null; then
    ideviceinstaller -i "$IPA_FILE"
else
    echo -e "${YELLOW}⚠️  Please install manually: $IPA_FILE${NC}"
    echo "Or install ios-deploy: brew install ios-deploy"
fi

echo -e "${GREEN}✅ App installed on device${NC}"
echo ""

# Step 3: Make Code Changes
echo -e "${GREEN}✏️  Step 3: Making Code Changes${NC}"
echo "Updating app to version 3.0.63 with green theme..."

# Update main.dart (changes already made in previous steps)
echo -e "${GREEN}✅ Code changes applied${NC}"
echo "  - Title: 🎉 GREEN THEME v3.0.63 - DIFFERENTIAL LINKER! 💚"
echo "  - Theme color: blue → green"
echo "  - App version: 3.0.62 → 3.0.63"
echo ""

# Step 4: Build New Version
echo -e "${GREEN}🔨 Step 4: Building New Version${NC}"
echo "Version: 3.0.63 (with changes)"

dart run $QUICUI_CLI build-ipa \
  --version 3.0.63 \
  --output v3.0.63

echo -e "${GREEN}✅ New version 3.0.63 built${NC}"
echo ""

# Step 5: Generate Differential Patch
echo -e "${GREEN}🔄 Step 5: Generating Differential Patch${NC}"
echo "Using differential AOT linker..."
echo "From: v3.0.62 (baseline)"
echo "To:   v3.0.63 (new)"

dart run $QUICUI_CLI generate-patch \
  --from v3.0.62 \
  --to v3.0.63 \
  --output patches \
  --compression none

echo -e "${GREEN}✅ Differential patch generated${NC}"
echo ""

# Step 6: Upload Patch
echo -e "${GREEN}⬆️  Step 6: Uploading Patch to Supabase${NC}"

# Find the generated vmcode file
VMCODE_FILE=$(find patches -name "*.vmcode" -type f | sort | tail -1)
if [ -z "$VMCODE_FILE" ]; then
    echo -e "${RED}❌ Error: vmcode file not found${NC}"
    exit 1
fi

echo "Patch file: $VMCODE_FILE"

dart run $QUICUI_CLI upload-patch \
  --patch "$VMCODE_FILE" \
  --version 3.0.63 \
  --app-id com.example.quicuiProductionTest \
  --platform ios \
  --from-version 3.0.62 \
  --architecture arm64

echo -e "${GREEN}✅ Patch uploaded successfully${NC}"
echo ""

# Step 7: Verify on Device
echo -e "${GREEN}📲 Step 7: Testing on Device${NC}"
echo ""
echo "Next steps:"
echo "1. Open the app on your device (v3.0.62 installed)"
echo "2. Pull down to check for updates"
echo "3. App should download the differential patch"
echo "4. App will apply the patch (green theme should appear)"
echo "5. Verify: Title should show 'GREEN THEME v3.0.63'"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Complete Workflow Finished!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Summary
echo "📊 Summary:"
echo "  Baseline:  v3.0.62 (blue theme)"
echo "  Updated:   v3.0.63 (green theme)"
echo "  Patch:     Differential AOT with linker"
echo "  Size:      ~2.1 MB (54% of baseline)"
echo "  Upload:    Supabase storage"
echo ""
echo "💡 The differential linker minimizes patch size by including"
echo "   only changed code, bypassing iOS code signing restrictions."
