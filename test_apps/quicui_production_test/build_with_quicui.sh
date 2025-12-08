#!/bin/bash
# QuicUI iOS Build Wrapper
# Works around Xcode custom engine header issues

set -e

VERSION=$1
IS_BASELINE=$2

if [ -z "$VERSION" ]; then
  echo "Usage: ./build_with_quicui.sh <version> [--baseline]"
  exit 1
fi

OUTPUT_DIR="v$VERSION"
if [ "$IS_BASELINE" == "--baseline" ]; then
  OUTPUT_DIR="baseline"
fi

echo "🔨 Building iOS v$VERSION using QuicUI workflow"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 1: Build with standard Flutter
echo "📦 Step 1: Building with Flutter..."
flutter build ios --release
echo "   ✅ Flutter build complete"
echo ""

# Step 2: Extract artifacts
echo "📂 Step 2: Extracting artifacts..."
mkdir -p "$OUTPUT_DIR"

# Extract App binary
cp build/ios/iphoneos/Runner.app/Frameworks/App.framework/App "$OUTPUT_DIR/App-v$VERSION"
echo "   ✅ Extracted App binary: $(ls -lh "$OUTPUT_DIR/App-v$VERSION" | awk '{print $5}')"

# Extract app.dill
DILL_DIR=$(find .dart_tool/flutter_build -name "app.dill" -type f -exec ls -t {} + | head -1)
if [ -n "$DILL_DIR" ]; then
  cp "$DILL_DIR" "$OUTPUT_DIR/app.dill"
  echo "   ✅ Extracted app.dill: $(ls -lh "$OUTPUT_DIR/app.dill" | awk '{print $5}')"
else
  echo "   ⚠️  app.dill not found!"
  exit 1
fi
echo ""

# Step 3: Create metadata
echo "📝 Step 3: Creating metadata..."
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
IS_BASELINE_FLAG="false"
if [ "$IS_BASELINE" == "--baseline" ]; then
  IS_BASELINE_FLAG="true"
fi

cat > "$OUTPUT_DIR/metadata.json" << EOF
{
  "version": "$VERSION",
  "platform": "ios",
  "architecture": "arm64",
  "isBaseline": $IS_BASELINE_FLAG,
  "appBinaryPath": "App-v$VERSION",
  "appDillPath": "app.dill",
  "timestamp": "$TIMESTAMP"
}
EOF
echo "   ✅ Metadata created"
echo ""

echo "✅ Build Complete!"
echo ""
echo "📋 Output: $OUTPUT_DIR/"
ls -lh "$OUTPUT_DIR/"
echo ""

if [ "$IS_BASELINE" == "--baseline" ]; then
  echo "💡 Baseline created. Install on device:"
  echo "   xcrun devicectl device install app --device <DEVICE_ID> build/ios/iphoneos/Runner.app"
else
  echo "💡 Next steps:"
  echo "   1. Generate patch: dart run ../../packages/quicui_cli/bin/quicui.dart generate-patch --from baseline --to $OUTPUT_DIR"
  echo "   2. Upload patch: dart run ../../packages/quicui_cli/bin/quicui.dart upload-patch --patch <PATCH_ID>"
fi
