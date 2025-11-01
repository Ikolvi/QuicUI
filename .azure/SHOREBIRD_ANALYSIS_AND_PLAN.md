# Shorebird Analysis & QuicUI Implementation Plan

## Executive Summary

After analyzing Shorebird's architecture, I've discovered they **DO use release mode APKs** for code push! This is a critical finding that changes our approach.

## Key Findings from Shorebird

### 1. **Release Mode + AOT Compilation**

Shorebird uses **AOT-compiled release mode** builds and patches them using a **linker-based approach**:

```dart
// From shorebirdtech/flutter - build_info.dart
BuildMode.release => <String>[
  '-Ddart.vm.product=true',
  '--delete-tostring-package-uri=dart:ui',
  ...
],
```

### 2. **Engine Architecture**

```cpp
// From shorebirdtech/flutter - fl_engine.cc
if (setup_shorebird_result) {
  // If we have a patch installed, we replace the default AOT library path
  // with the patch path here.
  source.elf_path = patch_path.c_str();  // Replaces libapp.so!
} else {
  source.elf_path = fl_dart_project_get_aot_library_path(self->project);
}
```

**Key insight**: They replace the **entire `libapp.so`** (the AOT snapshot) with a patched version!

### 3. **Patch Process**

From their CLI code:
1. **Build release APK** with AOT snapshots (libapp.so)
2. **Extract libapp.so** from APK
3. Use **custom linker** to create minimal diff
4. Upload **patch artifact** (not full snapshot)
5. At runtime, **download patch** and **reconstruct new libapp.so**

### 4. **The "Linker" - The Secret Sauce**

```dart
// From apple.dart - Shorebird's linker
Future<LinkResult> runLinker({
  required File kernelFile,
  required File releaseArtifact,  // Original libapp.so
  required File aotOutputFile,     // New libapp.so
  required File vmCodeFile,        // Patch output
}) async {
  // Uses analyze_snapshot and gen_snapshot
  // Creates a "linked" patch that shares code with original
  // Result: vmCodeFile contains only the DIFF!
}
```

The linker:
- Analyzes the **original AOT snapshot**
- Compares with **new AOT snapshot**
- Generates a **differential patch**
- Produces a "vmcode" file that can be applied to original

### 5. **Native Library Replacement**

```cpp
// shorebird.cc - Patch application
bool ConfigureShorebird(...) {
  // Check for patch in code_cache_path
  auto code_cache_dir = fml::paths::JoinPaths({
    code_cache_path, 
    "shorebird_updater", 
    app_id
  });
  
  if (patch_exists) {
    patch_path = code_cache_dir + "/libapp.so";  // Patched version
  }
  return true;
}
```

## Critical Differences from Our Approach

| Aspect | Our Current Approach | Shorebird's Approach |
|--------|---------------------|----------------------|
| **Build Mode** | Profile (JIT kernel) | **Release (AOT)** |
| **Patch Target** | kernel_blob.bin | **libapp.so** |
| **Patch Type** | Kernel diff | **AOT snapshot diff** |
| **Patch Size** | Full kernel (~MBs) | Linked diff (~KBs) |
| **Runtime** | Dart VM interprets | **Native ARM code** |
| **Performance** | Slower (JIT) | **Fast (AOT)** |

## Why Their Approach is Better

### 1. **Performance**
- AOT-compiled code runs at **native speed**
- No JIT warm-up time
- True production performance

### 2. **Patch Size**
- Linker produces **minimal diffs** (10-50KB typical)
- Only changed functions included
- Shared code references original snapshot

### 3. **Compatibility**
- Works with **release builds** on app stores
- No special build mode needed
- Standard Flutter workflow

### 4. **Security**
- Release mode has all optimizations
- No debug symbols
- Production-ready binaries

## QuicUI Implementation Plan

### Phase 1: Understand AOT Snapshot Format ✅ (Research)

**Goal**: Understand how Flutter generates AOT snapshots

**Tasks**:
1. Study Flutter's `gen_snapshot` tool
2. Analyze `libapp.so` structure (ELF format)
3. Understand snapshot sections:
   - VM instructions
   - Isolate data
   - VM data
   - Isolate instructions

**Tools**:
- `gen_snapshot` (in Flutter SDK)
- `analyze_snapshot` (engine artifact)
- ELF analysis tools

### Phase 2: Build AOT Snapshot Differ

**Goal**: Create tool to diff two AOT snapshots

**Tasks**:
1. Extract symbol table from `libapp.so`
2. Identify changed functions between versions
3. Create binary diff format
4. Implement patch application logic

**Output**: `quicui_aot_differ` tool

**Pseudocode**:
```dart
class AOTDiffer {
  PatchData generatePatch({
    required File baseSnapshot,  // v1.0.0 libapp.so
    required File newSnapshot,   // v1.0.1 libapp.so
  }) {
    // 1. Parse ELF headers
    final baseElf = ElfFile.parse(baseSnapshot);
    final newElf = ElfFile.parse(newSnapshot);
    
    // 2. Extract code sections
    final baseCode = baseElf.getSection('.text');
    final newCode = newElf.getSection('.text');
    
    // 3. Identify changed functions
    final changedFunctions = diffFunctions(baseCode, newCode);
    
    // 4. Generate patch
    return PatchData(
      functions: changedFunctions,
      metadata: {
        'base_hash': baseElf.hash,
        'patch_version': '1.0.1',
      },
    );
  }
}
```

### Phase 3: Implement Linker (Advanced)

**Goal**: Create a "linker" like Shorebird's to minimize patch size

**Tasks**:
1. Use `analyze_snapshot` to understand code layout
2. Identify shared code between versions
3. Generate "vmcode" format with references
4. Implement linking at runtime

**This is complex!** May need to study:
- Shorebird's engine modifications
- Flutter's snapshot format internals
- ARM instruction patching

**Alternative**: Start with **full snapshot replacement** (simpler)

### Phase 4: Modify QuicUI Engine

**Goal**: Make engine load patched AOT snapshots

**Files to modify**:
```cpp
// In QuicUI fork
engine/src/flutter/shell/platform/android/flutter_main.cc

// Add patch loading logic
bool LoadPatchedSnapshot(const std::string& patch_path) {
  // 1. Check for patch in app's code cache
  // 2. Validate patch checksum
  // 3. Apply patch to create new libapp.so
  // 4. Load patched snapshot instead of original
}
```

**Integration point**:
```cpp
// In RunEngine() or similar
if (ShouldUsePatch()) {
  aot_data_path = GetPatchedSnapshotPath();
} else {
  aot_data_path = GetOriginalSnapshotPath();
}
```

### Phase 5: Update Build System

**Goal**: Build release APKs and generate patches

**Script**: `build_release_and_patch.sh`
```bash
#!/bin/bash

# 1. Build v1.0.0 release APK
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk baseline.apk

# 2. Extract baseline libapp.so
unzip baseline.apk "lib/arm64-v8a/libapp.so" -d baseline/
BASELINE_SNAPSHOT="baseline/lib/arm64-v8a/libapp.so"

# 3. Make code changes for v1.0.1
sed -i '' 's/v1.0.0/v1.0.1/g' lib/main.dart

# 4. Build v1.0.1 release APK
flutter build apk --release
unzip build/app/outputs/flutter-apk/app-release.apk "lib/arm64-v8a/libapp.so" -d patched/
PATCHED_SNAPSHOT="patched/lib/arm64-v8a/libapp.so"

# 5. Generate patch
dart run quicui_aot_differ \
  --base "$BASELINE_SNAPSHOT" \
  --new "$PATCHED_SNAPSHOT" \
  --output patch_1.0.1.bin

# 6. Upload patch to server
curl -X POST -F "patch=@patch_1.0.1.bin" \
  http://localhost:8080/api/v1/patches/upload
```

### Phase 6: Runtime Patch Application

**Goal**: Download and apply patches at runtime

**Client code**:
```dart
class AOTPatchManager {
  Future<void> checkAndApplyPatch() async {
    // 1. Check for available patch
    final patchInfo = await _backend.checkForPatch(
      appId: 'com.quicui.testapp',
      version: '1.0.0',
    );
    
    if (patchInfo == null) return;
    
    // 2. Download patch
    final patchFile = await _backend.downloadPatch(patchInfo.url);
    
    // 3. Validate checksum
    if (!_validateChecksum(patchFile, patchInfo.checksum)) {
      throw Exception('Patch checksum mismatch');
    }
    
    // 4. Save patch to code cache
    final codeCacheDir = await getCodeCacheDir();
    await patchFile.copy('$codeCacheDir/libapp.so');
    
    // 5. Restart app to apply patch
    // (Engine will detect and use patched libapp.so)
    await _restartApp();
  }
}
```

## Implementation Roadmap

### **Simplified Phase 1** (Immediate - No Linker)

**Goal**: Get release mode patching working with **full snapshot replacement**

**Steps**:
1. ✅ Update build scripts to use `--release` mode
2. ✅ Modify patch generation to extract `libapp.so`
3. ⏳ Create simple "full snapshot replacement" differ
4. ⏳ Modify QuicUI engine to check for patched snapshot
5. ⏳ Test with release APK on device

**Estimated time**: 2-3 days

**Pros**: 
- Simple to implement
- Proves the concept works
- Production-ready builds

**Cons**:
- Larger patch sizes (full libapp.so ~3-10MB)
- No linker optimization yet

### **Advanced Phase 2** (Future - With Linker)

**Goal**: Implement Shorebird-style linker for minimal patches

**Steps**:
1. Study `analyze_snapshot` output format
2. Implement function-level diffing
3. Create linked patch format
4. Add runtime linking logic
5. Optimize patch size

**Estimated time**: 2-3 weeks

**Pros**:
- Tiny patch sizes (10-50KB)
- Optimal bandwidth usage
- Shorebird parity

**Cons**:
- Complex implementation
- Requires deep snapshot format knowledge
- More testing needed

## Immediate Next Steps

1. **Update current build scripts** ✅
   - Change from `--profile` to `--release`
   - Update patch generation script

2. **Create simple AOT differ**
   ```bash
   # Full snapshot replacement (simple)
   cp new_libapp.so patch_libapp.so
   ```

3. **Test extraction from release APK**
   ```bash
   unzip app-release.apk "lib/arm64-v8a/libapp.so"
   ```

4. **Modify engine to check for patch**
   ```cpp
   // In QuicUI fork
   std::string patch_path = GetCodeCachePath() + "/libapp.so";
   if (FileExists(patch_path)) {
     aot_data_path = patch_path;  // Use patched version
   }
   ```

## Questions to Research

1. **How does Shorebird's linker work exactly?**
   - Need to study their `aot_tools` package
   - Understand `analyze_snapshot` output
   - Learn ARM instruction layout in snapshots

2. **Can we use their tools directly?**
   - License check (they're open source)
   - Integration complexity
   - Customization needs for QuicUI

3. **What about multi-arch support?**
   - Need patches for: arm64-v8a, armeabi-v7a, x86_64
   - How to handle architecture detection
   - Patch size multiplication

## Conclusion

**Shorebird's approach is the right way** - they patch **release mode AOT snapshots**, not JIT kernels. This gives:
- ✅ Production performance
- ✅ Small patch sizes (with linker)
- ✅ App store compatibility
- ✅ Security and optimization

**Our path forward**:
1. **Short term**: Full snapshot replacement (simple, works)
2. **Long term**: Implement linker (optimal, complex)

The current kernel-patching approach won't work for production. We need to pivot to AOT snapshot patching like Shorebird.

---

**Status**: Ready to implement Phase 1 (Full Snapshot Replacement)
**Blocker**: None - can start immediately
**Risk**: Medium - need to learn AOT snapshot format, but simplified approach is achievable
