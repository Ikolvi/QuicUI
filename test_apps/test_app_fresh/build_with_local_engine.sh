#!/bin/bash

# Build test app with local engine
# This script will be run after host_release build completes

set -e

echo "Building test_app_fresh with --local-engine..."

# Use Flutter MASTER channel (matches the engine we built)
export PATH="/Users/admin/fvm/versions/master/bin:$PATH"
echo "Using Flutter: $(which flutter)"
flutter --version | head -1

# Clean previous build
echo "Cleaning previous build..."
flutter clean

# Build with local engine
echo "Building APK with custom engine..."
flutter build apk --release \
  --local-engine-src-path=/Volumes/DoWonder2/quicui_engine_build/engine_full/src \
  --local-engine=android_release_arm64 \
  --local-engine-host=host_release

echo ""
echo "Build complete!"
echo "APK location: build/app/outputs/flutter-apk/app-release.apk"
echo ""
echo "To install: adb install -r build/app/outputs/flutter-apk/app-release.apk"
