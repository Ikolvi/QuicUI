# Engine Patch Loading Fix - Implementation Guide

## Problem
Custom QuicUI engine at `/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1` does not load .vmcode patches on iOS.

## Solution: Modify FlutterDartProject.mm

### File Location
```
/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject.mm
```

### Implementation

Add this code after line ~100, where `settings.application_library_paths` is first populated:

```objectivec++
// ========== QuicUI Patch Loading for iOS ==========
// Check for patches in the cache directory and load if available
NSString* cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
if (cachePath) {
  NSString* patchStatePath = [cachePath stringByAppendingPathComponent:@"patches/patches_state.json"];
  
  if ([[NSFileManager defaultManager] fileExistsAtPath:patchStatePath]) {
    NSLog(@"[QuicUI] Found patches_state.json at: %@", patchStatePath);
    
    NSError* jsonError = nil;
    NSData* jsonData = [NSData dataWithContentsOfFile:patchStatePath];
    NSDictionary* patchState = [NSJSONSerialization JSONObjectWithData:jsonData 
                                                               options:0 
                                                                 error:&jsonError];
    
    if (patchState && !jsonError) {
      // Get patch ID from state file
      id patchNumber = patchState[@"number"];
      NSString* patchId = nil;
      
      if ([patchNumber isKindOfClass:[NSNumber class]]) {
        patchId = [patchNumber stringValue];
      } else if ([patchNumber isKindOfClass:[NSString class]]) {
        patchId = patchNumber;
      }
      
      if (patchId) {
        NSString* patchPath = [cachePath stringByAppendingPathComponent:
          [NSString stringWithFormat:@"patches/%@/dlc.vmcode", patchId]];
        
        // Verify patch file exists
        if ([[NSFileManager defaultManager] fileExistsAtPath:patchPath]) {
          NSLog(@"[QuicUI] Found patch file at: %@", patchPath);
          
          // Get file size for logging
          NSError* attrError = nil;
          NSDictionary* attrs = [[NSFileManager defaultManager] 
            attributesOfItemAtPath:patchPath error:&attrError];
          
          if (attrs && !attrError) {
            unsigned long long fileSize = [attrs fileSize];
            NSLog(@"[QuicUI] Patch size: %llu bytes (%.2f MB)", 
              fileSize, fileSize / 1024.0 / 1024.0);
          }
          
          // CRITICAL: Insert patch at the BEGINNING of the list
          // This allows the VM to find the patched code first while
          // still having access to base snapshots for VM initialization
          settings.application_library_paths.insert(
            settings.application_library_paths.begin(), 
            patchPath.UTF8String
          );
          
          NSLog(@"[QuicUI] ✅ Patch loaded successfully - ID: %@", patchId);
          NSLog(@"[QuicUI] application_library_paths[0] = %s", 
            settings.application_library_paths[0].c_str());
        } else {
          NSLog(@"[QuicUI] ⚠️ Patch file not found: %@", patchPath);
        }
      } else {
        NSLog(@"[QuicUI] ⚠️ No patch ID found in patches_state.json");
      }
    } else {
      NSLog(@"[QuicUI] ❌ Failed to parse patches_state.json: %@", jsonError);
    }
  } else {
    NSLog(@"[QuicUI] No patches_state.json found - running base AOT");
  }
} else {
  NSLog(@"[QuicUI] ❌ Could not determine cache directory");
}
// ========== End QuicUI Patch Loading ==========
```

## Build Configuration

### Required Build Flags

When building the engine, ensure these flags are set:

```bash
# In your GN build arguments (e.g., out/ios_release/args.gn)

# Enable interpreter mode for iOS
use_interpreter = true

# Or if using Shorebird-style flag:
# shorebird_use_interpreter = true
```

### Rebuild Command

```bash
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src

# Clean previous build
rm -rf out/ios_release

# Configure build
python3 ./flutter/tools/gn --ios --runtime-mode=release --unoptimized

# Build engine
ninja -C out/ios_release
```

## Testing Checklist

### 1. Build Verification
```bash
# After engine rebuild, check that FlutterDartProject.mm was compiled
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src
grep -n "QuicUI Patch Loading" out/ios_release/Flutter.framework/Headers/*.h
# Should show the engine was built with patch loading support
```

### 2. App Rebuild
```bash
cd /Users/admin/Documents/quicui2/test_apps/quicui_production_test

# Clean previous builds
rm -rf build/ v3.0.54/ v3.0.55/ patches/

# Build base version (v3.0.54)
dart /Users/admin/Documents/quicui2/packages/quicui_cli/bin/quicui.dart build-ipa \
  --project . \
  --version 3.0.54 \
  --build-number 36

# Build target version (v3.0.55) with visible changes
dart /Users/admin/Documents/quicui2/packages/quicui_cli/bin/quicui.dart build-ipa \
  --project . \
  --version 3.0.55 \
  --build-number 37
```

### 3. Patch Generation
```bash
# Generate patch
dart /Users/admin/Documents/quicui2/packages/quicui_cli/bin/quicui.dart generate-patch \
  --project . \
  --from v3.0.54 \
  --to v3.0.55 \
  -c xz

# Upload patch
dart /Users/admin/Documents/quicui2/packages/quicui_cli/bin/quicui.dart upload-patch \
  --project . \
  --patch <PATCH_ID>
```

### 4. Device Testing
```bash
# Uninstall old app
xcrun devicectl device uninstall app \
  --device 653324F8-D2E4-5A3A-BC77-C7C601AA9433 \
  com.example.quicuiProductionTest

# Install v3.0.54 (base)
xcrun devicectl device install app \
  --device 653324F8-D2E4-5A3A-BC77-C7C601AA9433 \
  build/ios/Release-iphoneos/Runner.app

# Launch with console to see patch loading logs
xcrun devicectl device process launch \
  --device 653324F8-D2E4-5A3A-BC77-C7C601AA9433 \
  --console com.example.quicuiProductionTest
```

### Expected Log Output

```
[QuicUI] Found patches_state.json at: .../patches/patches_state.json
[QuicUI] Found patch file at: .../patches/1764426073097/dlc.vmcode
[QuicUI] Patch size: 4015024 bytes (3.83 MB)
[QuicUI] ✅ Patch loaded successfully - ID: 1764426073097
[QuicUI] application_library_paths[0] = .../patches/1764426073097/dlc.vmcode
```

### Visual Verification
- App should display **purple theme** (ColorScheme.fromSeed(seedColor: Colors.purple))
- Title should show: **"🎨 PURPLE THEME v3.0.55 - PATCH WORKS! 🚀"**
- NOT the base v3.0.54 purple/pink gradient

## Troubleshooting

### Patch File Not Found
```
[QuicUI] ⚠️ Patch file not found: .../dlc.vmcode
```
**Solution**: Check that patch was downloaded and installed by iOS plugin

### Parse Error
```
[QuicUI] ❌ Failed to parse patches_state.json: Error Domain=...
```
**Solution**: Check patches_state.json format matches expected structure

### No Visual Change
If logs show patch loaded but no visual change:
1. Check v3.0.55 was built AFTER code changes
2. Verify patch hash is different from base
3. Check engine interpreter mode is enabled
4. Verify base snapshot is set up correctly

### App Crashes on Launch
If app crashes when loading patch:
1. Check .vmcode file format (should have 65536-byte Shorebird header)
2. Verify patch was generated from correct base version
3. Check engine logs for interpreter errors
4. Try without patch (delete patches_state.json) to isolate issue

## Key Differences from Shorebird

1. **No Updater Library**: QuicUI handles updates in Dart, not native code
2. **Different Path**: Uses `patches/` instead of `shorebird_updater/`
3. **Simpler State**: Only needs patch ID, not full updater state
4. **No Auto-Update**: Update checking happens in Dart layer

## References

- Shorebird Implementation: `shorebird_engine/shell/common/shorebird/shorebird.cc`
- Shorebird iOS Setup: `shorebird_engine/shell/platform/darwin/ios/framework/Source/FlutterDartProject.mm`
- Current Issue: `docs/2025-11-29/PATCH_LOADING_ISSUE_ANALYSIS.md`

## Status: Ready to Implement

This fix is ready to be applied to the custom engine. After rebuild and testing, OTA updates should work correctly on iOS.
