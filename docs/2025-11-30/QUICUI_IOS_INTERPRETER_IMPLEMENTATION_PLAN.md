# QuicUI iOS Code Push - Full Interpreter Implementation Plan

**Date:** November 30, 2025  
**Status:** Planning Phase  
**Goal:** Implement iOS code push exactly like Shorebird using ARM64 CPU simulator

---

## Executive Summary

This document outlines the complete implementation plan to enable iOS code push in QuicUI by using an ARM64 CPU simulator (interpreter) to execute unsigned patch code. This approach mirrors Shorebird's proprietary implementation.

### Key Insight

iOS prohibits executing unsigned code. Shorebird solves this by:
1. Compiling patch code to ARM64 machine code (same as release builds)
2. Loading the patch code as **read-only data** (not executable)
3. Using an ARM64 **CPU simulator** to interpret the machine code instruction-by-instruction
4. ~98% of code runs natively from the signed base app; only ~2% (changed functions) are interpreted

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        QuicUI iOS Code Push Architecture                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                         BUILD TIME (gen_snapshot)                     │   │
│  ├──────────────────────────────────────────────────────────────────────┤   │
│  │                                                                       │   │
│  │  1. Baseline Build:                                                   │   │
│  │     ├── Generate App binary (AOT snapshot)                            │   │
│  │     ├── Generate link info files:                                     │   │
│  │     │   ├── App.class_table.json                                      │   │
│  │     │   ├── App.field_table.json                                      │   │
│  │     │   ├── App.dispatch_table.json                                   │   │
│  │     │   └── App.object_pool.json                                      │   │
│  │     └── Store these for future patch comparison                       │   │
│  │                                                                       │   │
│  │  2. Patch Build:                                                      │   │
│  │     ├── Generate patch AOT snapshot                                   │   │
│  │     ├── Run QuicUI Linker:                                            │   │
│  │     │   ├── Compare base vs patch link info                           │   │
│  │     │   ├── Identify unchanged functions → run natively               │   │
│  │     │   └── Identify changed functions → run on simulator             │   │
│  │     └── Output .vmcode file:                                          │   │
│  │         ├── 64KB header (magic, version, link tables)                 │   │
│  │         └── ELF data (patch snapshot)                                 │   │
│  │                                                                       │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                         RUNTIME (Flutter.framework)                   │   │
│  ├──────────────────────────────────────────────────────────────────────┤   │
│  │                                                                       │   │
│  │  1. App Launch:                                                       │   │
│  │     ├── Load base AOT snapshot (signed, executable)                   │   │
│  │     ├── Check for downloaded .vmcode patch                            │   │
│  │     ├── If patch exists:                                              │   │
│  │     │   ├── Load .vmcode as READ-ONLY data                            │   │
│  │     │   ├── Parse link tables from header                             │   │
│  │     │   ├── Initialize CPU simulator with patch data                  │   │
│  │     │   └── Patch dispatch table to redirect changed functions        │   │
│  │     └── Start Dart isolate                                            │   │
│  │                                                                       │   │
│  │  2. Function Call (unchanged function):                               │   │
│  │     └── Execute natively from signed base app → FULL SPEED            │   │
│  │                                                                       │   │
│  │  3. Function Call (changed/patched function):                         │   │
│  │     ├── Dispatch table redirects to CPUToSimWrapper                   │   │
│  │     ├── Save CPU state (registers, stack)                             │   │
│  │     ├── Enter ARM64 Simulator                                         │   │
│  │     ├── Simulate instructions from patch .vmcode                      │   │
│  │     ├── Exit simulator via SimToCPUWrapper                            │   │
│  │     ├── Restore CPU state                                             │   │
│  │     └── Continue native execution                                     │   │
│  │                                                                       │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Enable ARM64 Simulator in Release Builds

### Status: ✅ COMPLETED

### Changes Made

**File:** `/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/tools/gn`

```python
# ========== QuicUI Modification ==========
# Enable simulator for RELEASE builds to support iOS code push.
# Original condition was debug-only, modified to include release.
# ==========================================
# Make the Dart VM include a simulator, even though it is generating arm64
# code on an arm64 device, so that it can fall back to interpreting the arm64
# code if the device does not support JITing.
if (runtime_mode == 'debug' or runtime_mode == 'release') and gn_args[
    'target_os'] == 'ios' and not gn_args['use_ios_simulator'] and gn_args[
        'target_cpu'] == 'arm64' and gn_args['dart_target_arch'] == 'arm64':
  gn_args['dart_force_simulator'] = True
```

### What This Enables

When `dart_force_simulator = True`:
- Adds `DART_INCLUDE_SIMULATOR` define to the build
- Compiles `runtime/vm/simulator_arm64.cc` into the Dart runtime
- Enables `Simulator::Call()` for executing ARM64 code through simulation

---

## Phase 2: Implement Wrapper/Trampoline Infrastructure

### Status: 🔲 NOT STARTED

### Overview

Wrappers are small code stubs that transition between:
- **CPUToSimWrapper**: Native CPU → Simulator (when calling patched function)
- **SimToCPUWrapper**: Simulator → Native CPU (when returning from patched function)

### Files to Create/Modify

#### 2.1 Create `vm/quicui/wrapper.cc`

```cpp
// Copyright (c) 2025 QuicUI Authors. All rights reserved.

#include "vm/quicui/wrapper.h"
#include "vm/simulator.h"
#include "vm/thread.h"

namespace dart {
namespace quicui {

// Thread-local storage for simulator state during transitions
thread_local SimulatorState* current_sim_state_ = nullptr;

// CPUToSimulator: Transition from native execution to simulator
// Called when a patched function is invoked
class CPUToSimulator {
 public:
  explicit CPUToSimulator(Thread* thread, uword target_pc);
  ~CPUToSimulator();
  
  // Execute the target function on the simulator
  int64_t Execute(int64_t arg0, int64_t arg1, int64_t arg2, int64_t arg3);
  
  // Check if currently simulating
  bool IsSimulating(uword pc) const;
  
 private:
  Thread* thread_;
  Simulator* simulator_;
  uword target_pc_;
  bool is_resuming_;
};

// SimulatorToCPU: Transition from simulator back to native execution
// Called when patched function calls an unchanged function
class SimulatorToCPU {
 public:
  explicit SimulatorToCPU(Simulator* simulator, uword target_pc);
  ~SimulatorToCPU();
  
  // Execute native code and return to simulator
  int64_t Execute(int64_t arg0, int64_t arg1, int64_t arg2, int64_t arg3);
  
 private:
  Simulator* simulator_;
  uword target_pc_;
  uword saved_pc_;
};

}  // namespace quicui
}  // namespace dart
```

#### 2.2 Create `vm/quicui/wrapper.h`

```cpp
#ifndef RUNTIME_VM_QUICUI_WRAPPER_H_
#define RUNTIME_VM_QUICUI_WRAPPER_H_

#include "vm/globals.h"
#include "platform/allocation.h"

namespace dart {

class Simulator;
class Thread;

namespace quicui {

// Configuration for CPU-to-Simulator wrapper
struct CPUToSimConfig {
  static constexpr intptr_t kWrapperSize = 128;  // bytes per wrapper
  static constexpr intptr_t kMaxWrappers = 4096;
};

// Configuration for Simulator-to-CPU wrapper
struct SimToCPUConfig {
  static constexpr intptr_t kWrapperSize = 128;
  static constexpr intptr_t kMaxWrappers = 4096;
};

// Wrapper layout template for generating transition stubs
template <typename Config>
class WrapperLayout {
 public:
  static constexpr intptr_t kWrapperSize = Config::kWrapperSize;
  
  static const uint8_t* GetWrapper(size_t index);
  static size_t GetWrapperCount();
};

// Forward declarations
class CPUToSimulator;
class SimulatorToCPU;

// Initialize wrapper infrastructure
void InitializeWrappers();

// Get wrapper for transitioning to target address
uword GetCPUToSimWrapper(uword target_pc);
uword GetSimToCPUWrapper(uword target_pc);

}  // namespace quicui
}  // namespace dart

#endif  // RUNTIME_VM_QUICUI_WRAPPER_H_
```

#### 2.3 Modify `compiler/assembler_arm64.cc`

Add QuicUI-specific assembler helpers:

```cpp
// ========== QuicUI Addition ==========
void Assembler::QuicuiEnterCFrame() {
  // Save all callee-saved registers for C frame entry
  // This is called when transitioning from simulator to native runtime calls
  
  // Save frame pointer and link register
  stp(FP, LR, Address(SP, -2 * kWordSize, Address::PreIndex));
  
  // Set up new frame pointer
  mov(FP, SP);
  
  // Save all callee-saved registers (X19-X28)
  for (int i = 19; i <= 28; i++) {
    str(Register(i), Address(SP, -(i - 18) * kWordSize, Address::PreIndex));
  }
  
  // Save SIMD registers if needed
  // ...
}

void Assembler::QuicuiLeaveCFrame() {
  // Restore all callee-saved registers
  for (int i = 28; i >= 19; i--) {
    ldr(Register(i), Address(SP, (28 - i + 1) * kWordSize, Address::PostIndex));
  }
  
  // Restore frame pointer and link register
  ldp(FP, LR, Address(SP, 2 * kWordSize, Address::PostIndex));
}
// ==========================================
```

---

## Phase 3: Implement StubCode Generator Stubs

### Status: 🔲 NOT STARTED

### Overview

StubCode stubs are pre-compiled assembly routines that handle specific runtime operations. We need to add stubs for interpreter transitions.

### Files to Modify

#### 3.1 Modify `compiler/stub_code_compiler_arm64.cc`

```cpp
// ========== QuicUI Addition ==========

// Stub that resumes execution on the interpreter (simulator)
// Called when returning to a patched function
void StubCodeCompiler::GenerateResumeInterpreterStub() {
  // R0: Thread
  // R1: Target PC in patch code
  
  // Save current native state
  __ QuicuiEnterCFrame();
  
  // Load simulator instance
  __ ldr(R2, Address(R0, Thread::quicui_simulator_offset()));
  
  // Set simulator PC to target
  __ str(R1, Address(R2, Simulator::pc_offset()));
  
  // Call Simulator::Run()
  __ ldr(R3, Address(R2, Simulator::run_entry_offset()));
  __ blr(R3);
  
  // Restore native state
  __ QuicuiLeaveCFrame();
  
  // Return result from R0
  __ ret();
}

// Stub that resumes execution on the real CPU
// Called when simulator needs to call native code
void StubCodeCompiler::GenerateResumeOnCPUStub() {
  // R0: Target native PC
  // R1-R7: Arguments
  
  // Save simulator state to thread
  __ ldr(R8, Address(THR, Thread::quicui_simulator_offset()));
  __ str(LR, Address(R8, Simulator::saved_lr_offset()));
  
  // Jump to native code
  __ br(R0);
  
  // (Control returns here when native code returns)
  
  // Restore simulator state
  __ ldr(R8, Address(THR, Thread::quicui_simulator_offset()));
  __ ldr(LR, Address(R8, Simulator::saved_lr_offset()));
  
  // Return to simulator
  __ ret();
}

// Stub that resumes execution on the simulator
// Called after native code returns to patch code
void StubCodeCompiler::GenerateResumeOnSimulatorStub() {
  // Save return value
  __ Push(R0);
  
  // Get simulator instance
  __ ldr(R1, Address(THR, Thread::quicui_simulator_offset()));
  
  // Set simulator's R0 to return value
  __ Pop(R2);
  __ str(R2, Address(R1, Simulator::register_offset(R0)));
  
  // Resume simulator execution
  __ ldr(R3, Address(R1, Simulator::resume_entry_offset()));
  __ br(R3);
}

// ==========================================
```

#### 3.2 Add Stub Entries in `stub_code_list.h`

```cpp
// In stub_code_list.h, add to the RUNTIME_ENTRY_LIST:
V(ResumeInterpreter)
V(ResumeOnCPU)
V(ResumeOnSimulator)
```

---

## Phase 4: Implement Runtime Entry Points

### Status: 🔲 NOT STARTED

### Overview

Runtime entries are C++ functions that can be called from generated code. They handle complex operations that can't be done in assembly.

### Files to Modify

#### 4.1 Modify `vm/quicui/quicui.cc`

```cpp
// Add to vm/quicui/quicui.cc

#include "vm/runtime_entry.h"
#include "vm/simulator.h"

namespace dart {

// Runtime entry for resuming the interpreter
// Called when transitioning from native code to simulated patch code
DEFINE_RUNTIME_ENTRY(ResumeInterpreter, 2) {
  Thread* thread = Thread::Current();
  uword target_pc = arguments.ArgAt<uword>(0);
  uword saved_sp = arguments.ArgAt<uword>(1);
  
  // Get or create simulator for this thread
  Simulator* sim = thread->quicui_simulator();
  if (sim == nullptr) {
    sim = new Simulator();
    thread->set_quicui_simulator(sim);
  }
  
  // Set up simulator state
  sim->set_register(SP, saved_sp);
  sim->set_pc(target_pc);
  
  // Run simulator until it hits a native call or returns
  int64_t result = sim->Run();
  
  // Return result in R0
  arguments.SetReturn(Integer::Handle(Integer::New(result)));
}

// Runtime entry for calling native code from simulator
DEFINE_RUNTIME_ENTRY(SimulatorCallNative, 5) {
  Thread* thread = Thread::Current();
  uword target_pc = arguments.ArgAt<uword>(0);
  int64_t arg0 = arguments.ArgAt<int64_t>(1);
  int64_t arg1 = arguments.ArgAt<int64_t>(2);
  int64_t arg2 = arguments.ArgAt<int64_t>(3);
  int64_t arg3 = arguments.ArgAt<int64_t>(4);
  
  // Save simulator state
  Simulator* sim = thread->quicui_simulator();
  SimulatorState saved_state;
  sim->SaveState(&saved_state);
  
  // Call native function
  typedef int64_t (*NativeFunction)(int64_t, int64_t, int64_t, int64_t);
  NativeFunction fn = reinterpret_cast<NativeFunction>(target_pc);
  int64_t result = fn(arg0, arg1, arg2, arg3);
  
  // Restore simulator state and set result
  sim->RestoreState(&saved_state);
  sim->set_register(R0, result);
  
  arguments.SetReturn(Integer::Handle(Integer::New(result)));
}

// Declare runtime entries
DECLARE_RUNTIME_ENTRY(ResumeInterpreter);
DECLARE_RUNTIME_ENTRY(SimulatorCallNative);

}  // namespace dart
```

#### 4.2 Add Thread Fields for Simulator

Modify `vm/thread.h`:

```cpp
// Add to Thread class private members:
Simulator* quicui_simulator_ = nullptr;

// Add public accessors:
Simulator* quicui_simulator() const { return quicui_simulator_; }
void set_quicui_simulator(Simulator* sim) { quicui_simulator_ = sim; }

// Add offset getter:
static intptr_t quicui_simulator_offset() {
  return OFFSET_OF(Thread, quicui_simulator_);
}
```

---

## Phase 5: Implement Linker for Patch Comparison

### Status: 🔲 NOT STARTED

### Overview

The linker compares base and patch snapshots to determine which functions can run natively (unchanged) and which need simulation (changed).

### Files to Modify

#### 5.1 Enhance `vm/quicui/linker.cc`

```cpp
// Add to linker.cc

#include "vm/object.h"
#include "vm/code_descriptors.h"

namespace dart {
namespace quicui {

// Structure to hold function comparison results
struct FunctionLinkInfo {
  uword base_entry_point;
  uword patch_entry_point;
  bool is_identical;  // True if function code is same in base and patch
  bool needs_simulation;  // True if function must run on simulator
};

// Compare two functions and determine if they're identical
bool QuicuiLinker::CompareFunctions(const Code& base_code,
                                    const Code& patch_code) {
  if (base_code.Size() != patch_code.Size()) {
    return false;
  }
  
  // Compare instruction bytes
  const uint8_t* base_instrs = 
      reinterpret_cast<const uint8_t*>(base_code.PayloadStart());
  const uint8_t* patch_instrs =
      reinterpret_cast<const uint8_t*>(patch_code.PayloadStart());
  
  return memcmp(base_instrs, patch_instrs, base_code.Size()) == 0;
}

// Analyze all functions and build link tables
void QuicuiLinker::AnalyzeAndLink(const ObjectPool& base_pool,
                                  const ObjectPool& patch_pool) {
  // Iterate through dispatch table entries
  const DispatchTable& base_dispatch = base_pool.dispatch_table();
  const DispatchTable& patch_dispatch = patch_pool.dispatch_table();
  
  intptr_t num_entries = base_dispatch.Length();
  link_results_.reserve(num_entries);
  
  for (intptr_t i = 0; i < num_entries; i++) {
    FunctionLinkInfo info;
    
    Code& base_code = Code::Handle(base_dispatch.CodeAt(i));
    Code& patch_code = Code::Handle(patch_dispatch.CodeAt(i));
    
    info.base_entry_point = base_code.PayloadStart();
    info.patch_entry_point = patch_code.PayloadStart();
    info.is_identical = CompareFunctions(base_code, patch_code);
    info.needs_simulation = !info.is_identical;
    
    link_results_.push_back(info);
    
    if (info.is_identical) {
      native_function_count_++;
      MarkNativeFunction(info.base_entry_point);
    } else {
      simulated_function_count_++;
    }
  }
  
  // Calculate link percentage
  link_percentage_ = static_cast<double>(native_function_count_) /
                     static_cast<double>(num_entries);
  
  initialized_ = true;
}

// Generate redirection table for patched functions
void QuicuiLinker::GenerateRedirectionTable(uint8_t* output_buffer,
                                            size_t buffer_size) {
  // Format: [num_entries:4][entries...]
  // Entry: [base_entry_point:8][redirect_target:8]
  
  uint32_t num_entries = simulated_function_count_;
  memcpy(output_buffer, &num_entries, sizeof(num_entries));
  
  size_t offset = sizeof(num_entries);
  
  for (const auto& info : link_results_) {
    if (info.needs_simulation) {
      // Write base entry point
      memcpy(output_buffer + offset, &info.base_entry_point, 8);
      offset += 8;
      
      // Write patch entry point (simulator target)
      memcpy(output_buffer + offset, &info.patch_entry_point, 8);
      offset += 8;
    }
  }
}

}  // namespace quicui
}  // namespace dart
```

---

## Phase 6: Modify gen_snapshot for Link Info Output

### Status: 🔲 NOT STARTED

### Overview

gen_snapshot must output link information files that are used during patch generation.

### Files to Modify

#### 6.1 Modify `vm/clustered_snapshot.cc`

Add link info serialization after snapshot generation:

```cpp
// Add to Serializer::Serialize()

#if defined(QUICUI_USE_INTERPRETER)
  // Output link info for QuicUI patching
  if (FLAG_quicui_output_link_info) {
    OutputClassTableLinkInfo(output_path + ".class_table.json");
    OutputFieldTableLinkInfo(output_path + ".field_table.json");
    OutputDispatchTableLinkInfo(output_path + ".dispatch_table.json");
    OutputObjectPoolLinkInfo(output_path + ".object_pool.json");
  }
#endif
```

#### 6.2 Add Link Info Output Functions

```cpp
void Serializer::OutputDispatchTableLinkInfo(const char* path) {
  JSONWriter writer;
  writer.OpenObject();
  
  writer.OpenArray("entries");
  
  const DispatchTable& table = isolate_group()->dispatch_table();
  for (intptr_t i = 0; i < table.Length(); i++) {
    Code& code = Code::Handle(table.CodeAt(i));
    Function& func = Function::Handle(code.function());
    
    writer.OpenObject();
    writer.PrintProperty("index", i);
    writer.PrintProperty("function", func.ToCString());
    writer.PrintProperty("entry_point", code.PayloadStart());
    writer.PrintProperty("size", code.Size());
    writer.PrintPropertyHex("hash", HashCode(code));
    writer.CloseObject();
  }
  
  writer.CloseArray();
  writer.CloseObject();
  
  // Write to file
  Utils::WriteFile(path, writer.ToCString());
}
```

---

## Phase 7: Implement Dispatch Table Patching

### Status: 🔲 NOT STARTED

### Overview

When a patch is loaded, we need to modify the dispatch table to redirect calls to patched functions through the simulator.

### Files to Modify

#### 7.1 Modify `vm/dispatch_table.cc`

```cpp
// Add QuicUI patching support

void DispatchTable::ApplyQuicuiPatch(const QuicuiLinker& linker) {
#if defined(QUICUI_USE_INTERPRETER)
  const auto& link_results = linker.GetLinkResults();
  
  for (const auto& info : link_results) {
    if (info.needs_simulation) {
      // Find the dispatch table entry for this function
      intptr_t index = FindEntryByBaseAddress(info.base_entry_point);
      if (index >= 0) {
        // Get wrapper that redirects to simulator
        uword wrapper = quicui::GetCPUToSimWrapper(info.patch_entry_point);
        
        // Patch the dispatch table entry to point to wrapper
        SetEntryPoint(index, wrapper);
        
        FML_LOG(INFO) << "QuicUI: Patched dispatch entry " << index
                      << " to simulator wrapper";
      }
    }
  }
#endif
}
```

---

## Phase 8: Modify ELF Loader for Read-Only Loading

### Status: 🔲 PARTIALLY DONE

### Overview

The ELF loader must map executable segments as read-only when loading patch files on iOS.

### Files Already Modified

**File:** `runtime/bin/elf_loader.cc`

The `load_as_readonly` parameter has been added to `Dart_LoadELF_Memory()`. When `true`:
- Executable segments (PF_X) are mapped as read-only instead of read-execute
- This allows loading patch code without iOS code signing violations

### Additional Changes Needed

Ensure `dart_snapshot.cc` passes `true` for `load_as_readonly`:

```cpp
// In dart_snapshot.cc SearchMapping()

#if QUICUI_USE_INTERPRETER
  if (is_patch) {
    leaked_elf = Dart_LoadELF_Memory(
        elf_data, elf_size, &error,
        &vm_data, &vm_instrs, &isolate_data, &isolate_instrs,
        true  /* load_as_readonly - CRITICAL for iOS sandbox */
    );
  }
#endif
```

---

## Phase 9: Implement .vmcode File Format

### Status: 🔲 NOT STARTED

### Overview

The .vmcode file contains the patch data and link tables in a format the runtime can parse.

### File Format Specification

```
┌──────────────────────────────────────────────────────┐
│                  .vmcode File Format                  │
├──────────────────────────────────────────────────────┤
│ Offset    │ Size   │ Description                     │
├───────────┼────────┼─────────────────────────────────┤
│ 0x0000    │ 4      │ Magic: "QUIC" (0x43495551)      │
│ 0x0004    │ 4      │ Version: 1                      │
│ 0x0008    │ 4      │ Header size (65536)             │
│ 0x000C    │ 4      │ ELF data offset                 │
│ 0x0010    │ 4      │ Link table offset               │
│ 0x0014    │ 4      │ Link table size                 │
│ 0x0018    │ 4      │ Num redirections                │
│ 0x001C    │ 4      │ Flags                           │
│ 0x0020    │ 8      │ Base snapshot hash              │
│ 0x0028    │ 8      │ Patch snapshot hash             │
│ 0x0030    │ ...    │ Reserved (zero-padded)          │
│ 0x10000   │ var    │ ELF data (patch snapshot)       │
│ EOF-N     │ var    │ Link table (redirection info)   │
└──────────────────────────────────────────────────────┘
```

### Implementation

#### 9.1 Create `tools/quicui_patcher.dart`

```dart
import 'dart:io';
import 'dart:typed_data';

class VmcodeGenerator {
  static const int kMagic = 0x43495551; // "QUIC"
  static const int kVersion = 1;
  static const int kHeaderSize = 65536;
  
  static Future<void> generate({
    required String baseSnapshotPath,
    required String patchSnapshotPath,
    required String baseLinkInfoPath,
    required String patchLinkInfoPath,
    required String outputPath,
  }) async {
    // Load snapshots
    final baseSnapshot = await File(baseSnapshotPath).readAsBytes();
    final patchSnapshot = await File(patchSnapshotPath).readAsBytes();
    
    // Load and compare link info
    final baseLinkInfo = await _loadLinkInfo(baseLinkInfoPath);
    final patchLinkInfo = await _loadLinkInfo(patchLinkInfoPath);
    
    // Generate redirection table
    final redirections = _compareAndGenerateRedirections(
      baseLinkInfo, patchLinkInfo);
    
    // Build .vmcode file
    final vmcode = BytesBuilder();
    
    // Header (64KB)
    final header = Uint8List(kHeaderSize);
    final headerView = ByteData.view(header.buffer);
    
    headerView.setUint32(0x0000, kMagic, Endian.little);
    headerView.setUint32(0x0004, kVersion, Endian.little);
    headerView.setUint32(0x0008, kHeaderSize, Endian.little);
    headerView.setUint32(0x000C, kHeaderSize, Endian.little); // ELF offset
    // ... more header fields
    
    vmcode.add(header);
    
    // ELF data
    vmcode.add(patchSnapshot);
    
    // Link table (at end)
    vmcode.add(_serializeRedirections(redirections));
    
    // Write output
    await File(outputPath).writeAsBytes(vmcode.toBytes());
    
    print('Generated ${outputPath} (${vmcode.length} bytes)');
    print('  - Native functions: ${baseLinkInfo.length - redirections.length}');
    print('  - Simulated functions: ${redirections.length}');
  }
}
```

---

## Phase 10: Build and Integration Testing

### Status: 🔲 NOT STARTED

### Build Steps

```bash
# 1. Navigate to engine source
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src

# 2. Configure build with QuicUI flags
./flutter/tools/gn \
  --ios \
  --runtime-mode=release \
  --no-lto

# 3. Build Flutter.framework
ninja -C out/ios_release Flutter.framework

# 4. Build gen_snapshot
ninja -C out/ios_release gen_snapshot_arm64

# 5. Copy to Flutter SDK cache
cp -R out/ios_release/Flutter.xcframework \
  /path/to/flutter-quicui/bin/cache/artifacts/engine/ios-release/

# 6. Sign the framework
codesign --force --sign - \
  /path/to/flutter-quicui/bin/cache/artifacts/engine/ios-release/Flutter.xcframework/ios-arm64/Flutter.framework/Flutter
```

### Integration Test Plan

1. **Build Baseline App**
   ```bash
   quicui build-ipa --version 1.0.0 --baseline
   ```

2. **Make Code Change**
   - Modify `lib/main.dart`
   - Change theme color or text

3. **Build Patch**
   ```bash
   quicui build-ipa --version 1.0.1
   ```

4. **Generate .vmcode**
   ```bash
   quicui generate-patch \
     --baseline ./baseline/App-v1.0.0 \
     --new ./baseline/App-v1.0.1 \
     --output ./patches/patch_1.0.1.vmcode
   ```

5. **Upload and Download Patch**
   ```bash
   quicui upload-patch --patch ./patches/patch_1.0.1.vmcode
   # App downloads patch on next launch
   ```

6. **Verify**
   - Launch app
   - Confirm patch loads without crash
   - Confirm UI change is visible
   - Check logs for "QuicUI: Running on simulator" messages

---

## Key Symbols Reference (from Shorebird)

### gen_snapshot Symbols
```
dart::ShorebirdLinker::shared()
dart::ShorebirdLinker::InitializeWithClassTableLinkInfo()
dart::ShorebirdLinker::InitializeWithFieldTableLinkInfo()
dart::ShorebirdLinker::InitializeWithDispatchTableLinkInfo()
dart::ShorebirdLinker::InitializeWithObjectPoolLinkInfo()
dart::compiler::Assembler::ShorebirdEnterCFrame()
dart::compiler::Assembler::ShorebirdLeaveCFrame()
dart::compiler::StubCodeCompiler::GenerateResumeInterpreterStub()
dart::shorebird::WrapperAllocator
dart::shorebird::WrapperLayout<CPUToSimConfig>
dart::shorebird::WrapperLayout<SimToCPUConfig>
```

### Flutter.framework Symbols
```
_shorebird_init
_shorebird_next_boot_patch_path
_shorebird_validate_next_boot_patch
CPUToSimWrapper
SimToCPUWrapper
Shorebird_SetBaseSnapshots
Shorebird_ReadLinkHeader
DRT_ResumeInterpreter
```

---

## Estimated Timeline

| Phase | Description | Estimated Effort |
|-------|-------------|------------------|
| 1 | Enable Simulator | ✅ Done |
| 2 | Wrapper Infrastructure | 1-2 weeks |
| 3 | StubCode Stubs | 1 week |
| 4 | Runtime Entries | 1 week |
| 5 | Linker Enhancement | 2 weeks |
| 6 | gen_snapshot Mods | 1 week |
| 7 | Dispatch Table Patching | 1 week |
| 8 | ELF Loader | ✅ Partially done |
| 9 | .vmcode Format | 1 week |
| 10 | Integration Testing | 2 weeks |

**Total Estimated: 10-12 weeks** for a single developer with deep Dart VM knowledge.

---

## Risk Factors

1. **Complexity**: Dart VM is complex; small mistakes cause crashes
2. **Debugging**: Simulator bugs are hard to diagnose
3. **Performance**: Simulated code runs ~10-100x slower than native
4. **Maintenance**: Must update with each Flutter/Dart release
5. **Testing**: Requires extensive testing across all Dart features

---

## Alternative: Partnership with Shorebird

Given the complexity, consider:
- **Licensing**: Pay Shorebird for their technology
- **Partnership**: White-label their solution
- **Hybrid**: Use Shorebird for iOS, custom for Android

Contact: https://shorebird.dev/

---

## Appendix A: Shorebird Binary Analysis

### gen_snapshot_arm64 Location
```
/Users/admin/.shorebird/bin/cache/flutter/5d7eab0b8cc0146649c1c37cd1e1968c97d9e5dd/bin/cache/artifacts/engine/ios-release/gen_snapshot_arm64
```

### Flutter.xcframework Location
```
/Users/admin/.shorebird/bin/cache/flutter/5d7eab0b8cc0146649c1c37cd1e1968c97d9e5dd/bin/cache/artifacts/engine/ios-release/Flutter.xcframework/
```

### Key Source Files (referenced in binaries)
```
flutter/third_party/dart/runtime/vm/shorebird/linker.cc
flutter/third_party/dart/runtime/vm/shorebird/link_info.cc
flutter/third_party/dart/runtime/vm/shorebird/class_table_mapper.cc
flutter/third_party/dart/runtime/vm/shorebird/object_pool_editor.cc
flutter/third_party/dart/runtime/vm/shorebird/object_pool_mapper.cc
flutter/third_party/dart/runtime/vm/shorebird/wrapper.cc
flutter/third_party/dart/runtime/vm/simulator_arm64.cc
flutter/shell/common/shorebird/shorebird.cc
flutter/shell/common/shorebird/snapshots_data_handle.cc
```

---

## Appendix B: QuicUI Current State

### Completed Work
- ✅ Engine fork with QUICUI_USE_INTERPRETER flag
- ✅ ELF loader with load_as_readonly parameter
- ✅ QuicUI linker skeleton (vm/quicui/)
- ✅ Patch loader in Flutter shell
- ✅ dart_snapshot.cc integration for .vmcode loading
- ✅ gn script modification for simulator in release builds

### Missing Work
- ❌ Wrapper/trampoline code
- ❌ StubCode generator stubs
- ❌ Runtime entry points
- ❌ Dispatch table patching
- ❌ Link info output from gen_snapshot
- ❌ .vmcode file generator
- ❌ Full engine rebuild with all components
- ❌ End-to-end testing

---

## Document History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2025-11-30 | 1.0 | QuicUI Team | Initial comprehensive plan |
