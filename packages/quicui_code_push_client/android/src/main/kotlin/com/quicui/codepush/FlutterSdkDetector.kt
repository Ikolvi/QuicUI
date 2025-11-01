package com.quicui.codepush

import android.util.Log

/**
 * Detects whether the app is using QuicUI-modified Flutter SDK or standard Flutter SDK
 * 
 * QuicUI Code Push requires the modified Flutter SDK with AOT patching support.
 * This class checks for the presence of QuicUICodePushLoader at runtime.
 */
object FlutterSdkDetector {
    private const val TAG = "FlutterSdkDetector"
    private const val QUICUI_LOADER_CLASS = "io.flutter.embedding.engine.loader.QuicUICodePushLoader"
    
    private var _isQuicUiSdk: Boolean? = null
    
    /**
     * Check if the app is using QuicUI-modified Flutter SDK
     * 
     * @return true if QuicUICodePushLoader is available, false otherwise
     */
    fun isQuicUiFlutterSdk(): Boolean {
        // Cache the result to avoid repeated class lookups
        if (_isQuicUiSdk != null) {
            return _isQuicUiSdk!!
        }
        
        try {
            // Try to load the QuicUICodePushLoader class
            Class.forName(QUICUI_LOADER_CLASS)
            _isQuicUiSdk = true
            Log.i(TAG, "✅ QuicUI Flutter SDK detected - Code Push enabled")
            return true
        } catch (e: ClassNotFoundException) {
            _isQuicUiSdk = false
            Log.w(TAG, """
                ⚠️  Standard Flutter SDK detected - Code Push DISABLED
                
                QuicUI Code Push requires the modified Flutter SDK with AOT patching support.
                
                To enable Code Push:
                1. Clone: https://github.com/Ikolvi/QuicUIFlutterSDK
                2. Checkout tag: quicui-v1.0.0-engine
                3. Set FLUTTER_ROOT to cloned directory
                4. Rebuild your app
                
                Or apply the patch to your Flutter SDK:
                git cherry-pick quicui-v1.0.0-engine
                
                See: https://github.com/Ikolvi/QuicUIFlutterSDK/blob/quicui/main/.quicui/MIGRATION_GUIDE.md
            """.trimIndent())
            return false
        }
    }
    
    /**
     * Require QuicUI Flutter SDK or throw exception
     * 
     * @throws IllegalStateException if not using QuicUI Flutter SDK
     */
    fun requireQuicUiFlutterSdk() {
        if (!isQuicUiFlutterSdk()) {
            throw IllegalStateException(
                "QuicUI Code Push requires the modified Flutter SDK. " +
                "See https://github.com/Ikolvi/QuicUIFlutterSDK for installation instructions."
            )
        }
    }
    
    /**
     * Get SDK information for debugging
     */
    fun getSdkInfo(): Map<String, Any> {
        return mapOf(
            "isQuicUiSdk" to isQuicUiFlutterSdk(),
            "requiredClass" to QUICUI_LOADER_CLASS,
            "repository" to "https://github.com/Ikolvi/QuicUIFlutterSDK",
            "tag" to "quicui-v1.0.0-engine"
        )
    }
}
