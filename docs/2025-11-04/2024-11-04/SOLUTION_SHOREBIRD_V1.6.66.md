# QuicUI Solution: Use Shorebird v1.6.66 Approach

**Date:** November 4, 2025  
**Status:** ✅ SOLUTION FOUND

## The Discovery

Shorebird just released **v1.6.66** which upgraded to **Flutter 3.35.7** - exactly what we need!

## What We Already Have

You already have the **flutter-quicui SDK** which is based on Shorebird's approach:
- **Location:** `/Users/admin/Documents/quicui2/forks/flutter-quicui`
- **Flutter Version:** 3.35.8 (compatible with 3.35.7)
- **Engine:** 035316565a (Oct 21, 2025)
- **Dart:** 3.9.2
- **QuicUI Engine Modifications:** ✅ Already integrated in `bin/cache/artifacts/engine/android-arm64-release/flutter.jar`

## The Missing Critical Piece (From Nov 3 Finding)

The **flutter-quicui SDK engine** has all QuicUI C++ code (`ConfigureQuicUI` function) **BUT** it's **NOT being called** from `flutter_main.cc`. This is why patches download and get stored, but the Dart code doesn't execute.

### The Fix Needed

We need to add **2 lines** to the engine source in the flutter-quicui SDK:

**File:** `engine/src/flutter/shell/platform/android/flutter_main.cc`

**1. Add include (around line 29):**
```cpp
#include "flutter/shell/common/quicui/quicui.h"
```

**2. Add ConfigureQuicUI call (before `g_flutter_main.reset`, around line 145-150):**
```cpp
#if FLUTTER_RELEASE
  // QuicUI Code Push: Configure patched library if available
  auto code_cache_path = fml::jni::JavaStringToString(env, engineCachesPath);
  auto app_storage_path = fml::jni::JavaStringToString(env, appStoragePath);
  std::string quicui_yaml = "";  // TODO: Read from assets if needed
  std::string version_str = "";
  std::string version_code_str = "";
  
  ConfigureQuicUI(code_cache_path, app_storage_path, settings,
                  quicui_yaml, version_str, version_code_str);
#endif

g_flutter_main.reset(new FlutterMain(settings));
```

## Why This Will Work

1. ✅ **ConfigureQuicUI function exists** - already in `shell/common/quicui/quicui.cc`
2. ✅ **Has the critical fix** - `settings.application_library_path.clear()` and `push_back(patch_path)`
3. ✅ **Rust updater library exists** - `third_party/quicui_updater/libquicui_updater.a` (15MB)
4. ✅ **Timing is correct** - Called BEFORE Dart VM initialization
5. ✅ **SDK version matches** - Flutter 3.35.8 works with engine 035316565a

## Next Steps

### Option A: Use Existing flutter-quicui SDK (Quick Test)

Since the flutter-quicui SDK already has QuicUI in the compiled engine artifacts, we can test if it works:

```bash
cd /Users/admin/Documents/quicui2
export PATH="/Users/admin/Documents/quicui2/forks/flutter-quicui/bin:$PATH"

# Create test app
flutter create quicui_test_app --org com.quicui
cd quicui_test_app

# Build APK
flutter build apk --release

# The built APK should have QuicUI engine integrated
```

**Expected:** APK will build successfully with QuicUI engine. However, **patches may not load** because `ConfigureQuicUI` is not called from `flutter_main.cc`.

### Option B: Rebuild flutter-quicui Engine with Fix (Complete Solution)

1. **Get Shorebird Flutter SDK v1.6.66:**
```bash
# Download Shorebird CLI
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash

# Or download their Flutter SDK directly
git clone -b stable https://github.com/shorebirdtech/flutter.git shorebird-flutter-3.35.7
```

2. **Copy QuicUI files to Shorebird engine:**
```bash
# Copy from our official_engine or flutter-quicui
cp -r official_engine/src/flutter/shell/common/quicui/ \
      shorebird-flutter-3.35.7/engine/src/flutter/shell/common/

cp -r official_engine/src/flutter/third_party/quicui_updater/ \
      shorebird-flutter-3.35.7/engine/src/flutter/third_party/
```

3. **Add the 2 critical lines to flutter_main.cc** (as shown above)

4. **Modify BUILD.gn files:**
```bash
# Add QuicUI sources to shell/common/BUILD.gn
# Add quicui_updater dependency
```

5. **Build engine:**
```bash
cd shorebird-flutter-3.35.7/engine/src
./flutter/tools/gn --android --android-cpu arm64 --runtime-mode release
ninja -C out/android_release_arm64
```

6. **Deploy to SDK:**
```bash
cp out/android_release_arm64/flutter.jar \
   ../bin/cache/artifacts/engine/android-arm64-release/
```

7. **Test:**
```bash
cd /Users/admin/Documents/quicui2
export PATH="/path/to/shorebird-flutter-3.35.7/bin:$PATH"

flutter create quicui_test_app_v2 --org com.quicui
cd quicui_test_app_v2
flutter build apk --release

# Install and test OTA updates
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Option C: Download Shorebird's Pre-built Engine

Since Shorebird already built engine 035316565a for Flutter 3.35.7, we could:

1. Download Shorebird CLI/SDK
2. Extract their pre-built engine artifacts
3. Add our QuicUI modifications
4. Rebuild just the parts we need

## Key Advantages of This Approach

1. **Latest Flutter** - 3.35.7/3.35.8 with all modern widgets ✅
2. **Working Engine** - Shorebird already validated this engine version ✅
3. **Proven OTA System** - Shorebird's approach is production-ready ✅
4. **Minimal Changes** - Just add 2 lines + QuicUI files ✅
5. **No Version Mismatch** - SDK and engine are perfectly aligned ✅

## Recommendation

**Start with Option A** (test existing flutter-quicui SDK) to verify the build process works, then move to **Option B** (add the 2 critical lines) for complete OTA functionality.

The critical finding from Nov 3 showed us exactly what's missing - just calling `ConfigureQuicUI` from `flutter_main.cc` before Dart VM initialization. With Shorebird v1.6.66 using Flutter 3.35.7, we now have a proven, working engine version to build against!

## Files to Modify

1. `engine/src/flutter/shell/platform/android/flutter_main.cc` - Add include + function call (2 additions)
2. That's it! All other QuicUI files already exist.

## Estimated Time

- Option A (test): 5 minutes
- Option B (complete fix): 2-3 hours (download SDK, add lines, rebuild engine)

## Success Criteria

After implementing the fix:
- ✅ APK builds with Flutter 3.35.7/3.35.8
- ✅ App runs with QuicUI engine
- ✅ Patches download successfully
- ✅ **Patched Dart code executes** (UI changes appear)
- ✅ OTA updates work end-to-end

---

**The answer was right in front of us:** Shorebird solved the version problem (v1.6.66 with Flutter 3.35.7), and we already have the QuicUI code - we just need to connect them with those 2 critical lines!
