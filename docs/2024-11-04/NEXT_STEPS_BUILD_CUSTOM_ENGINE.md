# Next Steps: Build Custom Matched Flutter Engine

**Date**: November 4, 2025  
**Status**: Ready to proceed with Option 3

## Current Situation Summary

### ✅ Phase 1 Complete: Minimal Test App Validated
- Created `simple_flutter_patch_test` app without QuicUI dependencies
- Successfully builds and runs on device
- Binary patch generation works (47KB for theme change)
- Proves OTA patching concept is sound

### ❌ Phase 1 Discovery: JNI Mismatch Affects ALL Apps
- Initially thought `quicui_engine_test` crash was due to custom MainActivity
- Fixed MainActivity initialization order (moved file I/O after `super.onCreate()`)
- **Still crashes** with same JNI signature mismatch

**Critical Log Evidence**:
```
11-04 16:19:47.785 19199 19218 E cui_engine_test: 
Failed to register native method 
io.flutter.embedding.engine.FlutterJNI.nativeInit(
  Landroid/content/Context;
  [Ljava/lang/String;
  Ljava/lang/String;
  Ljava/lang/String;
  Ljava/lang/String;
  J)V  # ← 6 parameters (ends with 'J' for long)
in /data/app/.../base.apk

11-04 16:19:47.785 19199 19218 F flutter : 
[FATAL:flutter/shell/platform/android/library_loader.cc(21)] 
Check failed: result.
```

### 🤔 Mystery: Why Does simple_flutter_patch_test Work?

**Both apps use the SAME custom engine** (11MB libflutter.so from Gradle cache), yet:
- ✅ `simple_flutter_patch_test` launches successfully
- ❌ `quicui_engine_test` crashes with JNI mismatch

**Hypothesis**: The `quicui_code_push_client` dependency in `quicui_engine_test` might be triggering early Flutter engine initialization that exposes the JNI mismatch before workarounds can apply.

**Evidence**:
- `simple_flutter_patch_test`: No QuicUI dependencies, uses standard `FlutterActivity`
- `quicui_engine_test`: Depends on `quicui_code_push_client` package, custom MainActivity

## Required Solution: Option 3 - Build Custom Matched Engine

### Goal
Build a Flutter engine that:
1. **Matches** Flutter stable 3.35.7 engine commit (035316565a)
2. **Fixes** JNI signature mismatch (6 parameters instead of 7)
3. **Includes** AttachJNI logging for debugging
4. **Works** with both simple apps and QuicUI Code Push system

### Why This is Necessary
- Flutter stable 3.35.7 ships with mismatched JNI signatures
- Google's official engine has this bug
- We cannot wait for upstream fix (no timeline provided)
- Downgrading to Flutter 3.24 would require significant rework
- Custom engine is the only path forward for production use

## Implementation Plan

### Phase 3.1: Identify Engine Version (5 minutes)

```bash
# Get exact engine commit from FVM stable
cat ~/fvm/versions/stable/bin/internal/engine.version
# Expected output: 035316565ad77281a75305515e4682e6c4c6f7ca
```

### Phase 3.2: Setup Engine Build Environment (10 minutes)

```bash
# Ensure you have enough disk space (30GB+ for engine source)
cd /Volumes/DoWonder2/quicui_engine_build
mkdir -p engine_035316565a
cd engine_035316565a

# Configure gclient for this specific commit
gclient config --unmanaged --name=src \
  https://github.com/flutter/engine.git@035316565ad77281a75305515e4682e6c4c6f7ca

# Sync dependencies (~30GB download, 10-20 minutes)
gclient sync -D
```

### Phase 3.3: Apply JNI Signature Fix (5 minutes)

**File 1**: `src/flutter/shell/platform/android/io/flutter/embedding/engine/FlutterJNI.java`

**Location ~Line 177** (nativeInit declaration):
```java
// BEFORE (7 parameters - BROKEN):
private static native void nativeInit(
    Context context,
    String[] args,
    String bundlePath,
    String appStoragePath,
    String engineCachesPath,
    long initTimeMillis,
    int apiLevel);  // ← REMOVE THIS PARAMETER

// AFTER (6 parameters - FIXED):
private static native void nativeInit(
    Context context,
    String[] args,
    String bundlePath,
    String appStoragePath,
    String engineCachesPath,
    long initTimeMillis);
```

**Location ~Line 211** (init() method call):
```java
// BEFORE (7 arguments - BROKEN):
nativeInit(
    context,
    args,
    bundlePath,
    appStoragePath,
    engineCachesPath,
    System.currentTimeMillis(),
    Build.VERSION.SDK_INT);  // ← REMOVE THIS ARGUMENT

// AFTER (6 arguments - FIXED):
nativeInit(
    context,
    args,
    bundlePath,
    appStoragePath,
    engineCachesPath,
    System.currentTimeMillis());
```

### Phase 3.4: Add AttachJNI Logging (2 minutes)

**File 2**: `src/flutter/shell/platform/android/android_shell_holder.cc`

**Location ~Line 97** (AttachJNI function):
```cpp
static void AttachJNI(fml::jni::JNIEnv* env) {
  // Add logging at the start
  FML_LOG(INFO) << "🔥 QuicUI: AttachJNI called with custom matched engine!";
  
  // ... existing code ...
}
```

### Phase 3.5: Build Engine (30-60 minutes)

```bash
cd src

# Configure build for Android ARM64 release
./flutter/tools/gn \
  --android \
  --android-cpu arm64 \
  --runtime-mode release

# Build engine (use -j4 for 4 parallel jobs, adjust based on CPU cores)
ninja -C out/android_release_arm64 -j4
```

**Expected build artifacts**:
- `out/android_release_arm64/lib.stripped/libflutter.so` (~11MB stripped)
- `out/android_release_arm64/lib.unstripped/libflutter.so` (~147MB with debug symbols)
- Java class files in `out/android_release_arm64/flutter_java/`

### Phase 3.6: Package Flutter.jar (10 minutes)

```bash
cd out/android_release_arm64

# The build should already create flutter.jar, but verify it contains:
# 1. io/flutter/embedding/engine/FlutterJNI.class (with 6-param nativeInit)
# 2. lib/arm64-v8a/libflutter.so (stripped ~11MB)

# Check Java class signature
unzip -p flutter.jar io/flutter/embedding/engine/FlutterJNI.class | \
  javap -p - | grep "nativeInit"
# Expected output: private static native void nativeInit(..., long);
#                                                              ^^^^
#                                                        6 parameters!

# Check native library size
unzip -l flutter.jar | grep "libflutter.so"
# Expected: ~11MB (11037032 bytes approximately)
```

### Phase 3.7: Deploy to Custom SDK (5 minutes)

```bash
# Backup current flutter.jar
cd /Users/admin/Documents/quicui2/forks/flutter-quicui/bin/cache/artifacts/engine/android-arm64-release
cp flutter.jar flutter.jar.backup_$(date +%Y%m%d_%H%M%S)

# Copy new custom engine
cp /Volumes/DoWonder2/quicui_engine_build/engine_035316565a/src/out/android_release_arm64/flutter.jar \
   flutter.jar

# Verify deployment
ls -lh flutter.jar
# Expected: ~38MB (contains 11MB stripped libflutter.so + Java classes)
```

### Phase 3.8: Verify Signatures Match (5 minutes)

```bash
cd /Users/admin/Documents/quicui2/forks/flutter-quicui/bin/cache/artifacts/engine/android-arm64-release

# Extract and decompile FlutterJNI.class
unzip -q flutter.jar io/flutter/embedding/engine/FlutterJNI.class -d /tmp/verify_engine
javap -p /tmp/verify_engine/io/flutter/embedding/engine/FlutterJNI.class | grep "nativeInit"

# Expected output:
# private static native void nativeInit(
#   android.content.Context, 
#   java.lang.String[], 
#   java.lang.String, 
#   java.lang.String, 
#   java.lang.String, 
#   long);  # ← 6 parameters! NO int apiLevel

# Extract libflutter.so and check symbols
unzip -q flutter.jar lib/arm64-v8a/libflutter.so -d /tmp/verify_engine
nm -D /tmp/verify_engine/lib/arm64-v8a/libflutter.so | grep "Java_io_flutter.*nativeInit"

# Should show JNI registration for 6-parameter version
```

### Phase 3.9: Clear Gradle Caches (2 minutes)

**CRITICAL**: Gradle caches old engine artifacts aggressively

```bash
# Clear ALL Gradle Flutter caches
rm -rf ~/.gradle/caches/8.*/transforms/*flutter*
rm -rf ~/.gradle/caches/8.*/transforms/*quicui*
rm -rf ~/.gradle/caches/modules-2/files-2.1/io.flutter*

# Clear Gradle daemon
gradle --stop
# or
~/.gradle/wrapper/dists/gradle-*/*/bin/gradle --stop

# Verify cleared
find ~/.gradle -name "libflutter.so" 2>/dev/null
# Should return NOTHING
```

### Phase 3.10: Rebuild and Test quicui_engine_test (5 minutes)

```bash
cd /Users/admin/Documents/quicui2/test_apps/quicui_engine_test

# Complete clean
rm -rf build
rm -rf android/.gradle
rm -rf android/.dart_tool
rm -rf .dart_tool

# Rebuild with custom matched engine
/Users/admin/Documents/quicui2/forks/flutter-quicui/bin/flutter build apk \
  --release \
  --target-platform android-arm64

# Verify libflutter.so in APK
unzip -l build/app/outputs/flutter-apk/app-release.apk | grep "libflutter.so"
# Should show ~11MB
```

### Phase 3.11: Install and Verify (3 minutes)

```bash
# Install APK
~/Library/Android/sdk/platform-tools/adb install -r \
  build/app/outputs/flutter-apk/app-release.apk

# Launch app
~/Library/Android/sdk/platform-tools/adb shell am start -n \
  com.quicui.test.quicui_engine_test/.MainActivity

# Check if process is running (should stay alive!)
sleep 3
~/Library/Android/sdk/platform-tools/adb shell ps | grep quicui_engine_test
# Expected: process ID shows app is running

# Check logs for success
~/Library/Android/sdk/platform-tools/adb logcat -d | grep "QuicUI: AttachJNI"
# Expected: "🔥 QuicUI: AttachJNI called with custom matched engine!"
```

### Phase 3.12: Visual Verification (2 minutes)

```bash
# Capture screenshot
~/Library/Android/sdk/platform-tools/adb shell screencap -p > /tmp/quicui_test_screen.png

# Should see:
# - Purple theme
# - "QuicUI Engine Test"
# - "v1.0.0"
# - Purple box with "ORIGINAL"
```

## Success Criteria

- [ ] Engine source downloaded (030316565a commit)
- [ ] JNI signature fixed (6 parameters in both Java and native)
- [ ] AttachJNI logging added
- [ ] Engine built successfully (~11MB stripped libflutter.so)
- [ ] flutter.jar packaged with correct signatures
- [ ] Deployed to custom flutter-quicui SDK
- [ ] Gradle caches cleared completely
- [ ] quicui_engine_test rebuilt with new engine
- [ ] App launches without JNI mismatch crash
- [ ] Process stays alive (not crashing)
- [ ] AttachJNI log message appears in logcat
- [ ] Purple theme displays correctly
- [ ] Ready for OTA patch testing

## Timeline Estimate

| Phase | Duration | Cumulative |
|-------|----------|------------|
| 3.1: Identify version | 5 min | 5 min |
| 3.2: Setup environment | 10 min | 15 min |
| 3.3: Apply JNI fix | 5 min | 20 min |
| 3.4: Add logging | 2 min | 22 min |
| 3.5: Build engine | 30-60 min | 52-82 min |
| 3.6: Package flutter.jar | 10 min | 62-92 min |
| 3.7: Deploy to SDK | 5 min | 67-97 min |
| 3.8: Verify signatures | 5 min | 72-102 min |
| 3.9: Clear Gradle caches | 2 min | 74-104 min |
| 3.10: Rebuild test app | 5 min | 79-109 min |
| 3.11: Install and verify | 3 min | 82-112 min |
| 3.12: Visual verification | 2 min | 84-114 min |

**Total**: ~1.5-2 hours (including 30-60 min build time)

## Risk Mitigation

### Risk 1: Build Failures
**Mitigation**: Follow official Flutter engine build instructions exactly. Check dependencies.

### Risk 2: Signature Still Mismatched
**Mitigation**: Verify Java class signatures before and after modification. Use `javap -p` to confirm.

### Risk 3: Gradle Still Caches Old Engine
**Mitigation**: Nuclear option - delete entire `~/.gradle` directory and rebuild from scratch.

### Risk 4: App Crashes for Different Reason
**Mitigation**: Check logcat for different error messages. May need additional engine modifications.

## Post-Success Next Steps

Once custom engine works:

1. **Test OTA Patching**:
   - Deploy original purple version
   - Create and deploy orange patch
   - Verify hot patch loading works
   - Confirm visual change (purple → orange)

2. **Document Engine Build**:
   - Create reproducible build script
   - Document all modifications
   - Version custom engine builds
   - Set up CI/CD for future engine builds

3. **Update QuicUI Documentation**:
   - Add custom engine requirement
   - Document JNI signature issue
   - Provide troubleshooting guide
   - Create FAQ for common issues

4. **Production Readiness**:
   - Test with multiple apps
   - Verify performance (no regression)
   - Test on different Android versions
   - Validate memory usage
   - Stress test OTA updates

## Alternative: Quick Test with Downgrade

If engine build fails or takes too long, consider:

```bash
# Downgrade to Flutter 3.24 (last known good version)
fvm install 3.24.0
cd test_apps/quicui_engine_test
fvm use 3.24.0
fvm flutter build apk --release
```

However, this is **NOT RECOMMENDED** because:
- Requires updating all dependencies
- May have breaking API changes
- Loses latest Flutter features
- Not a long-term solution

## Conclusion

Building a custom matched Flutter engine is the only proper solution to unblock QuicUI Code Push testing. The minimal test app proved the concept works, but the JNI mismatch in Flutter stable 3.35.7 prevents production use.

**Immediate Action**: Proceed with Phase 3.1-3.12 to build custom engine.

**Expected Outcome**: After ~2 hours, we'll have a working QuicUI Code Push system ready for full OTA testing and visual verification.
