#!/bin/bash
# Script to fix missing Flutter headers in build directory

BUILD_FRAMEWORK="/Users/admin/Documents/quicui2/test_apps/quicui_production_test/build/ios/Release-iphoneos/Flutter.framework"
ENGINE_FRAMEWORK="/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/out/ios_release/Flutter.framework"

echo "🔧 Fixing Flutter.framework headers..."

if [ -d "$BUILD_FRAMEWORK/Headers" ]; then
    cp "$ENGINE_FRAMEWORK/Headers/Flutter.h" "$BUILD_FRAMEWORK/Headers/"
    cp "$ENGINE_FRAMEWORK/Headers/FlutterAppDelegate.h" "$BUILD_FRAMEWORK/Headers/"
    echo "✅ Headers copied successfully"
else
    echo "❌ Build framework not found"
    exit 1
fi
