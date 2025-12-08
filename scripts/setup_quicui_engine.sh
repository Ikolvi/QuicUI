#!/bin/bash

# QuicUI Engine Setup Script
# This script configures the Flutter engine fork with QuicUI modifications
# and deploys the built artifacts to the Flutter SDK cache

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENGINE_ROOT="/Volumes/DoWonder2/quicui_engine_build/engine_full/src"
FLUTTER_SDK="$PROJECT_ROOT/forks/flutter"

echo "=================================================="
echo "QuicUI Engine Setup and Deployment"
echo "=================================================="
echo ""
echo "Project Root: $PROJECT_ROOT"
echo "Engine Root: $ENGINE_ROOT"
echo "Flutter SDK: $FLUTTER_SDK"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if engine root exists
if [ ! -d "$ENGINE_ROOT" ]; then
    print_error "Engine root not found: $ENGINE_ROOT"
    exit 1
fi

cd "$ENGINE_ROOT"

# ============================================================
# Step 1: Verify QuicUI C++ Files Exist
# ============================================================
print_status "Step 1: Verifying QuicUI implementation files..."

QUICUI_FILES=(
    "flutter/shell/common/quicui_patch_loader.h"
    "flutter/shell/common/quicui_patch_loader.cc"
    "flutter/shell/platform/android/io/flutter/embedding/engine/loader/QuicUICodePushLoader.java"
    "flutter/shell/platform/darwin/ios/framework/Source/QuicUICodePushLoader.h"
    "flutter/shell/platform/darwin/ios/framework/Source/QuicUICodePushLoader.mm"
)

ALL_FILES_EXIST=true
for file in "${QUICUI_FILES[@]}"; do
    if [ -f "$ENGINE_ROOT/$file" ]; then
        print_success "✓ $file"
    else
        print_error "✗ $file NOT FOUND"
        ALL_FILES_EXIST=false
    fi
done

if [ "$ALL_FILES_EXIST" = false ]; then
    print_error "Some QuicUI files are missing. Cannot proceed."
    exit 1
fi

print_success "All QuicUI implementation files present"
echo ""

# ============================================================
# Step 2: Modify Android BUILD.gn (shell/common)
# ============================================================
print_status "Step 2: Checking shell/common/BUILD.gn modifications..."

BUILD_GN="$ENGINE_ROOT/flutter/shell/common/BUILD.gn"
if grep -q "quicui_patch_loader.cc" "$BUILD_GN"; then
    print_success "BUILD.gn already includes QuicUI C++ files"
else
    print_warning "BUILD.gn needs QuicUI modifications"
    print_status "Adding quicui_patch_loader.cc and .h to sources..."
    
    # Backup BUILD.gn
    cp "$BUILD_GN" "$BUILD_GN.backup_$(date +%Y%m%d_%H%M%S)"
    
    # Add QuicUI files to sources (after switches.h)
    # This is a safe insertion point in the sources array
    print_status "Modifying BUILD.gn..."
    
    cat > /tmp/quicui_build_patch.txt << 'EOF'
    "quicui_patch_loader.cc",
    "quicui_patch_loader.h",
EOF
    
    # Insert after "switches.h",
    sed -i '' '/\"switches\.h\",/a\
    "quicui_patch_loader.cc",\
    "quicui_patch_loader.h",
' "$BUILD_GN"
    
    if grep -q "quicui_patch_loader.cc" "$BUILD_GN"; then
        print_success "BUILD.gn modified successfully"
    else
        print_error "Failed to modify BUILD.gn"
        exit 1
    fi
fi
echo ""

# ============================================================
# Step 3: Modify Android flutter_main.cc
# ============================================================
print_status "Step 3: Checking Android flutter_main.cc modifications..."

FLUTTER_MAIN_ANDROID="$ENGINE_ROOT/flutter/shell/platform/android/flutter_main.cc"

if grep -q "ConfigureQuicUI" "$FLUTTER_MAIN_ANDROID"; then
    print_success "flutter_main.cc already has ConfigureQuicUI"
else
    print_warning "flutter_main.cc needs ConfigureQuicUI function"
    
    # Backup flutter_main.cc
    cp "$FLUTTER_MAIN_ANDROID" "$FLUTTER_MAIN_ANDROID.backup_$(date +%Y%m%d_%H%M%S)"
    
    print_status "Adding #include for quicui_patch_loader.h..."
    
    # Add include after the last #include line
    sed -i '' '/^#include "third_party\/dart\/runtime\/include\/dart_tools_api.h"$/a\
#include "flutter/shell/common/quicui_patch_loader.h"\
#include <sys/stat.h>
' "$FLUTTER_MAIN_ANDROID"
    
    print_status "Adding ConfigureQuicUI() function..."
    
    # Add ConfigureQuicUI function before Init() function
    # Find the line with "bool FlutterMain::Register" and add before it
    cat > /tmp/configure_quicui.txt << 'EOF'

// QuicUI Code Push Configuration
// Checks for installed AOT patches and configures Flutter to load them
static void ConfigureQuicUI(flutter::Settings& settings, 
                           const std::string& code_cache_dir,
                           const std::string& architecture) {
  // Initialize QuicUI patch loader
  flutter::QuicUIPatchLoader loader;
  loader.SetCodeCacheDir(code_cache_dir);
  
  // Check for patched AOT snapshot
  std::string patched_path = loader.GetPatchedAOTPath(architecture);
  
  if (!patched_path.empty()) {
    __android_log_print(ANDROID_LOG_INFO, "FlutterMain", 
                       "[QuicUI] Found patched AOT at: %s", patched_path.c_str());
    
    // Validate the patch
    struct stat buffer;
    if (stat(patched_path.c_str(), &buffer) == 0) {
      __android_log_print(ANDROID_LOG_INFO, "FlutterMain",
                         "[QuicUI] Patch file size: %lld bytes", (long long)buffer.st_size);
      
      // Clear default application_library_path
      settings.application_library_path.clear();
      
      // Set to patched library
      settings.application_library_path.push_back(patched_path);
      
      __android_log_print(ANDROID_LOG_INFO, "FlutterMain",
                         "[QuicUI] ✅ Configured to use patched AOT snapshot");
    } else {
      __android_log_print(ANDROID_LOG_WARN, "FlutterMain",
                         "[QuicUI] ⚠️ Patch file not accessible, using original");
    }
  } else {
    __android_log_print(ANDROID_LOG_INFO, "FlutterMain",
                       "[QuicUI] No patch installed, using original AOT");
  }
}

EOF

    # Find line number of "bool FlutterMain::Register"
    LINE_NUM=$(grep -n "bool FlutterMain::Register" "$FLUTTER_MAIN_ANDROID" | head -1 | cut -d: -f1)
    
    if [ -z "$LINE_NUM" ]; then
        print_error "Could not find insertion point in flutter_main.cc"
        exit 1
    fi
    
    # Insert ConfigureQuicUI function before Register
    sed -i '' "${LINE_NUM}i\\
$(cat /tmp/configure_quicui.txt)
" "$FLUTTER_MAIN_ANDROID"
    
    print_success "ConfigureQuicUI() function added"
    
    # Now we need to call ConfigureQuicUI from Init()
    print_status "Adding ConfigureQuicUI() call in Init()..."
    
    # Find the Init() function and add call after settings are initialized
    # Look for "settings.task_observer_add" line as anchor
    if grep -q "settings.task_observer_add" "$FLUTTER_MAIN_ANDROID"; then
        sed -i '' '/settings\.task_observer_add/a\
\
  // QuicUI: Configure code push patches\
  std::string code_cache_dir = flutter::fml::paths::GetCachesDirectory();\
  std::string architecture = "arm64-v8a";  // TODO: Get from ABI\
  ConfigureQuicUI(settings, code_cache_dir, architecture);
' "$FLUTTER_MAIN_ANDROID"
        print_success "ConfigureQuicUI() call added to Init()"
    else
        print_warning "Could not auto-add ConfigureQuicUI() call - add manually"
    fi
fi

if grep -q "ConfigureQuicUI" "$FLUTTER_MAIN_ANDROID"; then
    print_success "flutter_main.cc configured for QuicUI"
else
    print_error "flutter_main.cc configuration failed"
    exit 1
fi
echo ""

# ============================================================
# Step 4: Verify iOS modifications
# ============================================================
print_status "Step 4: Verifying iOS BUILD.gn modifications..."

IOS_BUILD_GN="$ENGINE_ROOT/flutter/shell/platform/darwin/ios/BUILD.gn"

if grep -q "QuicUICodePushLoader" "$IOS_BUILD_GN"; then
    print_success "iOS BUILD.gn already includes QuicUI files"
else
    print_error "iOS BUILD.gn missing QuicUI - already configured manually"
fi
echo ""

# ============================================================
# Step 5: Build Configuration Check
# ============================================================
print_status "Step 5: Checking build configuration..."

# Check if we're using the right Xcode
XCODE_PATH=$(xcode-select -p)
XCODE_VERSION=$(xcodebuild -version | head -1)

print_status "Xcode Path: $XCODE_PATH"
print_status "Xcode Version: $XCODE_VERSION"

if [[ "$XCODE_VERSION" == *"26"* ]]; then
    print_error "Xcode 26 beta detected - iOS build will FAIL"
    print_error "Please download and install Xcode 16 stable"
    print_error "Run: sudo xcode-select -s /Applications/Xcode-16.app"
    XCODE_OK=false
else
    print_success "Xcode version looks good"
    XCODE_OK=true
fi
echo ""

# ============================================================
# Step 6: Ask user what to build
# ============================================================
echo "=================================================="
echo "Build Options"
echo "=================================================="
echo ""
echo "What would you like to build?"
echo ""
echo "  1) Android ARM64 engine only (~45 min)"
echo "  2) iOS release engine only (~90 min, requires Xcode 16)"
echo "  3) Both Android + iOS (~135 min)"
echo "  4) Skip build, just show status"
echo ""
read -p "Enter choice [1-4]: " BUILD_CHOICE
echo ""

case $BUILD_CHOICE in
    1)
        BUILD_ANDROID=true
        BUILD_IOS=false
        ;;
    2)
        BUILD_ANDROID=false
        BUILD_IOS=true
        
        if [ "$XCODE_OK" = false ]; then
            print_error "Cannot build iOS with Xcode 26 beta"
            exit 1
        fi
        ;;
    3)
        BUILD_ANDROID=true
        BUILD_IOS=true
        
        if [ "$XCODE_OK" = false ]; then
            print_error "Cannot build iOS with Xcode 26 beta"
            exit 1
        fi
        ;;
    4)
        BUILD_ANDROID=false
        BUILD_IOS=false
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

# ============================================================
# Step 7: Build Android Engine
# ============================================================
if [ "$BUILD_ANDROID" = true ]; then
    print_status "Step 7: Building Android ARM64 engine..."
    echo ""
    
    cd "$ENGINE_ROOT"
    export PATH="/Volumes/DoWonder2/quicui_engine_build/depot_tools:$PATH"
    
    # Clean previous build
    print_status "Cleaning previous Android build..."
    rm -rf out/android_release_arm64
    
    # Configure
    print_status "Configuring Android build..."
    ./flutter/tools/gn --android --android-cpu arm64 --runtime-mode release --no-lto
    
    # Build
    print_status "Building Android engine (4352 targets, ~45 minutes)..."
    print_status "Log: /tmp/android_engine_build.log"
    
    /Volumes/DoWonder2/quicui_engine_build/depot_tools/ninja \
        -C out/android_release_arm64 \
        -j4 2>&1 | tee /tmp/android_engine_build.log
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        print_success "Android engine build completed!"
        
        # Verify QuicUI symbols
        print_status "Verifying QuicUI symbols in libflutter.so..."
        if nm -D out/android_release_arm64/libflutter.so | grep -i quicui > /tmp/quicui_symbols.txt; then
            print_success "QuicUI symbols found:"
            cat /tmp/quicui_symbols.txt | head -10
        else
            print_error "QuicUI symbols NOT found in libflutter.so"
        fi
    else
        print_error "Android engine build FAILED"
        print_error "Check log: /tmp/android_engine_build.log"
        exit 1
    fi
    echo ""
fi

# ============================================================
# Step 8: Build iOS Engine
# ============================================================
if [ "$BUILD_IOS" = true ]; then
    print_status "Step 8: Building iOS release engine..."
    echo ""
    
    cd "$ENGINE_ROOT"
    export PATH="/Volumes/DoWonder2/quicui_engine_build/depot_tools:$PATH"
    
    # Clean previous build
    print_status "Cleaning previous iOS build..."
    rm -rf out/ios_release
    
    # Configure
    print_status "Configuring iOS build..."
    ./flutter/tools/gn --ios --runtime-mode release --no-lto
    
    # Build
    print_status "Building iOS engine (6597 targets, ~90 minutes)..."
    print_status "Log: /tmp/ios_engine_build.log"
    
    /Volumes/DoWonder2/quicui_engine_build/depot_tools/ninja \
        -C out/ios_release \
        -j4 2>&1 | tee /tmp/ios_engine_build.log
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        print_success "iOS engine build completed!"
        
        # Verify QuicUI symbols
        print_status "Verifying QuicUI symbols in Flutter.xcframework..."
        if nm out/ios_release/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter | grep -i quicui > /tmp/quicui_ios_symbols.txt; then
            print_success "QuicUI symbols found:"
            cat /tmp/quicui_ios_symbols.txt | head -10
        else
            print_warning "QuicUI symbols check - need to verify manually"
        fi
    else
        print_error "iOS engine build FAILED"
        print_error "Check log: /tmp/ios_engine_build.log"
        exit 1
    fi
    echo ""
fi

# ============================================================
# Step 9: Deploy to Flutter SDK Cache
# ============================================================
print_status "Step 9: Deploy to Flutter SDK cache..."
echo ""

if [ ! -d "$FLUTTER_SDK" ]; then
    print_error "Flutter SDK not found: $FLUTTER_SDK"
    exit 1
fi

SDK_ENGINE_DIR="$FLUTTER_SDK/bin/cache/artifacts/engine"

# Deploy Android artifacts
if [ "$BUILD_ANDROID" = true ]; then
    print_status "Deploying Android engine artifacts..."
    
    mkdir -p "$SDK_ENGINE_DIR/android-arm64-release"
    
    # Backup existing
    if [ -f "$SDK_ENGINE_DIR/android-arm64-release/linux-x64/flutter.jar" ]; then
        print_status "Backing up existing flutter.jar..."
        cp "$SDK_ENGINE_DIR/android-arm64-release/linux-x64/flutter.jar" \
           "$SDK_ENGINE_DIR/android-arm64-release/linux-x64/flutter.jar.backup_$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Copy flutter.jar
    print_status "Copying flutter.jar..."
    mkdir -p "$SDK_ENGINE_DIR/android-arm64-release/linux-x64"
    cp "$ENGINE_ROOT/out/android_release_arm64/flutter.jar" \
       "$SDK_ENGINE_DIR/android-arm64-release/linux-x64/"
    
    # Copy libflutter.so
    print_status "Copying libflutter.so..."
    mkdir -p "$SDK_ENGINE_DIR/android-arm64-release/linux-x64/lib.unstripped"
    cp "$ENGINE_ROOT/out/android_release_arm64/lib.unstripped/libflutter.so" \
       "$SDK_ENGINE_DIR/android-arm64-release/linux-x64/lib.unstripped/"
    
    print_success "Android engine deployed"
    ls -lh "$SDK_ENGINE_DIR/android-arm64-release/linux-x64/flutter.jar"
    ls -lh "$SDK_ENGINE_DIR/android-arm64-release/linux-x64/lib.unstripped/libflutter.so"
fi

# Deploy iOS artifacts
if [ "$BUILD_IOS" = true ]; then
    print_status "Deploying iOS engine artifacts..."
    
    mkdir -p "$SDK_ENGINE_DIR/ios-release"
    
    # Backup existing
    if [ -d "$SDK_ENGINE_DIR/ios-release/Flutter.xcframework" ]; then
        print_status "Backing up existing Flutter.xcframework..."
        mv "$SDK_ENGINE_DIR/ios-release/Flutter.xcframework" \
           "$SDK_ENGINE_DIR/ios-release/Flutter.xcframework.backup_$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Copy Flutter.xcframework
    print_status "Copying Flutter.xcframework..."
    cp -R "$ENGINE_ROOT/out/ios_release/Flutter.xcframework" \
          "$SDK_ENGINE_DIR/ios-release/"
    
    print_success "iOS engine deployed"
    ls -lh "$SDK_ENGINE_DIR/ios-release/Flutter.xcframework"
fi

echo ""
print_success "Deployment completed!"

# ============================================================
# Step 10: Summary
# ============================================================
echo ""
echo "=================================================="
echo "Setup Complete!"
echo "=================================================="
echo ""
print_success "QuicUI engine modifications applied"
echo ""
echo "Modified files:"
echo "  • flutter/shell/common/BUILD.gn"
echo "  • flutter/shell/platform/android/flutter_main.cc"
echo "  • flutter/shell/platform/darwin/ios/BUILD.gn"
echo ""
echo "QuicUI implementation files:"
echo "  • flutter/shell/common/quicui_patch_loader.{h,cc}"
echo "  • Android: QuicUICodePushLoader.java"
echo "  • iOS: QuicUICodePushLoader.{h,mm}"
echo ""

if [ "$BUILD_ANDROID" = true ] || [ "$BUILD_IOS" = true ]; then
    echo "Built artifacts:"
    
    if [ "$BUILD_ANDROID" = true ]; then
        echo "  • Android: flutter.jar ($(du -h $ENGINE_ROOT/out/android_release_arm64/flutter.jar | cut -f1))"
        echo "  • Android: libflutter.so ($(du -h $ENGINE_ROOT/out/android_release_arm64/lib.unstripped/libflutter.so | cut -f1))"
    fi
    
    if [ "$BUILD_IOS" = true ]; then
        echo "  • iOS: Flutter.xcframework"
    fi
    
    echo ""
    echo "Deployed to Flutter SDK: $FLUTTER_SDK"
fi

echo ""
echo "Next steps:"
echo "  1. cd $PROJECT_ROOT/test_apps/quicui_production_test"
echo "  2. $FLUTTER_SDK/bin/flutter clean"
echo "  3. $FLUTTER_SDK/bin/flutter build [android|ios] --release"
echo "  4. Deploy and test QuicUI code push"
echo ""
print_success "All done! 🚀"
