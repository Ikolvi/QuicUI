# Summary: iOS Hash Calculation Fix - November 28, 2025

## Issue
iOS code push was failing with hash mismatch. The C++ engine calculated an empty hash for downloaded patch files, causing validation to fail even though patches were correct.

## Root Cause
The engine's `CalculateFileHash()` function used `popen("shasum -a 256 ...")` which **doesn't work on iOS** due to app sandbox restrictions. iOS apps cannot execute shell commands.

## Fix Applied
Replaced shell-based hash calculation with native **CommonCrypto** framework for iOS/macOS.

### Changes
1. **Added includes**:
   - `#include <CommonCrypto/CommonDigest.h>` (iOS/macOS only)
   - `#include <iomanip>` (for hex formatting)

2. **Updated `CalculateFileHash()`** function:
   - iOS/macOS: Uses `CC_SHA256_Init/Update/Final` from CommonCrypto
   - Other platforms: Keeps original `popen("shasum")` implementation

### Modified Files
- `/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/shell/common/quicui_patch_loader.cc`

### Backup Created
- `quicui_patch_loader.cc.backup_before_hash_fix`

### Documentation
All files copied to: `/Users/admin/Documents/quicui2/docs/2025-11-28/`
- `engine_files/quicui_patch_loader.cc` - Modified source
- `engine_files/quicui_patch_loader.h` - Header file
- `HASH_CALCULATION_FIX.md` - Detailed explanation
- `ENGINE_REBUILD_INSTRUCTIONS.md` - Rebuild guide
- `SUMMARY.md` - This file

## Next Steps
1. **Rebuild iOS engine** (1-2 hours)
2. **Build new app** with fixed engine (Build 26)
3. **Test patch loading**
4. **Verify hash validation passes**

## Expected Behavior After Fix
```
✅ [INFO] Patch file exists, size: 4113328 bytes
✅ [INFO] Calculating hash for validation...
✅ [INFO] Hash: bc5201f1a228013021fdee9a7969f1b6574a509b34665338adea3c9527bfcf12
✅ [INFO] Hash validation: PASSED
✅ [INFO] Loading patch from: .../dlc.vmcode
✅ Pink/purple gradient displays (patch loaded)
```

## Technical Details

### Before (Broken)
```cpp
std::string QuicUIPatchLoader::CalculateFileHash(const std::string& path) {
  std::string command = "shasum -a 256 \"" + path + "\" | awk '{print $1}'";
  FILE* pipe = popen(command.c_str(), "r");  // ❌ Fails on iOS
  // ... returns empty string
}
```

### After (Fixed)
```cpp
std::string QuicUIPatchLoader::CalculateFileHash(const std::string& path) {
#ifdef __APPLE__
  // ✅ Use CommonCrypto for iOS/macOS
  CC_SHA256_CTX ctx;
  CC_SHA256_Init(&ctx);
  // ... read file and calculate hash
  CC_SHA256_Final(hash, &ctx);
  // ... convert to hex string
#else
  // Keep popen for other platforms
#endif
}
```

## Verification
Patch hash should match:
```
Expected: bc5201f1a228013021fdee9a7969f1b6574a509b34665338adea3c9527bfcf12
Server patch ID: 1764327189870
Size: 4113328 bytes (3.92 MB uncompressed)
```

## Status
- ✅ Issue identified
- ✅ Root cause found (popen doesn't work on iOS)
- ✅ Fix implemented (CommonCrypto)
- ✅ Files backed up
- ✅ Documentation created
- ⏳ Engine rebuild needed
- ⏳ Testing pending
