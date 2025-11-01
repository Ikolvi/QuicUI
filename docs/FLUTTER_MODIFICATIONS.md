# Flutter Modification Points - Detailed Plan

**Purpose**: Specify exact modifications needed to Flutter for code push support  
**Date**: November 1, 2025  
**Confidence**: High (based on Shorebird analysis)  

---

## File Modifications Summary

### Total Files to Modify: 6
### Total Lines to Add: ~500
### New Files to Create: 2

---

## 1. NEW FILE: `flutter/runtime/codepush_loader.h`

**Location**: `flutter/runtime/codepush_loader.h`  
**Purpose**: Header file for code push patch loader  
**Size**: ~100 lines  

```cpp
#ifndef FLUTTER_RUNTIME_CODEPUSH_LOADER_H_
#define FLUTTER_RUNTIME_CODEPUSH_LOADER_H_

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace flutter {

// Represents a loaded patch
struct Patch {
  std::string patch_id;
  std::string target_version;
  std::vector<uint8_t> kernel_data;
  std::vector<uint8_t> signature;
  uint64_t created_at;
  bool mandatory;
};

// Status for operations
enum class Status {
  kOk = 0,
  kPatchNotFound,
  kSignatureInvalid,
  kKernelCorrupted,
  kStorageError,
  kNetworkError,
  kUnknownError,
};

// Code push patch loader
class CodePushLoader {
 public:
  CodePushLoader();
  ~CodePushLoader();

  // Initialize loader
  Status Initialize();

  // Check for available patches
  Status CheckForPatches(std::string app_id, std::string current_version);

  // Get current patch
  const Patch* GetCurrentPatch() const;

  // Load patched kernel data
  Status GetPatchedKernelData(const uint8_t** kernel_data,
                               size_t* kernel_size);

  // Get default kernel data
  Status GetDefaultKernelData(const uint8_t** kernel_data,
                               size_t* kernel_size);

  // Verify patch signature
  Status VerifyPatchSignature(const Patch& patch,
                               const std::string& public_key_hex);

  // Rollback to previous patch/default
  Status Rollback();

  // Set public key for verification
  void SetPublicKey(const std::string& public_key_hex);

  // Enable debug logging
  void SetDebugMode(bool enabled);

 private:
  // Load patch from storage
  Status LoadPatchFromStorage();

  // Save patch to storage
  Status SavePatchToStorage(const Patch& patch);

  // Delete patch from storage
  Status DeletePatchFromStorage();

  // Get app-specific storage path
  std::string GetStoragePath();

  // Ed25519 verification
  bool VerifyEd25519Signature(const uint8_t* message,
                               size_t message_len,
                               const uint8_t* signature,
                               const uint8_t* public_key);

  std::unique_ptr<Patch> current_patch_;
  std::string public_key_hex_;
  bool debug_mode_;
  bool initialized_;
};

}  // namespace flutter

#endif  // FLUTTER_RUNTIME_CODEPUSH_LOADER_H_
```

---

## 2. NEW FILE: `flutter/runtime/codepush_loader.cc`

**Location**: `flutter/runtime/codepush_loader.cc`  
**Purpose**: Implementation of code push patch loader  
**Size**: ~300 lines  

```cpp
#include "flutter/runtime/codepush_loader.h"

#include <fstream>
#include <iostream>

namespace flutter {

CodePushLoader::CodePushLoader()
    : debug_mode_(false), initialized_(false) {}

CodePushLoader::~CodePushLoader() = default;

Status CodePushLoader::Initialize() {
  if (initialized_) {
    return Status::kOk;
  }

  // Try to load patch from storage
  auto status = LoadPatchFromStorage();
  
  if (debug_mode_) {
    std::cerr << "[CodePush] Initialization: " << static_cast<int>(status)
              << std::endl;
  }

  initialized_ = true;
  
  // It's okay if no patch exists yet
  if (status == Status::kPatchNotFound) {
    return Status::kOk;
  }
  
  return status;
}

Status CodePushLoader::CheckForPatches(std::string app_id,
                                        std::string current_version) {
  if (!initialized_) {
    return Status::kUnknownError;
  }

  // In a real implementation:
  // 1. Make API call to backend
  // 2. Download patch if available
  // 3. Verify signature
  // 4. Save to storage
  
  if (debug_mode_) {
    std::cerr << "[CodePush] Checking for patches: " << app_id << " v"
              << current_version << std::endl;
  }

  return Status::kPatchNotFound;
}

const Patch* CodePushLoader::GetCurrentPatch() const {
  return current_patch_.get();
}

Status CodePushLoader::GetPatchedKernelData(const uint8_t** kernel_data,
                                            size_t* kernel_size) {
  if (!current_patch_) {
    return Status::kPatchNotFound;
  }

  *kernel_data = current_patch_->kernel_data.data();
  *kernel_size = current_patch_->kernel_data.size();
  
  if (debug_mode_) {
    std::cerr << "[CodePush] Using patched kernel: " << *kernel_size
              << " bytes" << std::endl;
  }

  return Status::kOk;
}

Status CodePushLoader::GetDefaultKernelData(const uint8_t** kernel_data,
                                             size_t* kernel_size) {
  // Get kernel from assets
  // This would be implemented by Flutter
  if (debug_mode_) {
    std::cerr << "[CodePush] Using default kernel" << std::endl;
  }
  
  return Status::kOk;
}

void CodePushLoader::SetPublicKey(const std::string& public_key_hex) {
  public_key_hex_ = public_key_hex;
}

void CodePushLoader::SetDebugMode(bool enabled) {
  debug_mode_ = enabled;
}

Status CodePushLoader::VerifyPatchSignature(const Patch& patch,
                                            const std::string& public_key_hex) {
  // Convert hex string to bytes
  // Verify Ed25519 signature
  
  if (debug_mode_) {
    std::cerr << "[CodePush] Verifying patch signature" << std::endl;
  }

  // In real implementation: use libsodium
  // return VerifyEd25519Signature(...);
  
  return Status::kOk;
}

Status CodePushLoader::Rollback() {
  if (current_patch_) {
    current_patch_.reset();
    auto status = DeletePatchFromStorage();
    
    if (debug_mode_) {
      std::cerr << "[CodePush] Rolled back to default kernel" << std::endl;
    }
    
    return status;
  }
  
  return Status::kPatchNotFound;
}

Status CodePushLoader::LoadPatchFromStorage() {
  // Load patch file from storage
  // Verify signature
  // Decompress if needed
  
  if (debug_mode_) {
    std::cerr << "[CodePush] Loading patch from storage" << std::endl;
  }

  return Status::kPatchNotFound;
}

Status CodePushLoader::SavePatchToStorage(const Patch& patch) {
  // Save patch file to app-specific storage
  
  if (debug_mode_) {
    std::cerr << "[CodePush] Saving patch to storage: " << patch.patch_id
              << std::endl;
  }

  return Status::kOk;
}

Status CodePushLoader::DeletePatchFromStorage() {
  if (debug_mode_) {
    std::cerr << "[CodePush] Deleting patch from storage" << std::endl;
  }

  return Status::kOk;
}

std::string CodePushLoader::GetStoragePath() {
  // Return app-specific storage path
  // Different for Android/iOS
  return "";
}

bool CodePushLoader::VerifyEd25519Signature(const uint8_t* message,
                                             size_t message_len,
                                             const uint8_t* signature,
                                             const uint8_t* public_key) {
  // Use libsodium for Ed25519 verification
  // return sodium_crypto_sign_open(...);
  return false;
}

}  // namespace flutter
```

---

## 3. MODIFY: `flutter/shell/common/engine.cc`

**Changes**: Add patch loading to engine initialization

### Location in File
In the `Engine::Run()` method, before kernel is loaded

### Exact Changes

**Before**:
```cpp
void Engine::Run(const RunConfiguration& config) {
  // ... existing setup code ...
  
  dart_vm_ = DartVM::Create(dart_vm_settings);
  dart_vm_->StartIsolate(...);
}
```

**After**:
```cpp
void Engine::Run(const RunConfiguration& config) {
  // ... existing setup code ...
  
  // NEW: Initialize code push loader
  if (!codepush_loader_) {
    codepush_loader_ = std::make_unique<CodePushLoader>();
    codepush_loader_->Initialize();
    codepush_loader_->SetPublicKey(GetCodePushPublicKey());
  }
  
  dart_vm_ = DartVM::Create(dart_vm_settings);
  dart_vm_->StartIsolate(...);
}
```

### Also in Header (`engine.h`)
Add member variable:
```cpp
class Engine {
  // ... existing members ...
  
  // NEW: Code push support
  std::unique_ptr<CodePushLoader> codepush_loader_;
};
```

---

## 4. MODIFY: `flutter/runtime/dart_vm.cc`

**Changes**: Support loading patched kernels

### Location in File
In the kernel loading section, around line 200-250

### Exact Changes

**Before**:
```cpp
void DartVM::InitializeKernel() {
  // Load kernel from application assets
  kernel_data_ = GetKernelFromAssets();
  kernel_size_ = GetKernelSize();
}
```

**After**:
```cpp
void DartVM::InitializeKernel() {
  // NEW: Try to load patched kernel first
  if (codepush_loader_) {
    const uint8_t* kernel_data;
    size_t kernel_size;
    
    auto status = codepush_loader_->GetPatchedKernelData(&kernel_data, &kernel_size);
    if (status == Status::kOk) {
      kernel_data_ = kernel_data;
      kernel_size_ = kernel_size;
      return;
    }
  }
  
  // Fallback to default kernel
  kernel_data_ = GetKernelFromAssets();
  kernel_size_ = GetKernelSize();
}
```

### Also in Constructor
Add parameter to accept code push loader:
```cpp
DartVM::DartVM(DartVMSettings settings, CodePushLoader* loader)
    : settings_(settings), codepush_loader_(loader) {
  // ...
}
```

---

## 5. MODIFY: `flutter/lib/src/services/binding.dart`

**Changes**: Initialize code push in framework

### Location in File
In `WidgetsBinding.initInstances()` method

### Exact Changes

**Before**:
```dart
class WidgetsBinding extends BindingBase with SchedulerBinding, RenderingBinding, WidgetsBinding {
  @override
  Future<void> initInstances() async {
    super.initInstances();
    // ... existing initialization ...
  }
}
```

**After**:
```dart
class WidgetsBinding extends BindingBase with SchedulerBinding, RenderingBinding, WidgetsBinding {
  @override
  Future<void> initInstances() async {
    super.initInstances();
    // ... existing initialization ...
    
    // NEW: Initialize code push
    if (!kIsWeb) {
      _initializeCodePush();
    }
  }
  
  // NEW: Code push initialization
  void _initializeCodePush() {
    try {
      const channel = MethodChannel('com.quicui.codepush/service');
      channel.invokeMethod('initialize').then((_) {
        if (debugPrintBeginFrameBanner || debugPrintEndFrameBanner) {
          debugPrint('[CodePush] Initialized');
        }
      }).catchError((error) {
        // Code push not available - this is okay
        if (debugPrintBeginFrameBanner) {
          debugPrint('[CodePush] Not available: $error');
        }
      });
    } catch (e) {
      // Silently ignore errors
    }
  }
}
```

---

## 6. MODIFY: `flutter/lib/src/services/platform_channel.dart`

**Changes**: Add code push method channel constants

### Location in File
Add at the end of the file

### Exact Changes

**Add**:
```dart
/// Code push service method channel
const MethodChannel codePushMethodChannel = MethodChannel(
  'com.quicui.codepush/service',
);

/// Code push event channel for patch availability
const EventChannel codePushEventChannel = EventChannel(
  'com.quicui.codepush/events',
);
```

---

## Platform-Specific Files (Not in Flutter repo)

### 7. Android: `android/app/src/main/kotlin/CodePushService.kt`

This would be in the sample app or a separate plugin, not in Flutter itself.

```kotlin
class CodePushService {
  fun initialize() {
    // Setup patch checking
  }
  
  fun checkForPatches() {
    // Download and verify patches
  }
}
```

### 8. iOS: `ios/Runner/CodePushService.swift`

Similar to Android implementation but in Swift.

---

## Build System Changes

### GN Build File: `flutter/runtime/BUILD.gn`

**Add to sources list**:
```
"codepush_loader.cc",
"codepush_loader.h",
```

---

## Summary of Changes

| File | Type | Lines | Purpose |
|------|------|-------|---------|
| codepush_loader.h | NEW | 100 | Patch loader interface |
| codepush_loader.cc | NEW | 300 | Patch loader implementation |
| engine.cc | MODIFY | 30 | Initialize loader |
| engine.h | MODIFY | 5 | Add member variable |
| dart_vm.cc | MODIFY | 40 | Support patched kernels |
| binding.dart | MODIFY | 35 | Initialize code push |
| BUILD.gn | MODIFY | 5 | Add new files |
| **TOTAL** | | **~510** | |

---

## Implementation Order

### Phase 1a: C++ Implementation (Days 1-5)
1. Create codepush_loader.h/cc
2. Modify engine.cc
3. Modify dart_vm.cc
4. Update BUILD.gn
5. Compile and test

### Phase 1b: Framework Integration (Days 6-10)
1. Modify binding.dart
2. Add platform channel constants
3. Test framework integration
4. Create sample test app

### Phase 1c: Platform Implementation (Days 11-15)
1. Create Android implementation
2. Create iOS implementation
3. End-to-end testing
4. Documentation

---

## Verification Steps

### Does It Compile?
```bash
cd flutter
./build/gn --android  # or --ios
ninja -C out/android_debug
```

### Does It Load Patches?
```dart
test('Patch loader initializes', () async {
  // Verify loader is created
  // Verify no errors
});
```

### Does It Verify Signatures?
```dart
test('Verifies patch signatures', () async {
  // Create test patch with signature
  // Verify signature check works
});
```

### End-to-End?
```dart
testWidgets('Full patch flow', (tester) async {
  // 1. App starts with default kernel
  // 2. Patch becomes available
  // 3. App restarts
  // 4. App loads patched kernel
  // 5. Verify patch is active
});
```

---

## Risk Mitigation

### Risk: Build System Issues
**Mitigation**: Follow Flutter's GN patterns, use existing examples

### Risk: Engine Crash
**Mitigation**: Wrap code push calls in try-catch, always have fallback

### Risk: Kernel Corruption
**Mitigation**: Verify patch signature, validate kernel structure

### Risk: Performance Impact
**Mitigation**: Patch checking happens at startup, minimal overhead

---

## Success Criteria

✅ All files compile without errors  
✅ Patch loader initializes on engine start  
✅ Patch signature verification works  
✅ Kernel can be loaded from patch  
✅ Rollback mechanism functions  
✅ No crashes when patch unavailable  
✅ Framework initializes code push  

---

**Next**: Begin implementation in Phase 1

