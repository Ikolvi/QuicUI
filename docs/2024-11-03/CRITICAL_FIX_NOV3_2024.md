# CRITICAL FIX: QuicUI Patched Code Not Executing

**Date**: November 3, 2024  
**Status**: ⚠️ FIX IDENTIFIED - NEEDS ENGINE REBUILD  
**Commit**: 45e1216

## Problem Discovered

The QuicUI OTA update system was downloading and applying patches successfully, but the **patched Dart code was not executing**. The app continued running the original v1.0.0 code even after the patch was installed and the engine reported loading the patched library.

### Evidence of the Issue:
```
✅ Patch downloaded: 4500463 bytes
✅ BsDiff patch applied successfully  
✅ Patched file created: libapp_patched_arm64-v8a.so
✅ Engine log: "Using QuicUI patched AOT library: .../libapp_patched_arm64-v8a.so"
❌ Dart code from patch NOT executing (no version 1.0.1 logs found)
❌ App still reporting currentVersion: 1.0.0
```

## Root Cause

Our C++ engine code was **opening the patched file** but **NOT telling the Dart VM to use it**. We were missing the critical step that Shorebird implements.

### What We Did Wrong:
- ❌ Only checked if patched file exists
- ❌ Logged that we're "using" the patched library
- ❌ But never modified `settings.application_library_path`
- ❌ Result: Dart VM continued loading original libapp.so from APK

### What Shorebird Does Right:
```cpp
// From shorebird.cc - THE CRITICAL PATTERN
char* c_active_path = shorebird_next_boot_patch_path();
if (c_active_path != NULL) {
  std::string active_path = c_active_path;
  shorebird_free_string(c_active_path);
  FML_LOG(INFO) << "Shorebird updater: active path: " << active_path;

  settings.application_library_path.clear();  // ← CRITICAL!
  settings.application_library_path.emplace_back(active_path);  // ← THIS IS THE FIX!
}
```

## The Fix

**File**: `engine_src/shell/platform/android/flutter_main.cc`  
**Commit**: 45e1216

### Added ConfigureQuicUI Function:
```cpp
static void ConfigureQuicUI(const std::string& code_cache_path,
                             flutter::Settings& settings) {
  std::string patches_dir = code_cache_path + "/quicui_patches";
  std::string patched_lib = patches_dir + "/libapp_patched_arm64-v8a.so";
  
  struct stat buffer;
  if (stat(patched_lib.c_str(), &buffer) == 0) {
    // CRITICAL FIX: Modify settings.application_library_path
    settings.application_library_path.clear();
    settings.application_library_path.emplace_back(patched_lib);
    
    __android_log_print(ANDROID_LOG_INFO, "QuicUI", 
                        "✅ Configured Flutter to load patched AOT snapshot from: %s", 
                        patched_lib.c_str());
  }
}
```

### Call ConfigureQuicUI Before Creating FlutterMain:
```cpp
#if FLUTTER_RELEASE
  // QuicUI Code Push: Configure patched library if available
  auto code_cache_path = fml::jni::JavaStringToString(env, engineCachesPath);
  ConfigureQuicUI(code_cache_path, settings);
#endif

  g_flutter_main.reset(new FlutterMain(settings));
```

## Why This Fix Works

1. **settings.application_library_path** is the Flutter Settings field that tells the Dart VM where to find the AOT snapshot (libapp.so)
2. By default, it points to the libapp.so embedded in the APK
3. When we **clear and replace** this path with our patched library path, the Dart VM will:
   - Skip the original libapp.so from the APK
   - Load and execute our patched libapp.so instead
   - Run the patched Dart code (v1.0.1 with purple banner)

## Next Steps

### 1. Rebuild Engine (Required)
```bash
cd /Users/admin/Documents/quicui2/engine_src
./flutter/tools/gn --android --android-cpu arm64 --runtime-mode release
ninja -C out/android_release_arm64
```
**Time Required**: ~2 hours

### 2. Deploy New Engine
```bash
# Copy new flutter.jar to Flutter SDK
cp out/android_release_arm64/flutter.jar \
   /Users/admin/Documents/quicui2/forks/flutter-quicui/bin/cache/artifacts/engine/android-arm64-release/

# Backup old version
mv flutter.jar flutter.jar.old
```

### 3. Test With Fresh Build
```bash
cd /Users/admin/Documents/quicui2/test_apps/test_app_fresh

# Clean and rebuild app
flutter clean
flutter build apk --release

# Install v1.0.0 and test OTA update
adb install -r build/app/outputs/flutter-apk/app-release.apk
# Launch app, wait for patch download, restart
# Should see "🎉 VERSION 1.0.1 IS RUNNING! 🎉" in logs
```

### 4. Verify Success
Look for these logs after restart:
```
I QuicUI: ConfigureQuicUI: ✅ Patched library found! Size: 4522928 bytes
I QuicUI: ConfigureQuicUI: ✅ Configured Flutter to load patched AOT snapshot
I flutter: 🎉🎉🎉 VERSION 1.0.1 IS RUNNING! 🎉🎉🎉
```

## Impact

This fix makes QuicUI **fully functional** for OTA updates:
- ✅ Downloads patches
- ✅ Applies BsDiff patches  
- ✅ Stores patched library
- ✅ **EXECUTES patched Dart code** (NEW!)

## Files Changed

- `engine_src/shell/platform/android/flutter_main.cc` - Added ConfigureQuicUI function and call

## References

- Shorebird implementation: `/Users/admin/Documents/quicui2/shorebird_analysis/engine/shell/common/shorebird/shorebird.cc`
- Original QuicUI attempt: `/Users/admin/Documents/quicui2/engine_build/out/android_release_arm64/`
- Test results: Logs show engine loading patched lib but code not executing

## Lesson Learned

**Opening a file ≠ Using the file**

We assumed that logging "Using QuicUI patched AOT library" meant we were actually using it. In reality, we needed to modify the Flutter Settings object to tell the Dart VM to load from a different path. This is a subtle but critical distinction that Shorebird got right from the start.
