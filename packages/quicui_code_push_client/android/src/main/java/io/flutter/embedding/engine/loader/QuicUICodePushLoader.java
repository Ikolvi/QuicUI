// Copyright 2024 QuicUI Contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.loader;

import android.content.Context;
import android.os.Build;
import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

/**
 * QuicUI Code Push integration for Android platform.
 * 
 * Checks for installed AOT patches in the code cache directory and provides
 * paths to FlutterLoader for loading patched libapp.so files.
 * 
 * This enables over-the-air code updates without publishing a new APK to the Play Store.
 */
public class QuicUICodePushLoader {
  private static final String TAG = "QuicUICodePush";
  private static final String PATCHES_DIR = "quicui_patches";
  private static final String METADATA_FILE = "patch_metadata.json";
  
  private final Context context;
  
  /**
   * Creates a new QuicUI Code Push loader.
   * 
   * @param context Application context for accessing code cache directory
   */
  public QuicUICodePushLoader(@NonNull Context context) {
    this.context = context;
  }
  
  /**
   * Get path to patched libapp.so if available for the device architecture.
   * 
   * This method:
   * 1. Checks if patches directory exists
   * 2. Locates architecture-specific patched library
   * 3. Validates patch metadata
   * 4. Returns path if valid, null otherwise
   * 
   * @param architecture CPU architecture (e.g., "arm64-v8a", "armeabi-v7a", "x86_64")
   * @return Absolute path to patched library or null if not available
   */
  @Nullable
  public String getPatchedAOTPath(@NonNull String architecture) {
    File codeCacheDir = context.getCodeCacheDir();
    if (codeCacheDir == null) {
      Log.w(TAG, "Code cache directory not available");
      return null;
    }
    
    File patchesDir = new File(codeCacheDir, PATCHES_DIR);
    if (!patchesDir.exists()) {
      Log.d(TAG, "No patches directory found");
      return null;
    }
    
    // Look for architecture-specific patched library
    String libraryName = "libapp_patched_" + architecture + ".so";
    File patchedLibapp = new File(patchesDir, libraryName);
    
    if (!patchedLibapp.exists()) {
      Log.d(TAG, "No patched libapp.so found for architecture: " + architecture);
      return null;
    }
    
    // Validate patch metadata exists
    File metadataFile = new File(patchesDir, METADATA_FILE);
    if (!metadataFile.exists()) {
      Log.w(TAG, "Patch metadata not found - ignoring patch for safety");
      return null;
    }
    
    // Verify patch file is readable
    if (!patchedLibapp.canRead()) {
      Log.w(TAG, "Patched library exists but is not readable");
      return null;
    }
    
    String absolutePath = patchedLibapp.getAbsolutePath();
    Log.i(TAG, "Using QuicUI patched AOT library: " + absolutePath);
    Log.i(TAG, "Patch size: " + (patchedLibapp.length() / 1024.0 / 1024.0) + " MB");
    
    return absolutePath;
  }
  
  /**
   * Get path to patched libapp.so for current device architecture.
   * Convenience method that auto-detects architecture.
   * 
   * @return Absolute path to patched library or null if not available
   */
  @Nullable
  public String getPatchedAOTPath() {
    return getPatchedAOTPath(getDeviceArchitecture());
  }
  
  /**
   * Check if a patch is installed for the given architecture.
   * 
   * @param architecture CPU architecture to check
   * @return true if patch exists, false otherwise
   */
  public boolean hasPatch(@NonNull String architecture) {
    return getPatchedAOTPath(architecture) != null;
  }
  
  /**
   * Get the current device's primary CPU architecture.
   * 
   * @return Architecture string (e.g., "arm64-v8a")
   */
  @NonNull
  public static String getDeviceArchitecture() {
    // Check supported ABIs (API 21+)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      String[] abis = Build.SUPPORTED_ABIS;
      if (abis.length > 0) {
        return abis[0];  // Primary ABI
      }
    }
    
    // Fallback for older devices (API < 21)
    return Build.CPU_ABI;
  }
  
  /**
   * Clear installed patch (rollback to original APK code).
   * 
   * This is useful for:
   * - Manual rollback by user
   * - Automatic rollback after crashes
   * - Testing purposes
   * 
   * @return true if successfully cleared, false on error
   */
  public boolean clearPatch() {
    File codeCacheDir = context.getCodeCacheDir();
    if (codeCacheDir == null) {
      Log.w(TAG, "Code cache directory not available");
      return false;
    }
    
    File patchesDir = new File(codeCacheDir, PATCHES_DIR);
    if (!patchesDir.exists()) {
      Log.d(TAG, "Patches directory doesn't exist - already cleared");
      return true;  // Already cleared
    }
    
    // Delete all files in patches directory
    boolean success = deleteRecursive(patchesDir);
    
    if (success) {
      Log.i(TAG, "Successfully cleared QuicUI patches");
    } else {
      Log.e(TAG, "Failed to clear some patch files");
    }
    
    return success;
  }
  
  /**
   * Get metadata about the installed patch.
   * 
   * @return JSON string with patch metadata or null if not available
   */
  @Nullable
  public String getPatchMetadata() {
    File codeCacheDir = context.getCodeCacheDir();
    if (codeCacheDir == null) {
      return null;
    }
    
    File metadataFile = new File(codeCacheDir, PATCHES_DIR + "/" + METADATA_FILE);
    if (!metadataFile.exists()) {
      return null;
    }
    
    try {
      FileInputStream fis = new FileInputStream(metadataFile);
      byte[] data = new byte[(int) metadataFile.length()];
      fis.read(data);
      fis.close();
      
      String json = new String(data, "UTF-8");
      Log.d(TAG, "Patch metadata: " + json);
      return json;
    } catch (IOException e) {
      Log.e(TAG, "Failed to read patch metadata", e);
      return null;
    }
  }
  
  /**
   * Calculate SHA256 hash of a file for integrity verification.
   * 
   * @param file File to hash
   * @return Hex-encoded SHA256 hash or null on error
   */
  @Nullable
  public static String calculateFileHash(@NonNull File file) {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      FileInputStream fis = new FileInputStream(file);
      
      byte[] buffer = new byte[8192];
      int bytesRead;
      
      while ((bytesRead = fis.read(buffer)) != -1) {
        digest.update(buffer, 0, bytesRead);
      }
      
      fis.close();
      
      byte[] hashBytes = digest.digest();
      
      // Convert to hex string
      StringBuilder hexString = new StringBuilder();
      for (byte b : hashBytes) {
        String hex = Integer.toHexString(0xff & b);
        if (hex.length() == 1) {
          hexString.append('0');
        }
        hexString.append(hex);
      }
      
      return hexString.toString();
    } catch (NoSuchAlgorithmException | IOException e) {
      Log.e(TAG, "Failed to calculate file hash", e);
      return null;
    }
  }
  
  /**
   * Recursively delete a directory and all its contents.
   */
  private boolean deleteRecursive(@NonNull File file) {
    boolean success = true;
    
    if (file.isDirectory()) {
      File[] children = file.listFiles();
      if (children != null) {
        for (File child : children) {
          success = deleteRecursive(child) && success;
        }
      }
    }
    
    boolean deleted = file.delete();
    if (!deleted) {
      Log.w(TAG, "Failed to delete: " + file.getAbsolutePath());
    }
    
    return deleted && success;
  }
  
  /**
   * Get the patches directory path (for debugging).
   * 
   * @return Absolute path to patches directory or null if unavailable
   */
  @Nullable
  public String getPatchesDirectory() {
    File codeCacheDir = context.getCodeCacheDir();
    if (codeCacheDir == null) {
      return null;
    }
    
    return new File(codeCacheDir, PATCHES_DIR).getAbsolutePath();
  }
  
  /**
   * Check if code push is supported on this device.
   * 
   * @return true if supported, false otherwise
   */
  public static boolean isSupported() {
    // Code push requires API 21+ (for reliable code cache)
    return Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP;
  }
}
