// Copyright (c) 2025 QuicUI Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vm/quicui/wrapper_allocator.h"

#include <cstring>

#if defined(HOST_OS_MACOS) || defined(HOST_OS_IOS)
#include <mach/mach.h>
#include <mach/vm_map.h>
#endif

namespace dart {
namespace quicui {

// Static wrapper allocator instance
static WrapperAllocator* wrapper_allocator_ = nullptr;

WrapperAllocator& GetWrapperAllocator() {
  if (wrapper_allocator_ == nullptr) {
    wrapper_allocator_ = new WrapperAllocator();
  }
  return *wrapper_allocator_;
}

template <>
const uint8_t* WrapperLayout<CPUToSimConfig>::GetWrapper(size_t index) {
  // TODO: Return pre-generated wrapper stub code
  return nullptr;
}

template <>
size_t WrapperLayout<CPUToSimConfig>::GetWrapperCount() {
  // Number of pre-allocated CPU-to-Sim wrapper slots
  return 1024;
}

template <>
const uint8_t* WrapperLayout<SimToCPUConfig>::GetWrapper(size_t index) {
  // TODO: Return pre-generated wrapper stub code
  return nullptr;
}

template <>
size_t WrapperLayout<SimToCPUConfig>::GetWrapperCount() {
  // Number of pre-allocated Sim-to-CPU wrapper slots
  return 1024;
}

WrapperAllocator::WrapperAllocator() = default;

WrapperAllocator::~WrapperAllocator() {
  if (base_ != nullptr && allocated_) {
#if defined(HOST_OS_MACOS) || defined(HOST_OS_IOS)
    vm_deallocate(mach_task_self(), reinterpret_cast<vm_address_t>(base_),
                  size_);
#else
    delete[] base_;
#endif
    base_ = nullptr;
    size_ = 0;
    allocated_ = false;
  }
}

bool WrapperAllocator::Allocate(size_t size) {
  if (allocated_) {
    return false;
  }

#if defined(HOST_OS_MACOS) || defined(HOST_OS_IOS)
  // On iOS/macOS, allocate memory that can be made executable
  // Note: On iOS, we can only read this memory, not make it executable
  // The wrappers must be pre-compiled into the binary
  vm_address_t address = 0;
  kern_return_t result = vm_allocate(mach_task_self(), &address, size,
                                     VM_FLAGS_ANYWHERE);
  if (result != KERN_SUCCESS) {
    return false;
  }
  base_ = reinterpret_cast<uint8_t*>(address);
#else
  base_ = new uint8_t[size];
  if (base_ == nullptr) {
    return false;
  }
#endif

  size_ = size;
  allocated_ = true;
  memset(base_, 0, size_);

  return true;
}

void WrapperAllocator::InitializeCPUToSimWrappers() {
  // Calculate required size
  size_t wrapper_count = WrapperLayout<CPUToSimConfig>::GetWrapperCount();
  size_t wrapper_size = WrapperLayout<CPUToSimConfig>::kWrapperSize;

  cpu_to_sim_wrappers_.reserve(wrapper_count);

  // TODO: Copy pre-generated wrapper stubs to allocated memory
  // For now, just record placeholder addresses
  for (size_t i = 0; i < wrapper_count; i++) {
    uword wrapper_addr =
        reinterpret_cast<uword>(base_) + (i * wrapper_size);
    cpu_to_sim_wrappers_.push_back(wrapper_addr);
  }
}

void WrapperAllocator::InitializeSimToCPUWrappers() {
  size_t wrapper_count = WrapperLayout<SimToCPUConfig>::GetWrapperCount();
  size_t wrapper_size = WrapperLayout<SimToCPUConfig>::kWrapperSize;
  size_t cpu_to_sim_size =
      WrapperLayout<CPUToSimConfig>::GetWrapperCount() *
      WrapperLayout<CPUToSimConfig>::kWrapperSize;

  sim_to_cpu_wrappers_.reserve(wrapper_count);

  // Sim-to-CPU wrappers come after CPU-to-Sim wrappers
  for (size_t i = 0; i < wrapper_count; i++) {
    uword wrapper_addr = reinterpret_cast<uword>(base_) + cpu_to_sim_size +
                         (i * wrapper_size);
    sim_to_cpu_wrappers_.push_back(wrapper_addr);
  }
}

uword WrapperAllocator::GetWrapperFor(uword target_address, bool is_cpu_to_sim) {
  // TODO: Implement wrapper lookup/allocation
  // This should find or create a wrapper that transitions to target_address
  
  const auto& wrappers = is_cpu_to_sim ? cpu_to_sim_wrappers_ : sim_to_cpu_wrappers_;
  
  if (wrappers.empty()) {
    return 0;
  }
  
  // For now, return a placeholder
  // Real implementation would hash target_address to find appropriate wrapper
  size_t index = target_address % wrappers.size();
  return wrappers[index];
}

}  // namespace quicui
}  // namespace dart
