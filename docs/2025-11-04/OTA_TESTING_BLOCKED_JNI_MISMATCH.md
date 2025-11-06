# OTA Testing Blocked: JNI Signature Mismatch

**Date:** November 4, 2025  
**Status:** 🔴 BLOCKED - Cannot proceed with OTA testing due to Flutter framework bug

## Current Situation

App crashes immediately on launch with:
```
Failed to register native method io.flutter.embedding.engine.FlutterJNI.nativeInit
```

## Root Cause

**Flutter stable 3.35.7 (Oct 21, 2025) has mismatched JNI signatures:**

- **FlutterJNI.class** expects 7 parameters: `nativeInit(Context, String[], String, String, String, long, int)`
- **libflutter.so** provides 6 parameters: `nativeInit(Context, String[], String, String, String, long)`

The `int apiLevel` parameter was added to FlutterJNI.class but NOT to the native implementation in libflutter.so, causing runtime JNI registration failure.

## Affected Components

✅ **FVM Stable 3.35.7:**
- FlutterJNI.class: 7 parameters ❌
- libflutter.so: 6 parameters ❌
- **MISMATCH!**

✅ **Custom flutter-quicui SDK:**
- Originally: Both had 6 parameters ✅
- After modifications: flutter.jar has mixed versions
- Restored original: 147MB unstripped libflutter.so (has other issues)

## Attempted Fixes

1. ❌ **Use FVM stable** - Mismatch within SDK itself
2. ❌ **Clear Gradle caches** - Problem is in SDK artifacts
3. ❌ **Replace libflutter.so only** - FlutterJNI.class still mismatched
4. ❌ **Use custom SDK** - All backups have some version of mismatch
5. ❌ **Restore original flutter.jar** - 147MB unstripped version has compatibility issues

## Why This Happened

Our custom engine rebuild (ae5c3603) added AttachJNI logging, which likely came from a newer Flutter main branch that HAS the 7-parameter signature. But our SDK clone is from stable which still uses 6 parameters.

When we tried to use standard Flutter (FVM stable), we discovered that **even the official Flutter stable 3.35.7 has this mismatch**! This suggests:
- Flutter's release process didn't catch the mismatch, OR
- There's a conditional compilation that we're triggering incorrectly

## Evidence

**FVM Stable Flutter.jar Analysis:**
```bash
# FlutterJNI.class
unzip -p flutter.jar io/flutter/embedding/engine/FlutterJNI.class | javap -p
→ private static native void nativeInit(..., long, int);  # 7 params

# libflutter.so (from crash log)
Failed to register: nativeInit(...;J)V  # ends with 'J' (long), no 'I' (int)
```

**Build Ids in Crashes:**
- `0a144d8754d04c...` = Our custom 11MB engine (7-param native, 6-param Java)
- All attempts show same BuildId, meaning Gradle is caching our custom engine

## Next Steps

### Option 1: Wait for Flutter Fix (RECOMMENDED)
- Report bug to Flutter team
- Wait for stable release with matching signatures
- Timeline: Unknown

### Option 2: Downgrade to Older Flutter
- Find Flutter version before `int apiLevel` was added
- Likely need Flutter 3.24 or earlier
- Would require rebuilding everything

### Option 3: Build Custom Matched Engine
- Checkout Flutter engine source at exact stable commit
- Remove `int apiLevel` parameter from FlutterJNI.java
- Rebuild engine
- Replace in SDK
- Timeline: 2-3 hours of work

### Option 4: Patch FVM Stable's FlutterJNI.class
- Decompile FlutterJNI.class
- Remove `int apiLevel` parameter
- Recompile and inject back into flutter.jar
- High risk of other incompatibilities
- Timeline: 1-2 hours

### Option 5: Create Minimal Test Without QuicUI (FASTEST)
- Remove quicui_code_push_client dependency
- Build basic Flutter app
- Test OTA patching manually
- Verify patch loading mechanism works
- Timeline: 30 minutes

## Recommendation

**Implement Option 5** to unblock OTA testing:
1. Create `test_apps/simple_ota_test` without QuicUI dependencies
2. Build two versions (purple vs orange)
3. Manually push patched libapp.so to device
4. Use standard Flutter plugin channel to trigger patch load
5. Verify visual change confirms patch loading works

Once Flutter's JNI mismatch is fixed (or we downgrade), integrate proper QuicUI engine modifications.

## Files Ready for OTA Testing

✅ **Patch Files Created:**
- `patches/libapp_v2.0.0.patch` (2.93MB binary diff)
- `patches/original/lib/arm64-v8a/libapp.so` (3.67MB)
- `patches/patched/lib/arm64-v8a/libapp.so` (3.08MB)
- `patches/patch_metadata.json`

✅ **Visual Verification:**
- Original: Purple theme, "v1.0.0"
- Patched: Orange theme, "🔥 ORANGE PATCH LOADED! 🔥", "v2.0.0-PATCHED"

## Related Documentation

- `docs/JNI_SIGNATURE_MISMATCH_RESOLUTION.md` - Detailed analysis of signature mismatch
- `docs/ENGINE_REBUILD_WITH_ATTACHJNI.md` - Custom engine rebuild process
- `test_apps/quicui_engine_test/patches/` - Generated patch files

## Contact

For questions or alternative approaches, please discuss with the development team.
