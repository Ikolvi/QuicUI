#!/bin/bash

# SDK Detection Build Script
# This script detects the current Flutter SDK and passes it as build-time constants

set -e

# Get Flutter version info
FLUTTER_VERSION=$(flutter --version | head -1 | awk '{print $2}')
FLUTTER_CHANNEL=$(flutter --version | grep "channel" | sed 's/.*channel \([^ •]*\).*/\1/')
DART_VERSION=$(dart --version | sed 's/Dart SDK version: \([^ ]*\).*/\1/')

# Detect if this is QuicUI fork
IS_QUICUI=false
if [[ "$FLUTTER_CHANNEL" == *"user-branch"* ]] || [[ "$FLUTTER_VERSION" == *"pre"* ]]; then
  IS_QUICUI=true
fi

# Determine SDK type
if [ "$IS_QUICUI" = true ]; then
  SDK_TYPE="quicui"
else
  SDK_TYPE="standard"
fi

echo "🔍 SDK Detection:"
echo "  Flutter Version: $FLUTTER_VERSION"
echo "  Dart Version: $DART_VERSION"
echo "  Channel: $FLUTTER_CHANNEL"
echo "  Is QuicUI: $IS_QUICUI"
echo "  SDK Type: $SDK_TYPE"
echo ""

# Export as Dart build-time constants
export QUICUI_SDK_TYPE="$SDK_TYPE"
export QUICUI_FLUTTER_VERSION="$FLUTTER_VERSION"
export QUICUI_DART_VERSION="$DART_VERSION"
export QUICUI_SDK_CHANNEL="$FLUTTER_CHANNEL"
export QUICUI_IS_FORK="$IS_QUICUI"

echo "✅ Build-time constants set"
echo ""

# Run the flutter command with the constants
flutter run -d "$1" \
  --dart-define="QUICUI_SDK_TYPE=$SDK_TYPE" \
  --dart-define="QUICUI_FLUTTER_VERSION=$FLUTTER_VERSION" \
  --dart-define="QUICUI_DART_VERSION=$DART_VERSION" \
  --dart-define="QUICUI_SDK_CHANNEL=$FLUTTER_CHANNEL" \
  --dart-define="QUICUI_IS_FORK=$IS_QUICUI"
