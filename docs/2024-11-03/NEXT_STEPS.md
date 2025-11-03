# QuicUI Next Steps - Quick Reference

## Current Status: Code Complete ✅
All Rust, C++, and BUILD.gn changes are done. Ready for build testing.

## Immediate Next Action: Build Engine

### Step 1: Configure Build
```bash
cd /Volumes/DoWonder2/quicui_engine_build/engine_full/src
export PATH="/Volumes/DoWonder2/quicui_engine_build/depot_tools:$PATH"

# Configure for Android ARM64 release
./flutter/tools/gn --android --android-cpu arm64 --runtime-mode release
```

### Step 2: Build Engine
```bash
# Build with 8 parallel jobs
ninja -C out/android_release -j8

# Monitor for errors related to:
# - quicui_updater header not found
# - Rust library linking issues
# - Missing dependencies
```

### Common Build Fixes

#### If header not found:
```bash
# Verify header was copied
ls -la flutter/shell/common/quicui/quicui_updater.h

# If missing, copy again
cp third_party/quicui_updater/target/release/build/*/out/quicui_updater.h \
   flutter/shell/common/quicui/
```

#### If Rust library not found:
```bash
# Verify Rust library exists
ls -la third_party/quicui_updater/target/release/libquicui_updater.a

# Rebuild if needed
cd third_party/quicui_updater
source "$HOME/.cargo/env"
cargo build --release
cd ../../..
```

#### If BUILD.gn path wrong:
Update `third_party/quicui_updater/BUILD.gn` line with correct hash:
```gn
sources = [ "target/release/build/quicui_updater-ACTUAL_HASH/out/quicui_updater.h" ]
```

## After Successful Build

### Step 3: Copy Engine Artifacts
```bash
# Find Flutter SDK cache
FLUTTER_CACHE="$HOME/.gradle/caches/modules-2/files-2.1/io.flutter/flutter_embedding_release"
ENGINE_VERSION="1.0.0-abcd1234"  # From build

# Copy flutter.jar
cp out/android_release/flutter.jar \
   "$FLUTTER_CACHE/$ENGINE_VERSION/*/flutter_embedding_release-$ENGINE_VERSION-release.jar"

# Alternatively, replace in Flutter SDK directly
cp out/android_release/flutter.jar \
   /Users/admin/Documents/quicui2/forks/flutter-official/bin/cache/artifacts/engine/android-arm64-release/
```

### Step 4: Test Build
```bash
cd /Users/admin/Documents/quicui2/test_apps/test_app_fresh

# Use modified Flutter SDK
export PATH="/Users/admin/Documents/quicui2/forks/flutter-official/bin:$PATH"

# Build APK
flutter build apk --release

# Check logs for QuicUI initialization
adb logcat | grep QuicUI
```

## Expected Logs

### On App Launch (if working):
```
I/flutter: QuicUI: Initializing updater
I/flutter: QuicUI: code_cache_path: /data/user/0/com.example.app/code_cache
I/flutter: QuicUI: app_storage_path: /data/user/0/com.example.app/files
I/flutter: QuicUI: version: 1.0.0
I/flutter: QuicUI: Updater initialized successfully
I/flutter: QuicUI: No patch available, using base library
```

### On Second Launch (after patch download):
```
I/flutter: QuicUI: Initializing updater
I/flutter: QuicUI: Found patch to load: /data/.../code_cache/quicui_updater/2.full
I/flutter: QuicUI: Patched library will be loaded instead of base
I/flutter: QuicUI: Current patch number: 2
```

## File Locations Reference

### Engine Source
- **Main:** `/Volumes/DoWonder2/quicui_engine_build/engine_full/src/`
- **Rust:** `third_party/quicui_updater/`
- **C++:** `flutter/shell/common/quicui/`
- **Android:** `flutter/shell/platform/android/flutter_main.cc`

### Build Output
- **Artifacts:** `out/android_release/`
- **flutter.jar:** `out/android_release/flutter.jar`
- **Rust lib:** `third_party/quicui_updater/target/release/libquicui_updater.a`

### Test App
- **Location:** `/Users/admin/Documents/quicui2/test_apps/test_app_fresh/`
- **Backend:** `http://192.168.20.100:8080`
- **Device:** `BLZ5GBY23JB034715`

## Troubleshooting

### Build Error: "fatal error: 'quicui_updater.h' file not found"
**Fix:** Copy header to correct location
```bash
cd /Volumes/DoWonder2/quicui_engine_build/engine_full/src
cp third_party/quicui_updater/target/release/build/*/out/quicui_updater.h \
   flutter/shell/common/quicui/
```

### Build Error: "undefined reference to quicui_init"
**Fix:** Rust library not linked properly
1. Check BUILD.gn has correct target
2. Verify libquicui_updater.a exists
3. Try full rebuild: `ninja -C out/android_release -t clean && ninja -C out/android_release`

### Runtime: App crashes on launch
**Check:**
1. `adb logcat | grep -E "QuicUI|FATAL"`
2. Look for missing symbols or library load failures
3. Verify engine version matches

### Runtime: Patch not loading
**Check:**
1. state.json exists: `adb shell cat /data/data/com.quicui.test_app_fresh/files/quicui_updater/state.json`
2. Patch file exists: `adb shell ls -l /data/data/com.quicui.test_app_fresh/code_cache/quicui_updater/`
3. Backend registered patch correctly

## Documentation

- **Rust Implementation:** `docs/2024-11-03/RUST_UPDATER_IMPLEMENTATION.md`
- **Integration Complete:** `docs/2024-11-03/ENGINE_INTEGRATION_COMPLETE.md`
- **Shorebird Analysis:** `docs/SHOREBIRD_ANALYSIS.md`

## Modified Files List

```
✓ third_party/quicui_updater/BUILD.gn
✓ third_party/quicui_updater/Cargo.toml
✓ third_party/quicui_updater/library/Cargo.toml
✓ third_party/quicui_updater/library/build.rs
✓ third_party/quicui_updater/library/src/lib.rs
✓ third_party/quicui_updater/library/src/updater.rs
✓ third_party/quicui_updater/library/src/state.rs
✓ third_party/quicui_updater/library/src/patch.rs
✓ third_party/quicui_updater/library/src/android.rs
✓ flutter/shell/common/quicui/quicui.h
✓ flutter/shell/common/quicui/quicui.cc
✓ flutter/shell/common/quicui/quicui_updater.h (copied)
✓ flutter/shell/common/BUILD.gn (modified)
✓ flutter/shell/platform/android/flutter_main.cc (modified)
```

## Success Checklist

- [ ] Engine builds without errors
- [ ] Test app builds without errors
- [ ] App launches successfully
- [ ] QuicUI logs appear in logcat
- [ ] Patch can be downloaded
- [ ] Patch applies correctly
- [ ] **Counter appears after restart** ✨

---
**Ready to proceed with:** `ninja -C out/android_release -j8`
