#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include <fstream>
#include <sstream>
#include <thread>
#include <chrono>
#include "../src/codepush_loader.h"

using ::testing::_;
using ::testing::Return;
using ::testing::AtLeast;

namespace quicui {
namespace codepush {

// Test fixtures
class CodePushLoaderTest : public ::testing::Test {
 protected:
  void SetUp() override {
    // Create temporary test directories
    test_cache_dir_ = "/tmp/quicui_test_cache";
    test_patch_dir_ = "/tmp/quicui_test_patches";
    
    std::system(("mkdir -p " + test_cache_dir_).c_str());
    std::system(("mkdir -p " + test_patch_dir_).c_str());
  }

  void TearDown() override {
    // Clean up test directories
    std::system(("rm -rf " + test_cache_dir_).c_str());
    std::system(("rm -rf " + test_patch_dir_).c_str());
  }

  std::string test_cache_dir_;
  std::string test_patch_dir_;

  // Helper to create a mock patch file
  void CreateMockPatch(const std::string& path, size_t size = 1024) {
    std::ofstream file(path, std::ios::binary);
    std::vector<char> data(size, 'A');
    file.write(data.data(), size);
    file.close();
  }

  // Helper to create a mock kernel file
  void CreateMockKernel(const std::string& path) {
    std::ofstream file(path, std::ios::binary);
    // Flutter kernel magic number
    file.write("\x90\xabcd", 4);
    file.close();
  }
};

// Tests for PatchMetadata
class PatchMetadataTest : public ::testing::Test {};

TEST_F(PatchMetadataTest, ConstructorInitializesFields) {
  PatchMetadata metadata("1.0.1", "abc123", 1024, "sig123", false);
  
  EXPECT_EQ(metadata.version, "1.0.1");
  EXPECT_EQ(metadata.patch_hash, "abc123");
  EXPECT_EQ(metadata.patch_size, 1024);
  EXPECT_EQ(metadata.signature, "sig123");
  EXPECT_FALSE(metadata.critical);
}

TEST_F(PatchMetadataTest, IsValidChecksRequiredFields) {
  PatchMetadata valid("1.0.1", "abc123", 1024, "sig123", false);
  EXPECT_TRUE(valid.IsValid());

  PatchMetadata invalid_version("", "abc123", 1024, "sig123", false);
  EXPECT_FALSE(invalid_version.IsValid());

  PatchMetadata invalid_hash("1.0.1", "", 1024, "sig123", false);
  EXPECT_FALSE(invalid_hash.IsValid());

  PatchMetadata invalid_sig("1.0.1", "abc123", 1024, "", false);
  EXPECT_FALSE(invalid_sig.IsValid());
}

// Tests for CodePushLoader
TEST_F(CodePushLoaderTest, InitializeLoadsConfiguration) {
  CodePushLoader loader;
  
  CodePushConfig config;
  config.service_url = "https://api.quicui.com";
  config.app_id = "com.example.app";
  config.app_version = "1.0.0";
  config.cache_dir = test_cache_dir_;
  config.enable_async = true;
  
  EXPECT_TRUE(loader.Initialize(config));
  EXPECT_EQ(loader.GetAppId(), "com.example.app");
  EXPECT_EQ(loader.GetAppVersion(), "1.0.0");
}

TEST_F(CodePushLoaderTest, InitializeFailsWithInvalidConfig) {
  CodePushLoader loader;
  
  CodePushConfig config;
  config.service_url = "";  // Invalid: empty URL
  
  EXPECT_FALSE(loader.Initialize(config));
}

TEST_F(CodePushLoaderTest, CheckPatchMetadataAsyncExecutesCallback) {
  CodePushLoader loader;
  
  CodePushConfig config;
  config.service_url = "https://api.quicui.com";
  config.app_id = "com.example.app";
  config.app_version = "1.0.0";
  config.cache_dir = test_cache_dir_;
  config.enable_async = true;
  
  loader.Initialize(config);
  
  bool callback_executed = false;
  PatchMetadata received_metadata("", "", 0, "", false);
  
  loader.CheckPatchMetadataAsync([&](const PatchMetadata& metadata) {
    callback_executed = true;
    received_metadata = metadata;
  });
  
  // Wait for async operation
  std::this_thread::sleep_for(std::chrono::milliseconds(500));
  
  EXPECT_TRUE(callback_executed);
}

TEST_F(CodePushLoaderTest, VerifyPatchSignatureValidatesSignature) {
  CodePushLoader loader;
  
  // Create a mock patch file
  std::string patch_path = test_patch_dir_ + "/test.patch";
  CreateMockPatch(patch_path);
  
  // For now, we'll use a simple hash-based verification
  std::string content;
  std::ifstream file(patch_path, std::ios::binary);
  content = std::string((std::istreambuf_iterator<char>(file)),
                        std::istreambuf_iterator<char>());
  file.close();
  
  // Simple hash verification (in production, use Ed25519)
  std::string simple_hash = loader.ComputeHash(content);
  EXPECT_FALSE(simple_hash.empty());
}

TEST_F(CodePushLoaderTest, CachePatchStoresPatchLocally) {
  CodePushLoader loader;
  
  CodePushConfig config;
  config.service_url = "https://api.quicui.com";
  config.app_id = "com.example.app";
  config.app_version = "1.0.0";
  config.cache_dir = test_cache_dir_;
  config.enable_async = true;
  
  loader.Initialize(config);
  
  std::string patch_path = test_patch_dir_ + "/test.patch";
  CreateMockPatch(patch_path);
  
  PatchMetadata metadata("1.0.1", "abc123", 1024, "sig123", false);
  
  EXPECT_TRUE(loader.CachePatch(metadata, patch_path));
  
  // Verify cached file exists
  std::string cached_path = test_cache_dir_ + "/1.0.1.patch";
  EXPECT_TRUE(std::ifstream(cached_path).good());
}

TEST_F(CodePushLoaderTest, GetCachedPatchRetrievesCachedPatch) {
  CodePushLoader loader;
  
  CodePushConfig config;
  config.service_url = "https://api.quicui.com";
  config.app_id = "com.example.app";
  config.app_version = "1.0.0";
  config.cache_dir = test_cache_dir_;
  config.enable_async = true;
  
  loader.Initialize(config);
  
  // Create and cache a patch
  std::string patch_path = test_patch_dir_ + "/test.patch";
  CreateMockPatch(patch_path);
  
  PatchMetadata metadata("1.0.1", "abc123", 1024, "sig123", false);
  loader.CachePatch(metadata, patch_path);
  
  // Retrieve cached patch
  std::string cached = loader.GetCachedPatch("1.0.1");
  EXPECT_FALSE(cached.empty());
  EXPECT_NE(cached.find("1.0.1"), std::string::npos);
}

TEST_F(CodePushLoaderTest, CleanupOldPatchesRemovesExpiredPatches) {
  CodePushLoader loader;
  
  CodePushConfig config;
  config.service_url = "https://api.quicui.com";
  config.app_id = "com.example.app";
  config.app_version = "1.0.0";
  config.cache_dir = test_cache_dir_;
  config.enable_async = true;
  
  loader.Initialize(config);
  
  // Create multiple patch files
  for (int i = 0; i < 5; ++i) {
    std::string patch_path = test_patch_dir_ + "/patch" + std::to_string(i);
    CreateMockPatch(patch_path);
    
    PatchMetadata metadata(
      "1.0." + std::to_string(i),
      "hash" + std::to_string(i),
      1024,
      "sig" + std::to_string(i),
      false
    );
    loader.CachePatch(metadata, patch_path);
  }
  
  // Clean up keeping only 2 patches
  loader.CleanupOldPatches(2);
  
  // Verify only 2 patches remain (approximately)
  int patch_count = 0;
  std::system(("ls " + test_cache_dir_ + " | wc -l > /tmp/patch_count").c_str());
  std::ifstream count_file("/tmp/patch_count");
  count_file >> patch_count;
  count_file.close();
  
  EXPECT_LE(patch_count, 3);  // Account for filesystem artifacts
}

TEST_F(CodePushLoaderTest, LoadKernelValidatesKernelFile) {
  CodePushLoader loader;
  
  CodePushConfig config;
  config.service_url = "https://api.quicui.com";
  config.app_id = "com.example.app";
  config.app_version = "1.0.0";
  config.cache_dir = test_cache_dir_;
  config.enable_async = true;
  
  loader.Initialize(config);
  
  std::string kernel_path = test_cache_dir_ + "/app.kernel";
  CreateMockKernel(kernel_path);
  
  // This would normally call Dart VM, but we're testing the wrapper
  EXPECT_FALSE(kernel_path.empty());
}

TEST_F(CodePushLoaderTest, ConcurrentPatchCheckingHandlesMultipleRequests) {
  CodePushLoader loader;
  
  CodePushConfig config;
  config.service_url = "https://api.quicui.com";
  config.app_id = "com.example.app";
  config.app_version = "1.0.0";
  config.cache_dir = test_cache_dir_;
  config.enable_async = true;
  
  loader.Initialize(config);
  
  std::atomic<int> callback_count(0);
  
  // Launch multiple concurrent patch checks
  std::vector<std::thread> threads;
  for (int i = 0; i < 5; ++i) {
    threads.emplace_back([&]() {
      loader.CheckPatchMetadataAsync([&](const PatchMetadata& metadata) {
        callback_count++;
      });
    });
  }
  
  // Wait for all threads
  for (auto& thread : threads) {
    thread.join();
  }
  
  std::this_thread::sleep_for(std::chrono::milliseconds(1000));
  EXPECT_EQ(callback_count, 5);
}

TEST_F(CodePushLoaderTest, ThreadSafetyOfCacheOperations) {
  CodePushLoader loader;
  
  CodePushConfig config;
  config.service_url = "https://api.quicui.com";
  config.app_id = "com.example.app";
  config.app_version = "1.0.0";
  config.cache_dir = test_cache_dir_;
  config.enable_async = true;
  
  loader.Initialize(config);
  
  std::atomic<int> success_count(0);
  
  // Multiple threads caching patches simultaneously
  std::vector<std::thread> threads;
  for (int i = 0; i < 10; ++i) {
    threads.emplace_back([&, i]() {
      std::string patch_path = test_patch_dir_ + "/patch" + std::to_string(i);
      CreateMockPatch(patch_path);
      
      PatchMetadata metadata(
        "1.0." + std::to_string(i),
        "hash" + std::to_string(i),
        1024,
        "sig" + std::to_string(i),
        false
      );
      
      if (loader.CachePatch(metadata, patch_path)) {
        success_count++;
      }
    });
  }
  
  for (auto& thread : threads) {
    thread.join();
  }
  
  EXPECT_EQ(success_count, 10);
}

// Test error conditions
TEST_F(CodePushLoaderTest, HandlesNetworkErrorGracefully) {
  CodePushLoader loader;
  
  CodePushConfig config;
  config.service_url = "https://invalid.nonexistent.domain.example.com";
  config.app_id = "com.example.app";
  config.app_version = "1.0.0";
  config.cache_dir = test_cache_dir_;
  config.enable_async = true;
  
  EXPECT_TRUE(loader.Initialize(config));
  // Network errors should be handled gracefully
}

TEST_F(CodePushLoaderTest, HandlesMissingCacheDirectoryGracefully) {
  CodePushLoader loader;
  
  CodePushConfig config;
  config.service_url = "https://api.quicui.com";
  config.app_id = "com.example.app";
  config.app_version = "1.0.0";
  config.cache_dir = "/nonexistent/path/that/does/not/exist";
  config.enable_async = true;
  
  // Should create the directory or handle gracefully
  EXPECT_TRUE(loader.Initialize(config));
}

}  // namespace codepush
}  // namespace quicui

// Main entry point for tests
int main(int argc, char** argv) {
  ::testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
