# Build Configuration for QuicUI Code Push Test

**Date**: November 1, 2025  
**Build Type**: Release APK with QuicUI Flutter SDK  
**Target**: Local Network Testing at 192.168.20.100:8080

---

## Environment Configuration

### Flutter SDK Configuration
```bash
# Using QuicUI Fork of Flutter SDK
export FLUTTER_SDK=/path/to/QuicUIFlutterSDK
export PATH=$FLUTTER_SDK/bin:$PATH

# Verify QuicUI Fork is active
flutter --version  # Should show custom fork info
flutter channel  # Should show custom branch
```

### Build Parameters
- **Platform**: Android
- **Build Type**: Release
- **APK Output**: `build/app/outputs/flutter-apk/app-release.apk`
- **No Obfuscation**: Enabled (for debugging)
- **Code Push Support**: Enabled

### Target Configuration
- **Backend Endpoint**: http://192.168.20.100:8080
- **Test App Version**: v1.0.0
- **Patch Version Target**: v1.0.1
- **Network**: Local LAN (192.168.x.x)

---

## Build Steps

### Step 1: Prepare Build Environment
```bash
cd /Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1

# Get dependencies
flutter pub get

# Clean build directory
flutter clean
```

### Step 2: Verify QuicUI SDK
```bash
# Check SDK version
flutter doctor

# Verify custom fork
flutter config --list | grep flutter-root

# Expected output: Should point to QuicUI fork
```

### Step 3: Build Release APK (Baseline v1.0.0)
```bash
flutter build apk \
  --release \
  --no-obfuscate \
  --no-shrink \
  -v
```

### Step 4: Generate v1.0.1 for Patching
```bash
# Update version in pubspec.yaml to 1.0.1
# Make minimal UI changes
# Generate patch using quicui_compiler

quicui_compiler build \
  --from baseline-v1.0.0.dill \
  --to target-v1.0.1.dill \
  --output patch-v1.0.1.zip
```

### Step 5: Upload Patch to Backend
```bash
curl -X POST http://192.168.20.100:8080/api/v1/patches \
  -H "Content-Type: application/json" \
  -d '{
    "patchData": "<base64-encoded-patch>",
    "fromVersion": "1.0.0",
    "toVersion": "1.0.1"
  }'
```

---

## Build Output Paths

```
quicui_test_app_v1/
├── build/
│   ├── app/outputs/flutter-apk/
│   │   └── app-release.apk          ← Main release APK
│   └── app/outputs/bundle/release/
│       └── app-release.aab          ← App bundle
└── .dart_tool/                      ← Flutter cache
```

---

## QuicUI Flutter SDK Requirements

### Patches Applied
1. **CodePush Loader** - C++ core implementation
2. **Engine Integration** - Flutter engine hooks
3. **Dart VM Support** - Kernel loading

### Engine Features Enabled
- Async patch checking
- Binary patch verification
- Intelligent kernel caching
- Thread-safe operations

### Build Configuration
- `engine/src/flutter/runtime/codepush_loader.cc`
- `engine/src/flutter/runtime/dart_vm.cc`
- `third_party/dart/runtime/vm/kernel_loader.cc`

---

## Testing Verification

### Pre-Build Checks
- [ ] QuicUI Flutter SDK is active
- [ ] Version shows custom fork
- [ ] Dependencies are installed
- [ ] 192.168.20.100 is reachable
- [ ] Backend (8080) is ready

### Build Checks
- [ ] APK builds without errors
- [ ] APK is signed
- [ ] APK is ~50MB (typical size)
- [ ] APK contains QuicUI patches

### Post-Build Checks
- [ ] APK installs on device
- [ ] App launches successfully
- [ ] SDK detection shows QuicUI fork
- [ ] Backend endpoint is reachable
- [ ] Patch check button works

---

## Network Configuration

### Local Network Setup
```
Device (192.168.20.x)
         ↓ (Patch Check)
    192.168.20.100:8080
    (Backend Server)
         ↓ (Patch Data)
    Device receives patch
         ↓ (Apply)
    Dart VM patching
         ↓
    UI updates instantly
```

### Firewall Rules
- [ ] Port 8080 open on PC (192.168.20.100)
- [ ] Device can ping PC
- [ ] HTTP traffic allowed (not HTTPS in test)
- [ ] No proxy interfering with connection

### Endpoint Details
- **Protocol**: HTTP (not HTTPS for local testing)
- **Host**: 192.168.20.100
- **Port**: 8080
- **Base Path**: /api/v1

---

## Build Artifacts

### v1.0.0 Baseline
- **File**: `app-release-v1.0.0.apk`
- **Size**: ~50-60MB
- **Signature**: Enabled
- **Contains**: Base app code

### v1.0.1 Patch
- **File**: `patch-v1.0.1.bin`
- **Size**: ~100-500KB (typically 85% smaller)
- **Signature**: Ed25519 signed
- **Contains**: Only changed code

---

## Build Command Examples

### Quick Build
```bash
flutter build apk --release --no-obfuscate
```

### Verbose Build
```bash
flutter build apk --release --no-obfuscate -v
```

### Clean Build
```bash
flutter clean && flutter build apk --release --no-obfuscate
```

### With Split APK (Smaller Download)
```bash
flutter build apk --release --split-per-abi
```

---

## Troubleshooting

### Issue: "SDK not found"
```bash
# Verify FLUTTER_SDK is set
echo $FLUTTER_SDK

# Check QuicUI fork
flutter config --list | grep flutter-root
```

### Issue: "Port 8080 not reachable"
```bash
# Test connectivity
ping 192.168.20.100

# Test port
nc -zv 192.168.20.100 8080
```

### Issue: "APK build fails"
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release --no-obfuscate -v
```

### Issue: "Patch not applying"
```bash
# Check patch signature
quicui_compiler verify --patch patch-v1.0.1.bin

# Check backend logs
curl http://192.168.20.100:8080/api/v1/health
```

---

## Performance Metrics Expected

| Operation | Baseline | With Patch | Improvement |
|-----------|----------|-----------|-------------|
| **App Size** | 55MB | 55MB | 0% (patch separate) |
| **Init Time** | 1.2s | 1.3s | +0.1s (negligible) |
| **Patch Check** | - | <5s | Fast HTTP request |
| **Patch Download (500KB)** | - | ~3s | Fast LAN speed |
| **Patch Apply** | - | <2s | Dart VM fast |
| **Total Deployment** | - | ~10s | Faster than app store |

---

## Success Criteria

✅ **Build**
- APK builds without errors
- APK contains QuicUI SDK patches
- APK is signed and installable

✅ **Network**
- Device reaches 192.168.20.100:8080
- Backend responds to health checks
- HTTP requests work without HTTPS

✅ **App Launch**
- App installs successfully
- App launches without crashes
- SDK detection shows QuicUI fork

✅ **Patch Detection**
- App detects available patches
- Backend returns patch metadata
- Patch downloads successfully

✅ **Patch Application**
- Patch applies without restart
- UI updates are visible
- Version info updates to v1.0.1

✅ **Verification**
- App continues running
- All features work
- No memory leaks
- No crashes

---

**Build Configuration Complete**  
Ready for APK generation and local network testing  
Date: November 1, 2025
