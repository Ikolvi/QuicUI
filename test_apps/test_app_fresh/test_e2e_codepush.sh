#!/bin/bash
# QuicUI Code Push - Complete End-to-End Test Script
# This script automates the entire code push flow

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FLUTTER_SDK="/Users/admin/Documents/quicui2/forks/flutter-official/bin/flutter"
COMPILER="/Users/admin/Documents/quicui2/packages/quicui_compiler/bin/quicui-compiler"
DEVICE_ID="BLZ5GBY23JB034715"
SERVER_URL="http://192.168.20.100:8080"
APP_ID="com.quicui.test_app_fresh"

echo ""
echo "════════════════════════════════════════════════════════════════════"
echo "🚀 QuicUI Code Push - End-to-End Test"
echo "════════════════════════════════════════════════════════════════════"
echo ""

# Step 1: Build and install v1.0.0 (baseline without counter visible)
echo "📦 Step 1: Building v1.0.0 (baseline)..."
cd "$SCRIPT_DIR"

# Temporarily remove counter feature for baseline
echo "   Commenting out counter feature..."
sed -i.bak 's/^              \/\/ NEW in v1.0.1: Counter button/              \/\/ Counter button (will be added in v1.0.1)/' lib/main.dart
sed -i '' '/Card(/,/),$/s/^/\/\/ /' lib/main.dart || true

"$FLUTTER_SDK" build apk --release
echo "✅ v1.0.0 built successfully"

# Save v1.0.0 snapshot
echo "   Saving v1.0.0 snapshot..."
rm -rf snapshots/v1.0.0 snapshots/v1.0.1
mkdir -p snapshots/v1.0.0
cp build/app/intermediates/stripped_native_libs/release/stripReleaseDebugSymbols/out/lib/arm64-v8a/libapp.so snapshots/v1.0.0/
echo "✅ v1.0.0 snapshot saved"

# Install v1.0.0 on device
echo "   Installing v1.0.0 on device..."
adb -s "$DEVICE_ID" install -r build/app/outputs/flutter-apk/app-release.apk
echo "✅ v1.0.0 installed on device"
echo ""

# Step 2: Build v1.0.1 (with counter feature)
echo "📦 Step 2: Building v1.0.1 (with counter feature)..."

# Restore counter feature
mv lib/main.dart.bak lib/main.dart

"$FLUTTER_SDK" build apk --release
echo "✅ v1.0.1 built successfully"

# Save v1.0.1 snapshot
echo "   Saving v1.0.1 snapshot..."
mkdir -p snapshots/v1.0.1
cp build/app/intermediates/stripped_native_libs/release/stripReleaseDebugSymbols/out/lib/arm64-v8a/libapp.so snapshots/v1.0.1/
echo "✅ v1.0.1 snapshot saved"
echo ""

# Step 3: Generate patch
echo "🔧 Step 3: Generating binary patch..."
cd snapshots
"$COMPILER" diff v1.0.0/libapp.so v1.0.1/libapp.so --output=v1.0.0_to_v1.0.1.quicui --compress=none
echo "✅ Patch generated: $(du -h v1.0.0_to_v1.0.1.quicui | cut -f1)"
echo ""

# Step 4: Register patch with backend
echo "📤 Step 4: Registering patch with backend..."
"$COMPILER" register v1.0.0_to_v1.0.1.quicui \
  --app-id="$APP_ID" \
  --version=1.0.1 \
  --server-url="$SERVER_URL"
echo "✅ Patch registered successfully"
echo ""

# Step 5: Verify patch is available
echo "🔍 Step 5: Verifying patch is available..."
RESPONSE=$(curl -s -X POST "$SERVER_URL/api/v1/patches/check" \
  -H "Content-Type: application/json" \
  -d "{\"appId\": \"$APP_ID\", \"currentVersion\": \"1.0.0\", \"acceptCompression\": []}")

echo "$RESPONSE" | python3 -m json.tool
echo ""

if echo "$RESPONSE" | grep -q '"patchAvailable": *true'; then
  echo "✅ Patch is available on backend!"
else
  echo "❌ Patch not available on backend!"
  exit 1
fi

# Step 6: Launch app
echo "📱 Step 6: Launching app on device..."
adb -s "$DEVICE_ID" shell "am force-stop $APP_ID"
sleep 1
adb -s "$DEVICE_ID" shell "am start -n $APP_ID/.MainActivity"
echo "✅ App launched"
echo ""

echo "════════════════════════════════════════════════════════════════════"
echo "✅ Setup Complete! Now test on your device:"
echo "════════════════════════════════════════════════════════════════════"
echo ""
echo "1. 📱 Open the app (should already be running)"
echo "   ⚠️  You should NOT see the counter button (v1.0.0)"
echo ""
echo "2. 🧪 Tap 'Test Code Push' button"
echo ""
echo "3. 📥 Tap 'Download and Apply Patch'"
echo "   • Patch will download (4.3 MB uncompressed)"
echo "   • Patch will be installed to code_cache"
echo ""
echo "4. 🔄 Restart the app when prompted"
echo ""
echo "5. ✅ After restart, you should see:"
echo "   • Blue card with counter button"
echo "   • '🎉 NEW in v1.0.1!' message"
echo "   • Counter increments when you tap the button"
echo ""
echo "📊 Monitor logs:"
echo "   adb -s $DEVICE_ID logcat | grep -i 'quicui\\|codepush'"
echo ""
echo "════════════════════════════════════════════════════════════════════"
