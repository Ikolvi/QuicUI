// Copyright (c) 2025 QuicUI Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef RUNTIME_VM_QUICUI_WRAPPER_ALLOCATOR_H_
#define RUNTIME_VM_QUICUI_WRAPPER_ALLOCATOR_H_

#include <cstddef>
#include <cstdint>
#include <functional>
#include <memory>
#include <vector>

#include "platform/globals.h"

namespace dart {
namespace quicui {

// Configuration for CPU to Simulator (Interpreter) transitions
struct CPUToSimConfig {
  static constexpr const char* name = "CPUToSim";
};

// Configuration for Simulator (Interpreter) to CPU transitions
struct SimToCPUConfig {
  static constexpr const char* name = "SimToCPU";
};

// Wrapper layout template for transition stubs
template <typename Config>
class WrapperLayout {
 public:
  // Size of a single wrapper entry
  static constexpr size_t kWrapperSize = 64;  // bytes

  // Get the wrapper code for a specific entry
  static const uint8_t* GetWrapper(size_t index);

  // Get total number of wrappers
  static size_t GetWrapperCount();
};

// Allocates memory for wrapper stubs that transition between
// CPU (native) execution and Simulator (interpreter) execution.
//
// On iOS, we can't JIT compile code, so we pre-allocate a set of
// wrapper stubs that handle the transition:
// - CPUToSim: Called when native code needs to call interpreted code
// - SimToCPU: Called when interpreted code needs to call native code
class WrapperAllocator {
 public:
  // Layout descriptor for wrapper memory
  struct Layout {
    size_t offset;
    size_t size;
    std::function<void(size_t&, size_t&)> apply;

    template <typename Config>
    static Layout FromTemplate() {
      return Layout{
          0,
          WrapperLayout<Config>::GetWrapperCount() *
              WrapperLayout<Config>::kWrapperSize,
          [](size_t& offset, size_t& size) {
            // Apply layout adjustments
          }};
    }
  };

  WrapperAllocator();
  ~WrapperAllocator();

  // Allocate wrapper memory
  bool Allocate(size_t size);

  // Get base address of wrapper memory
  uint8_t* GetBase() const { return base_; }

  // Get size of allocated wrapper memory
  size_t GetSize() const { return size_; }

  // Initialize wrappers for CPU-to-Sim transitions
  void InitializeCPUToSimWrappers();

  // Initialize wrappers for Sim-to-CPU transitions
  void InitializeSimToCPUWrappers();

  // Get wrapper address for a specific function
  uword GetWrapperFor(uword target_address, bool is_cpu_to_sim);

 private:
  uint8_t* base_ = nullptr;
  size_t size_ = 0;
  bool allocated_ = false;

  // Wrapper address tables
  std::vector<uword> cpu_to_sim_wrappers_;
  std::vector<uword> sim_to_cpu_wrappers_;

  // Disable copy
  WrapperAllocator(const WrapperAllocator&) = delete;
  WrapperAllocator& operator=(const WrapperAllocator&) = delete;
};

// Get the global wrapper allocator instance
WrapperAllocator& GetWrapperAllocator();

}  // namespace quicui
}  // namespace dart

#endif  // RUNTIME_VM_QUICUI_WRAPPER_ALLOCATOR_H_
