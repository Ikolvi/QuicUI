#!/bin/bash

# Upload patch using multipart/form-data (no base64, direct binary)
set -e

BACKEND_URL="https://quicui-backend.onrender.com"
APP_ID="com.quicui.quicui_v1_test"
VERSION="2.0.0"
PATCH_ID="patch-v2.0.0"
PATCH_FILE="patch_v2.0.0.bsdiff"  # UNCOMPRESSED BSDIFF

echo "🚀 Uploading QuicUI Patch v${VERSION} (via multipart form)"
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

echo "File size: ${PATCH_SIZE} bytes"
echo "SHA-256: ${HASH}"
echo ""

# For now, just use the base64 upload for the small bsdiff file
# In production, would use multipart/form-data

echo "Note: Using standard BSDIFF40 format which is NOT supported by current native code"
echo "      The native BsDiffPatcher expects custom QUICUI01 format"
echo "      This will fail until we implement proper BSDIFF40 support"
echo ""
echo "Alternative: Generate patch using custom format or use a different approach"
