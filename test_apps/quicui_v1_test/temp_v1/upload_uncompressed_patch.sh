#!/bin/bash

# Upload UNCOMPRESSED patch file to backend
set -e

BACKEND_URL="https://quicui-backend.onrender.com"
APP_ID="com.quicui.quicui_v1_test"
VERSION="2.0.0"
PATCH_ID="patch-v2.0.0"
PATCH_FILE="patch_v2.0.0.bsdiff"  # UNCOMPRESSED
HASH="4e0a43d4269078134afb775d256b67d23f86e8e8ff037a65b6ded9b1291b6dcd"

echo "🚀 Uploading QuicUI Patch v${VERSION} (UNCOMPRESSED)"
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

echo "Encoding patch file to base64..."
PATCH_BASE64=$(base64 -i "${PATCH_PATH}")

echo "Uploading uncompressed bsdiff patch..."

# Upload patch with base64 encoded file (NO compression field)
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
echo "✅ Patch uploaded successfully!"
echo ""
echo "Test update:"
echo "  1. Open app on device"
echo "  2. Tap 'Check for Updates'"
echo "  3. Should download and apply patch!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
