// Copyright (c) 2025 QuicUI Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef RUNTIME_VM_QUICUI_LINK_INFO_H_
#define RUNTIME_VM_QUICUI_LINK_INFO_H_

#include <map>
#include <memory>
#include <string>
#include <vector>

#include "platform/globals.h"

namespace dart {
namespace quicui {

// Base class for link information
class LinkInfo {
 public:
  virtual ~LinkInfo() = default;
  virtual bool IsInitialized() const = 0;
};

// Class table link information
// Maps class IDs between base and patch snapshots
class ClassTableLinkInfo : public LinkInfo {
 public:
  ClassTableLinkInfo() = default;
  ~ClassTableLinkInfo() override = default;

  bool IsInitialized() const override { return initialized_; }

  // Map a class ID from base to patch
  intptr_t MapClassId(intptr_t base_class_id) const {
    auto it = class_id_map_.find(base_class_id);
    return it != class_id_map_.end() ? it->second : -1;
  }

  // Get class ID by name
  intptr_t GetClassIdByName(const std::string& name) const {
    auto it = class_name_to_id_.find(name);
    return it != class_name_to_id_.end() ? it->second : -1;
  }

  // Add a class ID mapping
  void AddMapping(intptr_t base_id, intptr_t patch_id) {
    class_id_map_[base_id] = patch_id;
  }

  // Add a class name to ID mapping
  void AddNameMapping(const std::string& name, intptr_t id) {
    class_name_to_id_[name] = id;
  }

  void MarkInitialized() { initialized_ = true; }

  // Parse from JSON file content
  static std::unique_ptr<ClassTableLinkInfo> ParseFromJson(
      const std::string& json_content);

  // Parse from binary link file
  static std::unique_ptr<ClassTableLinkInfo> ParseFromBinary(
      const uint8_t* data,
      intptr_t size);

 private:
  std::map<intptr_t, intptr_t> class_id_map_;
  std::map<std::string, intptr_t> class_name_to_id_;
  bool initialized_ = false;
};

// Field table link information
class FieldTableLinkInfo : public LinkInfo {
 public:
  FieldTableLinkInfo() = default;
  ~FieldTableLinkInfo() override = default;

  bool IsInitialized() const override { return initialized_; }

  // Map a field offset from base to patch
  intptr_t MapFieldOffset(intptr_t base_offset) const {
    auto it = field_offset_map_.find(base_offset);
    return it != field_offset_map_.end() ? it->second : -1;
  }

  // Add a field offset mapping
  void AddMapping(intptr_t base_offset, intptr_t patch_offset) {
    field_offset_map_[base_offset] = patch_offset;
  }

  void MarkInitialized() { initialized_ = true; }

  // Parse from JSON file content
  static std::unique_ptr<FieldTableLinkInfo> ParseFromJson(
      const std::string& json_content);

  // Parse from binary link file
  static std::unique_ptr<FieldTableLinkInfo> ParseFromBinary(
      const uint8_t* data,
      intptr_t size);

 private:
  std::map<intptr_t, intptr_t> field_offset_map_;
  bool initialized_ = false;
};

// Dispatch table link information
class DispatchTableLinkInfo : public LinkInfo {
 public:
  DispatchTableLinkInfo() = default;
  ~DispatchTableLinkInfo() override = default;

  bool IsInitialized() const override { return initialized_; }

  // Map a selector ID from base to patch
  intptr_t MapSelectorId(intptr_t base_selector_id) const {
    auto it = selector_id_map_.find(base_selector_id);
    return it != selector_id_map_.end() ? it->second : -1;
  }

  // Add a selector ID mapping
  void AddMapping(intptr_t base_id, intptr_t patch_id) {
    selector_id_map_[base_id] = patch_id;
  }

  void MarkInitialized() { initialized_ = true; }

  // Parse from JSON file content
  static std::unique_ptr<DispatchTableLinkInfo> ParseFromJson(
      const std::string& json_content);

  // Parse from binary link file
  static std::unique_ptr<DispatchTableLinkInfo> ParseFromBinary(
      const uint8_t* data,
      intptr_t size);

 private:
  std::map<intptr_t, intptr_t> selector_id_map_;
  bool initialized_ = false;
};

// Object pool link information
class ObjectPoolLinkInfo : public LinkInfo {
 public:
  ObjectPoolLinkInfo() = default;
  ~ObjectPoolLinkInfo() override = default;

  bool IsInitialized() const override { return initialized_; }

  // Map an object pool index from base to patch
  intptr_t MapObjectIndex(intptr_t base_index) const {
    auto it = object_index_map_.find(base_index);
    return it != object_index_map_.end() ? it->second : -1;
  }

  // Add an object index mapping
  void AddMapping(intptr_t base_index, intptr_t patch_index) {
    object_index_map_[base_index] = patch_index;
  }

  void MarkInitialized() { initialized_ = true; }

  // Parse from JSON file content
  static std::unique_ptr<ObjectPoolLinkInfo> ParseFromJson(
      const std::string& json_content);

  // Parse from binary link file
  static std::unique_ptr<ObjectPoolLinkInfo> ParseFromBinary(
      const uint8_t* data,
      intptr_t size);

 private:
  std::map<intptr_t, intptr_t> object_index_map_;
  bool initialized_ = false;
};

}  // namespace quicui
}  // namespace dart

#endif  // RUNTIME_VM_QUICUI_LINK_INFO_H_
