# Production-Ready Patch System - Implementation Plan

**Date**: November 4, 2025  
**Status**: Design Phase  
**Goal**: Replace current bspatch implementation with Shorebird-style kernel patching

---

## Problems with Current Implementation

### 1. **Native Binary Dependency**
- ❌ Bundled `bspatch` binary adds ~300KB to APK
- ❌ Native C++ code (JNI) may violate App Store policies
- ❌ Requires compilation for each architecture (arm64, arm32, x86)
- ❌ Security concerns with embedded binaries

### 2. **libapp.so Patching Complexity**
- ❌ Need to extract libapp.so from APK at runtime
- ❌ Patch must be applied to 3.67MB file (slow)
- ❌ Can't load patched library without restart
- ❌ Infinite restart loop issues

### 3. **Platform-Specific Issues**
- ❌ Android scoped storage prevents patch file deletion
- ❌ iOS would require completely different approach
- ❌ Not scalable to web/desktop platforms

---

## Shorebird's Approach (The Right Way)

### Key Insight: **Patch Dart Kernel, Not Native Code**

Shorebird doesn't patch `libapp.so`. They patch the **Dart kernel** (the compiled Dart code that runs on the Dart VM).

### Why This Works

1. **Kernel is Dart Code** → Pure Dart patching, no native binaries needed
2. **Small Files** → Kernel is typically 2-5MB, patches are 10-100KB
3. **Engine Support** → Engine checks for patched kernel at startup
4. **Cross-Platform** → Same approach works on all platforms
5. **App Store Safe** → No dynamic native code loading

---

## Proposed Architecture

### Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     QuicUI App                               │
├─────────────────────────────────────────────────────────────┤
│  Dart Code (lib/)                                            │
│  ├─ UpdateManager (check for patches)                       │
│  ├─ PatchDownloader (download & verify)                     │
│  └─ PatchStorage (save to app directory)                    │
├─────────────────────────────────────────────────────────────┤
│  Modified Flutter Engine                                     │
│  ├─ Kernel Loader (checks for patches)                      │
│  ├─ Patch Verifier (signature check)                        │
│  └─ Rollback Manager (safety net)                           │
├─────────────────────────────────────────────────────────────┤
│  Platform (Android/iOS)                                      │
│  └─ App-specific storage                                     │
│      └─ patches/                                             │
│          ├─ kernel_patch_v1.0.1.bin                         │
│          └─ metadata.json                                    │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

#### 1. Check for Updates (Background)
```
App running
  ↓
Dart: UpdateManager.checkForUpdates()
  ↓
HTTP: GET /api/patches/check?version=1.0.0
  ↓
Backend: Returns patch if available
  ↓
Dart: Download patch binary
  ↓
Dart: Verify signature
  ↓
Dart: Save to patches/kernel_patch_v1.0.1.bin
  ↓
Dart: Notify user (optional)
```

#### 2. Apply Patch (Next Launch)
```
App starts
  ↓
Engine: Initialize
  ↓
C++: CheckForPatchedKernel()
  ↓
C++: Found patches/kernel_patch_v1.0.1.bin
  ↓
C++: Verify signature (Ed25519)
  ↓
C++: Load patched kernel into Dart VM
  ↓
Dart VM: Run with patched code
  ↓
App: Running with update!
```

#### 3. Rollback (If Crash Detected)
```
App crashes 3 times
  ↓
Engine: Detect crash pattern
  ↓
C++: Delete patched kernel
  ↓
C++: Mark patch as bad
  ↓
Next launch: Load default kernel
  ↓
App: Running with safe code
```

---

## Implementation Steps

### Phase 1: Engine Modifications (1-2 days)

#### File: `shell/common/engine.cc`

**Add patch checking before kernel load:**

```cpp
// New function
std::unique_ptr<fml::Mapping> Engine::LoadKernel() {
  // 1. Check for patched kernel
  auto patched_kernel = patch_loader_->LoadPatchedKernel();
  
  if (patched_kernel && VerifyPatchSignature(patched_kernel)) {
    FML_LOG(INFO) << "QuicUI: Loading patched kernel";
    return patched_kernel;
  }
  
  // 2. Fall back to default kernel
  FML_LOG(INFO) << "QuicUI: Loading default kernel";
  return LoadDefaultKernel();
}
```

#### File: `shell/platform/android/platform_view_android.cc`

**Add patch storage helper:**

```cpp
std::string GetPatchDirectory() {
  // Returns: /data/data/<package>/files/patches/
  JNIEnv* env = fml::jni::AttachCurrentThread();
  jobject context = GetApplicationContext();
  jobject files_dir = env->CallObjectMethod(
      context, GetFilesDir());
  
  std::string path = JavaStringToString(env, files_dir);
  return path + "/patches/";
}
```

#### File: `runtime/dart_vm.cc`

**Add patched kernel support:**

```cpp
bool DartVM::LoadKernel(std::unique_ptr<fml::Mapping> kernel) {
  // Existing code, just ensure it works with external kernels
  // No changes needed if engine.cc handles loading
}
```

### Phase 2: Dart Patch Manager (1 day)

#### File: `packages/quicui_client/lib/src/patch_manager.dart`

```dart
class PatchManager {
  static const String _patchDir = 'patches';
  
  /// Check for available patches
  Future<PatchInfo?> checkForUpdates() async {
    final response = await http.get(
      Uri.parse('$_backendUrl/api/patches/check'),
      headers: {
        'X-App-ID': _appId,
        'X-Version': _currentVersion,
        'X-Platform': Platform.operatingSystem,
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PatchInfo.fromJson(data);
    }
    return null;
  }
  
  /// Download and verify patch
  Future<bool> downloadPatch(PatchInfo info) async {
    // 1. Download patch binary
    final patchData = await _downloadPatchBinary(info.downloadUrl);
    
    // 2. Verify signature
    if (!_verifySignature(patchData, info.signature)) {
      return false;
    }
    
    // 3. Save to app directory
    final patchFile = await _getPatchFile(info.version);
    await patchFile.writeAsBytes(patchData);
    
    // 4. Save metadata
    await _saveMetadata(info);
    
    return true;
  }
  
  /// Get patch directory
  Future<Directory> _getPatchDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final patchDir = Directory('${appDir.path}/$_patchDir');
    if (!await patchDir.exists()) {
      await patchDir.create(recursive: true);
    }
    return patchDir;
  }
  
  /// Verify Ed25519 signature
  bool _verifySignature(Uint8List data, String signature) {
    // Use ed25519_dart package
    final publicKey = ed25519.PublicKey(base64Decode(_publicKey));
    final sig = ed25519.Signature(base64Decode(signature));
    
    return ed25519.verify(publicKey, data, sig);
  }
}
```

### Phase 3: Patch Generation Tool (1 day)

#### Script: `scripts/generate_kernel_patch.sh`

```bash
#!/bin/bash
# Generate kernel patch between two app versions

OLD_VERSION=$1
NEW_VERSION=$2

echo "🔧 Generating kernel patch: $OLD_VERSION → $NEW_VERSION"

# 1. Extract kernels from APKs
OLD_KERNEL=$(extract_kernel "app-v$OLD_VERSION.apk")
NEW_KERNEL=$(extract_kernel "app-v$NEW_VERSION.apk")

# 2. Generate binary diff
bsdiff "$OLD_KERNEL" "$NEW_KERNEL" "patch-$NEW_VERSION.bin"

# 3. Sign patch
./scripts/sign_patch.sh "patch-$NEW_VERSION.bin"

# 4. Verify
PATCH_SIZE=$(stat -f%z "patch-$NEW_VERSION.bin")
echo "✅ Patch generated: ${PATCH_SIZE} bytes"
```

### Phase 4: Backend Integration (1 day)

#### Endpoint: `POST /api/patches/check`

```json
Request:
{
  "app_id": "com.example.app",
  "current_version": "1.0.0",
  "platform": "android",
  "architecture": "arm64"
}

Response (patch available):
{
  "patch_available": true,
  "target_version": "1.0.1",
  "download_url": "https://cdn.../patch-1.0.1.bin",
  "signature": "base64_ed25519_signature",
  "size": 85234,
  "required": false
}

Response (no patch):
{
  "patch_available": false
}
```

---

## File Size Comparison

### Current Implementation (with bspatch)
```
APK size increase:
- bspatch binary: ~300KB
- JNI wrapper: ~50KB
- Kotlin code: ~20KB
Total: ~370KB overhead

Patch file: 7KB (for UI change)
```

### Proposed Implementation (kernel patching)
```
APK size increase:
- Engine modifications: 0KB (compiled into existing engine)
- Dart patch manager: ~10KB
- No native binaries: 0KB
Total: ~10KB overhead

Patch file: 10-50KB (typical UI/logic change)
```

**Size savings: ~360KB per app**

---

## Security

### Signature Verification

1. **Ed25519 Signatures**
   - Fast verification (~50 microseconds)
   - 64-byte signatures
   - Industry standard (used by Signal, WhatsApp)

2. **Key Management**
   - Public key embedded in app
   - Private key secured on backend
   - Rotation mechanism for compromised keys

3. **Verification Flow**
   ```
   Patch downloaded
     ↓
   Hash patch data (SHA-256)
     ↓
   Verify Ed25519 signature
     ↓
   Check: signature valid?
     ↓
   Yes: Apply patch
   No: Delete and report
   ```

### Rollback Safety

1. **Crash Detection**
   - Track app starts vs. successful runs
   - If crash within 10 seconds of start → bad patch
   - After 3 crashes → auto-rollback

2. **Rollback Mechanism**
   ```cpp
   if (DetectBadPatch()) {
     DeletePatchedKernel();
     MarkPatchAsBad();
     LoadDefaultKernel();
   }
   ```

---

## Benefits Over Current Approach

| Aspect | Current (bspatch) | Proposed (Kernel) |
|--------|-------------------|-------------------|
| APK size | +370KB | +10KB |
| Platform support | Android only | All platforms |
| App Store compliance | Questionable | ✅ Compliant |
| Patch speed | Slow (26ms) | Fast (<5ms) |
| Restart required | Yes (infinite loop) | Yes (clean) |
| Complexity | High (native code) | Low (Dart + Engine) |
| Security | Manual verification | Built-in signing |
| Rollback | Manual | Automatic |

---

## Migration Path

### Step 1: Parallel Implementation
- Keep existing bspatch system working
- Add new kernel patching alongside
- Test both systems in parallel

### Step 2: Gradual Rollout
- 10% of users get kernel patches
- Monitor crash rates, performance
- 50% → 100% over 2 weeks

### Step 3: Deprecation
- Stop generating libapp.so patches
- Generate only kernel patches
- Remove bspatch code after 30 days

---

## Testing Strategy

### Unit Tests
```dart
test('PatchManager downloads and verifies patch', () async {
  final manager = PatchManager();
  final info = PatchInfo(version: '1.0.1', ...);
  
  final success = await manager.downloadPatch(info);
  expect(success, true);
  
  final patchFile = await manager.getPatchFile('1.0.1');
  expect(await patchFile.exists(), true);
});

test('Invalid signature is rejected', () async {
  final manager = PatchManager();
  final badPatch = createInvalidPatch();
  
  final success = await manager.downloadPatch(badPatch);
  expect(success, false);
});
```

### Integration Tests
```dart
testWidgets('App updates and shows new UI', (tester) async {
  // 1. Start app with v1.0.0
  await tester.pumpWidget(MyApp());
  expect(find.text('Version 1.0.0'), findsOneWidget);
  
  // 2. Download patch in background
  await PatchManager.checkAndApply();
  
  // 3. Restart app
  await tester.pumpWidget(MyApp());
  
  // 4. Verify new version
  expect(find.text('Version 1.0.1'), findsOneWidget);
});
```

### Engine Tests
```cpp
TEST_F(EngineTest, LoadsPatchedKernelWhenAvailable) {
  // Setup: Create mock patched kernel
  auto patch = CreateMockPatch();
  WritePatchToDisk(patch);
  
  // Execute: Start engine
  auto engine = CreateEngine();
  
  // Verify: Patched kernel was loaded
  EXPECT_TRUE(engine->IsUsingPatchedKernel());
}

TEST_F(EngineTest, FallsBackToDefaultOnBadSignature) {
  // Setup: Create invalid patch
  auto bad_patch = CreateInvalidPatch();
  WritePatchToDisk(bad_patch);
  
  // Execute: Start engine
  auto engine = CreateEngine();
  
  // Verify: Default kernel loaded
  EXPECT_FALSE(engine->IsUsingPatchedKernel());
  EXPECT_TRUE(IsPatchMarkedAsBad());
}
```

---

## Next Steps

### Immediate (Today)
1. ✅ Document current issues
2. ✅ Research Shorebird approach
3. 🔄 Create implementation plan

### Short Term (This Week)
1. [ ] Modify engine to support kernel patching
2. [ ] Build modified engine for Android
3. [ ] Create Dart PatchManager package
4. [ ] Test kernel patch generation

### Medium Term (Next Week)
1. [ ] Integrate with backend
2. [ ] Add signature verification
3. [ ] Implement rollback mechanism
4. [ ] E2E testing

### Long Term (Next Month)
1. [ ] iOS support
2. [ ] Web support (if applicable)
3. [ ] Production deployment
4. [ ] Migration from bspatch system

---

## Resources

### Code References
- Shorebird Engine: `github.com/shorebirdtech/engine`
- Flutter Engine: `github.com/flutter/engine`
- Dart Kernel Format: `github.com/dart-lang/sdk/wiki/Kernel-Documentation`

### Crypto Libraries
- Ed25519 (Dart): `pub.dev/packages/ed25519_dart`
- Ed25519 (C++): `libsodium`

### Tools
- `bsdiff`: Binary diff tool (for kernel patches)
- `unzip`: Extract kernels from APK/IPA

---

## Conclusion

By switching from libapp.so patching to kernel patching, we achieve:

✅ **Smaller APK size** (~360KB savings)  
✅ **App Store compliance** (no native binaries)  
✅ **Cross-platform support** (same approach everywhere)  
✅ **Better security** (built-in signing)  
✅ **Automatic rollback** (safety net)  
✅ **Cleaner implementation** (mostly Dart)  

This is the **production-ready approach** that Shorebird uses successfully with thousands of apps.

**Decision**: Proceed with kernel-based patching implementation.
