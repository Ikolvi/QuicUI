#!/bin/bash

# Test script for QuicUI .vmcode header loading
# This creates a minimal Flutter app that loads our test patch

set -e

QUICUI_ENGINE="/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/out/ios_release"
TEST_APP="/Users/admin/Documents/quicui2/test_apps/quicui_production_test"
VMCODE_FILE="/Users/admin/Documents/quicui2/test_apps/sample.vmcode"

echo "=== QuicUI .vmcode Header Loading Test ==="
echo ""
echo "1. Engine: $QUICUI_ENGINE"
echo "2. Test App: $TEST_APP"
echo "3. Sample vmcode: $VMCODE_FILE"
echo ""

# Verify files exist
if [ ! -f "$QUICUI_ENGINE/Flutter.framework/Flutter" ]; then
    echo "❌ Error: Custom engine not found at $QUICUI_ENGINE"
    exit 1
fi

if [ ! -f "$VMCODE_FILE" ]; then
    echo "❌ Error: Sample vmcode not found at $VMCODE_FILE"
    exit 1
fi

echo "✅ All files found"
echo ""

# Check if the header reading function is in the engine
echo "3. Checking for QuicUI_ReadLinkHeader in engine..."
if strings "$QUICUI_ENGINE/obj/flutter/runtime/runtime.dart_snapshot.o" | grep -q "Valid .vmcode file detected"; then
    echo "✅ QuicUI_ReadLinkHeader implementation found in engine"
else
    echo "❌ QuicUI_ReadLinkHeader not found in engine"
    exit 1
fi

echo ""
echo "4. Verifying .vmcode header structure..."
# Check first 4 bytes
HEADER_BYTES=$(hexdump -n 4 -e '4/1 "%02x " "\n"' "$VMCODE_FILE")
echo "   Header bytes: $HEADER_BYTES"

# Check ELF magic at offset 65536
ELF_MAGIC=$(dd if="$VMCODE_FILE" bs=1 skip=65536 count=4 2>/dev/null | hexdump -e '4/1 "%02x " "\n"')
echo "   ELF magic at 0x10000: $ELF_MAGIC"

if [ "$ELF_MAGIC" = "7f 45 4c 46 " ]; then
    echo "✅ Valid .vmcode format confirmed"
else
    echo "❌ Invalid .vmcode format"
    exit 1
fi

echo ""
echo "=== Test Complete ==="
echo ""
echo "Next steps:"
echo "1. Build an iOS app with custom engine using:"
echo "   flutter build ios --local-engine-src-path=$QUICUI_ENGINE/../../.."
echo "   flutter build ios --local-engine=ios_release"
echo ""
echo "2. Configure app to load $VMCODE_FILE"
echo "3. Run app and check logs for:"
echo "   - '[QuicUI] Loading .vmcode patch'"
echo "   - '[QuicUI] Valid .vmcode file detected, ELF at offset 65536'"
echo "   - '[QuicUI] ✅ Patch ELF loaded successfully from memory'"
