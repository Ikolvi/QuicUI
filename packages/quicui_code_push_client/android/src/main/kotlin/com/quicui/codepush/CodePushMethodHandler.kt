package com.quicui.codepush

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.URL
import java.util.concurrent.Executors
import java.util.zip.ZipFile

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
        
        /**
         * Create and attach the method channel handler
         */
        fun createAndAttach(
            context: Context,
            messenger: io.flutter.plugin.common.BinaryMessenger
        ): CodePushMethodHandler {
            val channel = MethodChannel(messenger, "dev.quicui.code_push")
            val handler = CodePushMethodHandler(context, channel)
            channel.setMethodCallHandler(handler)
            return handler
        }
    }

    private var isInitialized = false
    private var serviceUrl: String = ""
    private var appId: String = ""
    private var appVersion: String = ""

    /**
     * Check if QuicUI Flutter SDK is available
     * Returns error via result channel if not available
     */
    private fun checkQuicUiSdk(result: MethodChannel.Result): Boolean {
        if (!FlutterSdkDetector.isQuicUiFlutterSdk()) {
            result.error(
                "SDK_NOT_SUPPORTED",
                "QuicUI Code Push requires the modified Flutter SDK. " +
                "See https://github.com/Ikolvi/QuicUIFlutterSDK for installation instructions.",
                FlutterSdkDetector.getSdkInfo()
            )
            return false
        }
        return true
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "initCodePush" -> handleInitCodePush(call, result)
                "checkPatch" -> handleCheckPatch(call, result)
                "loadPatch" -> handleLoadPatch(call, result)
                "disableCodePush" -> handleDisableCodePush(call, result)
                "getLoadedPatchVersion" -> handleGetLoadedPatchVersion(call, result)
                // NEW: Platform channel methods for AOT patching
                "installPatch" -> handleInstallPatch(call, result)
                "hasPatch" -> handleHasPatch(call, result)
                "getInstalledPatchVersion" -> handleGetInstalledPatchVersion(call, result)
                "clearPatch" -> handleClearPatch(call, result)
                "getArchitecture" -> handleGetArchitecture(call, result)
                "restartApp" -> handleRestartApp(call, result)
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

    // ========================================================================
    // NEW: AOT Patch Installation Methods (Platform Channel → Engine)
    // ========================================================================

    /**
     * Install patch via Flutter engine
     * Transfers Dart-downloaded patch to native engine code cache
     */
    private fun handleInstallPatch(call: MethodCall, result: MethodChannel.Result) {
        // Check if QuicUI SDK is available
        if (!checkQuicUiSdk(result)) {
            return
        }
        
        val patchPath = call.argument<String>("patchPath")
        val version = call.argument<String>("version")
        val hash = call.argument<String>("hash")
        val architecture = call.argument<String>("architecture")
        val signature = call.argument<String>("signature")

        if (patchPath == null || version == null) {
            result.error("INVALID_ARGS", "patchPath and version are required", null)
            return
        }

        executor.execute {
            try {
                // Use QuicUICodePushLoader from the engine
                val codePushLoader = io.flutter.embedding.engine.loader.QuicUICodePushLoader(context)
                
                // Verify patch file exists
                val patchFile = File(patchPath)
                if (!patchFile.exists()) {
                    Handler(Looper.getMainLooper()).post {
                        result.error("FILE_NOT_FOUND", "Patch file not found: $patchPath", null)
                    }
                    return@execute
                }

                // Get device architecture if not provided
                val arch = architecture ?: io.flutter.embedding.engine.loader.QuicUICodePushLoader.getDeviceArchitecture()

                android.util.Log.i("QuicUI", "Installing patch for architecture: $arch")
                android.util.Log.i("QuicUI", "Patch file: ${patchFile.absolutePath} (${patchFile.length()} bytes)")

                // Extract original libapp.so from APK
                val originalLibapp = extractLibappFromApk(arch)
                if (originalLibapp == null) {
                    Handler(Looper.getMainLooper()).post {
                        result.error("EXTRACT_FAILED", "Failed to extract libapp.so from APK", null)
                    }
                    return@execute
                }
                
                android.util.Log.i("QuicUI", "Original libapp.so extracted: ${originalLibapp.absolutePath} (${originalLibapp.length()} bytes)")

                // Get code cache directory
                val codeCacheDir = context.codeCacheDir.absolutePath
                val patchesDir = File(codeCacheDir, "quicui_patches")
                patchesDir.mkdirs()

                // Target path: libapp_patched_<arch>.so
                val targetFile = File(patchesDir, "libapp_patched_${arch}.so")

                // Check if this is a full replacement or a diff patch
                // If patch file size is close to libapp.so size, it's a full replacement
                val isFullReplacement = patchFile.length() >= originalLibapp.length() * 0.8
                
                if (isFullReplacement) {
                    // Full replacement - just copy the file
                    android.util.Log.i("QuicUI", "Detected full replacement (${patchFile.length()} bytes vs ${originalLibapp.length()} bytes)")
                    android.util.Log.i("QuicUI", "Copying full libapp.so as patch...")
                    
                    patchFile.copyTo(targetFile, overwrite = true)
                    android.util.Log.i("QuicUI", "Full replacement installed successfully!")
                } else {
                    // Diff patch - apply BsDiff
                    android.util.Log.i("QuicUI", "Detected BsDiff patch (${patchFile.length()} bytes vs ${originalLibapp.length()} bytes)")
                    android.util.Log.i("QuicUI", "Applying BsDiff patch...")
                    
                    val patchSuccess = BsDiffPatcher.applyPatch(originalLibapp, patchFile, targetFile)
                    
                    if (!patchSuccess) {
                        // Clean up temporary file
                        originalLibapp.delete()
                        Handler(Looper.getMainLooper()).post {
                            result.error("PATCH_FAILED", "Failed to apply BsDiff patch", null)
                        }
                        return@execute
                    }
                    
                    android.util.Log.i("QuicUI", "BsDiff patch applied successfully!")
                }

                // Clean up temporary original file
                originalLibapp.delete()

                // Set executable permissions
                targetFile.setExecutable(true, false)
                targetFile.setReadable(true, false)

                // Save metadata
                val metadataFile = File(patchesDir, "patch_metadata.json")
                val metadata = buildString {
                    appendLine("{")
                    appendLine("  \"version\": \"$version\",")
                    appendLine("  \"platform\": \"android\",")
                    appendLine("  \"architecture\": \"$arch\",")
                    appendLine("  \"patch_hash\": \"${hash ?: ""}\",")
                    appendLine("  \"patch_size\": ${targetFile.length()},")
                    appendLine("  \"signature\": \"${signature ?: ""}\",")
                    appendLine("  \"install_date\": \"${java.time.Instant.now()}\",")
                    appendLine("  \"requires_restart\": true")
                    appendLine("}")
                }
                metadataFile.writeText(metadata)

                android.util.Log.i("QuicUI", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                android.util.Log.i("QuicUI", "✅ Patch installed successfully!")
                android.util.Log.i("QuicUI", "📁 Patches directory: ${patchesDir.absolutePath}")
                android.util.Log.i("QuicUI", "📄 Patched file: ${targetFile.absolutePath}")
                android.util.Log.i("QuicUI", "✅ File exists: ${targetFile.exists()}")
                android.util.Log.i("QuicUI", "✅ File readable: ${targetFile.canRead()}")
                android.util.Log.i("QuicUI", "📦 Patched libapp.so size: ${targetFile.length()} bytes (${targetFile.length() / 1024.0 / 1024.0} MB)")
                android.util.Log.i("QuicUI", "📄 Metadata file: ${metadataFile.absolutePath}")
                android.util.Log.i("QuicUI", "✅ Metadata exists: ${metadataFile.exists()}")
                android.util.Log.i("QuicUI", "")
                android.util.Log.i("QuicUI", "📂 Files in patches directory:")
                patchesDir.listFiles()?.forEach { file ->
                    android.util.Log.i("QuicUI", "   - ${file.name} (${file.length() / 1024.0 / 1024.0} MB)")
                }
                android.util.Log.i("QuicUI", "")
                android.util.Log.i("QuicUI", "⚠️  RESTART APP TO LOAD PATCHED CODE ⚠️")
                android.util.Log.i("QuicUI", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

                Handler(Looper.getMainLooper()).post {
                    result.success(true)
                }
            } catch (e: Exception) {
                android.util.Log.e("QuicUI", "Failed to install patch", e)
                Handler(Looper.getMainLooper()).post {
                    result.error("INSTALL_FAILED", e.message, null)
                }
            }
        }
    }
    
    /**
     * Extract original libapp.so from the APK for the given architecture
     */
    private fun extractLibappFromApk(architecture: String): File? {
        return try {
            val apkPath = context.packageCodePath
            android.util.Log.d("QuicUI", "Extracting libapp.so from APK: $apkPath")
            
            val zipFile = ZipFile(apkPath)
            val entryName = "lib/$architecture/libapp.so"
            val entry = zipFile.getEntry(entryName)
            
            if (entry == null) {
                android.util.Log.e("QuicUI", "libapp.so not found in APK for architecture: $architecture")
                zipFile.close()
                return null
            }
            
            // Create temporary file to store original libapp.so
            val tempFile = File.createTempFile("libapp_original_", ".so", context.cacheDir)
            
            zipFile.getInputStream(entry).use { input ->
                tempFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            
            zipFile.close()
            
            android.util.Log.d("QuicUI", "Extracted libapp.so: ${tempFile.absolutePath} (${tempFile.length()} bytes)")
            tempFile
        } catch (e: Exception) {
            android.util.Log.e("QuicUI", "Failed to extract libapp.so from APK", e)
            null
        }
    }

    /**
     * Check if patch is installed
     */
    private fun handleHasPatch(call: MethodCall, result: MethodChannel.Result) {
        // Check if QuicUI SDK is available
        if (!checkQuicUiSdk(result)) {
            return
        }
        
        try {
            val codePushLoader = io.flutter.embedding.engine.loader.QuicUICodePushLoader(context)
            val arch = io.flutter.embedding.engine.loader.QuicUICodePushLoader.getDeviceArchitecture()
            val hasPatch = codePushLoader.hasPatch(arch)
            result.success(hasPatch)
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }

    /**
     * Get installed patch version
     */
    private fun handleGetInstalledPatchVersion(call: MethodCall, result: MethodChannel.Result) {
        try {
            val codeCacheDir = context.codeCacheDir.absolutePath
            val metadataFile = File(codeCacheDir, "quicui_patches/patch_metadata.json")
            
            if (metadataFile.exists()) {
                val metadata = metadataFile.readText()
                // Simple JSON parsing - extract version
                val versionRegex = "\"version\":\\s*\"([^\"]+)\"".toRegex()
                val matchResult = versionRegex.find(metadata)
                val version = matchResult?.groupValues?.get(1)
                result.success(version)
            } else {
                result.success(null)
            }
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }

    /**
     * Clear installed patch (rollback)
     */
    private fun handleClearPatch(call: MethodCall, result: MethodChannel.Result) {
        // Check if QuicUI SDK is available
        if (!checkQuicUiSdk(result)) {
            return
        }
        
        executor.execute {
            try {
                val codePushLoader = io.flutter.embedding.engine.loader.QuicUICodePushLoader(context)
                val success = codePushLoader.clearPatch()
                Handler(Looper.getMainLooper()).post {
                    result.success(success)
                }
            } catch (e: Exception) {
                Handler(Looper.getMainLooper()).post {
                    result.error("ERROR", e.message, null)
                }
            }
        }
    }

    /**
     * Get device architecture
     */
    private fun handleGetArchitecture(call: MethodCall, result: MethodChannel.Result) {
        // Check if QuicUI SDK is available
        if (!checkQuicUiSdk(result)) {
            return
        }
        
        try {
            val arch = io.flutter.embedding.engine.loader.QuicUICodePushLoader.getDeviceArchitecture()
            result.success(arch)
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }

    /**
     * Restart the app
     */
    private fun handleRestartApp(call: MethodCall, result: MethodChannel.Result) {
        try {
            // Get the main activity intent
            val packageManager = context.packageManager
            val intent = packageManager.getLaunchIntentForPackage(context.packageName)
            
            if (intent != null) {
                intent.addFlags(android.content.Intent.FLAG_ACTIVITY_CLEAR_TOP)
                intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                
                // Exit current process
                android.os.Process.killProcess(android.os.Process.myPid())
                result.success(true)
            } else {
                result.error("ERROR", "Could not get launch intent", null)
            }
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
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
        "dev.quicui.code_push"  // Updated to match Dart side
    )
    val handler = CodePushMethodHandler(context, channel)
    channel.setMethodCallHandler(handler)
}
