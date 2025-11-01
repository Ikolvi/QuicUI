# QuicUI Engine Code Push - Unified Patch

## 📦 Single Patch File for All Platforms

This repository includes a **unified patch file** that contains all QuicUI Code Push modifications for both Android and iOS:

**File**: `quicui-engine-codepush-v1.0.0.patch`  
**Size**: 70KB (2,175 lines)  
**Commits**: 4 sequential commits  
**Platforms**: Android + iOS  

---

## 🎯 What This Patch Does

Adds **Over-The-Air (OTA) code update capability** to Flutter apps by modifying the Flutter engine to:

1. **Check for patched AOT snapshots** before loading the default embedded snapshots
2. **Load patched code** if available (from code push server downloads)
3. **Fall back seamlessly** to the original app if no patch exists or if patch is corrupted
4. **Validate integrity** using SHA256 hashing at multiple layers

This enables **instant app updates without app store approval** for both Android and iOS.

---

## 📋 Patch Contents

### Commit 1/4: Android Code Push Support
- **Files Modified**: 4 files, +633 lines
- **FlutterLoader.java** - Modified engine loader to check for patched libapp.so
- **QuicUICodePushLoader.java** - New file for patch management (+280 lines)
- **codepush_loader.h/cc** - C++ bridge for native code push support (+357 lines)

**What it adds**:
- Platform channel: `dev.quicui.code_push`
- Methods: installPatch, hasPatch, clearPatch, restartApp
- Patch location: `/data/data/<pkg>/code_cache/quicui_patches/libapp_patched_<arch>.so`
- SHA256 validation with auto-fallback on corruption

### Commit 2/4: Migration Documentation
- **Files Added**: MIGRATION_GUIDE.md
- Complete instructions for applying patch to new Flutter versions
- Manual merge conflict resolution guides
- Verification scripts

### Commit 3/4: Version Detection
- **Files Modified**: flutter_version.dart, .quicui_marker
- Adds `isQuicUISDK` detection for runtime identification
- Critical for apps to detect if they're running on QuicUI fork

### Commit 4/4: iOS Code Push Support
- **Files Modified**: FlutterDartProject.mm (+38 lines)
- Checks `Documents/quicui_snapshots/isolate_snapshot_data.patched`
- Creates temporary framework bundle for patched snapshot
- Falls back to App.framework if no patch exists

---

## 🚀 How to Apply

### Quick Apply (Recommended)

```bash
# Clone Flutter SDK at your desired version
git clone https://github.com/flutter/flutter.git -b 3.27.0 my-flutter-quicui
cd my-flutter-quicui

# Apply the unified patch
git am /path/to/quicui-engine-codepush-v1.0.0.patch

# Verify it worked
./.quicui/verify_quicui_patch.sh
```

### Handling Conflicts

If `git am` reports conflicts:

```bash
# See what's conflicting
git am --show-current-patch

# Manually fix the conflicting files
# See MIGRATION_GUIDE.md for detailed instructions

# Continue after fixing
git add <fixed-files>
git am --continue
```

---

## ✅ Verification

After applying the patch, run:

```bash
bash .quicui/verify_quicui_patch.sh
```

Expected output:
```
Checking QuicUI SDK modifications...
✓ .quicui_marker file found
✓ QuicUI SDK marker found in flutter_version.dart
✓ Android code push support enabled (QuicUICodePushLoader.java)
✓ Android engine integration (FlutterLoader.java)
✓ iOS code push support enabled (FlutterDartProject.mm)
✓ C++ CodePush loader found
✅ All checks passed! This is a QuicUI-enabled Flutter SDK.
```

---

## 📁 Files Modified by Patch

| File Path | Platform | Type | Lines Changed |
|-----------|----------|------|---------------|
| `engine/.../FlutterLoader.java` | Android | Modified | +70 |
| `engine/.../QuicUICodePushLoader.java` | Android | New | +280 |
| `engine/.../codepush_loader.h` | Android | Modified | +55 |
| `engine/.../codepush_loader.cc` | Android | Modified | +302 |
| `engine/.../FlutterDartProject.mm` | iOS | Modified | +38 |
| `packages/flutter/lib/.../flutter_version.dart` | Both | Modified | +15 |
| `.quicui/MIGRATION_GUIDE.md` | Docs | New | +500 |
| `.quicui/verify_quicui_patch.sh` | Docs | New | +100 |

**Total**: 8 files, ~1,360 lines of changes

---

## 🔨 Building the Engine (Optional)

The patch modifies engine **source code**, so you'll need to build the engine to use the modifications.

### Do I Need to Build?

**You can skip building if**:
- Using pre-built QuicUI SDK from https://github.com/Ikolvi/QuicUIFlutterSDK
- Testing with QuicUI's hosted engine artifacts

**You need to build if**:
- Applying patch to a custom Flutter version
- Want to verify the patch on your own infrastructure
- Need to customize the code push behavior

### Android Engine Build

```bash
cd engine/src
python3 flutter/tools/gn --android --runtime-mode=release
ninja -C out/android_release  # Takes 30-60 minutes
```

### iOS Engine Build

```bash
cd engine/src
python3 flutter/tools/gn --ios --runtime-mode=release
ninja -C out/ios_release  # Takes 60-90 minutes
```

**Detailed instructions**: See [IOS_ENGINE_BUILD_GUIDE.md](IOS_ENGINE_BUILD_GUIDE.md)

---

## 🧪 Testing the Patch

### Create Test App

```bash
flutter create test_codepush
cd test_codepush
flutter pub add quicui_code_push_client
```

### Android Test

```bash
flutter build apk --release
flutter install --release
adb logcat | grep -i quicui
```

Expected log:
```
[QuicUICodePush] Checking for patched snapshot...
[QuicUICodePush] No patch found, using base snapshot
[QuicUICodePush] Initialized successfully
```

### iOS Test

```bash
flutter build ios --release
flutter install --release -d <device-id>
```

Check Xcode console for:
```
[QuicUICodePush] Checking Documents/quicui_snapshots/
[QuicUICodePush] No patched snapshot found, using base version
```

---

## 🔄 Updating to Newer Flutter Versions

When a new Flutter version is released:

1. **Clone new version**
   ```bash
   git clone https://github.com/flutter/flutter.git -b 3.30.0 flutter-3.30.0-quicui
   ```

2. **Apply patch**
   ```bash
   cd flutter-3.30.0-quicui
   git am /path/to/quicui-engine-codepush-v1.0.0.patch
   ```

3. **Handle conflicts** (if any)
   - See [MIGRATION_GUIDE.md](forks/flutter-official/.quicui/MIGRATION_GUIDE.md)
   - Use `git am --show-current-patch` to see what's conflicting
   - Manually merge following the guide's instructions

4. **Verify**
   ```bash
   ./.quicui/verify_quicui_patch.sh
   ```

---

## 📚 Documentation

- **[APPLY_ENGINE_PATCH.md](APPLY_ENGINE_PATCH.md)** - Complete patch application guide
- **[MIGRATION_GUIDE.md](forks/flutter-official/.quicui/MIGRATION_GUIDE.md)** - Manual merge instructions
- **[IOS_ENGINE_BUILD_GUIDE.md](IOS_ENGINE_BUILD_GUIDE.md)** - Detailed iOS build guide
- **[BSDIFF_IMPLEMENTATION.md](BSDIFF_IMPLEMENTATION.md)** - Binary diffing algorithm
- **[IOS_IMPLEMENTATION.md](IOS_IMPLEMENTATION.md)** - iOS architecture details

---

## 🎯 Use Cases

### Scenario 1: Security Hotfix
- Critical vulnerability discovered in production
- Apply patch via code push: **instant fix**
- Users get update on next app restart
- No app store review delay (1-7 days saved)

### Scenario 2: A/B Testing
- Test new feature with 10% of users
- Deploy via code push
- Measure metrics
- Roll back or expand based on results

### Scenario 3: Gradual Rollout
- Deploy to 5% → 20% → 50% → 100%
- Monitor crash rates at each stage
- Auto-rollback if metrics degrade

### Scenario 4: Emergency Rollback
- Bad release causing crashes
- Push previous version instantly
- Users auto-heal on restart
- Fix root cause without pressure

---

## ⚠️ Limitations

**What can be updated via code push**:
- ✅ Dart business logic
- ✅ UI widgets and layouts
- ✅ State management code
- ✅ API integrations
- ✅ Minor bug fixes

**What CANNOT be updated** (requires app store):
- ❌ Native dependencies (Java/Kotlin/Swift/Objective-C)
- ❌ Permissions (AndroidManifest.xml, Info.plist)
- ❌ Assets added/removed (images, fonts)
- ❌ Flutter engine version changes
- ❌ Major architectural refactors

---

## 🔐 Security

### Multi-Layer Validation

1. **Server-side**: Patch signed with private key
2. **Dart layer**: SHA256 hash verification before download
3. **Native layer**: Hash re-verification before installation
4. **Engine layer**: Implicit validation during snapshot loading

### Auto-Fallback

If patched snapshot is corrupted or incompatible:
- Engine automatically falls back to original embedded snapshot
- App continues working normally
- Corruption logged for monitoring

---

## 🤝 Contributing

To modify the patch:

1. Clone QuicUI Flutter SDK fork
2. Make changes to engine files
3. Commit with descriptive messages
4. Regenerate patch:
   ```bash
   git format-patch <base-commit>^..<final-commit> --stdout > quicui-engine-codepush-v1.0.0.patch
   ```
5. Test on multiple Flutter versions
6. Submit PR with updated patch

---

## 📞 Support

- **Issues**: https://github.com/Ikolvi/QuicUICodepush/issues
- **Docs**: https://github.com/Ikolvi/QuicUICodepush/tree/main/docs
- **Fork**: https://github.com/Ikolvi/QuicUIFlutterSDK

---

## 📄 License

MIT License - See LICENSE file for details

---

**Patch Version**: v1.0.0  
**Generated**: November 2, 2025  
**Compatible Flutter Versions**: 3.24.0 - 3.35.0+ (and future versions)  
**Platforms**: Android (ARMv7, ARM64, x86_64), iOS (ARM64)  
**Patch File Size**: 70KB  
**Total Code Changes**: ~1,360 lines
