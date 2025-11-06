# Next Steps: Production-Ready Patch System

**Date**: November 4, 2025  
**Current Status**: PoC working with bspatch  
**Target**: Production-ready kernel-based patching (Shorebird approach)

---

## Current Situation Analysis

### ✅ What We Have Working

1. **Engine Integration**
   - Rust updater library integrated into Flutter engine
   - C++ QuicUI module in `shell/common/quicui/`
   - Engine checks for patches before loading libapp.so
   - Hooks in `flutter_main.cc` and `platform_view_android_jni_impl.cc`

2. **Patch Application**
   - Native bspatch working (7KB patch → 2.9MB output in 26ms)
   - BZ2 decompression functioning
   - Patch detection and loading verified
   - No crashes with proper `super.onCreate()` call

3. **Infrastructure**
   - Modified Flutter SDK in `forks/flutter-quicui/`
   - Build scripts and testing setup
   - Minimal test app working

### ❌ Critical Issues

1. **APK Size**
   - Bundled bspatch binary: ~300KB overhead
   - Increases every app by 300KB+ unnecessarily

2. **App Store Compliance**
   - Native binaries may violate App Store policies
   - Dynamic native code loading is restricted
   - Current approach won't work on iOS

3. **Maintenance**
   - Complex native code (C++, JNI, Kotlin)
   - Platform-specific implementations needed
   - Security concerns with embedded binaries

4. **Infinite Restart Loop**
   - Patch file not deleted after application
   - Scoped storage restrictions
   - Requires manual intervention

---

## The Shorebird Way (Target Architecture)

### Key Difference: **Patch Dart Code, Not Native Libraries**

Shorebird doesn't patch `libapp.so` (the native library). Instead, they patch the **Dart kernel** (compiled Dart code).

### Why This Is Better

| Aspect | Current (libapp.so) | Target (Kernel) |
|--------|---------------------|-----------------|
| **File being patched** | libapp.so (3.67MB) | kernel_blob.bin (~2MB) |
| **Patch size** | 7KB | 10-50KB |
| **APK overhead** | +300KB (bspatch) | +10KB (Dart code) |
| **Platforms** | Android only | All platforms |
| **App Store** | Risky | ✅ Compliant |
| **Native code** | Yes (security risk) | No (pure Dart) |
| **Complexity** | High | Low |

---

## Recommended Path Forward

### Option A: Kernel Patching (Recommended - 3-4 days)

**Pros:**
- ✅ App Store compliant
- ✅ 360KB smaller APKs
- ✅ Cross-platform (iOS, web, desktop)
- ✅ Simpler, maintainable
- ✅ Industry standard (Shorebird uses this)

**Cons:**
- Requires engine modifications
- Different patch generation process
- Need to learn Dart kernel format

**Implementation:**

1. **Day 1: Engine Modifications**
   - Modify `shell/common/quicui/quicui.cc` to check for kernel patches
   - Instead of patching libapp.so, load patched `kernel_blob.bin`
   - Update Rust updater to handle kernel files

2. **Day 2: Patch Generation**
   - Create script to extract kernel from APK
   - Generate binary diffs between kernels
   - Sign patches with Ed25519

3. **Day 3: Dart Integration**
   - Update `quicui_client` package
   - Download and verify kernel patches
   - Store in app directory

4. **Day 4: Testing**
   - E2E testing
   - Rollback mechanism
   - Production deployment

### Option B: Fix Current System (Quick Fix - 1 day)

**Pros:**
- Quick to implement
- Already working

**Cons:**
- ❌ Still 300KB overhead
- ❌ Still App Store issues
- ❌ Still Android-only
- ❌ Technical debt

**Implementation:**

1. **Morning: Fix Restart Loop**
   ```kotlin
   // PatchLoader.kt - Use version tracking instead of file deletion
   fun checkAndApplyPatch(context: Context): Boolean {
       val prefs = context.getSharedPreferences("quicui_patch", MODE_PRIVATE)
       val appliedVersion = prefs.getString("applied_patch_version", null)
       val availablePatch = findPatchFile()
       
       if (availablePatch != null && availablePatch.version != appliedVersion) {
           applyPatch(availablePatch)
           prefs.edit().putString("applied_patch_version", availablePatch.version).apply()
           return true
       }
       return false
   }
   ```

2. **Afternoon: Polish & Deploy**
   - Add version metadata to patches
   - Test restart flow
   - Deploy to test users

---

## Detailed Implementation: Option A (Kernel Patching)

### Step 1: Understand Current System

**Current Flow:**
```
App starts
  ↓
FlutterMain.startInitialization()
  ↓
ConfigureQuicUI() ← checks for patched libapp.so
  ↓
If patch found: settings.application_library_path = patch_path
  ↓
DartVM loads libapp.so (either original or patched)
  ↓
App runs
```

**What libapp.so contains:**
- AOT-compiled Dart code
- Flutter engine embedder
- Dart VM isolate snapshot
- **Kernel blob** ← This is what we should patch!

### Step 2: Extract Kernel from libapp.so

Libapp.so structure:
```
libapp.so:
├─ ELF header
├─ AOT compiled code
├─ VM isolate snapshot
└─ kernel_blob.bin ← Embedded here
```

**Extract kernel:**
```bash
# Method 1: Use Flutter tools
flutter analyze --dart-define=FLUTTER_TEST=true

# Method 2: Manual extraction (libapp.so has embedded kernel)
objcopy --dump-section .rodata=kernel.bin libapp.so
```

### Step 3: Modify Engine to Load External Kernel

**File: `shell/common/quicui/quicui.cc`**

```cpp
void ConfigureQuicUI(...) {
    // ... existing code ...
    
    // NEW: Check for kernel patch instead of libapp patch
    char* kernel_patch_path = quicui_get_kernel_patch_path();
    if (kernel_patch_path != nullptr) {
        std::string patch_path_str(kernel_patch_path);
        quicui_free_string(kernel_patch_path);
        
        FML_LOG(INFO) << "QuicUI: Found kernel patch: " << patch_path_str;
        
        // Load external kernel instead of embedded one
        settings.kernel_blob_path = patch_path_str;
        settings.use_external_kernel = true;
        
        FML_LOG(INFO) << "QuicUI: Will load patched kernel";
    }
}
```

**File: `runtime/dart_vm.cc`** (may need modification)

```cpp
bool DartVM::LoadKernel() {
    if (settings.use_external_kernel && !settings.kernel_blob_path.empty()) {
        // Load kernel from external file
        auto kernel_mapping = fml::FileMapping::CreateReadOnly(
            settings.kernel_blob_path);
        
        if (kernel_mapping && VerifyKernelSignature(kernel_mapping)) {
            return LoadKernelFromMapping(kernel_mapping);
        }
        
        FML_LOG(WARNING) << "Failed to load external kernel, using default";
    }
    
    // Fall back to embedded kernel in libapp.so
    return LoadEmbeddedKernel();
}
```

### Step 4: Generate Kernel Patches

**Script: `scripts/generate_kernel_patch.sh`**

```bash
#!/bin/bash
set -e

OLD_APK=$1
NEW_APK=$2
OUTPUT_PATCH=$3

echo "🔧 Generating kernel patch..."

# 1. Extract libapp.so from both APKs
unzip -q "$OLD_APK" lib/arm64-v8a/libapp.so -d /tmp/old_apk
unzip -q "$NEW_APK" lib/arm64-v8a/libapp.so -d /tmp/new_apk

# 2. Extract kernels from libapp.so files
extract_kernel() {
    local libapp=$1
    local output=$2
    
    # Kernel is at known offset in libapp.so
    # Find it using magic bytes: "KRNL" or use Flutter tool
    /Users/admin/Documents/quicui2/forks/flutter-quicui/bin/flutter \
        analyze --extract-kernel "$libapp" "$output"
}

extract_kernel "/tmp/old_apk/lib/arm64-v8a/libapp.so" "/tmp/old_kernel.bin"
extract_kernel "/tmp/new_apk/lib/arm64-v8a/libapp.so" "/tmp/new_kernel.bin"

# 3. Generate binary diff
bsdiff /tmp/old_kernel.bin /tmp/new_kernel.bin "$OUTPUT_PATCH"

# 4. Sign patch
./scripts/sign_patch.sh "$OUTPUT_PATCH"

# 5. Report
OLD_SIZE=$(stat -f%z /tmp/old_kernel.bin)
NEW_SIZE=$(stat -f%z /tmp/new_kernel.bin)
PATCH_SIZE=$(stat -f%z "$OUTPUT_PATCH")

echo "✅ Kernel patch generated:"
echo "   Old kernel: ${OLD_SIZE} bytes"
echo "   New kernel: ${NEW_SIZE} bytes"
echo "   Patch size: ${PATCH_SIZE} bytes"
echo "   Compression: $(awk "BEGIN {printf \"%.1f\", 100-($PATCH_SIZE*100/$NEW_SIZE)}")%"
```

### Step 5: Update Rust Updater

**File: `third_party/quicui_updater/library/src/updater.rs`**

```rust
impl Updater {
    pub fn next_boot_patch_path(&self) -> Option<String> {
        // OLD: Return patched libapp.so path
        // NEW: Return patched kernel.bin path
        
        let patch_dir = PathBuf::from(&self.app_storage_dir)
            .join("patches");
        
        let kernel_patch = patch_dir.join("kernel.bin");
        if kernel_patch.exists() {
            // Verify signature
            if self.verify_kernel_signature(&kernel_patch) {
                return Some(kernel_patch.to_string_lossy().to_string());
            } else {
                // Bad signature, delete patch
                let _ = std::fs::remove_file(&kernel_patch);
            }
        }
        
        None
    }
    
    fn verify_kernel_signature(&self, path: &PathBuf) -> bool {
        // Ed25519 signature verification
        let kernel_data = std::fs::read(path).ok()?;
        let signature = self.get_patch_signature()?;
        
        // Verify using embedded public key
        ed25519_dalek::verify_detached(
            &signature,
            &kernel_data,
            &self.public_key
        ).is_ok()
    }
}
```

### Step 6: Update Dart Client

**File: `packages/quicui_client/lib/src/update_manager.dart`**

```dart
class UpdateManager {
  Future<bool> checkForUpdates() async {
    final response = await http.get(
      Uri.parse('$_backendUrl/api/patches/check'),
      headers: {
        'X-App-ID': _appId,
        'X-Version': _currentVersion,
        'X-Platform': 'android', // or iOS, web, etc.
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['patch_available'] == true) {
        return await _downloadKernelPatch(data);
      }
    }
    return false;
  }
  
  Future<bool> _downloadKernelPatch(Map<String, dynamic> patchInfo) async {
    // 1. Download kernel patch
    final patchUrl = patchInfo['download_url'];
    final response = await http.get(Uri.parse(patchUrl));
    
    if (response.statusCode != 200) return false;
    
    // 2. Verify signature
    final signature = base64Decode(patchInfo['signature']);
    if (!_verifySignature(response.bodyBytes, signature)) {
      return false;
    }
    
    // 3. Save to patches/ directory
    final patchDir = await _getPatchDirectory();
    final kernelFile = File('${patchDir.path}/kernel.bin');
    await kernelFile.writeAsBytes(response.bodyBytes);
    
    // 4. Save metadata
    await _saveMetadata(patchInfo);
    
    return true;
  }
  
  bool _verifySignature(Uint8List data, Uint8List signature) {
    // Use ed25519_dart package
    final publicKey = ed25519.PublicKey(base64Decode(_embeddedPublicKey));
    final sig = ed25519.Signature(signature);
    return ed25519.verify(publicKey, data, sig);
  }
}
```

---

## Migration Strategy

### Week 1: Development
- Day 1-2: Engine modifications
- Day 3-4: Patch generation tooling
- Day 5: Testing & validation

### Week 2: Testing
- Day 1-2: Internal testing
- Day 3-4: Beta testing (10% of users)
- Day 5: Monitor metrics

### Week 3: Rollout
- Day 1: 25% rollout
- Day 2: 50% rollout
- Day 3: 75% rollout
- Day 4: 100% rollout
- Day 5: Remove old bspatch code

---

## Success Metrics

### Before (Current System)
- APK size: 18.9MB + 0.3MB (bspatch) = 19.2MB
- Patch time: 26ms
- Platforms: Android only
- Restart: Infinite loop

### After (Kernel Patching)
- APK size: 18.9MB + 0.01MB (Dart code) = 18.91MB
- Patch time: <5ms
- Platforms: Android, iOS, Web, Desktop
- Restart: Clean, one-time

**Total savings: ~300KB per app × millions of users = significant**

---

## Recommendation

**Go with Option A (Kernel Patching)** because:

1. ✅ **Future-proof**: Works on all platforms
2. ✅ **App Store compliant**: No native binary loading
3. ✅ **Smaller**: 360KB savings per app
4. ✅ **Simpler**: Less native code to maintain
5. ✅ **Industry standard**: Same as Shorebird

The upfront investment of 3-4 days will pay off massively in the long term.

---

## Next Immediate Actions

### 1. Decision (30 minutes)
- Review this document
- Choose Option A or Option B
- Get stakeholder approval

### 2. If Option A (Kernel Patching)
```bash
# Start with engine modifications
cd /Volumes/DoWonder2/quicui_engine_build/official_engine/src/flutter

# Backup current code
git checkout -b feature/kernel-patching

# Modify quicui.cc to support kernel patches
vim shell/common/quicui/quicui.cc

# Update Rust updater
cd third_party/quicui_updater/library
vim src/updater.rs
```

### 3. If Option B (Quick Fix)
```bash
# Fix restart loop
cd /Users/admin/Documents/quicui2/test_apps/minimal_patch_test
vim android/app/src/main/kotlin/.../PatchLoader.kt

# Add version tracking
# Test and deploy
```

---

## Questions?

**Q: Can we use both systems temporarily?**  
A: Yes, keep bspatch for Android while developing kernel patching. Migrate gradually.

**Q: What about iOS?**  
A: Kernel patching works on iOS. Bspatch doesn't.

**Q: How long until production-ready?**  
A: Option A: 3-4 days development + 1-2 weeks testing = 3 weeks total  
   Option B: 1 day development + 3 days testing = 4 days total

**Q: What does Shorebird use?**  
A: Kernel patching (Option A). They don't patch libapp.so.

---

**Decision needed**: Which option do you want to pursue?
