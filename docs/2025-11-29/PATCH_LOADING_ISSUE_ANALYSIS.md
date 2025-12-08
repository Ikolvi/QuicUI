# QuicUI Patch Loading Issue - 2025-11-29

## Current Status: PATCH NOT LOADING

### Problem Summary
The OTA patch system successfully downloads and installs patches on the device, but the **engine does not load them**. The app continues running the base v3.0.54 code instead of the patched v3.0.55 code.

## Evidence

### What Works ✅
1. **Patch Generation**: Successfully generates .vmcode patches with correct hash
   - Patch ID: 1764426073097
   - Hash: `f9beb6aa6192de5b3663a37266b0e091de53efe0cf4ce5b23f48172f8766669b`
   - Size: 3.83 MB uncompressed, 1.09 MB compressed (XZ)

2. **Patch Download**: App successfully downloads patch from Supabase

3. **Patch Installation**: iOS plugin successfully installs patch to cache directory
   - Location: `/var/mobile/Containers/Data/Application/.../Library/Caches/patches/1764426073097/dlc.vmcode`
   - State file: `patches_state.json` created correctly

### What Doesn't Work ❌
1. **Patch Loading**: Engine finds the patch file but **does not use it**
2. **Visual Changes**: App shows base v3.0.54 UI (purple/pink gradient from v3.0.53) instead of v3.0.55 purple theme
3. **Code Execution**: Patched Dart code never executes

## Device Logs Analysis

### From `/Users/admin/Documents/quicui2/logs/logs.txt` (19:56:44)

```
[QuicUI] Found valid patch at: .../patches/1764426073097/dlc.vmcode
[QuicUI] Patch version: 1764426073097
[QuicUI] Patch size: 4015024 bytes (3.83 MB)
[QuicUI] Instance #2: Patch file extension: vmcode
```

**Key observation**: Logs show patch was found but **no indication it was loaded into the VM**.

## Root Cause Analysis

### Comparison with Shorebird Implementation

Analyzed Shorebird engine code at:
- `shorebird_engine/shell/common/shorebird/shorebird.cc`
- `shorebird_engine/shell/platform/darwin/ios/framework/Source/FlutterDartProject.mm`

**Critical difference found in `shorebird.cc` lines 241-250:**

```cpp
#if SHOREBIRD_USE_INTERPRETER
    // On iOS we add the patch to the front of the list instead of clearing
    // the list, to allow dart_snapshot.cc to still find the base snapshot
    // for the vm isolate.
    settings.application_library_path.insert(
        settings.application_library_path.begin(), active_path);
#else
    settings.application_library_path.clear();
    settings.application_library_path.emplace_back(active_path);
#endif
```

**Shorebird also:**
1. Calls `SetBaseSnapshot(settings)` to provide base snapshots for interpreter
2. Uses `SHOREBIRD_USE_INTERPRETER` flag for iOS builds
3. Inserts patch path at the **beginning** of `application_library_paths`

### QuicUI Engine Issue

**Custom Engine Path**: `/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1`

**Problem**: This custom engine build **does not have patch loading logic** integrated into:
- `shell/platform/darwin/ios/framework/Source/FlutterDartProject.mm`

The engine needs to:
1. Check for `patches_state.json` in the cache directory
2. Read the patch ID and construct the path
3. **Insert the patch path at the beginning of `application_library_paths`**
4. Set up base snapshot for interpreter mode

## Current System State

### Build Configuration
- **Base Version**: v3.0.54 (build 36)
- **Target Version**: v3.0.55 (build 37) with purple theme
- **Engine**: Custom QuicUI build at `/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1`
- **Device**: iPhone (653324F8-D2E4-5A3A-BC77-C7C601AA9433)

### Patch Details
```json
{
  "number": 1764426073097,
  "hash": "f9beb6aa6192de5b3663a37266b0e091de53efe0cf4ce5b23f48172f8766669b",
  "platform": "ios",
  "architecture": "arm64",
  "version": "1764426073097",
  "size": 4015024,
  "requires_restart": true
}
```

### Database State
```sql
-- Supabase patches table
id: 120
patch_id: "1764426073097"
version: "3.0.55"
hash: "f9beb6aa6192de5b3663a37266b0e091de53efe0cf4ce5b23f48172f8766669b"
compressed_sizes: {"xz": 1121892}
created_at: "2025-11-29 14:23:36.743+00"
```

## Required Fix

### Engine Modification Needed

File: `/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject.mm`

Add after line ~100 where `application_library_paths` is set up:

```objectivec++
// QuicUI Patch Loading for iOS
NSString* cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
NSString* patchStatePath = [cachePath stringByAppendingPathComponent:@"patches/patches_state.json"];

if ([[NSFileManager defaultManager] fileExistsAtPath:patchStatePath]) {
  NSData* jsonData = [NSData dataWithContentsOfFile:patchStatePath];
  NSDictionary* patchState = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
  
  if (patchState) {
    NSString* patchId = [patchState[@"number"] stringValue];
    NSString* patchPath = [cachePath stringByAppendingPathComponent:
      [NSString stringWithFormat:@"patches/%@/dlc.vmcode", patchId]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:patchPath]) {
      // Insert patch at the BEGINNING of the list (like Shorebird does)
      settings.application_library_paths.insert(
        settings.application_library_paths.begin(), 
        patchPath.UTF8String
      );
      NSLog(@"[QuicUI] Loaded patch from: %@", patchPath);
    } else {
      NSLog(@"[QuicUI] Patch file not found: %@", patchPath);
    }
  }
}
```

### Build Flags Required
- `SHOREBIRD_USE_INTERPRETER=1` (or QuicUI equivalent)
- Interpreter mode support enabled in engine build

## Timeline of Session

### 19:15 - Initial Testing
- Installed v3.0.54 base app on device
- App had old v3.0.55 patch cached (ID: 1764418666155)

### 19:22 - First Rebuild
- Built v3.0.55 but code changes were made AFTER build
- Patch had old code without UI changes

### 19:35 - Code Changes
- Modified main.dart to add green theme (too late - already built)

### 19:40 - Second Rebuild
- Rebuilt v3.0.55 with green theme
- Generated new patch but hash was identical

### 19:43 - More Visible Changes
- Changed to purple theme with obvious title
- Title: "🎨 PURPLE THEME v3.0.55 - PATCH WORKS! 🚀"

### 19:44 - Third Rebuild
- Rebuilt v3.0.55 with purple theme
- Generated patch successfully with NEW hash

### 19:53 - Device Testing
- Uninstalled and reinstalled app to clear cache
- Downloaded new patch (ID: 1764426073097)
- Patch installed successfully

### 19:56 - Launch & Discovery
- App launched but showed OLD UI (v3.0.53 purple/pink gradient)
- Logs confirmed patch was found but not loaded
- **Root cause identified**: Engine doesn't load patches

## Next Steps

### Immediate (Required)
1. **Rebuild Custom Engine** with patch loading code integrated
   - Add patch detection to FlutterDartProject.mm
   - Insert patch path at beginning of application_library_paths
   - Set up base snapshot for interpreter mode

2. **Test Engine Build**
   - Rebuild test app with new engine
   - Verify patch loading logs appear
   - Confirm purple theme displays

### Future Improvements
1. Add more detailed logging in engine patch loader
2. Add patch validation before loading
3. Implement patch rollback on crash
4. Add metrics for patch load success/failure

## Files Modified During Session

### CLI Fixes
- `packages/quicui_cli/lib/src/commands/generate_patch_command.dart`
  - Fixed path resolution bugs
  - Added output directory creation

- `packages/quicui_cli/lib/src/commands/upload_patch_command.dart`
  - Fixed path normalization

### Test App
- `test_apps/quicui_production_test/lib/main.dart`
  - Changed from Colors.green to Colors.purple
  - Updated title to obvious test text

### Database
- Deleted patches: 118, 119, 1764425116935
- Active patch: 120 (ID: 1764426073097)

## Lessons Learned

1. **Build Timing Critical**: Code changes must be made BEFORE building versions
2. **Small Changes Hard to Verify**: Theme color changes don't significantly alter bytecode, use obvious text changes
3. **Engine Integration Essential**: Patch downloading/installing is only half the solution - engine must load them
4. **Shorebird Analysis Valuable**: Their implementation provides clear pattern to follow
5. **Logging Is Key**: Without detailed engine logs, issue was hard to diagnose

## References

- Shorebird Engine: `shorebird_engine/shell/common/shorebird/`
- QuicUI Patch Loader (docs only): `docs/2025-11-28/engine_files/quicui_patch_loader.cc`
- Device Logs: `logs/logs.txt`
- Supabase Patches Table: ID 120

## Status: BLOCKED ON ENGINE REBUILD

**Cannot proceed with OTA testing until custom engine is rebuilt with patch loading support.**
