# iOS Engine Build Instructions for QuicUI

**Date:** November 25, 2025  
**Status:** Ready for Implementation  
**Prerequisites:** macOS, Xcode, Flutter engine source

---

## Prerequisites

### System Requirements
- macOS 12.0 (Monterey) or later
- Xcode 14.0 or later
- Command Line Tools installed
- 100+ GB free disk space
- 16+ GB RAM (recommended)

### Software Requirements
```bash
# Install depot_tools (if not already installed)
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$PATH:/path/to/depot_tools"

# Install required tools
brew install ant ninja
```

---

## Step 1: Apply Source Code Modifications

### 1.1 Copy QuicUI C++ Files (Already Done)

The C++ patch loader should already be in place from Android implementation:

```bash
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/shell/common/

# Verify files exist
ls -l quicui_patch_loader.h
ls -l quicui_patch_loader.cc
```

✅ **Status:** These files are already cross-platform and work on iOS without changes.

### 1.2 Add iOS-Specific Files

```bash
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/shell/platform/darwin/ios/framework/Source/

# Copy QuicUICodePushLoader.mm
cp /Users/admin/Documents/quicui2/docs/2025-11-25/ios_implementation/QuicUICodePushLoader.mm .

# Verify
ls -l QuicUICodePushLoader.mm
```

### 1.3 Modify Existing iOS Files

#### A. FlutterDartProject.mm

```bash
# Backup original
cp FlutterDartProject.mm FlutterDartProject.mm.backup

# Apply modifications
# Use the patch file as reference:
# /Users/admin/Documents/quicui2/docs/2025-11-25/ios_implementation/FlutterDartProject_patch.mm
```

**Key Changes:**
1. Import QuicUICodePushLoader
2. Add `patchedAOTPath` property
3. Add `checkForCodePushPatches` method
4. Modify `aotLibraryPath` method to check for patches

#### B. FlutterEngine.mm

```bash
# Backup original
cp FlutterEngine.mm FlutterEngine.mm.backup

# Apply modifications
# Use the patch file as reference:
# /Users/admin/Documents/quicui2/docs/2025-11-25/ios_implementation/FlutterEngine_patch.mm
```

**Key Changes:**
1. Call `[_dartProject checkForCodePushPatches]` before engine start
2. Add optional debug method `quicuiCheckForPatchesAndReload`

### 1.4 Update BUILD.gn

```bash
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/shell/platform/darwin/ios/framework/

# Edit BUILD.gn
nano BUILD.gn
```

Find the `ios_objc_library` target and add:

```python
sources = [
  # ... existing sources ...
  "Source/QuicUICodePushLoader.mm",  # ADD THIS
]

deps = [
  # ... existing deps ...
  "//flutter/shell/common:quicui_patch_loader",  # ADD THIS
]
```

---

## Step 2: Configure Build

### 2.1 Set Build Configuration

```bash
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src

# Create iOS release configuration
flutter/tools/gn \
  --ios \
  --runtime-mode=release \
  --no-lto \
  --ios-cpu=arm64
```

This creates `out/ios_release/` directory with build configuration.

### 2.2 Verify GN Configuration

```bash
# Check generated configuration
cat out/ios_release/args.gn

# Should see:
# target_os = "ios"
# target_cpu = "arm64"
# is_debug = false
# ...
```

---

## Step 3: Build iOS Engine

### 3.1 Build for iOS Device (arm64)

```bash
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src

# Build iOS release engine
ninja -C out/ios_release
```

**Expected Output:**
```
[1/1234] ...
[1234/1234] STAMP obj/flutter/shell/platform/darwin/ios/framework/Flutter.stamp
```

**Build Time:** 30-60 minutes (first build)  
**Output:** `out/ios_release/Flutter.xcframework/`

### 3.2 Build for iOS Simulator (Optional)

```bash
# Configure simulator build
flutter/tools/gn \
  --ios \
  --runtime-mode=debug \
  --unoptimized \
  --simulator \
  --simulator-cpu=arm64

# Build
ninja -C out/ios_debug_sim_unopt
```

**Output:** `out/ios_debug_sim_unopt/Flutter.xcframework/`

---

## Step 4: Verify Build

### 4.1 Check Output Structure

```bash
cd out/ios_release

# List xcframework contents
ls -la Flutter.xcframework/

# Expected structure:
# Flutter.xcframework/
# ├── Info.plist
# ├── ios-arm64/
# │   └── Flutter.framework/
# │       ├── Flutter          # Binary
# │       ├── Headers/
# │       ├── Info.plist
# │       └── Modules/
# └── ios-arm64_x86_64-simulator/ (if built)
```

### 4.2 Verify QuicUI Symbols

```bash
cd out/ios_release/Flutter.xcframework/ios-arm64/Flutter.framework

# Check for QuicUI symbols in binary
nm Flutter | grep -i quicui

# Should see C++ symbols like:
# flutter::QuicUIPatchLoader::GetPatchedAOTPath
# flutter::QuicUIPatchLoader::SetCodeCacheDir
# ...
```

### 4.3 Check File Size

```bash
ls -lh Flutter

# Should be ~80-100 MB for release build
```

---

## Step 5: Integrate with Flutter App

### 5.1 Option A: Use Local Engine (Development)

In your Flutter project:

```bash
cd /path/to/your/flutter/project

# Build with local custom engine
flutter build ios \
  --local-engine-src-path=/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src \
  --local-engine=ios_release
```

### 5.2 Option B: Replace Framework (Distribution)

```bash
# 1. Build your Flutter app normally
flutter build ios --release

# 2. Replace the Flutter.xcframework
cd ios/Flutter
rm -rf Flutter.xcframework
cp -R /Volumes/DoWonder2/.../out/ios_release/Flutter.xcframework .

# 3. Open in Xcode and archive
open ios/Runner.xcworkspace
```

### 5.3 Update Podfile (If Using CocoaPods)

```ruby
# ios/Podfile

flutter_application_path = '../'

# Point to custom engine
engine_path = '/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/out/ios_release'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods(engine_path: engine_path)
end
```

Then:
```bash
cd ios
pod install
```

---

## Step 6: Test on Device

### 6.1 Prepare Test App

```bash
cd /path/to/test/app

# Build baseline version
flutter build ios --release

# Install via Xcode or:
ios-deploy --bundle ios/build/Release-iphoneos/Runner.app
```

### 6.2 Check Logs

```bash
# View iOS device logs
idevicesyslog | grep QuicUI

# Expected output:
# [QuicUI] iOS Code Push Loader initialized
# [QuicUI] Cache directory: /var/mobile/.../Library/Caches
# [QuicUI] Architecture: arm64
# [QuicUI] No patch found (C++ returned empty string)
# [QuicUI] Using original AOT library: .../App.framework/App
```

### 6.3 Install a Patch

```bash
# Use QuicUI CLI to generate and upload patch
# (Client-side iOS patch installer needed - separate task)

# After patch installed, check logs again:
# [QuicUI] ✅ Found valid patch at: .../quicui_patches/App_patched_arm64
# [QuicUI] Patch size: 3.8 MB
# [QuicUI] ✅ Will use patched AOT from: ...
```

---

## Troubleshooting

### Build Errors

**Error: `quicui_patch_loader.h` not found**
```bash
# Solution: Verify C++ files exist
ls flutter/shell/common/quicui_patch_loader.*

# If missing, copy from Android implementation
```

**Error: Xcode version mismatch**
```bash
# Solution: Update Xcode
sudo xcode-select --switch /Applications/Xcode.app

# Verify
xcodebuild -version
```

**Error: Ninja build fails**
```bash
# Solution: Clean and rebuild
rm -rf out/ios_release
flutter/tools/gn --ios --runtime-mode=release --ios-cpu=arm64
ninja -C out/ios_release
```

### Runtime Errors

**Error: Patch not detected**
```bash
# Check cache directory path
idevicesyslog | grep "Cache directory"

# Verify patch file exists on device:
# (Requires jailbroken device or ssh access)
# ls -l /var/mobile/Containers/Data/Application/<UUID>/Library/Caches/quicui_patches/
```

**Error: Code signing issue**
```bash
# Solution: Re-sign patched AOT
codesign -f -s "iPhone Developer: Your Name" \
  /path/to/App_patched_arm64

# Verify signature
codesign -dvvv /path/to/App_patched_arm64
```

---

## Build Artifacts

After successful build, you'll have:

```
out/ios_release/
├── Flutter.xcframework/          # Main framework (distribute this)
│   ├── ios-arm64/
│   │   └── Flutter.framework/
│   │       └── Flutter           # Binary with QuicUI (~90 MB)
│   └── Info.plist
├── flutter.jar                   # iOS doesn't use this
└── gen/
    └── flutter/                  # Generated headers
```

**Distribution:**
- **For development:** Use `--local-engine` flag
- **For TestFlight:** Build app with custom framework, archive, upload
- **For App Store:** Same as TestFlight (subject to review)

---

## Next Steps

After building the engine:

1. ✅ **Verify build** - Check symbols, test on device
2. 📱 **Implement iOS client** - Dart + Swift/Objective-C patch downloader
3. 🧪 **Test patches** - Generate, upload, download, install
4. 🔐 **Add code signing** - Automate patch signing process
5. 🚀 **TestFlight beta** - Test with real users
6. 📦 **App Store submission** - Submit with documentation

---

## Estimated Time

- **First-time setup:** 2-3 hours
- **Apply modifications:** 1 hour
- **Build engine:** 1 hour
- **Testing:** 2-3 hours
- **Total:** ~6-10 hours

---

## Support

For issues:
1. Check logs: `idevicesyslog | grep QuicUI`
2. Verify file locations: `ls -la ~/Library/Caches/quicui_patches/`
3. Review engine build: `nm Flutter | grep quicui`
4. Test on simulator first before device

---

**Status:** Ready for implementation  
**Next Action:** Run Step 1 to apply source code modifications
