#!/bin/bash

# QuicUI Code Push - End-to-End Test Script
# This script tests the complete code push flow on Android

set -e

ADB="/Users/admin/Library/Android/sdk/platform-tools/adb"
DEVICE_ID="BLZ5GBY23JB034715"
PACKAGE_NAME="com.quicui.test_app_fresh"
PATCH_FILE="snapshots/libapp_patched.so"  # Use the patched .so file directly
SERVER_URL="http://localhost:8080"

echo "════════════════════════════════════════════════════════════"
echo "QuicUI Code Push - End-to-End Test"
echo "════════════════════════════════════════════════════════════"
echo ""

# Step 1: Verify v1.0.0 is installed
echo "📱 Step 1: Verifying v1.0.0 is installed..."
$ADB -s $DEVICE_ID shell "pm list packages | grep $PACKAGE_NAME" || {
    echo "❌ App not installed!"
    exit 1
}
echo "✅ App is installed"
echo ""

# Step 2: Check backend server
echo "🔧 Step 2: Checking backend server..."
curl -s $SERVER_URL/health > /dev/null && echo "✅ Backend server is running" || {
    echo "❌ Backend server is not running!"
    echo "Start it with: cd packages/quicui_backend && dart run bin/server.dart"
    exit 1
}
echo ""

# Step 3: Copy patch to device
echo "📦 Step 3: Deploying patch to device..."
PATCH_DIR="/data/local/tmp/quicui_patches"
CODE_CACHE_DIR="/data/data/$PACKAGE_NAME/code_cache/quicui_patches"

# First push to tmp (accessible without root)
$ADB -s $DEVICE_ID shell "mkdir -p $PATCH_DIR"
$ADB -s $DEVICE_ID push $PATCH_FILE "$PATCH_DIR/libapp_patched_arm64-v8a.so"

# Then use run-as to copy to app's code cache (no root needed for debuggable apps)
$ADB -s $DEVICE_ID shell "run-as $PACKAGE_NAME mkdir -p code_cache/quicui_patches"
$ADB -s $DEVICE_ID shell "run-as $PACKAGE_NAME cp $PATCH_DIR/libapp_patched_arm64-v8a.so code_cache/quicui_patches/"
$ADB -s $DEVICE_ID shell "run-as $PACKAGE_NAME chmod 644 code_cache/quicui_patches/libapp_patched_arm64-v8a.so"

# Create minimal metadata file
$ADB -s $DEVICE_ID shell "run-as $PACKAGE_NAME sh -c 'echo {\\\"version\\\":\\\"1.0.1\\\",\\\"architecture\\\":\\\"arm64-v8a\\\"} > code_cache/quicui_patches/patch_metadata.json'"

echo "✅ Patch deployed to device"
echo ""

# Step 4: Verify patch file on device
echo "🔍 Step 4: Verifying patch on device..."
$ADB -s $DEVICE_ID shell "run-as $PACKAGE_NAME ls -lh code_cache/quicui_patches/"
echo ""

# Step 5: Restart app
echo "🔄 Step 5: Restarting app to apply patch..."
$ADB -s $DEVICE_ID shell "am force-stop $PACKAGE_NAME"
sleep 1
$ADB -s $DEVICE_ID shell "monkey -p $PACKAGE_NAME 1" > /dev/null 2>&1
echo "✅ App restarted"
echo ""

# Step 6: Check logs
echo "📋 Step 6: Checking app logs for QuicUI messages..."
echo "Looking for code push messages..."
sleep 2
$ADB -s $DEVICE_ID logcat -d | grep -i "quicui\|codepush" | tail -20 || echo "No QuicUI logs found yet"
echo ""

echo "════════════════════════════════════════════════════════════"
echo "✅ Test Complete!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "1. Open the app on your device"
echo "2. Check if the counter button appears (v1.0.1 feature)"
echo "3. If you see the counter, code push worked! 🎉"
echo ""
echo "To check logs in real-time:"
echo "$ADB -s $DEVICE_ID logcat | grep -i quicui"
echo ""
