import Flutter
import UIKit

/// QuicUI Code Push Plugin Registration
/// This is the main entry point for the iOS plugin
public class QuicUICodePushPlugin: NSObject, FlutterPlugin {
    
    private var methodHandler: CodePushMethodHandler?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.quicui/codepush",
            binaryMessenger: registrar.messenger()
        )
        
        let instance = QuicUICodePushPlugin()
        instance.methodHandler = CodePushMethodHandler(with: channel)
        
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        print("[QuicUICodePush] Plugin registered")
        
        // Enable code push by default if QuicUI SDK is detected
        if QuicUISDKDetection.shared.isQuicUISDK() {
            QuicUICodePushLoader.shared.setCodePushEnabled(true)
            print("[QuicUICodePush] Code push enabled (QuicUI SDK detected)")
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        methodHandler?.handle(call, result: result)
    }
    
    /// Called when app is about to be killed
    public func applicationWillTerminate(_ application: UIApplication) {
        // Clean up old patches
        methodHandler?.cleanupOldPatches()
    }
}

/// AppDelegate extension to integrate code push loading
extension FlutterAppDelegate {
    
    /// Override this in your AppDelegate to enable code push loading
    /// 
    /// Example:
    /// ```
    /// override func application(
    ///     _ application: UIApplication,
    ///     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    /// ) -> Bool {
    ///     // Check for patches before Flutter engine starts
    ///     QuicUICodePush.loadPatchBeforeFlutterStarts()
    ///     
    ///     GeneratedPluginRegistrant.register(with: self)
    ///     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    /// }
    /// ```
    public static func loadPatchBeforeFlutterStarts() {
        print("[QuicUICodePush] Checking for patches...")
        
        // Check if QuicUI SDK is being used
        guard QuicUISDKDetection.shared.isQuicUISDK() else {
            print("[QuicUICodePush] Standard Flutter SDK detected - code push not available")
            return
        }
        
        // Load patched snapshot if available
        if let patchedPath = QuicUICodePushLoader.shared.loadPatchedSnapshot() {
            print("[QuicUICodePush] ✅ Using patched snapshot: \(patchedPath)")
            
            // TODO: Configure Flutter engine to use custom snapshot path
            // This requires modifying the Flutter engine initialization
            // See: flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine.mm
            
        } else {
            print("[QuicUICodePush] Using base snapshot")
        }
    }
}
