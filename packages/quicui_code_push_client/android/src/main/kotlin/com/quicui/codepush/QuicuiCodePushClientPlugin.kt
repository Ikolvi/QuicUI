package com.quicui.codepush

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger

/**
 * QuicuiCodePushClientPlugin
 * 
 * This plugin provides platform channel integration between Dart and Android
 * for the QuicUI Code Push system. It registers the method channel handler
 * when the Flutter engine is attached.
 */
class QuicuiCodePushClientPlugin : FlutterPlugin {
    private var methodHandler: CodePushMethodHandler? = null

    /**
     * Called when the plugin is attached to the Flutter engine.
     * This is where we register our platform channel.
     */
    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        val messenger = binding.binaryMessenger
        
        // Create and attach the method channel handler
        methodHandler = CodePushMethodHandler.createAndAttach(
            context = context,
            messenger = messenger
        )
    }

    /**
     * Called when the plugin is detached from the Flutter engine.
     * Clean up resources here.
     */
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        // Clean up the method handler
        methodHandler = null
    }
}
