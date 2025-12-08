# iOS Hash Calculation Fix - Nov 28, 2025

## Problem Identified

The iOS code push was failing with hash mismatch errors:

```
[ERROR:flutter/shell/common/quicui_patch_loader.cc(345)] QuicUI: Hash mismatch
[ERROR:flutter/shell/common/quicui_patch_loader.cc(346)]   Expected: bc5201f1a228013021fdee9a7969f1b6574a509b34665338adea3c9527bfcf12
[ERROR:flutter/shell/common/quicui_patch_loader.cc(347)]   Actual:
```

**Root Cause**: The C++ engine was using `popen("shasum -a 256 ...")` to calculate file hashes, which **doesn't work on iOS** due to app sandboxing restrictions. iOS apps cannot execute shell commands, so `popen()` fails silently and returns an empty string.

## Solution Implemented

Replaced the shell-based hash calculation with native **CommonCrypto** framework for iOS/macOS, while keeping the original implementation for other platforms.

### Changes Made

#### File: `quicui_patch_loader.cc`

**1. Added CommonCrypto include** (lines 15-17):
```cpp
#ifdef __APPLE__
#include <CommonCrypto/CommonDigest.h>
#endif
```

**2. Added iomanip for hex formatting** (line 9):
```cpp
#include <iomanip>
```

**3. Replaced `CalculateFileHash()` function** with platform-specific implementation:

```cpp
std::string QuicUIPatchLoader::CalculateFileHash(const std::string& path) {
#ifdef __APPLE__
  // Use CommonCrypto for iOS/macOS
  std::ifstream file(path, std::ios::binary);
  if (!file.is_open()) {
    FML_LOG(ERROR) << "QuicUI: Failed to open file for hashing: " << path;
    return "";
  }
  
  CC_SHA256_CTX ctx;
  CC_SHA256_Init(&ctx);
  
  char buffer[4096];
  while (file.read(buffer, sizeof(buffer)) || file.gcount() > 0) {
    CC_SHA256_Update(&ctx, buffer, file.gcount());
  }
  file.close();
  
  unsigned char hash[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256_Final(hash, &ctx);
  
  std::stringstream ss;
  ss << std::hex << std::setfill('0');
  for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
    ss << std::setw(2) << (int)hash[i];
  }
  
  return ss.str();
#else
  // Use system shasum command for other platforms
  std::string command = "shasum -a 256 \"" + path + "\" | awk '{print $1}'";
  
  FILE* pipe = popen(command.c_str(), "r");
  if (!pipe) {
    FML_LOG(ERROR) << "QuicUI: Failed to calculate hash";
    return "";
  }

  char buffer[128];
  std::string hash;
  while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
    hash += buffer;
  }
  pclose(pipe);

  // Remove trailing newline
  if (!hash.empty() && hash[hash.length() - 1] == '\n') {
    hash.erase(hash.length() - 1);
  }

  return hash;
#endif
}
```

## Implementation Details

### iOS/macOS Path (CommonCrypto)
1. Opens the file in binary mode
2. Initializes SHA256 context with `CC_SHA256_Init()`
3. Reads file in 4KB chunks and updates hash with `CC_SHA256_Update()`
4. Finalizes hash with `CC_SHA256_Final()`
5. Converts binary hash to lowercase hexadecimal string

### Other Platforms Path (Shell Command)
- Keeps the original `popen("shasum")` implementation
- Works on platforms where shell commands are available

## Benefits

1. **iOS Compatibility**: Hash calculation now works in iOS sandbox
2. **Performance**: Native C++ hashing is faster than shell commands
3. **Security**: No need to execute external processes
4. **Cross-platform**: Maintains compatibility with other platforms
5. **Standard Library**: Uses Apple's official CommonCrypto framework

## Testing

To verify the fix works:
```bash
# Calculate hash of the patch file manually
xz -d < patch_3.0.46_1764327181227.vmcode.xz | shasum -a 256
# Expected: bc5201f1a228013021fdee9a7969f1b6574a509b34665338adea3c9527bfcf12
```

After rebuilding the engine with this fix:
1. Install app on device
2. Download patch
3. Restart app
4. Check logs - should show:
   - ✅ Hash validation PASSED
   - ✅ Patch loaded successfully
   - ❌ NO "Hash mismatch" error

## Next Steps

1. **Rebuild iOS engine** with the fixed code (~1-2 hours)
2. **Build new app** with updated engine
3. **Install and test** patch loading
4. **Verify** pink/purple gradient displays

## Files Modified

- `/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/shell/common/quicui_patch_loader.cc`

## Backup Location

- Original (before fix): `quicui_patch_loader.cc.backup_before_hash_fix`
- Modified version: Copied to `/Users/admin/Documents/quicui2/docs/2025-11-28/engine_files/`

## Related Issues

- Previous attempt used `popen("shasum")` which failed silently on iOS
- iOS apps cannot execute shell commands due to sandboxing
- Empty hash string caused validation to fail, rejecting valid patches
