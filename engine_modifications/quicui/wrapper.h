// Copyright (c) 2025 QuicUI Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef RUNTIME_VM_QUICUI_WRAPPER_H_
#define RUNTIME_VM_QUICUI_WRAPPER_H_

#include "platform/globals.h"
#include "vm/allocation.h"

#if defined(DART_INCLUDE_SIMULATOR)
#include "vm/simulator.h"
#endif

namespace dart {

class Thread;

namespace quicui {

// ============================================================================
// QuicUI Wrapper Infrastructure
// ============================================================================
//
// This module implements CPU <-> Simulator transition wrappers for iOS code 
// push. On iOS, patched code cannot be executed directly (code signing), so
// we use the ARM64 simulator to interpret it.
//
// Transitions:
//   CPUToSimulator: Native code calls a patched function
//                   -> Save CPU state, enter simulator, interpret patch code
//
//   SimulatorToCPU: Patched function calls an unchanged native function
//                   -> Exit simulator, restore CPU state, call native, return
//
// This is modeled after Shorebird's implementation.
// ============================================================================

// Forward declarations
class CPUToSimulator;
class SimulatorToCPU;

// ============================================================================
// SimulatorState - Saved state for CPU/Simulator transitions
// ============================================================================
struct SimulatorState {
  // General purpose registers (X0-X30)
  int64_t registers[31];
  
  // Stack pointer
  int64_t sp;
  
  // Program counter
  int64_t pc;
  
  // Link register (for returns)
  int64_t lr;
  
  // SIMD/FP registers (V0-V31)
  struct {
    int64_t d[2];
  } vregisters[32];
  
  // Condition flags
  bool n_flag;
  bool z_flag;
  bool c_flag;
  bool v_flag;
  
  // Thread pointer
  Thread* thread;
  
  // Whether we're currently simulating
  bool is_simulating;
  
  // Nesting depth (for nested transitions)
  int32_t depth;
};

// ============================================================================
// CPUToSimulator - Transitions from native CPU to simulator
// ============================================================================
//
// When native code needs to call a patched function, this class:
// 1. Saves the current CPU state
// 2. Sets up the simulator with the target PC
// 3. Runs the simulator until it returns or calls native code
// 4. Restores CPU state and returns the result
//
class CPUToSimulator : public ValueObject {
 public:
  // Create a transition to the given target PC in patch code
  CPUToSimulator(Thread* thread, uword target_pc);
  ~CPUToSimulator();
  
  // Execute the patched function with given arguments
  // Returns the function result (typically in R0)
  int64_t Execute(int64_t arg0 = 0,
                  int64_t arg1 = 0,
                  int64_t arg2 = 0,
                  int64_t arg3 = 0,
                  int64_t arg4 = 0,
                  int64_t arg5 = 0,
                  int64_t arg6 = 0,
                  int64_t arg7 = 0);
  
  // Check if a given PC is in simulated code
  static bool IsSimulating(uword pc);
  
  // Get the saved state
  const SimulatorState& saved_state() const { return saved_state_; }
  
 private:
  Thread* thread_;
  uword target_pc_;
  SimulatorState saved_state_;
  bool entered_;
  
#if defined(DART_INCLUDE_SIMULATOR)
  Simulator* simulator_;
#endif
  
  DISALLOW_COPY_AND_ASSIGN(CPUToSimulator);
};

// ============================================================================
// SimulatorToCPU - Transitions from simulator back to native CPU
// ============================================================================
//
// When simulated (patch) code needs to call an unchanged native function:
// 1. Pause the simulator
// 2. Extract arguments from simulator registers
// 3. Call the native function directly
// 4. Put the result back in simulator registers
// 5. Resume simulation
//
class SimulatorToCPU : public ValueObject {
 public:
  // Create a transition to native code at target_pc
#if defined(DART_INCLUDE_SIMULATOR)
  SimulatorToCPU(Simulator* simulator, uword target_pc);
#else
  SimulatorToCPU(void* simulator, uword target_pc);
#endif
  ~SimulatorToCPU();
  
  // Execute the native function with given arguments
  int64_t Execute(int64_t arg0 = 0,
                  int64_t arg1 = 0,
                  int64_t arg2 = 0,
                  int64_t arg3 = 0,
                  int64_t arg4 = 0,
                  int64_t arg5 = 0,
                  int64_t arg6 = 0,
                  int64_t arg7 = 0);
  
 private:
#if defined(DART_INCLUDE_SIMULATOR)
  Simulator* simulator_;
#else
  void* simulator_;
#endif
  uword target_pc_;
  uword saved_pc_;
  
  DISALLOW_COPY_AND_ASSIGN(SimulatorToCPU);
};

// ============================================================================
// WrapperManager - Manages wrapper stubs for transitions
// ============================================================================
//
// On iOS, we can't JIT compile wrapper code at runtime. Instead, we use
// pre-compiled stub code from stub_code_compiler that handles the transitions.
//
// The wrapper manager tracks which functions need wrappers and provides
// lookup from target address to wrapper address.
//
class WrapperManager {
 public:
  // Get the singleton instance
  static WrapperManager& Instance();
  
  // Initialize the wrapper manager
  void Initialize();
  
  // Shutdown and cleanup
  void Shutdown();
  
  // Register a function that needs a CPUToSim wrapper
  // Returns the wrapper address to use in the dispatch table
  uword RegisterCPUToSimWrapper(uword target_pc);
  
  // Register a function that needs a SimToCPU wrapper
  uword RegisterSimToCPUWrapper(uword target_pc);
  
  // Look up wrapper for a target address
  uword LookupCPUToSimWrapper(uword target_pc) const;
  uword LookupSimToCPUWrapper(uword target_pc) const;
  
  // Check if an address is a wrapper
  bool IsWrapper(uword addr) const;
  
  // Get the target address for a wrapper
  uword GetWrapperTarget(uword wrapper_addr) const;
  
  // Get statistics
  intptr_t cpu_to_sim_count() const { return cpu_to_sim_count_; }
  intptr_t sim_to_cpu_count() const { return sim_to_cpu_count_; }
  
 private:
  WrapperManager();
  ~WrapperManager();
  
  static WrapperManager* instance_;
  
  // Wrapper address -> target address mappings
  // Using simple arrays for now, can optimize with hash maps later
  static constexpr intptr_t kMaxWrappers = 8192;
  
  struct WrapperEntry {
    uword wrapper_addr;
    uword target_addr;
  };
  
  WrapperEntry cpu_to_sim_wrappers_[kMaxWrappers];
  WrapperEntry sim_to_cpu_wrappers_[kMaxWrappers];
  
  intptr_t cpu_to_sim_count_;
  intptr_t sim_to_cpu_count_;
  
  bool initialized_;
  
  DISALLOW_COPY_AND_ASSIGN(WrapperManager);
};

// ============================================================================
// Helper functions
// ============================================================================

// Initialize the QuicUI wrapper system
void InitializeWrappers();

// Shutdown the wrapper system
void ShutdownWrappers();

// Get a CPUToSim wrapper for the given target
uword GetCPUToSimWrapper(uword target_pc);

// Get a SimToCPU wrapper for the given target  
uword GetSimToCPUWrapper(uword target_pc);

// Check if currently executing in simulator
bool IsInSimulator();

// Get the current simulator state (if simulating)
SimulatorState* GetCurrentSimulatorState();

// Set the current simulator state
void SetCurrentSimulatorState(SimulatorState* state);

}  // namespace quicui
}  // namespace dart

#endif  // RUNTIME_VM_QUICUI_WRAPPER_H_
