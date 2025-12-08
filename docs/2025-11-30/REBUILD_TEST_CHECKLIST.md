# iOS Engine Rebuild & Test Checklist
**Date:** 2025-11-30  
**Goal:** Rebuild engine with QUIC differential patch support and test end-to-end

## Pre-Rebuild Verification

- [x] **elf_loader.cc modified**
  - [x] DetectQuicHeaderOffset() function added (44 lines)
  - [x] Dart_LoadELF() modified to use detection
  - [x] Original backed up to docs/2025-11-30/

- [x] **macho_loader.cc modified**
  - [x] DetectQuicHeaderOffset() function added (44 lines)
  - [x] Dart_LoadMachODylib() modified to use detection
  - [x] Original backed up to docs/2025-11-30/

- [x] **Verification commands run**
  ```bash
  grep -n "DetectQuicHeaderOffset" elf_loader.cc
  grep -n "DetectQuicHeaderOffset" macho_loader.cc
  ```

- [x] **Documentation created**
  - [x] ENGINE_MODIFICATIONS_SUMMARY.md
  - [x] QUICK_REBUILD_GUIDE.md
  - [x] IOS_DIFFERENTIAL_PATCH_STATUS.md
  - [x] REBUILD_TEST_CHECKLIST.md (this file)

## Phase 1: Engine Rebuild

### Step 1.1: Navigate to Engine Source
```bash
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src
pwd  # Verify location
```

- [ ] Command executed successfully
- [ ] In correct directory

### Step 1.2: Configure Build
```bash
./flutter/tools/gn --ios --ios-cpu=arm64 --runtime-mode=release --local-engine
```

**Expected output:** `Done. Made X targets from Y files in Zms`

- [ ] Command completed
- [ ] No errors reported
- [ ] Output shows success message

### Step 1.3: Build Engine
```bash
ninja -C out/ios_release
```

**Expected:**
- Duration: 20-40 minutes (first build), 2-5 minutes (incremental)
- Output: `[XXXX/XXXX] STAMP obj/default.stamp`

**Watch for:**
- Compilation errors in elf_loader.cc
- Compilation errors in macho_loader.cc
- Linker errors
- Missing symbols

- [ ] Build started
- [ ] No syntax errors in elf_loader.cc
- [ ] No syntax errors in macho_loader.cc
- [ ] No linker errors
- [ ] Build completed successfully
- [ ] Final output: `[XXXX/XXXX] STAMP obj/default.stamp`

### Step 1.4: Verify Build Output
```bash
# Check framework exists
ls -lh out/ios_release/Flutter.framework/Flutter

# Check size (should be ~50-100 MB)
du -sh out/ios_release/Flutter.framework

# Check for our symbols (may be inlined/optimized)
grep -r "DetectQuicHeaderOffset" out/ios_release/*.o 2>/dev/null || echo "OK - may be inlined"
```

- [ ] Flutter.framework exists
- [ ] Size is reasonable (~50-100 MB)
- [ ] No obvious errors in output

**Build Time:** __________ minutes  
**Build Date:** __________  
**Build Status:** ☐ Success ☐ Failed

**If failed, see rollback section**

## Phase 2: Test App Build

### Step 2.1: Navigate to Test App
```bash
cd /Users/admin/Documents/quicui2/test_apps/quicui_production_test
pwd  # Verify location
```

- [ ] In correct directory

### Step 2.2: Clean Previous Builds
```bash
flutter clean
rm -rf build/
rm -rf ios/Pods/
```

- [ ] Cleaned successfully

### Step 2.3: Build with Modified Engine
```bash
flutter build ios --release \
  --local-engine-src-path=/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src \
  --local-engine=ios_release
```

**Expected:**
- Duration: 2-4 minutes
- Output: App-arm64.ipa or similar

- [ ] Build started
- [ ] Using modified engine (check logs)
- [ ] No errors
- [ ] IPA generated successfully

**Build Time:** __________ minutes  
**IPA Location:** __________  
**Build Status:** ☐ Success ☐ Failed

### Step 2.4: Verify IPA
```bash
# Check IPA exists
ls -lh build/ios/iphoneos/Runner.app

# Check framework inside app
ls -lh build/ios/Release-iphoneos/Runner.app/Frameworks/App.framework/App

# Check size (baseline should be ~4 MB)
du -sh build/ios/Release-iphoneos/Runner.app/Frameworks/App.framework/App
```

- [ ] Runner.app exists
- [ ] App.framework/App exists
- [ ] Size matches baseline (~4 MB)

## Phase 3: Device Installation

### Step 3.1: Connect Device
```bash
# List devices
flutter devices

# Or use ios-deploy
ios-deploy -c
```

**Device Info:**
- Device Name: __________
- Device ID: __________
- iOS Version: __________

- [ ] Device connected
- [ ] Device shows in flutter devices

### Step 3.2: Install Baseline App
```bash
flutter install --device-id=<DEVICE_ID>

# Or use Xcode:
# 1. Open ios/Runner.xcworkspace
# 2. Select physical device
# 3. Product → Run
```

- [ ] Installation started
- [ ] Installation completed
- [ ] App icon visible on device

### Step 3.3: Launch and Verify Baseline
- [ ] App launches successfully
- [ ] UI renders correctly
- [ ] No crashes on startup
- [ ] Version shown: 3.0.60

**Notes:** _________________________________

## Phase 4: Patch Download Test

### Step 4.1: Prepare Device for Logs
```bash
# Terminal 1: Monitor device logs
idevicesyslog | grep -i "quicui\|flutter\|dart"

# Or use Xcode Console:
# Window → Devices and Simulators → Select device → Open Console
# Filter: QuicUI
```

- [ ] Logging started
- [ ] Can see app logs

### Step 4.2: Trigger Update Check
**In App:**
- [ ] Open app
- [ ] Pull to refresh (or use update button)
- [ ] See "Checking for updates..." message

**Watch Logs For:**
- Check request sent
- Server response received
- Patch available: v3.0.61
- Size: 2.1 MB

- [ ] Update check triggered
- [ ] Patch detected (v3.0.61, 2.1 MB)

### Step 4.3: Download Patch
**In App:**
- [ ] Download starts
- [ ] Progress indicator shows
- [ ] Download completes

**Watch Logs For:**
- Download started
- Download progress
- Download completed
- File saved to cache

**Expected:**
- File: patch_3.0.61_ios_arm64.vmcode
- Size: 2.1 MB (uncompressed)
- Location: /cache/code_push/patches/

- [ ] Download started
- [ ] Download completed
- [ ] File saved successfully

**Download Time:** __________ seconds

## Phase 5: Patch Application (CRITICAL TEST)

### Step 5.1: Apply Patch
**In App:**
- [ ] Tap "Apply Update" or "Restart"
- [ ] App closes

**Watch Logs For:**
```
[QuicUI] Installing patch: /cache/.../patch_3.0.61_ios_arm64.vmcode
[QuicUI] Calling Dart_LoadELF...
```

- [ ] Install triggered
- [ ] App closed

### Step 5.2: Watch for QUIC Detection (CRITICAL)
**Expected Logs:**
```
[QuicUI] ✓ Detected QUIC differential patch format
[QuicUI] ✓ Skipping 65536 bytes to reach ELF data
```

**This is THE critical test - if you see these logs, the engine modification worked!**

- [ ] **CRITICAL:** Saw "Detected QUIC differential patch format" log
- [ ] **CRITICAL:** Saw "Skipping 65536 bytes" log
- [ ] No error logs
- [ ] No crash logs

**Log Output:**
```
[Copy actual logs here]
```

### Step 5.3: Verify App Restart
- [ ] App restarted automatically
- [ ] OR manually launched app
- [ ] App launches successfully
- [ ] No crash on startup
- [ ] UI renders correctly

### Step 5.4: Verify Update Applied
- [ ] Version changed to 3.0.61
- [ ] UI changes visible (if any)
- [ ] App functions normally
- [ ] No obvious bugs

**Update Status:** ☐ Success ☐ Failed

## Phase 6: Quality Assurance

### Step 6.1: Basic Functionality
- [ ] Navigate between screens
- [ ] Test main features
- [ ] No crashes
- [ ] No UI glitches
- [ ] Performance acceptable

### Step 6.2: Memory Check
```bash
# Use Xcode Instruments
# Or check Settings → Developer → Memory
```

- [ ] No memory leaks detected
- [ ] Memory usage reasonable
- [ ] No warnings in Instruments

**Memory Usage:** __________ MB

### Step 6.3: Multiple Updates Test
```bash
# Generate another patch (v3.0.61 → v3.0.62)
# Upload to backend
# Test another update cycle
```

- [ ] Second patch generated
- [ ] Second patch uploaded
- [ ] Second update detected
- [ ] Second update downloaded
- [ ] Second update applied
- [ ] App still stable

### Step 6.4: Code Signing Check
```bash
# Check if app is still properly signed
codesign -dvv /path/to/Runner.app

# Should see valid signature, no errors
```

- [ ] App still properly signed
- [ ] No code signing errors
- [ ] No "trust" warnings on device

**Code Signing:** ☐ Valid ☐ Invalid ☐ Warning

## Phase 7: Edge Cases

### Step 7.1: Test with Corrupted Patch
```bash
# Create corrupted patch
cp patch_3.0.61.vmcode patch_corrupted.vmcode
echo "corrupt" >> patch_corrupted.vmcode

# Upload and test
```

- [ ] Corrupted patch rejected by backend
- [ ] OR app handles gracefully (doesn't crash)
- [ ] User sees error message

### Step 7.2: Test with Old Engine
- [ ] Build app with standard Flutter engine (no modifications)
- [ ] Try to apply differential patch
- [ ] Should fail gracefully (no QUIC detection)
- [ ] Falls back to full update

### Step 7.3: Test Offline
- [ ] Disconnect device from internet
- [ ] Try to check for updates
- [ ] Gets appropriate error message
- [ ] App still functional

## Results Summary

### Build Results
- Engine rebuild: ☐ Success ☐ Failed
- Test app build: ☐ Success ☐ Failed
- Device install: ☐ Success ☐ Failed

### Critical Tests
- **QUIC Detection:** ☐ Success ☐ Failed ☐ Not Tested
- **Patch Loading:** ☐ Success ☐ Failed ☐ Not Tested
- **App Update:** ☐ Success ☐ Failed ☐ Not Tested

### Quality Tests
- Memory leaks: ☐ None ☐ Found ☐ Not Tested
- Code signing: ☐ Valid ☐ Invalid ☐ Not Tested
- Performance: ☐ Good ☐ Acceptable ☐ Poor ☐ Not Tested

### Overall Status
☐ **All Tests Passed** - Ready for production  
☐ **Most Tests Passed** - Minor issues to fix  
☐ **Some Tests Failed** - Major issues to investigate  
☐ **Critical Failure** - Rollback required

## Issues Encountered

| Issue | Severity | Status | Notes |
|-------|----------|--------|-------|
| | | | |
| | | | |
| | | | |

## Performance Metrics

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Patch Size | < 500 KB | 2.1 MB | ⚠️ Needs optimization |
| Download Time | < 2 sec | ____ sec | |
| Apply Time | < 1 sec | ____ sec | |
| Memory Overhead | < 10 MB | ____ MB | |
| CPU Usage | < 5% | ____ % | |

## Rollback Procedure

If critical issues found:

### 1. Restore Original Engine
```bash
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/third_party/dart/runtime/bin

cp /Users/admin/Documents/quicui2/docs/2025-11-30/engine_modifications/elf_loader.cc.original elf_loader.cc
cp /Users/admin/Documents/quicui2/docs/2025-11-30/engine_modifications/macho_loader.cc.original macho_loader.cc
```

- [ ] Original files restored

### 2. Rebuild
```bash
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src
ninja -C out/ios_release
```

- [ ] Rebuild completed

### 3. Test with Original Engine
```bash
cd /Users/admin/Documents/quicui2/test_apps/quicui_production_test
flutter build ios --release
flutter install
```

- [ ] App works with original engine
- [ ] Issue confirmed as engine modification problem

## Next Steps

### If All Tests Pass ✅
1. [ ] Document results
2. [ ] Update knowledge base
3. [ ] Plan optimization (reduce patch size)
4. [ ] Test on more devices
5. [ ] Prepare for TestFlight

### If Tests Fail ❌
1. [ ] Document exact failure
2. [ ] Collect crash logs
3. [ ] Analyze engine logs
4. [ ] Debug modifications
5. [ ] Potentially rollback

### Optimization Tasks 📋
1. [ ] Implement byte-level comparison
2. [ ] Add symbol table for baseline references
3. [ ] Add relocations for inter-function calls
4. [ ] Target: < 500 KB patches (currently 2.1 MB)

## Sign-Off

**Engine Rebuild:**
- Completed by: __________
- Date: __________
- Time: __________
- Status: ☐ Success ☐ Failed

**Device Testing:**
- Tested by: __________
- Date: __________
- Device: __________
- Status: ☐ Pass ☐ Fail

**Final Approval:**
- Approved by: __________
- Date: __________
- Ready for: ☐ More Testing ☐ Optimization ☐ Production

---

**Notes:**

_____________________________________________________________
_____________________________________________________________
_____________________________________________________________
