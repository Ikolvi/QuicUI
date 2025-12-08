#!/bin/bash
# Script to deploy QuicUI custom engine to Gradle cache
# This is a workaround until proper Maven publishing is set up

set -e  # Exit on error

ENGINE_VERSION="b5990e5ccc5e325fd24f0746e7d6689bbebc7c65"
FORK_PATH="/Users/admin/Documents/quicui2/forks/flutter"
FORK_ENGINE="$FORK_PATH/bin/cache/artifacts/engine/android-arm64-release/darwin-x64"

echo "🚀 QuicUI Engine Gradle Cache Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Engine Version: $ENGINE_VERSION"
echo ""

# Step 1: Verify QuicUI artifacts exist in fork
echo "📋 Step 1: Verifying QuicUI artifacts..."
if [ ! -f "$FORK_ENGINE/libflutter.so" ]; then
    echo "❌ Error: libflutter.so not found in fork at $FORK_ENGINE"
    exit 1
fi

# Verify it contains QuicUI code
if ! strings "$FORK_ENGINE/libflutter.so" | grep -q "ConfigureQuicUI"; then
    echo "❌ Error: libflutter.so does not contain ConfigureQuicUI code"
    exit 1
fi

echo "   ✅ Found QuicUI libflutter.so ($(du -h "$FORK_ENGINE/libflutter.so" | cut -f1))"
echo ""

# Step 2: Build once to populate Gradle cache with standard artifacts
echo "📦 Step 2: Building once to populate Gradle cache..."
echo "   (This will download standard Flutter engine artifacts)"
cd /Users/admin/Documents/quicui2/test_apps/quicui_production_test
"$FORK_PATH/bin/flutter" build apk --release > /tmp/quicui_first_build.log 2>&1 || true
echo "   ✅ Initial build complete"
echo ""

# Step 3: Find the cached JAR location
echo "🔍 Step 3: Locating Gradle cache..."
GRADLE_CACHE_DIR=$(find ~/.gradle/caches/modules-2/files-2.1/io.flutter/arm64_v8a_release/1.0.0-${ENGINE_VERSION}/ -type f -name "*.jar" 2>/dev/null | head -1)

if [ -z "$GRADLE_CACHE_DIR" ]; then
    echo "❌ Error: Could not find Gradle cache for arm64_v8a_release"
    echo "   Expected path: ~/.gradle/caches/modules-2/files-2.1/io.flutter/arm64_v8a_release/1.0.0-${ENGINE_VERSION}/"
    exit 1
fi

GRADLE_CACHE_HASH=$(dirname "$GRADLE_CACHE_DIR" | xargs basename)
echo "   ✅ Found cache at: $GRADLE_CACHE_DIR"
echo "   Cache hash: $GRADLE_CACHE_HASH"
echo ""

# Step 4: Create QuicUI JAR from fork's libflutter.so
echo "📦 Step 4: Creating QuicUI JAR..."
TEMP_DIR="/tmp/quicui_jar_build"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR/lib/arm64-v8a"

cp "$FORK_ENGINE/libflutter.so" "$TEMP_DIR/lib/arm64-v8a/"
cd "$TEMP_DIR"
jar cvf /tmp/quicui_arm64_v8a.jar lib/arm64-v8a/libflutter.so > /dev/null 2>&1

JAR_SIZE=$(du -h /tmp/quicui_arm64_v8a.jar | cut -f1)
echo "   ✅ Created QuicUI JAR ($JAR_SIZE)"
echo ""

# Step 5: Backup original JAR
echo "💾 Step 5: Backing up original JAR..."
if [ ! -f "$GRADLE_CACHE_DIR.backup" ]; then
    cp "$GRADLE_CACHE_DIR" "$GRADLE_CACHE_DIR.backup"
    echo "   ✅ Backup saved: $GRADLE_CACHE_DIR.backup"
else
    echo "   ℹ️  Backup already exists"
fi
echo ""

# Step 6: Replace cached JAR with QuicUI JAR
echo "🔧 Step 6: Replacing Gradle cache JAR..."
cp /tmp/quicui_arm64_v8a.jar "$GRADLE_CACHE_DIR"
echo "   ✅ Replaced: $GRADLE_CACHE_DIR"
echo ""

# Step 7: Clear transforms cache
echo "🧹 Step 7: Clearing Gradle transforms cache..."
rm -rf ~/.gradle/caches/*/transforms/*arm64_v8a* 2>/dev/null || true
rm -rf ~/.gradle/caches/*/transforms/*flutter* 2>/dev/null || true
echo "   ✅ Transforms cache cleared"
echo ""

# Step 8: Clear project build cache
echo "🧹 Step 8: Clearing project build cache..."
cd /Users/admin/Documents/quicui2/test_apps/quicui_production_test
rm -rf android/.gradle android/build build
echo "   ✅ Project build cache cleared"
echo ""

# Step 9: Rebuild with QuicUI engine
echo "🔨 Step 9: Rebuilding with QuicUI engine..."
"$FORK_PATH/bin/flutter" build apk --release

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ DEPLOYMENT COMPLETE!"
echo ""
echo "📋 Next steps:"
echo "   1. Verify QuicUI engine in APK:"
echo "      unzip -p build/app/outputs/flutter-apk/app-release.apk lib/arm64-v8a/libflutter.so | strings | grep ConfigureQuicUI"
echo ""
echo "   2. Install and test:"
echo "      adb install -r build/app/outputs/flutter-apk/app-release.apk"
echo "      adb logcat | grep -E 'ConfigureQuicUI|QuicUI'"
echo ""
echo "⚠️  Note: This is a workaround. For production, use proper Maven publishing."
echo "    See: docs/2025-11-17/GRADLE_CACHE_ENGINE_ARTIFACTS.md"
echo ""
