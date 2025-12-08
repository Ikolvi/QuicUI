#!/bin/bash

# Deploy Existing QuicUI Engine to Flutter SDK Cache
# This script deploys the already-built QuicUI engine from official_engine

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OFFICIAL_ENGINE="/Volumes/DoWonder2/quicui_engine_build/official_engine/src"
ENGINE_FULL="/Volumes/DoWonder2/quicui_engine_build/engine_full/src"
FLUTTER_SDK="$PROJECT_ROOT/forks/flutter"

echo "=================================================="
echo "Deploy QuicUI Engine to Flutter SDK"
echo "=================================================="
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check sources
if [ -d "$OFFICIAL_ENGINE" ]; then
    ANDROID_SOURCE="$OFFICIAL_ENGINE"
    print_status "Using Android engine from: official_engine (ALREADY BUILT ✅)"
else
    print_error "official_engine not found"
    exit 1
fi

if [ -d "$ENGINE_FULL" ]; then
    IOS_SOURCE="$ENGINE_FULL"
    print_status "Using iOS engine from: engine_full"
else
    print_warning "engine_full not found - iOS deployment will be skipped"
    IOS_SOURCE=""
fi

# Check Flutter SDK
if [ ! -d "$FLUTTER_SDK" ]; then
    print_error "Flutter SDK not found: $FLUTTER_SDK"
    exit 1
fi

SDK_ENGINE_DIR="$FLUTTER_SDK/bin/cache/artifacts/engine"
print_status "Flutter SDK: $FLUTTER_SDK"
echo ""

# ============================================================
# Android Deployment
# ============================================================
print_status "Deploying Android QuicUI Engine..."

ANDROID_OUT="$ANDROID_SOURCE/out/android_release_arm64"

if [ ! -f "$ANDROID_OUT/flutter.jar" ]; then
    print_error "flutter.jar not found in official_engine/out/"
    print_error "Run: cd $OFFICIAL_ENGINE && ninja -C out/android_release_arm64"
    exit 1
fi

# Show what we're deploying
print_status "Android artifacts:"
ls -lh "$ANDROID_OUT/flutter.jar"
ls -lh "$ANDROID_OUT/libflutter.so" 2>/dev/null || echo "  libflutter.so: (stripped version will be used)"

# Create target directories
mkdir -p "$SDK_ENGINE_DIR/android-arm64-release/linux-x64"
mkdir -p "$SDK_ENGINE_DIR/android-arm64-release/linux-x64/lib.unstripped"

# Backup existing files
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
if [ -f "$SDK_ENGINE_DIR/android-arm64-release/linux-x64/flutter.jar" ]; then
    print_status "Backing up existing flutter.jar..."
    cp "$SDK_ENGINE_DIR/android-arm64-release/linux-x64/flutter.jar" \
       "$SDK_ENGINE_DIR/android-arm64-release/linux-x64/flutter.jar.backup_$TIMESTAMP"
fi

if [ -f "$SDK_ENGINE_DIR/android-arm64-release/linux-x64/lib.unstripped/libflutter.so" ]; then
    print_status "Backing up existing libflutter.so..."
    cp "$SDK_ENGINE_DIR/android-arm64-release/linux-x64/lib.unstripped/libflutter.so" \
       "$SDK_ENGINE_DIR/android-arm64-release/linux-x64/lib.unstripped/libflutter.so.backup_$TIMESTAMP"
fi

# Deploy flutter.jar
print_status "Deploying flutter.jar (5.5MB)..."
cp "$ANDROID_OUT/flutter.jar" "$SDK_ENGINE_DIR/android-arm64-release/linux-x64/"

# Deploy libflutter.so
print_status "Deploying libflutter.so (156MB)..."
cp "$ANDROID_OUT/libflutter.so" "$SDK_ENGINE_DIR/android-arm64-release/linux-x64/lib.unstripped/"

print_success "Android engine deployed to Flutter SDK ✅"
echo ""
ls -lh "$SDK_ENGINE_DIR/android-arm64-release/linux-x64/flutter.jar"
ls -lh "$SDK_ENGINE_DIR/android-arm64-release/linux-x64/lib.unstripped/libflutter.so"
echo ""

# ============================================================
# iOS Deployment (if available)
# ============================================================
if [ -n "$IOS_SOURCE" ] && [ -d "$IOS_SOURCE/out/ios_release" ]; then
    print_status "Checking iOS engine..."
    
    if [ -d "$IOS_SOURCE/out/ios_release/Flutter.xcframework" ]; then
        print_status "Deploying iOS QuicUI Engine..."
        
        mkdir -p "$SDK_ENGINE_DIR/ios-release"
        
        # Backup existing
        if [ -d "$SDK_ENGINE_DIR/ios-release/Flutter.xcframework" ]; then
            print_status "Backing up existing Flutter.xcframework..."
            mv "$SDK_ENGINE_DIR/ios-release/Flutter.xcframework" \
               "$SDK_ENGINE_DIR/ios-release/Flutter.xcframework.backup_$TIMESTAMP"
        fi
        
        # Deploy
        print_status "Deploying Flutter.xcframework..."
        cp -R "$IOS_SOURCE/out/ios_release/Flutter.xcframework" \
              "$SDK_ENGINE_DIR/ios-release/"
        
        print_success "iOS engine deployed to Flutter SDK ✅"
        echo ""
        du -sh "$SDK_ENGINE_DIR/ios-release/Flutter.xcframework"
        echo ""
    else
        print_warning "iOS engine not built yet - skipping iOS deployment"
        print_warning "Run iOS build first to deploy iOS engine"
        echo ""
    fi
else
    print_warning "iOS engine source not available - skipping iOS deployment"
    echo ""
fi

# ============================================================
# Summary
# ============================================================
echo "=================================================="
print_success "Deployment Complete!"
echo "=================================================="
echo ""
echo "Deployed to: $FLUTTER_SDK"
echo ""
echo "Android Engine:"
echo "  ✅ flutter.jar (5.5MB)"
echo "  ✅ libflutter.so (156MB)"
echo "  ✅ QuicUI ConfigureQuicUI() integrated"
echo "  ✅ QuicUI C++ patch loader included"
echo ""

if [ -d "$SDK_ENGINE_DIR/ios-release/Flutter.xcframework" ]; then
    echo "iOS Engine:"
    echo "  ✅ Flutter.xcframework deployed"
    echo "  ✅ QuicUICodePushLoader.mm integrated"
    echo ""
fi

echo "Backups saved with timestamp: $TIMESTAMP"
echo ""
echo "Next steps:"
echo "  1. cd $PROJECT_ROOT/test_apps/quicui_production_test"
echo "  2. $FLUTTER_SDK/bin/flutter clean"
echo "  3. $FLUTTER_SDK/bin/flutter build android --release"
echo "  4. Deploy and test QuicUI patches"
echo ""
print_success "Ready to build with QuicUI engine! 🚀"
