# Immediate Action Steps - iOS Code Push Fix

**Date**: November 27, 2025  
**Priority**: HIGH  
**Goal**: Get iOS code push working using interpreter approach

## What We Learned Today

### ❌ What Doesn't Work
- Loading `.so` files from `Library/Caches` with `dlopen()`
- Even with valid Flutter code signatures
- amfid (Apple Mobile File Integrity) blocks it

### ✅ What Works (Shorebird's Approach)
- Using `.vmcode` files (ELF snapshots)
- Loaded by Dart VM's `Dart_LoadELF`, not `dlopen()`
- Interpreter mode instead of AOT
- App Store compliant (3.3.1b allows interpreted code)

## Today's Tasks (Priority Order)

### Task 1: Copy Shorebird Code to Engine ⏳
**Time**: 1-2 hours

```bash
# 1. Navigate to your engine
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter

# 2. Create QuicUI directory
mkdir -p shell/common/quicui

# 3. Copy Shorebird implementation
cp -r /Volumes/DoWonder2/quicui_engine_build/shorebird_engine_quicui/src/flutter/shell/common/shorebird/* \
      shell/common/quicui/

# 4. Rename files
cd shell/common/quicui
mv shorebird.h quicui.h
mv shorebird.cc quicui.cc

# 5. Replace "shorebird" with "quicui" in all files
sed -i '' 's/shorebird/quicui/g' *.h *.cc
sed -i '' 's/Shorebird/QuicUI/g' *.h *.cc
sed -i '' 's/SHOREBIRD/QUICUI/g' *.h *.cc
```

**Verify**:
```bash
ls -la shell/common/quicui/
# Should see: quicui.h, quicui.cc, snapshots_data_handle.h, etc.
```

### Task 2: Copy Updater Library ⏳
**Time**: 30 minutes

```bash
# 1. Navigate to third_party
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src

# 2. Create updater directory
mkdir -p third_party/quicui_updater

# 3. Copy Shorebird updater
cp -r /Volumes/DoWonder2/quicui_engine_build/shorebird_engine_quicui/src/third_party/updater/* \
      third_party/quicui_updater/

# 4. Update references
cd third_party/quicui_updater
find . -name "*.cc" -o -name "*.h" | xargs sed -i '' 's/shorebird/quicui/g'
```

### Task 3: Modify BUILD.gn Files ⏳
**Time**: 30 minutes

**File**: `shell/common/quicui/BUILD.gn`

```gn
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import("//flutter/common/config.gni")

source_set("quicui") {
  sources = [
    "quicui.cc",
    "quicui.h",
    "snapshots_data_handle.cc",
    "snapshots_data_handle.h",
  ]

  deps = [
    "//flutter/common",
    "//flutter/fml",
    "//flutter/runtime",
    "//flutter/shell/platform/embedder:embedder_headers",
    "//third_party/quicui_updater/library",
    "//third_party/dart/runtime/include:dart_api",
  ]

  public_configs = [ "//flutter:config" ]
}
```

**File**: `shell/platform/darwin/ios/BUILD.gn`

Add to iOS target:
```gn
if (quicui_enabled) {
  defines += [ "QUICUI_USE_INTERPRETER=1" ]
  deps += [ "//flutter/shell/common/quicui" ]
}
```

### Task 4: Modify dart_snapshot.cc ⏳
**Time**: 1 hour

**File**: `runtime/dart_snapshot.cc`

Find the function that loads snapshots (around line 200), add:

```cpp
#if QUICUI_USE_INTERPRETER
  // Detect QuicUI .vmcode patch
  auto patch_path = native_library_path.front();
  bool is_vmcode_patch = patch_path.find(".vmcode") != std::string::npos;
  
  if (is_vmcode_patch) {
    FML_LOG(INFO) << "QuicUI: Loading .vmcode patch: " << patch_path;
    
    static Dart_LoadedElf* leaked_elf = nullptr;
    const uint8_t* ignored_vm_data = nullptr;
    const uint8_t* ignored_vm_instrs = nullptr;
    static const uint8_t* isolate_data = nullptr;
    static const uint8_t* isolate_instrs = nullptr;
    
    if (leaked_elf == nullptr) {
      const char* error = nullptr;
      leaked_elf = Dart_LoadELF(
          patch_path.c_str(), 0, &error,
          &ignored_vm_data, &ignored_vm_instrs,
          &isolate_data, &isolate_instrs
      );
      
      if (leaked_elf == nullptr || error != nullptr) {
        FML_LOG(ERROR) << "QuicUI: Failed to load patch: " << error;
        return nullptr;
      }
      
      FML_LOG(INFO) << "QuicUI: ✅ Patch loaded successfully";
    }
    
    return std::make_unique<const fml::NonOwnedMapping>(
        isolate_instrs, 0
    );
  }
#endif  // QUICUI_USE_INTERPRETER
```

### Task 5: Create Build Configuration ⏳
**Time**: 15 minutes

**File**: `flutter/build/quicui.gni`

```gn
# QuicUI Code Push configuration

declare_args() {
  # Enable QuicUI code push
  quicui_enabled = true
}
```

**Import in**: `flutter/BUILD.gn`
```gn
import("//flutter/build/quicui.gni")
```

## Testing Plan (After Engine Build)

### Step 1: Build Engine
```bash
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src

./flutter/tools/gn \
  --runtime-mode=release \
  --ios \
  --ios-cpu=arm64 \
  --quicui-enabled

ninja -C out/ios_release_arm64
```

**Expected**: Successful build with QuicUI integrated

### Step 2: Test .vmcode Generation
```bash
# In your Flutter app
cd /Users/admin/Documents/quicui2/test_apps/quicui_production_test

# Build with new engine
flutter build ios --release
```

### Step 3: Create Test Patch
```bash
# Change theme in main.dart
# Then generate .vmcode patch (need to update CLI first)
dart run ../../packages/quicui_cli/bin/quicui.dart generate-patch \
  --from baseline \
  --to v3.0.40 \
  --format vmcode
```

## Tomorrow's Tasks

### Morning (CLI Updates)
1. **Update `generate-patch` command**:
   - Add `--format` flag (aot | vmcode)
   - Implement `generateVMCodePatch()` method
   - Use `gen_snapshot` tool to create .vmcode

2. **Update `compileservice.dart`**:
   ```dart
   static Future<PatchResult> generateVMCodePatch({
     required String genSnapshotPath,
     required String appDillPath,
     required String outputPath,
   }) async {
     final result = await Process.run(
       genSnapshotPath,
       [
         '--snapshot_kind=app-aot-assembly',
         '--strip',
         '--output=$outputPath',
         appDillPath,
       ],
     );
     
     if (result.exitCode != 0) {
       throw Exception('Failed: ${result.stderr}');
     }
     
     return await compressPatch(outputPath, 'xz');
   }
   ```

### Afternoon (iOS Client Updates)
1. **Update client library**:
   - Change `.so` to `.vmcode`
   - Update cache paths
   - Test download flow

2. **Update iOS loader**:
   - Remove `dlopen` code
   - Engine now handles loading
   - Just configure cache paths

## Quick Reference

### Key Locations
- **Engine**: `/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter`
- **Shorebird Ref**: `/Volumes/DoWonder2/quicui_engine_build/shorebird_engine_quicui/src/flutter`
- **Your Project**: `/Users/admin/Documents/quicui2`

### Important Files
- `runtime/dart_snapshot.cc` - Add .vmcode loading
- `shell/common/quicui/quicui.cc` - Main integration
- `shell/platform/darwin/ios/BUILD.gn` - iOS config
- `flutter/BUILD.gn` - Add QuicUI import

### Build Commands
```bash
# Configure
./flutter/tools/gn --runtime-mode=release --ios --ios-cpu=arm64

# Build
ninja -C out/ios_release_arm64

# Clean (if needed)
rm -rf out/ios_release_arm64
```

## Blockers & Solutions

### Blocker 1: Build Errors
**Solution**: Check Shorebird's exact implementation, copy verbatim first

### Blocker 2: Linker Errors  
**Solution**: Verify BUILD.gn dependencies match Shorebird's

### Blocker 3: Runtime Crashes
**Solution**: Add extensive logging, compare with Shorebird behavior

## Success Criteria

- [ ] Engine builds without errors
- [ ] `.vmcode` files generated correctly
- [ ] No amfid errors when loading patches
- [ ] Theme changes visible after patch
- [ ] No crashes or security warnings

## If You Get Stuck

1. **Compare with Shorebird**: Check their exact implementation
2. **Add logging**: See what's actually happening
3. **Test incrementally**: Don't change everything at once
4. **Ask for help**: Shorebird Discord, Flutter Engine team

---

**Start with Task 1 now!** Copy the Shorebird code and verify it's in place. That's the foundation for everything else.
