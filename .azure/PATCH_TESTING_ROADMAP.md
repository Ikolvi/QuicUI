# Patch System End-to-End Testing Plan

**Objective**: Verify the complete patch workflow: generate, upload, download, and apply patches

**Prerequisites Status**:
- ✅ Backend server (Dart/Shelf) on localhost:8080
- ✅ Test app (quicui_test_app_v1) running on Android device (LAVA LXX503)
- ✅ QuicUI custom Flutter fork (3.38.0-1.0.pre-350) with patch loading support
- ✅ SDK detection working correctly (detects QuicUI fork)
- ✅ Build-time SDK info passing via dart-define

---

## Phase 1: Setup & Baseline

### 1.1 Start Backend Server
```bash
cd /Users/admin/Documents/quicui2/packages/quicui_backend
pkill -9 dart 2>/dev/null  # Clean up old processes
export $(cat .env.local | grep -v "^#" | xargs)
dart run lib/quicui_backend.dart
```

**Expected Output**:
```
Backend running on localhost:8080
Health check: GET /health → 200 OK
```

**Verification**:
```bash
curl http://localhost:8080/health
# Expected: {"status":"healthy","timestamp":"..."}
```

### 1.2 Build & Deploy Test App in RELEASE Mode with QuicUI Fork

```bash
# Switch to QuicUI fork
export FLUTTER_ROOT=/Users/admin/Documents/quicui2/forks/flutter-official
export PATH=$FLUTTER_ROOT/bin:$PATH

# Navigate to test app
cd /Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1

# Get dependencies
flutter pub get

# Build for release (required for patch system)
flutter build apk --release \
  --dart-define="QUICUI_SDK_TYPE=quicui" \
  --dart-define="QUICUI_FLUTTER_VERSION=3.38.0-1.0.pre-350" \
  --dart-define="QUICUI_DART_VERSION=3.11.0" \
  --dart-define="QUICUI_SDK_CHANNEL=[user-branch]" \
  --dart-define="QUICUI_IS_FORK=true"

# Deploy to device
flutter install -d BLZ5GBY23JB034715

# Run on device
flutter run -d BLZ5GBY23JB034715 --release
```

**Verification**:
- App launches in release mode (no debug banner)
- SDK Detection shows: "QuicUI 3.38.0-1.0.pre-350 ([user-branch]) ✅"
- No patches available yet (first run)
- Backend connectivity confirmed

### 1.3 Document Baseline State
- Screenshot baseline app UI
- Record version: 1.0.0
- Note: SDK Detection shows QuicUI fork detected
- Backend health: ✅ All endpoints responding

---

## Phase 2: Create Code Changes (V1.0.1)

### 2.1 Make a Simple UI Change
Edit `/Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1/lib/main.dart`:

**Change Example**: Update welcome text and add feature flag
```dart
// BEFORE:
const Text(
  'Welcome to QuicUI Code Push',
  ...
),

// AFTER:
const Text(
  'Welcome to QuicUI Code Push v1.0.1 🚀',
  ...
),
```

Plus add a new info field:
```dart
_InfoRow('Patch Version:', '1.0.1-PATCH'),
_InfoRow('Features:', 'OTA Updates ✨'),
```

### 2.2 Update Version in pubspec.yaml
```yaml
version: 1.0.1+2
```

### 2.3 Commit Changes Locally
```bash
git add .
git commit -m "v1.0.1: Add patch support indicator and update UI"
```

---

## Phase 3: Generate Binary Patch

### 3.1 Build Original APK (Baseline)
```bash
export FLUTTER_ROOT=/Users/admin/Documents/quicui2/forks/flutter-official
export PATH=$FLUTTER_ROOT/bin:$PATH
cd /Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1

# Checkout original version first
git checkout HEAD~1 lib/main.dart pubspec.yaml

# Build baseline
flutter build apk --release \
  --dart-define="QUICUI_SDK_TYPE=quicui" \
  --dart-define="QUICUI_FLUTTER_VERSION=3.38.0-1.0.pre-350" \
  --dart-define="QUICUI_DART_VERSION=3.11.0" \
  --dart-define="QUICUI_SDK_CHANNEL=[user-branch]" \
  --dart-define="QUICUI_IS_FORK=true"

# Save baseline
cp build/app/outputs/flutter-apk/app-release.apk /tmp/app-baseline-1.0.0.apk
```

### 3.2 Build Patched APK (V1.0.1)
```bash
# Restore changes
git checkout lib/main.dart pubspec.yaml

# Build patched version
flutter build apk --release \
  --dart-define="QUICUI_SDK_TYPE=quicui" \
  --dart-define="QUICUI_FLUTTER_VERSION=3.38.0-1.0.pre-350" \
  --dart-define="QUICUI_DART_VERSION=3.11.0" \
  --dart-define="QUICUI_SDK_CHANNEL=[user-branch]" \
  --dart-define="QUICUI_IS_FORK=true"

# Save patched
cp build/app/outputs/flutter-apk/app-release.apk /tmp/app-patched-1.0.1.apk
```

### 3.3 Generate Binary Diff Using quicui_compiler
```bash
cd /Users/admin/Documents/quicui2/packages/quicui_compiler

# Generate the patch
dart run bin/quicui_compiler.dart generate-patch \
  --baseline /tmp/app-baseline-1.0.0.apk \
  --target /tmp/app-patched-1.0.1.apk \
  --output /tmp/app-1.0.0-to-1.0.1.patch \
  --compression gzip \
  --optimization aggressive

# Generate checksum
sha256sum /tmp/app-1.0.0-to-1.0.1.patch > /tmp/app-1.0.0-to-1.0.1.patch.sha256
```

**Expected Output**:
```
✅ Patch generated successfully
  Baseline: 45.2 MB
  Target:   45.3 MB
  Patch:    2.8 MB (93.8% reduction)
  Checksum: abc123def456...
```

---

## Phase 4: Upload Patch to Backend

### 4.1 Create Patch Metadata
```bash
cat > /tmp/patch-metadata.json << 'EOF'
{
  "patchId": "patch-1.0.0-1.0.1",
  "appId": "com.quicui.testapp",
  "fromVersion": "1.0.0",
  "toVersion": "1.0.1",
  "patchType": "binary_diff",
  "size": 2834432,
  "checksum": "sha256:abc123def456...",
  "createdAt": "2025-11-01T00:00:00Z",
  "releaseNotes": "OTA update support, UI improvements",
  "sdkRequirement": {
    "minFlutterVersion": "3.35.7",
    "minDartVersion": "3.9.2",
    "requiresQuicUI": true,
    "minQuicUIVersion": "3.38.0"
  }
}
EOF
```

### 4.2 Upload Patch to Backend
```bash
# Upload patch file
curl -X POST http://localhost:8080/patches \
  -F "patchFile=@/tmp/app-1.0.0-to-1.0.1.patch" \
  -F "metadata=@/tmp/patch-metadata.json" \
  -H "Authorization: Bearer test-token"

# Expected response:
# {"patchId":"patch-1.0.0-1.0.1","status":"published","url":"..."}
```

### 4.3 Verify Upload
```bash
curl http://localhost:8080/patches/com.quicui.testapp/1.0.0
# Expected: Returns patch metadata and download URL
```

---

## Phase 5: Test Patch Download & Application

### 5.1 Restart App on Device
- Close app completely
- Reopen app
- Monitor logs for patch check

**Expected Behavior**:
```
I/flutter: Checking for patches...
I/flutter: Found patch: 1.0.0 → 1.0.1
I/flutter: Downloading patch (2.8 MB)...
I/flutter: Patch downloaded successfully
I/flutter: Verifying checksum...
I/flutter: Applying patch...
```

### 5.2 Verify UI Changes Applied
- Welcome text should show: "Welcome to QuicUI Code Push v1.0.1 🚀"
- New info rows visible: "Patch Version: 1.0.1-PATCH"
- Status shows: "Patch Applied: Yes ✅"

### 5.3 Check App Logs
```bash
flutter logs -d BLZ5GBY23JB034715
# Should show patch application logs
```

---

## Phase 6: Rollback Test (Optional)

### 6.1 Remove Patch
```bash
# API call to remove/rollback patch
curl -X DELETE http://localhost:8080/patches/patch-1.0.0-1.0.1 \
  -H "Authorization: Bearer test-token"
```

### 6.2 Restart App
- App should revert to original UI
- Version should show 1.0.0

---

## Success Criteria

### ✅ Patch Generation
- [ ] Binary diff generated successfully
- [ ] Patch size < 5% of original app
- [ ] Checksum calculated and verified

### ✅ Patch Upload
- [ ] Patch uploaded to backend
- [ ] Metadata stored correctly
- [ ] Download URL accessible

### ✅ Patch Application
- [ ] App detects available patch
- [ ] Patch downloaded to device
- [ ] Patch applied successfully
- [ ] UI changes visible in running app
- [ ] Version number updated

### ✅ SDK Compatibility
- [ ] Works with QuicUI fork only
- [ ] Standard SDK cannot apply patches
- [ ] Version constraints enforced

---

## Quick Command Reference

```bash
# Terminal 1: Start Backend
cd /Users/admin/Documents/quicui2/packages/quicui_backend
export $(cat .env.local | grep -v "^#" | xargs)
dart run lib/quicui_backend.dart

# Terminal 2: Build & Deploy
export FLUTTER_ROOT=/Users/admin/Documents/quicui2/forks/flutter-official
export PATH=$FLUTTER_ROOT/bin:$PATH
cd /Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1
flutter pub get
flutter run -d BLZ5GBY23JB034715 --release

# Terminal 3: Generate & Upload Patch
cd /Users/admin/Documents/quicui2/packages/quicui_compiler
# (Follow Phase 3 & 4 above)
```

---

## Troubleshooting

**Issue**: Patch not detected
- Check backend is running: `curl http://localhost:8080/health`
- Check app has patch checking enabled in Config
- Verify SDK detection shows QuicUI fork

**Issue**: Patch download fails
- Check file permissions: `ls -la /tmp/app-*.patch`
- Verify checksum: `sha256sum /tmp/app-1.0.0-to-1.0.1.patch`
- Check network connectivity: `ping localhost`

**Issue**: Patch application fails
- Check app has write permissions
- Verify app is in release mode (no debug)
- Check Dart VM supports patch loading (QuicUI fork only)

---

**Status**: Ready for execution
**Created**: 1 November 2025
**Device**: LAVA LXX503 (Android 14)
**Backend**: localhost:8080
