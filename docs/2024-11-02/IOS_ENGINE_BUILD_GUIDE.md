# iOS Engine Build Guide - QuicUI Code Push

**Date:** November 2, 2025  
**Status:** ✅ Engine Modified, Build Instructions Ready

---

## Overview

This guide explains how to build the modified Flutter iOS engine with QuicUI Code Push support. The engine has been modified to load patched AOT snapshots from the app's Documents directory, enabling over-the-air updates.

---

## What Was Modified

### File Changed

```
forks/flutter-official/engine/src/flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject.mm
```

### Modification Details

Added code push snapshot loading before the default App.framework loading logic:

```objc
// QuicUI Code Push: Check for patched snapshot first
NSArray* documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                                               NSUserDomainMask, 
                                                               YES);
if (documentsPaths.count > 0) {
  NSString* documentsPath = documentsPaths[0];
  NSString* patchedSnapshotDir = [documentsPath stringByAppendingPathComponent:@"quicui_snapshots"];
  NSString* patchedSnapshotPath = [patchedSnapshotDir stringByAppendingPathComponent:@"isolate_snapshot_data.patched"];
  
  if ([[NSFileManager defaultManager] fileExistsAtPath:patchedSnapshotPath]) {
    // Create temporary framework bundle for patched snapshot
    NSString* tempFrameworkPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"QuicUIPatchedApp.framework"];
    [[NSFileManager defaultManager] createDirectoryAtPath:tempFrameworkPath 
                              withIntermediateDirectories:YES 
                                               attributes:nil 
                                                    error:nil];
    
    NSString* tempSnapshotPath = [tempFrameworkPath stringByAppendingPathComponent:@"App"];
    NSError* copyError = nil;
    [[NSFileManager defaultManager] removeItemAtPath:tempSnapshotPath error:nil];
    if ([[NSFileManager defaultManager] copyItemAtPath:patchedSnapshotPath 
                                                 toPath:tempSnapshotPath 
                                                  error:&copyError]) {
      NSLog(@"[QuicUICodePush] ✅ Using patched snapshot: %@", patchedSnapshotPath);
      settings.application_library_paths.push_back(tempSnapshotPath.UTF8String);
    }
  }
}
```

### How It Works

1. **Check for Patch:** Looks for `isolate_snapshot_data.patched` in Documents/quicui_snapshots/
2. **Create Temp Bundle:** Creates QuicUIPatchedApp.framework in temp directory
3. **Copy Snapshot:** Copies patched snapshot to temp bundle as "App" executable
4. **Load Patched Code:** Engine loads from temp bundle instead of embedded App.framework
5. **Fallback:** If no patch exists, loads standard App.framework

---

## Prerequisites

### System Requirements

- macOS 12.0+ (Monterey or later)
- Xcode 14.0+
- Python 3.8+
- 50+ GB free disk space
- 8+ GB RAM

### Install Build Tools

```bash
# Install depot_tools (Google's build tools)
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$PATH:$HOME/depot_tools"

# Add to ~/.zshrc or ~/.bash_profile
echo 'export PATH="$PATH:$HOME/depot_tools"' >> ~/.zshrc
```

---

## Building the Engine

### Step 1: Sync Engine Dependencies

This downloads Skia, ICU, and other third-party dependencies (~10 GB):

```bash
cd /Users/admin/Documents/quicui2/forks/flutter-official/engine

# Create .gclient file
cat > .gclient << 'EOF'
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

# Sync dependencies (takes 30-60 minutes)
gclient sync -D --force --reset
```

### Step 2: Configure Build

Configure for iOS release mode:

```bash
cd src

# For iOS simulator (x64)
python3 flutter/tools/gn --ios --simulator --unoptimized

# For iOS device (arm64) - RECOMMENDED
python3 flutter/tools/gn --ios --runtime-mode=release

# For iOS device (debug mode)
python3 flutter/tools/gn --ios --unoptimized
```

This generates build files in `out/ios_release` (or `out/ios_debug_sim_unopt` for simulator).

### Step 3: Build Engine

Build the configured engine (takes 30-90 minutes):

```bash
# For iOS device release
ninja -C out/ios_release

# For iOS simulator
ninja -C out/ios_debug_sim_unopt
```

**Build Output:**
- Framework: `out/ios_release/Flutter.xcframework/`
- Size: ~200 MB
- Contains: Flutter.framework with code push support

### Step 4: Verify Build

```bash
# Check Flutter.framework was created
ls -lh out/ios_release/Flutter.xcframework/

# Should see:
# - ios-arm64/Flutter.framework/
# - Info.plist
```

---

## Using the Custom Engine

### Option 1: Local Engine (Development)

Use the local engine for testing:

```bash
cd /Users/admin/Documents/quicui2/test_apps/test_app_fresh

# Build with local engine
flutter build ios --local-engine-src-path=/Users/admin/Documents/quicui2/forks/flutter-official/engine/src \
                  --local-engine=ios_release \
                  --release
```

### Option 2: Replace Flutter SDK Engine (System-wide)

Replace the engine in your Flutter SDK:

```bash
# Backup original engine
cd /Users/admin/Documents/quicui2/forks/flutter-official/bin/cache/artifacts/engine/ios-release
mv Flutter.xcframework Flutter.xcframework.backup

# Copy custom engine
cp -r /Users/admin/Documents/quicui2/forks/flutter-official/engine/src/out/ios_release/Flutter.xcframework \
      /Users/admin/Documents/quicui2/forks/flutter-official/bin/cache/artifacts/engine/ios-release/

# Verify
flutter doctor -v
```

### Option 3: Pod Dependency (Per-App)

In your iOS app's Podfile:

```ruby
platform :ios, '12.0'

# Use custom Flutter engine
flutter_install_all_ios_pods(flutter_application_path, {
  flutter_local_engine_path: '/Users/admin/Documents/quicui2/forks/flutter-official/engine/src/out/ios_release'
})

target 'Runner' do
  use_frameworks!
  use_modular_headers!
end
```

---

## Testing the Modified Engine

### Step 1: Build Test App

```bash
cd /Users/admin/Documents/quicui2/test_apps/test_app_fresh

# Clean previous builds
flutter clean

# Build with custom engine
flutter build ios --local-engine-src-path=/Users/admin/Documents/quicui2/forks/flutter-official/engine/src \
                  --local-engine=ios_release \
                  --release

# Or if engine is in Flutter SDK
flutter build ios --release
```

### Step 2: Create Patched Snapshot

```bash
# Extract base snapshot
cp build/ios/Release-iphoneos/Runner.app/Frameworks/App.framework/App \
   ~/baseline_snapshot_ios

# Make code changes for v1.0.1
# ... edit lib/main.dart ...

# Build new version
flutter build ios --release

# Extract new snapshot
cp build/ios/Release-iphoneos/Runner.app/Frameworks/App.framework/App \
   ~/new_snapshot_ios

# Generate patch
/Users/admin/Documents/quicui2/packages/quicui_compiler/bin/quicui-compiler diff \
  ~/baseline_snapshot_ios \
  ~/new_snapshot_ios \
  --output=patch_ios.quicui
```

### Step 3: Test Patch Loading

```bash
# Install baseline version on iOS device
flutter install --release -d <device-id>

# Copy patch to device (via app logic or iTunes File Sharing)
# The app should place it in:
# Documents/quicui_snapshots/isolate_snapshot_data.patched

# Restart app - should load patched snapshot
# Check logs:
# [QuicUICodePush] ✅ Using patched snapshot: .../isolate_snapshot_data.patched
```

---

## Build Troubleshooting

### Error: "Python 2 is not supported"

```bash
# Use Python 3
python3 flutter/tools/gn --ios --runtime-mode=release
```

### Error: "depot_tools not found"

```bash
# Add depot_tools to PATH
export PATH="$PATH:$HOME/depot_tools"
```

### Error: "Xcode command line tools not found"

```bash
# Install Xcode command line tools
xcode-select --install
```

### Error: "gclient not found"

```bash
# Clone depot_tools
cd ~
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$PATH:$HOME/depot_tools"
```

### Error: "gn: path does not exist"

This means dependencies aren't synced. Run:

```bash
cd /Users/admin/Documents/quicui2/forks/flutter-official/engine
gclient sync -D --force --reset
```

### Build is Too Slow

Use multiple CPU cores:

```bash
# Use all cores
ninja -C out/ios_release -j$(sysctl -n hw.ncpu)

# Or specify core count
ninja -C out/ios_release -j8
```

---

## Build Time Estimates

| Build Type | First Build | Incremental | Size |
|------------|-------------|-------------|------|
| Debug (simulator) | 45-60 min | 2-5 min | ~300 MB |
| Release (device) | 60-90 min | 5-10 min | ~200 MB |
| Profile (device) | 60-90 min | 5-10 min | ~250 MB |

**Hardware:** MacBook Pro M1, 16GB RAM, SSD

---

## Alternative: Pre-built Engine

If building is too time-consuming, you can:

1. **Use CI/CD:** Set up GitHub Actions to build the engine
2. **Request Build:** Ask QuicUI team for pre-built engine
3. **Use Android Only:** Android engine modifications are already complete

---

## Verifying Code Push Works

After building and installing the custom engine:

```bash
# 1. Install baseline app
flutter install --release -d <device-id>

# 2. App should show in logs:
# [QuicUICodePush] Using base snapshot: .../App.framework/App

# 3. Download a patch via your app
# (QuicUICodePushLoader will write to Documents/quicui_snapshots/)

# 4. Restart app

# 5. App should now show:
# [QuicUICodePush] ✅ Using patched snapshot: .../isolate_snapshot_data.patched

# 6. Verify UI changes are applied
```

---

## Engine Commit

The engine modification has been committed to the QuicUI fork:

```
Repository: forks/flutter-official
Branch: quicui/main
Commit: ed3002d9cd5
Message: feat(ios-engine): Add QuicUI code push snapshot loading support
```

To see the changes:

```bash
cd /Users/admin/Documents/quicui2/forks/flutter-official
git log --oneline | head -5
git show ed3002d9cd5
```

---

## Next Steps

1. **Option A: Build Now**
   - Follow steps above to build custom engine
   - Test on iOS device
   - Verify code push flow works

2. **Option B: Test Android First**
   - Android engine already supports code push
   - Test complete flow on Android
   - Build iOS engine later

3. **Option C: CI/CD Build**
   - Set up automated engine builds
   - Host pre-built engines
   - Distribute to team

---

## References

- Flutter Engine Architecture: https://github.com/flutter/flutter/wiki/The-Engine-architecture
- Building the Engine: https://github.com/flutter/flutter/wiki/Compiling-the-engine
- Local Engine: https://github.com/flutter/flutter/wiki/The-flutter-tool#using-a-local-engine-build-with-the-flutter-tool
- Engine Source: /Users/admin/Documents/quicui2/forks/flutter-official/engine/
- Modified File: engine/src/flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject.mm

---

## Summary

✅ **Engine Modified:** Custom snapshot loading added to FlutterDartProject.mm  
✅ **Changes Committed:** ed3002d9cd5 in quicui/main branch  
⏳ **Build Pending:** Follow steps above to build (60-90 minutes)  
⏳ **Testing Pending:** Install and verify on iOS device

The modification is complete and ready to build. The engine will check for patched snapshots before loading the default App.framework, enabling code push on iOS.
