# Quick Start: Patch Testing Workflow

**Device**: LAVA LXX503 (BLZ5GBY23JB034715) - Android 14
**Backend**: Running on localhost:8080 ✅
**Test App**: quicui_test_app_v1 (v1.0.0)

## Status Check
```bash
# Verify backend is running
curl -s http://localhost:8080/health

# Verify device is connected
flutter devices | grep LAVA
```

## Next: Test Patch Workflow

### Step 1: Make a Code Change
Edit `test_apps/quicui_test_app_v1/lib/main.dart`:
- Change welcome text to "Welcome to QuicUI Code Push v1.0.1 🚀"
- Add new info row: `_InfoRow('Patch Version:', '1.0.1-PATCH')`
- Update pubspec.yaml: `version: 1.0.1+2`

### Step 2: Generate Binary Patch

**Build Baseline (v1.0.0)**:
```bash
export FLUTTER_ROOT=/Users/admin/Documents/quicui2/forks/flutter-official
export PATH=$FLUTTER_ROOT/bin:$PATH
cd test_apps/quicui_test_app_v1

# Revert to original
git checkout HEAD~1 lib/main.dart pubspec.yaml

# Build baseline
flutter build apk --release \
  --dart-define="QUICUI_IS_FORK=true" \
  --dart-define="QUICUI_FLUTTER_VERSION=3.38.0-1.0.pre-350" \
  --dart-define="QUICUI_SDK_CHANNEL=[user-branch]" \
  --dart-define="QUICUI_DART_VERSION=3.11.0"

cp build/app/outputs/flutter-apk/app-release.apk /tmp/app-v1.0.0.apk
```

**Build Patched (v1.0.1)**:
```bash
# Restore changes
git checkout lib/main.dart pubspec.yaml

# Build patched
flutter build apk --release \
  --dart-define="QUICUI_IS_FORK=true" \
  --dart-define="QUICUI_FLUTTER_VERSION=3.38.0-1.0.pre-350" \
  --dart-define="QUICUI_SDK_CHANNEL=[user-branch]" \
  --dart-define="QUICUI_DART_VERSION=3.11.0"

cp build/app/outputs/flutter-apk/app-release.apk /tmp/app-v1.0.1.apk
```

**Generate Patch**:
```bash
cd packages/quicui_compiler

dart run bin/quicui_compiler.dart generate-patch \
  --baseline /tmp/app-v1.0.0.apk \
  --target /tmp/app-v1.0.1.apk \
  --output /tmp/patch-1.0.0-1.0.1.patch

# Verify patch
ls -lh /tmp/patch-1.0.0-1.0.1.patch
```

### Step 3: Upload Patch to Backend
```bash
# Create patch metadata
cat > /tmp/patch-metadata.json << 'EOF'
{
  "patchId": "patch-1.0.0-1.0.1",
  "appId": "com.quicui.testapp",
  "fromVersion": "1.0.0",
  "toVersion": "1.0.1",
  "releaseNotes": "OTA update with UI improvements"
}
EOF

# Upload to backend
curl -X POST http://localhost:8080/patches \
  -F "patchFile=@/tmp/patch-1.0.0-1.0.1.patch" \
  -F "metadata=@/tmp/patch-metadata.json"
```

### Step 4: Test on Device
1. **Restart the app** on device
2. **Monitor logs**: `flutter logs -d BLZ5GBY23JB034715`
3. **Expected behavior**:
   - App checks for patches
   - Finds patch 1.0.0 → 1.0.1
   - Downloads patch
   - Applies patch
   - UI updates show new text: "Welcome to QuicUI Code Push v1.0.1 🚀"

## Helper Commands

**Check Backend Health**:
```bash
curl http://localhost:8080/health
```

**View Device Logs**:
```bash
flutter logs -d BLZ5GBY23JB034715 | grep -i patch
```

**Kill Backend**:
```bash
pkill -9 dart
```

**Restart Backend**:
```bash
cd packages/quicui_backend
export $(cat .env.local | grep -v "^#" | xargs)
dart run bin/server.dart
```

## Files Reference

- **Test App**: `/Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1/`
- **Backend**: `/Users/admin/Documents/quicui2/packages/quicui_backend/`
- **Compiler**: `/Users/admin/Documents/quicui2/packages/quicui_compiler/`
- **Plan**: `.azure/PATCH_TESTING_ROADMAP.md`

---

**Ready to proceed with patch testing!** ✅
