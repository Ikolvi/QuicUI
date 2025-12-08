#!/bin/bash

# Script to apply bsdiff patch and create full patched binary

set -e

echo "🔧 Applying BsDiff Patch to Create Full Binary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Decompress the XZ patch to get bsdiff patch
echo "📦 Decompressing XZ patch..."
xz -d -k ./patches/patch_1764180399125.quicui.xz
echo "✅ Decompressed to: ./patches/patch_1764180399125.quicui"
echo ""

# 2. Apply bsdiff patch to baseline
echo "🔨 Applying bsdiff patch to baseline..."
echo "   Baseline: ./baseline/App-v3.0.28"
echo "   Patch: ./patches/patch_1764180399125.quicui"
echo "   Output: ./patches/App-v3.0.30-patched"
echo ""

# Check if baseline exists
if [  ! -f "./baseline/App-v3.0.28" ]; then
    echo "❌ Error: Baseline not found"
    exit 1
fi

# Apply patch using bspatch (we need the real bspatch tool, not our custom format)
# Wait - our patch is in QUICUI01 format, not BSDIFF40!
# We need to use our Dart tool to apply it

echo "⚠️  Patch is in QUICUI01 custom format"
echo "   Using Dart BsDiff implementation to apply..."
echo ""

# Create a Dart script to apply the patch
cat > apply_patch.dart << 'DARTEOF'
import 'dart:io';
import '../../packages/quicui_compiler/lib/src/bsdiff.dart';

void main() async {
  print('[Dart BsPatch] Applying patch...');
  await BsDiff.applyPatch(
    './baseline/App-v3.0.28',
    './patches/patch_1764180399125.quicui',
    './patches/App-v3.0.30-patched',
  );
  print('[Dart BsPatch] ✅ Done!');
  
  // Get file size
  final file = File('./patches/App-v3.0.30-patched');
  final size = await file.length();
  print('[Dart BsPatch] Patched binary size: ${(size / 1024 / 1024).toStringAsFixed(2)} MB');
}
DARTEOF

dart run apply_patch.dart

echo ""
echo "✅ Full patched binary created"
echo ""

# 3. Verify the patched binary
echo "🔍 Verifying patched binary..."
ls -lh ./patches/App-v3.0.30-patched
file ./patches/App-v3.0.30-patched
echo ""

# 4. Compress the FULL patched binary for upload
echo "📦 Compressing full patched binary..."
xz -z -9 -k ./patches/App-v3.0.30-patched
echo "✅ Compressed to: ./patches/App-v3.0.30-patched.xz"
echo ""

# Show sizes
echo "📊 Size comparison:"
echo "   Baseline: $(ls -lh ./baseline/App-v3.0.28 | awk '{print $5}')"
echo "   BsDiff patch: $(ls -lh ./patches/patch_1764180399125.quicui | awk '{print $5}')"
echo "   Full patched binary: $(ls -lh ./patches/App-v3.0.30-patched | awk '{print $5}')"
echo "   Compressed patched binary: $(ls -lh ./patches/App-v3.0.30-patched.xz | awk '{print $5}')"
echo ""

echo "💡 Next step: Upload ./patches/App-v3.0.30-patched.xz to Supabase"
echo "   (This contains the FULL patched binary, not just the diff)"

