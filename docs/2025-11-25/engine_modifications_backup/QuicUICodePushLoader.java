// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.embedding.engine.loader;

import android.content.Context;
import android.os.Build;
import io.flutter.Log;
import java.io.File;

/**
 * QuicUI Code Push Loader
 * 
 * Integrates with C++ patch loader via JNI to check for and load
 * patched AOT snapshots (libapp.so) for hot updates.
 */
public class QuicUICodePushLoader {
    private static final String TAG = "QuicUICodePushLoader";
    
    private final Context context;
    private final String codeCacheDir;
    private final String architecture;
    
    // Native method declarations - implemented in quicui_patch_loader_jni.cc
    private native String nativeGetPatchedAOTPath(String codeCacheDir, String architecture);
    private native boolean nativeClearPatch(String codeCacheDir);
    private native String nativeGetPatchInfo(String codeCacheDir);
    
    // Load native library (libflutter.so contains our JNI functions)
    static {
        try {
            System.loadLibrary("flutter");
            Log.i(TAG, "QuicUI: Loaded libflutter.so for JNI");
        } catch (UnsatisfiedLinkError e) {
            Log.e(TAG, "QuicUI: Failed to load libflutter.so", e);
        }
    }
    
    /**
     * Constructor
     * 
     * @param context Android application context
     */
    public QuicUICodePushLoader(Context context) {
        this.context = context;
        this.codeCacheDir = context.getCodeCacheDir().getAbsolutePath();
        this.architecture = detectArchitecture();
        
        Log.i(TAG, "QuicUI: Initialized");
        Log.i(TAG, "QuicUI: Code cache dir: " + codeCacheDir);
        Log.i(TAG, "QuicUI: Architecture: " + architecture);
    }
    
    /**
     * Get the path to a patched AOT snapshot if available.
     * 
     * This method calls into C++ via JNI to:
     * 1. Check for patch existence
     * 2. Validate patch integrity (hash verification)
     * 3. Return path if valid, null otherwise
     * 
     * @return Path to patched libapp.so, or null if no valid patch
     */
    public String getPatchedAOTPath() {
        try {
            Log.i(TAG, "QuicUI: Checking for patches via C++ JNI...");
            
            // Call native C++ method
            String patchPath = nativeGetPatchedAOTPath(codeCacheDir, architecture);
            
            if (patchPath != null && !patchPath.isEmpty()) {
                File patchFile = new File(patchPath);
                if (patchFile.exists()) {
                    Log.i(TAG, "QuicUI: ✅ Found valid patch at: " + patchPath);
                    Log.i(TAG, "QuicUI: Patch size: " + patchFile.length() + " bytes");
                    return patchPath;
                } else {
                    Log.w(TAG, "QuicUI: C++ returned path but file doesn't exist: " + patchPath);
                    return null;
                }
            } else {
                Log.i(TAG, "QuicUI: No patch found (C++ returned null)");
                return null;
            }
        } catch (UnsatisfiedLinkError e) {
            Log.e(TAG, "QuicUI: JNI method not found - C++ code may not be linked", e);
            return null;
        } catch (Exception e) {
            Log.e(TAG, "QuicUI: Error getting patched AOT path", e);
            return null;
        }
    }
    
    /**
     * Clear any installed patches.
     * 
     * @return true if patches cleared successfully
     */
    public boolean clearPatch() {
        try {
            Log.i(TAG, "QuicUI: Clearing patches via C++ JNI...");
            boolean success = nativeClearPatch(codeCacheDir);
            
            if (success) {
                Log.i(TAG, "QuicUI: ✅ Patches cleared successfully");
            } else {
                Log.w(TAG, "QuicUI: Failed to clear patches");
            }
            
            return success;
        } catch (Exception e) {
            Log.e(TAG, "QuicUI: Error clearing patches", e);
            return false;
        }
    }
    
    /**
     * Get patch information for debugging.
     * 
     * @return JSON string with patch info, or null if no patch
     */
    public String getPatchInfo() {
        try {
            String info = nativeGetPatchInfo(codeCacheDir);
            if (info != null) {
                Log.i(TAG, "QuicUI: Patch info: " + info);
            }
            return info;
        } catch (Exception e) {
            Log.e(TAG, "QuicUI: Error getting patch info", e);
            return null;
        }
    }
    
    /**
     * Detect device architecture.
     * 
     * @return Architecture string (arm64-v8a, armeabi-v7a, x86_64, x86)
     */
    private String detectArchitecture() {
        // Prefer 64-bit ABIs
        if (Build.SUPPORTED_64_BIT_ABIS.length > 0) {
            return Build.SUPPORTED_64_BIT_ABIS[0];
        }
        
        // Fall back to 32-bit ABIs
        if (Build.SUPPORTED_ABIS.length > 0) {
            return Build.SUPPORTED_ABIS[0];
        }
        
        // Default fallback
        return "arm64-v8a";
    }
}
