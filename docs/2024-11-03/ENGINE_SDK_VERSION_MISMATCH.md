# Engine/SDK Version Mismatch Issue

**Date:** November 3, 2024  
**Status:** ⚠️ BLOCKED - Build failing due to API version mismatch

## Problem Summary

Successfully built Flutter engine with QuicUI modifications, but **cannot build test app** due to Flutter SDK/Engine version mismatch.

### What Happened

1. ✅ Built Android engine: `android_release_arm64` (flutter.jar 5.6MB, libflutter.so 158MB)
2. ✅ Built host engine: `host_release` (gen_snapshot 8.2MB, flutter_tester 40MB)
3. ❌ Test app build **FAILS** with hundreds of compilation errors

### Root Cause

**Engine has NEW APIs that Flutter SDK doesn't recognize:**
- `SemanticsRole` enum (new)
- `SemanticsInputType` enum (new)
- `SemanticsValidationResult` enum (new)  
- `RSuperellipse` class (new)
- `SystemColorPalette` class (new)

**Engine Version:** commit `cc9bcdd` (recent master)  
**Flutter SDK:** stable channel (3-4 months behind)

The engine we built is from **Flutter master/main** branch, which has newer dart:ui APIs. The stable Flutter SDK framework code tries to use these new APIs, but they don't exist in the engine's embedder.

## Error Examples

```dart
Error: 'SemanticsRole' isn't a type.
  final SemanticsRole semanticsRole;
        ^^^^^^^^^^^^^

Error: 'RSuperellipse' isn't a type.
  final CustomClipper<RSuperellipse>? clipper;
                      ^^^^^^^^^^^^^

Error: The method 'drawRSuperellipse' isn't defined for the class 'Canvas'.
```

## Solutions

### Option 1: Use Flutter Master/Main Channel ⭐ RECOMMENDED
**Time:** 10-15 minutes  
**Risk:** Low  
**Pros:** Quick, matches engine version  
**Cons:** Using unstable Flutter

```bash
# Install Flutter master via FVM
fvm install master
fvm use master

# Or install Flutter master directly
git clone https://github.com/flutter/flutter.git -b master ~/flutter_master
export PATH="$HOME/flutter_master/bin:$PATH"
flutter doctor

# Rebuild test app
cd test_apps/test_app_fresh
./build_with_local_engine.sh
```

### Option 2: Build Engine from Stable Version 
**Time:** 2-3 hours  
**Risk:** Medium  
**Pros:** Uses stable Flutter SDK  
**Cons:** Requires complete engine rebuild

```bash
# 1. Find stable Flutter's engine version
/Users/admin/fvm/versions/stable/bin/flutter --version -v
# Look for "Engine revision: XXXXX"

# 2. Checkout that engine version
cd /Volumes/DoWonder2/quicui_engine_build/engine_full/src
git checkout <engine-hash>
gclient sync

# 3. Re-apply QuicUI modifications
# Copy Rust updater, modify flutter_main.cc, etc.

# 4. Rebuild both engines (~2 hours)
./scripts/build_android_engine.sh
./scripts/build_host_engine.sh
```

### Option 3: Minimal Test Without New APIs
**Time:** 30 minutes  
**Risk:** High (may not compile)  
**Pros:** Tests core functionality  
**Cons:** Not a complete test

Create a minimal test app that doesn't use Material widgets (which use the new Semantics APIs).

## Recommended Next Steps

### Immediate (Now)
1. **Install Flutter master:** `fvm install master` (running in background)
2. **Update build script** to use master channel
3. **Rebuild test app** with matching SDK

### After Test App Builds
1. Install APK on device
2. Test OTA update flow
3. Verify ConfigureQuicUI is called
4. Check for purple banner after patch

### Long Term (After POC Success)
1. Pin to specific Flutter/engine versions
2. Document version compatibility matrix
3. Consider targeting stable channel
4. Automate version matching in CI/CD

## Current Build Status

| Component | Status | Version | Location |
|-----------|--------|---------|----------|
| **Android Engine** | ✅ Complete | arm64 | `out/android_release_arm64/` |
| **Host Engine** | ✅ Complete | host | `out/host_release/` |
| **Engine Commit** | ✅ Built | `cc9bcdd` | Shorebird fork |
| **Flutter SDK** | ❌ Mismatch | stable | FVM managed |
| **Test App** | ❌ Blocked | - | Cannot compile |

## Technical Details

### Engine Build Info
```
Location: /Volumes/DoWonder2/quicui_engine_build/engine_full/src
Commit: cc9bcdd
Branch: Follows Shorebird's engine fork
APIs: Includes dart:ui changes from Flutter 3.27+
```

### Flutter SDK Info  
```
Version: Stable (3.24.x likely)
Engine: Points to older stable engine
APIs: Expecting Flutter 3.24 dart:ui
```

### QuicUI Modifications
- ✅ Rust updater: `third_party/quicui_updater/` (9 files)
- ✅ C++ FFI: `flutter/shell/common/quicui/`
- ✅ Engine integration: `flutter_main.cc` ConfigureQuicUI()
- ✅ Cross-compilation: Android ARM64 working

## Files Modified

**Build Scripts:**
- `scripts/build_android_engine.sh`
- `scripts/build_host_engine.sh`
- `scripts/build_all.sh`
- `test_apps/test_app_fresh/build_with_local_engine.sh`

**Latest Change:**
```bash
# Changed from Flutter fork to standard SDK
export PATH="/Users/admin/flutter/bin:$PATH"  # Wrong version!
```

## Resolution Plan

1. ✅ Identify issue (API mismatch)
2. ⏳ Install Flutter master (in progress)
3. ⏳ Update build script PATH
4. ⏳ Rebuild test app
5. ⏳ Test on device
6. ⏳ Document working configuration

---

**Next Action:** Wait for `fvm install master` to complete, then update build script and retry.

**ETA:** 15-20 minutes total (10 min FVM install + 5 min app build)
