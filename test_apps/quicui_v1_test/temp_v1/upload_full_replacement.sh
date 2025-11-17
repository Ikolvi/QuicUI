#!/bin/bash

# Upload FULL libapp.so as patch (not diff)
set -e

BACKEND_URL="https://quicui-backend.onrender.com"
APP_ID="com.quicui.quicui_v1_test"
VERSION="2.0.0"
PATCH_ID="patch-v2.0.0"
PATCH_FILE="v2_extracted/lib/arm64-v8a/libapp.so"  # FULL LIBAPP.SO

echo "🚀 Uploading QuicUI Patch v${VERSION} (FULL REPLACEMENT)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Backend: ${BACKEND_URL}"
echo "App ID: ${APP_ID}"
echo "Patch ID: ${PATCH_ID}"
echo "File: ${PATCH_FILE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get absolute path to patch file
PATCH_PATH="$(cd "$(dirname "$0")" && pwd)/${PATCH_FILE}"

if [ ! -f "${PATCH_PATH}" ]; then
  echo "❌ Error: Patch file not found: ${PATCH_PATH}"
  exit 1
fi

PATCH_SIZE=$(wc -c < "${PATCH_PATH}" | tr -d ' ')
HASH=$(shasum -a 256 "${PATCH_PATH}" | awk '{print $1}')

echo "File size: ${PATCH_SIZE} bytes ($(echo "scale=2; ${PATCH_SIZE}/1024/1024" | bc) MB)"
echo "SHA-256: ${HASH}"
echo ""
echo "Encoding file to base64 (this may take a moment for 3.5MB file)..."
PATCH_BASE64=$(base64 -i "${PATCH_PATH}")

echo "Uploading full libapp.so as patch..."

# Upload full libapp.so as patch (NO compression, no diff)
RESPONSE=$(curl -s -X POST "${BACKEND_URL}/api/v1/patches/upload" \
  -H "Content-Type: application/json" \
  -d "{
    \"patchId\": \"${PATCH_ID}\",
    \"version\": \"${VERSION}\",
    \"appId\": \"${APP_ID}\",
    \"size\": ${PATCH_SIZE},
    \"hash\": \"${HASH}\",
    \"fileData\": \"${PATCH_BASE64}\"
  }")

echo "${RESPONSE}"
echo ""

# Verify upload
echo "Verifying patch availability..."
LIST_RESPONSE=$(curl -s "${BACKEND_URL}/api/v1/patches")
echo "${LIST_RESPONSE}"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Full libapp.so uploaded as patch!"
echo ""
echo "Note: This is a FULL REPLACEMENT (3.5MB)"
echo "      Native code will detect this and copy directly"
echo ""
echo "Test update:"
echo "  1. Open app on device"
echo "  2. Tap 'Check for Updates'"
echo "  3. Download 3.5MB and install!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
