# QuicUI Engine Patch Files

This directory contains the unified patch file and documentation for applying QuicUI Code Push modifications to any Flutter SDK version.

## 📦 Files in This Directory

### Core Patch File
- **`quicui-engine-codepush-v1.0.0.patch`** (70KB)
  - Single unified patch containing all Android + iOS modifications
  - Ready to apply with `git am`
  - 4 commits, 10 files, ~1,286 lines of changes

### Documentation
- **`APPLY_ENGINE_PATCH.md`** (9KB) - Step-by-step application guide
- **`README_PATCH.md`** (9KB) - Patch overview and use cases
- **`UNIFIED_PATCH_SUMMARY.md`** (8KB) - Complete summary of what was built
- **`IOS_ENGINE_BUILD_GUIDE.md`** (9KB) - iOS engine build instructions
- **`BSDIFF_IMPLEMENTATION.md`** (10KB) - Binary diff algorithm docs
- **`IOS_IMPLEMENTATION.md`** (16KB) - iOS architecture details

## 🚀 Quick Start

```bash
# 1. Clone Flutter SDK at your desired version
git clone https://github.com/flutter/flutter.git -b 3.27.0 my-flutter-sdk
cd my-flutter-sdk

# 2. Apply the patch
git am /path/to/quicui-engine-codepush-v1.0.0.patch

# 3. Verify
./.quicui/verify_quicui_patch.sh
```

## 📖 Which Guide Should I Read?

**If you want to...**

- **Apply the patch** → Read `APPLY_ENGINE_PATCH.md`
- **Understand what the patch does** → Read `README_PATCH.md`
- **Learn how we built this** → Read `UNIFIED_PATCH_SUMMARY.md`
- **Build iOS engine** → Read `IOS_ENGINE_BUILD_GUIDE.md`
- **Understand binary diffing** → Read `BSDIFF_IMPLEMENTATION.md`
- **Understand iOS architecture** → Read `IOS_IMPLEMENTATION.md`
- **Resolve merge conflicts** → Read `forks/flutter-official/.quicui/MIGRATION_GUIDE.md`

## ✅ What This Patch Does

Adds **Over-The-Air (OTA) code update capability** to Flutter apps:

### Android
- Checks for patched `libapp.so` in `/data/data/<pkg>/code_cache/quicui_patches/`
- Loads patched native library if exists
- Falls back to APK snapshot if no patch

### iOS
- Checks for patched snapshot in `Documents/quicui_snapshots/`
- Creates temporary framework bundle
- Falls back to App.framework if no patch

### SDK Detection
- Adds `isQuicUISDK` flag for runtime detection
- Critical for plugin initialization

## 📁 Files Modified by Patch

```
Android Engine:
  engine/.../FlutterLoader.java                (+70 lines)
  engine/.../QuicUICodePushLoader.java         (+280 lines, NEW)
  engine/.../codepush_loader.h                 (+55 lines)
  engine/.../codepush_loader.cc                (+302 lines)

iOS Engine:
  engine/.../FlutterDartProject.mm             (+38 lines)

Documentation:
  .quicui/MIGRATION_GUIDE.md                   (+500 lines, NEW)
  .quicui/VERSION_DETECTION.md                 (+200 lines, NEW)
  .quicui/README.md                            (+100 lines, NEW)
  .quicui/verify_quicui_patch.sh               (+100 lines, NEW)

Total: 10 files, ~1,286 lines of changes
```

## 🔧 Handling Conflicts

If `git am` fails with conflicts:

```bash
# See what's conflicting
git am --show-current-patch

# Fix conflicts manually (see MIGRATION_GUIDE.md)
git add <fixed-files>

# Continue applying remaining commits
git am --continue
```

Detailed conflict resolution: `forks/flutter-official/.quicui/MIGRATION_GUIDE.md`

## ✨ Key Benefits

- ✅ **Single command** to apply all changes
- ✅ **One file** to distribute (70KB)
- ✅ **Atomic** - all changes or none
- ✅ **Self-contained** - no remote repos needed
- ✅ **Version controlled** - easy to track
- ✅ **Auditable** - clear diff of all changes

## 🧪 Testing

After applying:

```bash
# Verify patch applied correctly
./.quicui/verify_quicui_patch.sh

# Create test app
flutter create test_app
cd test_app
flutter pub add quicui_code_push_client

# Build and test
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## 📞 Support

- **Issues**: https://github.com/Ikolvi/QuicUICodepush/issues
- **Docs**: https://github.com/Ikolvi/QuicUICodepush/tree/main/docs
- **Fork**: https://github.com/Ikolvi/QuicUIFlutterSDK

## 📄 License

MIT License - See LICENSE file for details

---

**Version**: v1.0.0  
**Created**: November 2, 2025  
**Compatible**: Flutter 3.24.0+  
**Platforms**: Android (ARMv7, ARM64, x86_64) + iOS (ARM64)
