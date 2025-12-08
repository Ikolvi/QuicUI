// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/quicui_patch_loader.h"

#include <fstream>
#include <sstream>
#include <sys/stat.h>
#include <unistd.h>
#include <dirent.h>
#include <cstring>

#include "flutter/fml/logging.h"
#include "flutter/fml/paths.h"

namespace flutter {

QuicUIPatchLoader::QuicUIPatchLoader() = default;

QuicUIPatchLoader::~QuicUIPatchLoader() = default;

void QuicUIPatchLoader::SetCodeCacheDir(const std::string& dir) {
  code_cache_dir_ = dir;
  FML_LOG(INFO) << "QuicUI: Code cache directory set to: " << dir;
}

std::string QuicUIPatchLoader::GetPatchesDir() const {
  if (code_cache_dir_.empty()) {
    return "";
  }
  return fml::paths::JoinPaths({code_cache_dir_, "quicui_patches"});
}

#ifdef TARGET_OS_IOS
std::string QuicUIPatchLoader::GetIOSPatchesStateDir() const {
  if (code_cache_dir_.empty()) {
    return "";
  }
  return fml::paths::JoinPaths({code_cache_dir_, "patches"});
}

std::string QuicUIPatchLoader::GetIOSPatchIdFromState() const {
  std::string state_path = fml::paths::JoinPaths({GetIOSPatchesStateDir(), "patches_state.json"});
  if (!FileExists(state_path)) {
    return "";
  }
  
  std::ifstream file(state_path);
  if (!file.is_open()) {
    return "";
  }
  
  std::string content((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
  
  // Extract patch number (iOS stores as "number": 1764259825584)
  size_t pos = content.find("\"number\"");
  if (pos == std::string::npos) return "";
  
  pos = content.find(":", pos);
  if (pos == std::string::npos) return "";
  
  // Skip whitespace
  while (pos < content.length() && (content[pos] == ':' || content[pos] == ' ')) pos++;
  
  size_t end = pos;
  while (end < content.length() && isdigit(content[end])) end++;
  
  if (end > pos) {
    return content.substr(pos, end - pos);
  }
  
  return "";
}
#endif


std::string QuicUIPatchLoader::GetPatchFilePath(const std::string& architecture) const {
  std::string patches_dir = GetPatchesDir();
  if (patches_dir.empty()) {
    return "";
  }
  
  #ifdef TARGET_OS_IOS
    // iOS: patches/{patchId}/dlc.vmcode
    std::string patch_id = GetIOSPatchIdFromState();
    if (patch_id.empty()) {
      return "";
    }
    std::string ios_patches_dir = GetIOSPatchesStateDir();
    return fml::paths::JoinPaths({ios_patches_dir, patch_id, "dlc.vmcode"});
  #else
    // Android: quicui_patches/libapp_patched_{arch}.so
  return fml::paths::JoinPaths({patches_dir, "libapp_patched_" + architecture + ".so"});
  #endif
}

std::string QuicUIPatchLoader::GetMetadataPath() const {
  std::string patches_dir = GetPatchesDir();
  if (patches_dir.empty()) {
    return "";
  }
  
  #ifdef TARGET_OS_IOS
    // iOS: patches/patches_state.json
    std::string ios_patches_dir = GetIOSPatchesStateDir();
    return fml::paths::JoinPaths({ios_patches_dir, "patches_state.json"});
  #else
    // Android: quicui_patches/metadata.json
  return fml::paths::JoinPaths({patches_dir, "metadata.json"});
  #endif
}

bool QuicUIPatchLoader::FileExists(const std::string& path) const {
  struct stat buffer;
  return (stat(path.c_str(), &buffer) == 0);
}

size_t QuicUIPatchLoader::GetFileSize(const std::string& path) {
  struct stat buffer;
  if (stat(path.c_str(), &buffer) != 0) {
    return 0;
  }
  return buffer.st_size;
}

std::string QuicUIPatchLoader::GetPatchedAOTPath(const std::string& architecture) {
  std::string patch_path = GetPatchFilePath(architecture);
  
  if (patch_path.empty()) {
    FML_LOG(INFO) << "QuicUI: Code cache directory not set";
    return "";
  }

  if (!FileExists(patch_path)) {
    FML_LOG(INFO) << "QuicUI: No patch found for " << architecture;
    return "";
  }

  // Load and validate metadata
  QuicUIPatchInfo info;
  if (!LoadPatchMetadata(info)) {
    FML_LOG(WARNING) << "QuicUI: Failed to load patch metadata";
    return "";
  }

  // Validate patch file hash
  if (!ValidateAOTSnapshot(patch_path, info.patch_hash)) {
    FML_LOG(ERROR) << "QuicUI: Patch validation failed, clearing corrupt patch";
    ClearInstalledPatch();
    return "";
  }

  FML_LOG(INFO) << "QuicUI: Found valid patch at: " << patch_path;
  FML_LOG(INFO) << "QuicUI: Patch version: " << info.version;
  
  return patch_path;
}

bool QuicUIPatchLoader::HasInstalledPatch() {
  std::string metadata_path = GetMetadataPath();
  return !metadata_path.empty() && FileExists(metadata_path);
}

std::string QuicUIPatchLoader::GetInstalledPatchVersion() {
  QuicUIPatchInfo info;
  if (LoadPatchMetadata(info)) {
    return info.version;
  }
  return "";
}

bool QuicUIPatchLoader::InstallPatch(const std::string& patch_path,
                                     const std::string& architecture,
                                     const std::string& expected_hash,
                                     const std::string& signature) {
  FML_LOG(INFO) << "QuicUI: Installing patch from: " << patch_path;
  FML_LOG(INFO) << "QuicUI: Target architecture: " << architecture;

  // Validate source file exists
  if (!FileExists(patch_path)) {
    FML_LOG(ERROR) << "QuicUI: Source patch file not found";
    return false;
  }

  // Validate hash
  if (!expected_hash.empty() && !ValidateAOTSnapshot(patch_path, expected_hash)) {
    FML_LOG(ERROR) << "QuicUI: Patch hash validation failed";
    return false;
  }

  // Create patches directory
  std::string patches_dir = GetPatchesDir();
  if (!CreateDirectory(patches_dir)) {
    FML_LOG(ERROR) << "QuicUI: Failed to create patches directory";
    return false;
  }

  // Install AOT snapshot
  if (!InstallAOTSnapshot(patch_path, architecture)) {
    FML_LOG(ERROR) << "QuicUI: Failed to install AOT snapshot";
    return false;
  }

  // Save metadata
  QuicUIPatchInfo info;
  info.architecture = architecture;
  info.patch_hash = expected_hash;
  info.signature = signature;
  info.requires_restart = true;
  
  if (!SavePatchMetadata(info)) {
    FML_LOG(WARNING) << "QuicUI: Failed to save metadata (patch still installed)";
  }

  FML_LOG(INFO) << "QuicUI: Patch installed successfully";
  FML_LOG(INFO) << "QuicUI: App restart required to apply patch";
  
  return true;
}

bool QuicUIPatchLoader::InstallAOTSnapshot(const std::string& source_path,
                                           const std::string& architecture) {
  std::string dest_path = GetPatchFilePath(architecture);
  
  if (!CopyFile(source_path, dest_path)) {
    return false;
  }

  // Make executable
  if (chmod(dest_path.c_str(), 0755) != 0) {
    FML_LOG(WARNING) << "QuicUI: Failed to set executable permission";
  }

  FML_LOG(INFO) << "QuicUI: AOT snapshot installed to: " << dest_path;
  return true;
}

bool QuicUIPatchLoader::ClearInstalledPatch() {
  std::string patches_dir = GetPatchesDir();
  if (patches_dir.empty() || !FileExists(patches_dir)) {
    return true;  // Nothing to clear
  }

  FML_LOG(INFO) << "QuicUI: Clearing installed patches";
  
  bool success = DeleteDirectory(patches_dir);
  if (success) {
    FML_LOG(INFO) << "QuicUI: Patches cleared successfully";
  } else {
    FML_LOG(ERROR) << "QuicUI: Failed to clear patches";
  }
  
  return success;
}

bool QuicUIPatchLoader::ValidateAOTSnapshot(const std::string& path,
                                            const std::string& expected_hash) {
  if (expected_hash.empty()) {
    return true;  // No hash to validate
  }

  std::string actual_hash = CalculateFileHash(path);
  bool valid = (actual_hash == expected_hash);
  
  if (!valid) {
    FML_LOG(ERROR) << "QuicUI: Hash mismatch";
    FML_LOG(ERROR) << "  Expected: " << expected_hash;
    FML_LOG(ERROR) << "  Actual:   " << actual_hash;
  }
  
  return valid;
}

std::string QuicUIPatchLoader::CalculateFileHash(const std::string& path) {
  // Use system shasum command for now
  // TODO: Replace with proper SHA-256 implementation
  std::string command = "shasum -a 256 \"" + path + "\" | awk '{print $1}'";
  
  FILE* pipe = popen(command.c_str(), "r");
  if (!pipe) {
    FML_LOG(ERROR) << "QuicUI: Failed to calculate hash";
    return "";
  }

  char buffer[128];
  std::string hash;
  while (fgets(buffer, sizeof(buffer), pipe) != nullptr) {
    hash += buffer;
  }
  pclose(pipe);

  // Remove trailing newline
  if (!hash.empty() && hash[hash.length() - 1] == '\n') {
    hash.erase(hash.length() - 1);
  }

  return hash;
}

bool QuicUIPatchLoader::CreateDirectory(const std::string& path) {
  if (FileExists(path)) {
    return true;
  }

  // Create parent directories recursively
  size_t pos = path.find_last_of('/');
  if (pos != std::string::npos) {
    std::string parent = path.substr(0, pos);
    if (!parent.empty() && !FileExists(parent)) {
      if (!CreateDirectory(parent)) {
        return false;
      }
    }
  }

  if (mkdir(path.c_str(), 0755) != 0 && errno != EEXIST) {
    FML_LOG(ERROR) << "QuicUI: Failed to create directory: " << path;
    FML_LOG(ERROR) << "  Error: " << strerror(errno);
    return false;
  }

  return true;
}

bool QuicUIPatchLoader::DeleteDirectory(const std::string& path) {
  DIR* dir = opendir(path.c_str());
  if (!dir) {
    return false;
  }

  struct dirent* entry;
  bool success = true;

  while ((entry = readdir(dir)) != nullptr) {
    if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
      continue;
    }

    std::string full_path = fml::paths::JoinPaths({path, entry->d_name});
    
    struct stat st;
    if (stat(full_path.c_str(), &st) == 0) {
      if (S_ISDIR(st.st_mode)) {
        success = DeleteDirectory(full_path) && success;
      } else {
        success = (unlink(full_path.c_str()) == 0) && success;
      }
    }
  }

  closedir(dir);
  success = (rmdir(path.c_str()) == 0) && success;
  
  return success;
}

bool QuicUIPatchLoader::CopyFile(const std::string& source, const std::string& dest) {
  std::ifstream src(source, std::ios::binary);
  if (!src.is_open()) {
    FML_LOG(ERROR) << "QuicUI: Failed to open source file: " << source;
    return false;
  }

  std::ofstream dst(dest, std::ios::binary);
  if (!dst.is_open()) {
    FML_LOG(ERROR) << "QuicUI: Failed to create destination file: " << dest;
    return false;
  }

  dst << src.rdbuf();
  
  if (!dst.good() || !src.good()) {
    FML_LOG(ERROR) << "QuicUI: File copy failed";
    return false;
  }

  return true;
}

bool QuicUIPatchLoader::SavePatchMetadata(const QuicUIPatchInfo& info) {
  std::string metadata_path = GetMetadataPath();
  if (metadata_path.empty()) {
    return false;
  }

  // Create JSON manually (simple implementation)
  std::ostringstream json;
  json << "{\n";
  json << "  \"version\": \"" << info.version << "\",\n";
  json << "  \"platform\": \"" << info.platform << "\",\n";
  json << "  \"architecture\": \"" << info.architecture << "\",\n";
  json << "  \"patch_hash\": \"" << info.patch_hash << "\",\n";
  json << "  \"signature\": \"" << info.signature << "\",\n";
  json << "  \"release_date\": \"" << info.release_date << "\",\n";
  json << "  \"critical\": " << (info.critical ? "true" : "false") << ",\n";
  json << "  \"requires_restart\": " << (info.requires_restart ? "true" : "false") << "\n";
  json << "}\n";

  std::ofstream file(metadata_path);
  if (!file.is_open()) {
    FML_LOG(ERROR) << "QuicUI: Failed to write metadata";
    return false;
  }

  file << json.str();
  return file.good();
}

bool QuicUIPatchLoader::LoadPatchMetadata(QuicUIPatchInfo& info) {
  std::string metadata_path = GetMetadataPath();
  if (metadata_path.empty() || !FileExists(metadata_path)) {
    return false;
  }

  std::ifstream file(metadata_path);
  if (!file.is_open()) {
    return false;
  }

  std::string content((std::istreambuf_iterator<char>(file)),
                      std::istreambuf_iterator<char>());

  // Simple JSON parsing (extract values between quotes)
  auto extract_string = [&content](const std::string& key) -> std::string {
    size_t pos = content.find("\"" + key + "\"");
    if (pos == std::string::npos) return "";
    
    pos = content.find("\"", pos + key.length() + 2);
    if (pos == std::string::npos) return "";
    pos++;
    
    size_t end = content.find("\"", pos);
    if (end == std::string::npos) return "";
    
    return content.substr(pos, end - pos);
  };

  auto extract_bool = [&content](const std::string& key) -> bool {
    size_t pos = content.find("\"" + key + "\"");
    if (pos == std::string::npos) return false;
    
    pos = content.find(":", pos);
    if (pos == std::string::npos) return false;
    
    return content.find("true", pos) < content.find("false", pos);
  };

  info.version = extract_string("version");
  info.platform = extract_string("platform");
  info.architecture = extract_string("architecture");
  info.patch_hash = extract_string("patch_hash");
  info.signature = extract_string("signature");
  info.release_date = extract_string("release_date");
  info.critical = extract_bool("critical");
  info.requires_restart = extract_bool("requires_restart");

  return !info.architecture.empty();
}

std::string QuicUIPatchLoader::GetPatchInfoJSON() {
  QuicUIPatchInfo info;
  if (!LoadPatchMetadata(info)) {
    return "";
  }

  // Build simple JSON string
  std::string json = "{\n";
  json += "  \"version\": \"" + info.version + "\",\n";
  json += "  \"platform\": \"" + info.platform + "\",\n";
  json += "  \"architecture\": \"" + info.architecture + "\",\n";
  json += "  \"patch_hash\": \"" + info.patch_hash + "\",\n";
  json += "  \"signature\": \"" + info.signature + "\",\n";
  json += "  \"release_date\": \"" + info.release_date + "\",\n";
  json += "  \"critical\": " + std::string(info.critical ? "true" : "false") + ",\n";
  json += "  \"requires_restart\": " + std::string(info.requires_restart ? "true" : "false") + "\n";
  json += "}";

  return json;
}

}  // namespace flutter
