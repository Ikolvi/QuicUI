# QuicUI Engine Modification Guide: Kernel → AOT Patching

**Status**: 🚧 IMPLEMENTATION IN PROGRESS  
**Date**: November 1, 2025  
**Branch**: `develop`

---

## 📋 Overview

This document outlines the engine modifications needed to transition from **kernel patching** (JIT/Profile mode) to **AOT snapshot patching** (Release mode) for the QuicUI Code Push system.

### Why This Change?

| Aspect | Kernel Patching (OLD) | AOT Patching (NEW) |
|--------|----------------------|-------------------|
| **Build Mode** | Profile/Debug (JIT) | Release (AOT) |
| **Patch Target** | `kernel_blob.bin` | `libapp.so` |
| **Production Ready** | ❌ No | ✅ Yes |
| **App Size** | Larger | Optimized |
| **Performance** | Slower (JIT) | Faster (AOT) |
| **Hot Reload** | ✅ Yes | ❌ No (restart required) |
| **Industry Standard** | Uncommon | ✅ Shorebird uses this |

---

## 🎯 Goals

1. **Remove** kernel patching logic from `codepush_loader.cc`
2. **Add** AOT snapshot installation and loading
3. **Integrate** with Android's `FlutterLoader.java`
4. **Ensure** patches are validated before loading
5. **Handle** app restart requirements

---

## 📁 Files to Modify

### Core Engine Files

```
forks/flutter-official/engine/src/flutter/shell/common/
├── codepush_loader.h        (Update interface)
└── codepush_loader.cc       (Rewrite implementation)
```

### Android Platform Files

```
forks/flutter-official/engine/src/flutter/shell/platform/android/
└── io/flutter/embedding/engine/loader/
    ├── FlutterLoader.java          (Modify AOT path logic)
    └── QuicUICodePushLoader.java   (NEW - Platform integration)
```

---

## 🔄 Changes Summary

### REMOVED ❌

- `LoadPatchKernel()` - Loads JIT kernel patches
- `DartPatchLoader::LoadKernelPatch()` - Dart VM kernel API
- Kernel-specific validation logic
- Hot reload assumptions

### ADDED ✅

- `InstallAOTSnapshot()` - Copy patch to code cache
- `GetPatchedAOTPath()` - Check for installed patches
- `ValidateAOTSnapshot()` - Verify patch integrity
- Platform-specific path management
- Restart requirement handling

---

## 📝 Implementation Details

### Part 1: Update codepush_loader.h

#### Changes to `CodePushPatch` struct:

```cpp
struct CodePushPatch {
  std::string version;
  std::string platform;        // "android", "ios", "linux"
  std::string patch_hash;      // SHA256 of patched libapp.so
  std::string patch_url;       // Download URL
  uint64_t patch_size;
  std::string signature;       // Ed25519 signature
  std::string release_date;
  bool critical;
  
  // NEW: AOT-specific fields
  std::string architecture;    // "arm64-v8a", "armeabi-v7a", "x86_64"
  bool requires_restart;       // Always true for AOT patches
};
```

#### Changes to `CodePushLoader` class:

```cpp
class CodePushLoader {
 public:
  CodePushLoader();
  ~CodePushLoader();

  // Check for patches (unchanged)
  void CheckForPatches(PatchCheckCallback callback);

  // MODIFIED: Install patch instead of loading
  bool InstallPatch(const CodePushPatch& patch, PatchLoadCallback callback);

  // NEW: Get path to installed AOT patch
  std::string GetPatchedAOTPath(const std::string& architecture);

  // NEW: Check if patch is installed
  bool HasInstalledPatch();

  // NEW: Get installed patch version
  std::string GetInstalledPatchVersion();

  // NEW: Clear installed patch (rollback)
  bool ClearInstalledPatch();

  // Configuration (unchanged)
  void SetEnabled(bool enabled);
  void SetServiceUrl(const std::string& url);
  void SetAppId(const std::string& app_id);
  void SetAppVersion(const std::string& version);

 private:
  // REMOVED: LoadPatchKernel()
  
  // NEW: Install AOT snapshot to code cache
  bool InstallAOTSnapshot(const std::string& patch_path,
                         const std::string& architecture);

  // NEW: Validate AOT snapshot
  bool ValidateAOTSnapshot(const std::string& path,
                          const std::string& expected_hash);

  // NEW: Get code cache directory
  std::string GetCodeCacheDir();

  // NEW: Save patch metadata
  bool SavePatchMetadata(const CodePushPatch& patch);

  // NEW: Load patch metadata
  bool LoadPatchMetadata(CodePushPatch& patch);

  // Existing helper methods (mostly unchanged)
  bool VerifyPatchSignature(const std::string& patch_data,
                           const std::string& signature);
  std::string CalculatePatchHash(const std::string& patch_path);
  std::string FetchPatchMetadata();
  bool DownloadPatch(const std::string& url, const std::string& destination);
  void CleanupOldPatches();
};
```

### Part 2: Update codepush_loader.cc

#### Key Method: `InstallPatch()` (replaces `LoadPatch()`)

```cpp
bool CodePushLoader::InstallPatch(const CodePushPatch& patch,
                                  PatchLoadCallback callback) {
  if (!enabled_) {
    if (callback) callback(false, "Code push is disabled");
    return false;
  }

  // 1. Download patch if not cached
  std::string patch_dest = GetPatchCachePath(patch.version);
  if (!IsPatchCached(patch.version)) {
    if (!DownloadPatch(patch.patch_url, patch_dest)) {
      if (callback) callback(false, "Failed to download patch");
      return false;
    }
  }

  // 2. Verify patch hash
  std::string calculated_hash = CalculatePatchHash(patch_dest);
  if (calculated_hash != patch.patch_hash) {
    if (callback) callback(false, "Patch hash verification failed");
    return false;
  }

  // 3. Verify signature
  std::ifstream file(patch_dest, std::ios::binary);
  std::string patch_data((std::istreambuf_iterator<char>(file)),
                         std::istreambuf_iterator<char>());
  file.close();

  if (!VerifyPatchSignature(patch_data, patch.signature)) {
    if (callback) callback(false, "Signature verification failed");
    return false;
  }

  // 4. Install AOT snapshot to code cache
  if (!InstallAOTSnapshot(patch_dest, patch.architecture)) {
    if (callback) callback(false, "Failed to install AOT snapshot");
    return false;
  }

  // 5. Save patch metadata
  if (!SavePatchMetadata(patch)) {
    if (callback) callback(false, "Failed to save patch metadata");
    return false;
  }

  // 6. Cleanup old patches
  CleanupOldPatches();

  current_patch_version_ = patch.version;
  
  if (callback) {
    callback(true, "Patch installed. Restart required.");
  }

  return true;
}
```

#### Key Method: `InstallAOTSnapshot()`

```cpp
bool CodePushLoader::InstallAOTSnapshot(const std::string& patch_path,
                                       const std::string& architecture) {
  // Get code cache directory
  std::string cache_dir = GetCodeCacheDir();
  if (cache_dir.empty()) {
    std::cerr << "Failed to get code cache directory" << std::endl;
    return false;
  }

  // Create patches directory
  std::string patches_dir = cache_dir + "/quicui_patches";
  std::string cmd = "mkdir -p " + patches_dir;
  system(cmd.c_str());

  // Copy patch to code cache with architecture-specific name
  // Format: libapp_patched_<arch>.so
  std::string target_path = patches_dir + "/libapp_patched_" + 
                           architecture + ".so";

  // Use system copy for reliability
  cmd = "cp " + patch_path + " " + target_path;
  int result = system(cmd.c_str());

  if (result != 0) {
    std::cerr << "Failed to copy patch to: " << target_path << std::endl;
    return false;
  }

  // Set appropriate permissions (readable + executable)
  cmd = "chmod 755 " + target_path;
  system(cmd.c_str());

  std::cout << "AOT snapshot installed: " << target_path << std::endl;
  return true;
}
```

#### Key Method: `GetPatchedAOTPath()`

```cpp
std::string CodePushLoader::GetPatchedAOTPath(
    const std::string& architecture) {
  
  std::string cache_dir = GetCodeCacheDir();
  if (cache_dir.empty()) {
    return "";
  }

  std::string patch_path = cache_dir + "/quicui_patches/libapp_patched_" +
                          architecture + ".so";

  // Check if patch exists
  std::ifstream file(patch_path);
  if (!file.good()) {
    return "";  // No patch installed
  }
  file.close();

  // Load and validate metadata
  CodePushPatch patch_metadata;
  if (!LoadPatchMetadata(patch_metadata)) {
    std::cerr << "Failed to load patch metadata" << std::endl;
    return "";
  }

  // Validate patch integrity
  if (!ValidateAOTSnapshot(patch_path, patch_metadata.patch_hash)) {
    std::cerr << "Patch validation failed, removing corrupted patch" << std::endl;
    ClearInstalledPatch();
    return "";
  }

  std::cout << "Using patched AOT snapshot: " << patch_path << std::endl;
  return patch_path;
}
```

#### Key Method: `ValidateAOTSnapshot()`

```cpp
bool CodePushLoader::ValidateAOTSnapshot(const std::string& path,
                                        const std::string& expected_hash) {
  // Check file exists
  std::ifstream file(path);
  if (!file.good()) {
    return false;
  }
  file.close();

  // Calculate hash
  std::string calculated_hash = CalculatePatchHash(path);
  
  // Compare hashes
  if (calculated_hash != expected_hash) {
    std::cerr << "Hash mismatch - Expected: " << expected_hash 
              << ", Got: " << calculated_hash << std::endl;
    return false;
  }

  return true;
}
```

#### Helper Method: `GetCodeCacheDir()`

```cpp
std::string CodePushLoader::GetCodeCacheDir() {
  // Platform-specific code cache paths
  // This will be set by platform-specific code (Android/iOS)
  
  // For Android: /data/data/<package>/code_cache
  // For iOS: <App>/Library/Caches
  // For Linux: ~/.cache/<app>
  
  // This should be injected from platform layer
  return code_cache_dir_;
}
```

### Part 3: Create Android Platform Integration

#### NEW FILE: `QuicUICodePushLoader.java`

```java
package io.flutter.embedding.engine.loader;

import android.content.Context;
import android.util.Log;
import java.io.File;

/**
 * QuicUI Code Push integration for Android platform.
 * Checks for installed AOT patches and provides paths to FlutterLoader.
 */
public class QuicUICodePushLoader {
  private static final String TAG = "QuicUICodePush";
  private static final String PATCHES_DIR = "quicui_patches";
  
  private final Context context;
  
  public QuicUICodePushLoader(Context context) {
    this.context = context;
  }
  
  /**
   * Get path to patched libapp.so if available.
   * @param architecture CPU architecture (e.g., "arm64-v8a")
   * @return Path to patched library or null if not available
   */
  public String getPatchedAOTPath(String architecture) {
    File codeCacheDir = context.getCodeCacheDir();
    if (codeCacheDir == null) {
      Log.w(TAG, "Code cache directory not available");
      return null;
    }
    
    File patchesDir = new File(codeCacheDir, PATCHES_DIR);
    if (!patchesDir.exists()) {
      Log.d(TAG, "No patches directory found");
      return null;
    }
    
    File patchedLibapp = new File(patchesDir, 
                                  "libapp_patched_" + architecture + ".so");
    
    if (!patchedLibapp.exists()) {
      Log.d(TAG, "No patched libapp.so found for: " + architecture);
      return null;
    }
    
    // Validate patch metadata
    File metadataFile = new File(patchesDir, "patch_metadata.json");
    if (!metadataFile.exists()) {
      Log.w(TAG, "Patch metadata not found, ignoring patch");
      return null;
    }
    
    Log.i(TAG, "Using patched AOT library: " + patchedLibapp.getAbsolutePath());
    return patchedLibapp.getAbsolutePath();
  }
  
  /**
   * Check if a patch is installed.
   */
  public boolean hasPatch(String architecture) {
    return getPatchedAOTPath(architecture) != null;
  }
  
  /**
   * Clear installed patch (rollback).
   */
  public boolean clearPatch() {
    File codeCacheDir = context.getCodeCacheDir();
    if (codeCacheDir == null) {
      return false;
    }
    
    File patchesDir = new File(codeCacheDir, PATCHES_DIR);
    if (!patchesDir.exists()) {
      return true;  // Already cleared
    }
    
    // Delete all files in patches directory
    File[] files = patchesDir.listFiles();
    if (files != null) {
      for (File file : files) {
        file.delete();
      }
    }
    
    patchesDir.delete();
    Log.i(TAG, "Cleared installed patches");
    return true;
  }
}
```

### Part 4: Modify FlutterLoader.java

#### Add QuicUI Code Push Integration

**Location**: In `ensureInitializationCompleteAsync()` method, before setting up shell arguments.

```java
// Inside FlutterLoader.java

private void ensureInitializationCompleteAsync(...) {
  // ... existing code ...
  
  // QuicUI Code Push: Check for patched AOT library
  String patchedAotPath = checkForPatchedAOT(applicationContext);
  if (patchedAotPath != null) {
    // Use patched library instead of default
    flutterApplicationInfo.aotSharedLibraryName = patchedAotPath;
    Log.i(TAG, "Using QuicUI patched AOT: " + patchedAotPath);
  }
  
  // Continue with existing initialization...
  shellArgs.add(aotSharedLibraryNameFlag + flutterApplicationInfo.aotSharedLibraryName);
  
  // ... rest of existing code ...
}

/**
 * Check for QuicUI Code Push patched AOT library.
 * @return Path to patched libapp.so or null if not available
 */
private String checkForPatchedAOT(Context context) {
  try {
    // Detect device architecture
    String architecture = getDeviceArchitecture();
    
    // Check for patch
    QuicUICodePushLoader codePushLoader = new QuicUICodePushLoader(context);
    String patchedPath = codePushLoader.getPatchedAOTPath(architecture);
    
    return patchedPath;
  } catch (Exception e) {
    Log.e(TAG, "Error checking for QuicUI patch: " + e.getMessage());
    return null;
  }
}

/**
 * Get device CPU architecture.
 */
private String getDeviceArchitecture() {
  // Check supported ABIs (newer API)
  if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
    String[] abis = Build.SUPPORTED_ABIS;
    if (abis.length > 0) {
      return abis[0];  // Primary ABI
    }
  }
  
  // Fallback for older devices
  return Build.CPU_ABI;
}
```

---

## 🔐 Security Considerations

### 1. Signature Verification

```cpp
bool CodePushLoader::VerifyPatchSignature(const std::string& patch_data,
                                         const std::string& signature) {
  // TODO: Implement Ed25519 verification
  // Use libsodium or similar crypto library
  // 
  // Steps:
  // 1. Load public verification key from app config
  // 2. Decode base64 signature
  // 3. Verify signature against patch data
  // 4. Return true only if signature is valid
  
  if (signature.empty()) {
    std::cerr << "Empty signature provided" << std::endl;
    return false;
  }
  
  // CRITICAL: Replace with actual verification
  return true;  // Placeholder - DO NOT USE IN PRODUCTION
}
```

### 2. Hash Validation

```cpp
std::string CodePushLoader::CalculatePatchHash(const std::string& patch_path) {
  // Use SHA256 for integrity verification
  // 
  // Production options:
  // 1. Use OpenSSL: EVP_DigestInit_ex, EVP_DigestUpdate, EVP_DigestFinal_ex
  // 2. Use system command (less secure but works)
  
  std::string command = "shasum -a 256 " + patch_path + " | awk '{print $1}'";
  FILE* fp = popen(command.c_str(), "r");
  
  if (!fp) {
    std::cerr << "Failed to calculate hash" << std::endl;
    return "";
  }
  
  char hash[65] = {0};
  fgets(hash, sizeof(hash) - 1, fp);
  pclose(fp);
  
  std::string result(hash);
  if (!result.empty() && result.back() == '\n') {
    result.pop_back();
  }
  
  return result;
}
```

### 3. Metadata Storage

**Format**: JSON file stored alongside patch

```json
{
  "version": "1.0.1",
  "platform": "android",
  "architecture": "arm64-v8a",
  "patch_hash": "abc123...",
  "signature": "def456...",
  "install_date": "2025-11-01T10:30:00Z",
  "app_version": "1.0.0",
  "requires_restart": true
}
```

---

## 🧪 Testing Strategy

### Unit Tests (C++)

```cpp
// test_codepush_loader.cc

TEST(CodePushLoaderTest, InstallAOTSnapshot) {
  CodePushLoader loader;
  
  // Mock patch file
  std::string patch_path = "/tmp/test_patch.so";
  CreateMockPatch(patch_path);
  
  // Install
  bool success = loader.InstallAOTSnapshot(patch_path, "arm64-v8a");
  EXPECT_TRUE(success);
  
  // Verify installed
  std::string installed_path = loader.GetPatchedAOTPath("arm64-v8a");
  EXPECT_FALSE(installed_path.empty());
  
  // Validate
  EXPECT_TRUE(FileExists(installed_path));
}

TEST(CodePushLoaderTest, ValidateAOTSnapshot) {
  CodePushLoader loader;
  
  std::string test_file = "/tmp/test.so";
  CreateTestFile(test_file, "test content");
  
  std::string hash = loader.CalculatePatchHash(test_file);
  EXPECT_FALSE(hash.empty());
  
  EXPECT_TRUE(loader.ValidateAOTSnapshot(test_file, hash));
  EXPECT_FALSE(loader.ValidateAOTSnapshot(test_file, "wrong_hash"));
}
```

### Integration Tests (Android)

```java
// QuicUICodePushLoaderTest.java

@Test
public void testGetPatchedAOTPath() {
  Context context = InstrumentationRegistry.getTargetContext();
  QuicUICodePushLoader loader = new QuicUICodePushLoader(context);
  
  // Create mock patch
  File codeCacheDir = context.getCodeCacheDir();
  File patchesDir = new File(codeCacheDir, "quicui_patches");
  patchesDir.mkdirs();
  
  File patchFile = new File(patchesDir, "libapp_patched_arm64-v8a.so");
  createMockFile(patchFile);
  
  // Test
  String path = loader.getPatchedAOTPath("arm64-v8a");
  assertNotNull(path);
  assertTrue(new File(path).exists());
}

@Test
public void testClearPatch() {
  Context context = InstrumentationRegistry.getTargetContext();
  QuicUICodePushLoader loader = new QuicUICodePushLoader(context);
  
  // Create patch
  createMockPatch(context);
  assertTrue(loader.hasPatch("arm64-v8a"));
  
  // Clear
  assertTrue(loader.clearPatch());
  assertFalse(loader.hasPatch("arm64-v8a"));
}
```

### Device Tests

1. **Install baseline APK** (v1.0.0)
   ```bash
   flutter build apk --release
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

2. **Verify app runs** with original code

3. **Generate and upload patch** (v1.0.1)
   ```bash
   bash scripts/generate_aot_patch.sh
   curl -X POST http://localhost:8080/api/v1/patches/upload \
     -F "patch=@output/patches/v1.0.1/patch_arm64-v8a.so"
   ```

4. **Trigger patch download** in app
   - App should download patch to code cache
   - App should show "Restart to apply patch"

5. **Restart app**
   - FlutterLoader should detect patch
   - App should load patched libapp.so
   - Verify new code is running (e.g., text shows "v1.0.1 - LIVE ✨")

6. **Test rollback**
   - Clear patch from code cache
   - Restart app
   - Verify fallback to original APK code

---

## 📊 Performance Impact

### Storage

| Item | Size | Location |
|------|------|----------|
| Original APK | ~30MB | `/data/app/...` |
| libapp.so (baseline) | ~3.1MB | Inside APK |
| libapp_patched.so | ~3.1MB | Code cache |
| Metadata | ~1KB | Code cache |
| **Total Added** | **~3.1MB** | Per patch |

### Memory

- **No runtime overhead** - patch is just a different library file
- **Same as baseline** - AOT compiled code has identical structure
- **No hot reload** - restart required, so no extra memory for patch system

### Startup Time

| Scenario | Time |
|----------|------|
| No patch installed | Baseline (unchanged) |
| Patch installed | +5-10ms (file existence check) |
| First launch after patch | +50-100ms (hash validation) |

---

## 🚀 Deployment Workflow

### Developer Side

1. **Make code changes**
   ```dart
   // In test_apps/quicui_test_app_v1/lib/main.dart
   Text('Version: 1.0.2 - NEW FEATURE 🎉')
   ```

2. **Generate patch**
   ```bash
   bash scripts/generate_aot_patch.sh
   ```

3. **Upload patch**
   ```bash
   curl -X POST http://localhost:8080/api/v1/patches/upload \
     -F "patch=@output/patches/v1.0.2/patch_arm64-v8a.so" \
     -F "metadata=@output/patches/v1.0.2/metadata.json"
   ```

### Client Side

1. **App checks for patches** (on startup or manually)
   ```dart
   final hasUpdate = await QuicUICodePush.checkForUpdate();
   ```

2. **Download and install**
   ```dart
   if (hasUpdate) {
     await QuicUICodePush.downloadAndInstall();
   }
   ```

3. **Prompt user to restart**
   ```dart
   showDialog(
     context: context,
     builder: (context) => AlertDialog(
       title: Text('Update Ready'),
       content: Text('Restart to apply new version'),
       actions: [
         TextButton(
           onPressed: () => QuicUICodePush.restart(),
           child: Text('Restart Now'),
         ),
       ],
     ),
   );
   ```

4. **On restart** - FlutterLoader automatically loads patched library

---

## ⚠️ Risks & Mitigations

### Risk 1: Corrupted Patch

**Problem**: Downloaded patch is corrupted or incomplete

**Mitigation**:
- Hash verification before installation
- Fallback to original if validation fails
- Automatic patch deletion on failure

### Risk 2: Incompatible Patch

**Problem**: Patch for wrong app version or architecture

**Mitigation**:
- Check app version in metadata
- Validate architecture match
- Server-side compatibility checking

### Risk 3: Security Breach

**Problem**: Malicious patch injected

**Mitigation**:
- Ed25519 signature verification (mandatory)
- HTTPS for downloads
- Public key embedded in app at build time

### Risk 4: Storage Cleared

**Problem**: Android clears code cache

**Mitigation**:
- Patch system is stateless
- Next startup re-downloads if needed
- Original APK always works

### Risk 5: App Crash After Patch

**Problem**: Patched code causes crash

**Mitigation**:
- Rollback on repeated crashes
- Error reporting to server
- Automatic patch deletion after 3 crashes

---

## 📈 Success Criteria

- ✅ Kernel patching code completely removed
- ✅ AOT installation methods implemented
- ✅ FlutterLoader integration working
- ✅ Patches validated before loading
- ✅ App restarts correctly with patch
- ✅ Rollback mechanism functional
- ✅ Security checks in place
- ✅ Device testing successful

---

## 🎯 Next Steps

1. **Implement engine modifications** (this document)
2. **Build modified engine** 
   ```bash
   cd forks/flutter-official/engine
   ./flutter/tools/gn --android --android-cpu arm64
   ninja -C out/android_release_arm64
   ```
3. **Test with QuicUI fork**
   ```bash
   bash scripts/build_with_quicui_fork.sh
   ```
4. **Device testing**
5. **Production hardening** (crypto, error handling)

---

## 📚 References

- [Shorebird Source Code](https://github.com/shorebirdtech/shorebird)
- [Flutter Engine Architecture](https://github.com/flutter/flutter/wiki/The-Engine-architecture)
- [AOT Compilation in Flutter](https://flutter.dev/docs/resources/architectural-overview#compilation)
- [Previous Analysis](.azure/FORK_CAPABILITY_ANALYSIS.md)
- [Phase 1 Complete](.azure/PHASE_1_COMPLETE.md)

---

**Status**: 📝 Documentation Complete - Ready for Implementation  
**Estimated Time**: 4-6 hours for full implementation  
**Risk Level**: Medium (engine modifications required)

