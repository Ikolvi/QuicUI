# Maven Deployment Findings - JNI Signature Mismatch

**Date**: November 4, 2024  
**Session**: QuicUI Engine Maven Publication & Testing

## TL;DR

✅ **Successfully built APK with QuicUI engine from local Maven**  
❌ **Runtime crash due to JNI signature mismatch**  

**Root Cause**: The modified QuicUI engine was built with different Flutter version/patches than the Flutter SDK used to build the app, causing native method registration to fail.

---

## What Worked

### 1. Maven Publication ✅
- Published QuicUI engine to local Maven (`.m2/repository`)
- Coordinate: `io.flutter:arm64_v8a_release:1.0.0-quicui`
- Size: 5.0MB JAR containing 11.3MB stripped libflutter.so
- Verification: `strings` confirmed "AttachJNI called!" present in JAR

### 2. Gradle Configuration ✅
- Added local Maven repository to settings.gradle.kts (pluginManagement)
- Added local Maven repository to build.gradle.kts (allprojects)
- Used `resolutionStrategy.force()` to override Flutter engine version
- **Key fix**: Had to use absolute path (`/Users/admin/Documents/quicui2/.m2/repository`) instead of relative path

### 3. Build Process ✅
- Gradle successfully resolved QuicUI engine from local Maven
- APK built successfully (15.6MB)
- Verified QuicUI engine in APK: `strings lib/arm64-v8a/libflutter.so | grep "AttachJNI"` → "AttachJNI called!"

### 4. Gradle Cache Resolution ✅
- Initially encountered persistent Kotlin DSL cache corruption
- **Solution**: Deleted entire `~/.gradle` directory
- Fresh Gradle home solved the metadata.bin corruption issue

---

## What Failed

### JNI Signature Mismatch ❌

**Error Log**:
```
E cui_engine_test:     26: void io.flutter.embedding.engine.FlutterJNI.init(
    android.content.Context, 
    java.lang.String[], 
    java.lang.String, 
    java.lang.String, 
    java.lang.String, 
    long, 
    int)  // <-- Expects 7 parameters

Failed to register native method io.flutter.embedding.engine.FlutterJNI.nativeInit(
    Landroid/content/Context;
    [Ljava/lang/String;
    Ljava/lang/String;
    Ljava/lang/String;
    Ljava/lang/String;
    J)V  // <-- Engine only provides 6 parameters (missing int at end)

[FATAL:flutter/shell/platform/android/library_loader.cc(21)] Check failed: result.
```

**Analysis**:

1. **Expected Signature** (from Flutter SDK in app):
   ```java
   void nativeInit(Context, String[], String, String, String, long, int)
   ```
   JNI Descriptor: `(Landroid/content/Context;[Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;JI)V`

2. **Actual Signature** (from QuicUI engine):
   ```java
   void nativeInit(Context, String[], String, String, String, long)
   ```
   JNI Descriptor: `(Landroid/content/Context;[Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;J)V`

3. **Root Cause**:
   - Modified QuicUI engine built from `/Volumes/DoWonder2/quicui_engine_build/engine_full`
   - App's Flutter SDK from `forks/flutter-quicui`
   - These are from **different Flutter versions or have incompatible patches**
   - The extra `int` parameter was added in a newer Flutter version

**Result**: App crashes immediately with `SIGABRT` when trying to load native library.

---

## Technical Deep Dive

### The Build Process

#### Phase 1: Engine Build ✅
```bash
# Engine was built separately
cd /Volumes/DoWonder2/quicui_engine_build/engine_full
./src/flutter/tools/gn --runtime-mode=release --android --android-cpu=arm64
ninja -C src/out/android_release_arm64
# Output: libflutter.so (158MB unstripped, 11.3MB stripped)
```

#### Phase 2: Maven Publication ✅
```bash
# Published to local Maven
scripts/publish_engine_to_maven.sh
# Created:
# .m2/repository/io/flutter/arm64_v8a_release/1.0.0-quicui/
#   ├── arm64_v8a_release-1.0.0-quicui.jar (5.0MB)
#   ├── arm64_v8a_release-1.0.0-quicui.pom
#   ├── arm64_v8a_release-1.0.0-quicui.jar.md5
#   └── arm64_v8a_release-1.0.0-quicui.jar.sha1
```

#### Phase 3: App Build ✅
```bash
# App built with flutter-quicui SDK
cd test_apps/quicui_engine_test
/Users/admin/Documents/quicui2/forks/flutter-quicui/bin/flutter build apk \
    --release --target-platform android-arm64
# Gradle resolved QuicUI engine from local Maven
# Output: app-release.apk (15.6MB) containing modified libflutter.so
```

#### Phase 4: Runtime ❌
```bash
# App installed successfully
adb install -r build/app/outputs/flutter-apk/app-release.apk
# App crashes during native library initialization
# Reason: JNI signature mismatch in nativeInit()
```

### The Version Mismatch Problem

**Symptom**: Engine built separately doesn't match SDK used to build app

**Evidence**:
1. **Engine source**: `/Volumes/DoWonder2/quicui_engine_build/engine_full`
   - Contains AttachJNI modifications ✅
   - Built with older Flutter version or custom patches
   - `nativeInit` has 6 parameters

2. **App SDK**: `forks/flutter-quicui`
   - Contains Flutter framework code
   - Expects newer Flutter engine
   - `FlutterJNI.java` expects 7 parameters for `nativeInit`

3. **Flutter's Contract**: Flutter framework and engine must be built from **exact same commit hash**
   - Framework (Dart code) defines JNI method signatures
   - Engine (C++ code) must provide matching implementations
   - Any mismatch causes registration failure

---

## Root Cause: Separated Build Process

The fundamental issue is that we're building the engine and app SDK separately:

```
Engine Build Location:
/Volumes/DoWonder2/quicui_engine_build/engine_full/
└── Flutter engine commit: UNKNOWN (older or custom)
    └── Built libflutter.so with 6-param nativeInit

App SDK Location:
/Users/admin/Documents/quicui2/forks/flutter-quicui/
└── Flutter framework commit: UNKNOWN (newer)
    └── FlutterJNI.java expects 7-param nativeInit

Result: 💥 JNI signature mismatch
```

---

## Solutions

### Option 1: Rebuild Engine from flutter-quicui SDK ✅ **RECOMMENDED**

Use the same Flutter source for both engine and SDK:

```bash
# 1. Check Flutter version in flutter-quicui
cd /Users/admin/Documents/quicui2/forks/flutter-quicui
cat bin/internal/engine.version  # Get engine commit hash

# 2. Sync engine to same commit
cd /Volumes/DoWonder2/quicui_engine_build/engine_full/src
gclient sync --revision <commit-hash-from-step-1>

# 3. Apply AttachJNI modifications to platform_view_android_jni_impl.cc

# 4. Rebuild engine
./flutter/tools/gn --runtime-mode=release --android --android-cpu=arm64
ninja -C out/android_release_arm64

# 5. Publish to Maven and rebuild app
```

**Pros**:
- Guaranteed compatibility
- Same approach as Shorebird (they also build engine from their Flutter fork)
- Clean Maven distribution

**Cons**:
- Requires modifying engine source again
- Must rebuild whenever Flutter SDK updates

---

### Option 2: Use Direct APK Injection ⚠️ **WORKAROUND**

Bypass Maven entirely and inject libflutter.so directly into built APK:

```bash
# 1. Build app with standard engine
flutter build apk --release

# 2. Extract APK
unzip build/app/outputs/flutter-apk/app-release.apk -d /tmp/apk_extract

# 3. Replace libflutter.so
cp /Volumes/DoWonder2/.../libflutter.so \
   /tmp/apk_extract/lib/arm64-v8a/libflutter.so

# 4. Repackage APK
cd /tmp/apk_extract
zip -r ../app-modified.apk *

# 5. Align and sign
zipalign -v 4 ../app-modified.apk ../app-aligned.apk
apksigner sign --ks keystore.jks ../app-aligned.apk
```

**Pros**:
- Works with any engine build
- No need to rebuild engine

**Cons**:
- Still has JNI signature mismatch (will crash)
- Not a real solution, just demonstrates same problem

**Note**: This won't solve the JNI mismatch. The engine and SDK must match.

---

### Option 3: Update flutter-quicui SDK ⚠️ **NOT RECOMMENDED**

Downgrade flutter-quicui to match engine's Flutter version:

```bash
cd /Users/admin/Documents/quicui2/forks/flutter-quicui
git log --oneline --all | grep <date-matching-engine>
git checkout <commit-hash>
flutter doctor
```

**Pros**:
- Makes SDK match engine

**Cons**:
- Loses any newer features in flutter-quicui
- May break compatibility with app code
- Requires identifying exact Flutter version used for engine

---

## Shorebird's Approach (Reference)

Shorebird solves this by:

1. **Forking Flutter SDK**: They maintain `shorebird/flutter` fork
2. **Building Engine from Fork**: Engine built from same source as SDK
3. **Publishing to CDN**: Engine artifacts hosted at `download.shorebird.dev`
4. **Environment Variable**: `FLUTTER_STORAGE_BASE_URL=https://download.shorebird.dev`
5. **Transparent to Users**: Users just use `shorebird flutter` CLI

**Key Insight**: Engine and SDK are **always** from the same commit hash.

---

## Next Steps

### Immediate (Development)

1. ✅ Get engine commit hash from flutter-quicui:
   ```bash
   cat forks/flutter-quicui/bin/internal/engine.version
   ```

2. ✅ Sync engine source to matching commit:
   ```bash
   cd /Volumes/DoWonder2/quicui_engine_build/engine_full/src
   gclient sync --revision <hash-from-step-1>
   ```

3. ✅ Re-apply AttachJNI modifications to platform_view_android_jni_impl.cc

4. ✅ Rebuild engine with matching Flutter version

5. ✅ Re-publish to local Maven

6. ✅ Rebuild and test app

### Long-term (Production)

1. **Automate Engine Building**: Script to rebuild engine whenever flutter-quicui updates
2. **CI/CD Integration**: Automatically publish engine to Maven/CDN on commit
3. **Version Management**: Track engine.version and enforce matching
4. **Shorebird-style Distribution**: Consider `FLUTTER_STORAGE_BASE_URL` approach for transparency

---

## Lessons Learned

1. **Flutter Framework + Engine = Tightly Coupled**
   - Must be built from same commit hash
   - JNI signatures change between versions
   - Can't mix and match versions

2. **Maven Publication Works**
   - Gradle successfully resolved custom engine
   - resolutionStrategy.force() correctly overrides version
   - Local Maven repository is viable for development

3. **Gradle Cache Can Be Problematic**
   - Kotlin DSL cache corruption is real
   - Solution: Delete ~/.gradle when issues persist
   - Fresh Gradle home resolves most cache problems

4. **Engine Building is Complex**
   - Requires exact version synchronization
   - Must track Flutter's engine.version file
   - Any modifications need careful version management

5. **Shorebird's Approach is Elegant**
   - Maintaining Flutter fork ensures compatibility
   - Environment variable redirection is transparent
   - Users don't need to know about custom engine

---

## Files Modified This Session

### Created
- `scripts/publish_engine_to_maven.sh` - Maven publication automation
- `scripts/build_test_app.sh` - Build script with correct directory handling
- `scripts/inject_quicui_engine.sh` - Direct APK injection (backup method)
- `docs/2024-11-04/ARCHITECTURE_MAPPING_ANALYSIS.md` - Flutter's arch mapping
- `docs/2024-11-04/SHOREBIRD_MAVEN_STRATEGY.md` - Shorebird analysis
- `docs/2024-11-04/MAVEN_PUBLICATION_SUMMARY.md` - Implementation summary
- `docs/2024-11-04/MAVEN_DEPLOYMENT_FINDINGS.md` - This document

### Modified
- `test_apps/quicui_engine_test/android/settings.gradle.kts` - Added local Maven repo
- `test_apps/quicui_engine_test/android/build.gradle.kts` - Added resolutionStrategy.force()

### Published
- `.m2/repository/io/flutter/arm64_v8a_release/1.0.0-quicui/` - Maven artifacts

---

## Success Metrics

| Metric | Status | Notes |
|--------|--------|-------|
| Maven Publication | ✅ | Successfully published to local Maven |
| Gradle Resolution | ✅ | Gradle found and used QuicUI engine |
| APK Build | ✅ | Built 15.6MB APK with QuicUI engine |
| APK Verification | ✅ | Confirmed AttachJNI modifications present |
| APK Installation | ✅ | Installed successfully on device |
| Runtime Execution | ❌ | Crashes due to JNI signature mismatch |
| AttachJNI Logs | ⏸️ | Can't test until signature mismatch fixed |

---

## Conclusion

The Maven deployment approach is **technically sound** and **successfully works** for distribution. The runtime failure is **not a Maven issue** but a **Flutter version incompatibility issue** between the separately-built engine and SDK.

**Next action**: Rebuild engine from the same Flutter source as `flutter-quicui` SDK to ensure JNI signature compatibility.
