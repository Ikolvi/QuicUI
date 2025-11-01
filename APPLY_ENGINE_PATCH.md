# QuicUI Engine Patch Application Guide

This guide shows how to apply the unified QuicUI Code Push modifications to any Flutter SDK version.

## 📦 What's Included

The patch file `quicui-engine-codepush-v1.0.0.patch` contains:

### Android Modifications
- **FlutterLoader.java** - Checks for patched libapp.so before loading
- **QuicUICodePushLoader.java** - Manages patch installation and validation
- **codepush_loader.h/cc** - C++ bridge for native code push support

### iOS Modifications
- **FlutterDartProject.mm** - Loads patched snapshots from Documents directory

### SDK Detection
- **flutter_version.dart** - Adds QuicUI SDK identification

### Documentation
- **MIGRATION_GUIDE.md** - Manual merge instructions for conflicts

---

## 🚀 Quick Start: Apply Patch to New Flutter SDK

### Option 1: Apply Patch File (Recommended)

```bash
# 1. Clone the Flutter SDK version you want to patch
git clone https://github.com/flutter/flutter.git -b 3.27.0 flutter-3.27.0-quicui
cd flutter-3.27.0-quicui

# 2. Apply the QuicUI patch
git am /path/to/quicui-engine-codepush-v1.0.0.patch

# 3. Build the engine (if needed)
cd engine/src
python3 flutter/tools/gn --android --runtime-mode=release
ninja -C out/android_release

# 4. Use your patched SDK
export PATH="$(pwd)/bin:$PATH"
flutter --version
```

### Option 2: Cherry-pick from QuicUI Fork

```bash
# 1. Clone Flutter SDK
git clone https://github.com/flutter/flutter.git -b 3.27.0 flutter-3.27.0-quicui
cd flutter-3.27.0-quicui

# 2. Add QuicUI remote
git remote add quicui https://github.com/Ikolvi/QuicUIFlutterSDK.git
git fetch quicui

# 3. Cherry-pick the commits
git cherry-pick 15f629c8e3f  # QuicUI SDK identification
git cherry-pick 9fcb574f34e  # Android code push support
git cherry-pick ef50e0383f1  # Version detection docs
git cherry-pick ed3002d9cd5  # iOS code push support

# 4. Build if needed
cd engine/src
python3 flutter/tools/gn --ios --runtime-mode=release
ninja -C out/ios_release
```

---

## 🔧 Handling Merge Conflicts

If you encounter conflicts during `git am` or `git cherry-pick`, refer to the included `MIGRATION_GUIDE.md` for detailed manual merge instructions.

### Common Conflicts

**FlutterLoader.java** - Android engine loader might have structural changes
- Solution: Manually add `checkForQuicUIPatch()` call before initialization completes
- See MIGRATION_GUIDE.md section "Common Conflict: FlutterLoader.java"

**FlutterDartProject.mm** - iOS snapshot loading logic might differ
- Solution: Insert patched snapshot check before existing App.framework loading
- See MIGRATION_GUIDE.md section "Common Conflict: FlutterDartProject.mm"

**flutter_version.dart** - Version detection API might change
- Solution: Add `isQuicUISDK` field to version info structure
- Usually this file has minimal changes between Flutter versions

---

## ✅ Verifying the Patch

After applying the patch, verify it worked:

### Check Files Exist

```bash
# Android files
ls engine/src/flutter/shell/platform/android/io/flutter/embedding/engine/loader/QuicUICodePushLoader.java
ls engine/src/flutter/shell/common/codepush_loader.cc

# iOS file
ls engine/src/flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject.mm

# SDK detection
ls packages/flutter/lib/src/services/flutter_version.dart
```

### Search for QuicUI Markers

```bash
# Android: Check for patch loading logic
grep -n "checkForQuicUIPatch" engine/src/flutter/shell/platform/android/io/flutter/embedding/engine/loader/FlutterLoader.java

# iOS: Check for patched snapshot logic
grep -n "quicui_snapshots" engine/src/flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject.mm

# SDK detection
grep -n "isQuicUISDK" packages/flutter/lib/src/services/flutter_version.dart
```

Expected output:
```
FlutterLoader.java:123:  private void checkForQuicUIPatch() {
FlutterDartProject.mm:98:  NSString* patchedSnapshotPath = [documentsPath stringByAppendingPathComponent:@"quicui_snapshots/isolate_snapshot_data.patched"];
flutter_version.dart:45:  bool get isQuicUISDK => _channel == 'quicui';
```

### Run Verification Script

```bash
# Use the included verification script
cd forks/flutter-official/.quicui
bash verify_quicui_sdk.sh
```

Expected output:
```
✓ QuicUI SDK marker found
✓ Android code push support enabled
✓ iOS code push support enabled
✓ Version detection configured
✅ All checks passed! This is a QuicUI-enabled Flutter SDK.
```

---

## 📋 File Changes Summary

| File | Platform | Change Type | Lines |
|------|----------|-------------|-------|
| `FlutterLoader.java` | Android | Modified | +70 |
| `QuicUICodePushLoader.java` | Android | New | +280 |
| `codepush_loader.h` | Android | Modified | +55 |
| `codepush_loader.cc` | Android | Modified | +302 |
| `FlutterDartProject.mm` | iOS | Modified | +38 |
| `flutter_version.dart` | Both | Modified | +15 |
| `MIGRATION_GUIDE.md` | Docs | New | +500 |

**Total changes**: ~1,260 lines across 7 files

---

## 🏗️ Building the Engine (Optional)

The patch modifies engine source code. You'll need to rebuild the engine if you want to use it.

### Android Engine Build

```bash
cd engine/src

# Configure for Android
python3 flutter/tools/gn --android --runtime-mode=release

# Build (takes 30-60 minutes)
ninja -C out/android_release

# Use local engine in your app
flutter run --local-engine=android_release \
  --local-engine-src-path=/path/to/engine/src
```

### iOS Engine Build

```bash
cd engine/src

# Configure for iOS
python3 flutter/tools/gn --ios --runtime-mode=release

# Build (takes 60-90 minutes)
ninja -C out/ios_release

# Use local engine
flutter run --local-engine=ios_release \
  --local-engine-src-path=/path/to/engine/src
```

**Note**: See `IOS_ENGINE_BUILD_GUIDE.md` for detailed iOS build instructions.

---

## 🧪 Testing the Patch

### 1. Create Test App

```bash
flutter create test_codepush_app
cd test_codepush_app

# Add QuicUI dependencies to pubspec.yaml
flutter pub add quicui_code_push_client
```

### 2. Android Test

```bash
# Build release APK
flutter build apk --release

# Check for code push support in logs
flutter install --release
adb logcat | grep -i quicui

# Expected log output:
# [QuicUICodePush] No patched snapshot found, using base version
# [QuicUICodePush] Initialized successfully
```

### 3. iOS Test

```bash
# Build release IPA
flutter build ios --release

# Deploy to device
flutter install --release -d <device-id>

# Check for code push support in logs
# Expected: "[QuicUICodePush] No patched snapshot found, using base version"
```

---

## 🔄 Updating to Newer Flutter Versions

When a new Flutter version is released:

1. **Clone new Flutter version**
   ```bash
   git clone https://github.com/flutter/flutter.git -b 3.28.0 flutter-3.28.0-quicui
   ```

2. **Apply the patch**
   ```bash
   cd flutter-3.28.0-quicui
   git am /path/to/quicui-engine-codepush-v1.0.0.patch
   ```

3. **Handle conflicts** (if any)
   ```bash
   # If git am fails with conflicts:
   git am --show-current-patch  # See what's conflicting
   
   # Edit conflicting files manually (see MIGRATION_GUIDE.md)
   git add <fixed-files>
   git am --continue
   ```

4. **Verify and build**
   ```bash
   bash forks/flutter-official/.quicui/verify_quicui_sdk.sh
   cd engine/src && python3 flutter/tools/gn --android --runtime-mode=release
   ninja -C out/android_release
   ```

---

## 📚 Additional Resources

- **MIGRATION_GUIDE.md** - Detailed manual merge instructions
- **IOS_ENGINE_BUILD_GUIDE.md** - Complete iOS engine build guide
- **BSDIFF_IMPLEMENTATION.md** - Binary diffing algorithm documentation
- **IOS_IMPLEMENTATION.md** - iOS architecture details

---

## 🐛 Troubleshooting

### Patch Fails to Apply

**Error**: `error: patch failed: engine/src/.../FlutterLoader.java:123`

**Solution**: The target Flutter version has significant changes. Use manual merge:
```bash
git am --abort
# Follow manual instructions in MIGRATION_GUIDE.md
```

### Build Fails After Patch

**Error**: `ninja: error: unknown target 'flutter/shell/common/codepush_loader.cc'`

**Solution**: Re-run GN configuration:
```bash
cd engine/src
rm -rf out
python3 flutter/tools/gn --android --runtime-mode=release
ninja -C out/android_release
```

### QuicUI Not Detected

**Error**: Verification script reports "QuicUI marker not found"

**Solution**: Check if patch was applied completely:
```bash
git log --oneline -5 | grep -i quicui
# Should show: "[QUICUI-PATCH] Add AOT Code Push support"
#              "feat(ios-engine): Add QuicUI code push snapshot loading"
```

---

## 📞 Support

- **GitHub Issues**: https://github.com/Ikolvi/QuicUICodepush/issues
- **Documentation**: https://github.com/Ikolvi/QuicUICodepush/tree/main/docs
- **QuicUI Flutter SDK Fork**: https://github.com/Ikolvi/QuicUIFlutterSDK

---

## 📄 License

QuicUI Code Push is licensed under MIT License.
Flutter is licensed under BSD 3-Clause License.

---

**Generated**: November 2, 2025  
**Patch Version**: v1.0.0  
**Compatible Flutter Versions**: 3.24.0+  
**Platforms**: Android (ARM64, ARMv7), iOS (ARM64)
