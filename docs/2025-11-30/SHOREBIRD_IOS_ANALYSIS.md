# Shorebird iOS Code Push - Technical Analysis

**Date:** November 30, 2025  
**Author:** QuicUI Research Team  
**Status:** Research Complete

## 🎉 MAJOR DISCOVERY: Shorebird SDK Installed Locally

We discovered that **Shorebird is installed on this machine** at:
```
/Users/admin/.shorebird/
```

This installation contains:
- **Full Shorebird CLI source code**
- **Pre-built iOS Flutter.xcframework** with Shorebird modifications
- **Pre-built gen_snapshot_arm64** with ShorebirdLinker
- **Pre-built Dart SDK** with Shorebird modifications (version 3.10.1)

## Executive Summary

After extensive analysis of Shorebird's open-source components and documentation, we have determined that iOS code push requires **proprietary modifications to the Dart SDK** that are not publicly available. **However, the pre-built binaries are available locally and could potentially be studied or used.**

---

## How Shorebird Implements iOS Code Push

### The Core Problem

iOS has strict code signing requirements that prevent:
1. Loading unsigned native code into executable memory
2. JIT compilation at runtime
3. Dynamic code execution from downloaded files

Standard Flutter apps use AOT (Ahead-of-Time) compilation, producing signed machine code that cannot be modified post-installation.

### Shorebird's Solution: Custom Dart Interpreter

Shorebird created a **novel Dart interpreter** embedded in their private Dart SDK fork.

From their official documentation:
> "On iOS, instead of compiling to the normal machine code, we instead compile to a **modified format** that can be then interpreted on device."

### Technical Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    iOS App (IPA)                            │
├─────────────────────────────────────────────────────────────┤
│  Base App (Signed, AOT)                                     │
│  ├── Flutter.framework (Modified with Shorebird)            │
│  ├── App.framework (Original Dart code, AOT compiled)       │
│  └── Shorebird Updater Library (libupdater.a)              │
├─────────────────────────────────────────────────────────────┤
│  Downloaded Patches (.vmcode files)                         │
│  └── Loaded as READ-ONLY data, NOT executable              │
│  └── Interpreted by custom Dart VM                         │
└─────────────────────────────────────────────────────────────┘
```

### Key Components (4 Forked Repositories)

| Repository | Status | Purpose |
|------------|--------|---------|
| `flutter/buildroot` | Public | Expose updater symbols, include libunwind |
| `flutter/engine` | Public | Integrate Shorebird updater, load patches |
| `flutter/flutter` | Public | Modified Flutter tool, include shorebird.yaml |
| `dart-lang/sdk` | **PRIVATE** | Custom interpreter, linker, compiler changes |

### The Private Dart SDK Modifications

Shorebird's private Dart SDK includes:

1. **Modified Dart Compiler**
   - Produces output maximally similar to previous version
   - Enables code reuse at per-function level

2. **Custom Linker**
   - Compares "previous" and "new" Dart programs
   - Determines which functions can run from signed base app
   - Which functions need interpretation

3. **Dart Interpreter**
   - Runs patched functions that differ from base
   - Reads patch data as read-only memory
   - No executable memory mapping required

4. **Key Functions (defined in private SDK)**
   - `Shorebird_SetBaseSnapshots()` - Stores base app's AOT snapshots
   - `Shorebird_ReadLinkHeader()` - Reads .vmcode patch header

### Performance Optimization

From Shorebird documentation:
> "You should expect almost all (typically **98% or higher**) of the patched code to run out of the 'previous' binary included in the IPA, and thus run **full-speed on the CPU**."

This means:
- ~98% of code runs as native AOT (full speed)
- ~2% of changed code runs through interpreter (slower)
- Net impact is minimal for typical updates

---

## What We Tried

### Approach 1: Native ELF Loading (Failed)

**Attempt:** Load ARM64 ELF files directly like Android
```
Error: codesigning:invalid-page
```
**Reason:** iOS requires all executable memory to be signed

### Approach 2: Read-Only ELF Loading (Failed)

**Attempt:** Modified `Dart_LoadELF` with `load_as_readonly` parameter
```cpp
leaked_elf = Dart_LoadELF_Memory(
    elf_data, elf_size, &error,
    &vm_data, &vm_instrs, &isolate_data, &isolate_instrs,
    true  /* load_as_readonly */
);
```
**Reason:** Data is loaded, but standard Dart VM still tries to **execute** the instructions, causing crash

### Approach 3: Standard Dart Interpreter (Not Available)

**Finding:** The Dart interpreter (`runtime/vm/interpreter.cc`) is excluded from iOS builds:
```cpp
#if !defined(DART_PRECOMPILED_RUNTIME)
// Interpreter code here - NOT included in iOS release builds
#endif
```

---

## Code Evidence

### Shorebird's config.gni (iOS flag)
```gni
if (is_ios) {
  feature_defines_list += [ "SHOREBIRD_USE_INTERPRETER=1" ]
}
```

### Shorebird's dart_snapshot.cc (Patch loading)
```cpp
#if SHOREBIRD_USE_INTERPRETER
  if (is_patch) {
    // Load patch as read-only
    leaked_elf = Dart_LoadELF(patch_path.c_str(), elf_file_offset, &error,
                              &ignored_vm_data, &ignored_vm_instrs,
                              &isolate_data, &isolate_instrs,
                              /* load as read-only, not rx */ false);
    // ... custom interpreter handles execution
  }
#endif
```

### Shorebird's DEPS (Private Dart SDK)
```python
"dart_sdk_git": "git@github.com:shorebirdtech/dart-sdk.git",  # PRIVATE
"dart_sdk_revision": "ddb0f3b6c38b1774a3413c2c159b124be6bd1df7",
```

---

## Conclusions

### Why We Cannot Replicate Shorebird's iOS Approach

1. **Private Dart SDK** - The interpreter and linker code is proprietary
2. **Massive Engineering Effort** - Modifying the Dart VM requires:
   - Deep understanding of Dart's compilation pipeline
   - Creating a custom bytecode format
   - Building a per-function linker
   - Extensive testing across all Dart features
3. **Ongoing Maintenance** - Must track Dart/Flutter updates

### Current QuicUI Status

| Platform | Code Push Status | Method |
|----------|------------------|--------|
| Android | ✅ **Working** | Native ELF loading |
| iOS | ❌ **Not Possible** | Requires private Dart SDK |

---

## Recommendations

### Option 1: Partner with Shorebird (Recommended)
- License their technology
- Integrate their SDK into QuicUI
- Leverage their ongoing maintenance

### Option 2: iOS-Specific Alternatives

1. **Server-Driven UI**
   - Define UI as JSON on server
   - Render with Flutter widgets on client
   - No code changes, just data changes

2. **Asset-Only Updates**
   - Update images, text, configuration
   - No Dart code changes possible

3. **WebView Hybrid**
   - Use WebView for dynamic content areas
   - Run JavaScript for patch logic

### Option 3: Android-Only Code Push
- Continue with current working Android implementation
- Document iOS limitation clearly
- Focus resources on Android excellence

---

## References

- [Shorebird System Architecture](https://docs.shorebird.dev/code-push/system-architecture/)
- [Shorebird Engine Fork](https://github.com/shorebirdtech/engine)
- [Shorebird Updater Library](https://github.com/shorebirdtech/updater)
- [Flutter Engine Source](https://github.com/flutter/engine)
- [Dart SDK Source](https://github.com/dart-lang/sdk)

---

## Appendix A: Key Files Analyzed

### Shorebird Engine (Public)
- `shell/common/shorebird/shorebird.cc` - Main integration
- `shell/common/shorebird/shorebird.h` - Configuration structs
- `shell/common/shorebird/snapshots_data_handle.cc` - Snapshot handling
- `runtime/dart_snapshot.cc` - Patch loading logic
- `common/config.gni` - Build flags including `SHOREBIRD_USE_INTERPRETER`

### Shorebird Updater (Public)
- `library/src/c_api/mod.rs` - C API for Flutter engine
- `library/src/updater.rs` - Core update logic
- `library/include/updater.h` - Exported functions

### Standard Dart SDK
- `runtime/bin/elf_loader.cc` - ELF loading (7 params standard, 8 in Shorebird)
- `runtime/vm/interpreter.cc` - Interpreter (excluded in AOT builds)
- `runtime/vm/dart_api_impl.cc` - `Dart_IsPrecompiledRuntime()` check

---

## Appendix B: Local Shorebird Installation Analysis

### Location
```
/Users/admin/.shorebird/
```

### Key Binaries (Pre-built with Shorebird Modifications)

#### 1. iOS gen_snapshot (with ShorebirdLinker)
```
/Users/admin/.shorebird/bin/cache/flutter/5d7eab0b8cc0146649c1c37cd1e1968c97d9e5dd/bin/cache/artifacts/engine/ios-release/gen_snapshot_arm64
```

**Symbols found:**
```
ShorebirdLinker::shared()
ShorebirdLinker::InitializeWithClassTableLinkInfo()
ShorebirdLinker::InitializeWithFieldTableLinkInfo()
ShorebirdLinker::InitializeWithDispatchTableLinkInfo()
ShorebirdLinker::InitializeWithObjectPoolLinkInfo()
dart::shorebird::WrapperAllocator
dart::shorebird::WrapperLayout<CPUToSimConfig>
dart::shorebird::WrapperLayout<SimToCPUConfig>
```

**Source files referenced in binary:**
```
flutter/third_party/dart/runtime/vm/shorebird/linker.cc
flutter/third_party/dart/runtime/vm/shorebird/link_info.cc
flutter/third_party/dart/runtime/vm/shorebird/class_table_mapper.cc
flutter/third_party/dart/runtime/vm/shorebird/object_pool_editor.cc
flutter/third_party/dart/runtime/vm/shorebird/object_pool_mapper.cc
flutter/third_party/dart/runtime/vm/simulator_arm64.cc
```

#### 2. iOS Flutter.xcframework (with Shorebird updater)
```
/Users/admin/.shorebird/bin/cache/flutter/.../bin/cache/artifacts/engine/ios-release/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter
```

**Exported Shorebird functions:**
```
_shorebird_init
_shorebird_check_for_update
_shorebird_check_for_downloadable_update
_shorebird_update
_shorebird_update_with_result
_shorebird_start_update_thread
_shorebird_current_boot_patch_number
_shorebird_next_boot_patch_number
_shorebird_next_boot_patch_path
_shorebird_validate_next_boot_patch
_shorebird_should_auto_update
_shorebird_report_launch_start
_shorebird_report_launch_success
_shorebird_report_launch_failure
_shorebird_free_string
_shorebird_free_update_result
```

#### 3. Dart SDK Binary (with Shorebird extensions)
```
/Users/admin/.shorebird/bin/cache/flutter/.../bin/cache/dart-sdk/bin/dart
```

**Shorebird-specific symbols:**
```
FLAG_print_shorebird_info
```

**Shorebird-specific strings:**
```
"Print shorebird information"
"Shorebird stats:"
"Has shorebird base instructions table: %s"
"flutter/third_party/dart/runtime/vm/shorebird.cc"
```

### CLI Source Code Location
```
/Users/admin/.shorebird/packages/shorebird_cli/
```

### Key iOS Patching Implementation

#### ios_patcher.dart
```dart
// Path: /Users/admin/.shorebird/packages/shorebird_cli/lib/src/commands/patch/ios_patcher.dart
// Key workflow:
1. Build IPA with flutter (artifactBuilder.buildIpa)
2. Build ELF AOT snapshot (artifactBuilder.buildElfAotSnapshot)  
3. Copy supplement files (class_table, field_table, dispatch_table)
4. Run Shorebird linker (apple.runLinker)
5. Generate .vmcode output file
```

#### aot_tools.dart (Linker Interface)
```dart
// The linker command:
await _exec([
  'link',
  '--base=$base',           // Release App binary
  '--patch=$patch',         // Patch AOT snapshot
  '--analyze-snapshot=$analyzeSnapshot',
  '--gen-snapshot=$genSnapshot',
  '--kernel=$kernel',
  '--output=$outputPath',   // out.vmcode
  '--reporter=json',
  ...
]);
```

### Supplement Files Used for Linking
```
App.ct.link / App.class_table.json
App.ft.link / App.field_table.json
App.dt.link / App.dispatch_table.json
```

These files are generated by gen_snapshot during release build and stored on Shorebird servers. During patching, they're used to determine which functions can be linked (run natively) vs interpreted.

---

## Appendix C: Potential Next Steps

### Option 1: Study Local Binaries (Reverse Engineering)
The pre-built binaries could potentially be:
- Disassembled with tools like Ghidra/IDA Pro
- Analyzed to understand the ShorebirdLinker algorithm
- Used as reference for implementing similar functionality

**Legal Concerns:** Check Shorebird's license before reverse engineering.

### Option 2: Use Shorebird's Pre-built Artifacts
The iOS Flutter.framework with shorebird functions is already built. QuicUI could potentially:
- Replace standard Flutter.framework with Shorebird's version
- Implement backend that's compatible with their update protocol
- Produce patches using their gen_snapshot

**Challenges:** 
- Would need to understand their server protocol
- Patches must be in specific format for their Flutter.framework
- May require subscription to their service for patch generation

### Option 3: Partnership
Contact Shorebird to discuss:
- Licensing their technology
- White-label arrangement
- Integration partnership
