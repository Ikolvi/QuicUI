// Copyright (c) 2025 QuicUI Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "vm/quicui/link_info.h"

#include <cstring>

namespace dart {
namespace quicui {

std::unique_ptr<ClassTableLinkInfo> ClassTableLinkInfo::ParseFromJson(
    const std::string& json_content) {
  auto info = std::make_unique<ClassTableLinkInfo>();
  // TODO: Implement JSON parsing
  // For now, just mark as initialized
  info->MarkInitialized();
  return info;
}

std::unique_ptr<ClassTableLinkInfo> ClassTableLinkInfo::ParseFromBinary(
    const uint8_t* data,
    intptr_t size) {
  auto info = std::make_unique<ClassTableLinkInfo>();

  if (data == nullptr || size < 4) {
    info->MarkInitialized();
    return info;
  }

  // Binary format:
  // 4 bytes: number of entries
  // For each entry:
  //   4 bytes: class ID
  //   4 bytes: name length
  //   N bytes: class name (UTF-8)

  intptr_t offset = 0;

  uint32_t num_entries;
  memcpy(&num_entries, data + offset, sizeof(num_entries));
  offset += 4;

  for (uint32_t i = 0; i < num_entries && offset < size; i++) {
    if (offset + 8 > size) break;

    uint32_t class_id;
    memcpy(&class_id, data + offset, sizeof(class_id));
    offset += 4;

    uint32_t name_length;
    memcpy(&name_length, data + offset, sizeof(name_length));
    offset += 4;

    if (static_cast<uintptr_t>(offset) + name_length > static_cast<uintptr_t>(size)) break;

    std::string name(reinterpret_cast<const char*>(data + offset), name_length);
    offset += name_length;

    info->AddNameMapping(name, class_id);
  }

  info->MarkInitialized();
  return info;
}

std::unique_ptr<FieldTableLinkInfo> FieldTableLinkInfo::ParseFromJson(
    const std::string& json_content) {
  auto info = std::make_unique<FieldTableLinkInfo>();
  // TODO: Implement JSON parsing
  info->MarkInitialized();
  return info;
}

std::unique_ptr<FieldTableLinkInfo> FieldTableLinkInfo::ParseFromBinary(
    const uint8_t* data,
    intptr_t size) {
  auto info = std::make_unique<FieldTableLinkInfo>();

  if (data == nullptr || size < 4) {
    info->MarkInitialized();
    return info;
  }

  intptr_t offset = 0;

  uint32_t num_entries;
  memcpy(&num_entries, data + offset, sizeof(num_entries));
  offset += 4;

  for (uint32_t i = 0; i < num_entries && offset + 8 <= size; i++) {
    uint32_t base_offset;
    memcpy(&base_offset, data + offset, sizeof(base_offset));
    offset += 4;

    uint32_t patch_offset;
    memcpy(&patch_offset, data + offset, sizeof(patch_offset));
    offset += 4;

    info->AddMapping(base_offset, patch_offset);
  }

  info->MarkInitialized();
  return info;
}

std::unique_ptr<DispatchTableLinkInfo> DispatchTableLinkInfo::ParseFromJson(
    const std::string& json_content) {
  auto info = std::make_unique<DispatchTableLinkInfo>();
  // TODO: Implement JSON parsing
  info->MarkInitialized();
  return info;
}

std::unique_ptr<DispatchTableLinkInfo> DispatchTableLinkInfo::ParseFromBinary(
    const uint8_t* data,
    intptr_t size) {
  auto info = std::make_unique<DispatchTableLinkInfo>();

  if (data == nullptr || size < 4) {
    info->MarkInitialized();
    return info;
  }

  intptr_t offset = 0;

  uint32_t num_entries;
  memcpy(&num_entries, data + offset, sizeof(num_entries));
  offset += 4;

  for (uint32_t i = 0; i < num_entries && offset + 8 <= size; i++) {
    uint32_t base_id;
    memcpy(&base_id, data + offset, sizeof(base_id));
    offset += 4;

    uint32_t patch_id;
    memcpy(&patch_id, data + offset, sizeof(patch_id));
    offset += 4;

    info->AddMapping(base_id, patch_id);
  }

  info->MarkInitialized();
  return info;
}

std::unique_ptr<ObjectPoolLinkInfo> ObjectPoolLinkInfo::ParseFromJson(
    const std::string& json_content) {
  auto info = std::make_unique<ObjectPoolLinkInfo>();
  // TODO: Implement JSON parsing
  info->MarkInitialized();
  return info;
}

std::unique_ptr<ObjectPoolLinkInfo> ObjectPoolLinkInfo::ParseFromBinary(
    const uint8_t* data,
    intptr_t size) {
  auto info = std::make_unique<ObjectPoolLinkInfo>();

  if (data == nullptr || size < 4) {
    info->MarkInitialized();
    return info;
  }

  intptr_t offset = 0;

  uint32_t num_entries;
  memcpy(&num_entries, data + offset, sizeof(num_entries));
  offset += 4;

  for (uint32_t i = 0; i < num_entries && offset + 8 <= size; i++) {
    uint32_t base_index;
    memcpy(&base_index, data + offset, sizeof(base_index));
    offset += 4;

    uint32_t patch_index;
    memcpy(&patch_index, data + offset, sizeof(patch_index));
    offset += 4;

    info->AddMapping(base_index, patch_index);
  }

  info->MarkInitialized();
  return info;
}

}  // namespace quicui
}  // namespace dart
