# QuicUI Code Push - Complete Feature Test Plan

## Objective
Test the complete QuicUI code push system end-to-end:
1. Build a Flutter app with the custom modified SDK
2. Create a patch from code modifications
3. Push patch to backend server on localhost
4. Download and apply patch to running app
5. Verify app runs with patched code
6. Test rollback mechanism

## Architecture Overview
```
┌─────────────────────────────────────────────────────┐
│         Test Flutter Application                     │
│  - Uses custom Flutter SDK (v3.35.7-quicui-0.9.0)   │
│  - Integrates quicui_code_push_client library        │
│  - Checks for patches on startup                     │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│    QuicUI Code Push Compiler (quicui_compiler)       │
│  - Generates binary patches from source changes      │
│  - Uses bsdiff4 algorithm for delta compression      │
│  - Outputs signed patch files with versioning        │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│   Backend API Server (localhost:8080)                │
│  - Stores patch metadata                             │
│  - Serves patch files to clients                     │
│  - Manages patch versioning and releases             │
└─────────────────────────────────────────────────────┘
```

## Phase 1: Setup & Preparation

### Step 1.1: Verify Backend Server
- Status: Backend running on localhost:8080
- Check: `curl http://localhost:8080/health`
- Expected: HTTP 200 with "OK" response

### Step 1.2: Create Test Flutter App Directory
```bash
cd /Users/admin/Documents/quicui2/
mkdir -p test_apps/quicui_test_app_v1
cd test_apps/quicui_test_app_v1
```

### Step 1.3: Create Flutter App Using Custom SDK
```bash
flutter create --org com.quicui --project-name quicui_test_app .
```

Configuration:
- Custom Flutter SDK: Point to `/Users/admin/Documents/quicui2/forks/flutter-official`
- Flutter version: v3.35.7-quicui-0.9.0 (custom fork)
- Target: iOS/Android with code push support

### Step 1.4: Verify App Builds with Modified SDK
```bash
flutter pub get
flutter build ios --debug  # or android
```

## Phase 2: Integrate Code Push Client

### Step 2.1: Add Dependency
File: `pubspec.yaml`
```yaml
dependencies:
  quicui_code_push_client:
    path: ../../packages/quicui_code_push_client
```

### Step 2.2: Initialize Code Push in App
File: `lib/main.dart`
- Import: `import 'package:quicui_code_push_client/quicui_code_push_client.dart';`
- On startup: Create `Config` instance pointing to `localhost:8080`
- On startup: Initialize `PatchManager` to check for patches
- Display patch status in UI

### Step 2.3: Build App with Code Push Support
```bash
flutter pub get
flutter build ios --debug
```

Output directory: `build/ios/Debug/` or `build/android/debug/`

## Phase 3: Create Baseline Snapshot

### Step 3.1: Generate Initial App Snapshot
```bash
# Create a binary snapshot of the app
cd /Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1
cp build/ios/Debug/quicui_test_app.app baseline_snapshot.app
```

### Step 3.2: Calculate Baseline Checksum
```bash
shasum -a 256 baseline_snapshot.app > baseline.sha256
```

## Phase 4: Create & Generate Patch

### Step 4.1: Modify App Code
File: `lib/main.dart` or `lib/screens/home.dart`

Example modifications:
- Change text from "Welcome to QuicUI" to "Welcome to QuicUI - Patched v2"
- Add a new UI element (button, icon, etc.)
- Update version string from "1.0.0" to "1.0.1-patch"

### Step 4.2: Rebuild App with Modifications
```bash
flutter clean
flutter pub get
flutter build ios --debug
```

Output: Modified app at `build/ios/Debug/quicui_test_app.app`

### Step 4.3: Generate Binary Patch
```bash
cd /Users/admin/Documents/quicui2
dart run packages/quicui_compiler/bin/quicui_compiler.dart patch \
  --from test_apps/quicui_test_app_v1/baseline_snapshot.app \
  --to test_apps/quicui_test_app_v1/build/ios/Debug/quicui_test_app.app \
  --output test_apps/quicui_test_app_v1/v1.0.1.patch \
  --version 1.0.1
```

Expected output: Binary patch file `v1.0.1.patch` (~100-500KB, significantly smaller than full app)

## Phase 5: Push Patch to Backend

### Step 5.1: Create Patch Metadata
```json
{
  "patchId": "patch-v1.0.1",
  "version": "1.0.1",
  "appVersion": "1.0.0",
  "size": 245120,
  "checksum": "sha256_hash_here",
  "releaseDate": "2025-11-01T00:00:00Z",
  "description": "UI update and bug fixes"
}
```

### Step 5.2: Upload Patch via Backend API
```bash
curl -X POST http://localhost:8080/api/v1/patches \
  -H "Content-Type: application/json" \
  -d @patch_metadata.json

curl -X POST http://localhost:8080/api/v1/patches/upload \
  -H "Content-Type: application/octet-stream" \
  --data-binary @test_apps/quicui_test_app_v1/v1.0.1.patch
```

### Step 5.3: Verify Patch in Backend
```bash
curl http://localhost:8080/api/v1/patches
# Should return list with new patch
```

## Phase 6: Test Patch Download & Application

### Step 6.1: Run App (with v1.0.0 code)
- Start test app from clean build
- App checks for patches against localhost:8080
- App detects available patch v1.0.1 for app version 1.0.0

### Step 6.2: App Downloads Patch
- Code push client initiates download
- Patch file downloaded to app cache directory
- Checksum verified

### Step 6.3: App Applies Patch
- App applies binary patch to running code using bsdiff
- Code is replaced in memory/disk cache
- Version updated from 1.0.0 to 1.0.1

## Phase 7: Verification

### Step 7.1: Restart App
- Close and reopen application
- App should run with patched code

### Step 7.2: Verify Changes Visible
- Text should show "Welcome to QuicUI - Patched v2"
- New UI elements should appear
- Version displayed should be "1.0.1-patch"

### Step 7.3: Check Patch Status
- Code push client reports patch status: "completed"
- No rollback needed
- Patch remains applied

## Phase 8: Test Rollback (Optional)

### Step 8.1: Trigger Rollback
```bash
# Delete patch or trigger via app menu
# App reverts to original v1.0.0 code
```

### Step 8.2: Verify Rollback
- App runs with original code
- Text shows "Welcome to QuicUI"
- Version back to "1.0.0"

## Phase 9: Test Multiple Patches (Advanced)

### Step 9.1: Create Patch v1.0.2
- Modify app code again (v1.0.0 → v1.0.2)
- Generate new patch
- Push to backend
- Test download and application

### Step 9.2: Chain Patches
- Test applying v1.0.1 then v1.0.2
- Or test skipping v1.0.1 and applying v1.0.2 directly

## Test Success Criteria

✅ **All Features Working When:**
1. [x] Custom Flutter SDK builds and runs app
2. [ ] Code push client integrates without errors
3. [ ] Baseline app snapshot created
4. [ ] Patch generated from code modifications
5. [ ] Patch uploaded to backend successfully
6. [ ] Patch retrieved via API endpoints
7. [ ] App downloads patch automatically
8. [ ] Patch applied without crashes
9. [ ] Modified code runs after restart
10. [ ] Visual changes confirm patch applied
11. [ ] Rollback mechanism works
12. [ ] Multiple patches chain correctly

## Expected Timeline

| Phase | Duration | Status |
|-------|----------|--------|
| Setup & Prep | 5 min | ⏳ |
| Create App | 10 min | ⏳ |
| Integrate Code Push | 10 min | ⏳ |
| Create Baseline | 5 min | ⏳ |
| Modify & Generate Patch | 10 min | ⏳ |
| Push to Backend | 5 min | ⏳ |
| Test Download & Apply | 10 min | ⏳ |
| Verify Results | 5 min | ⏳ |
| **Total** | **~60 min** | ⏳ |

## Troubleshooting Guide

| Issue | Symptom | Solution |
|-------|---------|----------|
| Custom SDK not used | Build uses system Flutter | Verify `flutter --version` points to fork |
| Code push not initializing | App crashes on startup | Check Config pointing to localhost:8080 |
| Patch generation fails | Compiler error | Verify baseline and modified apps exist |
| Patch upload fails | 403/500 error | Check backend is running and accepting POST |
| App doesn't detect patch | No download starts | Check network connectivity to localhost:8080 |
| Patch apply fails | App crash after download | Check patch checksum matches |
| Changes not visible | App shows old code | Verify patch was actually applied |

## Files Generated During Testing

```
test_apps/quicui_test_app_v1/
├── lib/                          # Source code
├── pubspec.yaml                  # Dependencies
├── baseline_snapshot.app          # V1.0.0 app binary
├── baseline.sha256               # V1.0.0 checksum
├── v1.0.1.patch                  # Binary patch file
├── patch_metadata.json           # Patch info for backend
└── build/                        # Build outputs
    └── ios/Debug/                # Final app binary
```

## Success Indicators

- ✅ App builds with custom SDK
- ✅ Code push client initialized
- ✅ Patch downloaded successfully
- ✅ Patch applied without errors
- ✅ Visual changes confirmed in app
- ✅ App restarts with patched code
- ✅ Rollback works correctly

---

**Next Step:** Start Phase 1 - Setup & Preparation
