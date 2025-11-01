package com.quicui.codepush

import android.content.Context
import android.util.Log
import java.io.File
import java.security.MessageDigest

/**
 * Utility for managing patch storage on Android
 */
object PatchStorage {
    private const val TAG = "PatchStorage"
    private const val PATCH_CACHE_DIR = "quicui_patches"

    /**
     * Get the cache directory for patches
     */
    fun getCacheDirectory(context: Context): File {
        val cacheDir = File(context.getExternalFilesDir(null), PATCH_CACHE_DIR)
        cacheDir.mkdirs()
        return cacheDir
    }

    /**
     * Save a patch to storage
     */
    fun savePatch(context: Context, version: String, data: ByteArray): Boolean {
        return try {
            val patchFile = getPatchFile(context, version)
            patchFile.parentFile?.mkdirs()
            
            patchFile.writeBytes(data)
            Log.d(TAG, "Patch saved: $version (${data.size} bytes)")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error saving patch: $version", e)
            false
        }
    }

    /**
     * Get the file for a specific patch version
     */
    fun getPatchFile(context: Context, version: String): File {
        val cacheDir = getCacheDirectory(context)
        return File(cacheDir, "$version.patch")
    }

    /**
     * Get directory for a specific patch version
     */
    fun getPatchDirectory(context: Context, version: String): File? {
        val patchFile = getPatchFile(context, version)
        return if (patchFile.exists()) patchFile.parentFile else null
    }

    /**
     * List all cached patch versions
     */
    fun listCachedPatches(context: Context): List<String> {
        return try {
            val cacheDir = getCacheDirectory(context)
            cacheDir.listFiles()
                ?.filter { it.isFile && it.extension == "patch" }
                ?.map { it.nameWithoutExtension }
                ?.sorted()
                ?: emptyList()
        } catch (e: Exception) {
            Log.e(TAG, "Error listing patches", e)
            emptyList()
        }
    }

    /**
     * Get the size of a cached patch
     */
    fun getPatchSize(context: Context, version: String): Long {
        return try {
            val patchFile = getPatchFile(context, version)
            if (patchFile.exists()) patchFile.length() else 0L
        } catch (e: Exception) {
            Log.e(TAG, "Error getting patch size", e)
            0L
        }
    }

    /**
     * Calculate SHA256 hash of patch file
     */
    fun calculatePatchHash(context: Context, version: String): String {
        return try {
            val patchFile = getPatchFile(context, version)
            if (!patchFile.exists()) return ""

            val bytes = patchFile.readBytes()
            val md = MessageDigest.getInstance("SHA-256")
            val digest = md.digest(bytes)

            // Convert to hex string
            digest.joinToString("") { "%02x".format(it) }
        } catch (e: Exception) {
            Log.e(TAG, "Error calculating hash", e)
            ""
        }
    }

    /**
     * Verify patch integrity with hash
     */
    fun verifyPatchIntegrity(
        context: Context,
        version: String,
        expectedHash: String
    ): Boolean {
        val calculatedHash = calculatePatchHash(context, version)
        return calculatedHash.equals(expectedHash, ignoreCase = true)
    }

    /**
     * Load patch data from storage
     */
    fun loadPatchData(context: Context, version: String): ByteArray? {
        return try {
            val patchFile = getPatchFile(context, version)
            if (patchFile.exists()) {
                patchFile.readBytes()
            } else {
                null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error loading patch", e)
            null
        }
    }

    /**
     * Delete a specific patch
     */
    fun deletePatch(context: Context, version: String): Boolean {
        return try {
            val patchFile = getPatchFile(context, version)
            if (patchFile.exists()) {
                patchFile.delete()
            } else {
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error deleting patch", e)
            false
        }
    }

    /**
     * Clean up old patches, keeping only the most recent ones
     */
    fun cleanupOldPatches(context: Context, keepCount: Int = 3): Int {
        return try {
            val cacheDir = getCacheDirectory(context)
            val files = cacheDir.listFiles()
                ?.filter { it.isFile && it.extension == "patch" }
                ?.sortedByDescending { it.lastModified() }
                ?: emptyList()

            var deletedCount = 0
            files.drop(keepCount).forEach { file ->
                if (file.delete()) {
                    deletedCount++
                    Log.d(TAG, "Deleted old patch: ${file.name}")
                }
            }

            deletedCount
        } catch (e: Exception) {
            Log.e(TAG, "Error cleaning up patches", e)
            0
        }
    }

    /**
     * Get total size of all cached patches
     */
    fun getTotalCacheSize(context: Context): Long {
        return try {
            val cacheDir = getCacheDirectory(context)
            cacheDir.listFiles()
                ?.filter { it.isFile }
                ?.sumOf { it.length() }
                ?: 0L
        } catch (e: Exception) {
            Log.e(TAG, "Error calculating cache size", e)
            0L
        }
    }

    /**
     * Clear all cached patches
     */
    fun clearAllPatches(context: Context): Boolean {
        return try {
            val cacheDir = getCacheDirectory(context)
            cacheDir.listFiles()?.forEach { it.delete() }
            Log.d(TAG, "Cleared all patches")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error clearing patches", e)
            false
        }
    }
}
