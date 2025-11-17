#!/bin/bash

# Upload patch v2.0.0 to QuicUI Backend

set -e

BACKEND_URL="https://quicui-backend.onrender.com"
PATCH_FILE="patch_v2.0.0.bsdiff.xz"
APP_ID="com.quicui.quicui_v1_test"
VERSION="2.0.0"
HASH="173a47f814a1ec06b38b78479a798caf0f91e45bf900f9f90c6c4c03a975be89"

echo "🚀 Uploading QuicUI Patch v2.0.0"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Backend: $BACKEND_URL"
echo "App ID: $APP_ID"
echo "Version: $VERSION"
echo "Patch: $PATCH_FILE"
echo "Hash: $HASH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if backend is accessible
echo "Checking backend connectivity..."
if ! curl -sf "$BACKEND_URL/api/v1/patches" > /dev/null; then
    echo "❌ Backend is not accessible!"
    echo "Please ensure backend is deployed to Render.com"
    exit 1
fi
echo "✅ Backend is accessible"
echo ""

# Upload patch
echo "Uploading patch..."
curl -X POST "$BACKEND_URL/api/v1/patches" \
  -H "Content-Type: multipart/form-data" \
  -H "Authorization: Bearer test-secret-123" \
  -F "patchFile=@$PATCH_FILE" \
  -F "appId=$APP_ID" \
  -F "version=$VERSION" \
  -F "hash=$HASH" \
  -F "compression=xz"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Patch uploaded successfully!"
echo ""
echo "Test update:"
echo "  1. Open app on device"
echo "  2. Tap 'Check for Updates'"
echo "  3. App should download and apply patch"
echo "  4. Restart app to see v2 changes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
