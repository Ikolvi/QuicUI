# QuicUI iOS Engine Modifications Guide

**Date:** November 25, 2025  
**Status:** 📋 DESIGN DOCUMENT (Not Yet Implemented)  
**Platform:** iOS (Darwin/Objective-C++)

---

## ⚠️ Important Notice

**This document outlines the PLANNED modifications** for iOS support. The Android engine is currently working and tested. iOS implementation requires:

1. Building a custom iOS Flutter engine
2. Understanding iOS/Apple security restrictions
3. Testing on physical iOS devices
4. App Store submission considerations

---

## iOS vs Android Differences

### Key Challenges

| Aspect | Android | iOS |
|--------|---------|-----|
| **Code Signing** | Flexible | Strict (requires re-signing) |
| **File System** | Open access to /data | Sandboxed (Container/Documents) |
| **Dynamic Loading** | `dlopen()` works freely | Restricted (App Review guidelines) |
| **AOT Library** | `libapp.so` (ELF) | `App.framework/App` (Mach-O) |
| **Patch Storage** | `/data/data/<app>/code_cache` | `Library/Caches/` or `Documents/` |
| **Language** | Java + JNI | Objective-C/Swift + C++ |

### Apple Restrictions

⚠️ **Critical Limitations:**

1. **Code Signing Required** - Any modified binary must be signed with valid provisioning profile
2. **App Review Risk** - Dynamically loading code may violate App Store guidelines (§3.3.2)
3. **No JIT on iOS** - Only AOT compilation allowed (already the case for Flutter)
4. **Sandbox Restrictions** - Limited file system access

**Recommendation:** Use TestFlight for beta testing patches before submitting to App Store.

---

## Proposed Architecture

### File Structure (iOS)

```
iOS App.app/
├── Frameworks/
│   ├── Flutter.framework/
│   │   └── Flutter          # Flutter engine binary
│   └── App.framework/
│       └── App              # Original AOT snapshot (Mach-O)
└── Library/                  # App's data directory
    └── Caches/
        └── quicui_patches/
            ├── App_patched_arm64  # Patched AOT (Mach-O)
            └── metadata.json      # Patch metadata
```

### Modified Files (Proposed)

```
flutter/shell/platform/darwin/ios/framework/Source/
├── FlutterEngine.mm                    # Modified (add patch detection)
├── FlutterDartProject.mm               # Modified (add patch path property)
└── QuicUICodePushLoader.mm            # New (Objective-C patch loader)

flutter/shell/common/
├── quicui_patch_loader.h               # Existing (cross-platform)
└── quicui_patch_loader.cc              # Existing (cross-platform)
```

**Note:** The C++ `quicui_patch_loader` is already cross-platform and will work on iOS without changes.

---

## Implementation Plan

### 1. Create QuicUICodePushLoader (Objective-C)

**File:** `flutter/shell/platform/darwin/ios/framework/Source/QuicUICodePushLoader.mm`

```objc
// QuicUICodePushLoader.mm
#import <Foundation/Foundation.h>
#include "flutter/shell/common/quicui_patch_loader.h"

@interface QuicUICodePushLoader : NSObject

- (instancetype)initWithCacheDirectory:(NSString*)cacheDir;
- (NSString*)getPatchedAOTPath;
- (BOOL)clearPatch;
- (NSDictionary*)getPatchInfo;

@end

@implementation QuicUICodePushLoader {
  flutter::QuicUIPatchLoader* _patchLoader;
  NSString* _cacheDirectory;
  NSString* _architecture;
}

- (instancetype)initWithCacheDirectory:(NSString*)cacheDir {
  self = [super init];
  if (self) {
    _cacheDirectory = cacheDir;
    _architecture = [self detectArchitecture];
    _patchLoader = new flutter::QuicUIPatchLoader();
    _patchLoader->SetCodeCacheDir([cacheDir UTF8String]);
    
    NSLog(@"[QuicUI] Initialized");
    NSLog(@"[QuicUI] Cache dir: %@", cacheDir);
    NSLog(@"[QuicUI] Architecture: %@", _architecture);
  }
  return self;
}

- (void)dealloc {
  delete _patchLoader;
}

- (NSString*)detectArchitecture {
#if TARGET_CPU_ARM64
  return @"arm64";
#elif TARGET_CPU_ARM
  return @"armv7";
#elif TARGET_CPU_X86_64
  return @"x86_64";
#else
  return @"unknown";
#endif
}

- (NSString*)getPatchedAOTPath {
  @try {
    NSLog(@"[QuicUI] Checking for patches via C++...");
    
    std::string patchPath = _patchLoader->GetPatchedAOTPath([_architecture UTF8String]);
    
    if (!patchPath.empty()) {
      NSString* nsPath = [NSString stringWithUTF8String:patchPath.c_str()];
      
      // Verify file exists
      if ([[NSFileManager defaultManager] fileExistsAtPath:nsPath]) {
        NSLog(@"[QuicUI] ✅ Found valid patch at: %@", nsPath);
        
        NSDictionary* attrs = [[NSFileManager defaultManager] 
                               attributesOfItemAtPath:nsPath error:nil];
        NSLog(@"[QuicUI] Patch size: %@ bytes", attrs[NSFileSize]);
        
        return nsPath;
      } else {
        NSLog(@"[QuicUI] C++ returned path but file doesn't exist: %@", nsPath);
        return nil;
      }
    } else {
      NSLog(@"[QuicUI] No patch found (C++ returned empty string)");
      return nil;
    }
  } @catch (NSException* exception) {
    NSLog(@"[QuicUI] Error getting patched AOT path: %@", exception);
    return nil;
  }
}

- (BOOL)clearPatch {
  @try {
    NSLog(@"[QuicUI] Clearing patches via C++...");
    bool success = _patchLoader->ClearInstalledPatch();
    
    if (success) {
      NSLog(@"[QuicUI] ✅ Patches cleared successfully");
    } else {
      NSLog(@"[QuicUI] Failed to clear patches");
    }
    
    return success;
  } @catch (NSException* exception) {
    NSLog(@"[QuicUI] Error clearing patches: %@", exception);
    return NO;
  }
}

- (NSDictionary*)getPatchInfo {
  @try {
    std::string infoJSON = _patchLoader->GetPatchInfoJSON();
    
    if (!infoJSON.empty()) {
      NSString* jsonString = [NSString stringWithUTF8String:infoJSON.c_str()];
      NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
      NSDictionary* info = [NSJSONSerialization JSONObjectWithData:jsonData 
                                                           options:0 
                                                             error:nil];
      return info;
    }
    
    return nil;
  } @catch (NSException* exception) {
    NSLog(@"[QuicUI] Error getting patch info: %@", exception);
    return nil;
  }
}

@end
```

---

### 2. Modify FlutterDartProject.mm

**File:** `flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject.mm`

**Add Property:**

```objc
@interface FlutterDartProject ()
@property(nonatomic, readonly, nonnull) NSBundle* flutterBundle;
@property(nonatomic, readonly, nonnull) NSString* flutterAssetsName;
@property(nonatomic, readonly, nonnull) NSString* assetsPath;
@property(nonatomic, readonly, nonnull) NSString* ICUDataPath;

// NEW: Add patch-related properties
@property(nonatomic, strong, nullable) NSString* patchedAOTPath;  // NEW

@end
```

**Add Method:**

```objc
- (void)checkForCodePushPatches {
  // Get cache directory
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, 
                                                       NSUserDomainMask, 
                                                       YES);
  NSString* cacheDir = [paths firstObject];
  
  if (!cacheDir) {
    NSLog(@"[QuicUI] Failed to get cache directory");
    return;
  }
  
  // Create QuicUI patch loader
  QuicUICodePushLoader* loader = [[QuicUICodePushLoader alloc] 
                                   initWithCacheDirectory:cacheDir];
  
  // Check for patched AOT
  NSString* patchedPath = [loader getPatchedAOTPath];
  
  if (patchedPath) {
    self.patchedAOTPath = patchedPath;
    NSLog(@"[QuicUI] Will use patched AOT: %@", patchedPath);
  } else {
    NSLog(@"[QuicUI] No patch found, using original AOT from bundle");
  }
}
```

---

### 3. Modify FlutterEngine.mm

**File:** `flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine.mm`

**Locate:** The method where `FlutterProjectArgs` is configured (usually in `runWithEntrypoint:`)

**Add Patch Detection:**

```objc
- (BOOL)runWithEntrypoint:(NSString*)entrypoint {
  // ... existing code ...
  
  // QuicUI Code Push: Check for patches
  [self.dartProject checkForCodePushPatches];
  
  FlutterProjectArgs args = {};
  args.struct_size = sizeof(FlutterProjectArgs);
  args.assets_path = [self.dartProject.assetsPath UTF8String];
  args.icu_data_path = [self.dartProject.ICUDataPath UTF8String];
  
  // QuicUI: Use patched AOT if available
  NSString* aotPath = self.dartProject.patchedAOTPath;
  if (!aotPath) {
    // Use original from bundle
    NSString* bundlePath = [[NSBundle mainBundle] pathForResource:@"App" 
                                                           ofType:@"framework"];
    aotPath = [bundlePath stringByAppendingPathComponent:@"App"];
  }
  
  args.vm_snapshot_data = [aotPath UTF8String];  // Mach-O path
  
  // ... rest of initialization ...
}
```

---

## Build Configuration

### GN Build File Changes

**File:** `flutter/shell/platform/darwin/ios/framework/BUILD.gn`

```python
# Add QuicUICodePushLoader to sources
ios_objc_library("flutter_framework_source") {
  sources = [
    # ... existing sources ...
    "Source/QuicUICodePushLoader.mm",  # NEW
  ]
  
  deps = [
    # ... existing deps ...
    "//flutter/shell/common:quicui_patch_loader",  # NEW
  ]
  
  # ... rest of config ...
}
```

### Build Commands

```bash
# Navigate to engine source
cd /path/to/flutter/engine/src

# Build iOS engine (arm64 device)
ninja -C out/ios_release

# Build iOS simulator engine (x86_64/arm64 sim)
ninja -C out/ios_debug_sim_unopt
```

**Output:**
- `out/ios_release/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter`
- Contains QuicUI patch loader integrated into engine

---

## iOS-Specific Considerations

### 1. Code Signing

**Problem:** Modified AOT binary must be signed

**Solution Options:**

**A. Development/TestFlight (Recommended):**
```bash
# After patch is downloaded, re-sign it
codesign -f -s "iPhone Developer" \
  ~/Library/Caches/quicui_patches/App_patched_arm64
```

**B. Embed in App Bundle (Not Dynamic):**
- Pre-sign patches during build
- Include in app bundle (defeats purpose of OTA updates)

**C. Use TestFlight:**
- Patches delivered via TestFlight
- Apple signs the updated binary
- Safer for App Store review

### 2. File Paths

**iOS Sandbox Structure:**
```
App.app/                           # Bundle (read-only)
├── App                            # Main executable
└── Frameworks/
    └── App.framework/App          # Original AOT snapshot

~/Library/Caches/                  # Cache directory (writable)
└── quicui_patches/
    ├── App_patched_arm64          # Patched AOT
    └── metadata.json

~/Documents/                       # Documents directory (writable, backed up)
└── (alternative patch storage)
```

**Get Cache Directory (Objective-C):**
```objc
NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, 
                                                     NSUserDomainMask, 
                                                     YES);
NSString* cacheDir = [paths firstObject];
// Result: /var/mobile/Containers/Data/Application/<UUID>/Library/Caches
```

### 3. Mach-O vs ELF

**Android:** `libapp.so` is ELF format  
**iOS:** `App` binary is Mach-O format

**Difference:** Patch generation must use Mach-O aware diff tool:
- BsDiff works on binary level (format-agnostic) ✅
- Hash calculation works the same ✅
- No changes needed to patch generation ✅

### 4. App Store Review

⚠️ **Risk Assessment:**

**Apple Guidelines §3.3.2:**
> "An app may not download or install executable code. Interpreted code may be downloaded to an Application but only so long as such code: (a) does not change the primary purpose of the Application..."

**QuicUI Approach:**
- AOT snapshot is **not interpreted code** (it's pre-compiled)
- Similar to React Native's CodePush (approved by Apple)
- Update only UI/business logic, not engine
- Must not change "primary purpose" of app

**Mitigation:**
1. Use TestFlight for beta distribution
2. Document patch system in App Review notes
3. Limit patches to bug fixes and UI updates (not major features)
4. Consider Enterprise distribution if targeting internal apps

---

## Testing Plan

### Phase 1: Engine Build
- [ ] Build custom iOS engine with QuicUI modifications
- [ ] Verify Flutter.framework includes QuicUICodePushLoader
- [ ] Test on iOS simulator

### Phase 2: Integration
- [ ] Create iOS test app with custom engine
- [ ] Verify app launches with original AOT
- [ ] Test patch detection logic

### Phase 3: Patch Generation
- [ ] Generate BsDiff patch for iOS (Mach-O)
- [ ] Verify patch format and compression
- [ ] Test patch upload to Supabase

### Phase 4: Patch Installation
- [ ] Implement iOS client for patch download
- [ ] Test patch installation to cache directory
- [ ] Verify file permissions and code signing

### Phase 5: Runtime Loading
- [ ] Restart app and check for patch detection
- [ ] Verify patched AOT loads successfully
- [ ] Confirm visual changes appear

### Phase 6: TestFlight Distribution
- [ ] Submit to TestFlight with patch system
- [ ] Test OTA updates with beta testers
- [ ] Monitor for crashes or issues

---

## Code Signing Strategy

### Development Signing

```bash
# After patch download, sign with development certificate
PATCH_PATH="~/Library/Caches/quicui_patches/App_patched_arm64"

codesign -f -s "iPhone Developer: Your Name (XXXXXXXXXX)" \
  --entitlements App.entitlements \
  "$PATCH_PATH"

# Verify signature
codesign -dvvv "$PATCH_PATH"
```

### Automated Signing (CI/CD)

```yaml
# Example GitHub Actions workflow
- name: Sign iOS Patch
  run: |
    security import-certificate -k ~/Library/Keychains/login.keychain \
      -P $CERT_PASSWORD -T /usr/bin/codesign certificates.p12
    
    codesign -f -s "iPhone Distribution" \
      --entitlements App.entitlements \
      patches/App_patched_arm64
```

---

## Comparison: Android vs iOS Implementation

| Component | Android | iOS |
|-----------|---------|-----|
| **Language** | Java + JNI | Objective-C + C++ |
| **Patch Loader** | `QuicUICodePushLoader.java` | `QuicUICodePushLoader.mm` |
| **Entry Point** | `FlutterLoader.java` | `FlutterEngine.mm` |
| **C++ Loader** | Same (`quicui_patch_loader.cc`) | Same |
| **AOT Format** | ELF (`libapp.so`) | Mach-O (`App`) |
| **Storage** | `/data/data/<app>/code_cache` | `~/Library/Caches/` |
| **Signing** | Optional | **Required** |
| **App Store** | Google Play (flexible) | App Store (strict) |

**Commonality:** The core C++ `QuicUIPatchLoader` class is **identical** across platforms. Only the Objective-C wrapper needs to be written.

---

## Next Steps

### Immediate (Before Implementation)

1. **Research Code Signing:**
   - Understand iOS code signing requirements
   - Test signing modified binaries locally
   - Verify signature doesn't break on device

2. **Build iOS Engine:**
   - Set up iOS engine build environment
   - Build Flutter.framework for arm64
   - Test custom engine with example app

3. **Study Shorebird iOS:**
   - Review how Shorebird handles iOS patches
   - Check their App Store approval strategy
   - Learn from their implementation

### Implementation Phase

1. **Create QuicUICodePushLoader.mm** (Objective-C wrapper)
2. **Modify FlutterDartProject.mm** (add patch path property)
3. **Modify FlutterEngine.mm** (patch detection on launch)
4. **Update BUILD.gn** (add new sources)
5. **Build and test** on iOS simulator
6. **Test on physical device** with development signing

### Testing Phase

1. **Unit tests** for QuicUICodePushLoader
2. **Integration tests** with test app
3. **End-to-end tests** with real patches
4. **TestFlight beta** with real users
5. **App Store submission** (after thorough testing)

---

## Risk Mitigation

### Technical Risks

| Risk | Mitigation |
|------|------------|
| Code signing breaks patch | Test signing thoroughly, automate in CI/CD |
| Mach-O format issues | Use format-agnostic BsDiff, verify with otool |
| Sandbox restrictions | Use proper iOS APIs for file access |
| Performance impact | Benchmark startup time with/without patches |

### Business Risks

| Risk | Mitigation |
|------|------------|
| App Store rejection | Start with TestFlight, document clearly |
| User data loss | Implement rollback, test extensively |
| Security concerns | Add signature verification, use HTTPS |
| Support burden | Create comprehensive documentation |

---

## Documentation Required

Before implementing iOS support, create:

1. **iOS Build Guide** - Step-by-step engine build instructions
2. **Code Signing Guide** - How to sign patches for different environments
3. **TestFlight Guide** - Beta distribution with patches
4. **App Store Guide** - Submission notes and guidelines
5. **Troubleshooting Guide** - Common iOS-specific issues

---

## Estimated Effort

**Implementation:** 2-3 weeks  
**Testing:** 1-2 weeks  
**Documentation:** 1 week  
**Total:** 4-6 weeks

**Breakdown:**
- Week 1-2: Engine modifications and build
- Week 3: iOS client integration
- Week 4: End-to-end testing
- Week 5-6: TestFlight beta and refinement

---

## Conclusion

iOS support for QuicUI code push is **technically feasible** using the same C++ core as Android. The main challenges are:

1. ✅ **Technical:** Solvable with Objective-C wrapper and proper code signing
2. ⚠️ **App Store:** Requires careful approach and TestFlight testing
3. ✅ **Architecture:** Reuses existing C++ patch loader (90% code reuse)

**Recommendation:**
- Start with TestFlight distribution to validate approach
- Document system thoroughly for App Review
- Limit initial patches to bug fixes/UI updates
- Consider Enterprise distribution for high-risk apps

**Current Status:**
- ✅ Android implementation complete and tested
- 📋 iOS design documented (this document)
- ⏳ iOS implementation pending

---

**Document By:** GitHub Copilot  
**Date:** November 25, 2025  
**Status:** 📋 DESIGN PROPOSAL (Not Yet Built)
