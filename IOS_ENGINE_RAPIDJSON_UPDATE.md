# iOS Engine Update: RapidJSON + Comprehensive Logging

**Date**: November 28, 2025
**Engine Path**: `/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine`
**Build**: ios_release (972/972 targets)
**Status**: ✅ Successfully Built

---

## Changes Made

### 1. Replaced Manual JSON Parsing with RapidJSON

**File**: `shell/common/quicui_patch_loader.cc`

**Before** (Manual string parsing):
```cpp
size_t pos = content.find("\"number\"");
if (pos == std::string::npos) return "";
// Manual string manipulation...
```

**After** (RapidJSON):
```cpp
#include "third_party/rapidjson/include/rapidjson/document.h"

rapidjson::Document json_doc;
json_doc.Parse(content.c_str());

if (json_doc.HasParseError()) {
  FML_LOG(WARNING) << "QuicUI: [iOS] JSON parse error at offset " 
                   << json_doc.GetErrorOffset();
  return "";
}

if (!json_doc.HasMember("number")) {
  FML_LOG(WARNING) << "QuicUI: [iOS] JSON does not have 'number' field";
  return "";
}

const auto& number_value = json_doc["number"];
if (number_value.IsUint64()) {
  return std::to_string(number_value.GetUint64());
} else if (number_value.IsInt64()) {
  return std::to_string(number_value.GetInt64());
}
```

**Benefits**:
- ✅ Proper JSON parsing (no manual string manipulation)
- ✅ Handles different number types (uint64, int64, int, uint)
- ✅ Clear error messages with offset information
- ✅ Validates JSON structure before accessing fields

---

### 2. Added Comprehensive Logging

**Every step is now logged with `[iOS]` prefix for easy filtering:**

#### A. Directory Validation
```cpp
std::string QuicUIPatchLoader::GetIOSPatchesStateDir() const {
  if (code_cache_dir_.empty()) {
    FML_LOG(WARNING) << "QuicUI: [iOS] code_cache_dir_ is empty";
    return "";
  }
  
  std::string result = fml::paths::JoinPaths({code_cache_dir_, "patches"});
  FML_LOG(INFO) << "QuicUI: [iOS] Patches state directory: " << result;
  
  if (result.empty()) {
    FML_LOG(WARNING) << "QuicUI: [iOS] Patches directory is empty";
  }
  
  return result;
}
```

#### B. File Existence Check
```cpp
std::string state_path = fml::paths::JoinPaths({patches_dir, "patches_state.json"});
FML_LOG(INFO) << "QuicUI: [iOS] Checking state file at: " << state_path;

if (!FileExists(state_path)) {
  FML_LOG(WARNING) << "QuicUI: [iOS] State file does not exist: " << state_path;
  return "";
}

FML_LOG(INFO) << "QuicUI: [iOS] State file exists, opening...";
```

#### C. File Open/Read
```cpp
std::ifstream file(state_path);
if (!file.is_open()) {
  FML_LOG(WARNING) << "QuicUI: [iOS] Failed to open state file: " << state_path;
  return "";
}

FML_LOG(INFO) << "QuicUI: [iOS] File opened successfully, reading content...";

uint64_t file_size = GetFileSize(state_path);
FML_LOG(INFO) << "QuicUI: [iOS] Read " << file_size << " bytes";

if (content.empty()) {
  FML_LOG(WARNING) << "QuicUI: [iOS] State file is empty";
  return "";
}

FML_LOG(INFO) << "QuicUI: [iOS] State file content: " << content;
```

#### D. JSON Parsing
```cpp
rapidjson::Document json_doc;
json_doc.Parse(content.c_str());

if (json_doc.HasParseError()) {
  FML_LOG(WARNING) << "QuicUI: [iOS] JSON parse error at offset " 
                   << json_doc.GetErrorOffset() << ": " 
                   << GetParseError_En(json_doc.GetParseError());
  return "";
}

FML_LOG(INFO) << "QuicUI: [iOS] JSON parsed successfully";

if (!json_doc.IsObject()) {
  FML_LOG(WARNING) << "QuicUI: [iOS] JSON root is not an object";
  return "";
}

if (!json_doc.HasMember("number")) {
  FML_LOG(WARNING) << "QuicUI: [iOS] JSON does not have 'number' field";
  return "";
}
```

#### E. Success Path
```cpp
std::string patch_id = std::to_string(number_value.GetUint64());
FML_LOG(INFO) << "QuicUI: [iOS] Extracted patch ID: " << patch_id;
return patch_id;
```

#### F. Patch Path Construction
```cpp
std::string QuicUIPatchLoader::GetPatchFilePath(const std::string& architecture) const {
  FML_LOG(INFO) << "QuicUI: [iOS] Getting patch file path...";
  
  std::string patch_id = GetIOSPatchIdFromState();
  if (patch_id.empty()) {
    FML_LOG(WARNING) << "QuicUI: [iOS] Failed to get patch ID from state";
    return "";
  }
  
  std::string ios_patches_dir = GetIOSPatchesStateDir();
  std::string result = fml::paths::JoinPaths({ios_patches_dir, patch_id, "dlc.vmcode"});
  
  FML_LOG(INFO) << "QuicUI: [iOS] Constructed patch path: " << result;
  return result;
}
```

---

### 3. Added Helper Function for File Size

**File**: `shell/common/quicui_patch_loader.h`

```cpp
uint64_t GetFileSize(const std::string& path) const;
```

**Implementation**:
```cpp
uint64_t QuicUIPatchLoader::GetFileSize(const std::string& path) const {
  struct stat stat_buf;
  int rc = stat(path.c_str(), &stat_buf);
  return rc == 0 ? stat_buf.st_size : 0;
}
```

---

## Expected Log Output

When the app restarts and tries to load a patch, you'll now see:

### Success Case:
```
[INFO] QuicUI: Code cache directory set to: /var/mobile/.../Library/Caches
[INFO] QuicUI: [iOS] Patches state directory: /var/mobile/.../Library/Caches/patches
[INFO] QuicUI: [iOS] Checking state file at: /var/mobile/.../Library/Caches/patches/patches_state.json
[INFO] QuicUI: [iOS] State file exists, opening...
[INFO] QuicUI: [iOS] File opened successfully, reading content...
[INFO] QuicUI: [iOS] Read 123 bytes
[INFO] QuicUI: [iOS] State file content: {"number":1764271672472,"size":4096944,"hash":"0bba873b..."}
[INFO] QuicUI: [iOS] JSON parsed successfully
[INFO] QuicUI: [iOS] Extracted patch ID: 1764271672472
[INFO] QuicUI: [iOS] Getting patch file path...
[INFO] QuicUI: [iOS] Constructed patch path: /var/mobile/.../Library/Caches/patches/1764271672472/dlc.vmcode
```

### Failure Cases (with specific errors):

**Case 1: File doesn't exist**
```
[WARNING] QuicUI: [iOS] State file does not exist: /var/mobile/.../Library/Caches/patches/patches_state.json
```

**Case 2: File can't be opened**
```
[INFO] QuicUI: [iOS] State file exists, opening...
[WARNING] QuicUI: [iOS] Failed to open state file: /var/mobile/.../Library/Caches/patches/patches_state.json
```

**Case 3: File is empty**
```
[INFO] QuicUI: [iOS] File opened successfully, reading content...
[INFO] QuicUI: [iOS] Read 0 bytes
[WARNING] QuicUI: [iOS] State file is empty
```

**Case 4: Invalid JSON**
```
[WARNING] QuicUI: [iOS] JSON parse error at offset 15: Invalid value.
```

**Case 5: Missing 'number' field**
```
[INFO] QuicUI: [iOS] JSON parsed successfully
[WARNING] QuicUI: [iOS] JSON does not have 'number' field
```

---

## Build Details

### Engine Build
```bash
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src
./flutter/tools/gn --ios --runtime-mode=release --no-lto
ninja -C out/ios_release
```

**Result**: ✅ 972/972 targets completed

### XCFramework Creation
```bash
cd out/ios_release
rm -rf Flutter.xcframework
xcodebuild -create-xcframework -framework Flutter.framework -output Flutter.xcframework
```

**Result**: ✅ xcframework successfully written

---

## Verification

### Check Compiled Code
```bash
strings Flutter.framework/Flutter | grep "QuicUI: \[iOS\]"
```

**Found 20+ log messages** including:
- ✅ `QuicUI: [iOS] code_cache_dir_ is empty`
- ✅ `QuicUI: [iOS] Patches state directory:`
- ✅ `QuicUI: [iOS] Checking state file at:`
- ✅ `QuicUI: [iOS] State file does not exist:`
- ✅ `QuicUI: [iOS] State file exists, opening...`
- ✅ `QuicUI: [iOS] Failed to open state file:`
- ✅ `QuicUI: [iOS] File opened successfully, reading content...`
- ✅ `QuicUI: [iOS] Read`
- ✅ `QuicUI: [iOS] State file is empty`
- ✅ `QuicUI: [iOS] State file content:`
- ✅ `QuicUI: [iOS] JSON parse error at offset`
- ✅ `QuicUI: [iOS] JSON parsed successfully`
- ✅ `QuicUI: [iOS] JSON root is not an object`
- ✅ `QuicUI: [iOS] JSON does not have 'number' field`
- ✅ `QuicUI: [iOS] 'number' field is not a valid integer type`
- ✅ `QuicUI: [iOS] Extracted patch ID:`
- ✅ `QuicUI: [iOS] Getting patch file path...`
- ✅ `QuicUI: [iOS] Failed to get patch ID from state`
- ✅ `QuicUI: [iOS] Constructed patch path:`

---

## Next Steps

1. **Build iOS app with new engine**:
   ```bash
   cd /Users/admin/Documents/quicui2/test_apps/quicui_production_test
   flutter build ios --release --no-codesign
   ```

2. **Install on device**:
   ```bash
   ios-deploy --bundle build/ios/iphoneos/Runner.app
   ```

3. **Check logs after restart**:
   - Look for `[iOS]` prefixed messages
   - Identify exact failure point
   - See actual file content being read

4. **Expected insights**:
   - Is the file path correct?
   - Does the file exist?
   - Can it be opened?
   - What's the actual content?
   - Is JSON valid?
   - Is the 'number' field present and correct type?

---

## Files Modified

1. **quicui_patch_loader.cc** (Lines 43-120)
   - Added RapidJSON include
   - Replaced manual JSON parsing
   - Added comprehensive logging at every step

2. **quicui_patch_loader.h** (Line ~129)
   - Added `GetFileSize()` declaration

3. **BUILD.gn** (If RapidJSON wasn't already included)
   - RapidJSON is part of Flutter engine's third_party deps

---

## Technical Notes

### RapidJSON Path
```cpp
#include "third_party/rapidjson/include/rapidjson/document.h"
```

This is already available in Flutter engine, no additional dependencies needed.

### JSON Format Expected
```json
{
  "number": 1764271672472,
  "size": 4096944,
  "hash": "0bba873b3ed44c10891576694b78216e0c57402ef3b0486470053ca0a513e618"
}
```

### Number Type Handling
RapidJSON supports: `IsUint64()`, `IsInt64()`, `IsInt()`, `IsUint()`, `IsNumber()`

We check in order:
1. `IsUint64()` - Most common for timestamps
2. `IsInt64()` - Signed 64-bit
3. `IsInt()` - 32-bit signed
4. `IsUint()` - 32-bit unsigned
5. Else: Warning about invalid type

---

## Debugging Strategy

With these logs, we can now pinpoint the exact failure:

| Log Message | Problem | Solution |
|-------------|---------|----------|
| "code_cache_dir_ is empty" | Cache dir not set | Check iOS platform setup |
| "Patches directory is empty" | Path construction failed | Check fml::paths::JoinPaths |
| "State file does not exist" | File not created | Check iOS plugin installation |
| "Failed to open state file" | Permission issue | Check file permissions |
| "State file is empty" | File written incorrectly | Check iOS plugin write logic |
| "JSON parse error" | Invalid JSON | Check file content |
| "JSON does not have 'number'" | Wrong format | Check iOS plugin JSON creation |
| "'number' is not valid type" | Type mismatch | Check number serialization |

---

## Success Criteria

✅ Engine builds successfully
✅ RapidJSON code present in binary
✅ All log messages present in binary
✅ XCFramework created

**Next**: Test with actual iOS app installation and check logs!
