# Flutter Gradle Cache and Engine Artifacts Issue

**Date:** November 17, 2025  
**Status:** ✅ SOLVED - Solution Implemented  
**Related:** QuicUI Code Push Engine Integration

---

## Problem Summary

When building Flutter apps with a **custom-modified Flutter engine** (containing QuicUI C++ code), the built APK was using the **standard Flutter engine** instead of the QuicUI-modified engine, despite the modified artifacts being present in the Flutter fork's cache.

### Symptoms

1. ✅ Fork has QuicUI engine artifacts:
   - Location: `forks/flutter/bin/cache/artifacts/engine/android-arm64-release/darwin-x64/`
   - `libflutter.so` (156MB) contains `ConfigureQuicUI` C++ functions
   - `flutter.jar` (5.5MB) contains QuicUI classes

2. ❌ Built APK has standard engine:
   - `lib/arm64-v8a/libflutter.so` (~11MB stripped) does NOT contain `ConfigureQuicUI`
   - APK built with fork's Flutter still uses standard engine

3. 🔍 Evidence of problem:
   ```bash
   # Fork's engine HAS QuicUI code:
   $ strings forks/flutter/.../darwin-x64/libflutter.so | grep ConfigureQuicUI
   ConfigureQuicUI: Looking for patch at: %s
   ConfigureQuicUI: No patched library found, using original libapp.so
   ConfigureQuicUI: Checking for patched library...
   
   # Built APK does NOT:
   $ strings app-release.apk lib/arm64-v8a/libflutter.so | grep ConfigureQuicUI
   (empty - no matches)
   ```

---

## Root Cause

### Flutter's Maven-Based Artifact System

Flutter's Gradle build system **completely bypasses** locally-modified SDK cache files. Instead, it:

1. **Downloads engine artifacts from Maven repository** at:
   ```
   https://storage.googleapis.com/download.flutter.io
   ```

2. **Uses separate Maven artifacts for each component:**
   - `io.flutter:flutter_embedding_release` - Java embedding code (flutter.jar, ~5.6MB)
   - `io.flutter:arm64_v8a_release` - Native library for ARM64 (libflutter.so in JAR, ~37MB standard / ~85MB custom)
   - `io.flutter:armeabi_v7a_release` - Native library for ARMv7
   - `io.flutter:x86_64_release` - Native library for x86_64

3. **Validates checksums** against remote metadata
   - Even if you replace cached JARs, Gradle re-downloads them if checksums don't match

4. **Critical locations where Maven URLs are configured:**
   - `packages/flutter_tools/gradle/aar_init_script.gradle` (for plugins)
   - `packages/flutter_tools/gradle/resolve_dependencies.gradle.kts` (for app dependencies)

### Why SDK Cache Modifications Don't Work

Modifying files in `forks/flutter/bin/cache/artifacts/engine/` has **NO EFFECT** on Gradle builds because:
- These are runtime artifacts for `flutter run` (VM mode)
- Gradle builds download artifacts from Maven, not from SDK cache
- The build system never looks at the SDK cache for release builds

---

## Solution Implemented

### 1. Add `mavenLocal()` to Flutter Gradle Scripts

Modified **two critical files** in the Flutter fork to check local Maven repository FIRST:

#### File 1: `aar_init_script.gradle` (Line ~58)

**Before:**
```gradle
project.repositories {
    maven {
        url "$storageUrl/${engineRealm}download.flutter.io"
    }
}
```

**After:**
```gradle
project.repositories {
    mavenLocal() // Check local Maven repository FIRST for custom engine artifacts
    maven {
        url "$storageUrl/${engineRealm}download.flutter.io"
    }
}
```

#### File 2: `resolve_dependencies.gradle.kts` (Line ~46)

**Before:**
```kotlin
repositories {
    google()
    mavenCentral()
    maven {
        url = uri("$storageUrl/${engineRealm}download.flutter.io")
    }
}
```

**After:**
```kotlin
repositories {
    mavenLocal() // Check local Maven repository FIRST for custom engine artifacts
    google()
    mavenCentral()
    maven {
        url = uri("$storageUrl/${engineRealm}download.flutter.io")
    }
}
```

### 2. Prepare QuicUI Engine Artifacts

The QuicUI-modified engine artifacts are located at:
```
forks/flutter/bin/cache/artifacts/engine/android-arm64-release/darwin-x64/
├── flutter.jar (5.5MB) - Contains QuicUI Java classes
├── libflutter.so (156MB) - Contains ConfigureQuicUI C++ code
└── lib.unstripped/libflutter.so (156MB) - Unstripped version with debug symbols
```

**Engine Version:** `b5990e5ccc5e325fd24f0746e7d6689bbebc7c65`

**Verification Commands:**
```bash
# Verify QuicUI C++ code present
strings forks/flutter/bin/cache/artifacts/engine/android-arm64-release/darwin-x64/libflutter.so | grep ConfigureQuicUI

# Expected output:
# ConfigureQuicUI: Looking for patch at: %s
# ConfigureQuicUI: No patched library found, using original libapp.so
# ConfigureQuicUI: Checking for patched library...

# Verify file size (should be ~156MB for QuicUI, not ~141MB standard)
ls -lh forks/flutter/bin/cache/artifacts/engine/android-arm64-release/darwin-x64/libflutter.so
```

---

## Implementation Options

### Option A: Proper Maven Publishing (RECOMMENDED for Production)

Create proper Maven artifacts in local Maven repository:

```bash
ENGINE_VERSION="b5990e5ccc5e325fd24f0746e7d6689bbebc7c65"

# 1. Create local Maven structure
mkdir -p ~/.m2/repository/io/flutter/arm64_v8a_release/1.0.0-${ENGINE_VERSION}/
mkdir -p ~/.m2/repository/io/flutter/flutter_embedding_release/1.0.0-${ENGINE_VERSION}/

# 2. Package libflutter.so into JAR
cd forks/flutter/bin/cache/artifacts/engine/android-arm64-release/darwin-x64/
mkdir -p lib/arm64-v8a/
cp libflutter.so lib/arm64-v8a/
jar cvf arm64_v8a_release-1.0.0-${ENGINE_VERSION}.jar lib/arm64-v8a/libflutter.so

# 3. Copy to Maven local
cp arm64_v8a_release-1.0.0-${ENGINE_VERSION}.jar \
   ~/.m2/repository/io/flutter/arm64_v8a_release/1.0.0-${ENGINE_VERSION}/

# 4. Create POM file (required for Maven resolution)
cat > ~/.m2/repository/io/flutter/arm64_v8a_release/1.0.0-${ENGINE_VERSION}/arm64_v8a_release-1.0.0-${ENGINE_VERSION}.pom << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>io.flutter</groupId>
  <artifactId>arm64_v8a_release</artifactId>
  <version>1.0.0-b5990e5ccc5e325fd24f0746e7d6689bbebc7c65</version>
  <packaging>jar</packaging>
</project>
EOF

# 5. Repeat for flutter_embedding_release (flutter.jar)
cp flutter.jar ~/.m2/repository/io/flutter/flutter_embedding_release/1.0.0-${ENGINE_VERSION}/flutter_embedding_release-1.0.0-${ENGINE_VERSION}.jar
# ... create POM file similarly
```

### Option B: Gradle Cache Replacement Workaround (SIMPLER for Development)

Let Gradle download standard artifacts once, then replace them:

```bash
ENGINE_VERSION="b5990e5ccc5e325fd24f0746e7d6689bbebc7c65"

# 1. Build once to populate Gradle cache
cd test_apps/quicui_production_test
../../forks/flutter/bin/flutter build apk --release

# 2. Find the cached JAR location
GRADLE_CACHE_DIR=$(find ~/.gradle/caches/modules-2/files-2.1/io.flutter/arm64_v8a_release/1.0.0-${ENGINE_VERSION}/ -type f -name "*.jar" | head -1)
GRADLE_CACHE_HASH=$(dirname "$GRADLE_CACHE_DIR" | xargs basename)

echo "Found Gradle cache at: $GRADLE_CACHE_DIR"
echo "Cache hash: $GRADLE_CACHE_HASH"

# 3. Create QuicUI JAR from fork's libflutter.so
cd ../../forks/flutter/bin/cache/artifacts/engine/android-arm64-release/darwin-x64/
mkdir -p lib/arm64-v8a/
cp libflutter.so lib/arm64-v8a/
jar cvf /tmp/quicui_arm64_v8a.jar lib/arm64-v8a/libflutter.so

# 4. Replace cached JAR
cp /tmp/quicui_arm64_v8a.jar "$GRADLE_CACHE_DIR"

# 5. Clear Gradle transforms cache (CRITICAL!)
rm -rf ~/.gradle/caches/*/transforms/*arm64_v8a*
rm -rf ~/.gradle/caches/*/transforms/*flutter*

# 6. Clear project build cache
cd /Users/admin/Documents/quicui2/test_apps/quicui_production_test
rm -rf android/.gradle android/build build

# 7. Rebuild
../../forks/flutter/bin/flutter build apk --release

# 8. Verify QuicUI engine in APK
unzip -p build/app/outputs/flutter-apk/app-release.apk lib/arm64-v8a/libflutter.so > /tmp/libflutter_from_apk.so
strings /tmp/libflutter_from_apk.so | grep ConfigureQuicUI
# Should return ConfigureQuicUI strings if successful
```

---

## Verification Steps

After implementing either solution, verify the APK contains QuicUI engine:

### 1. Check APK Size
```bash
ls -lh build/app/outputs/flutter-apk/app-release.apk
# Should be larger than standard builds due to 156MB libflutter.so
```

### 2. Extract and Check libflutter.so
```bash
# Extract libflutter.so from APK
unzip -p build/app/outputs/flutter-apk/app-release.apk lib/arm64-v8a/libflutter.so > /tmp/libflutter_from_apk.so

# Check for QuicUI C++ code
strings /tmp/libflutter_from_apk.so | grep -E "ConfigureQuicUI|quicui_patch"

# Expected output:
# ConfigureQuicUI: Looking for patch at: %s
# ConfigureQuicUI: No patched library found, using original libapp.so
# quicui_patch_loader_jni.cc
# quicui_patch_loader.cc
```

### 3. Compare with Fork's Engine
```bash
# Get MD5 of fork's libflutter.so
md5 forks/flutter/bin/cache/artifacts/engine/android-arm64-release/darwin-x64/libflutter.so

# Get MD5 of APK's libflutter.so
md5 /tmp/libflutter_from_apk.so

# Hashes should match (or at least size should be similar ~156MB vs ~141MB)
```

### 4. Runtime Verification
Install APK and check logs:
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb logcat | grep -E "ConfigureQuicUI|QuicUI"

# Expected logs on app startup:
# E FlutterLoader: 🚀🚀🚀 QuicUI: FlutterLoader ELSE BLOCK EXECUTING
# I QuicUICodePush: Using QuicUI patched AOT library: .../libapp_patched_arm64-v8a.so
# E FlutterLoader: 🚀 QuicUI: Using PATCHED AOT from .../libapp_patched_arm64-v8a.so
```

---

## Technical Background

### How Flutter Gradle Build System Works

1. **Plugin Resolution** (`aar_init_script.gradle`):
   - Applied to Flutter plugin projects
   - Downloads `flutter_embedding_release` for compile-only dependency
   - URL: `$storageUrl/${engineRealm}download.flutter.io`

2. **Dependency Resolution** (`resolve_dependencies.gradle.kts`):
   - Applied to app projects via `flutter build apk`
   - Downloads all engine artifacts (embedding + native libs)
   - Separate artifacts per architecture: arm64_v8a, armeabi_v7a, x86_64

3. **Build Process Flow:**
   ```
   flutter build apk
     ↓
   Gradle reads resolve_dependencies.gradle.kts
     ↓
   Downloads from Maven: https://storage.googleapis.com/.../download.flutter.io
     ↓
   Caches in: ~/.gradle/caches/modules-2/files-2.1/io.flutter/
     ↓
   Extracts to transforms cache: ~/.gradle/caches/transforms-*/
     ↓
   Packages into APK: lib/arm64-v8a/libflutter.so
   ```

4. **Why SDK Cache is Ignored:**
   - SDK cache (`bin/cache/artifacts/engine/`) is for VM mode (`flutter run`)
   - Release builds use AOT compilation with Maven artifacts
   - Two completely separate artifact sources

### Maven Artifact Structure

Flutter engine artifacts on Maven:
```
https://storage.googleapis.com/download.flutter.io/
└── io/
    └── flutter/
        ├── flutter_embedding_release/
        │   └── 1.0.0-{engine_hash}/
        │       ├── flutter_embedding_release-1.0.0-{engine_hash}.jar
        │       ├── flutter_embedding_release-1.0.0-{engine_hash}.pom
        │       └── flutter_embedding_release-1.0.0-{engine_hash}.jar.sha1
        ├── arm64_v8a_release/
        │   └── 1.0.0-{engine_hash}/
        │       ├── arm64_v8a_release-1.0.0-{engine_hash}.jar (contains libflutter.so)
        │       ├── arm64_v8a_release-1.0.0-{engine_hash}.pom
        │       └── arm64_v8a_release-1.0.0-{engine_hash}.jar.sha1
        └── ...
```

Local Maven repository mirrors this structure at `~/.m2/repository/`.

---

## Known Limitations

### 1. mavenLocal() Doesn't Fully Work
Even with `mavenLocal()` added to Gradle scripts:
- Gradle still validates checksums against remote metadata
- If checksums don't match, Gradle re-downloads from remote
- This is why the "cache replacement workaround" is needed

### 2. Build Time Indicators
- **Fast build (1-2s):** Using cached artifacts, modifications NOT included ❌
- **Slow build (60+ seconds):** Full recompilation, modifications INCLUDED ✅

### 3. Cache Clearing is Critical
Must clear BOTH:
- `~/.gradle/caches/*/transforms/*` - Extracted native libraries
- `android/.gradle`, `android/build`, `build/` - Project build cache

Failure to clear caches means Gradle reuses old artifacts.

---

## Alternative Approaches Tried (FAILED)

### ❌ Modifying SDK Cache Artifacts
```bash
# This does NOT work:
cp custom_libflutter.so forks/flutter/bin/cache/artifacts/engine/.../libflutter.so
flutter build apk  # Still uses standard engine
```
**Why it fails:** Gradle doesn't use SDK cache for release builds.

### ❌ Modifying Gradle Cache Directly
```bash
# This does NOT work reliably:
cp custom_jar ~/.gradle/caches/modules-2/.../artifact.jar
flutter build apk  # Gradle re-downloads and replaces it
```
**Why it fails:** Gradle validates checksums and re-downloads on mismatch.

### ❌ Using --local-engine Flag
```bash
# This REQUIRES full engine build output with .pom files:
flutter build apk --local-engine=android_release --local-engine-host=host_release
```
**Why it fails:** Requires complete engine build output structure, not just deployed artifacts.

---

## Future Improvements

### 1. Automated Script
Create `scripts/setup_quicui_maven.sh` to automate Maven artifact publishing:
```bash
#!/bin/bash
# Automatically publish QuicUI engine to local Maven repository
# with proper POM files and checksums
```

### 2. CI/CD Integration
- Publish QuicUI engine artifacts to private Maven repository
- Configure Gradle to use private Maven URL
- No need for manual cache replacement

### 3. Engine Build Automation
- Automate engine building with QuicUI patches
- Generate proper Maven artifacts during engine build
- Version QuicUI engine separately from Flutter stable

---

## Related Documentation

- **QuicUI Complete System:** `docs/2025-11-06/QUICUI_WORKING_SYSTEM_COMPLETE.md` (2727 lines)
- **Engine Build Process:** `docs/2024-11-03/build_android_engine.sh`
- **FlutterLoader Modifications:** Knowledge base entries from Nov 5-6, 2025

---

## Timeline of Discovery

**November 5-6, 2025:** Initial attempts to modify flutter.jar in various locations (Gradle cache, Maven local, SDK cache) - all failed because Flutter compiles from SOURCE, not JARs.

**November 6, 2025 (Evening):** Discovered Flutter uses Maven artifacts from `storage.googleapis.com`, not SDK cache. Found that modifications to SDK cache have no effect on release builds.

**November 17, 2025:** Found the solution - add `mavenLocal()` to Flutter Gradle scripts. Modified `aar_init_script.gradle` and `resolve_dependencies.gradle.kts` in the Flutter fork.

**November 17, 2025 (Success):** Implemented Option B (Gradle Cache Replacement Workaround). Created automated script `scripts/deploy_quicui_engine_to_gradle.sh`. Successfully deployed QuicUI engine and verified ConfigureQuicUI present in built APKs.

---

## Implementation Results (Nov 17, 2025)

### Successfully Deployed Using Option B

Created automation script: **`scripts/deploy_quicui_engine_to_gradle.sh`**

This script:
1. ✅ Verifies QuicUI artifacts exist in fork (156MB libflutter.so with ConfigureQuicUI)
2. ✅ Builds once to populate Gradle cache with standard artifacts
3. ✅ Locates cached JAR at `~/.gradle/caches/modules-2/files-2.1/io.flutter/arm64_v8a_release/`
4. ✅ Creates custom JAR (39MB) from QuicUI libflutter.so
5. ✅ Backs up original standard JAR
6. ✅ Replaces cached JAR with QuicUI version
7. ✅ Clears Gradle transforms cache
8. ✅ Clears project build cache
9. ✅ Rebuilds APK with QuicUI engine

### Verification Results

**APK Size Increase:**
```bash
✓ Built build/app/outputs/flutter-apk/app-release.apk (45.8MB)
# Standard Flutter APKs are typically ~32-44MB
# QuicUI APK is larger due to 156MB unstripped libflutter.so
```

**ConfigureQuicUI Confirmed Present:**
```bash
$ unzip -p build/app/outputs/flutter-apk/app-release.apk lib/arm64-v8a/libflutter.so | strings | grep ConfigureQuicUI
ConfigureQuicUI: 
/quicui_patches
ConfigureQuicUI: Looking for patch at: %s
ConfigureQuicUI: 
ConfigureQuicUI: No patched library found, using original libapp.so
ConfigureQuicUI: Checking for patched library...

# Total ConfigureQuicUI references: 5
```

**QuicUI CLI Integration:**
```bash
$ dart packages/quicui_cli/bin/quicui.dart build-apk --version 1.0.2 --baseline
🔨 QuicUI APK Builder
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Version:      1.0.2
Project:      .
Architecture: arm64-v8a
Type:         Baseline

📦 Building APK...
✅ Using QuicUI Flutter fork
   ✅ APK built: ./build/app/outputs/flutter-apk/app-release.apk

✅ Build Complete!
```

**Baseline APK Verification:**
```bash
$ unzip -p baseline/app-v1.0.2.apk lib/arm64-v8a/libflutter.so | strings | grep ConfigureQuicUI | wc -l
       5
# ✅ Baseline APK contains QuicUI engine
```

### Usage Instructions

**First Time Setup (after cloning or Gradle cache clear):**
```bash
./scripts/deploy_quicui_engine_to_gradle.sh
```

**Building APKs:**
```bash
# Option 1: Using QuicUI CLI (recommended)
cd test_apps/quicui_production_test
dart ../../packages/quicui_cli/bin/quicui.dart build-apk --version 1.0.2 --baseline

# Option 2: Direct Flutter command
cd test_apps/quicui_production_test
../../forks/flutter/bin/flutter build apk --release
```

**Verify QuicUI Engine:**
```bash
unzip -p build/app/outputs/flutter-apk/app-release.apk lib/arm64-v8a/libflutter.so | strings | grep ConfigureQuicUI
# Should return 5 lines with ConfigureQuicUI references
```

### Important Notes

⚠️ **When to Re-run Deployment Script:**
- After any Gradle cache clear (`rm -rf ~/.gradle/caches`)
- After Flutter SDK update
- After switching Flutter versions
- If APK verification shows no ConfigureQuicUI (standard engine being used)

⚠️ **Symptoms of Standard Engine Being Used:**
- APK size smaller than expected (~32-44MB instead of ~45-46MB)
- `strings libflutter.so | grep ConfigureQuicUI` returns empty
- Runtime logs show no QuicUI-related messages

---

## Summary

✅ **Problem:** Flutter Gradle builds download engine artifacts from Maven, ignoring local SDK cache modifications.

✅ **Solution:** Add `mavenLocal()` to Flutter fork's Gradle scripts + use Gradle cache replacement workaround (Option B).

✅ **Status:** Solution implemented and VERIFIED WORKING:
- `forks/flutter/packages/flutter_tools/gradle/aar_init_script.gradle` (Line 60) - mavenLocal() added
- `forks/flutter/packages/flutter_tools/gradle/resolve_dependencies.gradle.kts` (Line 47) - mavenLocal() added
- `scripts/deploy_quicui_engine_to_gradle.sh` - Automated deployment script created
- Built APKs confirmed contain QuicUI engine (45.8MB with ConfigureQuicUI C++ code)
- QuicUI CLI successfully builds APKs with modified engine
- Baseline APK created and verified with QuicUI engine

✅ **Completed Steps:** 
1. ✅ Modified Flutter fork's Gradle scripts
2. ✅ Created automated deployment script
3. ✅ Deployed QuicUI engine to Gradle cache
4. ✅ Built and verified APK with ConfigureQuicUI present
5. ✅ Tested with QuicUI CLI - working
6. ✅ Created baseline APK with QuicUI engine

---

**Key Takeaway:** Never assume Flutter SDK cache modifications will affect Gradle release builds. Always check if Gradle is downloading from Maven!
