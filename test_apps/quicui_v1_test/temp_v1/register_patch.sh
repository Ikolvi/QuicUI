#!/bin/bash

# QuicUI Patch Registration Script
# Registers patch metadata with the backend

set -e

BACKEND_URL="https://quicui-backend.onrender.com"
APP_ID="com.quicui.quicui_v1_test"
VERSION="2.0.0"
PATCH_ID="patch-v2.0.0"
PATCH_FILE="patch_v2.0.0.bsdiff.xz"
HASH="173a47f814a1ec06b38b78479a798caf0f91e45bf900f9f90c6c4c03a975be89"

echo "🚀 Registering QuicUI Patch v${VERSION}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Backend: ${BACKEND_URL}"
echo "App ID: ${APP_ID}"
echo "Patch ID: ${PATCH_ID}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get absolute path to patch file
PATCH_PATH="$(cd "$(dirname "$0")" && pwd)/${PATCH_FILE}"
PATCH_SIZE=$(wc -c < "${PATCH_PATH}" | tr -d ' ')

echo "Registering patch metadata..."

# Register patch with backend
RESPONSE=$(curl -s -X POST "${BACKEND_URL}/api/v1/patches/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"patchId\": \"${PATCH_ID}\",
    \"version\": \"${VERSION}\",
    \"appId\": \"${APP_ID}\",
    \"uncompressedPath\": \"${PATCH_PATH}\",
    \"compressedPaths\": {
      \"xz\": \"${PATCH_PATH}\"
    },
    \"uncompressedSize\": ${PATCH_SIZE},
    \"compressedSizes\": {
      \"xz\": ${PATCH_SIZE}
    },
    \"hash\": \"${HASH}\"
  }")

echo "${RESPONSE}"
echo ""

# Verify registration
echo "Verifying registration..."
LIST_RESPONSE=$(curl -s "${BACKEND_URL}/api/v1/patches")
echo "${LIST_RESPONSE}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Patch registered successfully!"
echo ""
echo "Test update:"
echo "  1. Open app on device"
echo "  2. Tap 'Check for Updates'"
echo "  3. App should detect v${VERSION}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
