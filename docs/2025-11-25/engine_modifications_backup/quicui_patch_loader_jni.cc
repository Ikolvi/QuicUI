// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <jni.h>
#include <string>

#include "flutter/fml/logging.h"
#include "flutter/shell/common/quicui_patch_loader.h"

// JNI method implementations for QuicUICodePushLoader.java

extern "C" {

/**
 * Get the path to the patched AOT snapshot.
 * 
 * Java signature:
 * private native String nativeGetPatchedAOTPath(String codeCacheDir, String architecture);
 * 
 * @param env JNI environment
 * @param obj Java QuicUICodePushLoader object
 * @param j_code_cache_dir Java string with code cache directory path
 * @param j_architecture Java string with device architecture (arm64-v8a, etc.)
 * @return Java string with patch path, or null if no valid patch
 */
JNIEXPORT jstring JNICALL
Java_io_flutter_embedding_engine_loader_QuicUICodePushLoader_nativeGetPatchedAOTPath(
    JNIEnv* env,
    jobject obj,
    jstring j_code_cache_dir,
    jstring j_architecture) {
  
  // Convert Java strings to C++ strings
  const char* code_cache_dir_chars = env->GetStringUTFChars(j_code_cache_dir, nullptr);
  const char* arch_chars = env->GetStringUTFChars(j_architecture, nullptr);
  
  if (!code_cache_dir_chars || !arch_chars) {
    FML_LOG(ERROR) << "QuicUI: Failed to convert Java strings to C++";
    if (code_cache_dir_chars) {
      env->ReleaseStringUTFChars(j_code_cache_dir, code_cache_dir_chars);
    }
    if (arch_chars) {
      env->ReleaseStringUTFChars(j_architecture, arch_chars);
    }
    return nullptr;
  }
  
  std::string code_cache_dir(code_cache_dir_chars);
  std::string architecture(arch_chars);
  
  // Release Java string resources
  env->ReleaseStringUTFChars(j_code_cache_dir, code_cache_dir_chars);
  env->ReleaseStringUTFChars(j_architecture, arch_chars);
  
  // Create patch loader instance
  flutter::QuicUIPatchLoader loader;
  loader.SetCodeCacheDir(code_cache_dir);
  
  // Check for patched AOT
  std::string patch_path = loader.GetPatchedAOTPath(architecture);
  
  if (patch_path.empty()) {
    FML_LOG(INFO) << "QuicUI: No valid patch found for architecture " << architecture;
    return nullptr;
  }
  
  FML_LOG(INFO) << "QuicUI: Found valid patch at " << patch_path;
  
  // Convert C++ string back to Java string
  return env->NewStringUTF(patch_path.c_str());
}

/**
 * Clear any installed patches.
 * 
 * Java signature:
 * private native boolean nativeClearPatch(String codeCacheDir);
 * 
 * @param env JNI environment
 * @param obj Java QuicUICodePushLoader object
 * @param j_code_cache_dir Java string with code cache directory path
 * @return true if patches cleared successfully
 */
JNIEXPORT jboolean JNICALL
Java_io_flutter_embedding_engine_loader_QuicUICodePushLoader_nativeClearPatch(
    JNIEnv* env,
    jobject obj,
    jstring j_code_cache_dir) {
  
  // Convert Java string to C++ string
  const char* code_cache_dir_chars = env->GetStringUTFChars(j_code_cache_dir, nullptr);
  
  if (!code_cache_dir_chars) {
    FML_LOG(ERROR) << "QuicUI: Failed to convert code cache dir to C++";
    return JNI_FALSE;
  }
  
  std::string code_cache_dir(code_cache_dir_chars);
  env->ReleaseStringUTFChars(j_code_cache_dir, code_cache_dir_chars);
  
  // Create patch loader instance
  flutter::QuicUIPatchLoader loader;
  loader.SetCodeCacheDir(code_cache_dir);
  
  // Clear installed patch
  bool success = loader.ClearInstalledPatch();
  
  if (success) {
    FML_LOG(INFO) << "QuicUI: Successfully cleared patches";
  } else {
    FML_LOG(WARNING) << "QuicUI: Failed to clear patches";
  }
  
  return success ? JNI_TRUE : JNI_FALSE;
}

/**
 * Get patch information for debugging.
 * 
 * Java signature:
 * private native String nativeGetPatchInfo(String codeCacheDir);
 * 
 * @param env JNI environment
 * @param obj Java QuicUICodePushLoader object
 * @param j_code_cache_dir Java string with code cache directory path
 * @return JSON string with patch info, or null if no patch
 */
JNIEXPORT jstring JNICALL
Java_io_flutter_embedding_engine_loader_QuicUICodePushLoader_nativeGetPatchInfo(
    JNIEnv* env,
    jobject obj,
    jstring j_code_cache_dir) {
  
  // Convert Java string to C++ string
  const char* code_cache_dir_chars = env->GetStringUTFChars(j_code_cache_dir, nullptr);
  
  if (!code_cache_dir_chars) {
    FML_LOG(ERROR) << "QuicUI: Failed to convert code cache dir to C++";
    return nullptr;
  }
  
  std::string code_cache_dir(code_cache_dir_chars);
  env->ReleaseStringUTFChars(j_code_cache_dir, code_cache_dir_chars);
  
  // Create patch loader instance
  flutter::QuicUIPatchLoader loader;
  loader.SetCodeCacheDir(code_cache_dir);
  
  // Get patch info
  std::string info_json = loader.GetPatchInfoJSON();
  
  if (info_json.empty()) {
    return nullptr;
  }
  
  // Convert C++ string to Java string
  return env->NewStringUTF(info_json.c_str());
}

}  // extern "C"
