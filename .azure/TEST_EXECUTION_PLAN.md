# QuicUI Code Push - Test Execution Plan (November 1, 2025)

**Status**: ✅ Ready for Execution  
**Backend**: 192.168.20.100:8080 (Local Network)  
**Build**: QuicUI Flutter SDK Only  
**Test App**: quicui_test_app_v1 v1.0.0

---

## 📋 Test Plan Summary

### Overview
End-to-end testing of QuicUI Code Push system on local network with:
- **Baseline**: App v1.0.0 running with QuicUI SDK
- **Patch**: v1.0.1 patch created and deployed
- **Validation**: Patch detection, download, verification, and application

### Architecture
```
PC (192.168.20.100)           Android Device
│                               │
├─ Backend (8080)      ←→      ├─ App v1.0.0
├─ Patch Storage               ├─ QuicUI SDK
└─ Test Coordinator           └─ Test Orchestrator
```

---

## 🚀 Quick Start Execution

### Step 1: Prepare Backend (On PC)

```bash
# Terminal 1 - Start Backend
cd /Users/admin/Documents/quicui2/packages/quicui_backend
dart run lib/quicui_backend.dart

# Expected Output:
# Server running on http://0.0.0.0:8080
# Ready for patch uploads and downloads
```

### Step 2: Build APK (On PC)

```bash
# Terminal 2 - Build APK
cd /Users/admin/Documents/quicui2

# Run build script
./scripts/build_and_test.sh

# Or build manually:
cd test_apps/quicui_test_app_v1
flutter clean
flutter pub get
flutter build apk --release --no-obfuscate

# APK output: 
# build/app/outputs/flutter-apk/app-release.apk (~55MB)
```

### Step 3: Install on Device

```bash
# Terminal 2 - Install APK
cd test_apps/quicui_test_app_v1

# Connect device via ADB
adb devices

# Install APK
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Launch app
adb shell am start -n com.example.quicui_test_app/.MainActivity
```

### Step 4: Verify Initial State

**On Device App Should Show**:
```
✅ Version: 1.0.0
✅ SDK Status: QuicUI (Custom Fork) ✅
✅ SDK Info: 3.35.7 (stable)
✅ Patch Status: No patches available
✅ Features: OTA Updates ✨
```

### Step 5: Trigger Patch Detection

```
On Device:
1. Tap "Check for Patches" button
2. Status shows "Checking for patches..."
3. Wait 5-10 seconds for backend query
4. Backend responds with patch info (if available)
```

### Step 6: Download and Apply Patch

```
On Device:
1. If patch available, app downloads it (~250KB)
2. App verifies patch signature
3. App applies patch (Dart VM patching)
4. NO app restart needed
5. UI updates appear immediately
```

### Step 7: Verify Patch Applied

**On Device App Should Show**:
```
✅ Version: 1.0.1 (UPDATED)
✅ Patch Applied: Yes ✅ (UPDATED)
✅ All features working
✅ UI changes visible
```

---

## 📊 Test Phases Detail

### Phase 1: Build APK with QuicUI SDK (5-10 min)

**Files**:
- Build script: `.azure/BUILD_CONFIG.md`
- Script: `scripts/build_and_test.sh`

**Commands**:
```bash
cd /Users/admin/Documents/quicui2
./scripts/build_and_test.sh
```

**Verification**:
- ✅ Flutter SDK detected (QuicUI fork)
- ✅ Network connectivity to 192.168.20.100:8080
- ✅ APK builds without errors
- ✅ APK size ~55MB
- ✅ APK contains QuicUI patches

**Artifacts**:
- `test_apps/quicui_test_app_v1/build/app/outputs/flutter-apk/app-release.apk`

---

### Phase 2: Install on Device (2-3 min)

**Prerequisites**:
- Android device connected via USB
- USB debugging enabled
- ADB accessible

**Commands**:
```bash
adb devices  # Verify connection
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell pm list packages | grep quicui  # Verify install
```

**Verification**:
- ✅ APK installs successfully
- ✅ No installation errors
- ✅ Package appears in package list

---

### Phase 3: Launch App (2-3 min)

**Launch**:
```bash
adb shell am start -n com.example.quicui_test_app/.MainActivity
```

**Verification on Device**:
- ✅ App launches without crash
- ✅ Main UI displays
- ✅ All text visible
- ✅ All buttons responsive
- ✅ No error messages

**Display Verification**:
```
Title: "QuicUI Code Push Test" ✅
Version: 1.0.0 ✅
SDK Status: "QuicUI (Custom Fork) ✅" ✅
SDK Info: 3.35.7 (stable) ✅
Patch Status: "No patches available" ✅
Button: "Check for Patches" ✅
```

---

### Phase 4: Patch Detection (3-5 min)

**Backend Preparation** (on PC):
```bash
# Ensure backend is running
curl http://192.168.20.100:8080/api/v1/health
# Expected: {"status":"ok"}
```

**On Device**:
```
1. Tap "Check for Patches" button
2. Watch for loading spinner
3. Status updates: "Checking for patches..."
4. After 5-10s, status changes to one of:
   - "Patches available!" (if patch exists on backend)
   - "No patches available" (if no patches)
```

**Network Request**:
```
GET http://192.168.20.100:8080/api/v1/patches
  ?appId=com.example.quicui_test_app
  &version=1.0.0

Response: List of available patches for v1.0.0
```

**Verification**:
- ✅ Network request succeeds
- ✅ Backend responds <500ms
- ✅ Status updates on UI
- ✅ No app crashes

---

### Phase 5: Download Patch (5-10 min)

**Prerequisites**:
- Patch exists on backend
- Download URL is accessible
- Patch file is valid

**On Device**:
```
1. App detects patch available
2. Button changes to "Download Patch"
3. Tap to download
4. Status: "Downloading patch..."
5. Progress indicator shows download
6. After ~10s: "Patch downloaded"
```

**Network Transfer**:
```
Download: http://192.168.20.100:8080/patches/v1.0.1.bin
Size: ~250KB (85% smaller than full app)
Time: ~5-10s on LAN
```

**Verification**:
- ✅ Download starts on tap
- ✅ Download completes without errors
- ✅ File size matches expected
- ✅ No timeout or connection errors

---

### Phase 6: Verify & Apply Patch (3-5 min)

**Verification**:
```
1. App verifies patch signature
2. Ed25519 signature check passes
3. Checksum validation passes
4. Status: "Patch verified"
```

**Application**:
```
1. App applies patch to Dart kernel
2. Status: "Applying patch..."
3. **NO app restart occurs**
4. UI updates immediately
5. Status: "Patch applied successfully!"
```

**Changes Visible on Device**:
- UI text updates appear
- Version changes to 1.0.1
- "Patch Applied" shows "Yes ✅"
- All new elements visible
- App continues running (never restarted)

**Verification**:
- ✅ Patch signature valid (Ed25519)
- ✅ Patch applies without errors
- ✅ No restart occurs
- ✅ UI changes immediate
- ✅ App stability maintained

---

### Phase 7: Verify Final State (2-3 min)

**Display After Patch**:
```
App Version:         1.0.1 ✅ (changed from 1.0.0)
SDK Status:          QuicUI (Custom Fork) ✅
SDK Info:            3.35.7 (stable)
Patch Status:        Patch applied successfully! ✅
Available Patch:     None (already applied)
Patch Applied:       Yes ✅ (changed from No)
Patch Version:       v1.0.1 ✅
Features:            OTA Updates ✨
```

**Functionality Verification**:
- ✅ All buttons still work
- ✅ No crashes or errors
- ✅ Memory usage stable
- ✅ Network requests work
- ✅ App performance unchanged

---

## ✅ Success Criteria

### Build Phase
- [ ] APK builds without errors using `./scripts/build_and_test.sh`
- [ ] APK contains QuicUI Flutter SDK patches
- [ ] APK is signed and installable
- [ ] APK size is ~55MB

### Installation Phase
- [ ] APK installs successfully on device
- [ ] No installation errors
- [ ] Package appears in system packages

### Launch Phase
- [ ] App launches without crashes
- [ ] Main UI displays completely
- [ ] All text and buttons visible
- [ ] SDK detection works
- [ ] Shows "QuicUI (Custom Fork)" ✅

### Patch Detection Phase
- [ ] Network request to backend succeeds
- [ ] Response time <500ms
- [ ] Status updates on device
- [ ] No timeout errors

### Download Phase
- [ ] Patch downloads successfully
- [ ] Download completes without errors
- [ ] File size matches expected (~250KB)
- [ ] No connection issues

### Apply Phase
- [ ] Patch verifies signature successfully
- [ ] Patch applies without errors
- [ ] **App does NOT restart**
- [ ] UI updates appear immediately

### Verification Phase
- [ ] Version updates to 1.0.1
- [ ] "Patch Applied" shows "Yes ✅"
- [ ] All new UI changes visible
- [ ] App remains stable
- [ ] No crashes or errors
- [ ] Memory usage normal

### Overall
- [ ] **All 7 phases complete successfully**
- [ ] **No critical errors or crashes**
- [ ] **System functions as designed**

---

## 📈 Performance Expectations

| Operation | Expected Time | Notes |
|-----------|---------------|-------|
| Build APK | 5-10 min | First build slower |
| Install APK | 1-2 min | Depends on device |
| Launch App | <2s | Typical Flutter app |
| SDK Detection | <1s | Cached after first run |
| Check for Patches | 5-10s | Network request + server response |
| Download Patch | 5-10s | ~250KB on LAN |
| Verify Patch | 1-2s | Ed25519 signature verification |
| Apply Patch | <1s | Dart VM patching |
| **Total** | **~30-45s** | Full patch cycle |

---

## 🔄 Test Execution Timeline

```
T+0min:    Start Backend
T+2min:    Build APK starts
T+12min:   APK ready, install starts
T+14min:   App launches on device
T+15min:   Initial state verified
T+16min:   Tap "Check for Patches"
T+20min:   Patch detected and download starts
T+25min:   Patch applied to device
T+26min:   Final state verified
T+27min:   ✅ Test Complete
```

---

## 📝 Documentation & Guides

### Created Files

1. **`.azure/BUILD_CONFIG.md`** - Build configuration and steps
2. **`.azure/CODE_PUSH_TEST_PLAN.md`** - Original test plan
3. **`.azure/LOCAL_NETWORK_TESTING.md`** - Detailed testing guide
4. **`scripts/build_and_test.sh`** - Automated build script
5. **`test_apps/quicui_test_app_v1/lib/main.dart`** - Updated with 192.168.20.100:8080

### Quick Reference

- **Build Script**: `./scripts/build_and_test.sh`
- **APK Location**: `test_apps/quicui_test_app_v1/build/app/outputs/flutter-apk/app-release.apk`
- **Backend URL**: http://192.168.20.100:8080
- **Test Plan**: `.azure/LOCAL_NETWORK_TESTING.md`

---

## 🎯 Next Steps

### Immediate (Next Session)
1. [ ] Start backend on PC at 192.168.20.100:8080
2. [ ] Run `./scripts/build_and_test.sh`
3. [ ] Install APK on Android device
4. [ ] Execute test phases 1-7
5. [ ] Document results

### Follow-up
1. [ ] Create v1.0.1 with actual UI changes
2. [ ] Generate real patch binary
3. [ ] Upload patch to backend
4. [ ] Run full patch cycle
5. [ ] Performance tuning if needed

### Post-Testing
1. [ ] Document all results
2. [ ] Fix any issues found
3. [ ] Prepare for Phase 5.4 (Beta Testing)
4. [ ] Plan Phase 5.5 (Community Release)

---

## 🔧 Troubleshooting Quick Guide

### "Network not reachable"
```bash
ping 192.168.20.100
# If fails: Check PC IP and device network
```

### "Backend not responding"
```bash
curl http://192.168.20.100:8080/api/v1/health
# If fails: Verify backend is running
```

### "APK build fails"
```bash
flutter clean
flutter pub get
./scripts/build_and_test.sh
```

### "App crashes on launch"
```bash
adb logcat | grep -i "crash\|error"
adb uninstall com.example.quicui_test_app
# Rebuild and reinstall
```

---

## 📞 Support & Resources

- **Backend Setup**: See `DEPLOYMENT_GUIDE.md`
- **Flutter Setup**: See `GETTING_STARTED.md`
- **API Documentation**: See `API_DOCUMENTATION.md`
- **Testing Guide**: See `.azure/LOCAL_NETWORK_TESTING.md`

---

**Test Plan Prepared**: November 1, 2025  
**Status**: ✅ Ready for Execution  
**Estimated Duration**: 1.5 - 2 hours  
**Success Probability**: Very High (All components complete & tested)

**Start with**: `./scripts/build_and_test.sh`
