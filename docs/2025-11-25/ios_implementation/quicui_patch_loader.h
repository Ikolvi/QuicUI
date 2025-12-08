// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_QUICUI_PATCH_LOADER_H_
#define FLUTTER_SHELL_COMMON_QUICUI_PATCH_LOADER_H_

#include <string>
#include <memory>
#include <functional>

namespace flutter {

/// QuicUI patch metadata
struct QuicUIPatchInfo {
  std::string version;
  std::string platform;
  std::string architecture;  // arm64-v8a, armeabi-v7a, x86_64
  std::string patch_hash;
  std::string signature;
  std::string release_date;
  bool critical;
  bool requires_restart;
  
  QuicUIPatchInfo() : critical(false), requires_restart(true) {}
};

/// Manages AOT snapshot patches for QuicUI code push
/// 
/// This class handles:
/// - Checking for installed patches
/// - Loading patched AOT snapshots
/// - Validating patch integrity
/// - Rollback support
class QuicUIPatchLoader {
 public:
  QuicUIPatchLoader();
  ~QuicUIPatchLoader();

  /// Set the code cache directory (platform-specific)
  /// e.g., /data/data/com.example.app/code_cache on Android
  void SetCodeCacheDir(const std::string& dir);

  /// Get the path to patched AOT snapshot if available
  /// Returns empty string if no valid patch found
  /// 
  /// @param architecture Target architecture (arm64-v8a, etc.)
  /// @return Path to patched libapp.so or empty string
  std::string GetPatchedAOTPath(const std::string& architecture);

  /// Check if a patch is installed
  bool HasInstalledPatch();

  /// Get installed patch version
  std::string GetInstalledPatchVersion();

  /// Install an AOT patch from downloaded file
  /// 
  /// @param patch_path Path to downloaded patch file
  /// @param architecture Target architecture
  /// @param expected_hash Expected SHA-256 hash
  /// @param signature Ed25519 signature (optional, for future security)
  /// @return true if installation succeeded
  bool InstallPatch(const std::string& patch_path,
                   const std::string& architecture,
                   const std::string& expected_hash,
                   const std::string& signature = "");

  /// Clear installed patch (rollback)
  /// @return true if successfully cleared
  bool ClearInstalledPatch();

  /// Validate AOT snapshot integrity
  /// @param path Path to snapshot file
  /// @param expected_hash Expected SHA-256 hash
  /// @return true if valid
  bool ValidateAOTSnapshot(const std::string& path,
                          const std::string& expected_hash);

  /// Get patch information as JSON string
  /// @return JSON string with patch metadata, or empty if no patch
  std::string GetPatchInfoJSON();

 private:
  std::string code_cache_dir_;

  /// Get patches directory path
  std::string GetPatchesDir() const;

  /// Get patch file path for architecture
  std::string GetPatchFilePath(const std::string& architecture) const;

  /// Get metadata file path
  std::string GetMetadataPath() const;

  /// Install AOT snapshot to code cache
  bool InstallAOTSnapshot(const std::string& source_path,
                         const std::string& architecture);

  /// Save patch metadata
  bool SavePatchMetadata(const QuicUIPatchInfo& info);

  /// Load patch metadata
  bool LoadPatchMetadata(QuicUIPatchInfo& info);

  /// Calculate SHA-256 hash of file
  std::string CalculateFileHash(const std::string& path);

  /// Check if file exists
  bool FileExists(const std::string& path);

  /// Get file size
  size_t GetFileSize(const std::string& path);

  /// Create directory recursively
  bool CreateDirectory(const std::string& path);

  /// Delete directory recursively
  bool DeleteDirectory(const std::string& path);

  /// Copy file
  bool CopyFile(const std::string& source, const std::string& dest);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_QUICUI_PATCH_LOADER_H_
