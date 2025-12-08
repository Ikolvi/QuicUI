// Copyright (c) 2025 QuicUI Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// QuicUI Dispatch Table Patcher
///
/// This module patches the dispatch table at runtime to redirect
/// modified functions through the ARM64 simulator interpreter.
///
/// For iOS code push, we cannot execute new code directly (App Store policy).
/// Instead, we:
/// 1. Compare base and patch link info to find changed functions
/// 2. Patch dispatch table entries for changed functions
/// 3. Redirect calls to simulator interpreter that reads patch code as DATA

#ifndef RUNTIME_VM_QUICUI_DISPATCH_PATCHER_H_
#define RUNTIME_VM_QUICUI_DISPATCH_PATCHER_H_

#include <atomic>
#include <cstdint>
#include <cstring>
#include <map>
#include <mutex>
#include <vector>

namespace dart {
namespace quicui {

// Forward declarations
class WrapperManager;

// Redirection entry for a patched function
struct PatchRedirection {
  uint32_t function_id;           // Function identifier
  uint64_t original_entry_point;  // Original entry in dispatch table
  uint64_t patch_code_offset;     // Offset in patch file
  uint64_t patch_code_size;       // Size of patch code
  uintptr_t wrapper_stub_addr;    // Generated wrapper stub address
  bool is_active;                 // Whether patch is active
};

// Link info header for parsing
struct LinkInfoHeader {
  uint32_t magic;               // 'QLIC' = 0x51 0x4C 0x49 0x43
  uint32_t version;             // Format version
  uint32_t function_count;      // Number of functions
  uint32_t dispatch_table_size; // Size of dispatch table
  uint64_t code_section_offset; // Offset to code section
  uint64_t code_section_size;   // Size of code section
};

static const uint32_t LINK_INFO_MAGIC = 0x43494C51;  // 'QLIC'
static const uint32_t LINK_INFO_VERSION = 1;

// Wrapper stub template for ARM64
// This is the machine code for a trampoline that calls into the interpreter
struct WrapperStubTemplate {
  // ARM64 instructions to:
  // 1. Save LR
  // 2. Load patch code address into X16
  // 3. Load interpreter entry into X17
  // 4. Branch to interpreter
  uint32_t instructions[16];
  uintptr_t patch_code_addr;
  uintptr_t interpreter_entry;
};

// Manages dispatch table patching
class DispatchTablePatcher {
 public:
  DispatchTablePatcher();
  ~DispatchTablePatcher();

  // Singleton access
  static DispatchTablePatcher& Instance();

  // Initialize patcher with dispatch table location
  bool Initialize(uintptr_t dispatch_table_base, size_t dispatch_table_size);

  // Set the interpreter entry point (QuicuiResumeInterpreter stub)
  void SetInterpreterEntry(uintptr_t entry) {
    interpreter_entry_ = entry;
  }

  // Load patch redirections from link info comparison
  bool LoadPatchRedirections(const uint8_t* base_link_info,
                             size_t base_size,
                             const uint8_t* patch_link_info,
                             size_t patch_size);

  // Apply all patch redirections to dispatch table
  bool ApplyPatches(const uint8_t* patch_code_data, size_t patch_code_size);

  // Revert all patches (restore original dispatch table)
  bool RevertPatches();

  // Get list of patched functions
  const std::vector<PatchRedirection>& GetRedirections() const {
    return redirections_;
  }

  // Get wrapper stub entry point for a function
  uintptr_t GetWrapperStubFor(uint32_t function_id) const;

  // Check if a function is patched
  bool IsFunctionPatched(uint32_t function_id) const;

  // Get patch code address for a wrapper stub
  uintptr_t GetPatchCodeForWrapper(uintptr_t wrapper_addr) const;

 private:
  // Singleton instance
  static DispatchTablePatcher* instance_;

  // Mutex for thread-safe operations
  mutable std::mutex mutex_;

  // Dispatch table location
  uintptr_t dispatch_table_base_ = 0;
  size_t dispatch_table_size_ = 0;

  // Interpreter entry point
  uintptr_t interpreter_entry_ = 0;

  // Patch code data
  const uint8_t* patch_code_data_ = nullptr;
  size_t patch_code_size_ = 0;

  // List of redirections
  std::vector<PatchRedirection> redirections_;

  // Map from wrapper stub address to patch code offset
  std::map<uintptr_t, uint64_t> wrapper_to_patch_;

  // Allocated wrapper stubs (for cleanup)
  std::vector<void*> allocated_stubs_;

  // Whether patches are currently active
  std::atomic<bool> patches_active_{false};

  // Whether initialized
  bool initialized_ = false;

  // Parse link info to extract function entries
  bool ParseLinkInfo(const uint8_t* data, size_t size,
                     std::vector<uint32_t>& function_ids,
                     std::vector<uint32_t>& function_hashes,
                     std::vector<uint64_t>& function_offsets);

  // Compare function hashes to find changes
  void FindChangedFunctions(const std::vector<uint32_t>& base_ids,
                            const std::vector<uint32_t>& base_hashes,
                            const std::vector<uint32_t>& patch_ids,
                            const std::vector<uint32_t>& patch_hashes,
                            const std::vector<uint64_t>& patch_offsets);

  // Generate wrapper stub for redirecting to simulator
  uintptr_t GenerateWrapperStub(uint64_t patch_code_offset);

  // Free all allocated wrapper stubs
  void FreeWrapperStubs();
};

// ============================================================================
// Implementation
// ============================================================================

inline DispatchTablePatcher* DispatchTablePatcher::instance_ = nullptr;

inline DispatchTablePatcher::DispatchTablePatcher() = default;

inline DispatchTablePatcher::~DispatchTablePatcher() {
  FreeWrapperStubs();
}

inline DispatchTablePatcher& DispatchTablePatcher::Instance() {
  if (instance_ == nullptr) {
    instance_ = new DispatchTablePatcher();
  }
  return *instance_;
}

inline bool DispatchTablePatcher::Initialize(uintptr_t dispatch_table_base,
                                              size_t dispatch_table_size) {
  std::lock_guard<std::mutex> lock(mutex_);

  if (initialized_) {
    return true;  // Already initialized
  }

  dispatch_table_base_ = dispatch_table_base;
  dispatch_table_size_ = dispatch_table_size;
  initialized_ = (dispatch_table_base != 0 && dispatch_table_size > 0);
  return initialized_;
}

inline bool DispatchTablePatcher::LoadPatchRedirections(
    const uint8_t* base_link_info,
    size_t base_size,
    const uint8_t* patch_link_info,
    size_t patch_size) {
  std::lock_guard<std::mutex> lock(mutex_);

  std::vector<uint32_t> base_ids, base_hashes;
  std::vector<uint64_t> base_offsets;  // Not used for base
  std::vector<uint32_t> patch_ids, patch_hashes;
  std::vector<uint64_t> patch_offsets;

  if (!ParseLinkInfo(base_link_info, base_size, base_ids, base_hashes,
                     base_offsets)) {
    return false;
  }

  if (!ParseLinkInfo(patch_link_info, patch_size, patch_ids, patch_hashes,
                     patch_offsets)) {
    return false;
  }

  FindChangedFunctions(base_ids, base_hashes, patch_ids, patch_hashes,
                       patch_offsets);
  return true;
}

inline bool DispatchTablePatcher::ParseLinkInfo(
    const uint8_t* data,
    size_t size,
    std::vector<uint32_t>& function_ids,
    std::vector<uint32_t>& function_hashes,
    std::vector<uint64_t>& function_offsets) {
  if (data == nullptr || size < sizeof(LinkInfoHeader)) {
    return false;
  }

  const LinkInfoHeader* header =
      reinterpret_cast<const LinkInfoHeader*>(data);

  if (header->magic != LINK_INFO_MAGIC) {
    return false;
  }

  if (header->version != LINK_INFO_VERSION) {
    return false;
  }

  const uint8_t* ptr = data + sizeof(LinkInfoHeader);
  const uint8_t* end = data + size;

  for (uint32_t i = 0; i < header->function_count; i++) {
    // Each entry: func_id(4) + hash(4) + entry_point(8) + code_size(8) +
    // name_len(4)
    if (ptr + 28 > end) {
      break;
    }

    uint32_t func_id;
    uint32_t func_hash;
    uint64_t entry_point;

    memcpy(&func_id, ptr, sizeof(uint32_t));
    memcpy(&func_hash, ptr + 4, sizeof(uint32_t));
    memcpy(&entry_point, ptr + 8, sizeof(uint64_t));

    function_ids.push_back(func_id);
    function_hashes.push_back(func_hash);
    function_offsets.push_back(entry_point);

    ptr += 24;  // Skip to name_len

    // Read name length and skip name
    if (ptr + 4 > end) break;
    uint32_t name_len;
    memcpy(&name_len, ptr, sizeof(uint32_t));
    ptr += 4 + name_len;
  }

  return true;
}

inline void DispatchTablePatcher::FindChangedFunctions(
    const std::vector<uint32_t>& base_ids,
    const std::vector<uint32_t>& base_hashes,
    const std::vector<uint32_t>& patch_ids,
    const std::vector<uint32_t>& patch_hashes,
    const std::vector<uint64_t>& patch_offsets) {
  redirections_.clear();

  // Build map of base function hashes (function_id -> hash)
  std::map<uint32_t, uint32_t> base_hash_map;
  for (size_t i = 0; i < base_ids.size(); i++) {
    base_hash_map[base_ids[i]] = base_hashes[i];
  }

  // Find functions with different hashes
  for (size_t i = 0; i < patch_ids.size(); i++) {
    uint32_t func_id = patch_ids[i];
    uint32_t patch_hash = patch_hashes[i];

    auto it = base_hash_map.find(func_id);

    // Function is changed if:
    // 1. It exists in base but hash differs, OR
    // 2. It's new in patch (not in base)
    bool is_changed = (it == base_hash_map.end()) || (it->second != patch_hash);

    if (is_changed) {
      PatchRedirection redir;
      redir.function_id = func_id;
      redir.original_entry_point = 0;  // Will be filled when applying
      redir.patch_code_offset = patch_offsets[i];
      redir.patch_code_size = 0;  // TODO: Calculate from next entry
      redir.wrapper_stub_addr = 0;
      redir.is_active = false;

      redirections_.push_back(redir);
    }
  }
}

inline bool DispatchTablePatcher::ApplyPatches(const uint8_t* patch_code_data,
                                                size_t patch_code_size) {
  std::lock_guard<std::mutex> lock(mutex_);

  if (patches_active_.load(std::memory_order_acquire)) {
    return false;  // Already patched
  }

  if (!initialized_ || dispatch_table_base_ == 0) {
    return false;
  }

  patch_code_data_ = patch_code_data;
  patch_code_size_ = patch_code_size;

  // Use atomic operations for dispatch table access
  std::atomic<uintptr_t>* dispatch_table =
      reinterpret_cast<std::atomic<uintptr_t>*>(dispatch_table_base_);
  size_t entry_count = dispatch_table_size_ / sizeof(uintptr_t);

  for (auto& redir : redirections_) {
    if (redir.function_id < entry_count) {
      // Save original entry point with acquire semantics
      redir.original_entry_point =
          dispatch_table[redir.function_id].load(std::memory_order_acquire);

      // Generate wrapper stub
      uintptr_t wrapper = GenerateWrapperStub(redir.patch_code_offset);
      if (wrapper == 0) {
        // Failed to generate stub, skip this function
        continue;
      }

      redir.wrapper_stub_addr = wrapper;

      // Patch dispatch table with release semantics
      dispatch_table[redir.function_id].store(wrapper,
                                               std::memory_order_release);
      redir.is_active = true;

      // Record mapping for lookup
      wrapper_to_patch_[wrapper] = redir.patch_code_offset;
    }
  }

  // Full memory barrier to ensure all patches are visible
  std::atomic_thread_fence(std::memory_order_seq_cst);

  patches_active_.store(true, std::memory_order_release);
  return true;
}

inline bool DispatchTablePatcher::RevertPatches() {
  std::lock_guard<std::mutex> lock(mutex_);

  if (!patches_active_.load(std::memory_order_acquire)) {
    return false;
  }

  if (!initialized_ || dispatch_table_base_ == 0) {
    return false;
  }

  // Use atomic operations for dispatch table access
  std::atomic<uintptr_t>* dispatch_table =
      reinterpret_cast<std::atomic<uintptr_t>*>(dispatch_table_base_);
  size_t entry_count = dispatch_table_size_ / sizeof(uintptr_t);

  for (auto& redir : redirections_) {
    if (redir.is_active && redir.function_id < entry_count) {
      // Restore original entry with release semantics
      dispatch_table[redir.function_id].store(redir.original_entry_point,
                                               std::memory_order_release);
      redir.is_active = false;
    }
  }

  // Full memory barrier
  std::atomic_thread_fence(std::memory_order_seq_cst);

  wrapper_to_patch_.clear();
  patches_active_.store(false, std::memory_order_release);
  return true;
}

inline uintptr_t DispatchTablePatcher::GenerateWrapperStub(
    uint64_t patch_code_offset) {
  // Calculate the actual patch code address
  if (patch_code_data_ == nullptr) {
    return 0;
  }

  uintptr_t patch_code_addr =
      reinterpret_cast<uintptr_t>(patch_code_data_) + patch_code_offset;

  // Allocate memory for the wrapper stub
  // On iOS, we need to use executable memory allocation
  // For now, we use a simple approach: the wrapper stub is a small
  // piece of code that:
  // 1. Loads the patch code address into a register
  // 2. Jumps to the interpreter entry point

  // Allocate stub memory (needs to be executable on real device)
  // Using posix_memalign for alignment, mprotect for execute permission
  void* stub_mem = nullptr;

#if defined(__APPLE__)
  // On Apple platforms, allocate page-aligned memory
  size_t stub_size = sizeof(WrapperStubTemplate);
  size_t page_size = 4096;
  size_t alloc_size = ((stub_size + page_size - 1) / page_size) * page_size;

  if (posix_memalign(&stub_mem, page_size, alloc_size) != 0) {
    return 0;
  }

  // Note: On iOS device, this would need to be handled differently
  // as we cannot make memory executable. The stub is pre-compiled
  // into the app binary and we just need to look it up.
  // For simulator builds, we can generate stubs.

#if defined(TARGET_OS_SIMULATOR) || defined(__x86_64__)
  // On simulator, we can make memory executable
  // mprotect(stub_mem, alloc_size, PROT_READ | PROT_EXEC | PROT_WRITE);
#endif

#else
  // Simple allocation for other platforms
  stub_mem = malloc(sizeof(WrapperStubTemplate));
  if (stub_mem == nullptr) {
    return 0;
  }
#endif

  // Initialize the stub template
  WrapperStubTemplate* stub = static_cast<WrapperStubTemplate*>(stub_mem);

  // ARM64 instructions for wrapper stub:
  // The stub will be called instead of the original function.
  // It needs to:
  // 1. Preserve arguments (X0-X7 are already set by caller)
  // 2. Set X16 = patch_code_addr
  // 3. Set X17 = interpreter_entry
  // 4. Branch to X17 (interpreter will use X16)

  // LDR X16, [PC, #offset_to_patch_addr]  // Load patch code address
  // LDR X17, [PC, #offset_to_interp]      // Load interpreter entry
  // BR X17                                 // Branch to interpreter

  // For simplicity, we use a data-driven approach:
  // The stub contains the addresses and a simple branch sequence

  // ARM64 encoding for: LDR X16, [PC, #40] (load from PC+40)
  stub->instructions[0] = 0x58000150;  // LDR X16, #40

  // ARM64 encoding for: LDR X17, [PC, #44] (load from PC+44)
  stub->instructions[1] = 0x58000171;  // LDR X17, #44

  // ARM64 encoding for: BR X17
  stub->instructions[2] = 0xD61F0220;

  // NOP padding
  for (int i = 3; i < 10; i++) {
    stub->instructions[i] = 0xD503201F;  // NOP
  }

  // Store addresses after instructions
  stub->patch_code_addr = patch_code_addr;
  stub->interpreter_entry = interpreter_entry_;

  // Track allocation for cleanup
  allocated_stubs_.push_back(stub_mem);

  return reinterpret_cast<uintptr_t>(stub_mem);
}

inline void DispatchTablePatcher::FreeWrapperStubs() {
  for (void* stub : allocated_stubs_) {
    free(stub);
  }
  allocated_stubs_.clear();
}

inline uintptr_t DispatchTablePatcher::GetWrapperStubFor(
    uint32_t function_id) const {
  std::lock_guard<std::mutex> lock(mutex_);

  for (const auto& redir : redirections_) {
    if (redir.function_id == function_id && redir.is_active) {
      return redir.wrapper_stub_addr;
    }
  }
  return 0;
}

inline bool DispatchTablePatcher::IsFunctionPatched(
    uint32_t function_id) const {
  std::lock_guard<std::mutex> lock(mutex_);

  for (const auto& redir : redirections_) {
    if (redir.function_id == function_id && redir.is_active) {
      return true;
    }
  }
  return false;
}

inline uintptr_t DispatchTablePatcher::GetPatchCodeForWrapper(
    uintptr_t wrapper_addr) const {
  std::lock_guard<std::mutex> lock(mutex_);

  auto it = wrapper_to_patch_.find(wrapper_addr);
  if (it != wrapper_to_patch_.end()) {
    return reinterpret_cast<uintptr_t>(patch_code_data_) + it->second;
  }
  return 0;
}

}  // namespace quicui
}  // namespace dart

#endif  // RUNTIME_VM_QUICUI_DISPATCH_PATCHER_H_
