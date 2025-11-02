#!/bin/bash

# Build and install test app with environment variable for server URL
# This sets QUICUI_SERVER_URL to point to the PC's IP address

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR"
FLUTTER_SDK="/Users/admin/Documents/quicui2/forks/flutter-official/bin/flutter"
DEVICE_ID="BLZ5GBY23JB034715"

# PC IP address where backend server is running
SERVER_URL="http://192.168.20.100:8080"

echo "🔧 Building QuicUI Test App"
echo "════════════════════════════════════════"
echo "Project: $PROJECT_DIR"
echo "Flutter: $FLUTTER_SDK"
echo "Device:  $DEVICE_ID"
echo "Server:  $SERVER_URL"
echo "════════════════════════════════════════"
echo ""

# Set environment variable for the build
export QUICUI_SERVER_URL="$SERVER_URL"

echo "📦 Building release APK..."
cd "$PROJECT_DIR"
"$FLUTTER_SDK" build apk --release \
  --dart-define=QUICUI_SERVER_URL="$SERVER_URL"

if [ $? -ne 0 ]; then
  echo "❌ Build failed!"
  exit 1
fi

echo ""
echo "✅ Build successful!"
echo ""
echo "📱 Installing to device $DEVICE_ID..."
"$FLUTTER_SDK" install --release -d "$DEVICE_ID"

if [ $? -ne 0 ]; then
  echo "❌ Install failed!"
  exit 1
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "🎯 Next Steps:"
echo "1. Open the app on your device"
echo "2. Tap 'Test Code Push' button"
echo "3. The app will connect to: $SERVER_URL"
echo "4. Check for updates and download the patch"
echo ""
