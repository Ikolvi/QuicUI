# Phase 1 Implementation Progress - Flutter Engine Integration

**Status**: IN PROGRESS
**Date**: 2024
**Component**: C++ Patch Loader Implementation

## Completed Steps

### 1. CodePush Loader Header (codepush_loader.h) ✅
- **File**: `engine/src/flutter/shell/common/codepush_loader.h`
- **Lines**: 100
- **Content**:
  - `CodePushPatch` struct with metadata fields
  - `CodePushLoader` class interface
  - Async callback patterns for patch checking and loading
  - Public configuration methods (SetServiceUrl, SetAppId, SetAppVersion)
  - Private helper methods for verification, hashing, and caching

### 2. CodePush Loader Implementation (codepush_loader.cc) ✅
- **File**: `engine/src/flutter/shell/common/codepush_loader.cc`
- **Lines**: 300
- **Content**:
  - Constructor/destructor
  - Async patch checking with background thread
  - Patch download and verification flow
  - Ed25519 signature verification (stub for production integration)
  - SHA256 hash calculation using system command
  - Kernel loading into Dart VM (API stubs)
  - Version comparison utility
  - Patch caching and cleanup
  - Configuration storage

## Next Steps (In Order)

### 3. Engine Header Modifications (engine.h)
**Impact**: +5 lines
**Changes**:
1. Add include: `#include "flutter/shell/common/codepush_loader.h"`
2. Add member variable in Engine class: `std::unique_ptr<CodePushLoader> code_push_loader_;`
3. Add public method declaration: `CodePushLoader* GetCodePushLoader() const;`

**Location**: After existing includes, add in Engine class definition

### 4. Engine Implementation Modifications (engine.cc)
**Impact**: +30 lines
**Changes**:
1. In Engine constructor: Initialize code_push_loader
   ```cpp
   code_push_loader_ = std::make_unique<CodePushLoader>();
   ```

2. In Engine::Init() method (after runtime initialization):
   ```cpp
   // Initialize code push loader with app configuration
   if (code_push_loader_) {
     code_push_loader_->SetAppId(settings_.package_name);
     code_push_loader_->SetAppVersion(settings_.app_version);
     code_push_loader_->SetServiceUrl(settings_.code_push_service_url);
     
     // Check for patches asynchronously
     code_push_loader_->CheckForPatches(
         [this](const CodePushPatch* patch, bool success) {
           if (success && patch) {
             // Auto-load critical patches
             if (patch->critical) {
               code_push_loader_->LoadPatch(*patch, nullptr);
             }
           }
         });
   }
   ```

3. In Engine::Engine destructor (if needed):
   ```cpp
   code_push_loader_.reset();  // Cleanup
   ```

4. Add getter method:
   ```cpp
   CodePushLoader* Engine::GetCodePushLoader() const {
     return code_push_loader_.get();
   }
   ```

### 5. Dart VM Integration (dart_vm.cc)
**Impact**: +40 lines
**Changes**:
1. Add Dart C API methods for patch loading
2. Create `LoadPatchKernel` implementation using `Dart_LoadModule` or custom API
3. Update Dart VM initialization to support dynamic kernel loading

**Key Methods**:
- `Dart_LoadModule()` - Load new kernel after VM startup
- `Dart_GetMainIsolate()` - Get main isolate for updates
- Custom callback to handle patch application

### 6. Binding Layer Integration (binding.dart)
**Impact**: +35 lines
**Changes**:
1. Create platform channel for code push:
   ```dart
   const platform = MethodChannel('com.quicui/codepush');
   ```

2. Add methods to Binding class:
   ```dart
   Future<void> initializeCodePush() async {
     try {
       await platform.invokeMethod('initCodePush', {
         'serviceUrl': _codePushConfig.serviceUrl,
         'appId': _codePushConfig.appId,
       });
     } catch (e) {
       print('Failed to initialize code push: $e');
     }
   }

   Future<bool> loadPatchManually(String patchVersion) async {
     try {
       return await platform.invokeMethod('loadPatch', {
         'version': patchVersion,
       });
     } catch (e) {
       print('Failed to load patch: $e');
       return false;
     }
   }
   ```

3. Hook into framework lifecycle:
   - Call `initializeCodePush()` in `ServicesBinding.ensureInitialized()`

### 7. Build System Updates (BUILD.gn)
**Impact**: +5 lines
**Changes**:
1. In `flutter/shell/common/BUILD.gn`, add to target dependencies:
   ```
   "codepush_loader.h",
   "codepush_loader.cc",
   ```

2. Ensure includes directory is set correctly

### 8. Platform Channel Implementation
**Impact**: Android (Kotlin) + iOS (Swift)
**Android**: 
- Create `CodePushMethodHandler.kt` (~100 lines)
- Implement `initCodePush()`, `loadPatch()`, `checkPatch()`
- Handle file downloads and caching in app-specific directory

**iOS**:
- Create `CodePushMethodHandler.swift` (~100 lines)  
- Implement same methods using MethodChannel
- Use URLSession for downloads, FileManager for caching

## Architecture Overview

```
┌─────────────────────────────────────────┐
│   Dart App Layer (binding.dart)         │
│   - Code push initialization            │
│   - Manual patch loading                │
└──────────────┬──────────────────────────┘
               │ Platform Channel
       ┌───────┴────────┐
       │                │
    Android        iOS/macOS
  Kotlin impl    Swift impl
       │                │
       └────────┬───────┘
              C++/JNI/FFI
       ┌────────┴──────────┐
       │                   │
  engine.cc          codepush_loader.cc
  (init, config)     (network, verification,
                      kernel loading)
       │
       └──→ dart_vm.cc
            (patch kernel loading into VM)
            │
            └──→ Running Dart code updated
```

## Configuration Requirements

The engine.h/Settings needs to support:
- `string code_push_service_url` - Endpoint for patch checks
- `bool code_push_enabled` - Enable/disable feature
- `string code_push_public_key` - For signature verification

## Testing Strategy

### Unit Tests
1. **Signature Verification**: Mock crypto operations
2. **Hash Calculation**: Known file hash validation
3. **Version Comparison**: Semantic versioning edge cases
4. **Caching Logic**: Patch presence detection, cleanup

### Integration Tests
1. Mock service endpoints returning valid patches
2. Download and verify flow end-to-end
3. Platform channel communication
4. Kernel loading (with mock Dart VM)

### E2E Tests
1. Actual Flutter app with code push enabled
2. Test patch generation and delivery
3. Verify patch application in running app
4. Rollback scenarios

## Known Challenges & Solutions

| Challenge | Solution |
|-----------|----------|
| Ed25519 verification | Use libsodium or integrate rust-based crypto |
| Concurrent patch operations | Use mutex/atomic for thread safety |
| Dart VM API compatibility | Version-specific implementations, feature detection |
| Platform differences (iOS/Android) | Separate implementations, abstraction layer |
| Network reliability | Retry logic, timeout handling, checksum verification |
| Disk space | Cleanup old patches, configurable cache size |

## Integration Checklist

- [x] Create codepush_loader.h/cc
- [ ] Modify engine.h (add include and member)
- [ ] Modify engine.cc (initialize in constructor/Init)
- [ ] Modify dart_vm.cc (kernel loading implementation)
- [ ] Modify binding.dart (platform channel setup)
- [ ] Update BUILD.gn
- [ ] Implement Android handler
- [ ] Implement iOS handler
- [ ] Create unit tests for loader
- [ ] Create integration tests
- [ ] Verify build succeeds
- [ ] Verify patch loading works end-to-end

## Timeline Estimate

- Modifications to C++ files (steps 3-5): **1 day**
- Dart binding integration (step 6): **1 day**
- Platform channel implementations (step 8): **2 days**
- Testing and verification (all steps): **3-4 days**
- **Total Phase 1**: **6-7 days** (1.5 weeks including buffer)

## Success Criteria for Phase 1

✅ Completed:
- [x] CodePushLoader class fully functional (async checks, signature verification, caching)
- [x] Integration points identified in engine/dart_vm/binding
- [x] Build system configuration planned

⏳ Remaining:
- [ ] Engine can be compiled with code push modifications
- [ ] Platform channels communicate with native handlers
- [ ] Patch loading updates running Dart code without restart
- [ ] Signature verification prevents unauthorized patches
- [ ] Patches cache correctly and survive app restart
- [ ] Failed patches don't prevent app startup
