// Copyright (c) 2025 QuicUI Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vm/quicui/wrapper.h"

#include <cstring>

#include "platform/assert.h"
#include "vm/thread.h"

#if defined(DART_INCLUDE_SIMULATOR)
#include "vm/simulator.h"
#endif

namespace dart {
namespace quicui {

// ============================================================================
// Thread-local state for tracking simulator transitions
// ============================================================================

// Thread-local pointer to current simulator state
static thread_local SimulatorState* current_sim_state_ = nullptr;

// Thread-local flag indicating if we're in simulator
static thread_local bool in_simulator_ = false;

// ============================================================================
// Helper function implementations
// ============================================================================

bool IsInSimulator() {
  return in_simulator_;
}

SimulatorState* GetCurrentSimulatorState() {
  return current_sim_state_;
}

void SetCurrentSimulatorState(SimulatorState* state) {
  current_sim_state_ = state;
  in_simulator_ = (state != nullptr && state->is_simulating);
}

// ============================================================================
// WrapperManager implementation
// ============================================================================

WrapperManager* WrapperManager::instance_ = nullptr;

WrapperManager& WrapperManager::Instance() {
  if (instance_ == nullptr) {
    instance_ = new WrapperManager();
  }
  return *instance_;
}

WrapperManager::WrapperManager()
    : cpu_to_sim_count_(0),
      sim_to_cpu_count_(0),
      initialized_(false) {
  memset(cpu_to_sim_wrappers_, 0, sizeof(cpu_to_sim_wrappers_));
  memset(sim_to_cpu_wrappers_, 0, sizeof(sim_to_cpu_wrappers_));
}

WrapperManager::~WrapperManager() {
  Shutdown();
}

void WrapperManager::Initialize() {
  if (initialized_) {
    return;
  }
  
  // Clear wrapper tables
  memset(cpu_to_sim_wrappers_, 0, sizeof(cpu_to_sim_wrappers_));
  memset(sim_to_cpu_wrappers_, 0, sizeof(sim_to_cpu_wrappers_));
  cpu_to_sim_count_ = 0;
  sim_to_cpu_count_ = 0;
  
  initialized_ = true;
}

void WrapperManager::Shutdown() {
  if (!initialized_) {
    return;
  }
  
  cpu_to_sim_count_ = 0;
  sim_to_cpu_count_ = 0;
  initialized_ = false;
}

uword WrapperManager::RegisterCPUToSimWrapper(uword target_pc) {
  if (!initialized_) {
    Initialize();
  }
  
  // Check if already registered
  for (intptr_t i = 0; i < cpu_to_sim_count_; i++) {
    if (cpu_to_sim_wrappers_[i].target_addr == target_pc) {
      return cpu_to_sim_wrappers_[i].wrapper_addr;
    }
  }
  
  // Register new wrapper
  if (cpu_to_sim_count_ >= kMaxWrappers) {
    FATAL("QuicUI: Too many CPUToSim wrappers");
    return 0;
  }
  
  // The wrapper address will be the stub code address plus an offset
  // For now, we use the target_pc as the wrapper address and handle
  // the actual transition in the runtime entry point
  uword wrapper_addr = target_pc;  // Placeholder - will be stub address
  
  cpu_to_sim_wrappers_[cpu_to_sim_count_].wrapper_addr = wrapper_addr;
  cpu_to_sim_wrappers_[cpu_to_sim_count_].target_addr = target_pc;
  cpu_to_sim_count_++;
  
  return wrapper_addr;
}

uword WrapperManager::RegisterSimToCPUWrapper(uword target_pc) {
  if (!initialized_) {
    Initialize();
  }
  
  // Check if already registered
  for (intptr_t i = 0; i < sim_to_cpu_count_; i++) {
    if (sim_to_cpu_wrappers_[i].target_addr == target_pc) {
      return sim_to_cpu_wrappers_[i].wrapper_addr;
    }
  }
  
  // Register new wrapper
  if (sim_to_cpu_count_ >= kMaxWrappers) {
    FATAL("QuicUI: Too many SimToCPU wrappers");
    return 0;
  }
  
  uword wrapper_addr = target_pc;  // Placeholder
  
  sim_to_cpu_wrappers_[sim_to_cpu_count_].wrapper_addr = wrapper_addr;
  sim_to_cpu_wrappers_[sim_to_cpu_count_].target_addr = target_pc;
  sim_to_cpu_count_++;
  
  return wrapper_addr;
}

uword WrapperManager::LookupCPUToSimWrapper(uword target_pc) const {
  for (intptr_t i = 0; i < cpu_to_sim_count_; i++) {
    if (cpu_to_sim_wrappers_[i].target_addr == target_pc) {
      return cpu_to_sim_wrappers_[i].wrapper_addr;
    }
  }
  return 0;
}

uword WrapperManager::LookupSimToCPUWrapper(uword target_pc) const {
  for (intptr_t i = 0; i < sim_to_cpu_count_; i++) {
    if (sim_to_cpu_wrappers_[i].target_addr == target_pc) {
      return sim_to_cpu_wrappers_[i].wrapper_addr;
    }
  }
  return 0;
}

bool WrapperManager::IsWrapper(uword addr) const {
  for (intptr_t i = 0; i < cpu_to_sim_count_; i++) {
    if (cpu_to_sim_wrappers_[i].wrapper_addr == addr) {
      return true;
    }
  }
  for (intptr_t i = 0; i < sim_to_cpu_count_; i++) {
    if (sim_to_cpu_wrappers_[i].wrapper_addr == addr) {
      return true;
    }
  }
  return false;
}

uword WrapperManager::GetWrapperTarget(uword wrapper_addr) const {
  for (intptr_t i = 0; i < cpu_to_sim_count_; i++) {
    if (cpu_to_sim_wrappers_[i].wrapper_addr == wrapper_addr) {
      return cpu_to_sim_wrappers_[i].target_addr;
    }
  }
  for (intptr_t i = 0; i < sim_to_cpu_count_; i++) {
    if (sim_to_cpu_wrappers_[i].wrapper_addr == wrapper_addr) {
      return sim_to_cpu_wrappers_[i].target_addr;
    }
  }
  return 0;
}

// ============================================================================
// CPUToSimulator implementation
// ============================================================================

CPUToSimulator::CPUToSimulator(Thread* thread, uword target_pc)
    : thread_(thread),
      target_pc_(target_pc),
      entered_(false)
#if defined(DART_INCLUDE_SIMULATOR)
      , simulator_(nullptr)
#endif
{
  // Initialize saved state
  memset(&saved_state_, 0, sizeof(saved_state_));
  saved_state_.thread = thread;
  saved_state_.is_simulating = false;
  saved_state_.depth = 0;
  
  // Save current state if there is one
  SimulatorState* current = GetCurrentSimulatorState();
  if (current != nullptr) {
    saved_state_.depth = current->depth + 1;
  }
}

CPUToSimulator::~CPUToSimulator() {
  if (entered_) {
    // Restore previous simulator state
    SimulatorState* prev = GetCurrentSimulatorState();
    if (prev != nullptr && prev->depth > 0) {
      prev->depth--;
    }
  }
}

int64_t CPUToSimulator::Execute(int64_t arg0,
                                 int64_t arg1,
                                 int64_t arg2,
                                 int64_t arg3,
                                 int64_t arg4,
                                 int64_t arg5,
                                 int64_t arg6,
                                 int64_t arg7) {
#if defined(DART_INCLUDE_SIMULATOR)
  entered_ = true;
  
  // Get or create simulator for this thread
  simulator_ = Simulator::Current();
  if (simulator_ == nullptr) {
    FATAL("QuicUI: No simulator available");
    return 0;
  }
  
  // Save current state
  saved_state_.pc = target_pc_;
  saved_state_.is_simulating = true;
  SetCurrentSimulatorState(&saved_state_);
  
  // Set up arguments in simulator registers
  // ARM64 calling convention: X0-X7 for first 8 arguments
  simulator_->set_register(nullptr, R0, arg0);
  simulator_->set_register(nullptr, R1, arg1);
  simulator_->set_register(nullptr, R2, arg2);
  simulator_->set_register(nullptr, R3, arg3);
  simulator_->set_register(nullptr, R4, arg4);
  simulator_->set_register(nullptr, R5, arg5);
  simulator_->set_register(nullptr, R6, arg6);
  simulator_->set_register(nullptr, R7, arg7);
  
  // Call into the simulator
  // The simulator will execute ARM64 instructions from target_pc_
  // until it hits a return or needs to call back to native code
  int64_t result = simulator_->Call(
      static_cast<int64_t>(target_pc_),
      arg0, arg1, arg2, arg3,
      false,  // fp_return
      false   // fp_args
  );
  
  // Restore state
  saved_state_.is_simulating = false;
  SetCurrentSimulatorState(nullptr);
  
  return result;
#else
  // Without simulator, we can't interpret code
  FATAL("QuicUI: Simulator not available for code interpretation");
  return 0;
#endif
}

bool CPUToSimulator::IsSimulating(uword pc) {
  SimulatorState* state = GetCurrentSimulatorState();
  if (state == nullptr || !state->is_simulating) {
    return false;
  }
  // Check if PC is in the range being simulated
  // This is a simplified check - real implementation would check
  // against the patch code memory range
  return true;
}

// ============================================================================
// SimulatorToCPU implementation
// ============================================================================

#if defined(DART_INCLUDE_SIMULATOR)
SimulatorToCPU::SimulatorToCPU(Simulator* simulator, uword target_pc)
    : simulator_(simulator),
      target_pc_(target_pc),
      saved_pc_(0) {
  if (simulator_ != nullptr) {
    saved_pc_ = simulator_->get_pc();
  }
}
#else
SimulatorToCPU::SimulatorToCPU(void* simulator, uword target_pc)
    : simulator_(simulator),
      target_pc_(target_pc),
      saved_pc_(0) {
}
#endif

SimulatorToCPU::~SimulatorToCPU() {
#if defined(DART_INCLUDE_SIMULATOR)
  if (simulator_ != nullptr) {
    // Restore simulator PC if needed
    // simulator_->set_pc(saved_pc_);
  }
#endif
}

int64_t SimulatorToCPU::Execute(int64_t arg0,
                                 int64_t arg1,
                                 int64_t arg2,
                                 int64_t arg3,
                                 int64_t arg4,
                                 int64_t arg5,
                                 int64_t arg6,
                                 int64_t arg7) {
  // Call the native function directly
  // This is a function pointer call to the native code
  typedef int64_t (*NativeFunction)(int64_t, int64_t, int64_t, int64_t,
                                    int64_t, int64_t, int64_t, int64_t);
  
  NativeFunction fn = reinterpret_cast<NativeFunction>(target_pc_);
  int64_t result = fn(arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7);
  
#if defined(DART_INCLUDE_SIMULATOR)
  // Put result back in simulator's R0
  if (simulator_ != nullptr) {
    simulator_->set_register(nullptr, R0, result);
  }
#endif
  
  return result;
}

// ============================================================================
// Global helper function implementations
// ============================================================================

void InitializeWrappers() {
  WrapperManager::Instance().Initialize();
}

void ShutdownWrappers() {
  WrapperManager::Instance().Shutdown();
}

uword GetCPUToSimWrapper(uword target_pc) {
  return WrapperManager::Instance().RegisterCPUToSimWrapper(target_pc);
}

uword GetSimToCPUWrapper(uword target_pc) {
  return WrapperManager::Instance().RegisterSimToCPUWrapper(target_pc);
}

}  // namespace quicui
}  // namespace dart
