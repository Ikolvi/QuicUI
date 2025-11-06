# Flutter Engine Rebuild Plan for QuicUI OTA
**Date:** November 3, 2025  
**Status:** 🔄 In Progress  
**Goal:** Build Flutter engine with QuicUI modifications that matches forked SDK version

---

## Current Situation

### ✅ What We Have
1. **Forked Flutter SDK**: `~/Documents/quicui2/forks/flutter-quicui/`
   - Version: 3.35.8-0.0.pre-2 (based on Flutter 3.35.7 stable)
   - Branch: quicui-codepush
   - Remote: git@github.com:Ikolvi/QuicUIFlutterSDK.git
   - Dart Version: 3.9.2
   - SDK Commit: 035316565ad (October 21, 2024)

2. **Engine Built (Wrong Version)**: `/Volumes/DoWonder2/quicui_engine_build/official_engine/`
   - Current Commit: ae5c3603d013 (February 25, 2025) - **TOO NEW**
   - Dart SDK: 3.9 (but at language level 3.7)
   - Status: Built successfully with QuicUI modifications
   - Size: 158MB libflutter.so, 8.2MB gen_snapshot, 40MB flutter_tester
   - **Problem**: Dart language version mismatch - SDK requires 3.8+, engine supports only 3.7

3. **QuicUI Modifications Applied**:
   - ✅ Rust updater: `flutter/third_party/quicui_updater/`
   - ✅ C++ wrapper: `flutter/shell/common/quicui/`
   - ✅ Engine integration: `flutter_main.cc` with ConfigureQuicUI function
   - ✅ Build system: Updated BUILD.gn files
   - ✅ Path fix: Corrected `../../third_party/` (not `../../flutter/third_party/`)
   - ✅ Include fix: Added `<sys/stat.h>` to flutter_main.cc

### ❌ The Problem
**Version Mismatch**: 
- Our built engine (Feb 2025) is **4 months newer** than the forked SDK (Oct 2024)
- SDK expects Dart language version 3.8+
- Our engine only supports Dart 3.7 (even though Dart SDK is 3.9)
- Using `--local-engine` causes hundreds of compilation errors:
  ```
  Error: The language version 3.8 specified for the package 'flutter' is too high. 
  The highest supported language version is 3.7.
  ```

### 🎯 The Solution
**Build engine from October 2024** that matches the forked SDK's expected version.

---

## Engine Version Detective Work

### SDK Version Information
From `~/Documents/quicui2/forks/flutter-quicui/bin/cache/flutter.version.json`:
```json
{
  "frameworkVersion": "3.35.8-0.0.pre-2",
  "engineRevision": "035316565ad77281a75305515e4682e6c4c6f7ca"
}
```

**IMPORTANT DISCOVERY**: The `engineRevision` field contains **035316565ad77281a75305515e4682e6c4c6f7ca**, which is actually the **Flutter SDK commit**, NOT the engine commit. This is a custom/modified version indicator.

### Finding the Correct Engine Commit

From Flutter 3.35.7 stable (commit adc90106255), the `bin/internal/engine.version` file contains:
```
035316565ad77281a75305515e4682e6c4c6f7ca
```

This appears to be the Flutter framework commit that was used, not a standard engine commit hash.

### Engine Commits from October 2024

Checking engine repository for October 20-22, 2024 timeframe:
```bash
cd /Volumes/DoWonder2/quicui_engine_build/official_engine/src/flutter
git log --since="2024-10-20" --until="2024-10-22" --oneline
```

Key commits from that period:
- `2410cdf12c` - Roll Skia (Oct 21)
- `1df749a00e` - Roll Skia (Oct 21)
- `b3205a28d0` - Flutter GPU fix (Oct 21)
- `64a015c740` - Roll Dart SDK (Oct 21)
- `91f4bc7424` - Roll Skia (Oct 21)

**Target Commit**: Let's use **`1df749a00e`** from October 21, 2024 as our baseline, which aligns with the SDK date.

---

## Build Plan

### Step 1: Checkout Correct Engine Version
```bash
cd /Volumes/DoWonder2/quicui_engine_build/official_engine/src/flutter
git fetch origin
git checkout 1df749a00e  # October 21, 2024
git log -1 --format="%H %ci %s"
```

**Expected Output**:
```
1df749a00e... 2024-10-21 ... Roll Skia from c89324dd8f6e to b11804aaabbb (1 revision)
```

### Step 2: Sync Dependencies
```bash
cd /Volumes/DoWonder2/quicui_engine_build/official_engine
export PATH="/Volumes/DoWonder2/quicui_engine_build/depot_tools:$PATH"
gclient sync -D
```

**Duration**: ~30-45 minutes (only updates changed dependencies)

### Step 3: Reapply QuicUI Modifications

#### 3a. Copy Rust Updater
```bash
# Source: Previous engine build or backup
# Destination: flutter/third_party/quicui_updater/

cd /Volumes/DoWonder2/quicui_engine_build/official_engine/src/flutter/third_party
# Verify quicui_updater directory exists with:
# - BUILD.gn
# - Cargo.toml
# - library/ (with src/lib.rs)
# - target/aarch64-linux-android/release/libquicui_updater.a

ls -la quicui_updater/
```

#### 3b. Copy C++ Wrapper
```bash
cd /Volumes/DoWonder2/quicui_engine_build/official_engine/src/flutter/shell/common
# Verify quicui directory exists with:
# - quicui.h
# - quicui.cc
# - quicui_updater.h (generated)

ls -la quicui/
```

#### 3c. Modify flutter_main.cc
**File**: `flutter/shell/platform/android/flutter_main.cc`

Add at top (around line 10):
```cpp
#include <sys/stat.h>
```

Add ConfigureQuicUI function (around line 58):
```cpp
static void ConfigureQuicUI(const std::string& code_cache_path,
                             flutter::Settings& settings) {
  __android_log_print(ANDROID_LOG_INFO, "QuicUI", 
                      "ConfigureQuicUI: Checking for patched library...");
  
  std::string patches_dir = code_cache_path + "/quicui_patches";
  std::string patched_lib = patches_dir + "/libapp_patched_arm64-v8a.so";
  
  __android_log_print(ANDROID_LOG_INFO, "QuicUI", 
                      "ConfigureQuicUI: Looking for patch at: %s", 
                      patched_lib.c_str());
  
  struct stat buffer;
  if (stat(patched_lib.c_str(), &buffer) == 0) {
    __android_log_print(ANDROID_LOG_INFO, "QuicUI", 
                        "ConfigureQuicUI: ✅ Patched library found! Size: %lld bytes", 
                        (long long)buffer.st_size);
    
    settings.application_library_path.clear();
    settings.application_library_path.emplace_back(patched_lib);
    
    __android_log_print(ANDROID_LOG_INFO, "QuicUI", 
                        "ConfigureQuicUI: ✅ Configured Flutter to load patched AOT snapshot from: %s", 
                        patched_lib.c_str());
  } else {
    __android_log_print(ANDROID_LOG_INFO, "QuicUI", 
                        "ConfigureQuicUI: No patched library found, using original libapp.so");
  }
}
```

Call ConfigureQuicUI BEFORE g_flutter_main.reset (around line 204):
```cpp
#if FLUTTER_RELEASE
  auto code_cache_path = fml::jni::JavaStringToString(env, engineCachesPath);
  ConfigureQuicUI(code_cache_path, settings);
#endif

  g_flutter_main.reset(new FlutterMain(settings));  // ← VM initialized HERE
```

#### 3d. Update BUILD.gn Files

**File**: `flutter/shell/common/BUILD.gn`

Add to sources (around line 128):
```gn
source_set("common") {
  sources = [
    # ... existing sources
    "quicui/quicui.cc",
    "quicui/quicui.h",
  ]
```

Add to deps (around line 154):
```gn
  deps = [
    # ... existing deps
    "//flutter/third_party/quicui_updater:quicui_updater",
  ]
```

**File**: `flutter/third_party/quicui_updater/BUILD.gn`

**CRITICAL FIX** - Correct path:
```gn
libs = [
  "$root_out_dir/libquicui_updater.a",
  "../../third_party/android_tools/...",  # ✅ CORRECT
  # NOT: "../../flutter/third_party/android_tools/..."  # ❌ WRONG
]
```

### Step 4: Verify Modifications
```bash
# Check flutter_main.cc
grep -c "ConfigureQuicUI" /Volumes/DoWonder2/quicui_engine_build/official_engine/src/flutter/shell/platform/android/flutter_main.cc
# Expected: 7 (function + calls + comments)

# Check BUILD.gn
grep "quicui.cc" /Volumes/DoWonder2/quicui_engine_build/official_engine/src/flutter/shell/common/BUILD.gn
grep "quicui_updater" /Volumes/DoWonder2/quicui_engine_build/official_engine/src/flutter/shell/common/BUILD.gn

# Check quicui_updater BUILD.gn path
grep "third_party/android_tools" /Volumes/DoWonder2/quicui_engine_build/official_engine/src/flutter/third_party/quicui_updater/BUILD.gn
# Should show: ../../third_party/ (NOT ../../flutter/third_party/)
```

### Step 5: Configure Build
```bash
cd /Volumes/DoWonder2/quicui_engine_build/official_engine/src
export PATH="/Volumes/DoWonder2/quicui_engine_build/depot_tools:$PATH"

# Android ARM64
./flutter/tools/gn --android --android-cpu arm64 --runtime-mode release

# Host tools
./flutter/tools/gn --runtime-mode release
```

**Expected Output**:
```
Done. Made 1092 targets from 338 files in ~30s
```

### Step 6: Build Android Engine
```bash
cd /Volumes/DoWonder2/quicui_engine_build/official_engine/src
export PATH="/Volumes/DoWonder2/quicui_engine_build/depot_tools:$PATH"

ninja -C out/android_release_arm64 -j4 2>&1 | tee /tmp/android_build_oct2024.log
```

**Duration**: ~45-60 minutes  
**Targets**: 4352 total  
**Expected Output**:
- `libflutter.so`: ~158MB
- Contains ConfigureQuicUI strings

**Verification**:
```bash
ls -lh out/android_release_arm64/libflutter.so
strings out/android_release_arm64/libflutter.so | grep ConfigureQuicUI
```

### Step 7: Build Host Tools
```bash
ninja -C out/host_release -j4 2>&1 | tee /tmp/host_build_oct2024.log
```

**Duration**: ~30-45 minutes  
**Targets**: 8292 total  
**Expected Output**:
- `gen_snapshot`: ~8MB
- `flutter_tester`: ~40MB
- `dart-sdk/`: Complete SDK

### Step 8: Build Test App with Custom Engine
```bash
cd ~/Documents/quicui2/test_apps/test_app_fresh

# Clean first
~/Documents/quicui2/forks/flutter-quicui/bin/flutter clean
rm -rf android/.gradle android/app/build build

# Build with local engine
~/Documents/quicui2/forks/flutter-quicui/bin/flutter build apk --release \
  --local-engine=android_release_arm64 \
  --local-engine-host=host_release \
  --local-engine-src-path=/Volumes/DoWonder2/quicui_engine_build/official_engine/src
```

**Expected**: APK builds successfully with NO language version errors

**Verification**:
```bash
# Extract and check libflutter.so
cd /tmp && rm -rf apk_verify && mkdir apk_verify && cd apk_verify
unzip -q ~/Documents/quicui2/test_apps/test_app_fresh/build/app/outputs/flutter-apk/app-release.apk
strings lib/arm64-v8a/libflutter.so | grep ConfigureQuicUI
# Should show 5-7 lines with ConfigureQuicUI messages
```

---

## Alternative: Find Official Flutter 3.35.7 Engine

If the above commit doesn't work, we can find the official engine commit for Flutter 3.35.7 stable:

```bash
# Clone Flutter SDK stable branch
git clone https://github.com/flutter/flutter.git --branch stable --depth=1 /tmp/flutter_stable_check
cat /tmp/flutter_stable_check/bin/internal/engine.version

# Checkout that engine version
cd /Volumes/DoWonder2/quicui_engine_build/official_engine/src/flutter
git checkout <hash-from-engine.version>
```

---

## Success Criteria

### Build Success
- [  ] Engine checked out to October 2024 commit
- [  ] gclient sync completed without errors
- [  ] All QuicUI modifications reapplied
- [  ] Android engine builds successfully (4352 targets)
- [  ] Host tools build successfully (8292 targets)
- [  ] ConfigureQuicUI strings present in libflutter.so
- [  ] Test app builds with `--local-engine` **without language version errors**
- [  ] APK contains our custom libflutter.so with QuicUI

### Runtime Success (After Install)
- [  ] App launches successfully (v1.0.0)
- [  ] Logcat shows: `"ConfigureQuicUI: Checking for patched library..."`
- [  ] Logcat shows: `"ConfigureQuicUI: No patched library found, using original libapp.so"`
- [  ] Patch downloads and applies successfully
- [  ] App restart shows: `"ConfigureQuicUI: ✅ Patched library found!"`
- [  ] Purple banner appears (v1.0.1) 🎉

---

## Backup & Recovery

### Before Starting
```bash
# Backup current engine state
cd /Volumes/DoWonder2/quicui_engine_build/official_engine/src/flutter
git log -1 > /tmp/engine_commit_before_rebuild.txt
git stash save "Before October 2024 rebuild"

# Backup modified files
tar -czf /tmp/quicui_modifications_backup.tar.gz \
  flutter/third_party/quicui_updater \
  flutter/shell/common/quicui \
  flutter/shell/platform/android/flutter_main.cc \
  flutter/shell/common/BUILD.gn
```

### If Build Fails
```bash
# Restore to previous state
cd /Volumes/DoWonder2/quicui_engine_build/official_engine/src/flutter
git checkout ae5c3603d013  # Feb 2025 version
gclient sync -D
```

---

## Timeline Estimate

| Task | Duration | Total |
|------|----------|-------|
| Checkout & sync | 30-45 min | 0:45 |
| Reapply modifications | 15-20 min | 1:05 |
| Build Android engine | 45-60 min | 2:05 |
| Build host tools | 30-45 min | 2:50 |
| Build & test app | 5-10 min | 3:00 |
| **Total** | **~3 hours** | |

---

## Key Files Reference

### Locations
| Component | Path |
|-----------|------|
| Engine Source | `/Volumes/DoWonder2/quicui_engine_build/official_engine/src/` |
| Flutter Subdir | `/Volumes/DoWonder2/quicui_engine_build/official_engine/src/flutter/` |
| Forked SDK | `~/Documents/quicui2/forks/flutter-quicui/` |
| Test App | `~/Documents/quicui2/test_apps/test_app_fresh/` |
| depot_tools | `/Volumes/DoWonder2/quicui_engine_build/depot_tools/` |

### Build Outputs
| Artifact | Location |
|----------|----------|
| libflutter.so | `out/android_release_arm64/libflutter.so` |
| gen_snapshot | `out/android_release_arm64/gen_snapshot` |
| flutter_tester | `out/host_release/flutter_tester` |
| dart-sdk | `out/host_release/dart-sdk/` |

---

**Status**: 📋 Plan documented, ready to execute  
**Next Action**: Execute Step 1 - Checkout correct engine version  
**Estimated Completion**: ~3 hours from start

