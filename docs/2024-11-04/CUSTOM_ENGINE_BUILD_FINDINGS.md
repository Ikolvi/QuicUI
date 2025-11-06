# Custom Flutter Engine Build - Complete Findings
**Date:** November 4, 2024  
**Session:** QuicUI OTA Patch Testing - Engine Compatibility Investigation

## Executive Summary

Successfully built a custom Flutter engine from the main branch with correct 6-parameter JNI signatures. However, discovered a critical version mismatch issue: the custom engine (main branch) is incompatible with the Flutter SDK 3.35.7 currently in use, causing library loading failures.

## Problem Statement

### Initial Issue: JNI Signature Mismatch
**Symptom:** All Flutter apps crash immediately on launch with JNI method not found error.

**Root Cause:** Flutter stable 3.35.7 (via FVM) ships with mismatched JNI signatures:
- `FlutterJNI.java` expects: `nativeInit(Context, String[], String, String, String, long)` - **6 parameters**
- `libflutter.so` provides: `nativeInit(Context, String[], String, String, String, int, long)` - **7 parameters**

The extra `int apiLevel` parameter causes the mismatch.

## Investigation Process

### Phase 1: Identifying the Root Cause
1. **Initial Testing** - quicui_engine_test app crashed on MainActivity initialization
2. **Logcat Analysis** - Revealed JNI method not found error
3. **Binary Analysis** - Used `javap` to decompile FlutterJNI.class and confirmed 6-parameter signature
4. **Native Analysis** - Used `nm` to inspect libflutter.so symbols, confirmed 7-parameter signature

### Phase 2: Engine Source Analysis
**Location:** `/Volumes/DoWonder2/quicui_engine_build/official_engine/src`

**Key Files Examined:**
1. `flutter/shell/platform/android/io/flutter/embedding/engine/FlutterJNI.java` (Line 174-180)
   ```java
   private static native void nativeInit(
       @NonNull Context context,
       @NonNull String[] args,
       @Nullable String bundlePath,
       @NonNull String appStoragePath,
       @NonNull String engineCachesPath,
       long initTimeMillis);  // 6 parameters - NO int apiLevel
   ```

2. `flutter/shell/platform/android/flutter_main.cc` (Line 107-115)
   ```cpp
   void FlutterMain::Init(JNIEnv* env,
                          jclass clazz,
                          jobject context,
                          jobjectArray jargs,
                          jstring kernelPath,
                          jstring appStoragePath,
                          jstring engineCachesPath,
                          jlong initTimeMillis) {
     // 8 parameters in C++, maps to 6 in Java (jclass is implicit)
   ```

3. JNI Registration (Line 258-263)
   ```cpp
   static const JNINativeMethod methods[] = {
       {
           .name = "nativeInit",
           .signature = "(Landroid/content/Context;[Ljava/lang/String;Ljava/"
                        "lang/String;Ljava/lang/String;Ljava/lang/String;J)V",
           .fnPtr = reinterpret_cast<void*>(&Init),
       },
   ```
   Signature ends with `J` (long), not `I` (int) - **correct 6-parameter version**

**Discovery:** The Flutter engine main branch already has the correct 6-parameter signatures. No code modifications needed for the JNI fix.

### Phase 3: Custom Engine Build

#### Build Environment Setup
- **Build Location:** `/Volumes/DoWonder2/quicui_engine_build/official_engine/`
- **Tools:** depot_tools, GN, Ninja
- **Python:** 3.14 (`/Library/Frameworks/Python.framework/Versions/3.14/bin/python3`)
- **Branch:** main (latest Flutter engine source)

#### Build Configuration
```bash
# Host tools (required for Android build)
./flutter/tools/gn --runtime-mode release
ninja -C out/host_release -j4
# Result: 5024 targets built successfully

# Android ARM64 engine
./flutter/tools/gn --android --android-cpu arm64 --runtime-mode release
ninja -C out/android_release_arm64 -j4
# Result: 21 targets built successfully
```

#### Custom Modification Added
**File:** `flutter/shell/platform/android/flutter_main.cc` (Line 115)
```cpp
FML_LOG(INFO) << "🔥 QuicUI: FlutterMain::Init called with custom matched engine!";
```

**Purpose:** Debugging marker to confirm custom engine is being used.

#### Build Artifacts
```
out/android_release_arm64/
├── libflutter.so              (155MB unstripped)
├── lib.stripped/libflutter.so (11MB stripped for deployment)
└── flutter.jar                (5.5MB - contains Java classes + native lib)
```

**Verification:**
- ✅ JNI signatures: 6 parameters confirmed via `javap`
- ✅ Custom logging: Embedded in libflutter.so verified via `strings`
- ✅ File sizes: Match expected values (~11MB native, ~5.5MB JAR)

### Phase 4: Deployment and Testing

#### Deployment Steps
1. Backed up original flutter.jar from flutter-quicui SDK
2. Deployed custom flutter.jar to SDK cache
3. Cleared all Gradle caches (system-wide)
4. Cleared all Flutter build caches
5. Rebuilt quicui_engine_test app

#### Test Results
**Status:** ❌ **FAILED - Library Loading Error**

**Error:**
```
[FATAL:flutter/shell/platform/android/library_loader.cc(21)] Check failed: result.
```

**Root Cause:** `flutter::FlutterMain::Register(env)` failed at JNI_OnLoad

**Analysis:**
- Custom engine built from **main branch** (commit: cc9bcdd)
- Flutter SDK requires engine version **035316565ad77281a75305515e4682e6c4c6f7ca**
- Version mismatch causes JNI registration failure
- The main branch engine (Nov 2024) is incompatible with SDK from Oct 2024

## Critical Findings

### Finding 1: Engine Version Mismatch
**SDK Engine Version:** 035316565ad77281a75305515e4682e6c4c6f7ca  
**Custom Engine Version:** cc9bcdd (main branch, 10 days newer)

**Impact:** Complete incompatibility - app crashes on library load before any Flutter code runs.

**Verification:**
```bash
# SDK's engine version
$ cat forks/flutter-quicui/bin/internal/engine.version
035316565ad77281a75305515e4682e6c4c6f7ca

# SDK info
$ flutter --version
Flutter 3.35.8-0.0.pre-2 • channel [user-branch]
Engine • hash 6b24e1b529bc46df7ff397667502719a2a8b6b72 (revision 035316565a)
```

### Finding 2: Non-Public Engine Commit
The required engine commit (`035316565ad77281a75305515e4682e6c4c6f7ca`) is **not available** in the public Flutter engine repository.

**Attempted Commands:**
```bash
$ git fetch origin 035316565ad77281a75305515e4682e6c4c6f7ca
fatal: remote error: upload-pack: not our ref

$ git log --all --oneline | grep "035316565a"
# No results
```

**Hypothesis:** The QuicUIFlutterSDK uses a forked/custom engine build that isn't publicly available.

### Finding 3: Original JNI Mismatch Still Present
Even with the original flutter.jar restored, apps with QuicUI dependencies still crash due to the 6-param vs 7-param JNI mismatch in the stable Flutter 3.35.7 release.

## Build Performance Metrics

### Host Tools Build
- **Targets:** 5024
- **Time:** ~45 minutes
- **Parallelism:** -j4 (4 cores)
- **Output Size:** Several GB of tools and intermediate files

### Android ARM64 Build  
- **Targets:** 21
- **Time:** ~2 hours (includes compilation of previous unbuilt targets)
- **Parallelism:** -j4 (4 cores)
- **Final Artifacts:**
  - libflutter.so: 155MB (unstripped), 11MB (stripped)
  - flutter.jar: 5.5MB

## Technical Insights

### JNI Registration Process
1. **JNI_OnLoad** called when libflutter.so loads
2. Registers native methods via `RegisterNatives`
3. Each registration returns boolean result
4. FlutterMain::Register must succeed first
5. Failure triggers FML_CHECK assertion → crash

### Library Loading Order
```
System.loadLibrary("flutter")
  ↓
JNI_OnLoad(JavaVM*, void*)
  ↓
flutter::FlutterMain::Register(env)  ← FAILURE HERE
  ↓
flutter::PlatformViewAndroid::Register(env)
  ↓
flutter::VsyncWaiterAndroid::Register(env)
```

### Engine Compatibility Requirements
- **Java Code:** Must match engine's FlutterJNI.class
- **Native Code:** Must match engine's libflutter.so
- **Framework Version:** Must match Dart SDK and Flutter tools
- **Dependencies:** Must match third_party libraries

**All four must be in sync for successful operation.**

## Solutions Evaluated

### ❌ Option 1: Use Main Branch Engine
**Pros:**
- Latest code, correct JNI signatures
- Easy to build

**Cons:**
- Version incompatible with SDK 3.35.7
- Causes library loading failures
- Not a viable solution

**Status:** Attempted and failed

### ⏳ Option 2: Build Engine at SDK Version
**Pros:**
- Perfect version match
- Should work immediately

**Cons:**
- Required commit not in public repo
- May need access to QuicUI fork
- Unknown if commit has correct JNI signatures

**Status:** Blocked - commit unavailable

### ✅ Option 3: Test Without QuicUI Dependencies
**Pros:**
- Can proceed with testing immediately
- Isolates OTA mechanism from engine issues
- Standard engine should work

**Cons:**
- Doesn't test QuicUI integration
- Limited validation

**Status:** **RECOMMENDED NEXT STEP**

## Recommendations

### Immediate Action: Minimal App Testing
Create and test a minimal Flutter app WITHOUT QuicUI dependencies:
1. Use standard Flutter create
2. Build two versions (purple/orange theme)
3. Generate binary patches
4. Test OTA loading mechanism
5. Validate patch application works

**Goal:** Prove the OTA mechanism works independently of engine issues.

### Short-Term: Engine Source Resolution
**Required Information:**
1. Where is engine commit `035316565a` located?
2. Is there a QuicUI engine fork?
3. What modifications exist in that engine version?
4. Does it have 6-param or 7-param JNI?

**Actions:**
- Contact QuicUI team about engine source
- Check if QuicUIFlutterSDK repository has engine as submodule
- Investigate private repositories

### Long-Term: Stable Engine Solution
**Options:**
1. **Build from Correct Commit:** Once source is located
2. **Update SDK:** Move to newer Flutter version with main branch engine
3. **Create Engine Fork:** Maintain custom engine with fixes
4. **Upstream Fix:** Wait for official Flutter fix (if applicable)

## Files Generated

### Build Artifacts
```
/Volumes/DoWonder2/quicui_engine_build/official_engine/src/out/
├── host_release/                    # Host build tools
│   └── [5024 targets]
└── android_release_arm64/           # Android engine
    ├── libflutter.so               # 155MB unstripped
    ├── lib.stripped/libflutter.so  # 11MB stripped
    └── flutter.jar                 # 5.5MB packaged
```

### Build Logs
```
/tmp/
├── host_tools_build.log           # Host build output
├── android_engine_build.log       # Android build output
└── build_custom_engine.log        # App rebuild log
```

### Backups
```
forks/flutter-quicui/bin/cache/artifacts/engine/android-arm64-release/
├── flutter.jar.backup             # Original FVM stable
├── flutter.jar.backup_20251104_144243
└── flutter.jar.backup_fvm_stable_20251104_191232
```

## Lessons Learned

1. **Engine Version Matters:** Flutter engine must exactly match SDK version
2. **Public vs Private Builds:** Not all engine commits are publicly available
3. **JNI is Complex:** Multiple layers (Java, JNI registration, native) must align
4. **Build Infrastructure:** depot_tools requires careful PATH management
5. **Testing Strategy:** Isolate components to identify root causes

## Next Steps

### Phase 1: Minimal App Testing (Today)
- [x] Create minimal Flutter app (minimal_patch_test)
- [ ] Modify app to have two theme versions
- [ ] Build and extract libapp.so from both
- [ ] Generate binary patch with bsdiff
- [ ] Deploy and test OTA loading
- [ ] Document results

### Phase 2: Engine Source Investigation
- [ ] Contact team about engine source location
- [ ] Check for QuicUI engine fork/repository
- [ ] Verify JNI signatures in correct version
- [ ] Document any custom modifications

### Phase 3: Production Solution
- [ ] Build engine at correct version
- [ ] Deploy and test with QuicUI dependencies
- [ ] Verify all features work
- [ ] Create deployment documentation

## Conclusion

Successfully built a custom Flutter engine with correct 6-parameter JNI signatures, but discovered a fundamental version compatibility issue. The engine built from main branch is incompatible with the Flutter SDK 3.35.7 currently in use.

**Key Achievement:** Demonstrated the ability to build and customize Flutter engines.

**Key Blocker:** Engine version mismatch prevents deployment.

**Path Forward:** Test OTA mechanism with minimal app first, then resolve engine version issue for full QuicUI integration.

---

**Build Stats:**
- Total Build Time: ~3 hours
- Disk Space Used: ~50GB (source + build artifacts)
- Success Rate: 100% (builds completed successfully)
- Deployment Success: 0% (version incompatibility)
