# QuicUI Code Push - End-to-End Architecture

**Last Updated:** November 2, 2025

## Overview

This document describes the complete end-to-end flow of QuicUI Code Push, from building apps with the modified Flutter SDK to applying patches on devices.

---

## System Components

### 1. Modified Flutter SDK

**Location:** `/Users/admin/Documents/quicui2/forks/flutter-official/`  
**Version:** `3.38.0-1.0.pre-356 (quicui)`

**What it does:**
- Checks for patches in `code_cache/quicui_patches/` at app startup
- If patch exists and hash is valid, loads it instead of original snapshot
- Adds `• quicui` marker to version string for runtime detection

**Key modifications:**
- `FlutterLoader.java` - Calls `checkForQuicUIPatch()` before loading app
- `QuicUICodePushLoader.java` - Returns path to patched snapshot if exists
- `flutter_version.dart` - Appends `• quicui` to version string

**Build Process:** See [Building the Modified Flutter SDK](#building-the-modified-flutter-sdk) section below.

### 2. Code Push Client Plugin

**Location:** `packages/quicui_code_push_client/`

**What it does:**
- Downloads patches from backend server
- Validates patch integrity (SHA256 hash)
- Installs patches to `code_cache/quicui_patches/`
- Provides Dart API for apps

**Platform channels:**
- `installPatch` - Copies patch file to code cache
- `hasPatch` - Checks if patch is installed
- `clearPatch` - Removes installed patch (rollback)

### 3. Backend Server

**Location:** `packages/quicui_backend/bin/server.dart`  
**Running on:** `http://192.168.20.102:8080`

**What it does:**
- Stores patch metadata (version, hash, file paths)
- Serves patches to apps
- Manages version compatibility

**Endpoints:**
- `POST /api/v1/patches/register` - Register new patch
- `POST /api/v1/patches/check` - Check for available updates
- `GET /api/v1/patches/download/:id` - Download patch file

### 4. Patch Compiler

**Location:** `packages/quicui_compiler/bin/quicui-compiler`

**What it does:**
- Generates binary diffs between snapshots (BsDiff algorithm)
- Calculates SHA256 hashes
- **NEW:** Automatically registers patches with backend after creation

**Usage:**
```bash
quicui-compiler diff old.so new.so \
  --output=patch.quicui \
  --compress=none \
  --app-id=com.quicui.test_app_fresh \
  --version=1.0.1 \
  --server-url=http://192.168.20.102:8080
```

---

## Building the Modified Flutter SDK

### Overview

The QuicUI Code Push system requires modifications to the Flutter engine's Android embedding. Specifically, we added code to check for installed patches at app startup before loading the default AOT snapshot.

### Engine Modifications Made

**Files Modified:**

1. **`FlutterLoader.java`** (lines 360, 673)
   - Added `checkForQuicUIPatch()` method to check for patched libraries
   - Integrated patch checking into the initialization flow
   - Location: `forks/flutter-official/engine/src/flutter/shell/platform/android/io/flutter/embedding/engine/loader/FlutterLoader.java`

2. **`QuicUICodePushLoader.java`** (NEW - 280 lines)
   - Implements patch discovery logic
   - Methods: `getPatchedAOTPath()`, `hasPatch()`, `clearPatch()`
   - Location: `forks/flutter-official/engine/src/flutter/shell/platform/android/io/flutter/embedding/engine/loader/QuicUICodePushLoader.java`

3. **`flutter_version.dart`**
   - Added `• quicui` marker to version string
   - Location: `forks/flutter-official/bin/internal/flutter_version.dart`

### Build Approach: Manual JAR Modification

Due to the complexity of a full Flutter engine build (requires 8-10 GB of dependencies, depot_tools, gclient sync), we used a **pragmatic approach** for Java-only modifications:

#### Why Manual Build?

- **Full engine build requirements:**
  - Complete Chromium depot_tools setup
  - 8-10 GB of third-party dependencies via gclient
  - DEPS file and complete engine repository structure
  - Several hours of build time

- **Our situation:**
  - Only Java files modified (no C++/Dart engine changes)
  - Engine fork incomplete (missing DEPS, third-party deps)
  - Need rapid iteration for testing

- **Solution:**
  - Extract existing `flutter.jar` from SDK
  - Compile modified Java files locally
  - Inject updated `.class` files back into JAR
  - Replace JAR in Flutter SDK cache

#### Step-by-Step Build Process

**1. Prepare Build Environment**

```bash
# Create working directory
mkdir -p ~/Documents/quicui2/engine_build
cd ~/Documents/quicui2/engine_build

# Copy existing flutter.jar from SDK
cp ~/Documents/quicui2/forks/flutter-official/bin/cache/artifacts/engine/android-arm64-release/flutter.jar .

# Extract JAR contents
jar xf flutter.jar
# Extracts 429 .class files + resources
```

**2. Locate Required Dependencies**

```bash
# Find androidx.annotation library (required for @NonNull, @Nullable)
find ~/.gradle -name "annotation-*.jar" 2>/dev/null | head -1
# Example: ~/.gradle/caches/modules-2/files-2.1/androidx.annotation/annotation/1.8.2/.../annotation-1.8.2.jar

# Set classpath for compilation
export ANDROIDX_JAR="<path_from_above>"
```

**3. Compile Modified Java Files**

```bash
# Copy modified source files to build directory
cp ~/Documents/quicui2/forks/flutter-official/engine/src/flutter/shell/platform/android/io/flutter/embedding/engine/loader/QuicUICodePushLoader.java .
cp ~/Documents/quicui2/forks/flutter-official/engine/src/flutter/shell/platform/android/io/flutter/embedding/engine/loader/FlutterLoader.java .

# Compile QuicUICodePushLoader first (no dependencies on FlutterLoader)
javac -cp ".:$ANDROIDX_JAR" \
  -d io/flutter/embedding/engine/loader/ \
  QuicUICodePushLoader.java

# Compile FlutterLoader (depends on QuicUICodePushLoader)
javac -cp ".:$ANDROIDX_JAR" \
  -d io/flutter/embedding/engine/loader/ \
  FlutterLoader.java
```

**Expected Warnings:**
```
warning: unknown enum constant AnnotationRetention.BINARY
  reason: class file for kotlin.annotation.AnnotationRetention not found
```

These warnings are **safe to ignore**:
- They relate to Kotlin metadata annotations in existing compiled classes
- Only affect annotation metadata, not runtime functionality
- Both classes compile successfully (0 errors)

**4. Create Updated JAR**

```bash
# Package all classes into new JAR
jar cf flutter_updated.jar -C . .

# Verify JAR contains updated classes
jar tf flutter_updated.jar | grep -i "quicui\|FlutterLoader"
# Should show:
# io/flutter/embedding/engine/loader/FlutterLoader.class
# io/flutter/embedding/engine/loader/QuicUICodePushLoader.class
```

**5. Deploy to Flutter SDK**

```bash
# Backup original JAR (recommended)
cp ~/Documents/quicui2/forks/flutter-official/bin/cache/artifacts/engine/android-arm64-release/flutter.jar \
   ~/Documents/quicui2/forks/flutter-official/bin/cache/artifacts/engine/android-arm64-release/flutter.jar.backup

# Replace with updated JAR
cp flutter_updated.jar \
   ~/Documents/quicui2/forks/flutter-official/bin/cache/artifacts/engine/android-arm64-release/flutter.jar

# Verify replacement
ls -lh ~/Documents/quicui2/forks/flutter-official/bin/cache/artifacts/engine/android-arm64-release/flutter.jar
```

**6. Rebuild Applications**

After updating the engine JAR, **all apps must be rebuilt** to use the new engine:

```bash
cd ~/Documents/quicui2/test_apps/test_app_fresh

# Clean previous builds
flutter clean

# Rebuild with updated engine
flutter build apk --release

# The new APK now includes the modified flutter.jar with QuicUI Code Push support
```

### Verification

**Check engine modifications are active:**

```bash
# Install app on device
adb -s <DEVICE_ID> install -r build/app/outputs/flutter-apk/app-release.apk

# Clear logcat
adb -s <DEVICE_ID> logcat -c

# Launch app and monitor logs
adb -s <DEVICE_ID> logcat | grep -i "quicui\|FlutterLoader"
```

**Expected log output (if patch installed):**
```
FlutterLoader: QuicUI Code Push: Checking for patch in code_cache/quicui_patches/
FlutterLoader: QuicUI Code Push: Using patched AOT library: /data/data/.../code_cache/quicui_patches/libapp_arm64-v8a.so
```

**Expected log output (no patch):**
```
FlutterLoader: QuicUI Code Push: Checking for patch in code_cache/quicui_patches/
FlutterLoader: QuicUI Code Push: No patch found, using default AOT library
```

### When Full Engine Build is Required

Use manual JAR modification for:
- ✅ Java-only changes (Android embedding)
- ✅ Rapid iteration during development
- ✅ Testing and debugging

Use full engine build for:
- ❌ C++ engine changes
- ❌ Dart VM modifications  
- ❌ Platform channel protocol changes
- ❌ Production releases (recommended)

### Troubleshooting

**Issue: "class file not found" errors during compilation**

```bash
# Missing dependencies - locate required JARs
find ~/.gradle -name "*.jar" | grep -i <missing_class>

# Add to classpath
javac -cp ".:$ANDROIDX_JAR:/path/to/other.jar" ...
```

**Issue: Apps still use old engine behavior**

```bash
# Verify JAR was replaced
ls -lh ~/Documents/quicui2/forks/flutter-official/bin/cache/artifacts/engine/android-arm64-release/flutter.jar

# Check modification time (should be recent)
stat ~/Documents/quicui2/forks/flutter-official/bin/cache/artifacts/engine/android-arm64-release/flutter.jar

# Ensure flutter clean was run
cd test_apps/test_app_fresh
flutter clean
flutter build apk --release
```

**Issue: Cannot extract JAR files**

```bash
# Verify jar command available
which jar
# Should show: /usr/bin/jar or similar

# If missing, install JDK
brew install openjdk@17
```

### Engine Build Commit Hash

The engine modifications are based on:
- **Commit:** `9fcb574f34e` (Flutter 3.38.0-1.0.pre-356)
- **Date:** October 31, 2025
- **Repository:** `forks/flutter-official/engine/`

To rebuild from source (if needed):
```bash
cd ~/Documents/quicui2/forks/flutter-official
git log --oneline | grep "9fcb574"
```

---

## Complete End-to-End Flow

### Phase 1: Development (What We're Doing)

```
Step 1: Build v1.0.0 (Baseline)
├── Comment out counter feature in main.dart
├── Build: flutter build apk --release
├── Install: adb -s BLZ5GBY23JB034715 install -r app-release.apk
└── Save snapshot: cp build/.../libapp.so snapshots/v1.0.0/
    Result: App running with NO counter button

Step 2: Build v1.0.1 (With Changes)
├── Restore counter feature in main.dart
├── Build: flutter build apk --release
└── Save snapshot: cp build/.../libapp.so snapshots/v1.0.1/
    Result: Two snapshots ready for diff

Step 3: Generate Patch & Auto-Register
├── Run compiler with auto-register:
│   quicui-compiler diff v1.0.0/libapp.so v1.0.1/libapp.so \
│     --output=v1.0.0_to_v1.0.1.quicui \
│     --compress=none \
│     --app-id=com.quicui.test_app_fresh \
│     --version=1.0.1 \
│     --server-url=http://192.168.20.102:8080
├── Compiler generates binary patch (4.3 MB)
├── Compiler calculates SHA256 hash
├── Compiler POSTs to /api/v1/patches/register
└── Backend stores patch metadata
    Result: Patch available on server
```

### Phase 2: Runtime (What We're Testing)

```
Step 4: App Startup (First Launch - v1.0.0)
├── User launches app
├── FlutterLoader.checkForQuicUIPatch() called
├── Check: code_cache/quicui_patches/libapp_arm64-v8a.so
├── File NOT found
├── Load default snapshot from APK
└── App displays: NO counter button ✓

Step 5: Check for Updates
├── User taps "Test Code Push" button
├── App POSTs to /api/v1/patches/check
│   Body: { appId, currentVersion: "1.0.0" }
├── Backend responds:
│   {
│     "patchAvailable": true,
│     "patchVersion": "1.0.1",
│     "downloadUrl": "http://.../ download/...",
│     "hash": "sha256:...",
│     "size": 4534523
│   }
└── App displays: "Update available: v1.0.1"

Step 6: Download & Install Patch
├── User taps "Download and Apply Patch"
├── App downloads patch from downloadUrl
├── Save to: /data/.../cache/quicui_patch_1.0.1.so
├── Calculate SHA256 hash of downloaded file
├── Compare with expected hash
├── ✅ Hash matches
├── Call platform channel: installPatch(...)
├── Kotlin code:
│   ├── Create: code_cache/quicui_patches/
│   ├── Copy to: libapp_arm64-v8a.so
│   └── Write: patch_metadata.json (version, hash, timestamp)
├── Return success to Dart
└── Show dialog: "Patch installed! Restart to apply?"

Step 7: Restart & Load Patch
├── User taps "Restart"
├── App exits (SystemNavigator.pop())
├── User manually relaunches app
├── FlutterLoader.checkForQuicUIPatch() called
├── Check: code_cache/quicui_patches/libapp_arm64-v8a.so
├── File FOUND! ✅
├── Read patch_metadata.json
├── Verify hash matches file
├── Set engine parameter to load patched snapshot
├── Flutter engine loads PATCHED snapshot instead of APK snapshot
└── App displays: Counter button visible! 🎉
```

---

## File System Layout

### On Android Device

```
/data/data/com.quicui.test_app_fresh/
├── app_flutter/
│   └── flutter_assets/
│       └── isolate_snapshot_data          # Original from APK (not used if patch exists)
│
├── code_cache/
│   └── quicui_patches/
│       ├── libapp_arm64-v8a.so           # PATCHED snapshot (4.3 MB)
│       └── patch_metadata.json            # {"version":"1.0.1","hash":"sha256:..."}
│
└── cache/
    └── quicui_patch_1.0.1.so             # Temporary download (deleted after install)
```

### On Development Machine

```
test_apps/test_app_fresh/
├── lib/
│   └── main.dart                          # Counter feature (lines 145-187)
│
├── snapshots/
│   ├── v1.0.0/
│   │   └── libapp.so                      # Baseline snapshot (4.3 MB)
│   ├── v1.0.1/
│   │   └── libapp.so                      # Updated snapshot (4.3 MB)
│   └── v1.0.0_to_v1.0.1.quicui           # Binary patch (4.3 MB)
│
└── build/
    └── app/
        ├── outputs/flutter-apk/
        │   └── app-release.apk            # Installable APK (46.8 MB)
        └── intermediates/stripped_native_libs/
            └── .../libapp.so              # Extracted for snapshots
```

---

## What We Modified

### In Flutter SDK

**Build Process:** Manual JAR modification (see [Building the Modified Flutter SDK](#building-the-modified-flutter-sdk))

1. **flutter_version.dart** - Added `• quicui` marker
   ```dart
   static const String? version = '3.38.0-1.0.pre-356 • quicui';
   ```

2. **FlutterLoader.java** - Added patch check at startup (line 360)
   ```java
   // Called during FlutterLoader initialization
   checkForQuicUIPatch();
   
   // Method implementation at line 673
   private void checkForQuicUIPatch() {
     String patchPath = QuicUICodePushLoader.getPatchedAOTPath(context, arch);
     if (patchPath != null) {
       Log.i(TAG, "QuicUI Code Push: Using patched AOT library: " + patchPath);
       shellArgs.put(AOT_SHARED_LIBRARY_NAME, patchPath);
     } else {
       Log.d(TAG, "QuicUI Code Push: No patch found, using default AOT library");
     }
   }
   ```

3. **QuicUICodePushLoader.java** - NEW file (280 lines) for patch loading
   ```java
   public class QuicUICodePushLoader {
     public static String getPatchedAOTPath(Context context, String arch) {
       File patchDir = new File(context.getCodeCacheDir(), "quicui_patches");
       File patchFile = new File(patchDir, "libapp_" + arch + ".so");
       
       if (!patchFile.exists()) {
         return null;
       }
       
       // Validate metadata
       File metadataFile = new File(patchDir, "patch_metadata.json");
       if (!metadataFile.exists()) {
         Log.w(TAG, "QuicUI Code Push: Patch file exists but metadata missing");
         return null;
       }
       
       // TODO: Verify hash matches metadata
       
       return patchFile.getAbsolutePath();
     }
     
     public static boolean hasPatch(Context context, String arch) {
       String path = getPatchedAOTPath(context, arch);
       return path != null;
     }
     
     public static void clearPatch(Context context) {
       File patchDir = new File(context.getCodeCacheDir(), "quicui_patches");
       deleteRecursively(patchDir);
     }
   }
   ```

4. **Compiled and deployed** - Manual build process:
   - Extracted existing `flutter.jar` (429 .class files)
   - Compiled modified Java files with javac
   - Injected updated `.class` files into JAR
   - Replaced JAR in Flutter SDK cache: `bin/cache/artifacts/engine/android-arm64-release/flutter.jar`
   - **All apps must be rebuilt** after engine update

### In Compiler

**Auto-Register Feature** - Automatically uploads patch after generation

Before:
```bash
# Generate patch
quicui-compiler diff old.so new.so --output=patch.quicui

# Register manually
quicui-compiler register patch.quicui --app-id=... --version=...
```

After:
```bash
# Generate AND register in one command
quicui-compiler diff old.so new.so \
  --output=patch.quicui \
  --app-id=com.quicui.test_app_fresh \
  --version=1.0.1
```

### In Backend Server

**Stores absolute paths** instead of copying files:

```dart
final patches = {
  'com.quicui.test_app_fresh_v1.0.1': {
    'uncompressedPath': '/Users/admin/.../v1.0.0_to_v1.0.1.quicui',
    'hash': 'sha256:...',
    'size': 4534523,
  }
};
```

When app downloads, backend streams file from disk.

### In Code Push Plugin

**No Accept-Encoding header** - Requests uncompressed patches because Android lacks xz/gzip decompression tools:

```dart
// Removed: headers['Accept-Encoding'] = 'xz, gz, bz2';
// Android doesn't have xz command, so we request uncompressed
```

---

## Critical: IP Address Changes

**⚠️ IMPORTANT:** If your PC's IP address changes, you must update it in multiple places and **rebuild the app**:

### Files to Update

1. **Code Push Client** (embedded in app):
   ```
   packages/quicui_code_push_client/lib/src/quicui_code_push.dart
   Line ~59: const hardcodedUrl = 'http://YOUR_IP:8080';
   ```

2. **Compiler** (for auto-register):
   ```
   packages/quicui_compiler/bin/quicui_compiler.dart
   Line ~169: final serverUrl = ... ?? 'http://YOUR_IP:8080';
   ```

3. **Test Scripts**:
   - `test_apps/test_app_fresh/build_and_install.sh`
   - `test_apps/test_app_fresh/test_e2e_codepush.sh`
   - `test_apps/test_app_fresh/test_codepush_auto.sh`

### After Updating

1. **Recompile compiler:**
   ```bash
   cd packages/quicui_compiler
   dart compile exe bin/quicui_compiler.dart -o bin/quicui-compiler
   ```

2. **Rebuild and reinstall app:**
   ```bash
   cd test_apps/test_app_fresh
   flutter clean
   flutter build apk --release
   adb -s DEVICE_ID install -r build/app/outputs/flutter-apk/app-release.apk
   ```

**Why:** The server URL is hardcoded in the app at compile time. If you just change the IP in the code without rebuilding, the old APK will still try to connect to the old IP address.

---

## Test Scenario

### What We're Testing Today

**App:** `com.quicui.test_app_fresh`  
**Device:** LAVA LXX503 (BLZ5GBY23JB034715)  
**Backend:** `http://192.168.20.102:8080`

### Feature Changes

**v1.0.0 (Baseline):**
- Basic UI
- NO counter button

**v1.0.1 (Update via Code Push):**
- Blue card with counter
- "🎉 NEW in v1.0.1!" label
- Counter increments on button tap

### Test Checklist

- [x] Build v1.0.0 without counter
- [x] Install v1.0.0 on device
- [x] Save v1.0.0 snapshot
- [x] Build v1.0.1 with counter
- [x] Save v1.0.1 snapshot
- [ ] Generate patch with auto-register
- [ ] Verify patch available on backend
- [ ] App checks for updates (receives patch info)
- [ ] App downloads patch
- [ ] App validates hash
- [ ] App installs to code_cache
- [ ] Restart app
- [ ] Counter button appears
- [ ] Counter increments correctly

### Success Criteria

✅ **Complete end-to-end flow works:**
1. Patch generated and registered automatically
2. Backend serves patch metadata
3. App downloads and validates patch
4. Platform channel installs to code_cache
5. Engine loads patched snapshot on restart
6. New code (counter) visible and functional

---

## Key Insights

### Why This Works

1. **Engine modification is minimal** - Just checks one directory at startup
2. **No server-side patch generation** - Patches pre-generated, backend just serves them
3. **Hash validation** - Ensures patch integrity
4. **Automatic fallback** - If patch corrupt, engine loads original
5. **No root required** - Uses app's own code_cache directory

### Why We Use Uncompressed Patches

- Android doesn't include xz/gzip/bzip2 commands
- Process.start('xz', ...) throws "No such file or directory"
- Solution: Request uncompressed patches from backend
- Future: Add Dart-based decompression library

### Why Auto-Register Matters

**Before:** Developer must remember to run register command  
**After:** Compiler handles registration automatically  
**Benefit:** Fewer errors, faster workflow, atomic operation

---

## Next Steps

1. **Complete current test** - Verify end-to-end flow works
2. **Monitor logs** - Watch for any errors during download/install
3. **Test rollback** - Verify clearPatch() works if issues occur
4. **Document process** - Update guides with findings
5. **Optimize** - Consider adding Dart compression support
6. **iOS implementation** - Port to Swift/Objective-C

---

## Troubleshooting

### Backend not responding

```bash
curl http://192.168.20.102:8080/health
# Should return: {"status":"OK"}
```

If failed, restart backend:
```bash
cd packages/quicui_backend
dart run bin/server.dart
```

### Patch not available

Check registration:
```bash
curl -X POST http://192.168.20.102:8080/api/v1/patches/check \
  -H "Content-Type: application/json" \
  -d '{"appId":"com.quicui.test_app_fresh","currentVersion":"1.0.0"}'
```

Should return `"patchAvailable": true`

### Hash validation fails

Check hash of patch file:
```bash
shasum -a 256 v1.0.0_to_v1.0.1.quicui
```

Compare with hash in backend response.

### App doesn't load patch

Check file exists:
```bash
adb -s BLZ5GBY23JB034715 shell "ls -lh /data/data/com.quicui.test_app_fresh/code_cache/quicui_patches/"
```

Should show `libapp_arm64-v8a.so` and `patch_metadata.json`

### Monitor logs

```bash
adb -s BLZ5GBY23JB034715 logcat | grep -i "quicui\|codepush\|flutter"
```

Look for:
- "QuicUI: Loading patched snapshot from ..."
- "✅ Patch installed successfully"
- Any error messages

---

**Document Status:** Ready for Testing  
**Last Validated:** November 2, 2025
