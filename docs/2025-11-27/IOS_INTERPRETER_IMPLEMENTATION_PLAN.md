# iOS Code Push Implementation Plan - Interpreter Approach

**Date**: November 27, 2025  
**Status**: Planning Phase  
**Based on**: Shorebird's proven iOS code push implementation

## Executive Summary

After extensive investigation, we've discovered that iOS **does not allow loading dynamically downloaded native binaries** (`.so` files) from cache due to Apple Mobile File Integrity (amfid) restrictions. Even with valid code signatures, iOS blocks `dlopen()` on files outside the app bundle.

**Solution**: Implement Shorebird's interpreter-based approach using `.vmcode` files (Dart VM snapshots) instead of AOT-compiled binaries.

## Why Current Approach Fails

### Problem: amfid Rejection
```
amfid: libapp_patched_arm64.so not valid: 
  Error Domain=AppleMobileFileIntegrityError Code=-400
```

**Root Cause**:
- iOS security policy blocks loading executable native code from `Library/Caches`
- Code signatures are valid, but **location matters**
- Even Apple-signed binaries cannot be loaded dynamically outside app bundle
- This is a fundamental iOS restriction, not a signature issue

### What We Tried
1. ✅ Removed ad-hoc signing (corrupted patches)
2. ✅ Uploaded full binaries instead of bsdiff patches
3. ✅ Preserved Flutter's original code signatures
4. ❌ **Still rejected by amfid** - location-based restriction

## Shorebird's Solution

### Key Insight: Use Interpreter, Not AOT on iOS

**App Store Guidelines 3.3.1(b):**
> "interpreted code may be downloaded to an Application but only so long as such code: (a) does not change the primary purpose of the Application..."

**Shorebird's Implementation**:
- Android: AOT-compiled `.so` files (works fine)
- iOS: Dart VM interpreter with `.vmcode` snapshot files
- `.vmcode` files are **data**, not executable code in Apple's definition
- Loaded via Dart VM's ELF loader, not `dlopen()`

### How It Works

**On iOS:**
```
┌─────────────────────────────────────────────────┐
│  App Bundle (App Store Approved)                │
│  ├── Runner.app                                 │
│  │   └── App (Flutter AOT - base snapshot)      │
│  │       ├── VM Snapshot (isolate_snapshot)     │
│  │       └── Isolate Snapshot (data+instrs)     │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Download Patch (from Supabase)                 │
│  └── patch_12345.vmcode (compressed with XZ)    │
│      ├── Isolate Data (Dart bytecode)           │
│      └── Isolate Instructions (interpreted)     │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Library/Caches/shorebird/patch_12345.vmcode    │
│  ↓                                               │
│  Dart VM ELF Loader                             │
│  ├── Loads .vmcode as ELF data                  │
│  ├── Extracts isolate_data and isolate_instrs   │
│  └── Runs in INTERPRETER MODE                   │
└─────────────────────────────────────────────────┘
```

**Key Differences from Android:**
| Aspect | Android | iOS |
|--------|---------|-----|
| Format | `.so` (native) | `.vmcode` (ELF data) |
| Execution | AOT (direct) | Interpreted (Dart VM) |
| Loading | `dlopen()` | `Dart_LoadedElf` |
| Performance | Fast | Slower (acceptable) |
| App Store | Allowed | Compliant |

## Implementation Plan

### Phase 1: Engine Modifications ⏳

**Location**: `/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter`

#### 1.1 Add Shorebird Code to Engine

**Create**: `shell/common/quicui/`

**Files to add:**
```
shell/common/quicui/
├── BUILD.gn
├── quicui.h
├── quicui.cc
└── snapshots_data_handle.h
└── snapshots_data_handle.cc
```

**Based on**:
- `/Volumes/DoWonder2/quicui_engine_build/shorebird_engine_quicui/src/flutter/shell/common/shorebird/`

**Key Changes**:
- Replace "shorebird" with "quicui" throughout
- Update API names: `quicui_init`, `quicui_next_boot_patch_path`, etc.
- Keep same interpreter logic

#### 1.2 Modify `runtime/dart_snapshot.cc`

**Add** (around line 50):
```cpp
#if QUICUI_USE_INTERPRETER
  // Detect when we're trying to load a QuicUI patch
  auto patch_path = native_library_path.front();
  bool is_patch = patch_path.find(".vmcode") != std::string::npos;
  
  if (is_patch) {
    // Load the .vmcode ELF file and extract symbols
    static Dart_LoadedElf* leaked_elf = nullptr;
    static const uint8_t* isolate_data = nullptr;
    static const uint8_t* isolate_instrs = nullptr;
    
    if (leaked_elf == nullptr) {
      const char* error = nullptr;
      leaked_elf = Dart_LoadELF(
          patch_path.c_str(), 0, &error,
          &ignored_vm_data, &ignored_vm_instrs,
          &isolate_data, &isolate_instrs
      );
      
      if (leaked_elf == nullptr || error != nullptr) {
        FML_LOG(ERROR) << "Failed to load QuicUI patch: " << error;
        return nullptr;
      }
    }
    
    // Return mapping for the patch isolate snapshot
    return std::make_unique<const fml::NonOwnedMapping>(
        isolate_instrs, 0 /* size unknown */
    );
  }
#endif  // QUICUI_USE_INTERPRETER
```

#### 1.3 Add Build Configuration

**Modify**: `shell/platform/darwin/ios/BUILD.gn`

**Add**:
```gn
if (quicui_enabled) {
  defines += [ "QUICUI_USE_INTERPRETER=1" ]
  deps += [ "//flutter/shell/common/quicui" ]
}
```

**Create**: `flutter/build/quicui.gni`
```gn
# QuicUI code push configuration
declare_args() {
  quicui_enabled = true
}
```

#### 1.4 Integrate Updater Library

**Location**: `third_party/updater/`

**Options**:
1. **Fork Shorebird updater** (recommended)
   - Clone: https://github.com/shorebirdtech/updater
   - Rename to `quicui_updater`
   - Update API calls
   
2. **Build from scratch** (more work)
   - Implement patch download
   - Implement patch verification
   - Implement rollback logic

**We'll use Option 1** - fork and customize Shorebird's updater.

### Phase 2: Build System Setup ⏳

#### 2.1 Update Engine Build Script

**File**: `scripts/build_with_quicui.sh`

```bash
#!/bin/bash
set -e

ENGINE_PATH="/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1"
cd "$ENGINE_PATH/engine/src"

# Build iOS engine with QuicUI interpreter
./flutter/tools/gn \
  --runtime-mode=release \
  --ios \
  --ios-cpu=arm64 \
  --quicui-enabled

ninja -C out/ios_release_arm64
```

#### 2.2 Generate `.vmcode` Patches

**Modify CLI**: `packages/quicui_compiler/lib/src/services/compiler_service.dart`

**Add method**:
```dart
static Future<PatchResult> generateVMCodePatch({
  required String dartExecutable,
  required String genSnapshotPath,
  required String appDillPath,
  required String outputPath,
}) async {
  // Use gen_snapshot to create .vmcode file
  final result = await Process.run(
    genSnapshotPath,
    [
      '--snapshot_kind=app-aot-assembly',
      '--strip',
      '--output=$outputPath',
      appDillPath,
    ],
  );
  
  if (result.exitCode != 0) {
    throw Exception('gen_snapshot failed: ${result.stderr}');
  }
  
  // Compress with XZ
  return await compressPatch(outputPath, 'xz');
}
```

### Phase 3: CLI Modifications ⏳

#### 3.1 Update `generate-patch` Command

**File**: `packages/quicui_cli/lib/src/commands/generate_patch_command.dart`

**Modify iOS handling** (lines 107-130):
```dart
if (platform == 'ios') {
  print('🍎 iOS Platform Detected - Using Interpreter Approach');
  
  // For iOS, we need to generate .vmcode file, not upload binary
  final vmcodePath = await CompilerService.generateVMCodePatch(
    dartExecutable: dartPath,
    genSnapshotPath: genSnapshotPath,
    appDillPath: newBinaryPath,  // Actually points to app.dill
    outputPath: '$outputDir/${toMetadata['version']}.vmcode',
  );
  
  print('   ✅ Generated .vmcode patch');
  print('   📝 This will be interpreted by Dart VM on device');
  
  finalPatchPath = vmcodePath;
  // ... set other metadata
}
```

#### 3.2 Update Client Library

**File**: `packages/quicui_client/lib/src/quicui_client.dart`

**Modify download** (for iOS):
```dart
Future<void> _downloadAndInstallPatch(Patch patch) async {
  if (patch.platform == 'ios') {
    // Download .vmcode file
    final vmcodePath = await _downloadPatch(patch);
    
    // Decompress XZ
    final decompressed = await _decompressXZ(vmcodePath);
    
    // Save to cache as .vmcode (NOT .so)
    final targetPath = path.join(
      _cacheDir,
      'quicui_patches',
      'patch_${patch.version}.vmcode',  // .vmcode extension
    );
    
    await File(decompressed).copy(targetPath);
    
    print('[QuicUI] ✅ Installed .vmcode patch: ${patch.version}');
  }
}
```

### Phase 4: iOS Platform Integration ⏳

#### 4.1 Update iOS Loader

**File**: `docs/2025-11-25/ios_implementation/QuicUICodePushLoader.mm`

**Replace `dlopen` approach with engine integration**:

```objc
+ (void)initializeWithCachePath:(NSString *)cachePath {
    _cacheDirectory = cachePath;
    
    // QuicUI is now integrated into the engine
    // No need for manual loading - engine handles .vmcode files
    
    NSLog(@"[QuicUI] Initialized iOS Interpreter Mode");
    NSLog(@"[QuicUI] Cache: %@", cachePath);
    NSLog(@"[QuicUI] Patches will be loaded by Dart VM");
}

+ (NSString *)getActivePatchPath {
    // Check for .vmcode file, not .so
    NSString *patchesDir = [_cacheDirectory stringByAppendingPathComponent:@"quicui_patches"];
    NSArray *patches = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:patchesDir error:nil];
    
    for (NSString *file in patches) {
        if ([file hasSuffix:@".vmcode"]) {
            return [patchesDir stringByAppendingPathComponent:file];
        }
    }
    
    return nil;
}
```

#### 4.2 Update AppDelegate

**File**: `ios/Runner/AppDelegate.swift`

```swift
override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    
    // QuicUI configuration
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
    
    // Initialize QuicUI (handled by engine now)
    QuicUICodePushLoader.initialize(withCachePath: cachePath)
    
    // Engine will automatically check for .vmcode patches
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}
```

### Phase 5: Testing & Validation ⏳

#### 5.1 Build Test Flow

1. **Build baseline**:
   ```bash
   dart run quicui.dart build-ipa --version 3.0.36 --baseline
   ```
   - Uses custom engine with interpreter
   - Contains base AOT snapshot

2. **Make code changes** (e.g., change theme)

3. **Generate .vmcode patch**:
   ```bash
   dart run quicui.dart generate-patch --from baseline --to v3.0.37
   ```
   - Generates `3.0.37.vmcode` file
   - Compresses with XZ
   - Uploads to Supabase

4. **Install baseline on device**

5. **App checks for updates**:
   - Downloads `3.0.37.vmcode.xz`
   - Decompresses to cache
   - Engine detects `.vmcode` file
   - Loads via Dart VM ELF loader
   - **SUCCESS**: Patch applied!

#### 5.2 Validation Checklist

- [ ] Engine builds successfully with `QUICUI_USE_INTERPRETER`
- [ ] `.vmcode` files generated correctly
- [ ] Patches compress/decompress properly
- [ ] Engine detects `.vmcode` files in cache
- [ ] Dart VM loads snapshots without amfid errors
- [ ] Patch functionality works (theme changes visible)
- [ ] Performance acceptable (slower than AOT but usable)
- [ ] No crashes or security warnings

### Phase 6: Performance Optimization 🔮

#### Interpreter vs AOT Performance

**Expected**:
- AOT (Android): ~95-100% native performance
- Interpreter (iOS): ~40-60% of AOT performance

**Mitigation**:
- Most UI code is fast enough interpreted
- Critical code stays in base snapshot (AOT)
- Only patch updates are interpreted
- Acceptable for most business logic

**Future**:
- Hybrid approach: Cache JIT-compiled code
- Profile-guided optimization
- Selective AOT for hot paths

## File Structure Changes

### Before (Current - Broken on iOS)
```
v3.0.35/
├── App-v3.0.35           # 3.87 MB - AOT binary
└── App-v3.0.35.xz        # 1.1 MB - Compressed
                          # ❌ Rejected by amfid
```

### After (Interpreter - iOS Compliant)
```
v3.0.37/
├── patch_3.0.37.vmcode   # 2-3 MB - ELF snapshot
└── patch_3.0.37.vmcode.xz # 800 KB - Compressed
                          # ✅ Loaded by Dart VM
```

## API Changes Summary

### Engine (C++)
```cpp
// Old (your current attempt)
dlopen("libapp_patched_arm64.so")  // ❌ Blocked by amfid

// New (Shorebird approach)
Dart_LoadELF("patch_3.0.37.vmcode")  // ✅ Works!
```

### CLI (Dart)
```dart
// Old
CompilerService.compressBinary()  // Uploads full AOT binary

// New  
CompilerService.generateVMCodePatch()  // Generates .vmcode
```

### Client (Dart)
```dart
// Old
final soPath = 'libapp_patched_arm64.so';  // ❌ Won't load

// New
final vmcodePath = 'patch_3.0.37.vmcode';  // ✅ Will load
```

## Migration Path

### For Existing Users
1. **App Store Update Required**:
   - Users need to update to version with interpreter engine
   - Cannot patch from AOT-based to interpreter-based app
   
2. **Baseline Reset**:
   - All existing patches invalidated
   - Users start fresh with new interpreter-based app

3. **Backward Compatibility**:
   - Android continues using AOT (no changes)
   - Only iOS switches to interpreter

## Timeline Estimate

| Phase | Tasks | Estimated Time |
|-------|-------|----------------|
| Phase 1 | Engine modifications | 2-3 days |
| Phase 2 | Build system | 1 day |
| Phase 3 | CLI updates | 1-2 days |
| Phase 4 | iOS integration | 1 day |
| Phase 5 | Testing | 2-3 days |
| **Total** | **Complete implementation** | **7-10 days** |

## Next Steps

1. **Immediate** (Today):
   - ✅ Document findings (this file)
   - ⏳ Set up engine development environment
   - ⏳ Copy Shorebird code to QuicUI engine

2. **Short-term** (This Week):
   - Build modified engine with interpreter
   - Test .vmcode generation
   - Validate engine can load patches

3. **Medium-term** (Next Week):
   - Complete CLI modifications
   - End-to-end testing
   - Performance validation

4. **Long-term** (Month):
   - Production deployment
   - Monitor performance
   - Optimize as needed

## References

### Shorebird Code Locations
- **Engine**: `/Volumes/DoWonder2/quicui_engine_build/shorebird_engine_quicui/src/flutter/`
- **Updater**: `third_party/updater/library/`
- **Key Files**:
  - `shell/common/shorebird/shorebird.cc` - Main integration
  - `runtime/dart_snapshot.cc` - ELF loading
  - `shell/platform/darwin/ios/` - iOS platform

### Key Insights from Research
1. **amfid rejection** is location-based, not signature-based
2. `.vmcode` files are **data**, not executable code
3. Dart VM's `Dart_LoadELF` bypasses iOS restrictions
4. App Store guidelines **explicitly allow** interpreter-based updates
5. Shorebird has been doing this successfully since 2023

### Documentation
- Shorebird FAQ: https://docs.shorebird.dev/code-push/faq/
- App Store Guidelines: Section 3.3.1(b)
- Dart VM API: `third_party/dart/runtime/include/dart_api.h`

## Conclusion

The iOS code push solution requires switching from AOT binaries to interpreter-based `.vmcode` files. This is the **only** App Store-compliant approach for dynamic code updates on iOS. Shorebird has proven this works in production with thousands of apps.

**Recommendation**: Proceed with interpreter implementation. It's the right technical solution, aligns with App Store policies, and provides a path forward for iOS code push.

---

**Status**: Ready to begin implementation  
**Risk**: Low (proven approach)  
**Effort**: Medium (7-10 days)  
**Reward**: Working iOS code push! 🎉
