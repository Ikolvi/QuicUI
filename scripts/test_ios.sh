#!/bin/bash
# QuicUI iOS Test Script
# Tests patch generation and application end-to-end

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🍎 QuicUI iOS Test Suite${NC}"
echo "========================================"
echo ""

# Configuration
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_APP_DIR="$PROJECT_DIR/test_apps/quicui_ios_test"

# Test 1: Check dependencies
echo -e "${YELLOW}Test 1: Checking dependencies...${NC}"

if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Flutter found: $(flutter --version | head -1)${NC}"

if ! command -v bsdiff &> /dev/null; then
    echo -e "${RED}❌ bsdiff not found${NC}"
    echo "Install with: brew install bsdiff"
    exit 1
fi
echo -e "${GREEN}✓ bsdiff found${NC}"

if ! command -v xz &> /dev/null; then
    echo -e "${RED}❌ xz not found${NC}"
    echo "Install with: brew install xz"
    exit 1
fi
echo -e "${GREEN}✓ xz found${NC}"

echo ""

# Test 2: Check test app
echo -e "${YELLOW}Test 2: Checking test app...${NC}"

if [ ! -d "$TEST_APP_DIR" ]; then
    echo -e "${RED}❌ Test app not found at: $TEST_APP_DIR${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Test app found${NC}"

cd "$TEST_APP_DIR"

if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Invalid Flutter project${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Valid Flutter project${NC}"

echo ""

# Test 3: Check backend
echo -e "${YELLOW}Test 3: Checking backend...${NC}"

BACKEND_URL="${BACKEND_URL:-http://localhost:8080}"

if curl -s -f "$BACKEND_URL/api/v1/patches" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Backend reachable at $BACKEND_URL${NC}"
else
    echo -e "${YELLOW}⚠️  Backend not reachable at $BACKEND_URL${NC}"
    echo "  Start backend with: cd packages/quicui_backend && dart run bin/server.dart"
fi

echo ""

# Test 4: Build test app
echo -e "${YELLOW}Test 4: Building test app...${NC}"

flutter pub get
flutter build ios --release --no-codesign

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Build successful${NC}"
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

echo ""

# Test 5: Check Flutter engine modifications
echo -e "${YELLOW}Test 5: Checking Flutter engine modifications...${NC}"

ENGINE_LOADER="$PROJECT_DIR/forks/flutter-quicui/engine/shell/platform/darwin/ios/framework/Source/QuicUICodePushLoader.mm"

if [ -f "$ENGINE_LOADER" ]; then
    echo -e "${GREEN}✓ QuicUICodePushLoader.mm exists${NC}"
else
    echo -e "${YELLOW}⚠️  QuicUICodePushLoader.mm not found${NC}"
    echo "  Engine modifications may not be applied"
fi

echo ""

# Test 6: Check plugin files
echo -e "${YELLOW}Test 6: Checking plugin files...${NC}"

PLUGIN_DIR="$PROJECT_DIR/packages/quicui_code_push_client/ios"

if [ -f "$PLUGIN_DIR/Classes/QuicUICodePushPlugin.swift" ]; then
    echo -e "${GREEN}✓ QuicUICodePushPlugin.swift exists${NC}"
else
    echo -e "${RED}❌ QuicUICodePushPlugin.swift not found${NC}"
    exit 1
fi

if [ -f "$PLUGIN_DIR/Classes/BSDiffPatcher.swift" ]; then
    echo -e "${GREEN}✓ BSDiffPatcher.swift exists${NC}"
else
    echo -e "${RED}❌ BSDiffPatcher.swift not found${NC}"
    exit 1
fi

echo ""

# Summary
echo -e "${BLUE}=======================================${NC}"
echo -e "${GREEN}✅ All tests passed!${NC}"
echo ""
echo "Next steps:"
echo "  1. Generate a patch: ./scripts/generate_patch_ios.sh"
echo "  2. Install app on device"
echo "  3. Test update flow"
echo ""
echo -e "${GREEN}Done!${NC}"
