# iOS Patch Generation Crash Fix - 2025-11-26

## Problem Summary
iOS app crashed with SIGSEGV when loading patches. After cache clearing, still crashing.

## Root Cause Discovered
**Ad-hoc code signing was corrupting the patch files.**

The workflow was:
1. Build v3.0.24 baseline → Extract binary → **Sign with `codesign -f -s -`**
2. Build v3.0.27 target → Extract binary → **Sign with `codesign -f -s -`**
3. Generate patch between the TWO ad-hoc signed binaries
4. Result: **Corrupt 3.7 MB patch** that crashes device with SIGSEGV

### Why This Failed
- Ad-hoc signatures (`codesign -f -s -`) embed metadata that changes each time
- Signing modifies the binary structure
- BsDiff patch between two differently-signed binaries creates corrupt patch
- Test: `bspatch` reported "Corrupt patch" when trying to apply it

## Solution
**DO NOT sign binaries before generating patches. Use original Flutter-signed binaries.**

### Correct Workflow
```bash
# Build baseline - DON'T sign after!
dart run quicui.dart build-ipa --version 3.0.24 --baseline

# Build target - DON'T sign after!
dart run quicui.dart build-ipa --version 3.0.27

# Generate patch from ORIGINAL binaries
dart run quicui.dart generate-patch --from baseline --to v3.0.27

# Upload to Supabase
dart run quicui.dart upload-patch --patch <PATCH_ID>
```

## Results

### Before Fix (with ad-hoc signing)
- Patch size: **3,894,052 bytes** (3.7 MB)
- Compression: Only 3.96%
- Test: `bspatch: Corrupt patch`
- Device: SIGSEGV crash on load

### After Fix (original signatures)
- Patch size: **173 bytes** (0.17 KB) ✅
- Compression: 97%
- Makes sense: Only UI strings changed between v3.0.24 and v3.0.27
- Should work correctly on device

## Key Insights
1. Flutter's build already signs the App binary properly
2. QuicUI CLI correctly extracts the signed binary
3. **No additional signing needed for patch generation**
4. The device loads whatever signature the binary has
5. Code signing should only be done for App Store/TestFlight distribution

## Current Status

### Device State
- Installed: v3.0.24 (green nature theme)
- Device ID: `653324F8-D2E4-5A3A-BC77-C7C601AA9433`
- Install location: `9E2990D2-36FB-46BA-B75B-CF2CFB352C57`

### Patches
- **v3.0.26**: 632 KB (may be corrupt, needs regeneration)
- **v3.0.27 (old)**: 3.7 MB corrupt patch in Supabase - **NEEDS DELETION**
- **v3.0.27 (new)**: 173 bytes valid patch - **READY TO UPLOAD**
  - Patch ID: `1764115137953`
  - Hash: `ebb3fc09f075a1b913d380391aa51a84b14f1b4cba8b1492a920bbbea9f35041`

## Next Steps
1. ⏳ Delete corrupt v3.0.27 patch from Supabase backend
2. ⏳ Upload new 173-byte v3.0.27 patch
3. ⏳ Test on device - should show blue ocean theme without crash
4. ⏳ Regenerate v3.0.26 patch using correct workflow
5. ⏳ Test multiple sequential patches

## Backend Note
**QuicUI uses Supabase as backend**, not a local server. All patch operations go through Supabase.

## Files
- Baseline: `baseline/App-v3.0.24`
- Target: `v3.0.27/App-v3.0.27`
- New patch: `patches/1764115137953_metadata.json`
- Patch binary: `patches/patch_1764115137797.quicui.xz`
