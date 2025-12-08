# QuicUI Shorebird-Style Interpreter Implementation

## Overview

This document describes the complete iOS code push implementation using a Shorebird-style ARM64 simulator interpreter approach. This enables hot updates on iOS without violating App Store policies by executing patch code as DATA rather than as executable code.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         iOS Application                              │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────────────────────────────┐ │
│  │   Dispatch      │    │           Patch Manager                 │ │
│  │   Table         │◄───┤  - Download patch                       │ │
│  │                 │    │  - Compare link info                    │ │
│  │  ┌───────────┐  │    │  - Identify changed functions           │ │
│  │  │ func_1    │──┼────┤  - Patch dispatch table                 │ │
│  │  ├───────────┤  │    └─────────────────────────────────────────┘ │
│  │  │ func_2    │──┼──────────┐                                     │
│  │  ├───────────┤  │          │                                     │
│  │  │ func_3*   │──┼──┐       │                                     │
│  │  │ (patched) │  │  │       ▼                                     │
│  │  ├───────────┤  │  │    ┌──────────────────────────────────────┐ │
│  │  │   ...     │  │  │    │        Original Code                 │ │
│  │  └───────────┘  │  │    │   (Executable in __TEXT)             │ │
│  └─────────────────┘  │    └──────────────────────────────────────┘ │
│                       │                                             │
│                       ▼                                             │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │              CPU to Simulator Wrapper Stub                      │ │
│  │  1. Save CPU registers (x0-x30, sp, pc, flags)                  │ │
│  │  2. Call WrapperManager::RegisterCPUToSimWrapper()              │ │
│  │  3. Invoke Simulator::Call() with patch code address            │ │
│  │  4. Simulator reads patch code as DATA                          │ │
│  │  5. Restore CPU registers                                       │ │
│  │  6. Return result to caller                                     │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                       │                                             │
│                       ▼                                             │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │              ARM64 Simulator (Interpreter)                      │ │
│  │                                                                 │ │
│  │  - Fetches instructions from patch data (read-only)             │ │
│  │  - Decodes ARM64 instructions                                   │ │
│  │  - Emulates execution (ALU, memory, branches)                   │ │
│  │  - Handles calls back to native code (CPU stubs)                │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                       │                                             │
│                       ▼                                             │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │                    Patch Data File                              │ │
│  │              (Loaded as read-only DATA)                         │ │
│  │                                                                 │ │
│  │  ┌───────────────────────────────────────────────────────────┐  │ │
│  │  │ Header: magic, version, function_count                    │  │ │
│  │  ├───────────────────────────────────────────────────────────┤  │ │
│  │  │ Link Info: function IDs, hashes, entry points             │  │ │
│  │  ├───────────────────────────────────────────────────────────┤  │ │
│  │  │ Code Section: ARM64 instructions (as raw bytes)           │  │ │
│  │  └───────────────────────────────────────────────────────────┘  │ │
│  └─────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## Implementation Files

### Core Engine Files (runtime/vm/quicui/)

| File | Purpose | Status |
|------|---------|--------|
| `wrapper.h` | CPU↔Simulator transition class declarations | ✅ Complete |
| `wrapper.cc` | WrapperManager, CPUToSimulator, SimulatorToCPU implementations | ✅ Complete |
| `linker.h` | Link info structures and linker declarations | ✅ Complete |
| `linker.cc` | Function comparison, AnalyzeAndLink(), redirection table | ✅ Complete |
| `dispatch_patcher.h` | Runtime dispatch table patching | ✅ Complete |
| `link_info_extractor.cc` | Tool to extract link info from snapshots | ✅ Complete |
| `quicui.cc` | Runtime entry points, DEFINE_RUNTIME_ENTRY macros | ✅ Complete |
| `quicui.h` | QuicUI public interface declarations | ✅ Complete |
| `link_info.cc/.h` | Link info data structures | ✅ Complete |
| `wrapper_allocator.cc/.h` | Memory allocation for wrappers | ✅ Complete |

### Modified Engine Files

| File | Modification | Status |
|------|--------------|--------|
| `stub_code_compiler_arm64.cc` | Added QuicUI stubs (GenerateQuicuiResumeInterpreterStub, etc.) | ✅ Complete |
| `runtime_entry_list.h` | Added V(QuicuiResumeInterpreter), V(QuicuiResumeOnSimulator) | ✅ Complete |
| `stub_code_list.h` | Added V(QuicuiResumeInterpreter), V(QuicuiDispatchToPatch), etc. | ✅ Complete |
| `thread.h` | Added quicui_resume_interpreter_stub_, quicui_dispatch_to_patch_stub_ | ✅ Complete |
| `runtime_api.h` | Added quicui_resume_interpreter_stub_offset(), quicui_dispatch_to_patch_stub_offset() | ✅ Complete |
| `runtime_offsets_list.h` | Added FIELD(Thread, quicui_*_stub_offset) entries | ✅ Complete |
| `flutter/tools/gn` | Verified dart_force_simulator=true for iOS release | ✅ Verified |

### Build Files

| File | Purpose | Status |
|------|---------|--------|
| `quicui/BUILD.gn` | QuicUI module build configuration | ✅ Complete |
| `quicui/quicui_sources.gni` | Source file list for VM integration | ✅ Complete |
| `vm/BUILD.gn` | Includes quicui_sources | ✅ Verified |

## Key Components

### 1. Wrapper Classes (wrapper.h/cc)

```cpp
// State preserved during CPU↔Simulator transitions
struct SimulatorState {
  uint64_t registers[31];  // x0-x30
  uint64_t sp;
  uint64_t pc;
  uint64_t pstate;
  double fp_registers[32];
  bool valid;
};

// Manages CPU to Simulator wrapper transitions
class CPUToSimulator {
 public:
  // Execute code on simulator, returns result in x0
  static uint64_t Execute(uintptr_t patch_entry_point,
                          uintptr_t patch_data_base,
                          const SimulatorState& cpu_state);
};

// Singleton manager for wrapper lifecycle
class WrapperManager {
 public:
  static WrapperManager& Instance();
  void RegisterCPUToSimWrapper(uintptr_t wrapper_address,
                               uintptr_t patch_entry_point);
  void InitializeForThread(Thread* thread);
};
```

### 2. Linker Classes (linker.h/cc)

```cpp
// Information about a function for linking
struct FunctionLinkInfo {
  uint32_t function_id;
  uint32_t content_hash;
  uint64_t base_entry_point;
  uint64_t patch_entry_point;
  uint64_t code_size;
  bool is_identical;
  bool needs_simulation;
};

// Compares base and patch snapshots
class QuicuiLinker {
 public:
  // Analyze and produce link info
  bool AnalyzeAndLink(const uint8_t* base_snapshot,
                      size_t base_size,
                      const uint8_t* patch_snapshot,
                      size_t patch_size);
  
  // Get functions that need redirection
  const std::vector<FunctionLinkInfo>& GetLinkResults() const;
  
  // Generate redirection table for runtime
  bool GenerateRedirectionTable(uint8_t* output, size_t* output_size);
};
```

### 3. Dispatch Table Patcher (dispatch_patcher.h)

```cpp
// Patches dispatch table at runtime
class DispatchTablePatcher {
 public:
  bool Initialize(uintptr_t dispatch_table_base, size_t dispatch_table_size);
  bool LoadPatchRedirections(const uint8_t* base_link_info,
                             size_t base_size,
                             const uint8_t* patch_link_info,
                             size_t patch_size);
  bool ApplyPatches(const uint8_t* patch_code_data, size_t patch_code_size);
  bool RevertPatches();
};
```

### 4. Runtime Entries (quicui.cc)

```cpp
// Called when entering a patched function
DEFINE_RUNTIME_ENTRY(QuicuiResumeInterpreter, 2) {
  Thread* thread = Thread::Current();
  uintptr_t patch_entry = arguments.ArgAt<uintptr_t>(0);
  uintptr_t patch_data = arguments.ArgAt<uintptr_t>(1);
  
  // Initialize wrapper manager for this thread
  WrapperManager::Instance().InitializeForThread(thread);
  
  // Get simulator instance
  Simulator* sim = thread->simulator();
  
  // Execute patch code on simulator
  sim->Call(patch_entry, patch_data, 0, 0, 0);
}

// Called when simulator needs to call back to CPU code
DEFINE_RUNTIME_ENTRY(QuicuiResumeOnSimulator, 1) {
  // Handle simulator → CPU → simulator transitions
}
```

### 5. Stub Code (stub_code_compiler_arm64.cc)

```cpp
void StubCodeCompiler::GenerateQuicuiResumeInterpreterStub() {
  // Save all registers
  __ PushPair(R0, R1);
  // ... save x0-x30, sp, lr
  
  // Set up call to runtime
  __ ldr(R0, Address(THR, target::Thread::quicui_resume_interpreter_stub_offset()));
  __ blr(R0);
  
  // Restore registers and return
  __ PopPair(R0, R1);
  __ ret();
}

void StubCodeCompiler::GenerateQuicuiDispatchToPatchStub() {
  // Trampoline for dispatch table entries
  // Loads patch code address and jumps to interpreter
}
```

## Runtime Flow

### 1. Patch Application

```
1. App downloads patch from server
2. QuicuiClient receives patch data
3. Linker compares base and patch link info
4. Identifies changed functions (hash comparison)
5. For each changed function:
   a. Get dispatch table entry
   b. Save original entry point
   c. Replace with wrapper stub address
6. Wrapper stubs point to patch code in DATA segment
```

### 2. Patched Function Execution

```
1. Caller invokes function through dispatch table
2. Dispatch table entry now points to QuicuiDispatchToPatch stub
3. Stub saves CPU state
4. Stub calls QuicuiResumeInterpreter runtime entry
5. Runtime entry:
   a. Gets current thread's simulator
   b. Sets up simulator state from CPU state
   c. Points simulator PC to patch code (as DATA)
   d. Calls Simulator::Call()
6. Simulator interprets ARM64 instructions
7. If patch calls unpatched function:
   a. Simulator calls QuicuiResumeOnCPU stub
   b. Control returns to native execution
   c. After return, resumes simulation
8. When patch function returns:
   a. Simulator stops
   b. Result extracted from simulated x0
   c. CPU state restored
   d. Returns to original caller
```

### 3. Memory Layout

```
┌───────────────────────────────────────┐
│        __TEXT (Executable)            │
│  - Original Dart code                 │
│  - Stub code                          │
│  - QuicUI wrappers                    │
├───────────────────────────────────────┤
│        __DATA (Read-Write)            │
│  - Dispatch table (patched)           │
│  - WrapperManager state               │
│  - Simulator state per thread         │
├───────────────────────────────────────┤
│    Patch Data (Read-Only DATA)        │
│  - Link info header                   │
│  - Function entries                   │
│  - Patch code (ARM64 bytes as data)   │
└───────────────────────────────────────┘
```

## Build Instructions

### 1. Configure Engine Build

```bash
cd engine/src

# Configure for iOS device (ARM64)
flutter/tools/gn \
  --ios \
  --runtime-mode=release \
  --no-lto
```

### 2. Verify dart_force_simulator

The `flutter/tools/gn` file should contain (at line ~562):
```python
# Force simulator for iOS release to enable code push
if args.runtime_mode == 'release' and args.ios:
  dart_flags += ' dart_force_simulator=true'
```

### 3. Build Engine

```bash
ninja -C out/ios_release

# Build gen_snapshot with QuicUI support
ninja -C out/host_release gen_snapshot
```

### 4. Generate Link Info

```bash
# Extract link info from base snapshot
./out/host_release/gen_snapshot_quicui \
  --extract-link-info \
  --input=app.so \
  --output=base_link_info.bin

# Extract from patch snapshot
./out/host_release/gen_snapshot_quicui \
  --extract-link-info \
  --input=patch.so \
  --output=patch_link_info.bin
```

## Testing

### Unit Tests

```bash
# Run QuicUI unit tests
dart test packages/quicui_code_push_client/test/

# Test linker
dart test packages/quicui_compiler/test/linker_test.dart

# Test wrapper
dart test packages/quicui_compiler/test/wrapper_test.dart
```

### Integration Tests

```bash
# Full code push flow test
./scripts/test_patch_generation.sh

# iOS simulator test
./scripts/run_ios_simulator_test.sh
```

## Performance Considerations

1. **Interpreted code is slower**: Expect 10-50x slowdown for simulated functions
2. **Optimize patch size**: Only changed functions are simulated
3. **Cache simulation state**: WrapperManager maintains per-thread state
4. **Minimize transitions**: Frequent CPU↔Simulator switches are expensive

## Security

1. **Patch verification**: All patches signed and verified before application
2. **No executable memory**: Patch code loaded as read-only DATA
3. **Sandbox compliance**: No JIT, no code signing bypass
4. **Rollback capability**: Can revert to original dispatch table

## Future Improvements

1. **Selective simulation**: Only simulate changed basic blocks
2. **Ahead-of-time wrapper generation**: Pre-generate wrappers at build time
3. **Incremental linking**: Support partial patches
4. **Hot reload integration**: Use same mechanism for development

## Related Documentation

- [FLUTTER_MODIFICATIONS.md](docs/FLUTTER_MODIFICATIONS.md) - Flutter engine changes
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Deployment instructions
- [API_DOCUMENTATION.md](API_DOCUMENTATION.md) - Client API reference

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025 | Initial implementation |

