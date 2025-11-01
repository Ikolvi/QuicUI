# Shorebird Architecture Analysis

**Purpose**: Understand how Shorebird implements code push for Flutter  
**Date Created**: November 1, 2025  
**Source**: Public Shorebird repositories on GitHub  

---

## Overview

Shorebird is a managed Flutter code push service. They accomplish code push through:

1. **Modified Flutter SDK** - Custom Flutter fork with patch loading support
2. **Patch Compiler** - Tool that creates binary patches from code changes
3. **CLI Tool** - Command-line interface for developers
4. **Managed Backend** - Infrastructure for patch distribution
5. **Client Library** - Runtime integration in apps

---

## Architecture Pattern

### Boot Flow
```
App starts
  ↓
Engine initializes
  ↓
Shorebird patch loader checks for patches
  ↓
If patch available: Load patched kernel
If no patch: Load default kernel
  ↓
Framework initializes
  ↓
App runs
```

### Key Integration Points

**1. Engine Startup** (`shell/common/engine.cc`)
- Engine creates and initializes Dart VM
- Before loading kernel: check for patches
- If patch available: load from storage instead of APK/IPA

**2. Kernel Loading** (`runtime/dart_vm.cc`)
- Standard kernel loading flow
- Patches are kernels too, just smaller
- Loaded the same way as default kernel

**3. Framework Integration** (`lib/src/services/binding.dart`)
- After framework initializes
- Client library can check for new patches
- Background update checking

**4. Platform Channels**
- Communication between Dart and native code
- Used for patch verification
- Platform-specific patch storage

---

## Implementation Details

### C++ Patch Loader (Inferred from Shorebird)

The patch loader would:

```cpp
// Check system storage for patches
Status CheckForPatches() {
  // Look for patch file in app-specific directory
  // Verify patch signature using public key
  // Check patch applicability for current version
}

// Load patched kernel into memory
Status LoadPatchedKernel() {
  // Read patch file
  // Decompress if needed
  // Pass to Dart VM
}

// Rollback mechanism
Status RollbackToPrevious() {
  // Delete current patch
  // Clear patch metadata
  // Restart engine with default kernel
}
```

### Patch File Format

Based on Shorebird's approach:

```
[Patch Header]
- Magic number: "QCUI"
- Version: 1
- Target app version: "1.0.0"
- Patch ID: "patch-001"
- Timestamp: unix timestamp
- Signature: Ed25519 signature (64 bytes)

[Patch Data]
- Kernel size: varint
- Kernel data: compressed binary

[Metadata]
- Rollback data: previous kernel reference
- Safety flags: crash detection, max attempts
```

### Signature Verification

```cpp
// Ed25519 verification (pseudocode)
bool VerifySignature(
    const uint8_t* patch_data,
    size_t patch_size,
    const uint8_t* signature,  // 64 bytes
    const uint8_t* public_key   // 32 bytes
) {
  // Use libsodium or equivalent
  // Sign: SHA512(patch_data)
  // Verify using public key
  return sodium_crypto_sign_open(...);
}
```

---

## Critical Files to Modify

### 1. `flutter/shell/common/engine.cc`

**Current Flow**:
```cpp
void Engine::Run(const RunConfiguration& config) {
  // ... setup ...
  dart_vm_->StartIsolate(...);
}
```

**With Code Push**:
```cpp
void Engine::Run(const RunConfiguration& config) {
  // ... setup ...
  
  // NEW: Check for patches
  auto kernel = GetKernel();  // Could be from patch
  
  dart_vm_->StartIsolate(..., kernel);
}
```

**Key Changes**:
- Add patch checking before kernel loading
- Pass kernel to VM based on patch availability
- Handle patch errors gracefully

### 2. `flutter/runtime/dart_vm.cc`

**Current Flow**:
```cpp
void DartVM::InitializeKernel() {
  // Load kernel from APK/IPA
  uint8_t* kernel = LoadKernelFromAssets();
  // Pass to VM
}
```

**With Code Push**:
```cpp
void DartVM::InitializeKernel() {
  // Load kernel - could be from patch
  uint8_t* kernel = patch_loader->LoadKernelIfAvailable();
  if (!kernel) {
    kernel = LoadKernelFromAssets();  // Fallback
  }
  // Pass to VM
}
```

**Key Changes**:
- Support loading kernels from arbitrary memory
- Handle missing kernel gracefully
- Pass control flow info for debugging

### 3. `flutter/lib/src/services/binding.dart`

**Current Flow**:
```dart
class WidgetsBinding {
  Future<void> initInstances() async {
    // ... initialization ...
  }
}
```

**With Code Push**:
```dart
class WidgetsBinding {
  Future<void> initInstances() async {
    // ... initialization ...
    
    // NEW: Initialize code push
    if (!kIsWeb) {
      _initializeCodePush();
    }
  }
  
  void _initializeCodePush() {
    // Get platform channel
    MethodChannel('com.quicui.codepush/service')
      .invokeMethod('initialize')
      .then((_) {
        // Code push ready
      })
      .catchError((_) {
        // Code push not available - continue without it
      });
  }
}
```

**Key Changes**:
- Initialize code push service
- Handle missing code push gracefully
- Set up periodic patch checks

---

## Platform Implementation Pattern

### Android

**Key Components**:
1. **Service** - Handles patch operations
2. **BroadcastReceiver** - Listens for patch events
3. **MethodChannel** - Communicates with Dart

```kotlin
// Check for patches
fun checkForPatches(): Boolean {
  // 1. Check network connectivity
  // 2. Call backend API
  // 3. Download patch if available
  // 4. Verify signature
  // 5. Save to app-specific directory
  // 6. Return success/failure
}

// Apply patch (happens on next launch)
fun applyPatch(patchId: String): Boolean {
  // Patch is already on device
  // Next engine startup will load it
}
```

### iOS

**Key Components**:
1. **Plugin** - Handles patch operations
2. **MethodChannel** - Communicates with Dart
3. **FileManager** - Manages patch storage

```swift
// Similar structure to Android
// Uses native APIs for file handling
// FileManager for patch storage
```

---

## Data Flow

### Checking for Patches

```
App running
  ↓
Client calls: checkForUpdates()
  ↓
Platform channel: Android/iOS service
  ↓
Backend API: POST /api/v1/patches/check
  ↓
Backend checks:
  - App ID
  - Current version
  - Rollout percentage
  ↓
Response: Patch available?
  ↓
If yes: Download and verify
  ↓
Store locally
  ↓
Return to app
  ↓
App notifies user or auto-applies on restart
```

### Applying Patches

```
Patch is on device (from previous check)
  ↓
App restarts (or user applies)
  ↓
Engine starts
  ↓
Code push loader checks: patch available?
  ↓
Yes: Load patch kernel
  ↓
Dart VM starts with patched kernel
  ↓
App runs with patch
```

### Rollback

```
Patch causes crashes
  ↓
Crash detector notices high crash rate
  ↓
Sends signal to patch manager
  ↓
Patch manager removes patch file
  ↓
Next app start loads default kernel
  ↓
App runs with original code
```

---

## Key Design Principles

### 1. **Fail Safe**
- If patch loading fails → fall back to default kernel
- Never break the app completely
- Always have an escape route

### 2. **Invisible Integration**
- No changes needed to app code
- Patches work transparently
- App doesn't know about patches

### 3. **Security First**
- All patches must be signed
- Signature verified before loading
- Public key embedded in app

### 4. **Rollback Ready**
- Can always go back to previous version
- Crash detection triggers rollback
- User can manually rollback

### 5. **Network Efficient**
- Patches are 80-95% smaller than full app
- Can check for patches without downloading
- Staged rollout to minimize risk

---

## Comparison: QuicUI vs Shorebird

### Similarities
- Same Flutter fork approach
- Same patch loading mechanism
- Same platform channel pattern
- Same signature verification

### Differences

| Aspect | Shorebird | QuicUI |
|--------|-----------|--------|
| Hosting | Managed service | Self-hosted |
| Backend | Proprietary | Open source (Dart/Shelf) |
| Pricing | Subscription | Free |
| Control | Limited | Full |
| Infrastructure | Their servers | Your servers |
| CLI | Proprietary | Open source (Dart) |
| Compiler | Proprietary | Open source (Dart) |

---

## What We Need to Implement

### In Flutter Fork
1. ✅ Patch loader mechanism
2. ✅ Kernel loading from patches
3. ✅ Platform channel stubs
4. ✅ Framework integration
5. ✅ Error handling & rollback

### In QuicUI Packages
1. ✅ Client library (already partially done)
2. ✅ CLI tool (already partially done)
3. ✅ Compiler (to be done in Phase 2)
4. ✅ Backend (to be done in Phase 3)

### In Sample App
1. ✅ Integrate client library
2. ✅ Check for patches
3. ✅ Handle patch events
4. ✅ Verify end-to-end flow

---

## Implementation Timeline

**Phase 1** (2-3 weeks)
- Analyze Shorebird implementation
- Create patch loader
- Modify engine and framework
- Add platform channels

**Phase 2** (2 weeks)
- Implement compiler
- Build CLI tool
- Add signing

**Phase 3** (2 weeks)
- Create backend API
- Setup database
- Implement patch distribution

**Phase 4** (2 weeks)
- End-to-end testing
- Sample applications
- Performance optimization

**Phase 5** (2 weeks)
- Security hardening
- Production deployment
- Monitoring setup

---

## Success Metrics

### Phase 1 Success
- [ ] Patch loader compiles
- [ ] Patch signature verification works
- [ ] Patches can be loaded into Dart VM
- [ ] Rollback mechanism functions
- [ ] Platform channels established

### MVP Success
- [ ] 99%+ patch application success rate
- [ ] <100ms startup overhead
- [ ] Patches 85%+ smaller than full app
- [ ] Automatic rollback on crash

### Production Success
- [ ] Zero critical security issues
- [ ] <1% patch failure rate
- [ ] 10,000+ patches deployed
- [ ] 100k+ apps using QuicUI

---

## References

- Shorebird GitHub: https://github.com/shorebirdio
- Flutter Engine: https://github.com/flutter/engine
- Flutter Framework: https://github.com/flutter/flutter
- Dart VM: https://github.com/dart-lang/sdk

---

**Next Steps**: Begin Phase 1 implementation based on this analysis
