#!/bin/bash

# QuicUI Engine Build Script
# This script downloads the standard Flutter engine at the correct commit
# and applies QuicUI modifications before building

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENGINE_BUILD_DIR="/Volumes/DoWonder2/quicui_engine_build/engine_b5990e5ccc"
DEPOT_TOOLS_DIR="/Volumes/DoWonder2/quicui_engine_build/depot_tools"
QUICUI_BACKUP_DIR="/Volumes/DoWonder2/quicui_engine_build/quicui_source_backup"

# Target engine commit (from Flutter 3.38.1)
ENGINE_COMMIT="b5990e5ccc5e325fd24f0746e7d6689bbebc7c65"

echo "================================================================"
echo "QuicUI Engine Build Setup"
echo "================================================================"
echo "Target commit: $ENGINE_COMMIT"
echo "Build directory: $ENGINE_BUILD_DIR"
echo ""

# Step 1: Check if depot_tools exists
if [ ! -d "$DEPOT_TOOLS_DIR" ]; then
  echo "❌ depot_tools not found at $DEPOT_TOOLS_DIR"
  exit 1
fi

export PATH="$DEPOT_TOOLS_DIR:$PATH"

# Step 2: Create build directory
mkdir -p "$ENGINE_BUILD_DIR"
cd "$ENGINE_BUILD_DIR"

# Step 3: Check if engine source exists
if [ ! -d "src/flutter" ]; then
  echo "📥 Fetching Flutter engine source (this may take a while)..."
  echo "   Using 'fetch flutter' command..."
  
  # Create .gclient file
  cat > .gclient <<EOF
solutions = [
  {
    "managed": False,
    "name": "src/flutter",
    "url": "https://github.com/flutter/engine.git",
    "custom_deps": {},
    "deps_file": "DEPS",
    "safesync_url": "",
  },
]
EOF
  
  # Sync the engine
  gclient sync --shallow --no-history
fi

# Step 4: Checkout the correct commit
echo ""
echo "🔄 Checking out engine commit $ENGINE_COMMIT..."
cd src/flutter
git fetch origin
git checkout $ENGINE_COMMIT

if [ $? -ne 0 ]; then
  echo "❌ Failed to checkout commit $ENGINE_COMMIT"
  exit 1
fi

echo "✅ Checked out commit: $(git log --oneline -1)"

# Step 5: Sync dependencies
echo ""
echo "📦 Syncing dependencies..."
cd ../..
gclient sync

# Step 6: Copy QuicUI modifications
echo ""
echo "📝 Applying QuicUI modifications..."

if [ ! -d "$QUICUI_BACKUP_DIR" ]; then
  echo "❌ QuicUI backup directory not found: $QUICUI_BACKUP_DIR"
  exit 1
fi

# Copy quicui_patch_loader files
cp "$QUICUI_BACKUP_DIR/quicui_patch_loader.h" src/flutter/shell/common/
cp "$QUICUI_BACKUP_DIR/quicui_patch_loader.cc" src/flutter/shell/common/
cp "$QUICUI_BACKUP_DIR/quicui_patch_loader_jni.cc" src/flutter/shell/platform/android/

echo "✅ Copied QuicUI C++ files"

# Step 7: Modify BUILD.gn files
echo ""
echo "🔧 Updating BUILD.gn files..."

# Update common/BUILD.gn
BUILD_GN_COMMON="src/flutter/shell/common/BUILD.gn"
if ! grep -q "quicui_patch_loader.cc" "$BUILD_GN_COMMON"; then
  echo "  Adding quicui_patch_loader to common/BUILD.gn..."
  # Find the sources section and add our files
  sed -i.bak '/sources = \[/,/\]/{ /\]/i\
    "quicui_patch_loader.cc",\
    "quicui_patch_loader.h",
  }' "$BUILD_GN_COMMON"
  echo "✅ Updated common/BUILD.gn"
else
  echo "✅ common/BUILD.gn already contains quicui_patch_loader"
fi

# Update android/BUILD.gn
BUILD_GN_ANDROID="src/flutter/shell/platform/android/BUILD.gn"
if ! grep -q "quicui_patch_loader_jni.cc" "$BUILD_GN_ANDROID"; then
  echo "  Adding quicui_patch_loader_jni to android/BUILD.gn..."
  # Find the sources section and add our file
  sed -i.bak '/sources = \[/,/\]/{ /\]/i\
    "quicui_patch_loader_jni.cc",
  }' "$BUILD_GN_ANDROID"
  echo "✅ Updated android/BUILD.gn"
else
  echo "✅ android/BUILD.gn already contains quicui_patch_loader_jni"
fi

# Step 8: Modify flutter_main.cc
echo ""
echo "🔧 Modifying flutter_main.cc..."

FLUTTER_MAIN="src/flutter/shell/platform/android/flutter_main.cc"

# Add include at the top
if ! grep -q "#include \"flutter/shell/common/quicui_patch_loader.h\"" "$FLUTTER_MAIN"; then
  sed -i.bak '/#include "flutter\/shell\/platform\/android\/flutter_main.h"/a\
#include "flutter/shell/common/quicui_patch_loader.h"
' "$FLUTTER_MAIN"
  echo "✅ Added quicui_patch_loader.h include"
else
  echo "✅ quicui_patch_loader.h already included"
fi

# Add ConfigureQuicUI function (we'll add it manually after the script checks)
if ! grep -q "static void ConfigureQuicUI" "$FLUTTER_MAIN"; then
  echo "⚠️  Need to manually add ConfigureQuicUI function to flutter_main.cc"
  echo "    See $QUICUI_BACKUP_DIR/ConfigureQuicUI_function.txt"
else
  echo "✅ ConfigureQuicUI function already present"
fi

# Step 9: Configure build
echo ""
echo "🔧 Configuring Android ARM64 release build..."
cd src
./flutter/tools/gn --android --android-cpu arm64 --runtime-mode release

if [ $? -ne 0 ]; then
  echo "❌ GN configuration failed"
  exit 1
fi

echo "✅ Build configured successfully"

# Step 10: Ready to build
echo ""
echo "================================================================"
echo "✅ Setup complete! Ready to build."
echo "================================================================"
echo ""
echo "To build the engine, run:"
echo "  cd $ENGINE_BUILD_DIR/src"
echo "  ninja -C out/android_release_arm64 -j4"
echo ""
echo "Build will take 1-2 hours. Monitor progress with:"
echo "  tail -f /tmp/quicui_engine_build.log"
echo ""
echo "After build completes, libflutter.so will be at:"
echo "  $ENGINE_BUILD_DIR/src/out/android_release_arm64/libflutter.so"
echo ""
