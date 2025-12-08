# QuicUI Patch Type Support

## Overview
The QuicUI code push system now supports multiple patch formats for maximum flexibility and cross-platform compatibility.

## Supported Patch Types

### 1. **Binary Patch (.quicui)**
**Platforms**: iOS  
**Method**: BsDiff binary patching  
**Process**:
1. Download `.quicui` or `.quicui.xz` file
2. Decompress if needed
3. Apply BsDiff patch to base App.framework/App binary
4. Save result as `libapp_patched_arm64.so`
5. Engine loads patched binary on next restart

**Pros**:
- Smaller download size (delta patch)
- Works with standard Flutter AOT
- No special engine modifications needed

**Cons**:
- Requires base binary extraction
- Patch application adds startup time
- Requires code signing on iOS

### 2. **Interpreter Snapshot (.vmcode)**
**Platforms**: iOS  
**Method**: Dart VM snapshot loading via Dart_LoadELF  
**Process**:
1. Download `.vmcode` or `.vmcode.xz` file
2. Decompress if needed
3. Copy directly to cache as `libapp_patched_arm64.so`
4. Engine loads via Dart_LoadELF on next restart

**Pros**:
- Direct loading (no patching needed)
- Fastest installation
- No base binary dependency

**Cons**:
- Requires modified Flutter engine with QUICUI_USE_INTERPRETER
- Requires app.dill generation during build
- Currently blocked by kernel_blob.bin issue

### 3. **Shared Library (.so)**
**Platforms**: Android  
**Method**: Dynamic library loading  
**Process**:
1. Download `.so` or `.so.xz` file
2. Decompress if needed
3. Copy directly to cache as `libapp_patched_<arch>.so`
4. Engine loads via dlopen() on next restart

**Pros**:
- Native Android support
- No patching required
- Fast installation

**Cons**:
- Larger file size (full binary)
- Platform-specific builds required

## Implementation Details

### Client Detection (Dart)
```dart
// Detects patch type from download URL
final uri = Uri.parse(patch.downloadUrl);
final urlPath = uri.path;

if (urlPath.contains('.vmcode')) {
  fileExtension = 'vmcode';
} else if (urlPath.contains('.so')) {
  fileExtension = 'so';
} else if (urlPath.contains('.quicui')) {
  fileExtension = 'quicui';
}
```

### Native Installation (iOS Swift)
```swift
let fileExtension = sourceURL.pathExtension

if isPatchFile {
  // Apply BsDiff patch to base App.framework
  try loader.applyPatchPublic(
    oldFile: baseAppPath,
    patchFile: sourceURL.path,
    newFile: patchedAppPath.path
  )
} else if isVMCode {
  // Copy .vmcode directly
  try fileManager.copyItem(at: sourceURL, to: destinationURL)
} else {
  // Copy .so or unknown directly
  try fileManager.copyItem(at: sourceURL, to: destinationURL)
}
```

## Current Status

| Patch Type | iOS | Android | Status |
|------------|-----|---------|--------|
| .quicui    | ✅  | N/A     | Working |
| .vmcode    | ⚠️  | N/A     | Blocked (app.dill) |
| .so        | ⚠️  | ✅      | iOS untested |

## Testing Required

1. **iOS .quicui patches** (Binary approach)
   - [ ] Download and decompress
   - [ ] Apply BsDiff patch
   - [ ] Load patched binary
   - [ ] Verify UI changes
   
2. **iOS .vmcode patches** (Interpreter approach)
   - [ ] Fix app.dill generation
   - [ ] Test vmcode loading
   - [ ] Performance comparison

3. **Android .so patches**
   - [ ] Test existing Android flow
   - [ ] Verify no regressions

## Next Steps

1. **Fix app.dill generation** for iOS release builds
   - Investigate kernel_blob.bin location
   - Test with --debug flag
   - Consider extracting from .app bundle

2. **Test iOS binary patch flow**
   - Rebuild app with fixes
   - Install on device
   - Download patch
   - Verify patch application
   - Test app restart

3. **Performance benchmarking**
   - Compare .quicui vs .vmcode load times
   - Measure patch application overhead
   - Optimize if needed

4. **Code signing**
   - Investigate iOS library signing requirements
   - Test unsigned patches
   - Document signing workflow if needed

## File Naming Convention

All patch types use the same final name for C++ loader compatibility:
```
libapp_patched_<architecture>.so
```

Examples:
- iOS: `libapp_patched_arm64.so`
- Android: `libapp_patched_arm64-v8a.so`

## Metadata Format

```json
{
  "version": "3.0.36",
  "hash": "sha256_hash_here",
  "architecture": "arm64",
  "type": "quicui|vmcode|so"
}
```

## Compression Support

All patch types support compression:
- `.xz` (recommended, best ratio)
- `.gz` (fast, good ratio)
- `.bz2` (balanced)
- No compression (fastest download on fast networks)

Backend automatically serves compressed versions based on `Accept-Encoding` header.
