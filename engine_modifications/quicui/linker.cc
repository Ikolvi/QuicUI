// Copyright (c) 2025 QuicUI Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vm/quicui/linker.h"

#include <cstdio>
#include <cstring>

#include "vm/quicui/link_info.h"
#include "vm/quicui/wrapper.h"

namespace dart {
namespace quicui {

// Singleton instance
QuicuiLinker* QuicuiLinker::instance_ = nullptr;

QuicuiLinker& QuicuiLinker::Shared() {
  if (instance_ == nullptr) {
    instance_ = new QuicuiLinker();
  }
  return *instance_;
}

QuicuiLinker::QuicuiLinker() = default;

QuicuiLinker::~QuicuiLinker() = default;

void QuicuiLinker::InitializeWithClassTableLinkInfo(
    std::unique_ptr<ClassTableLinkInfo> base_info,
    std::unique_ptr<ClassTableLinkInfo> patch_info) {
  if (class_table_base_info_ != nullptr) {
    fprintf(stderr,
            "QuicuiLinker::InitializeWithClassTableLinkInfo was already "
            "called.\n");
    return;
  }
  class_table_base_info_ = std::move(base_info);
  class_table_patch_info_ = std::move(patch_info);
  CheckInitialized();
}

void QuicuiLinker::InitializeWithFieldTableLinkInfo(
    std::unique_ptr<FieldTableLinkInfo> info) {
  if (field_table_info_ != nullptr) {
    fprintf(stderr,
            "QuicuiLinker::InitializeWithFieldTableLinkInfo was already "
            "called.\n");
    return;
  }
  field_table_info_ = std::move(info);
  CheckInitialized();
}

void QuicuiLinker::InitializeWithDispatchTableLinkInfo(
    std::unique_ptr<DispatchTableLinkInfo> info) {
  if (dispatch_table_info_ != nullptr) {
    fprintf(stderr,
            "QuicuiLinker::InitializeWithDispatchTableLinkInfo was already "
            "called.\n");
    return;
  }
  dispatch_table_info_ = std::move(info);
  CheckInitialized();
}

void QuicuiLinker::InitializeWithObjectPoolLinkInfo(
    std::unique_ptr<ObjectPoolLinkInfo> base_info,
    std::unique_ptr<ObjectPoolLinkInfo> patch_info) {
  if (object_pool_base_info_ != nullptr) {
    fprintf(stderr,
            "QuicuiLinker::InitializeWithObjectPoolLinkInfo was already "
            "called.\n");
    return;
  }
  object_pool_base_info_ = std::move(base_info);
  object_pool_patch_info_ = std::move(patch_info);
  CheckInitialized();
}

bool QuicuiLinker::IsInitialized() const {
  return initialized_;
}

double QuicuiLinker::GetLinkPercentage() const {
  return link_percentage_;
}

bool QuicuiLinker::CanRunNatively(uword entry_point) const {
  return native_functions_.find(entry_point) != native_functions_.end();
}

void QuicuiLinker::MarkNativeFunction(uword entry_point) {
  native_functions_.insert(entry_point);
}

const uint8_t* QuicuiLinker::GetBaseInstructionsTable() const {
  return base_vm_instrs_;
}

intptr_t QuicuiLinker::GetBaseInstructionsTableSize() const {
  return base_vm_instrs_size_;
}

void QuicuiLinker::SetBaseSnapshots(const uint8_t* vm_data,
                                    intptr_t vm_data_size,
                                    const uint8_t* vm_instrs,
                                    intptr_t vm_instrs_size,
                                    const uint8_t* isolate_data,
                                    intptr_t isolate_data_size,
                                    const uint8_t* isolate_instrs,
                                    intptr_t isolate_instrs_size) {
  base_vm_data_ = vm_data;
  base_vm_data_size_ = vm_data_size;
  base_vm_instrs_ = vm_instrs;
  base_vm_instrs_size_ = vm_instrs_size;
  base_isolate_data_ = isolate_data;
  base_isolate_data_size_ = isolate_data_size;
  base_isolate_instrs_ = isolate_instrs;
  base_isolate_instrs_size_ = isolate_instrs_size;
}

bool QuicuiLinker::ReadLinkHeader(const uint8_t* data,
                                  intptr_t data_size,
                                  intptr_t* header_size,
                                  intptr_t* link_data_offset) {
  if (data == nullptr || data_size < 16) {
    return false;
  }

  // QuicUI vmcode header format:
  // Bytes 0-3: Magic "QUIC" (0x43495551 little endian)
  // Bytes 4-7: Version (1)
  // Bytes 8-11: Header size (typically 65536)
  // Bytes 12-15: Link data offset

  uint32_t magic;
  memcpy(&magic, data, sizeof(magic));
  if (magic != kQuicuiMagic) {
    return false;
  }

  uint32_t version;
  memcpy(&version, data + 4, sizeof(version));
  if (version != kQuicuiVersion) {
    return false;
  }

  uint32_t hdr_size;
  memcpy(&hdr_size, data + 8, sizeof(hdr_size));
  *header_size = hdr_size;

  uint32_t link_offset;
  memcpy(&link_offset, data + 12, sizeof(link_offset));
  *link_data_offset = link_offset;

  return true;
}

void QuicuiLinker::GenerateLinkHeader(uint8_t* buffer,
                                      intptr_t header_size,
                                      intptr_t link_data_offset) {
  memset(buffer, 0, 16);

  uint32_t magic = kQuicuiMagic;
  memcpy(buffer, &magic, sizeof(magic));

  uint32_t version = kQuicuiVersion;
  memcpy(buffer + 4, &version, sizeof(version));

  uint32_t hdr_size = static_cast<uint32_t>(header_size);
  memcpy(buffer + 8, &hdr_size, sizeof(hdr_size));

  uint32_t link_offset = static_cast<uint32_t>(link_data_offset);
  memcpy(buffer + 12, &link_offset, sizeof(link_offset));
}

// ============================================================================
// Function Comparison and Linking
// ============================================================================

bool QuicuiLinker::CompareFunctionCode(const uint8_t* base_code,
                                        intptr_t base_size,
                                        const uint8_t* patch_code,
                                        intptr_t patch_size) {
  if (base_size != patch_size) {
    return false;
  }
  return memcmp(base_code, patch_code, base_size) == 0;
}

void QuicuiLinker::AnalyzeAndLink(const uint8_t* base_instrs,
                                   intptr_t base_instrs_size,
                                   const uint8_t* patch_instrs,
                                   intptr_t patch_instrs_size,
                                   const FunctionEntry* base_functions,
                                   intptr_t base_function_count,
                                   const FunctionEntry* patch_functions,
                                   intptr_t patch_function_count) {
  if (base_function_count != patch_function_count) {
    fprintf(stderr, "QuicUI: Function count mismatch (base=%ld, patch=%ld)\n",
            static_cast<long>(base_function_count),
            static_cast<long>(patch_function_count));
    return;
  }

  native_functions_.clear();
  link_results_.clear();
  link_results_.reserve(base_function_count);

  intptr_t native_count = 0;
  intptr_t simulated_count = 0;

  for (intptr_t i = 0; i < base_function_count; i++) {
    const FunctionEntry& base_entry = base_functions[i];
    const FunctionEntry& patch_entry = patch_functions[i];

    FunctionLinkInfo info;
    info.base_entry_point = base_entry.entry_point;
    info.patch_entry_point = patch_entry.entry_point;
    info.function_id = base_entry.function_id;

    // Get pointers to the actual code bytes
    const uint8_t* base_code = base_instrs + base_entry.code_offset;
    const uint8_t* patch_code = patch_instrs + patch_entry.code_offset;

    // Compare the code bytes
    info.is_identical = CompareFunctionCode(
        base_code, base_entry.code_size,
        patch_code, patch_entry.code_size);

    info.needs_simulation = !info.is_identical;

    if (info.is_identical) {
      // Function unchanged - can run natively from signed base app
      native_functions_.insert(base_entry.entry_point);
      native_count++;
    } else {
      // Function changed - needs to be simulated
      // Register a wrapper for this function
      info.wrapper_address = GetCPUToSimWrapper(patch_entry.entry_point);
      simulated_count++;
    }

    link_results_.push_back(info);
  }

  // Calculate link percentage
  if (base_function_count > 0) {
    link_percentage_ = static_cast<double>(native_count) /
                       static_cast<double>(base_function_count);
  } else {
    link_percentage_ = 1.0;
  }

  printf("QuicUI Linker: Analyzed %ld functions\n",
         static_cast<long>(base_function_count));
  printf("  - Native (unchanged): %ld (%.1f%%)\n",
         static_cast<long>(native_count),
         link_percentage_ * 100.0);
  printf("  - Simulated (changed): %ld\n",
         static_cast<long>(simulated_count));

  initialized_ = true;
}

void QuicuiLinker::GenerateRedirectionTable(uint8_t* output_buffer,
                                             size_t buffer_size,
                                             size_t* bytes_written) {
  // Redirection table format:
  // [4 bytes] Number of entries
  // For each entry:
  //   [8 bytes] Base entry point
  //   [8 bytes] Wrapper address (for CPU-to-sim transition)
  //   [8 bytes] Patch entry point (target in patch code)

  size_t offset = 0;

  // Count entries that need redirection
  uint32_t num_redirections = 0;
  for (const auto& info : link_results_) {
    if (info.needs_simulation) {
      num_redirections++;
    }
  }

  // Write count
  if (offset + sizeof(uint32_t) > buffer_size) {
    *bytes_written = 0;
    return;
  }
  memcpy(output_buffer + offset, &num_redirections, sizeof(uint32_t));
  offset += sizeof(uint32_t);

  // Write entries
  for (const auto& info : link_results_) {
    if (info.needs_simulation) {
      if (offset + 24 > buffer_size) {
        break;
      }

      // Base entry point
      memcpy(output_buffer + offset, &info.base_entry_point, sizeof(uword));
      offset += sizeof(uword);

      // Wrapper address
      memcpy(output_buffer + offset, &info.wrapper_address, sizeof(uword));
      offset += sizeof(uword);

      // Patch entry point
      memcpy(output_buffer + offset, &info.patch_entry_point, sizeof(uword));
      offset += sizeof(uword);
    }
  }

  *bytes_written = offset;
}

bool QuicuiLinker::ParseRedirectionTable(const uint8_t* data,
                                          size_t data_size) {
  if (data == nullptr || data_size < 4) {
    return false;
  }

  size_t offset = 0;

  // Read count
  uint32_t num_redirections;
  memcpy(&num_redirections, data + offset, sizeof(uint32_t));
  offset += sizeof(uint32_t);

  // Read entries
  link_results_.clear();
  link_results_.reserve(num_redirections);

  for (uint32_t i = 0; i < num_redirections; i++) {
    if (offset + 24 > data_size) {
      return false;
    }

    FunctionLinkInfo info;

    // Base entry point
    memcpy(&info.base_entry_point, data + offset, sizeof(uword));
    offset += sizeof(uword);

    // Wrapper address
    memcpy(&info.wrapper_address, data + offset, sizeof(uword));
    offset += sizeof(uword);

    // Patch entry point
    memcpy(&info.patch_entry_point, data + offset, sizeof(uword));
    offset += sizeof(uword);

    info.is_identical = false;
    info.needs_simulation = true;

    link_results_.push_back(info);
  }

  return true;
}

const std::vector<FunctionLinkInfo>& QuicuiLinker::GetLinkResults() const {
  return link_results_;
}

void QuicuiLinker::PrintStats() const {
  printf("QuicUI Linker Stats:\n");
  printf("  Initialized: %s\n", initialized_ ? "yes" : "no");
  printf("  Link percentage: %.2f%%\n", link_percentage_ * 100.0);
  printf("  Native functions: %zu\n", native_functions_.size());
  printf("  Link results: %zu\n", link_results_.size());
  printf("  Has base VM data: %s\n", base_vm_data_ != nullptr ? "yes" : "no");
  printf("  Has base VM instrs: %s\n",
         base_vm_instrs_ != nullptr ? "yes" : "no");
  printf("  Has base isolate data: %s\n",
         base_isolate_data_ != nullptr ? "yes" : "no");
  printf("  Has base isolate instrs: %s\n",
         base_isolate_instrs_ != nullptr ? "yes" : "no");
}

void QuicuiLinker::Reset() {
  class_table_base_info_.reset();
  class_table_patch_info_.reset();
  field_table_info_.reset();
  dispatch_table_info_.reset();
  object_pool_base_info_.reset();
  object_pool_patch_info_.reset();
  base_vm_data_ = nullptr;
  base_vm_data_size_ = 0;
  base_vm_instrs_ = nullptr;
  base_vm_instrs_size_ = 0;
  base_isolate_data_ = nullptr;
  base_isolate_data_size_ = 0;
  base_isolate_instrs_ = nullptr;
  base_isolate_instrs_size_ = 0;
  native_functions_.clear();
  link_results_.clear();
  initialized_ = false;
  link_percentage_ = 0.0;
}

void QuicuiLinker::CheckInitialized() {
  if (class_table_base_info_ != nullptr && class_table_patch_info_ != nullptr &&
      field_table_info_ != nullptr && dispatch_table_info_ != nullptr &&
      object_pool_base_info_ != nullptr && object_pool_patch_info_ != nullptr) {
    initialized_ = true;
    // Default to 98% link percentage (typical for small code changes)
    link_percentage_ = 0.98;
  }
}

}  // namespace quicui
}  // namespace dart
