# Engine Rebuild Instructions

## Overview
After fixing the hash calculation in `quicui_patch_loader.cc`, the engine needs to be rebuilt to generate the iOS framework with the corrected code.

## Modified Files
- `engine/src/flutter/shell/common/quicui_patch_loader.cc`
  - Added CommonCrypto include
  - Added iomanip include  
  - Replaced `popen("shasum")` with `CC_SHA256` functions

## Rebuild Commands

### 1. Navigate to Engine Directory
```bash
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1
```

### 2. Clean Previous Build (Optional but Recommended)
```bash
# Remove old build artifacts for iOS
rm -rf engine/src/out/ios_debug
rm -rf engine/src/out/ios_profile
rm -rf engine/src/out/ios_release
```

### 3. Build iOS Engine (Release Mode)
```bash
cd engine/src
./flutter/tools/gn --ios --runtime-mode release --ios-cpu arm64
ninja -C out/ios_release
```

**Estimated time**: 1-2 hours (depending on Mac specs)

### 4. Copy Framework to Project
After build completes, copy the framework:
```bash
# Backup old framework
cp -r /Users/admin/Documents/quicui2/forks/flutter-quicui/bin/cache/artifacts/engine/ios-release/Flutter.xcframework \
     /Users/admin/Documents/quicui2/forks/flutter-quicui/bin/cache/artifacts/engine/ios-release/Flutter.xcframework.backup_before_hash_fix

# Copy new framework
cp -r engine/src/out/ios_release/Flutter.xcframework \
     /Users/admin/Documents/quicui2/forks/flutter-quicui/bin/cache/artifacts/engine/ios-release/
```

### 5. Rebuild Test App
```bash
cd /Users/admin/Documents/quicui2/packages/quicui_cli

# Build v3.0.45 with new engine (Build 26)
dart run bin/quicui.dart build-ipa --version 3.0.45 --build-number 26 -p ../../test_apps/quicui_production_test
```

### 6. Install and Test
```bash
# Install new build
xcrun devicectl device install app --device 653324F8-D2E4-5A3A-BC77-C7C601AA9433 \
  /Users/admin/Documents/quicui2/test_apps/quicui_production_test/build/ios/iphoneos/Runner.app

# The patch (ID: 1764327189870) is already on the server
# Just restart the app and check logs
```

## Expected Result

After installing the new build with fixed engine:
1. Launch app → Download patch (already exists on server)
2. Restart app → Should show:
   ```
   [INFO] QuicUI: Patch file exists, size: 4113328 bytes
   [INFO] QuicUI: Calculating hash for validation...
   [INFO] QuicUI: Hash: bc5201f1a228013021fdee9a7969f1b6574a509b34665338adea3c9527bfcf12
   [INFO] QuicUI: Hash validation: PASSED ✅
   [INFO] QuicUI: Loading patch from: .../dlc.vmcode
   ```
3. App should display **pink/purple gradient** (patch loaded successfully)

## Verification Checklist

- [ ] Engine rebuilt successfully
- [ ] Framework copied to project
- [ ] App rebuilt with new engine (Build 26)
- [ ] App installed on device
- [ ] Patch downloaded (reuse existing ID: 1764327189870)
- [ ] App restarted
- [ ] Logs show hash validation PASSED
- [ ] Pink/purple gradient displays
- [ ] No "Hash mismatch" error

## Troubleshooting

### If build fails:
```bash
# Check for syntax errors
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/shell/common
# Verify includes are correct
head -20 quicui_patch_loader.cc
```

### If hash still fails:
- Verify CommonCrypto include is present
- Check that `#ifdef __APPLE__` surrounds CommonCrypto code
- Ensure iomanip is included for std::setw/setfill

## Time Estimates
- Engine rebuild: 1-2 hours
- App rebuild: 2-3 minutes  
- Install and test: 5 minutes
- **Total: ~1.5-2 hours**

## Alternative: Quick Test Without Full Rebuild

If you want to verify the fix works before full rebuild:
1. Create a minimal test program that uses CommonCrypto
2. Calculate hash of the patch file
3. Compare with expected hash: `bc5201f1a228013021fdee9a7969f1b6574a509b34665338adea3c9527bfcf12`
