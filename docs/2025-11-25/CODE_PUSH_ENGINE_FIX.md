# QuicUI Code Push Engine Fix

**Date:** November 25, 2025  
**Status:** 🔴 CRITICAL - Patches download but don't execute  
**Issue:** Visual changes don't appear after patch installation

## Problem Summary

The QuicUI code push system successfully:
- ✅ Downloads patches from Supabase
- ✅ Decompresses XZ-compressed patches
- ✅ Applies BsDiff patches using native code
- ✅ Installs patched library to `/data/data/.../code_cache/quicui_patches/libapp_patched_arm64-v8a.so`
- ✅ Logs confirm patched library is "loaded"

**BUT:** Visual changes from patches don't appear in the running app.

## Root Cause

The Flutter engine is loading the **original libapp.so from the APK** instead of the **patched libapp.so** from code_cache.

### Why This Happens

The code push system has two components:

1. **QuicUI Code Push Client** (Dart + Kotlin)
   - Downloads patches ✅
   - Decompresses patches ✅
   - Applies patches ✅
   - Installs to code_cache ✅
   - Status: **WORKING**

2. **Flutter Engine Loader** (FlutterLoader.java + JNI)
   - Determines which libapp.so to load at startup
   - Passes path to native engine via `--aot-shared-library-name` flag
   - Status: **NOT MODIFIED** - Always loads from APK

## Solution

The Flutter engine's `FlutterLoader.java` must be modified to **check for patched libraries** before loading the default library from the APK.

### Required Modification

**File:** `engine/src/flutter/shell/platform/android/io/flutter/embedding/engine/loader/FlutterLoader.java`

**Location:** In the `ensureInitializationComplete()` method, in the AOT section (after line 350)

**Before:**
```java
} else {
  // Add default AOT shared library name arg.
  shellArgs.add(aotSharedLibraryNameFlag + flutterApplicationInfo.aotSharedLibraryName);

  // Some devices cannot load the an AOT shared library based on the library name
  // with no directory path. So, we provide a fully qualified path to the default library
  // as a workaround for devices where that fails.
  shellArgs.add(
      aotSharedLibraryNameFlag
          + flutterApplicationInfo.nativeLibraryDir
          + File.separator
          + flutterApplicationInfo.aotSharedLibraryName);
}
```

**After:**
```java
} else {
  // QuicUI Code Push: Check for patched AOT library
  String patchedLibPath = null;
  String codeCachePath = applicationContext.getCodeCacheDir().getAbsolutePath();
  String[] architectures = {"arm64-v8a", "armeabi-v7a", "x86_64", "x86"};
  
  for (String arch : architectures) {
    String candidatePath = codeCachePath + File.separator + "quicui_patches" + 
                           File.separator + "libapp_patched_" + arch + ".so";
    File candidateFile = new File(candidatePath);
    if (candidateFile.exists()) {
      patchedLibPath = candidatePath;
      Log.i(TAG, "QuicUI: Found patched AOT library at: " + patchedLibPath);
      break;
    }
  }

  if (patchedLibPath != null) {
    // Use the patched library
    shellArgs.add(aotSharedLibraryNameFlag + patchedLibPath);
    Log.i(TAG, "QuicUI: Using patched AOT library");
  } else {
    // Use the default library from APK
    // Add default AOT shared library name arg.
    shellArgs.add(aotSharedLibraryNameFlag + flutterApplicationInfo.aotSharedLibraryName);

    // Some devices cannot load the an AOT shared library based on the library name
    // with no directory path. So, we provide a fully qualified path to the default library
    // as a workaround for devices where that fails.
    shellArgs.add(
        aotSharedLibraryNameFlag
            + flutterApplicationInfo.nativeLibraryDir
            + File.separator
            + flutterApplicationInfo.aotSharedLibraryName);
  }
}
```

### How It Works

1. **On app startup**, FlutterLoader.java runs `ensureInitializationComplete()`
2. **Check for patches**: Loop through architectures and check if patched library exists:
   ```
   /data/data/com.example.app/code_cache/quicui_patches/libapp_patched_arm64-v8a.so
   ```
3. **If patch exists**: Pass patched path to engine: `--aot-shared-library-name=/path/to/patched.so`
4. **If no patch**: Use default from APK: `--aot-shared-library-name=libapp.so`
5. **Native engine** loads the specified library and executes the Dart code

## Implementation Steps

### Step 1: Locate the Built Engine

The QuicUI CLI uses a pre-built engine at:
```
/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/out/android_release_arm64/
```

The source that needs modification is at:
```
/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/shell/platform/android/io/flutter/embedding/engine/loader/FlutterLoader.java
```

### Step 2: Apply the Modification

Edit the FlutterLoader.java file at the built engine location (not in `forks/flutter-quicui`).

### Step 3: Rebuild the Android Engine

```bash
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src

# Build Android engine
ninja -C out/android_release_arm64

# Verify flutter.jar is updated
ls -lh out/android_release_arm64/flutter.jar
```

This compiles the modified Java code into `flutter.jar`.

### Step 4: Build New Baseline APK

Use the QuicUI CLI to build a new baseline with the modified engine:

```bash
cd test_apps/quicui_production_test

# Update version in pubspec.yaml to 2.0.9 (new baseline)
# Update version in main.dart to 2.0.9

# Build baseline
quicui build-apk --version 2.0.9 --baseline
```

The CLI will use `--local-engine=android_release_arm64` which points to the rebuilt engine.

### Step 5: Test the Fix

1. **Install new baseline APK** (v2.0.9) on device
2. **Create a new patch** (e.g., v2.0.10 with different colors)
3. **Upload the patch** to Supabase
4. **Open the app** and wait for patch download
5. **Restart the app**
6. **Verify visual changes appear** 🎉

## Verification

### Expected Logs

After applying the fix, you should see these logs on app startup:

```
I/FlutterLoader: QuicUI: Found patched AOT library at: /data/data/.../code_cache/quicui_patches/libapp_patched_arm64-v8a.so
I/FlutterLoader: QuicUI: Using patched AOT library
```

Or if no patch is installed:
```
I/FlutterLoader: ensureInitializationComplete (using default libapp.so from APK)
```

### Testing Checklist

- [ ] Engine modification applied to correct file
- [ ] Engine rebuilt with `ninja -C out/android_release_arm64`
- [ ] New baseline APK built with modified engine
- [ ] Baseline installed and runs correctly
- [ ] Patch generated and uploaded
- [ ] App downloads patch successfully
- [ ] After restart, logs show "Using patched AOT library"
- [ ] **Visual changes from patch are visible in UI**

## Technical Details

### Architecture Support

The modification checks all supported architectures in priority order:
1. `arm64-v8a` (64-bit ARM - most common)
2. `armeabi-v7a` (32-bit ARM - older devices)
3. `x86_64` (64-bit Intel - rare)
4. `x86` (32-bit Intel - emulators)

### Path Structure

```
/data/data/com.example.app/
├── cache/                          # Regular cache
├── code_cache/                     # Code cache (our patches)
│   └── quicui_patches/
│       ├── libapp_patched_arm64-v8a.so      # Patched library
│       └── libapp_patched_arm64-v8a.so.meta # Metadata (hash, version)
└── lib/                            # APK native libraries
    └── arm64-v8a/
        └── libapp.so               # Original (baseline)
```

### JNI Bridge Flow

```
FlutterLoader.java (Java)
    ↓ shellArgs.add("--aot-shared-library-name=/path/to/lib.so")
    ↓
FlutterJNI.init() (Java → Native)
    ↓
flutter_main.cc::Init() (C++)
    ↓
SettingsFromCommandLine() (C++)
    ↓ settings.application_library_path = ["/path/to/lib.so"]
    ↓
DartSnapshot::VMSnapshotFromSettings() (C++)
    ↓ Loads ELF library and maps AOT snapshots
    ↓
DartVM executes compiled Dart code
```

## Comparison with Shorebird

Shorebird solves this problem differently:

**Shorebird Approach:**
- Custom C++ code in `shorebird.cc`
- Calls `shorebird_next_boot_patch_path()` from Rust updater library
- Modifies `settings.application_library_path` directly in C++
- Requires deep engine modifications and Rust integration

**QuicUI Approach:**
- Simple Java modification in FlutterLoader.java
- Checks filesystem for patch presence
- Passes path via existing `--aot-shared-library-name` flag
- Minimal engine changes, no Rust dependencies

## Alternative Solutions Considered

### ❌ Runtime Library Loading
**Idea:** Load patched library at runtime after app starts  
**Problem:** Dart VM already initialized with original library. Can't hot-swap native code.

### ❌ Custom Native Loader
**Idea:** Write custom JNI to replace default loader  
**Problem:** Complex, fragile, requires deep engine knowledge

### ❌ Modify APK After Installation
**Idea:** Replace libapp.so in installed APK  
**Problem:** Android security prevents modifying installed apps

### ✅ FlutterLoader Modification (Chosen)
**Why:** Simple, clean, uses existing engine mechanisms, minimal changes

## Current Status

- [x] Problem identified and documented
- [x] Solution designed and tested (in source)
- [ ] **Modification applied to BUILT engine** ← YOU ARE HERE
- [ ] Engine rebuilt with modifications
- [ ] New baseline APK created with modified engine
- [ ] Patch system tested end-to-end
- [ ] Visual changes verified

## Next Actions

1. **IMMEDIATE**: Apply modification to `/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/shell/platform/android/io/flutter/embedding/engine/loader/FlutterLoader.java`

2. **BUILD**: Run `ninja -C out/android_release_arm64` to rebuild engine

3. **TEST**: Create new baseline v2.0.9 and test patch system

4. **DOCUMENT**: Update deployment guide with working patch flow

## Related Files

- **This Fix**: `engine/src/flutter/shell/platform/android/io/flutter/embedding/engine/loader/FlutterLoader.java`
- **Patch Client**: `packages/quicui_code_push_client/lib/src/quicui_code_push.dart`
- **Patch Installer**: `packages/quicui_code_push_client/android/src/main/kotlin/com/quicui/codepush/CodePushMethodHandler.kt`
- **CLI**: `packages/quicui_cli/lib/src/services/flutter_service.dart`
- **Backend**: Supabase Edge Functions

## References

- [Shorebird Engine Implementation](../../shorebird_engine/shell/common/shorebird/shorebird.cc)
- [Flutter Engine Architecture](../../engine_src/shell/README.md)
- [QuicUI CLI Documentation](../../packages/quicui_cli/README.md)
- [Code Push Client Documentation](../../packages/quicui_code_push_client/README.md)

---

**Last Updated:** November 25, 2025  
**Author:** QuicUI Development Team  
**Status:** 🔴 Critical Fix Required
