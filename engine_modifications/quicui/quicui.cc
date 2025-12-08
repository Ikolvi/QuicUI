// Copyright (c) 2025 QuicUI Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vm/quicui/quicui.h"

#include <cstdio>

#include "vm/quicui/linker.h"
#include "vm/quicui/wrapper.h"
#include "vm/runtime_entry.h"
#include "vm/thread.h"

#if defined(DART_INCLUDE_SIMULATOR)
#include "vm/simulator.h"
#endif

// QuicUI code push enable flag
// Set via QUICUI_USE_INTERPRETER=1 in config.gni
#if defined(QUICUI_USE_INTERPRETER) && QUICUI_USE_INTERPRETER
#define QUICUI_ENABLED 1
#else
#define QUICUI_ENABLED 0
#endif

namespace dart {
namespace quicui {

static bool initialized_ = false;
static intptr_t patch_version_ = 0;

bool IsEnabled() {
#if QUICUI_ENABLED
  return true;
#else
  return false;
#endif
}

void Initialize() {
  if (initialized_) {
    return;
  }

#if QUICUI_ENABLED
  printf("QuicUI: Initializing code push system\n");
  InitializeWrappers();
#endif

  initialized_ = true;
}

void Shutdown() {
  if (!initialized_) {
    return;
  }

#if QUICUI_ENABLED
  printf("QuicUI: Shutting down code push system\n");
  ShutdownWrappers();
  QuicuiLinker::Shared().Reset();
#endif

  initialized_ = false;
  patch_version_ = 0;
}

void PrintInfo() {
  printf("QuicUI stats:\n");
  printf("  Enabled: %s\n", IsEnabled() ? "yes" : "no");
  printf("  Initialized: %s\n", initialized_ ? "yes" : "no");
  printf("  Has patch: %s\n", HasPatch() ? "yes" : "no");
  printf("  Patch version: %ld\n", static_cast<long>(patch_version_));

#if QUICUI_ENABLED
  if (QuicuiLinker::Shared().IsInitialized()) {
    printf("  Has base instructions table: %s\n",
           QuicuiLinker::Shared().GetBaseInstructionsTable() != nullptr
               ? "yes"
               : "no");
  }
#endif
}

bool HasPatch() {
  return patch_version_ > 0;
}

intptr_t GetPatchVersion() {
  return patch_version_;
}

}  // namespace quicui

// ============================================================================
// QuicUI Runtime Entry Points
// ============================================================================
//
// These runtime entries are called from the QuicUI stub code to handle
// CPU <-> Simulator transitions for iOS code push.
// ============================================================================

#if QUICUI_ENABLED

// Runtime entry for entering the interpreter (simulator)
// Called from GenerateQuicuiResumeInterpreterStub
//
// Arguments:
//   Arg0: Target PC in patch code
//   Arg1: Saved SP
//   Arg2: Thread pointer
//
// This function:
// 1. Gets or creates a simulator for this thread
// 2. Sets up the simulator with target PC and arguments
// 3. Runs the simulator until it returns
// 4. Returns the result to the stub
DEFINE_RUNTIME_ENTRY(QuicuiResumeInterpreter, 3) {
  uword target_pc = static_cast<uword>(arguments.ArgAt(0));
  uword saved_sp = static_cast<uword>(arguments.ArgAt(1));
  Thread* thread = reinterpret_cast<Thread*>(arguments.ArgAt(2));
  
  ASSERT(thread != nullptr);
  ASSERT(target_pc != 0);
  
#if defined(DART_INCLUDE_SIMULATOR)
  // Get or create simulator for this thread
  Simulator* sim = Simulator::Current();
  if (sim == nullptr) {
    FATAL("QuicUI: No simulator available for thread");
  }
  
  // The simulator will execute the patch code
  // The actual arguments are already on the stack at saved_sp
  
  // Set up simulator state
  // Note: The stub has already saved the CPU state
  
  // Call into the simulator to execute patch code
  // The simulator will interpret ARM64 instructions from target_pc
  int64_t result = sim->Call(
      static_cast<int64_t>(target_pc),
      0, 0, 0, 0,  // Arguments come from saved stack
      false,  // fp_return
      false   // fp_args
  );
  
  // Return result
  arguments.SetReturn(Integer::Handle(zone, Integer::New(result)));
#else
  FATAL("QuicUI: Simulator not available - cannot interpret patch code");
#endif
}

// Runtime entry for returning to the simulator
// Called from GenerateQuicuiResumeOnSimulatorStub
//
// Arguments:
//   Arg0: Return value from native call
//   Arg1: Thread pointer
//
// This function puts the return value back into the simulator state
DEFINE_RUNTIME_ENTRY(QuicuiResumeOnSimulator, 2) {
  int64_t return_value = static_cast<int64_t>(arguments.ArgAt(0));
  Thread* thread = reinterpret_cast<Thread*>(arguments.ArgAt(1));
  
  ASSERT(thread != nullptr);
  
#if defined(DART_INCLUDE_SIMULATOR)
  Simulator* sim = Simulator::Current();
  if (sim != nullptr) {
    // Put return value in simulator's R0
    sim->set_register(nullptr, R0, return_value);
  }
#endif
  
  // Pass through the return value
  arguments.SetReturn(Integer::Handle(zone, Integer::New(return_value)));
}

#endif  // QUICUI_ENABLED

}  // namespace dart

// ============================================================================
// C API implementations
// ============================================================================

extern "C" {

DART_EXPORT void QuicUI_SetBaseSnapshots(const uint8_t* vm_data,
                                         intptr_t vm_data_size,
                                         const uint8_t* vm_instrs,
                                         intptr_t vm_instrs_size,
                                         const uint8_t* isolate_data,
                                         intptr_t isolate_data_size,
                                         const uint8_t* isolate_instrs,
                                         intptr_t isolate_instrs_size) {
#if QUICUI_ENABLED
  dart::quicui::QuicuiLinker::Shared().SetBaseSnapshots(
      vm_data, vm_data_size, vm_instrs, vm_instrs_size, isolate_data,
      isolate_data_size, isolate_instrs, isolate_instrs_size);
#else
  (void)vm_data;
  (void)vm_data_size;
  (void)vm_instrs;
  (void)vm_instrs_size;
  (void)isolate_data;
  (void)isolate_data_size;
  (void)isolate_instrs;
  (void)isolate_instrs_size;
#endif
}

DART_EXPORT bool QuicUI_ReadLinkHeader(const uint8_t* data,
                                       intptr_t data_size,
                                       intptr_t* header_size,
                                       intptr_t* link_data_offset) {
#if QUICUI_ENABLED
  return dart::quicui::QuicuiLinker::ReadLinkHeader(data, data_size,
                                                     header_size,
                                                     link_data_offset);
#else
  (void)data;
  (void)data_size;
  (void)header_size;
  (void)link_data_offset;
  return false;
#endif
}

DART_EXPORT const uint8_t* QuicUI_GetBaseInstructionsTable() {
#if QUICUI_ENABLED
  return dart::quicui::QuicuiLinker::Shared().GetBaseInstructionsTable();
#else
  return nullptr;
#endif
}

DART_EXPORT intptr_t QuicUI_GetBaseInstructionsTableSize() {
#if QUICUI_ENABLED
  return dart::quicui::QuicuiLinker::Shared().GetBaseInstructionsTableSize();
#else
  return 0;
#endif
}

DART_EXPORT bool QuicUI_IsInitialized() {
#if QUICUI_ENABLED
  return dart::quicui::QuicuiLinker::Shared().IsInitialized();
#else
  return false;
#endif
}

DART_EXPORT double QuicUI_GetLinkPercentage() {
#if QUICUI_ENABLED
  return dart::quicui::QuicuiLinker::Shared().GetLinkPercentage();
#else
  return 0.0;
#endif
}

DART_EXPORT void QuicUI_PrintStats() {
#if QUICUI_ENABLED
  dart::quicui::QuicuiLinker::Shared().PrintStats();
#endif
}

DART_EXPORT void QuicUI_Initialize() {
  dart::quicui::Initialize();
}

DART_EXPORT void QuicUI_Shutdown() {
  dart::quicui::Shutdown();
}

}  // extern "C"
