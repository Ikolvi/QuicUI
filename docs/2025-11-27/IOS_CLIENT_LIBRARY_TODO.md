# iOS Client Library Implementation - Phase 3

## Status: IN PROGRESS

**Date**: November 27, 2025  
**Current Issue**: .vmcode patch downloads and decompresses successfully, but fails to load into Dart VM

## What's Working ✅

1. **Engine** (Phase 1): Custom engine with `QUICUI_USE_INTERPRETER` flag built
   - Location: `/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/out/ios_release`
   - Supports `Dart_LoadELF()` for .vmcode loading
   - Reference: Shorebird implementation

2. **CLI** (Phase 2): .vmcode generation complete
   - Generates .vmcode using `gen_snapshot --snapshot_kind=app-aot-elf`
   - Compresses with XZ
   - Uploads to backend successfully
   - **Latest patch**: v3.0.39 → v3.0.40 (1.14 MB compressed)

3. **Client Download**: Dart side working
   - Downloads .vmcode.xz from backend ✅
   - Decompresses XZ format ✅  
   - Detects file type correctly (`.vmcode`) ✅
   - Saves to: `/var/mobile/.../tmp/quicui_patch_3.0.40.quicui` ✅

4. **Client Install**: Partial iOS implementation
   - Detects `.vmcode` extension ✅
   - Copies file to cache directory ✅
   - **BUT**: Doesn't integrate with engine ❌

## Current Problem ❌

**Error**: `Failed to install patch: The operation couldn't be completed. (quicui_code_push_client.QuicUICodePushLoader.CodePushError error 0.)`

**Root Cause**: The .vmcode file is being copied to cache, but:
1. Wrong destination path (`libapp_patched_arm64.so` instead of `.vmcode`)
2. Engine not configured to load .vmcode at startup
3. No AppDelegate integration to trigger engine loading

## Implementation Required

### 1. Fix installPatch to Store .vmcode Correctly

**File**: `packages/quicui_code_push_client/ios/quicui_code_push_client/CodePushMethodHandler.swift`

**Current Code** (line ~200):
```swift
// Final destination for C++ loader
// C++ loader expects: libapp_patched_<arch>.so
let destinationURL = patchesDirectory.appendingPathComponent("libapp_patched_\(arch).so")
```

**Should Be**:
```swift
let destinationFilename: String
if isVMCode {
    // For .vmcode files, keep the .vmcode extension
    destinationFilename = "\(version).vmcode"
} else {
    // For binary patches (Android), use .so extension
    destinationFilename = "libapp_patched_\(arch).so"
}
let destinationURL = patchesDirectory.appendingPathComponent(destinationFilename)
```

### 2. Create Engine Integration Layer

The iOS engine needs to be told to load the .vmcode file. This requires:

**File**: `packages/quicui_code_push_client/ios/quicui_code_push_client/QuicUIEngineLoader.swift` (NEW)

```swift
import Flutter
import Foundation

/// Integrates with custom QuicUI Flutter engine to load .vmcode patches
class QuicUIEngineLoader {
    
    /// Check for pending .vmcode patch and prepare engine arguments
    static func prepareEngineArgs() -> [String]? {
        let fileManager = FileManager.default
        
        // Check for installed .vmcode files
        guard let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let patchesDir = cachesDir.appendingPathComponent("quicui_patches", isDirectory: true)
        
        guard let files = try? fileManager.contentsOfDirectory(
            at: patchesDir,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else {
            return nil
        }
        
        // Find the latest .vmcode file
        let vmcodeFiles = files.filter { $0.pathExtension == "vmcode" }
        guard let latestVMCode = vmcodeFiles.sorted(by: {
            let date1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
            let date2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
            return date1 > date2
        }).first else {
            return nil
        }
        
        print("[QuicUI] Found .vmcode patch: \(latestVMCode.path)")
        
        // Return engine arguments for loading .vmcode
        // The custom engine looks for these arguments to load interpreter snapshot
        return [
            "--vmcode-snapshot=\(latestVMCode.path)"
        ]
    }
}
```

### 3. Integrate with AppDelegate

**File**: `test_apps/quicui_production_test/ios/Runner/AppDelegate.swift`

**Current**:
```swift
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**Should Be**:
```swift
import quicui_code_push_client  // Import the plugin

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Check for .vmcode patches before creating Flutter engine
    if let engineArgs = QuicUIEngineLoader.prepareEngineArgs() {
        print("[QuicUI] Loading with interpreter patch: \(engineArgs)")
        
        // Pass arguments to Flutter engine
        // NOTE: This requires custom engine integration
        // The engine must support --vmcode-snapshot argument
        
        // For custom engine, we might need to use FlutterEngineGroup
        // or modify engine initialization to accept runtime arguments
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 4. Engine Argument Passing (CRITICAL)

**Problem**: Standard Flutter iOS doesn't allow passing runtime arguments to the engine from AppDelegate.

**Solution Options**:

#### Option A: Modify Flutter Engine Bootstrap (Preferred)
Add hook in `shell/platform/darwin/ios/framework/Source/FlutterEngine.mm`:

```objc
// In FlutterEngine initialization
- (instancetype)initWithName:(NSString*)labelPrefix
                     project:(FlutterDartProject*)projectOrNil {
    
    // Check for QuicUI .vmcode file
    NSString* vmcodePath = [self checkForQuicUIVMCode];
    if (vmcodePath) {
        NSLog(@"[QuicUI] Loading .vmcode: %@", vmcodePath);
        
        // Add to Dart VM arguments
        // This loads the ELF snapshot via Dart_LoadELF()
        [settings.dart_entrypoint_args addObject:
            [NSString stringWithFormat:@"--vmcode-snapshot=%@", vmcodePath]];
    }
    
    // Continue with normal initialization...
}
```

#### Option B: Use Environment Variable
Set environment variable that engine checks:

```swift
// In AppDelegate before engine creation
if let vmcodePath = QuicUIEngineLoader.getVMCodePath() {
    setenv("QUICUI_VMCODE_PATH", vmcodePath.cString(using: .utf8), 1)
}
```

Then modify engine to check:
```cpp
// In shell/common/quicui/quicui.cc
const char* vmcode_path = getenv("QUICUI_VMCODE_PATH");
if (vmcode_path) {
    Dart_LoadELF(vmcode_path, ...);
}
```

#### Option C: File-Based Configuration (Simplest)
Engine checks well-known path on startup:

```cpp
// In shell/common/quicui/quicui.cc
// Check for .vmcode file in known location
std::string vmcode_path = GetCachesDirectory() + "/quicui_patches/current.vmcode";
if (FileExists(vmcode_path)) {
    Dart_LoadELF(vmcode_path.c_str(), ...);
}
```

Client library creates symlink:
```swift
// After installing patch
let currentLink = patchesDir.appendingPathComponent("current.vmcode")
try? fileManager.removeItem(at: currentLink)
try fileManager.createSymbolicLink(at: currentLink, withDestinationURL: vmcodeFile)
```

## Testing Plan

1. Fix `destinationURL` to use `.vmcode` extension
2. Implement **Option C** (File-Based) - simplest and most reliable
3. Update engine `shell/common/quicui/quicui.cc` to check for `current.vmcode`
4. Rebuild engine
5. Update client to create `current.vmcode` symlink
6. Test patch installation:
   - Install v3.0.39 baseline
   - Download patch v3.0.40
   - Restart app
   - Verify purple theme loads

## Estimated Time

- Fix 1 (destinationURL): **5 minutes**
- Fix 2 (Engine integration): **30-45 minutes**
- Fix 3 (Client symlink): **10 minutes**
- Engine rebuild: **20 minutes**
- Testing: **15 minutes**

**Total**: ~90 minutes

## Next Steps

1. Update `CodePushMethodHandler.swift` destination path
2. Add engine .vmcode loading logic
3. Rebuild engine with .vmcode loader
4. Update client to create symlink
5. Test end-to-end on device

## References

- Shorebird implementation: `/Volumes/DoWonder2/quicui_engine_build/shorebird_engine_quicui/`
- Engine modifications doc: `docs/2025-11-27/CLI_IOS_SUPPORT_COMPLETE.md`
- Current patch: v3.0.39 → v3.0.40, ID: 1764246748435
