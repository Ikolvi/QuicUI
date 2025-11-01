# QuicUI Code Push - Local Network Testing Guide

**Date**: November 1, 2025  
**Backend**: 192.168.20.100:8080  
**Test App**: quicui_test_app_v1 v1.0.0  
**Build**: QuicUI Flutter SDK Only

---

## 🎯 Testing Overview

This guide provides step-by-step instructions for end-to-end testing of the QuicUI Code Push system on a local network.

### Test Architecture

```
Device (192.168.20.x)
    │
    ├─ Launch App (v1.0.0)
    │
    ├─ Check for Patches
    │   └─> GET 192.168.20.100:8080/api/v1/patches
    │
    ├─ Download Patch (v1.0.1)
    │   └─> Download ~100-500KB patch
    │
    ├─ Verify Patch
    │   └─> Ed25519 signature verification
    │
    ├─ Apply Patch
    │   └─> Dart VM kernel patching
    │
    └─ Display Update
        └─> UI changes appear (no restart needed)
```

---

## 📋 Pre-Test Checklist

### On Development Machine (PC at 192.168.20.100)

- [ ] **QuicUI Backend Running**
  ```bash
  cd /Users/admin/Documents/quicui2/packages/quicui_backend
  dart run lib/quicui_backend.dart
  # Should output: "Server running on http://0.0.0.0:8080"
  ```

- [ ] **Port 8080 is Open**
  ```bash
  # Test if port is listening
  netstat -an | grep 8080
  # Or: sudo lsof -i :8080
  ```

- [ ] **Network Interface Configured**
  ```bash
  # Get IP address
  ifconfig | grep "inet 192.168"
  # Should show: inet 192.168.20.100 ...
  ```

### On Android Device

- [ ] **Connected via USB with ADB**
  ```bash
  adb devices
  # Should list device as "device" (not "offline")
  ```

- [ ] **On Same Network**
  - Device WiFi connected to same network as PC
  - Or: Connected via USB debugging

- [ ] **Development Build Installed**
  - Clear previous app: `adb uninstall com.example.quicui_test_app`

---

## 🏗️ Test Execution Steps

### Phase 1: Build Release APK

**Duration**: 5-10 minutes

```bash
# Navigate to project
cd /Users/admin/Documents/quicui2

# Run build script
./scripts/build_and_test.sh

# Expected Output:
# ✅ Flutter SDK verified
# ✅ Network connectivity checked
# ✅ Dependencies installed
# ✅ APK built successfully
# APK Location: test_apps/quicui_test_app_v1/build/app/outputs/flutter-apk/app-release.apk
```

**What happens**:
1. Flutter SDK verified (should be QuicUI fork)
2. Network connectivity tested to 192.168.20.100:8080
3. Build directory cleaned
4. Dependencies installed
5. Release APK compiled
6. APK verified (size, checksum)

**Artifacts**:
- `app-release.apk` (~50-60MB)
- Build logs in `/tmp/quicui_build_summary.txt`

---

### Phase 2: Install on Device

**Duration**: 2-3 minutes

```bash
# Connect device via USB
# Enable USB debugging on device

# Install APK
cd /Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Expected Output:
# Success
```

**Verification**:
```bash
# Verify installation
adb shell pm list packages | grep quicui
# Should output: package:com.example.quicui_test_app
```

**Troubleshooting**:
- If installation fails: `adb uninstall com.example.quicui_test_app` then retry
- If device not found: `adb devices` and check connection

---

### Phase 3: Launch App and Verify

**Duration**: 2-3 minutes

```bash
# Launch app
adb shell am start -n com.example.quicui_test_app/.MainActivity

# Or: Open app manually on device

# Expected Screen:
# - Title: "QuicUI Code Push Test"
# - App Version: 1.0.0
# - SDK Status: QuicUI (Custom Fork) ✅
# - SDK Info: 3.35.7 (stable)
# - Patch Status: No patches available
# - Button: "Check for Patches"
```

**UI Elements to Verify**:
- ✅ App launches without crashing
- ✅ SDK displays "QuicUI (Custom Fork) ✅"
- ✅ Version shows "1.0.0"
- ✅ All buttons are responsive
- ✅ "Check for Patches" button works

**Test Data Display**:
```
App Version:         1.0.0
SDK Status:          QuicUI (Custom Fork) ✅
SDK Info:            3.35.7 (stable)
Patch Status:        No patches available
Available Patch:     None
Patch Applied:       No
Patch Version:       v1.0.1
Features:            OTA Updates ✨
```

---

### Phase 4: Test Patch Detection

**Duration**: 3-5 minutes

**Step 4a: Prepare Patch on Backend**

```bash
# On PC, create patch metadata in backend
# POST to http://192.168.20.100:8080/api/v1/patches

curl -X POST http://192.168.20.100:8080/api/v1/patches \
  -H "Content-Type: application/json" \
  -d '{
    "appId": "com.example.quicui_test_app",
    "fromVersion": "1.0.0",
    "toVersion": "1.0.1",
    "patchUrl": "http://192.168.20.100:8080/patches/v1.0.1.bin",
    "patchSize": 250000,
    "checksum": "sha256_checksum_here"
  }'

# Expected Response:
# {"success": true, "patchId": "patch_123"}
```

**Step 4b: Tap "Check for Patches" Button**

```
On Device:
1. Tap blue "Check for Patches" button
2. Button shows loading spinner
3. Wait 5-10 seconds for network request
```

**Expected Behavior**:
- Button shows circular progress indicator
- Status updates to "Checking for patches..."
- After 5-10s, status changes to either:
  - "Patches available!" → v1.0.1 detected
  - "No patches available" → No patches on backend

**Network Request Details**:
```
GET http://192.168.20.100:8080/api/v1/patches?appId=com.example.quicui_test_app&version=1.0.0

Expected Response:
{
  "status": "success",
  "patches": [
    {
      "id": "patch_v1.0.1",
      "version": "1.0.1",
      "size": 250000,
      "url": "http://192.168.20.100:8080/patches/v1.0.1.bin"
    }
  ]
}
```

---

### Phase 5: Download and Apply Patch

**Duration**: 5-10 minutes

**Step 5a: Download Patch**

```
On Device:
1. App downloads patch (~250KB)
2. Display shows "Downloading patch..."
3. Progress indicator updates
4. After ~10 seconds: "Patch downloaded successfully"
```

**Step 5b: Verify Patch**

```
On Device:
1. App verifies signature
2. Display shows "Verifying patch..."
3. Ed25519 signature validated
4. Checksum matches
5. Status: "Patch verified"
```

**Step 5c: Apply Patch**

```
On Device:
1. Display shows "Applying patch..."
2. Dart VM patches kernel
3. No app restart needed
4. Status changes to "Patch applied successfully!"
```

**Expected UI Changes After Patch**:
- Text updates appear
- New UI elements visible
- Version info shows "1.0.1"
- "Patch Applied" field shows "Yes ✅"
- All changes instant (no restart)

---

### Phase 6: Verify Post-Patch State

**Duration**: 2-3 minutes

**On Device Screen Should Show**:
```
App Version:         1.0.1 ← Updated
SDK Status:          QuicUI (Custom Fork) ✅
SDK Info:            3.35.7 (stable)
Patch Status:        Patch applied successfully! ✅
Available Patch:     None (already applied)
Patch Applied:       Yes ✅ ← Updated
Patch Version:       v1.0.1 ← Updated
Features:            OTA Updates ✨
```

**Functional Verification**:
- [ ] All buttons still work
- [ ] No crashes or errors
- [ ] Memory usage stable
- [ ] App performance unchanged
- [ ] Data persistence works

---

### Phase 7: Test Rollback (Optional)

**Duration**: 3-5 minutes

```bash
# On Device:
# If app has rollback button:
# 1. Tap "Rollback Patch"
# 2. App reverts to v1.0.0
# 3. Version shows "1.0.0" again
# 4. "Patch Applied" shows "No"
```

**Verification**:
- App reverts to original state
- UI changes disappear
- Version reverts to 1.0.0
- No crashes during rollback

---

## 📊 Test Results Template

Create file: `.azure/TEST_RESULTS_$(date +%Y%m%d).md`

```markdown
# Test Results - November 1, 2025

## Environment
- Backend: 192.168.20.100:8080 ✅ Reachable
- Device: Android 14
- Flutter SDK: 3.35.7 (QuicUI fork) ✅
- App Version: 1.0.0

## Phase 1: Build ✅ SUCCESS
- Duration: X minutes
- APK Size: Y MB
- Checksum: [SHA256]

## Phase 2: Installation ✅ SUCCESS
- Installation time: X seconds
- Device: [Device name]
- Status: Ready

## Phase 3: Launch ✅ SUCCESS
- Launch time: X seconds
- SDK Detection: QuicUI ✅
- Version Display: 1.0.0 ✅

## Phase 4: Patch Detection ✅ SUCCESS
- Network request: OK
- Response time: X ms
- Patches found: 1 (v1.0.1)

## Phase 5: Download & Apply ✅ SUCCESS
- Download time: X seconds
- Patch size: ~250KB
- Verification: PASSED
- Application: SUCCESS

## Phase 6: Post-Patch ✅ SUCCESS
- Version: 1.0.1 ✅
- UI Changes: Visible ✅
- Patch Applied: Yes ✅
- App Stability: STABLE

## Overall Result: ✅ ALL TESTS PASSED
```

---

## 🔍 Verification Checklist

### Network
- [ ] Device can ping 192.168.20.100
- [ ] Port 8080 is accessible
- [ ] HTTP requests work (not blocked)
- [ ] Response times <500ms

### App Functionality
- [ ] App launches successfully
- [ ] SDK detection works correctly
- [ ] Version info displays
- [ ] All buttons responsive

### Patch System
- [ ] Patch detection works
- [ ] Download completes
- [ ] Verification passes
- [ ] Application succeeds
- [ ] No restart needed

### Stability
- [ ] No crashes before patch
- [ ] No crashes during patch
- [ ] No crashes after patch
- [ ] Memory usage stable
- [ ] Performance unchanged

---

## 🐛 Troubleshooting

### Issue: Device Not Found
```bash
# Solution:
adb kill-server
adb start-server
adb devices
```

### Issue: Network Not Reachable
```bash
# Test connectivity:
ping 192.168.20.100

# If failed:
# 1. Verify PC IP: ifconfig | grep 192.168
# 2. Verify device on same network
# 3. Check firewall rules
# 4. Check router connectivity
```

### Issue: APK Installation Fails
```bash
# Solution:
adb uninstall com.example.quicui_test_app
adb install -r app-release.apk
```

### Issue: App Crashes on Launch
```bash
# Check logs:
adb logcat | grep -i "quicui\|crash\|error"

# Reinstall clean:
adb uninstall com.example.quicui_test_app
flutter clean
flutter build apk --release
adb install -r app-release.apk
```

### Issue: Patch Not Detected
```bash
# Verify backend health:
curl http://192.168.20.100:8080/api/v1/health

# Check patch availability:
curl http://192.168.20.100:8080/api/v1/patches?appId=com.example.quicui_test_app&version=1.0.0

# Check app logs:
adb logcat | grep -i "patch"
```

### Issue: Patch Download Fails
```bash
# Verify patch URL:
curl -v http://192.168.20.100:8080/patches/v1.0.1.bin

# Check file size:
ls -lh /path/to/patch/file

# Check checksum:
shasum -a 256 patch-file
```

---

## 📈 Performance Benchmarks

**Expected Results**:

| Operation | Target | Measured | Status |
|-----------|--------|----------|--------|
| App Launch | <2s | ? | |
| SDK Detection | <1s | ? | |
| Patch Check | <5s | ? | |
| Download (250KB) | <10s | ? | |
| Verify | <2s | ? | |
| Apply | <1s | ? | |
| Total | ~20s | ? | |

---

## 🎉 Success Criteria

✅ **All Tests Passed When**:
1. APK builds without errors
2. App installs on device
3. App launches and displays correctly
4. SDK detection shows QuicUI fork
5. Patch detection works
6. Patch downloads successfully
7. Patch applies without restart
8. UI changes are visible
9. Version updates to 1.0.1
10. No crashes or errors

---

## 📝 Next Steps After Testing

1. **Document Results**: Create test results file
2. **Fix Issues**: If any tests fail, debug and retry
3. **Generate Patch**: Create v1.0.1 with actual changes
4. **Test Rollout**: Test deployment to users
5. **Performance Tune**: Optimize if needed
6. **Release**: Move to Phase 5.5 (Community Release)

---

**Test Plan Created**: November 1, 2025  
**Status**: Ready for Execution  
**Confidence**: High  
**Expected Duration**: 1-2 hours total
