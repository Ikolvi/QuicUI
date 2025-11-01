package com.quicui.codepush

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.URL
import java.util.concurrent.Executors

/**
 * QuicUI Code Push Android implementation
 * Handles native method calls from Dart for patch operations
 */
class CodePushMethodHandler(
    private val context: Context,
    private val channel: MethodChannel
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val PATCH_CACHE_DIR = "quicui_patches"
        private const val TIMEOUT_SECONDS = 30
        private val executor = Executors.newSingleThreadExecutor()
    }

    private var isInitialized = false
    private var serviceUrl: String = ""
    private var appId: String = ""
    private var appVersion: String = ""

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "initCodePush" -> handleInitCodePush(call, result)
                "checkPatch" -> handleCheckPatch(call, result)
                "loadPatch" -> handleLoadPatch(call, result)
                "disableCodePush" -> handleDisableCodePush(call, result)
                "getLoadedPatchVersion" -> handleGetLoadedPatchVersion(call, result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("ERROR", e.message, e.stackTrace)
        }
    }

    /**
     * Initialize code push with service configuration
     */
    private fun handleInitCodePush(call: MethodCall, result: MethodChannel.Result) {
        serviceUrl = call.argument<String>("serviceUrl") ?: "https://api.quicui.com"
        appId = call.argument<String>("appId") ?: "com.example.app"
        appVersion = call.argument<String>("appVersion") ?: "1.0.0"

        isInitialized = true
        result.success(true)
    }

    /**
     * Check for available patches from the service
     */
    private fun handleCheckPatch(call: MethodCall, result: MethodChannel.Result) {
        if (!isInitialized) {
            result.error("NOT_INITIALIZED", "Code push not initialized", null)
            return
        }

        executor.execute {
            try {
                val patchUrl = "$serviceUrl/api/v1/patches/check?app_id=$appId&version=$appVersion"
                val patch = fetchPatchMetadata(patchUrl)

                Handler(Looper.getMainLooper()).post {
                    if (patch != null) {
                        result.success(patch)
                    } else {
                        result.success(null)
                    }
                }
            } catch (e: Exception) {
                Handler(Looper.getMainLooper()).post {
                    result.error("FETCH_FAILED", e.message, null)
                }
            }
        }
    }

    /**
     * Load a specific patch by version
     */
    private fun handleLoadPatch(call: MethodCall, result: MethodChannel.Result) {
        val version: String = call.argument("version") ?: run {
            result.error("INVALID_ARGS", "Version required", null)
            return
        }

        if (!isInitialized) {
            result.error("NOT_INITIALIZED", "Code push not initialized", null)
            return
        }

        executor.execute {
            try {
                val patchFile = getPatchFile(version)
                
                // Check if patch is cached
                if (patchFile.exists()) {
                    Handler(Looper.getMainLooper()).post {
                        result.success(mapOf(
                            "success" to true,
                            "message" to "Patch loaded from cache",
                            "patchVersion" to version
                        ))
                    }
                    return@execute
                }

                // Download patch
                val patchUrl = "$serviceUrl/api/v1/patches/$version"
                val success = downloadPatch(patchUrl, patchFile)

                Handler(Looper.getMainLooper()).post {
                    if (success) {
                        result.success(mapOf(
                            "success" to true,
                            "message" to "Patch loaded successfully",
                            "patchVersion" to version
                        ))
                    } else {
                        result.success(mapOf(
                            "success" to false,
                            "message" to "Failed to download patch",
                            "patchVersion" to null
                        ))
                    }
                }
            } catch (e: Exception) {
                Handler(Looper.getMainLooper()).post {
                    result.success(mapOf(
                        "success" to false,
                        "message" to (e.message ?: "Unknown error"),
                        "patchVersion" to null
                    ))
                }
            }
        }
    }

    /**
     * Disable code push functionality
     */
    private fun handleDisableCodePush(call: MethodCall, result: MethodChannel.Result) {
        isInitialized = false
        serviceUrl = ""
        appId = ""
        appVersion = ""
        result.success(true)
    }

    /**
     * Get the currently loaded patch version
     */
    private fun handleGetLoadedPatchVersion(call: MethodCall, result: MethodChannel.Result) {
        // TODO: Implement based on your patch loading mechanism
        // For now, return empty string indicating no patch loaded
        result.success("")
    }

    /**
     * Fetch patch metadata from the service
     */
    private fun fetchPatchMetadata(url: String): Map<String, Any>? {
        return try {
            val connection = URL(url).openConnection()
            connection.connectTimeout = TIMEOUT_SECONDS * 1000
            connection.readTimeout = TIMEOUT_SECONDS * 1000

            val response = connection.inputStream.bufferedReader().readText()
            
            // Simple JSON parsing (in production, use proper JSON library)
            // This is a placeholder - actual implementation would parse JSON
            mapOf(
                "version" to "1.0.1",
                "platform" to "android",
                "patchHash" to "abc123",
                "patchSize" to 1024,
                "signature" to "sig123",
                "critical" to false,
                "releaseDate" to "2024-11-01T00:00:00Z"
            )
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Download patch file from service
     */
    private fun downloadPatch(url: String, destination: File): Boolean {
        return try {
            val connection = URL(url).openConnection()
            connection.connectTimeout = TIMEOUT_SECONDS * 1000
            connection.readTimeout = TIMEOUT_SECONDS * 1000

            // Ensure parent directory exists
            destination.parentFile?.mkdirs()

            // Download and save
            connection.inputStream.use { input ->
                destination.outputStream().use { output ->
                    input.copyTo(output)
                }
            }

            true
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Get the file for storing a patch
     */
    private fun getPatchFile(version: String): File {
        val cacheDir = File(context.getExternalFilesDir(null), PATCH_CACHE_DIR)
        return File(cacheDir, "$version.patch")
    }

    /**
     * Clean up old patches to save storage
     */
    fun cleanupOldPatches(keepCount: Int = 3) {
        try {
            val cacheDir = File(context.getExternalFilesDir(null), PATCH_CACHE_DIR)
            if (cacheDir.exists() && cacheDir.isDirectory) {
                val files = cacheDir.listFiles()?.sortedByDescending { it.lastModified() } ?: emptyList()
                
                // Delete old patches, keep only recent ones
                files.drop(keepCount).forEach { it.delete() }
            }
        } catch (e: Exception) {
            android.util.Log.e("CodePush", "Error cleaning patches", e)
        }
    }
}

/**
 * Register the code push method handler with Flutter
 * Call this from your MainActivity or generated plugin code
 */
fun registerCodePushHandler(flutterEngine: FlutterEngine, context: Context) {
    val channel = MethodChannel(
        flutterEngine.dartExecutor.binaryMessenger,
        "com.quicui/codepush"
    )
    val handler = CodePushMethodHandler(context, channel)
    channel.setMethodCallHandler(handler)
}
