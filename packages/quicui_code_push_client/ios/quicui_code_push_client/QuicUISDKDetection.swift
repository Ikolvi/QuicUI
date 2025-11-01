import Flutter
import Foundation

/// QuicUI SDK Detection for iOS
/// Detects which Flutter SDK was used to build the app
class QuicUISDKDetection {
    
    static let shared = QuicUISDKDetection()
    
    private init() {}
    
    /// Check if app was built with QuicUI SDK
    /// Returns true if QuicUI SDK detected, false otherwise
    func isQuicUISDK() -> Bool {
        // Method 1: Check Flutter version string
        if let version = getFlutterVersion() {
            print("[QuicUISDK] Flutter version: \(version)")
            
            // QuicUI SDK versions contain our marker: "3.38.0-1.0.pre-"
            if version.contains("-1.0.pre-") {
                print("[QuicUISDK] ✅ QuicUI SDK detected (version marker)")
                return true
            }
        }
        
        // Method 2: Check for QuicUI-specific files in the bundle
        if let frameworkPath = Bundle.main.privateFrameworksPath {
            let quicuiMarkerPath = "\(frameworkPath)/App.framework/.quicui_build_marker"
            
            if FileManager.default.fileExists(atPath: quicuiMarkerPath) {
                print("[QuicUISDK] ✅ QuicUI SDK detected (marker file)")
                return true
            }
        }
        
        // Method 3: Check for QuicUI-specific metadata
        if let buildInfo = getQuicUIBuildInfo() {
            print("[QuicUISDK] ✅ QuicUI SDK detected (build info)")
            print("[QuicUISDK] Build info: \(buildInfo)")
            return true
        }
        
        print("[QuicUISDK] ❌ Standard Flutter SDK detected")
        return false
    }
    
    /// Get Flutter version string from framework
    private func getFlutterVersion() -> String? {
        // Try to get version from Flutter.framework Info.plist
        guard let frameworkPath = Bundle.main.privateFrameworksPath else {
            return nil
        }
        
        let flutterPlistPath = "\(frameworkPath)/Flutter.framework/Info.plist"
        
        guard let plist = NSDictionary(contentsOfFile: flutterPlistPath),
              let version = plist["CFBundleShortVersionString"] as? String else {
            return nil
        }
        
        return version
    }
    
    /// Get QuicUI build information
    private func getQuicUIBuildInfo() -> [String: Any]? {
        guard let frameworkPath = Bundle.main.privateFrameworksPath else {
            return nil
        }
        
        let buildInfoPath = "\(frameworkPath)/App.framework/quicui_build_info.json"
        
        guard FileManager.default.fileExists(atPath: buildInfoPath),
              let data = try? Data(contentsOf: URL(fileURLWithPath: buildInfoPath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        return json
    }
    
    /// Get detailed SDK information
    func getSDKInfo() -> [String: Any] {
        var info: [String: Any] = [
            "isQuicUISDK": isQuicUISDK(),
            "flutterVersion": getFlutterVersion() ?? "unknown"
        ]
        
        if let buildInfo = getQuicUIBuildInfo() {
            info["quicuiBuildInfo"] = buildInfo
        }
        
        if let loader = QuicUICodePushLoader.shared as? QuicUICodePushLoader {
            info["codePushEnabled"] = loader.isCodePushEnabled
            info["loadedPatchVersion"] = loader.loadedPatchVersion ?? ""
            info["isRunningWithPatch"] = loader.isRunningWithPatch()
        }
        
        return info
    }
}

/// Expose SDK detection to method channel
extension CodePushMethodHandler {
    
    func handleGetSDKInfo(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let info = QuicUISDKDetection.shared.getSDKInfo()
        result(info)
    }
    
    func handleIsQuicUISDK(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let isQuicUI = QuicUISDKDetection.shared.isQuicUISDK()
        result(isQuicUI)
    }
}
