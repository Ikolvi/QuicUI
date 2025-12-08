// Copyright (c) 2025 QuicUI Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Link Info Extractor for QuicUI Code Push
// Extracts function entry points from compiled snapshots for patch generation.

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>
#include <map>
#include <string>

namespace quicui {

// Represents a function's linking information
struct FunctionInfo {
  uint32_t function_id;         // Unique identifier
  uint32_t hash;                // Content hash for comparison
  uint64_t entry_point;         // Code entry point offset
  uint64_t code_size;           // Size of compiled code
  const char* name;             // Function name (for debugging)
  const char* class_name;       // Class name if method
  bool is_closure;              // Whether this is a closure
};

// Link info header format
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

// Extracts link info from a compiled snapshot
class LinkInfoExtractor {
 public:
  LinkInfoExtractor() = default;
  ~LinkInfoExtractor() = default;

  // Extract link info from snapshot and write to output file
  bool Extract(const char* snapshot_path, const char* output_path) {
    // Read snapshot file
    FILE* snapshot_file = fopen(snapshot_path, "rb");
    if (!snapshot_file) {
      fprintf(stderr, "Error: Cannot open snapshot file: %s\n", snapshot_path);
      return false;
    }

    fseek(snapshot_file, 0, SEEK_END);
    size_t snapshot_size = ftell(snapshot_file);
    fseek(snapshot_file, 0, SEEK_SET);

    uint8_t* snapshot_data = static_cast<uint8_t*>(malloc(snapshot_size));
    if (!snapshot_data) {
      fclose(snapshot_file);
      fprintf(stderr, "Error: Cannot allocate memory for snapshot\n");
      return false;
    }

    size_t read_size = fread(snapshot_data, 1, snapshot_size, snapshot_file);
    fclose(snapshot_file);

    if (read_size != snapshot_size) {
      free(snapshot_data);
      fprintf(stderr, "Error: Failed to read snapshot file\n");
      return false;
    }

    // Parse snapshot and extract function info
    std::vector<FunctionInfo> functions;
    if (!ParseSnapshot(snapshot_data, snapshot_size, functions)) {
      free(snapshot_data);
      return false;
    }

    free(snapshot_data);

    // Write link info
    return WriteLinkInfo(output_path, functions);
  }

 private:
  // Parse snapshot to extract function information
  bool ParseSnapshot(const uint8_t* data, size_t size,
                     std::vector<FunctionInfo>& functions) {
    // Snapshot format detection
    // Check for ELF magic
    if (size >= 4 && data[0] == 0x7F && data[1] == 'E' && 
        data[2] == 'L' && data[3] == 'F') {
      return ParseElfSnapshot(data, size, functions);
    }
    
    // Check for Mach-O magic (fat or single-arch)
    uint32_t magic = *reinterpret_cast<const uint32_t*>(data);
    if (magic == 0xFEEDFACE || magic == 0xFEEDFACF ||
        magic == 0xCAFEBABE || magic == 0xBEBAFECA) {
      return ParseMachOSnapshot(data, size, functions);
    }
    
    // Try as raw AOT blob
    return ParseBlobSnapshot(data, size, functions);
  }

  // Parse ELF format snapshot
  bool ParseElfSnapshot(const uint8_t* data, size_t size,
                        std::vector<FunctionInfo>& functions) {
    // ELF header parsing
    const uint8_t* ptr = data;
    
    // Skip ELF header (64-bit assumed for iOS simulator)
    bool is_64bit = (data[4] == 2);
    size_t ehdr_size = is_64bit ? 64 : 52;
    
    if (size < ehdr_size) {
      fprintf(stderr, "Error: Invalid ELF header\n");
      return false;
    }
    
    // Read section header info from ELF header
    uint64_t shoff;
    uint16_t shentsize, shnum, shstrndx;
    
    if (is_64bit) {
      shoff = *reinterpret_cast<const uint64_t*>(data + 40);
      shentsize = *reinterpret_cast<const uint16_t*>(data + 58);
      shnum = *reinterpret_cast<const uint16_t*>(data + 60);
      shstrndx = *reinterpret_cast<const uint16_t*>(data + 62);
    } else {
      shoff = *reinterpret_cast<const uint32_t*>(data + 32);
      shentsize = *reinterpret_cast<const uint16_t*>(data + 46);
      shnum = *reinterpret_cast<const uint16_t*>(data + 48);
      shstrndx = *reinterpret_cast<const uint16_t*>(data + 50);
    }
    
    // Find _kDartVmSnapshotInstructions section
    // For now, use simplified extraction
    printf("ELF snapshot: %zu bytes, %d sections\n", size, shnum);
    
    // Extract dispatch table info
    return ExtractDispatchTable(data, size, functions);
  }

  // Parse Mach-O format snapshot
  bool ParseMachOSnapshot(const uint8_t* data, size_t size,
                          std::vector<FunctionInfo>& functions) {
    const uint8_t* ptr = data;
    uint32_t magic = *reinterpret_cast<const uint32_t*>(ptr);
    
    bool is_fat = (magic == 0xCAFEBABE || magic == 0xBEBAFECA);
    bool is_64bit = (magic == 0xFEEDFACF);
    
    if (is_fat) {
      // Handle fat binary - find arm64 slice
      printf("Fat Mach-O binary detected\n");
      // For now, skip to first slice
      uint32_t nfat_arch = *reinterpret_cast<const uint32_t*>(ptr + 4);
      // TODO: Find arm64 slice
    }
    
    printf("Mach-O snapshot: %zu bytes, 64-bit: %s\n", 
           size, is_64bit ? "yes" : "no");
    
    return ExtractDispatchTable(data, size, functions);
  }

  // Parse raw blob format snapshot  
  bool ParseBlobSnapshot(const uint8_t* data, size_t size,
                         std::vector<FunctionInfo>& functions) {
    printf("Blob snapshot: %zu bytes\n", size);
    return ExtractDispatchTable(data, size, functions);
  }

  // Extract dispatch table entries as function info
  bool ExtractDispatchTable(const uint8_t* data, size_t size,
                            std::vector<FunctionInfo>& functions) {
    // Search for dispatch table pattern
    // Dispatch table entries are typically:
    // - Array of code entry points (pointers)
    // - Can identify by looking for sequences of valid code addresses
    
    // For now, create placeholder entries
    // In production, this would parse the actual dispatch table
    
    FunctionInfo placeholder;
    placeholder.function_id = 0;
    placeholder.hash = ComputeHash(data, size);
    placeholder.entry_point = 0;
    placeholder.code_size = size;
    placeholder.name = "snapshot_root";
    placeholder.class_name = nullptr;
    placeholder.is_closure = false;
    
    functions.push_back(placeholder);
    
    printf("Extracted %zu function entries\n", functions.size());
    return true;
  }

  // Compute a simple hash of data
  uint32_t ComputeHash(const uint8_t* data, size_t size) {
    uint32_t hash = 0;
    for (size_t i = 0; i < size; i++) {
      hash = hash * 31 + data[i];
    }
    return hash;
  }

  // Write link info to file
  bool WriteLinkInfo(const char* path,
                     const std::vector<FunctionInfo>& functions) {
    FILE* file = fopen(path, "wb");
    if (!file) {
      fprintf(stderr, "Error: Cannot create output file: %s\n", path);
      return false;
    }

    // Write header
    LinkInfoHeader header;
    header.magic = LINK_INFO_MAGIC;
    header.version = LINK_INFO_VERSION;
    header.function_count = static_cast<uint32_t>(functions.size());
    header.dispatch_table_size = 0;  // Filled in later
    header.code_section_offset = 0;
    header.code_section_size = 0;
    
    fwrite(&header, sizeof(header), 1, file);

    // Write function entries
    for (const auto& func : functions) {
      fwrite(&func.function_id, sizeof(uint32_t), 1, file);
      fwrite(&func.hash, sizeof(uint32_t), 1, file);
      fwrite(&func.entry_point, sizeof(uint64_t), 1, file);
      fwrite(&func.code_size, sizeof(uint64_t), 1, file);
      
      // Write name as null-terminated string
      size_t name_len = func.name ? strlen(func.name) : 0;
      fwrite(&name_len, sizeof(uint32_t), 1, file);
      if (name_len > 0) {
        fwrite(func.name, 1, name_len, file);
      }
    }

    fclose(file);
    printf("Wrote link info to: %s\n", path);
    return true;
  }
};

}  // namespace quicui

// Main entry point
int main(int argc, char* argv[]) {
  if (argc < 3) {
    fprintf(stderr, "Usage: %s <snapshot-file> <output-linkinfo>\n", argv[0]);
    fprintf(stderr, "\n");
    fprintf(stderr, "Extracts function link information from compiled Dart "
                    "snapshots\n");
    fprintf(stderr, "for use in QuicUI code push patch generation.\n");
    return 1;
  }

  const char* snapshot_path = argv[1];
  const char* output_path = argv[2];

  quicui::LinkInfoExtractor extractor;
  if (!extractor.Extract(snapshot_path, output_path)) {
    return 1;
  }

  return 0;
}
