# JNI Signature Mismatch Resolution

**Date:** November 4, 2025  
**Issue:** App crashing with "Failed to register native method FlutterJNI.nativeInit" signature mismatch

## Problem Discovery

After successfully rebuilding Flutter engine (ae5c3603) with AttachJNI modifications, app crashed on launch with:

```
Failed to register native method io.flutter.embedding.engine.FlutterJNI.nativeInit(
  Landroid/content/Context;
  [Ljava/lang/String;
  Ljava/lang/String;
  Ljava/lang/String;
  Ljava/lang/String;
  J
)V
```

The error indicated a **6-parameter** signature was expected, but libflutter.so provided a **7-parameter** signature.

## Root Cause Analysis

### Signature Evolution

**6-Parameter Signature** (older Flutter versions, e.g., stable 3.35.8):
```java
private static native void nativeInit(
    @NonNull Context context,
    @NonNull String[] args,
    @Nullable String bundlePath,
    @NonNull String appStoragePath,
    @NonNull String engineCachesPath,
    long initTimeMillis
);
```

**7-Parameter Signature** (newer engine builds, ae5c3603):
```java
private static native void nativeInit(
    @NonNull Context context,
    @NonNull String[] args,
    @Nullable String bundlePath,
    @NonNull String appStoragePath,
    @NonNull String engineCachesPath,
    long initTimeMillis,
    int apiLevel  // <-- NEW PARAMETER
);
```

### The Mismatch

1. **Custom Engine (libflutter.so):** Built from ae5c3603, expects 7 parameters
2. **SDK Embedding Classes (FlutterJNI.class):** From SDK 3.35.8-0.0.pre-2, provides 6 parameters
3. **Result:** JNI registration fails because signatures don't match

### Why This Happened

The custom SDK (`forks/flutter-quicui`) was cloned from an older stable version. When we:
- Rebuilt the engine with ae5c3603 (7-parameter version)
- Replaced only libflutter.so in flutter.jar
- **Kept the old FlutterJNI.class** (6-parameter version)

The app compiled successfully but crashed at runtime when JNI tried to register native methods.

## Failed Attempts

### 1. Replace Only libflutter.so
**Action:** Extracted custom 11MB libflutter.so from Maven artifact, replaced in SDK flutter.jar  
**Result:** ❌ FlutterJNI.class still had old 6-parameter signature

### 2. Use Maven resolutionStrategy
**Action:** Tried forcing engine version via Gradle: `configurations.all { resolutionStrategy.force('io.flutter:arm64_v8a_release:1.0.0-quicui-ae5c3603') }`  
**Result:** ❌ Flutter Gradle plugin bypasses Maven, downloads engines directly from storage.googleapis.com

### 3. Copy FVM Stable flutter.jar
**Action:** Attempted to copy flutter.jar from FVM stable to ensure consistency  
**Result:** ❌ FVM stable hadn't cached engine artifacts yet

### 4. Replace Entire flutter.jar with Custom Build
**Action:** Used `/tmp/custom_libflutter.jar` (extracted from Maven)  
**Result:** ❌ Maven artifact only contained libflutter.so, missing FlutterJNI.class

### 5. Engine Version Workaround
**Action:** Set engine.version to known hash (035316565a) to avoid Google downloads, kept custom libflutter.so  
**Result:** ✅ Build succeeded, but app still crashed (same mismatch issue)

## Working Solution

**Use FVM Stable for Now:**

```bash
cd test_apps/quicui_engine_test
fvm use stable
fvm flutter clean
fvm flutter build apk --release --target-platform android-arm64
```

This ensures **both** libflutter.so and FlutterJNI.class have matching 6-parameter signatures.

**Result:** ✅ App launches successfully, no JNI crash

## Proper Integration Strategy

To use our custom engine (ae5c3603) with 7-parameter signature:

### Option 1: Update SDK Embedding Classes (RECOMMENDED)

1. **Find Compiled FlutterJNI.class from ae5c3603 Build:**
   ```bash
   # Check engine build output
   find shorebird_engine -name "FlutterJNI.class" -type f
   ```

2. **Replace in SDK flutter.jar:**
   ```bash
   # Extract existing flutter.jar
   cd /tmp/flutter_jar_rebuild
   unzip -q /path/to/sdk/flutter.jar
   
   # Replace FlutterJNI.class with version from ae5c3603
   cp /path/to/compiled/FlutterJNI.class io/flutter/embedding/engine/
   
   # Repackage
   zip -qr /path/to/sdk/flutter.jar .
   ```

3. **Rebuild app:**
   ```bash
   flutter clean && flutter build apk --release
   ```

### Option 2: Downgrade Engine to 6-Parameter Version

Find a stable engine version that uses 6-parameter signature:
```bash
# Use engine version from stable SDK
cat ~/fvm/versions/stable/bin/internal/engine.version
# 035316565ad77281a75305515e4682e6c4c6f7ca

# Download and use matching libflutter.so
```

### Option 3: Fork and Patch SDK

1. Create branch in `forks/flutter-quicui`
2. Update `engine/src/.../FlutterJNI.java` to 6-parameter signature
3. Rebuild engine with matching signature
4. Publish and deploy

## Key Learnings

1. **JNI Signature Must Match:** Native library (libflutter.so) and Java class (FlutterJNI.class) signatures must be identical
2. **flutter.jar Contains Both:** Native libraries AND Java classes are packaged together
3. **Maven Artifacts Incomplete:** Maven-published engine artifacts may only contain libflutter.so
4. **Flutter Gradle Plugin Behavior:** Bypasses Maven, downloads engines from Google Cloud Storage
5. **Engine Version Evolution:** Flutter's engine API evolves between versions; mixing versions causes runtime failures

## Impact on QuicUI Code Push

For OTA patch testing:
- ✅ Use FVM stable for now to test patch loading mechanism
- ⏳ Later: Integrate proper 7-parameter engine build for AttachJNI diagnostics

The QuicUICodePushLoader should work with standard engine (6-parameter) since patch loading happens **before** FlutterJNI.nativeInit is called.

## References

- **Custom Engine Build:** ae5c3603d013477d37ae301993fc0967d4ad7ed2
- **Stable Engine:** 035316565ad77281a75305515e4682e6c4c6f7ca
- **SDK Location:** `/Users/admin/Documents/quicui2/forks/flutter-quicui`
- **FlutterJNI Source:** `engine/src/flutter/shell/platform/android/io/flutter/embedding/engine/FlutterJNI.java`
- **flutter.jar Location:** `bin/cache/artifacts/engine/android-arm64-release/flutter.jar`

## Next Steps

1. ✅ Test OTA patch loading with FVM stable build
2. ⏳ Compile FlutterJNI.class from ae5c3603 engine source
3. ⏳ Deploy full custom engine with matching embedding classes
4. ⏳ Verify AttachJNI logging in custom engine build
