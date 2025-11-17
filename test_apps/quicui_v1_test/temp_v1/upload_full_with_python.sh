#!/bin/bash

# Upload FULL libapp.so using file streaming
set -e

BACKEND_URL="https://quicui-backend.onrender.com"
APP_ID="com.quicui.quicui_v1_test"
VERSION="2.0.0"
PATCH_ID="patch-v2.0.0"
PATCH_FILE="patch_v2.0.0_full.so"
HASH="afe1ead1cb8548a63177f90804cc05ea149c919e688319768bedf928a6d1b4bd"

echo "🚀 Uploading Full Replacement Patch v${VERSION}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Backend: ${BACKEND_URL}"
echo "App ID: ${APP_ID}"
echo "Patch ID: ${PATCH_ID}"
echo "File: ${PATCH_FILE} (3.5MB)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get absolute path to patch file
PATCH_PATH="$(cd "$(dirname "$0")" && pwd)/${PATCH_FILE}"
PATCH_SIZE=$(wc -c < "${PATCH_PATH}" | tr -d ' ')

echo "File size: ${PATCH_SIZE} bytes (3.5 MB)"
echo "SHA-256: ${HASH}"
echo ""
echo "Creating temp file with base64 in chunks..."

# Split base64 encoding into manageable chunks
# Use a small file upload approach
TEMP_JSON=$(mktemp)
trap "rm -f ${TEMP_JSON}" EXIT

# For 3.5MB, we need multipart upload or file-based approach
# For now, let's use a simple Python script to do the upload
python3 << 'PYTHON_EOF'
import requests
import sys
import base64

url = "https://quicui-backend.onrender.com/api/v1/patches/upload"
file_path = sys.argv[1]
patch_id = sys.argv[2]
version = sys.argv[3]
app_id = sys.argv[4]
hash_val = sys.argv[5]

print("Reading file...")
with open(file_path, 'rb') as f:
    file_data = f.read()

file_size = len(file_data)
print(f"File size: {file_size} bytes")

print("Encoding to base64...")
file_base64 = base64.b64encode(file_data).decode('utf-8')

print(f"Base64 length: {len(file_base64)}")
print("Uploading...")

payload = {
    "patchId": patch_id,
    "version": version,
    "appId": app_id,
    "size": file_size,
    "hash": hash_val,
    "fileData": file_base64
}

try:
    response = requests.post(url, json=payload, timeout=60)
    print(f"Status: {response.status_code}")
    print(response.text)
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
PYTHON_EOF "${PATCH_PATH}" "${PATCH_ID}" "${VERSION}" "${APP_ID}" "${HASH}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Upload complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
