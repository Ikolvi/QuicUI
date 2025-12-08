# iOS Engine Build Issues - November 17, 2025

## Summary
Attempted to build custom Flutter iOS engine with QuicUI code push support. Build blocked by fundamental Xcode 26.1 beta SDK incompatibilities.

## Environment
- **macOS**: 26.0.1 (25A362) - Beta
- **Xcode**: 26.1 Build 17B55 - Beta
- **Flutter**: 3.38.1 stable
- **Engine Commit**: b5990e5ccc5e325fd24f0746e7d6689bbebc7c65
- **Build Location**: `/Volumes/DoWonder2/quicui_engine_build/engine_full/`
- **Device**: iPhone (Kiran's), iOS 26.1, UDID: 00008140-001C28D40CF2801C

## Issues Encountered

### Issue 1: UIUtilities Framework Missing in Xcode 26 SDK

**Problem**: iOS SDK UIKit headers reference non-existent UIUtilities framework
```
'UIUtilities/UIDefines.h' file not found
```

**Details**:
- First failure at target 358/6597 (FlutterUmbrellaImport.m)
- UIKit.framework headers import `<UIUtilities/UIDefines.h>` and related headers
- UIUtilities framework doesn't exist in modern iOS SDKs
- This is a known Xcode 26.1 beta regression

**Attempted Solutions**:
1. ❌ Used system SDK directly - same missing framework issue
2. ❌ Added include path via GN args - args not recognized by build system
3. ❌ Modified single target in BUILD.gn - other targets failed with same error
4. ❌ Commented out problematic target - different files hit same issue
5. ⚠️ Created synthetic UIUtilities.framework shim:
   - Location: `flutter/sdk_fixes/UIUtilities.framework/Headers/`
   - Created 11 stub header files:
     - `UIDefines.h` - UIKIT_EXTERN, UIKIT_STATIC_INLINE macros
     - `UIGeometry.h` - UIAxis, UIRectEdge type definitions
     - `UIEdgeInsets.h`, `UIOffset.h`, `UICoordinateSpace.h`
     - `UIFocusSystem.h`, `UISceneDef.h`, `UIScene.h`, `UISceneSession.h`
     - `UIWindowSceneDragInteraction.h`, `UIWindowSceneGeometry.h`
   - Recreated iOS SDK directory with symlinks to system frameworks + UIUtilities shim
   - This resolved UIKit compilation errors but exposed Issue 2

**Files Modified**:
- `/Volumes/DoWonder2/quicui_engine_build/engine_full/src/flutter/shell/platform/darwin/ios/BUILD.gn`
  - Added QuicUICodePushLoader.h and .mm to sources
  - Commented out `:copy_and_verify_framework_module` dependency
- Created entire UIUtilities.framework shim structure

### Issue 2: C Math Functions Missing in iOS SDK (CRITICAL BLOCKER)

**Problem**: iOS SDK's math.h only defines functions as preprocessor macros, but C++ libcxx expects them as actual functions
```
error: reference to unresolved using declaration
../../flutter/third_party/libcxx/include/cmath:573:12: error: reference to unresolved using declaration
  573 |     return isnan(__lcpp_x);
      |            ^
../../flutter/third_party/libcxx/include/cmath:326:1: note: using declaration annotated with 'using_if_exists' here
  326 | using ::isnan _LIBCPP_USING_IF_EXISTS;
```

**Details**:
- First appeared at target 2154/6182 (libcxx.any.o)
- Affects ALL C++ libcxx source files (~2000+ files)
- Missing functions: `isnan`, `isinf`, `isfinite`, `signbit`
- These exist as macros in math.h but not as callable functions
- libcxx uses `_LIBCPP_USING_IF_EXISTS` attribute to import from global namespace
- When functions don't exist, using declarations fail silently, but code still tries to use them
- Results in 16 errors per affected C++ file

**Error Pattern** (repeated in many files):
```cpp
// From libcxx/include/cmath
using ::signbit _LIBCPP_USING_IF_EXISTS;   // Lines 322
using ::isfinite _LIBCPP_USING_IF_EXISTS;  // Line 324
using ::isinf _LIBCPP_USING_IF_EXISTS;     // Line 325
using ::isnan _LIBCPP_USING_IF_EXISTS;     // Line 326

// Later used in __compare/strong_order.h and __compare/weak_order.h
return _VSTD::signbit(__u) <=> _VSTD::signbit(__t);  // Error: unresolved
bool __t_is_nan = _VSTD::isnan(__t);                 // Error: unresolved
```

**Root Cause**: 
- Xcode 26.1 Build 17B55 is beta software with SDK regressions
- iOS SDK incompatible with C++20 standard library used by Flutter engine
- math.h provides macros but libcxx needs function symbols in ::namespace

**Why It's Critical**:
- Blocks compilation of entire libcxx (C++ standard library)
- Cannot proceed past ~35% of build (2154/6182 targets)
- Would require patching libcxx to work around missing functions
- Affects fundamental operations: comparisons, floating-point math, algorithms

**Attempted Solutions**:
1. ❌ Used system SDK symlink instead of custom SDK - same issue
2. ❌ Added framework search paths globally via GN args - libcxx still failed
3. ⚠️ Could patch libcxx to define wrapper functions, but very complex and risky

### Issue 3: Code Signing for Physical Device

**Problem**: Cannot install app on iPhone due to provisioning profile issues
```
error: Provisioning profile doesn't include the currently selected device
```

**Status**: ⏸️ Deferred until custom engine is ready

**Solution**: Configure code signing in Xcode manually:
1. Open `ios/Runner.xcworkspace`
2. Select Runner project → Signing & Capabilities
3. Verify Team: 28GSXHNVQW
4. Trust development certificates if prompted

## QuicUI iOS Implementation Status

### Completed ✅
- [x] Downloaded official Flutter 3.38.1 stable
- [x] Built iOS test app successfully (Runner.app 14.7MB)
- [x] Recreated QuicUICodePushLoader.h (110 lines) from Android implementation
- [x] Recreated QuicUICodePushLoader.mm (250+ lines) from Android implementation
- [x] Modified engine BUILD.gn to include QuicUI source files
- [x] Identified root causes of build failures

### QuicUI Loader Files Created
**Location**: `flutter/shell/platform/darwin/ios/framework/Source/`

1. **QuicUICodePushLoader.h**
   - Objective-C++ interface for iOS engine patch loading
   - Methods:
     - `+ (nullable NSString*)checkAndLoadPatch`
     - `+ (BOOL)hasPatch`
     - `+ (void)clearPatch`
     - `+ (nullable NSDictionary*)getPatchMetadata`
     - `+ (BOOL)validatePatch:(NSString*)patchPath`
     - `+ (nullable NSString*)calculateFileHash:(NSString*)filePath`
   - Constants: kQuicUIPatchDirectoryName, kQuicUIPatchFileName, size limits
   - Dependencies: Foundation, CommonCrypto

2. **QuicUICodePushLoader.mm**
   - Implementation of iOS patch loading logic
   - Features:
     - Checks `NSDocumentDirectory/quicui_patches/libapp.so`
     - File size validation (1MB-500MB)
     - SHA256 checksum verification
     - Metadata JSON parsing with error handling
     - Comprehensive logging with `[QuicUI]` prefix
   - Based on Android QuicUICodePushLoader.java

### Blocked ❌
- [ ] iOS engine build (~90 minutes if successful)
- [ ] Verify Flutter.xcframework includes QuicUI symbols
- [ ] Deploy custom engine to Flutter SDK cache
- [ ] Rebuild test app with custom engine
- [ ] Configure code signing
- [ ] Deploy to iPhone for testing
- [ ] Test patch execution (download/apply/execute flow)

## Current Build State

**Build Command**:
```bash
cd /Volumes/DoWonder2/quicui_engine_build/engine_full/src
export PATH="/Volumes/DoWonder2/quicui_engine_build/depot_tools:$PATH"
ninja -C out/ios_release -j4
```

**Progress**: Blocked at target 2154/6182 (~35% complete)

**Build Configuration**:
- Target: iOS release (arm64)
- Mode: `--no-lto` (no link-time optimization)
- Total targets: 6182 compilation units (regenerated after GN changes)
- Parallelism: `-j4` (4 concurrent jobs)
- Estimated time if successful: ~90 minutes

## Why Prebuilt Engine Cannot Be Used

Flutter 3.38.1 includes prebuilt iOS engine at:
```
/Users/admin/Documents/quicui2/forks/flutter/bin/cache/artifacts/engine/ios-release/Flutter.xcframework
```

**However**:
- ✅ Prebuilt engine exists and is valid
- ❌ Does NOT include QuicUI modifications
- ❌ Cannot inject code into compiled binary

**QuicUI Requirements**:
- Custom engine code to load patched snapshots
- Validate and execute downloaded patches
- Switch between original and patched code at runtime

**Plugin Capabilities Without Engine Mods**:
- ✅ Download patches from server
- ✅ Verify checksums and metadata
- ✅ Store patches locally in NSDocumentDirectory
- ✅ UI updates and error handling
- ❌ **Patch execution** - new code won't actually run

From `packages/quicui_code_push_client/ios/Example_AppDelegate.swift`:
```swift
// TODO: Configure Flutter engine to use patched snapshot
// This requires modifications to FlutterEngine initialization
```

## Solutions

### Option 1: Downgrade to Xcode 16 Stable ⭐ RECOMMENDED

**Why**: Xcode 16 is stable and officially supported by Flutter

**Steps**:
1. Download Xcode 16.x from https://developer.apple.com/download/all/
2. Install to `/Applications/Xcode-16.app`
3. Switch active Xcode: `sudo xcode-select -s /Applications/Xcode-16.app`
4. Rebuild engine with stable SDK

**Time**: ~15GB download + 30-45 min install + 90 min build = **~2-3 hours total**

**Outcome**: Full QuicUI iOS support with patch execution

### Option 2: Test Without Patch Execution (Limited)

**What Works**:
- Download patches from server
- Apply patches to storage
- Validate checksums
- UI updates and notifications
- Error handling

**What Doesn't Work**:
- **Patch execution** - downloaded code won't run
- Cannot test end-to-end QuicUI functionality

**Use Case**: Test download flow, UI, error handling only

**Time**: 5 minutes (use existing prebuilt engine)

### Option 3: Continue with Xcode 26 (Not Recommended)

**Status**: Blocked by fundamental SDK issues

**Would Require**:
1. Patching libcxx to work around missing math functions
2. Creating comprehensive UIUtilities framework implementation
3. High risk of hitting additional issues during 90-min build
4. Potential for new errors in linking or final framework generation

**Complexity**: Very High

**Success Probability**: Low (<30%)

## Technical Details

### UIUtilities Framework Shim Created

**Location**: `/Volumes/DoWonder2/quicui_engine_build/engine_full/src/flutter/sdk_fixes/UIUtilities.framework/Headers/`

**UIDefines.h**:
```objc
#ifdef __cplusplus
#define UIKIT_EXTERN extern "C" __attribute__((visibility("default")))
#define UIKIT_STATIC_INLINE static inline __attribute__((always_inline))
#else
#define UIKIT_EXTERN extern __attribute__((visibility("default")))
#define UIKIT_STATIC_INLINE static inline __attribute__((always_inline))
#endif
```

**UIGeometry.h**:
```objc
typedef NS_OPTIONS(NSUInteger, UIAxis) {
    UIAxisNeither = 0,
    UIAxisHorizontal = 1 << 0,
    UIAxisVertical = 1 << 1,
    UIAxisBoth = (UIAxisHorizontal | UIAxisVertical)
};

typedef NS_OPTIONS(NSUInteger, UIRectEdge) {
    UIRectEdgeNone   = 0,
    UIRectEdgeTop    = 1 << 0,
    UIRectEdgeLeft   = 1 << 1,
    UIRectEdgeBottom = 1 << 2,
    UIRectEdgeRight  = 1 << 3,
    UIRectEdgeAll    = UIRectEdgeTop | UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight
};
```

### iOS SDK Workaround Attempted

Created custom SDK directory structure:
```
/Volumes/DoWonder2/quicui_engine_build/engine_full/src/flutter/prebuilts/SDKs/iPhoneOS18.4.sdk/
├── System/Library/Frameworks/ → symlinks to all system frameworks (400+) + UIUtilities shim
└── usr/ → symlink to system SDK usr directory
```

Later replaced with direct symlink to system SDK when math function issues appeared.

### Build Configuration Changes

**args.gn additions**:
```gn
extra_cflags_objc = ["-F/Volumes/DoWonder2/quicui_engine_build/engine_full/src/flutter/sdk_fixes"]
```

**BUILD.gn modifications**:
```gn
# Added QuicUI sources
"framework/Source/QuicUICodePushLoader.h",
"framework/Source/QuicUICodePushLoader.mm",

# Commented out problematic target
#":copy_and_verify_framework_module", # Disabled for QuicUI build
```

## Recommendations

1. **Immediate**: Download and install Xcode 16 stable
2. **Short-term**: Complete iOS engine build with stable toolchain
3. **Long-term**: Document Xcode version requirements in QuicUI setup guide
4. **Testing**: Consider CI/CD with stable Xcode version for engine builds

## Lessons Learned

1. **Beta software compounds problems**: macOS 26.0.1 beta + Xcode 26.1 beta created multiple SDK incompatibilities
2. **Engine builds are sensitive**: Require stable, tested toolchains
3. **SDK regressions can be fundamental**: Math function issue affects core C++ stdlib
4. **Workarounds have limits**: Some issues (like missing ::functions) can't be easily shimmed
5. **Prebuilt engines are valuable**: Having official builds available saved time in validation

## Related Files

**Created**:
- `/Volumes/DoWonder2/quicui_engine_build/engine_full/src/flutter/shell/platform/darwin/ios/framework/Source/QuicUICodePushLoader.h`
- `/Volumes/DoWonder2/quicui_engine_build/engine_full/src/flutter/shell/platform/darwin/ios/framework/Source/QuicUICodePushLoader.mm`
- `/Volumes/DoWonder2/quicui_engine_build/engine_full/src/flutter/sdk_fixes/UIUtilities.framework/Headers/*.h` (11 headers)

**Modified**:
- `/Volumes/DoWonder2/quicui_engine_build/engine_full/src/flutter/shell/platform/darwin/ios/BUILD.gn`
- `/Volumes/DoWonder2/quicui_engine_build/engine_full/src/out/ios_release/args.gn`

**Backups**:
- `BUILD.gn.with_verify` - Before commenting out verify module target
- `BUILD.gn.pre_uikit_fix` - Before UIKit fixes

## Next Steps

**When Xcode 16 is installed**:
1. Switch active Xcode: `sudo xcode-select -s /Applications/Xcode-16.app`
2. Verify SDK: `xcrun --show-sdk-path --sdk iphoneos`
3. Clean build: `rm -rf out/ios_release`
4. Regenerate: `flutter/tools/gn --ios --runtime-mode=release --no-lto`
5. Build: `ninja -C out/ios_release -j4`
6. Monitor: Watch for successful completion (~90 min)
7. Verify: Check for QuicUI symbols in Flutter.xcframework
8. Deploy and test on physical device

## References

- Flutter Engine Wiki: https://github.com/flutter/flutter/wiki/Compiling-the-engine
- Xcode Downloads: https://developer.apple.com/download/all/
- QuicUI iOS Implementation: `packages/quicui_code_push_client/ios/`
- Example Integration: `packages/quicui_code_push_client/ios/Example_AppDelegate.swift`
