#!/bin/bash

echo "========================================="
echo "Testing BSDIFF40 Patch with Fixed Patcher"
echo "========================================="
echo ""

echo "1. Clearing logs..."
adb logcat -c

echo "2. Please tap 'Check for Updates' button in the app now"
echo "   Waiting 15 seconds..."
sleep 15

echo ""
echo "3. Checking logs for patch application..."
adb logcat -d | grep -E "Bsdiff40|BSDIFF40|patch applied successfully" | tail -10

echo ""
echo "4. Pulling patched file to verify hash..."
adb exec-out run-as com.example.quicui_production_test cat code_cache/quicui_patches/libapp_patched_arm64-v8a.so > /tmp/patched_after_fix.so

echo ""
echo "5. Comparing hashes:"
echo "   Patched file:"
sha256sum /tmp/patched_after_fix.so
echo "   Expected (v2.0.2):"
sha256sum v2.0.2/libapp.so

PATCHED_HASH=$(sha256sum /tmp/patched_after_fix.so | awk '{print $1}')
EXPECTED_HASH=$(sha256sum v2.0.2/libapp.so | awk '{print $1}')

echo ""
if [ "$PATCHED_HASH" = "$EXPECTED_HASH" ]; then
    echo "✅ SUCCESS! Patch applied correctly!"
    echo ""
    echo "6. Now restart the app to see visual changes:"
    echo "   adb shell am force-stop com.example.quicui_production_test"
    echo "   adb shell am start -n com.example.quicui_production_test/.MainActivity"
    echo ""
    echo "   Expected: TEAL/GREEN theme with '🌟 QuicUI v2.0.2 - LATEST!'"
else
    echo "❌ FAILED! Patch hash mismatch"
    echo "   This means the Kotlin patcher is still producing wrong output"
fi
