# FlutterEngine.mm Modifications for QuicUI Code Push (iOS)

**This document is for internal reference only - NOT included in engine source.**

## Integration Steps

### 1. Add Import

Add to top of `FlutterEngine.mm` (after existing imports):

```objc
#import "flutter/shell/platform/darwin/ios/framework/Source/QuicUICodePushLoader.h"
```

### 2. Modify Engine Startup

In method `runWithEntrypoint:libraryURI:initialRoute:entrypointArgs:`, add:

```objc
// QuicUI: Check for patched libapp.so
NSString* patchPath = [QuicUICodePushLoader checkAndLoadPatch];

if (patchPath != nil) {
    NSLog(@"[QuicUI] Loading patched AOT from: %@", patchPath);
    [self loadAOTData:patchPath];
} else {
    // Load original AOT
    NSString* assetsPath = [_dartProject assetsPath];
    NSString* appFrameworkPath = [assetsPath stringByDeletingLastPathComponent];
    NSString* aotPath = [appFrameworkPath stringByAppendingPathComponent:@"App.framework/App"];
    [self loadAOTData:aotPath];
}
```

### 3. Build Engine

```bash
cd forks/flutter-quicui
# Follow Flutter engine build instructions
./flutter/tools/gn --ios --unoptimized
ninja -C out/ios_debug_unopt
```

## Files Modified

- `shell/platform/darwin/ios/framework/Source/FlutterEngine.mm` (~20 lines added)
- `shell/platform/darwin/ios/framework/Source/QuicUICodePushLoader.h` (new)
- `shell/platform/darwin/ios/framework/Source/QuicUICodePushLoader.mm` (new)

## Testing

1. Build modified engine
2. Link test app with modified engine
3. Place patch at `NSDocumentDirectory/quicui_patches/libapp.so`
4. Run app
5. Check logs for `[QuicUI]` messages
