// Copyright (c) 2025 QuicUI Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef RUNTIME_VM_QUICUI_LINKER_H_
#define RUNTIME_VM_QUICUI_LINKER_H_

#include <memory>
#include <string>
#include <unordered_set>
#include <vector>

#include "platform/globals.h"

namespace dart {
namespace quicui {

// Forward declarations for link info types
class ClassTableLinkInfo;
class FieldTableLinkInfo;
class DispatchTableLinkInfo;
class ObjectPoolLinkInfo;

// vmcode file header magic number "QUIC" in little endian
constexpr uint32_t kQuicuiMagic = 0x43495551;  // "QUIC"
constexpr uint32_t kQuicuiVersion = 1;
constexpr intptr_t kQuicuiHeaderSize = 65536;  // 64KB header like Shorebird

// ============================================================================
// FunctionEntry - Describes a function for comparison
// ============================================================================
struct FunctionEntry {
  uword entry_point;      // Entry point address
  intptr_t code_offset;   // Offset into instructions section
  intptr_t code_size;     // Size of code in bytes
  intptr_t function_id;   // Unique function identifier
  uint64_t code_hash;     // Hash of code bytes for quick comparison
};

// ============================================================================
// FunctionLinkInfo - Result of comparing base and patch functions
// ============================================================================
struct FunctionLinkInfo {
  uword base_entry_point;    // Entry point in base (signed) app
  uword patch_entry_point;   // Entry point in patch code
  uword wrapper_address;     // Address of CPU-to-sim wrapper (if needed)
  intptr_t function_id;      // Function identifier
  bool is_identical;         // True if code is same in base and patch
  bool needs_simulation;     // True if must run on simulator
};

// ============================================================================
// QuicUI Linker - Links AOT snapshots for iOS code push updates
// ============================================================================
//
// This class enables over-the-air updates on iOS by:
// 1. Comparing "base" (release) and "patch" snapshots
// 2. Identifying functions that are identical (can run natively from signed IPA)
// 3. Identifying functions that differ (must be interpreted)
// 4. Generating .vmcode files with link information
//
// The linking process allows ~98% of code to run at native speed
// while only ~2% of changed code needs interpretation.
class QuicuiLinker {
 public:
  // Get the singleton linker instance
  static QuicuiLinker& Shared();

  // Destructor
  ~QuicuiLinker();

  // Initialize with class table link information
  // Maps class IDs between base and patch snapshots
  void InitializeWithClassTableLinkInfo(
      std::unique_ptr<ClassTableLinkInfo> base_info,
      std::unique_ptr<ClassTableLinkInfo> patch_info);

  // Initialize with field table link information
  void InitializeWithFieldTableLinkInfo(
      std::unique_ptr<FieldTableLinkInfo> info);

  // Initialize with dispatch table link information
  void InitializeWithDispatchTableLinkInfo(
      std::unique_ptr<DispatchTableLinkInfo> info);

  // Initialize with object pool link information
  void InitializeWithObjectPoolLinkInfo(
      std::unique_ptr<ObjectPoolLinkInfo> base_info,
      std::unique_ptr<ObjectPoolLinkInfo> patch_info);

  // Check if linker has been initialized with all required info
  bool IsInitialized() const;

  // Get the percentage of code that was successfully linked
  // (can run natively instead of interpreted)
  double GetLinkPercentage() const;

  // Check if a specific function can run natively
  bool CanRunNatively(uword entry_point) const;

  // Mark a function as able to run natively
  void MarkNativeFunction(uword entry_point);

  // Get the base instructions table for the release snapshot
  const uint8_t* GetBaseInstructionsTable() const;
  intptr_t GetBaseInstructionsTableSize() const;

  // Set base snapshots from the release build
  void SetBaseSnapshots(const uint8_t* vm_data,
                        intptr_t vm_data_size,
                        const uint8_t* vm_instrs,
                        intptr_t vm_instrs_size,
                        const uint8_t* isolate_data,
                        intptr_t isolate_data_size,
                        const uint8_t* isolate_instrs,
                        intptr_t isolate_instrs_size);

  // Read link header from vmcode file
  // Returns true if header is valid
  static bool ReadLinkHeader(const uint8_t* data,
                             intptr_t data_size,
                             intptr_t* header_size,
                             intptr_t* link_data_offset);

  // Generate link header for vmcode file
  static void GenerateLinkHeader(uint8_t* buffer,
                                 intptr_t header_size,
                                 intptr_t link_data_offset);

  // =========================================================================
  // Function Comparison and Linking
  // =========================================================================

  // Compare two function code sections
  // Returns true if they are byte-for-byte identical
  static bool CompareFunctionCode(const uint8_t* base_code,
                                  intptr_t base_size,
                                  const uint8_t* patch_code,
                                  intptr_t patch_size);

  // Analyze and link base and patch snapshots
  // Identifies which functions can run natively vs need simulation
  void AnalyzeAndLink(const uint8_t* base_instrs,
                      intptr_t base_instrs_size,
                      const uint8_t* patch_instrs,
                      intptr_t patch_instrs_size,
                      const FunctionEntry* base_functions,
                      intptr_t base_function_count,
                      const FunctionEntry* patch_functions,
                      intptr_t patch_function_count);

  // Generate a redirection table for patched functions
  // This table maps base entry points to simulator wrappers
  void GenerateRedirectionTable(uint8_t* output_buffer,
                                size_t buffer_size,
                                size_t* bytes_written);

  // Parse a redirection table from vmcode file
  bool ParseRedirectionTable(const uint8_t* data, size_t data_size);

  // Get the link results
  const std::vector<FunctionLinkInfo>& GetLinkResults() const;

  // Print linker statistics (for debugging)
  void PrintStats() const;

  // Reset linker state
  void Reset();

 private:
  QuicuiLinker();

  // Check if all required link info has been provided
  void CheckInitialized();

  // Singleton instance
  static QuicuiLinker* instance_;

  // Link information
  std::unique_ptr<ClassTableLinkInfo> class_table_base_info_;
  std::unique_ptr<ClassTableLinkInfo> class_table_patch_info_;
  std::unique_ptr<FieldTableLinkInfo> field_table_info_;
  std::unique_ptr<DispatchTableLinkInfo> dispatch_table_info_;
  std::unique_ptr<ObjectPoolLinkInfo> object_pool_base_info_;
  std::unique_ptr<ObjectPoolLinkInfo> object_pool_patch_info_;

  // Base snapshot data (from release build)
  const uint8_t* base_vm_data_ = nullptr;
  intptr_t base_vm_data_size_ = 0;
  const uint8_t* base_vm_instrs_ = nullptr;
  intptr_t base_vm_instrs_size_ = 0;
  const uint8_t* base_isolate_data_ = nullptr;
  intptr_t base_isolate_data_size_ = 0;
  const uint8_t* base_isolate_instrs_ = nullptr;
  intptr_t base_isolate_instrs_size_ = 0;

  // Set of function entry points that can run natively
  std::unordered_set<uword> native_functions_;

  // Results from linking
  std::vector<FunctionLinkInfo> link_results_;

  bool initialized_ = false;
  double link_percentage_ = 0.0;

  // Disable copy and assign
  QuicuiLinker(const QuicuiLinker&) = delete;
  QuicuiLinker& operator=(const QuicuiLinker&) = delete;
};

}  // namespace quicui
}  // namespace dart

#endif  // RUNTIME_VM_QUICUI_LINKER_H_
