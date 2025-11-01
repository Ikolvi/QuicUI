# QuicUI Fork Analysis: AOT Patching Capability

## Executive Summary

**STATUS: ❌ NOT READY FOR AOT PATCHING**

The QuicUI Flutter fork currently only supports **kernel patching** (JIT/Profile mode), not **AOT snapshot patching** (Release mode).

## Current Implementation

### What Exists ✅

The fork has a `CodePushLoader` class at:
```
forks/flutter-official/engine/src/flutter/shell/common/codepush_loader.cc
```

**What it does:**
- Checks for patches from a remote server
- Downloads patch files
- Verifies signatures and checksums
- Loads patches using `DartPatchLoader::LoadKernelPatch()`

**Key limitation:**
```cpp
flutter::DartPatchLoadResult result = 
    flutter::DartPatchLoader::LoadKernelPatch(kernel_data);
```
↑ This loads **KERNEL** patches, not **AOT snapshots**!

### What's Missing ❌

#### 1. **AOT Snapshot Loading Logic**

Standard Flutter loads `libapp.so` during engine initialization:

**Android:**
```java
// FlutterLoader.java
shellArgs.add("--aot-shared-library-name=" + flutterApplicationInfo.aotSharedLibraryName);
// Default: "libapp.so"
```

**What we need:**
```cpp
// Check for patched AOT snapshot
std::string patch_path = GetCodeCachePath() + "/libapp_patched.so";
if (FileExists(patch_path) && ValidateChecksum(patch_path)) {
  // Load patched snapshot instead of original
  return patch_path;
}
return originalLibappPath; // Fallback to original
```

#### 2. **Platform-Specific Integration**

**Android needs:**
```java
// In FlutterLoader.java or FlutterJNI.java
private String getAOTLibraryPath() {
  // Check for patched libapp.so in code cache
  File patchedLibapp = new File(codeCacheDir, "libapp_patched.so");
  if (patchedLibapp.exists() && validateChecksum(patchedLibapp)) {
    return patchedLibapp.getAbsolutePath();
  }
  return getDefaultLibappPath(); // From APK
}
```

**Linux needs:**
```cpp
// fl_engine.cc already has:
fl_dart_project_set_aot_library_path(project, path);

// We need to call this with patched path:
std::string patched_path = GetPatchedAOTPath();
if (!patched_path.empty()) {
  fl_dart_project_set_aot_library_path(project, patched_path.c_str());
}
```

#### 3. **Patch Application Logic**

Current `LoadPatch()` function does:
```cpp
bool CodePushLoader::LoadPatchKernel(const std::string& patch_path) {
  // Reads patch file
  // Calls DartPatchLoader::LoadKernelPatch()
  // ❌ Only works for KERNEL files, not AOT snapshots
}
```

What we need:
```cpp
bool CodePushLoader::InstallAOTSnapshot(const std::string& patch_path) {
  // 1. Validate patch file (checksum, signature)
  // 2. Copy to code cache as "libapp_patched.so"
  // 3. Set flag for next app start
  // 4. Return success
  // 
  // Note: AOT patches require app restart
  // Cannot hot-reload AOT snapshots like kernels
}
```

## Comparison: Current vs Needed

| Feature | Current Implementation | Needed for AOT |
|---------|----------------------|----------------|
| **Build Mode** | Profile (JIT kernel) | Release (AOT) |
| **Patch Target** | `kernel_blob.bin` | `libapp.so` |
| **Loading Method** | `DartPatchLoader::LoadKernelPatch()` | System library loader |
| **Hot Reload** | ✅ Yes (kernel reload) | ❌ No (requires restart) |
| **App Restart** | Not needed | **Required** |
| **Platform Code** | Generic C++ | Android/iOS specific |

## How Shorebird Does It

### Shorebird's Engine Modifications

From their open-source code:

**1. Check for patch on startup:**
```cpp
// In engine initialization
std::string patch_path;
if (ConfigureShorebird(args, patch_path)) {
  // Use patch_path instead of original
  source.elf_path = patch_path.c_str();
} else {
  // Use original from APK
  source.elf_path = fl_dart_project_get_aot_library_path(project);
}
```

**2. Patch management:**
```cpp
bool ConfigureShorebird(const ShorebirdConfigArgs& args,
                        std::string& patch_path) {
  // 1. Check code cache for patches
  auto code_cache_dir = fml::paths::JoinPaths({
    code_cache_path, "shorebird_updater", app_id
  });
  
  // 2. Find latest valid patch
  std::string latest_patch = FindLatestPatch(code_cache_dir);
  
  // 3. Validate patch
  if (ValidatePatch(latest_patch)) {
    patch_path = latest_patch;
    return true;
  }
  
  return false; // Use original
}
```

**3. Native library path override:**
- On Android: Override `aot-shared-library-name` argument
- On iOS: Change ELF path before creating AOTData
- On Linux: Call `fl_dart_project_set_aot_library_path()`

## Required Modifications

### Phase A: Core Engine Changes

#### 1. Add AOT Patch Installer (codepush_loader.cc)

```cpp
class CodePushLoader {
public:
  // New method for AOT patches
  bool InstallAOTSnapshot(
    const std::string& patch_path,
    const std::string& patch_version
  );
  
  // Check for installed AOT patch
  std::string GetInstalledAOTPatch();
  
  // Validate AOT snapshot
  bool ValidateAOTSnapshot(const std::string& path);
};
```

#### 2. Add Platform-Specific Loaders

**Android (FlutterLoader.java):**
```java
public class FlutterLoader {
  private String getAOTSnapshotPath(Context context) {
    // Check for patched snapshot
    File codeCacheDir = context.getCodeCacheDir();
    File patchedSnapshot = new File(codeCacheDir, 
                                    "quicui_patches/libapp_patched.so");
    
    if (patchedSnapshot.exists()) {
      // Validate checksum
      if (validateSnapshot(patchedSnapshot)) {
        return patchedSnapshot.getAbsolutePath();
      }
    }
    
    // Return original from APK
    return flutterApplicationInfo.aotSharedLibraryName;
  }
}
```

**iOS (FlutterEngine.mm):**
```objc
- (NSString*)getAOTSnapshotPath {
  // Check for patched App.framework
  NSString* cacheDir = [NSSearchPathForDirectoriesInDomains(
    NSCachesDirectory, NSUserDomainMask, YES) firstObject];
  NSString* patchedPath = [cacheDir 
    stringByAppendingPathComponent:@"quicui_patches/App.framework"];
  
  if ([[NSFileManager defaultManager] fileExistsAtPath:patchedPath]) {
    if ([self validateSnapshot:patchedPath]) {
      return patchedPath;
    }
  }
  
  // Return original from bundle
  return [[NSBundle mainBundle] pathForResource:@"App" 
                                         ofType:@"framework"];
}
```

### Phase B: Client Integration

#### 1. Download and Install

```dart
// In quicui_code_push_client
class AOTPatchManager {
  Future<bool> downloadAndInstallPatch(PatchInfo patch) async {
    // 1. Download patch file
    final patchFile = await _downloadPatch(patch.url);
    
    // 2. Validate checksum
    if (!_validateChecksum(patchFile, patch.checksum)) {
      throw Exception('Patch checksum mismatch');
    }
    
    // 3. Call native method to install
    final installed = await _nativeInstall(patchFile);
    
    if (installed) {
      // 4. Schedule app restart
      await _scheduleRestart();
      return true;
    }
    
    return false;
  }
  
  // Platform channel to native code
  Future<bool> _nativeInstall(File patchFile) async {
    return await _channel.invokeMethod('installAOTPatch', {
      'patchPath': patchFile.path,
      'version': currentVersion,
    });
  }
}
```

#### 2. Native Method Implementation

**Android (Kotlin/Java):**
```kotlin
class CodePushPlugin : MethodCallHandler {
  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "installAOTPatch" -> {
        val patchPath = call.argument<String>("patchPath")
        val version = call.argument<String>("version")
        
        // Copy to code cache
        val codeCacheDir = context.codeCacheDir
        val targetDir = File(codeCacheDir, "quicui_patches")
        targetDir.mkdirs()
        
        val targetFile = File(targetDir, "libapp_patched.so")
        File(patchPath).copyTo(targetFile, overwrite = true)
        
        // Save metadata
        saveMetadata(version, targetFile)
        
        result.success(true)
      }
    }
  }
}
```

## Implementation Plan

### Immediate (Get It Working)

1. **Modify `CodePushLoader`** (2-3 hours)
   - Add `InstallAOTSnapshot()` method
   - Add `GetInstalledAOTPatch()` method
   - Copy patch to code cache directory

2. **Add Android integration** (3-4 hours)
   - Modify `FlutterLoader.java`
   - Override AOT library path
   - Add native method handler

3. **Add client-side installer** (2 hours)
   - Platform channel setup
   - Download and install logic
   - Restart handling

4. **Test on device** (2-3 hours)
   - Install baseline APK
   - Download patch
   - Restart app
   - Verify patch applied

**Total: ~1 day of focused work**

### Future Optimizations

5. **Add iOS support** (4-6 hours)
6. **Add automatic restart logic** (2 hours)
7. **Add rollback on failure** (3 hours)
8. **Optimize patch size (Phase 2)** (1-2 weeks)
9. **Add linker (Phase 3)** (2-3 weeks)

## Key Differences from Kernel Patching

| Aspect | Kernel Patching (Current) | AOT Patching (Needed) |
|--------|--------------------------|----------------------|
| **When Applied** | Runtime (hot reload) | App restart |
| **File Location** | Temp directory | Code cache |
| **File Name** | `*.patch` | `libapp_patched.so` |
| **Loading** | `DartPatchLoader` | System lib loader |
| **Validation** | Checksum only | Checksum + platform check |
| **Platform Code** | Generic | Android/iOS specific |
| **App Restart** | Not needed | **Required** |

## Risks & Considerations

### 1. **App Restart Required**
- AOT patches cannot be hot-reloaded
- User must restart app or app must auto-restart
- Could interrupt user workflow

### 2. **Storage Location**
- Code cache can be cleared by system
- Need fallback to original if patch deleted
- Must handle partial downloads

### 3. **Security**
- AOT snapshots are executable code
- Signature validation is **critical**
- Must prevent injection attacks

### 4. **Platform Differences**
- Android: `.so` files
- iOS: `.framework` bundles
- Different loading mechanisms

### 5. **Testing Complexity**
- Need to test: install → restart → verify
- Cannot unit test easily (native code)
- Requires device testing

## Conclusion

**Current Status**: ❌ QuicUI fork is NOT ready for AOT patching

**What exists**: Kernel patching infrastructure (profile mode)

**What's needed**: 
1. AOT snapshot installer logic
2. Platform-specific library path override
3. Client-side download and install
4. App restart handling

**Estimated effort**: ~1 day for basic working implementation

**Next step**: Decide whether to:
- **Option A**: Continue with kernel patching (profile mode)
  - Pros: Already works, no engine changes needed
  - Cons: Not production-ready, larger patches, slower performance
  
- **Option B**: Implement AOT patching (release mode)
  - Pros: Production-ready, Shorebird-equivalent, better performance
  - Cons: Requires engine modifications, app restart needed, 1 day work

**Recommendation**: **Option B** - Implement AOT patching

Reasons:
1. It's the industry standard (Shorebird proves it works)
2. Only 1 day of work for basic implementation
3. We already have the patch generation working
4. Enables true production deployments
5. Better performance and smaller eventual patch sizes

---

Generated: 2025-11-01
Status: Analysis Complete
Decision Needed: Proceed with engine modifications?
