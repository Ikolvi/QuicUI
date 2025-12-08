# Reverse-Engineering Shorebird's iOS Code Push

## Executive Summary

After complete research of Shorebird's implementation, we now understand their approach:
- `.vmcode` files are **ELF files with a custom header prepended**
- They use a proprietary **linker** to create differential AOT patches
- Their Flutter engine has been modified to load these patches at runtime
- This is **NOT simple binary patching** - it's differential AOT compilation

## What We Discovered

### 1. The .vmcode File Format

```
┌─────────────────────────────────┐
│ Shorebird Custom Header         │ ← Unknown size, proprietary
├─────────────────────────────────┤
│ Standard ELF File                │
│  - kDartIsolateSnapshotData      │ ← Modified isolate data
│  - kDartIsolateSnapshotInstructions │ ← Modified isolate instructions
└─────────────────────────────────┘
```

**Key Function**: `Shorebird_ReadLinkHeader(uint8_t* data, size_t size) -> int`
- Reads custom header
- Returns offset to ELF start

### 2. Engine Loading Code

From `shorebirdtech/engine` at `runtime/dart_snapshot.cc` lines 59-116:

```cpp
#if SHOREBIRD_USE_INTERPRETER
  auto patch_path = native_library_path.front();
  bool is_patch = patch_path.find(".vmcode") != std::string::npos;
  
  if (is_patch) {
    static Dart_LoadedElf* leaked_elf = nullptr;
    static const uint8_t* isolate_data = nullptr;
    static const uint8_t* isolate_instrs = nullptr;
    
    if (leaked_elf == nullptr) {
      // Read custom header to get ELF offset
      auto elf_mapping = GetFileMapping(patch_path, false);
      int elf_file_offset = Shorebird_ReadLinkHeader(
        elf_mapping->GetMapping(),
        elf_mapping->GetSize()
      );
      
      // Load ELF from offset position
      const uint8_t* ignored_vm_data = nullptr;
      const uint8_t* ignored_vm_instrs = nullptr;
      
      leaked_elf = Dart_LoadELF(
        patch_path.c_str(), 
        elf_file_offset,  // ← Key: load from offset
        &error,
        &ignored_vm_data,      // VM snapshot unchanged
        &ignored_vm_instrs,    // VM snapshot unchanged
        &isolate_data,         // ← Patch isolate data
        &isolate_instrs,       // ← Patch isolate instructions
        false  // read-only, not executable
      );
    }
    
    // Return appropriate symbol
    if (native_library_symbol_name == DartSnapshot::kIsolateDataSymbol) {
      return std::make_unique<fml::NonOwnedMapping>(isolate_data, 0, nullptr, true);
    } else if (native_library_symbol_name == DartSnapshot::kIsolateInstructionsSymbol) {
      return std::make_unique<fml::NonOwnedMapping>(isolate_instrs, 0, nullptr, true);
    }
  }
#endif
```

**Critical Insights**:
1. VM snapshot **never changes** (same Dart version)
2. Only isolate snapshot changes (app code)
3. ELF is "leaked" intentionally to keep memory valid
4. Uses standard Dart `Dart_LoadELF()` function

### 3. The Linker Process

From `shorebirdtech/shorebird` CLI code:

```dart
// apple.dart lines 297-327
Future<double?> link({
  required String base,           // App.framework/App (Mach-O)
  required String patch,          // out.aot (ELF)
  required String analyzeSnapshot,
  required String genSnapshot,
  required String kernel,         // app.dill
  required String outputPath,     // out.vmcode
}) async {
  // Uses proprietary aot_tools executable
  final result = await aotTools.link(
    base: base,
    patch: patch,
    analyzeSnapshot: analyzeSnapshot,
    genSnapshot: genSnapshot,
    kernel: kernel,
    outputPath: outputPath,
  );
  
  return result.linkPercentage; // % of code shared
}
```

**What the linker does**:
1. Parses release AOT (App.framework/App)
2. Parses patch AOT (out.aot)
3. Uses `analyze_snapshot` to compare
4. Generates differential (only changed code)
5. Writes ELF with custom header
6. Result: `.vmcode` file 10x smaller

### 4. Supplement Files

The linker requires these additional files:
- `App.ct.link` - Class table link info
- `App.class_table.json` - Class table data
- `App.ft.link` - Field table link info
- `App.field_table.json` - Field table data
- `App.dt.link` - Dispatch table link info
- `App.dispatch_table.json` - Dispatch table data

These are copied from release build to patch build directory.

## Implementation Plan

### Phase 1: Reverse-Engineer Header Format (Week 1)

**Goal**: Understand the custom header structure

**Steps**:
1. Download Shorebird CLI
2. Create a test Flutter app
3. Generate a `.vmcode` patch
4. Hex dump the file
5. Identify header structure

**Expected header fields**:
- Magic number (signature)
- Version number
- ELF offset
- Checksum/hash?
- Metadata?

**Command to generate test patch**:
```bash
# Install Shorebird
curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash

# Create test app
flutter create test_app
cd test_app
shorebird init

# Create release
shorebird release ios

# Make a small change
echo "// Modified" >> lib/main.dart

# Generate patch (creates .vmcode file)
shorebird patch ios
```

**Analyze the .vmcode file**:
```bash
hexdump -C build/out.vmcode | head -n 50
```

### Phase 2: Implement Header Reading (Week 1-2)

**File**: `engine/src/shell/common/quicui/quicui.h`

```cpp
#ifndef FLUTTER_SHELL_COMMON_QUICUI_QUICUI_H_
#define FLUTTER_SHELL_COMMON_QUICUI_QUICUI_H_

#include <stdint.h>
#include <stddef.h>

// Reads QuicUI patch header and returns offset to ELF data
extern "C" int QuicUI_ReadLinkHeader(const uint8_t* data, size_t size);

// Stores base snapshots for mixed mode patching
extern "C" void QuicUI_SetBaseSnapshots(
  const uint8_t* isolate_data,
  const uint8_t* isolate_instructions,
  const uint8_t* vm_data,
  const uint8_t* vm_instructions
);

#endif  // FLUTTER_SHELL_COMMON_QUICUI_QUICUI_H_
```

**File**: `engine/src/shell/common/quicui/quicui.cc`

```cpp
#include "flutter/shell/common/quicui/quicui.h"
#include <cstring>

// TODO: Reverse-engineer actual format
struct QuicUIHeader {
  uint32_t magic;      // Magic number
  uint32_t version;    // Format version
  uint32_t elf_offset; // Offset to ELF data
  uint32_t checksum;   // Header checksum
};

extern "C" int QuicUI_ReadLinkHeader(const uint8_t* data, size_t size) {
  if (size < sizeof(QuicUIHeader)) {
    return -1;
  }
  
  const QuicUIHeader* header = reinterpret_cast<const QuicUIHeader*>(data);
  
  // TODO: Validate magic number
  // TODO: Validate checksum
  // TODO: Validate offset < size
  
  return static_cast<int>(header->elf_offset);
}

// Storage for base snapshots
static const uint8_t* base_isolate_data = nullptr;
static const uint8_t* base_isolate_instrs = nullptr;
static const uint8_t* base_vm_data = nullptr;
static const uint8_t* base_vm_instrs = nullptr;

extern "C" void QuicUI_SetBaseSnapshots(
  const uint8_t* isolate_data,
  const uint8_t* isolate_instructions,
  const uint8_t* vm_data,
  const uint8_t* vm_instructions
) {
  base_isolate_data = isolate_data;
  base_isolate_instrs = isolate_instructions;
  base_vm_data = vm_data;
  base_vm_instrs = vm_instructions;
}
```

### Phase 3: Modify Engine (Week 2)

**File**: `engine/src/runtime/dart_snapshot.cc`

Add after line 58:

```cpp
#if QUICUI_CODE_PUSH
#include "flutter/shell/common/quicui/quicui.h"

// Detect QuicUI patch files
static bool IsQuicUIPatch(const std::string& path) {
  return path.find(".vmcode") != std::string::npos ||
         path.find(".quicui") != std::string::npos;
}

// Load QuicUI patch ELF
static Dart_LoadedElf* LoadQuicUIPatchElf(const std::string& patch_path,
                                          const uint8_t** isolate_data,
                                          const uint8_t** isolate_instrs) {
  static Dart_LoadedElf* cached_elf = nullptr;
  
  if (cached_elf != nullptr) {
    return cached_elf;
  }
  
  // Read patch file
  auto elf_mapping = GetFileMapping(patch_path, false);
  if (!elf_mapping) {
    FML_LOG(ERROR) << "Failed to map patch file: " << patch_path;
    return nullptr;
  }
  
  // Read custom header to get ELF offset
  int elf_offset = QuicUI_ReadLinkHeader(
    elf_mapping->GetMapping(),
    elf_mapping->GetSize()
  );
  
  if (elf_offset < 0) {
    FML_LOG(ERROR) << "Failed to read QuicUI header from: " << patch_path;
    return nullptr;
  }
  
  // Load ELF from offset
  const char* error = nullptr;
  const uint8_t* ignored_vm_data = nullptr;
  const uint8_t* ignored_vm_instrs = nullptr;
  
  cached_elf = Dart_LoadELF(
    patch_path.c_str(),
    elf_offset,
    &error,
    &ignored_vm_data,
    &ignored_vm_instrs,
    isolate_data,
    isolate_instrs,
    false  // load as read-only
  );
  
  if (cached_elf == nullptr) {
    FML_LOG(ERROR) << "Failed to load ELF from patch: " << error;
    return nullptr;
  }
  
  FML_LOG(INFO) << "Successfully loaded QuicUI patch from: " << patch_path;
  return cached_elf;
}
#endif  // QUICUI_CODE_PUSH
```

Then modify the `SearchMapping` function around line 80:

```cpp
static std::shared_ptr<const fml::Mapping> SearchMapping(
    const MappingCallback& embedder_mapping_callback,
    const std::string& file_path,
    const std::vector<std::string>& native_library_path,
    const char* native_library_symbol_name,
    bool is_executable) {
    
#if QUICUI_CODE_PUSH
  // Check if this is a QuicUI patch
  if (!native_library_path.empty()) {
    auto patch_path = native_library_path.front();
    if (IsQuicUIPatch(patch_path)) {
      static const uint8_t* isolate_data = nullptr;
      static const uint8_t* isolate_instrs = nullptr;
      
      if (isolate_data == nullptr) {
        LoadQuicUIPatchElf(patch_path, &isolate_data, &isolate_instrs);
      }
      
      // Return appropriate symbol
      if (native_library_symbol_name == DartSnapshot::kIsolateDataSymbol) {
        return std::make_unique<fml::NonOwnedMapping>(isolate_data, 0, nullptr, true);
      } else if (native_library_symbol_name == DartSnapshot::kIsolateInstructionsSymbol) {
        return std::make_unique<fml::NonOwnedMapping>(isolate_instrs, 0, nullptr, true);
      }
      
      // Fall through for VM symbols (unchanged)
    }
  }
#endif  // QUICUI_CODE_PUSH
  
  // Original code continues...
```

### Phase 4: Build Configuration (Week 2)

**File**: `engine/src/BUILD.gn`

Add QuicUI source files:

```gn
source_set("quicui") {
  sources = [
    "shell/common/quicui/quicui.h",
    "shell/common/quicui/quicui.cc",
  ]
  
  defines = [ "QUICUI_CODE_PUSH=1" ]
}

# Add to flutter_engine dependencies
deps += [ ":quicui" ]
```

### Phase 5: Testing (Week 3)

**Test Plan**:
1. Build modified engine
2. Use Shorebird to generate a `.vmcode` patch
3. Place patch in app's Documents directory
4. Modify `FlutterDartProject.mm` to load it
5. Verify app launches and patch code executes

**Test command**:
```bash
# Build engine
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src
./flutter/tools/gn --ios --unoptimized
ninja -C out/ios_debug_unopt

# Build test app with modified engine
flutter build ios --local-engine-src-path=/path/to/engine/src \
  --local-engine=ios_debug_unopt
```

### Phase 6: Build the Linker (Weeks 4-6)

**This is the hardest part**. Two options:

**Option A: Use Shorebird's aot_tools** (if licensing allows)
- Extract their binary
- Call it from our tooling
- Fastest path to working solution

**Option B: Build our own linker**
- Parse ELF files (use LIEF library)
- Analyze AOT snapshots
- Calculate differential
- Generate output ELF
- Add custom header

## Next Steps

1. **Generate a Shorebird patch** to examine
2. **Reverse-engineer the header format**
3. **Implement header reading**
4. **Test with Shorebird-generated patches first**
5. **Then build our own linker**

## Quick Win: Test With Shorebird Patches

Before building everything, we can test the engine modifications:

1. Install Shorebird
2. Create a Flutter app
3. Generate a release and patch with Shorebird
4. Copy the `.vmcode` file
5. Modify our engine to load it
6. Verify it works

This validates our understanding before investing in the linker.

## Resources

- Shorebird Engine: https://github.com/shorebirdtech/engine
- Shorebird CLI: https://github.com/shorebirdtech/shorebird
- LIEF (ELF manipulation): https://lief-project.github.io
- Dart `Dart_LoadELF` docs: In Dart SDK source
