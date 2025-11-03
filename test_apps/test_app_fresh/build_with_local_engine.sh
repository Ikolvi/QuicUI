#!/bin/bash

# Build test app with local engine
# This script will be run after host_release build completes

set -e

echo "Building test_app_fresh with --local-engine..."

# Set Flutter SDK path
export PATH="/Users/admin/Documents/quicui2/forks/flutter-quicui/bin:$PATH"

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
