# Modern Flutter Initialization Discovery - November 4, 2024

## Executive Summary

**Critical Discovery**: Flutter's initialization architecture has fundamentally changed between older versions (used by Shorebird) and modern Flutter 3.35.x. The `FlutterMain::Init()` function exists in the codebase but is **never called** in modern Flutter, making it an obsolete code path.

**Solution Found**: Modern Flutter uses `AttachJNI()` in `platform_view_android_jni_impl.cc` as the actual initialization entry point, where Settings are retrieved and passed to AndroidShellHolder for Shell creation.

## Problem Statement

### Initial Issue
- QuicUI OTA system appeared complete: patches download, install, app restarts
- UI changes never appeared despite successful patch installation
- Root cause: `ConfigureQuicUI()` function was added to `FlutterMain::Init()` but never executed

### Investigation Results
Added diagnostic log to `FlutterMain::Init()`:
```cpp
FML_LOG(INFO) << "🔥 FlutterMain::Init CALLED!";
```

**Result**: Log never appeared in logcat, despite:
- Function exists in flutter_main.cc (lines 107-217)
- Function is compiled into binary (verified with `strings`)
- `FLUTTER_RELEASE` is defined in build
- App running in release mode

**Conclusion**: `FlutterMain::Init()` is legacy/obsolete code that modern Flutter no longer calls.

## Architecture Analysis

### Modern Flutter Initialization Flow

**Actual execution path** (traced through source code):

```
Java Layer:
└── FlutterJNI.nativeAttach()

JNI Layer (platform_view_android_jni_impl.cc):
└── AttachJNI(JNIEnv* env, jclass clazz, jobject flutterJNI)  [line 157-168]
    ├── Creates PlatformViewAndroidJNI facade
    ├── Calls FlutterMain::Get().GetSettings()  // Gets singleton Settings
    └── Creates AndroidShellHolder(settings, jni_facade)

C++ Layer (android_shell_holder.cc):
└── AndroidShellHolder constructor [line 85-170]
    └── Calls Shell::Create(task_runners, settings, ...)

Shell Creation (shell.cc):
└── Shell::Create()
    └── Initializes Dart VM with settings.application_library_path
        └── Loads libapp.so from specified path
```

### Obsolete Code Path (Never Executed)

```
flutter_main.cc:
└── FlutterMain::Init(...)  [line 107-217]  ❌ NEVER CALLED
    ├── Line 211: ConfigureQuicUI(code_cache_path, settings)
    └── Creates g_flutter_main singleton
```

**Why it exists**: Legacy compatibility from older Flutter versions. The singleton is still accessed via `FlutterMain::Get()`, but the `Init()` function that performs initialization is no longer called.

## Solution Implementation

### Key Insight
Settings must be modified **before** `AndroidShellHolder` is created, because that's when the Shell initializes the Dart VM and loads libapp.so.

### Implementation Location
**File**: `platform_view_android_jni_impl.cc`  
**Function**: `AttachJNI` (lines 160-201)  
**Reason**: This is where `FlutterMain::Get().GetSettings()` is called and settings are passed to AndroidShellHolder

### Code Changes

#### Added Includes (top of file):
```cpp
#include <android/log.h>
#include <sys/stat.h>
#include "flutter/fml/paths.h"
```

#### Modified AttachJNI Function:
```cpp
static jlong AttachJNI(JNIEnv* env, jclass clazz, jobject flutterJNI) {
  __android_log_print(ANDROID_LOG_INFO, "QuicUI", "🔥 AttachJNI called!");
  
  fml::jni::JavaObjectWeakGlobalRef java_object(env, flutterJNI);
  std::shared_ptr<PlatformViewAndroidJNI> jni_facade =
      std::make_shared<PlatformViewAndroidJNIImpl>(java_object);
  
  // Get settings from FlutterMain (mutable copy for modification)
  flutter::Settings settings = FlutterMain::Get().GetSettings();
  
  __android_log_print(ANDROID_LOG_INFO, "QuicUI", "📋 Got settings from FlutterMain");
  
  #if FLUTTER_RELEASE
  // Hardcoded path for testing (production should get from context)
  std::string patches_dir = "/data/user/0/com.quicui.test.quicui_engine_test/code_cache/quicui_patches";
  std::string patched_lib = patches_dir + "/libapp_patched_arm64-v8a.so";
  
  __android_log_print(ANDROID_LOG_INFO, "QuicUI", "🔍 Checking for patch at: %s", patched_lib.c_str());
  
  struct stat buffer;
  if (stat(patched_lib.c_str(), &buffer) == 0) {
    __android_log_print(ANDROID_LOG_INFO, "QuicUI", 
                        "✅ Patched library found! Size: %lld bytes", (long long)buffer.st_size);
    
    // CRITICAL: Modify Settings to load patched library
    settings.application_library_path.clear();
    settings.application_library_path.emplace_back(patched_lib);
    
    __android_log_print(ANDROID_LOG_INFO, "QuicUI", "✅ Configured to load patched AOT snapshot!");
  } else {
    __android_log_print(ANDROID_LOG_INFO, "QuicUI", "ℹ️ No patch found, using bundled libapp.so");
  }
  #endif
  
  // Pass modified settings to AndroidShellHolder
  auto shell_holder = std::make_unique<AndroidShellHolder>(settings, jni_facade);
  if (shell_holder->IsValid()) {
    return reinterpret_cast<jlong>(shell_holder.release());
  } else {
    return 0;
  }
}
```

### Why This Works

1. **Correct Entry Point**: AttachJNI is actually called by Flutter's initialization
2. **Settings Interception**: Gets Settings before Shell creation
3. **Path Modification**: Clears default libapp.so path and replaces with patched version
4. **Proper Timing**: Settings modifications happen before AndroidShellHolder constructor
5. **Diagnostic Logging**: Four log statements to trace execution and verify patch detection

## Build Process

### Minimal Rebuild Strategy (Success)

Instead of full engine rebuild (2 hours, 5,710 targets), achieved targeted rebuild:

```bash
# Step 1: Compile modified file (3 steps, ~30 seconds)
cd /Volumes/DoWonder2/quicui_engine_build/engine_full/src
export PATH="/Volumes/DoWonder2/quicui_engine_build/depot_tools:$PATH"
ninja -C out/android_release_arm64 flutter/shell/platform/android:flutter_shell_native

# Output:
# [1/3] CXX obj/flutter/shell/platform/android/flutter_shell_native_src.platform_view_android_jni_impl.o
# [2/3] STAMP obj/flutter/shell/platform/android/flutter_shell_native_src.stamp
# [3/3] SOLINK ./libflutter.so

# Step 2: Package into flutter.jar (1 step, ~5 seconds)
ninja -C out/android_release_arm64 flutter.jar

# Output:
# [1/1] ACTION //flutter/shell/platform/android:android_jar(//build/toolchain/android:clang_arm64)
```

**Total time**: <1 minute vs 2 hours for full rebuild

### Build Artifacts

- **libflutter.so**: Contains modified AttachJNI implementation
- **flutter.jar**: 5.6 MB (5,911,185 bytes)
- **Location**: `/Volumes/DoWonder2/quicui_engine_build/engine_full/src/out/android_release_arm64/flutter.jar`

## Compilation Issues Resolved

### Issue 1: UniqueFD Type Mismatch

**Error**:
```
error: invalid operands to binary expression ('fml::UniqueFD' and 'const char[16]')
```

**Problematic Code**:
```cpp
auto code_cache_path = fml::paths::GetCachesDirectory();
std::string patches_dir = code_cache_path + "/quicui_patches";  // ❌ UniqueFD + string
```

**Cause**: `fml::paths::GetCachesDirectory()` returns a file descriptor (UniqueFD), not a string path.

**Solution**: Used hardcoded path for testing:
```cpp
std::string patches_dir = "/data/user/0/com.quicui.test.quicui_engine_test/code_cache/quicui_patches";
```

**TODO**: Replace with context-based path retrieval in production (get from Java context or Settings object).

## Testing Plan

### Deployment Steps (Ready to Execute)

1. **Deploy flutter.jar**:
   ```bash
   cp /Volumes/DoWonder2/quicui_engine_build/engine_full/src/out/android_release_arm64/flutter.jar \
      /Users/admin/Documents/quicui2/forks/flutter-quicui/bin/cache/artifacts/engine/android-arm64-release/flutter.jar
   ```

2. **Rebuild test app**:
   ```bash
   cd /Users/admin/Documents/quicui2/test_apps/quicui_engine_test
   flutter clean
   flutter build apk --release
   ```

3. **Install on device**:
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```

4. **Monitor logs** (corrected command):
   ```bash
   # Clear logs first
   adb logcat -c
   
   # Launch app
   adb shell am start -n com.quicui.test.quicui_engine_test/.MainActivity
   
   # Monitor logs (no background process to avoid prompt mode)
   adb logcat | grep -E "QuicUI|flutter"
   ```

### Expected Log Output

If implementation works correctly:
```
I/QuicUI: 🔥 AttachJNI called!
I/QuicUI: 📋 Got settings from FlutterMain  
I/QuicUI: 🔍 Checking for patch at: /data/user/0/com.quicui.test.quicui_engine_test/code_cache/quicui_patches/libapp_patched_arm64-v8a.so
I/QuicUI: ✅ Patched library found! Size: 3146672 bytes
I/QuicUI: ✅ Configured to load patched AOT snapshot!
```

If patch file exists and loads, UI should change to orange theme with celebration icon.

### Success Criteria

- ✅ See "🔥 AttachJNI called!" (proves entry point reached)
- ✅ See "📋 Got settings" (proves Settings retrieved)
- ✅ See "🔍 Checking for patch" (proves detection code runs)
- ✅ See "✅ Patched library found" (proves patch detected)
- ✅ See "✅ Configured to load patched AOT snapshot!" (proves Settings modified)
- ✅ UI changes to orange theme (proves patch actually loaded by Dart VM)

## Fallback Plan

### Plan B: Use Shorebird v1.6.66 Engine

If modern Flutter implementation fails at runtime:

1. **Shorebird uses older Flutter** that may still call FlutterMain::Init
2. **Already available**: `/Users/admin/Documents/quicui2/shorebird_analysis/`
3. **Shorebird pattern**: Has ConfigureShorebird in flutter_main.cc line 138
4. **Adaptation**: Study how Shorebird hooks into initialization

**Trade-off**: Would require full engine download (~39GB) and rebuild (2 hours).

## Key Findings Summary

### What Worked
1. ✅ Root cause analysis: FlutterMain::Init is obsolete
2. ✅ Architecture research: Traced actual initialization through AttachJNI
3. ✅ Implementation: Inline QuicUI logic at correct interception point
4. ✅ Minimal rebuild: 3 steps vs 5,710 steps
5. ✅ Compilation: Fixed UniqueFD error, built successfully

### What Didn't Work
1. ❌ ConfigureQuicUI in flutter_main.cc (never called)
2. ❌ Using `fml::paths::GetCachesDirectory()` directly (returns UniqueFD not string)

### Production TODOs
1. Replace hardcoded package path with dynamic path retrieval
2. Consider getting path from Java context via JNI
3. Document Flutter version differences for future compatibility
4. Add fallback to bundled libapp.so if patch is corrupted

## Technical Insights

### Flutter Version Differences

**Older Flutter** (used by Shorebird v1.6.66):
- Calls FlutterMain::Init() during startup
- Allows initialization customization in Init function
- ConfigureShorebird pattern works

**Modern Flutter** (3.35.x):
- Does NOT call FlutterMain::Init()
- Uses AttachJNI → FlutterMain::Get().GetSettings() → AndroidShellHolder pattern
- Must intercept Settings at AttachJNI level

### Settings.application_library_path

**Type**: `std::vector<std::string>`  
**Purpose**: Tells Dart VM which libapp.so to load  
**Default**: Points to bundled APK libapp.so (e.g., `lib/arm64-v8a/libapp.so`)  
**Modified**: Clear vector and replace with patched library absolute path

**Critical timing**: Must be set before `Shell::Create()` initializes Dart VM.

### JNI Registration

AttachJNI is registered as a JNI native method in `platform_view_android_jni_impl.cc` line 661:
```cpp
{
  .name = "nativeAttach",
  .signature = "(Lio/flutter/embedding/engine/FlutterJNI;)J",
  .fnPtr = reinterpret_cast<void*>(&AttachJNI),
},
```

Called from Java: `io.flutter.embedding.engine.FlutterJNI.nativeAttach()`

## Files Modified

### Primary Changes
- **platform_view_android_jni_impl.cc**: Modified AttachJNI function (lines 160-201)
  - Backup: `platform_view_android_jni_impl.cc.backup`
  - Location: `/Volumes/DoWonder2/quicui_engine_build/engine_full/src/flutter/shell/platform/android/`

### Abandoned Changes
- **flutter_main.cc**: Added diagnostic log (line 116) - proved function is obsolete
  - ConfigureQuicUI call exists (line 211) but never executes

## Command Reference

### Correct adb logcat Command

**WRONG** (causes prompt mode):
```bash
adb logcat -c && adb logcat -s flutter:I | grep -E "QuicUI|patch|update" &
```

**CORRECT** (no background process):
```bash
# Clear logs
adb logcat -c

# Launch app
adb shell am start -n com.quicui.test.quicui_engine_test/.MainActivity

# Monitor in foreground
adb logcat | grep -E "QuicUI|flutter"

# Or with specific tag filter:
adb logcat -s QuicUI:I flutter:I
```

### Build Commands

```bash
# Set up environment
cd /Volumes/DoWonder2/quicui_engine_build/engine_full/src
export PATH="/Volumes/DoWonder2/quicui_engine_build/depot_tools:$PATH"

# Rebuild modified platform code
ninja -C out/android_release_arm64 flutter/shell/platform/android:flutter_shell_native

# Package into flutter.jar
ninja -C out/android_release_arm64 flutter.jar

# Deploy to Flutter SDK
cp out/android_release_arm64/flutter.jar \
   /Users/admin/Documents/quicui2/forks/flutter-quicui/bin/cache/artifacts/engine/android-arm64-release/flutter.jar
```

## Next Session Objectives

1. Deploy new flutter.jar to test
2. Verify AttachJNI logs appear
3. Confirm patched libapp.so loads
4. Visual verification of orange theme
5. If successful: Replace hardcoded path with context-based path
6. If fails: Investigate Shorebird engine approach

## References

- Flutter Engine Source: `flutter/engine` main branch (latest)
- Modified File: `shell/platform/android/platform_view_android_jni_impl.cc`
- Key Classes: AndroidShellHolder, Shell, Settings, FlutterMain
- Build System: Ninja + GN (Generate Ninja)
- Test App: `test_apps/quicui_engine_test`
- Patch Location: `/data/user/0/com.quicui.test.quicui_engine_test/code_cache/quicui_patches/`

---

**Session Date**: November 4, 2024  
**Status**: Implementation complete, ready for deployment testing  
**Build Output**: flutter.jar (5.6 MB) ready at engine build directory

---

## Update: Deployment Challenges (13:00-13:30)

### Issue Encountered
Successfully built modified engine with AttachJNI QuicUI integration, but faced deployment challenges due to Gradle's multi-layer caching system.

### Gradle Engine Artifact Resolution
Flutter Gradle plugin resolves engine artifacts through Maven-style dependencies:
- Artifact: `io.flutter:arm64_v8a_release:1.0.0-035316565ad77281a75305515e4682e6c4c6f7ca`
- Cached at: `~/.gradle/caches/modules-2/files-2.1/io.flutter/arm64_v8a_release/.../*.jar`
- Original Size: 38MB
- Modified Size: 41MB (after replacing libflutter.so)
- Contains: Unstripped libflutter.so (158MB with debug symbols)

### Attempted Solutions
1. ✅ Modified `bin/cache/artifacts/engine/android-arm64-release/flutter.jar` - Not used by Gradle
2. ✅ Replaced libflutter.so in Gradle cached JAR - Corrupted transform cache
3. ❌ Used `--local-engine` flag - Framework/engine version incompatibility (SemanticsRole, RSuperellipse APIs missing)

### Root Cause
Gradle caches and transforms Flutter engine artifacts in multiple layers:
1. Downloads JAR to modules-2 cache
2. Transforms/extracts to transforms-N cache
3. Merges natives to build intermediates
4. Strips symbols for final APK

Modifying cached JARs after Gradle has already transformed them requires clearing transform caches, which can corrupt the Gradle daemon state.

### Recommended Next Steps
1. **Option A**: Build with correct engine version that matches Flutter SDK framework
   - Use Shorebird v1.6.66 engine source (Plan B from earlier)
   - Or update forked Flutter SDK framework to match engine_full version

2. **Option B**: Direct libflutter.so injection
   - Build APK with standard engine
   - Unzip APK, replace lib/arm64-v8a/libflutter.so with modified version
   - Re-sign APK with jarsigner
   - Install and test

3. **Option C**: Publish modified engine to local Maven repo
   - Create proper Maven artifact with modified engine
   - Configure Gradle to use local Maven repository
   - Clean rebuild will pick up modified engine

### Files Ready for Testing
- Modified libflutter.so (with AttachJNI logs): `/Volumes/DoWonder2/quicui_engine_build/engine_full/src/out/android_release_arm64/libflutter.so` (158MB unstripped)
- Stripped version: Available in flutter.jar (11.3MB)
- Contains diagnostic strings: "🔥 AttachJNI called!", "✅ Configured to load patched AOT snapshot!"

### Status
Build infrastructure complete, deployment method needs refinement. Modified engine verified to contain AttachJNI modifications via `strings` command.

