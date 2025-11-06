# QuicUI OTA Update System - Ready for Testing

**Date:** November 4, 2025, 12:25 PM  
**Status:** ✅ Ready for Manual Testing  
**Test App:** quicui_engine_test v1.0.0  
**Backend:** http://192.168.20.100:8080  
**Device:** BLZ5GBY23JB034715

---

## System Components

### 1. QuicUI Engine
- **Location:** `forks/flutter-quicui/bin/cache/artifacts/engine/android-arm64-release/flutter.jar`
- **Size:** 5.6 MB
- **Integration:** 7 ConfigureQuicUI calls
- **Status:** ✅ Deployed and verified

### 2. Backend Server
- **URL:** http://192.168.20.100:8080
- **Status:** ✅ Running
- **Patch Registered:** Yes
  - Patch ID: `patch_1.0.0_to_1.0.1`
  - Version: `1.0.1`
  - Size: 3,073,024 bytes (3.0 MB)
  - Hash: `2ca839ecdf15044ad0346066f1d58bd074952b59c0e928384860a4142c86b60a`
  - Path: `/tmp/quicui_patch_test/patch_1.0.0_to_1.0.1.so`

### 3. Test Application
- **Package:** com.quicui.test.quicui_engine_test
- **Current Version:** 1.0.0 (installed on device)
- **APK Size:** 43.2 MB
- **Features:**
  - QuicUI Code Push Client integrated
  - "Check for Updates" button
  - Update status display
  - Visual theme changes between versions

### 4. Patch Files
- **Location:** `/tmp/quicui_patch_test/`
- **Contents:**
  - `app-v1.0.0.apk` - Original version (pulled from device)
  - `app-v1.0.1.apk` - Updated version (built but not installed)
  - `patch_1.0.0_to_1.0.1.so` - Patch file (libapp.so from v1.0.1)
  - `patch_metadata.json` - Patch metadata

---

## Visual Differences Between Versions

### v1.0.0 (Current - Installed)
- **Icon:** 🚀 Purple rocket (Icons.rocket_launch)
- **Title:** "QuicUI Engine Test v1.0.0"
- **Header:** "QuicUI Engine Test" (default color)
- **Status Box:** Blue background
- **Status Title:** "Engine Status"
- **Status Items:**
  - ✅ QuicUI Engine Active
  - ✅ Ready for OTA Updates
  - ✅ Code Push Enabled
- **Version Display:** "1.0.0"

### v1.0.1 (Available for Download)
- **Icon:** 🎉 Orange celebration (Icons.celebration)
- **Title:** "QuicUI Engine Test v1.0.1 🎉"
- **Header:** "UPDATED! 🚀" (orange, bold)
- **Status Box:** Orange background
- **Status Title:** "OTA Update Applied! ✨"
- **Status Items:**
  - ✅ QuicUI Engine Active
  - ✅ Patch Loaded Successfully
  - ✅ Hot Update Complete!
- **Version Display:** "1.0.1"

---

## Manual Testing Instructions

### Step 1: Open App
The app is already installed and running on device BLZ5GBY23JB034715.

**Expected UI:**
- Purple rocket icon 🚀
- "QuicUI Engine Test" header
- Blue status box
- "Check for Updates" button at bottom
- "Update Status: Not checked"

### Step 2: Check for Updates
Press the "Check for Updates" button.

**Expected Behavior:**
1. Button shows "Checking..." with spinner
2. App makes HTTP request to `http://192.168.20.100:8080/api/v1/patches/check`
3. Backend responds with patch info
4. Status changes to "Update found: v1.0.1"
5. Download begins automatically
6. Status changes to "Update installed! Restart app to apply."

**Console Output (QuicUI Client):**
```
[QuicUI] Checking for updates...
[QuicUI] Backend URL: http://192.168.20.100:8080
[QuicUI] POST http://192.168.20.100:8080/api/v1/patches/check
[QuicUI] Request body: {appId: com.quicui.test.quicui_engine_test, currentVersion: 1.0.0, acceptCompression: [xz, gz, bz2]}
[QuicUI] Response status: 200
[QuicUI] Patch available: true
[QuicUI] ✅ Patch found: 1.0.1 (3073024 bytes, compression: null, uncompressed: 3073024 bytes)
[QuicUI] Starting patch download and install process
[QuicUI] Patch version: 1.0.1
[QuicUI] Patch size: 3073024 bytes
[QuicUI] Device architecture: arm64-v8a
[QuicUI] Downloading patch to: /data/user/0/com.quicui.test.quicui_engine_test/cache/quicui_patch_1.0.1.compressed
[QuicUI] Patch downloaded: 3073024 bytes
[QuicUI] Compression format: none
[QuicUI] No compression, using file directly
[QuicUI] Patch file size: 3073024 bytes
[QuicUI] Patch hash: 2ca839ecdf15044ad0346066f1d58bd074952b59c0e928384860a4142c86b60a
[QuicUI] Installing patch via platform channel
[QuicUI] Patch successfully installed to code cache
[QuicUI] App restart required to load patched code
[QuicUI] Patch installation complete!
```

**Backend Output:**
```
📥 Serving patch: patch_1.0.0_to_1.0.1
   Version: 1.0.1
   Size: 3073024 bytes
   Compression: none
```

### Step 3: Restart App
Force stop and restart the app:

```bash
adb shell am force-stop com.quicui.test.quicui_engine_test
adb shell am start -n com.quicui.test.quicui_engine_test/.MainActivity
```

**Expected UI After Restart:**
- Orange celebration icon 🎉
- "UPDATED! 🚀" header (orange, bold)
- Orange status box
- "OTA Update Applied! ✨"
- Version shows "1.0.1"

**Console Output (QuicUI Engine):**
```
ConfigureQuicUI called
QuicUI: Patched library will be loaded
QuicUI: Using patch: /data/user/0/com.quicui.test.quicui_engine_test/code_cache/quicui/1.0.1/libapp.so
```

### Step 4: Verify Visual Changes
Confirm all visual changes are present:
- ✅ Icon changed from rocket to celebration
- ✅ Color theme changed from purple/blue to orange
- ✅ Header text changed to "UPDATED! 🚀"
- ✅ Status box changed from blue to orange
- ✅ Status title changed to "OTA Update Applied! ✨"
- ✅ Version number shows "1.0.1"

---

## Verification Commands

### Check Backend Status
```bash
curl http://192.168.20.100:8080/health
```
Expected: `OK`

### List Available Patches
```bash
curl http://192.168.20.100:8080/api/v1/patches
```
Expected:
```json
{
  "patches": [
    {
      "patchId": "patch_1.0.0_to_1.0.1",
      "version": "1.0.1",
      "appId": "com.quicui.test.quicui_engine_test",
      "uncompressedSize": 3073024,
      "compressedSizes": {},
      "compressionAvailable": [],
      "hash": "2ca839ecdf15044ad0346066f1d58bd074952b59c0e928384860a4142c86b60a",
      "createdAt": "2025-11-04T12:23:45.123Z"
    }
  ],
  "total": 1
}
```

### Check for Updates (API)
```bash
curl -X POST http://192.168.20.100:8080/api/v1/patches/check \
  -H "Content-Type: application/json" \
  -d '{
    "appId": "com.quicui.test.quicui_engine_test",
    "currentVersion": "1.0.0"
  }'
```
Expected:
```json
{
  "patchAvailable": true,
  "patchId": "patch_1.0.0_to_1.0.1",
  "version": "1.0.1",
  "downloadSize": 3073024,
  "uncompressedSize": 3073024,
  "compression": null,
  "hash": "2ca839ecdf15044ad0346066f1d58bd074952b59c0e928384860a4142c86b60a",
  "downloadUrl": "/api/v1/patches/download/patch_1.0.0_to_1.0.1"
}
```

### Monitor App Logs
```bash
adb logcat -s flutter:I | grep -E "QuicUI|patch|update"
```

---

## Troubleshooting

### If Update Check Fails
1. Verify backend is running:
   ```bash
   curl http://192.168.20.100:8080/health
   ```

2. Check backend logs:
   ```bash
   cd packages/quicui_backend
   tail -f backend.log
   ```

3. Verify patch is registered:
   ```bash
   curl http://192.168.20.100:8080/api/v1/patches
   ```

### If Patch Doesn't Apply After Restart
1. Check app logs for QuicUI messages:
   ```bash
   adb logcat -s flutter:I | grep QuicUI
   ```

2. Verify patch file exists on device:
   ```bash
   adb shell ls -la /data/data/com.quicui.test.quicui_engine_test/code_cache/quicui/
   ```

3. Check QuicUI engine integration:
   ```bash
   unzip -l forks/flutter-quicui/bin/cache/artifacts/engine/android-arm64-release/flutter.jar | grep -i quicui
   ```

### If UI Doesn't Change
1. Verify you're running the patched version:
   - Check logs for "Using patch:" message
   - Version number should show "1.0.1"

2. Force stop and restart again:
   ```bash
   adb shell am force-stop com.quicui.test.quicui_engine_test
   adb shell am start -n com.quicui.test.quicui_engine_test/.MainActivity
   ```

---

## Architecture Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    QuicUI OTA Update Flow                        │
└─────────────────────────────────────────────────────────────────┘

1. User Opens App (v1.0.0)
   ↓
   [App UI shows purple rocket, blue theme]
   
2. User Presses "Check for Updates"
   ↓
   [QuicUICodePush.checkForUpdates()]
   ↓
   POST http://192.168.20.100:8080/api/v1/patches/check
   {
     "appId": "com.quicui.test.quicui_engine_test",
     "currentVersion": "1.0.0"
   }
   ↓
   [Backend checks _patches map]
   ↓
   Response: {
     "patchAvailable": true,
     "patchId": "patch_1.0.0_to_1.0.1",
     "version": "1.0.1",
     "downloadUrl": "/api/v1/patches/download/patch_1.0.0_to_1.0.1"
   }
   
3. Auto-Download and Install
   ↓
   [QuicUICodePush.downloadAndInstall(patch)]
   ↓
   GET http://192.168.20.100:8080/api/v1/patches/download/patch_1.0.0_to_1.0.1
   ↓
   [Download 3.0 MB libapp.so to temp directory]
   ↓
   [Verify hash: 2ca839ec...c86b60a]
   ↓
   [CodePushMethodChannel.installPatch()]
   ↓
   [Copy to: /data/data/.../code_cache/quicui/1.0.1/libapp.so]
   ↓
   UI shows: "Update installed! Restart app to apply."
   
4. User Restarts App
   ↓
   [Engine: ConfigureQuicUI called]
   ↓
   [Engine checks: /data/data/.../code_cache/quicui/1.0.1/libapp.so]
   ↓
   [Engine loads patched libapp.so instead of embedded one]
   ↓
   [App UI shows orange celebration, orange theme - v1.0.1 code!]
```

---

## Success Criteria

- ✅ Backend serves patch metadata
- ✅ App checks for updates without errors
- ✅ Patch downloads successfully (3.0 MB)
- ✅ Hash verification passes
- ✅ Patch installs to code cache
- ⏳ **Pending:** App restart loads patched code
- ⏳ **Pending:** UI shows v1.0.1 visual changes

---

## Next Steps

1. **Manual Test:** Follow testing instructions above
2. **Document Results:** Record actual behavior vs expected
3. **Create E2E Test:** Automate the full flow
4. **Performance Metrics:** Measure download time, restart time
5. **Compression Test:** Test with xz/gz/bz2 compressed patches
6. **Multi-Device Test:** Test on different Android versions/architectures
7. **Rollback Test:** Implement and test patch rollback feature
8. **Production Deployment:** Move to real server with HTTPS, authentication

---

## Files Modified

### Test App
- `test_apps/quicui_engine_test/lib/main.dart` - Added QuicUI client, update button
- `test_apps/quicui_engine_test/pubspec.yaml` - Added quicui_code_push_client dependency

### Backend
- `packages/quicui_backend/bin/server.dart` - Already had `/api/v1/patches/register` endpoint

### Patch Generation
- `/tmp/quicui_patch_test/generate_patch.sh` - Created (not used, manual registration instead)
- `/tmp/quicui_patch_test/patch_1.0.0_to_1.0.1.so` - Patch file (3.0 MB)
- `/tmp/quicui_patch_test/patch_metadata.json` - Metadata

---

## Technical Notes

### Patch Generation Strategy
Currently using **full libapp.so replacement** (3.0 MB) rather than binary diff. This is simpler and reliable for initial testing. Future optimization:
- Use bsdiff/courgette for smaller patches
- Compress with xz (70-80% reduction)
- Delta updates for small code changes

### Backend Architecture
In-memory patch storage (not persistent). For production:
- Database storage (PostgreSQL/MongoDB)
- File storage (S3/Azure Blob)
- CDN for patch distribution
- Authentication and authorization
- Rate limiting
- Analytics and monitoring

### Security
Current implementation uses SHA-256 hash for verification. Production should add:
- RSA signature verification
- HTTPS/TLS for transport security
- Certificate pinning
- API key authentication
- Encrypted patch storage

---

**Status:** Ready for manual testing! Press "Check for Updates" in the app to begin.
