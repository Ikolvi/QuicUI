// Copyright 2025 QuicUI. All rights reserved.
// Flutter plugin for QuicUI Code Push on iOS

import Flutter
import UIKit

/**
 * QuicUI Code Push Plugin for iOS
 * 
 * Handles method channel calls from Dart side for:
 * - Checking for updates from backend
 * - Downloading patch files
 * - Applying patches
 * - Getting current version
 * - Managing patch lifecycle
 * 
 * Method Channel: "quicui_code_push"
 * 
 * Supported Methods:
 * - checkForUpdates: Query backend for available patches
 * - downloadPatch: Download a patch file
 * - applyPatch: Apply downloaded patch
 * - getCurrentVersion: Get current app version
 * - deletePatch: Remove installed patch (rollback)
 * - getPatchMetadata: Get info about installed patch
 */
public class QuicUICodePushPlugin: NSObject, FlutterPlugin {
    
    private let patcher = QuicUIPatcher()
    private let channelName = "quicui_code_push"
    
    // MARK: - Plugin Registration
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "quicui_code_push",
                                           binaryMessenger: registrar.messenger())
        let instance = QuicUICodePushPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        print("[QuicUI Plugin] Registered successfully")
    }
    
    // MARK: - Method Channel Handler
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("[QuicUI Plugin] Method call: \(call.method)")
        
        switch call.method {
        case "checkForUpdates":
            checkForUpdates(call, result: result)
            
        case "downloadPatch":
            downloadPatch(call, result: result)
            
        case "applyPatch":
            applyPatch(call, result: result)
            
        case "getCurrentVersion":
            getCurrentVersion(result: result)
            
        case "deletePatch":
            deletePatch(result: result)
            
        case "getPatchMetadata":
            getPatchMetadata(result: result)
            
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Check For Updates
    
    private func checkForUpdates(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let serverUrl = args["serverUrl"] as? String else {
            result(FlutterError(code: "INVALID_ARGS",
                              message: "Missing serverUrl parameter",
                              details: "Expected: { serverUrl: String }"))
            return
        }
        
        print("[QuicUI Plugin] Checking for updates at: \(serverUrl)")
        
        // Build API URL
        guard var urlComponents = URLComponents(string: serverUrl) else {
            result(FlutterError(code: "INVALID_URL",
                              message: "Invalid server URL: \(serverUrl)",
                              details: nil))
            return
        }
        
        // Ensure path includes /api/v1/patches
        if !urlComponents.path.contains("/api/v1/patches") {
            urlComponents.path = (urlComponents.path.hasSuffix("/") ? urlComponents.path : urlComponents.path + "/") + "api/v1/patches"
        }
        
        guard let url = urlComponents.url else {
            result(FlutterError(code: "INVALID_URL",
                              message: "Failed to construct API URL",
                              details: nil))
            return
        }
        
        print("[QuicUI Plugin] API URL: \(url.absoluteString)")
        
        // Make HTTP request
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                result(FlutterError(code: "NETWORK_ERROR",
                                  message: error.localizedDescription,
                                  details: nil))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                result(FlutterError(code: "INVALID_RESPONSE",
                                  message: "Invalid HTTP response",
                                  details: nil))
                return
            }
            
            print("[QuicUI Plugin] HTTP Status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                result(FlutterError(code: "HTTP_ERROR",
                                  message: "HTTP \(httpResponse.statusCode)",
                                  details: nil))
                return
            }
            
            guard let data = data else {
                result(FlutterError(code: "NO_DATA",
                                  message: "No response data",
                                  details: nil))
                return
            }
            
            // Parse JSON
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    print("[QuicUI Plugin] Found \(json.count) patch(es)")
                    
                    // Filter for iOS patches
                    let iosPatches = json.filter { patch in
                        if let platform = patch["platform"] as? String {
                            return platform.lowercased() == "ios"
                        }
                        return false
                    }
                    
                    if let latest = iosPatches.first {
                        print("[QuicUI Plugin] Latest iOS patch: \(latest)")
                        result(latest)
                    } else if let latest = json.first {
                        // Fallback: return first patch if no iOS-specific one
                        print("[QuicUI Plugin] No iOS patch found, returning first available")
                        result(latest)
                    } else {
                        print("[QuicUI Plugin] No patches available")
                        result(nil)
                    }
                } else {
                    result(FlutterError(code: "PARSE_ERROR",
                                      message: "Invalid JSON format (expected array)",
                                      details: nil))
                }
            } catch {
                result(FlutterError(code: "PARSE_ERROR",
                                  message: error.localizedDescription,
                                  details: nil))
            }
        }
        
        task.resume()
    }
    
    // MARK: - Download Patch
    
    private func downloadPatch(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let patchUrl = args["patchUrl"] as? String else {
            result(FlutterError(code: "INVALID_ARGS",
                              message: "Missing patchUrl parameter",
                              details: "Expected: { patchUrl: String }"))
            return
        }
        
        print("[QuicUI Plugin] Downloading patch from: \(patchUrl)")
        
        guard let url = URL(string: patchUrl) else {
            result(FlutterError(code: "INVALID_URL",
                              message: "Invalid patch URL: \(patchUrl)",
                              details: nil))
            return
        }
        
        let patchDir = QuicUIPatcher.getPatchDirectory()
        let patchPath = (patchDir as NSString).appendingPathComponent("patch.bsdiff")
        
        // Download file
        let task = URLSession.shared.downloadTask(with: url) { tempUrl, response, error in
            if let error = error {
                result(FlutterError(code: "DOWNLOAD_ERROR",
                                  message: error.localizedDescription,
                                  details: nil))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                result(FlutterError(code: "INVALID_RESPONSE",
                                  message: "Invalid HTTP response",
                                  details: nil))
                return
            }
            
            print("[QuicUI Plugin] Download status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                result(FlutterError(code: "HTTP_ERROR",
                                  message: "HTTP \(httpResponse.statusCode)",
                                  details: nil))
                return
            }
            
            guard let tempUrl = tempUrl else {
                result(FlutterError(code: "NO_FILE",
                                  message: "No downloaded file",
                                  details: nil))
                return
            }
            
            // Move to patch directory
            do {
                if FileManager.default.fileExists(atPath: patchPath) {
                    try FileManager.default.removeItem(atPath: patchPath)
                }
                try FileManager.default.moveItem(at: tempUrl,
                                                to: URL(fileURLWithPath: patchPath))
                
                let fileSize = try FileManager.default.attributesOfItem(atPath: patchPath)[.size] as? Int64 ?? 0
                print("[QuicUI Plugin] ✅ Patch downloaded: \(patchPath) (\(fileSize) bytes)")
                
                result([
                    "success": true,
                    "path": patchPath,
                    "size": fileSize
                ])
            } catch {
                result(FlutterError(code: "FILE_ERROR",
                                  message: error.localizedDescription,
                                  details: nil))
            }
        }
        
        task.resume()
    }
    
    // MARK: - Apply Patch
    
    private func applyPatch(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let patchPath = args["patchPath"] as? String else {
            result(FlutterError(code: "INVALID_ARGS",
                              message: "Missing patchPath parameter",
                              details: "Expected: { patchPath: String }"))
            return
        }
        
        print("[QuicUI Plugin] Applying patch: \(patchPath)")
        
        // Get original libapp.so path
        // iOS: App.framework/flutter_assets/... is not the right path
        // We need to find App.framework/App (the main executable)
        
        let bundle = Bundle.main
        
        // Try to find App.framework
        guard let frameworksPath = bundle.privateFrameworksPath,
              let appFrameworkPath = findAppFramework(in: frameworksPath) else {
            result(FlutterError(code: "FILE_NOT_FOUND",
                              message: "Could not find App.framework",
                              details: "Frameworks path: \(bundle.privateFrameworksPath ?? "nil")"))
            return
        }
        
        let originalPath = (appFrameworkPath as NSString).appendingPathComponent("App")
        
        print("[QuicUI Plugin] Original AOT: \(originalPath)")
        
        guard FileManager.default.fileExists(atPath: originalPath) else {
            result(FlutterError(code: "FILE_NOT_FOUND",
                              message: "Could not find original App executable",
                              details: "Path: \(originalPath)"))
            return
        }
        
        // Output path
        let patchDir = QuicUIPatcher.getPatchDirectory()
        let outputPath = (patchDir as NSString).appendingPathComponent("libapp.so")
        
        print("[QuicUI Plugin] Output path: \(outputPath)")
        
        // Apply patch (this may take a few seconds)
        DispatchQueue.global(qos: .userInitiated).async {
            let success = self.patcher.applyPatch(originalPath: originalPath,
                                                  patchPath: patchPath,
                                                  outputPath: outputPath)
            
            DispatchQueue.main.async {
                if success {
                    // Verify patched file
                    let verified = self.patcher.verifyPatch(patchedPath: outputPath)
                    
                    if verified {
                        print("[QuicUI Plugin] ✅ Patch applied and verified successfully")
                        result([
                            "success": true,
                            "outputPath": outputPath,
                            "verified": true
                        ])
                    } else {
                        print("[QuicUI Plugin] ⚠️  Patch applied but verification failed")
                        result([
                            "success": true,
                            "outputPath": outputPath,
                            "verified": false
                        ])
                    }
                } else {
                    print("[QuicUI Plugin] ❌ Patch application failed")
                    result(FlutterError(code: "PATCH_FAILED",
                                      message: "Failed to apply patch",
                                      details: nil))
                }
            }
        }
    }
    
    // MARK: - Get Current Version
    
    private func getCurrentVersion(result: @escaping FlutterResult) {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            result("\(version) (\(build))")
        } else {
            result("unknown")
        }
    }
    
    // MARK: - Delete Patch
    
    private func deletePatch(result: @escaping FlutterResult) {
        print("[QuicUI Plugin] Deleting patch...")
        let success = QuicUIPatcher.deleteAllPatches()
        result(["success": success])
    }
    
    // MARK: - Get Patch Metadata
    
    private func getPatchMetadata(result: @escaping FlutterResult) {
        let patchDir = QuicUIPatcher.getPatchDirectory()
        let patchPath = (patchDir as NSString).appendingPathComponent("libapp.so")
        
        guard FileManager.default.fileExists(atPath: patchPath) else {
            result(nil)
            return
        }
        
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: patchPath)
            let size = attrs[.size] as? Int64 ?? 0
            let modDate = attrs[.modificationDate] as? Date ?? Date()
            
            result([
                "path": patchPath,
                "size": size,
                "modificationDate": ISO8601DateFormatter().string(from: modDate)
            ])
        } catch {
            result(nil)
        }
    }
    
    // MARK: - Helper Methods
    
    private func findAppFramework(in frameworksPath: String) -> String? {
        let fileManager = FileManager.default
        
        // Try App.framework directly
        let appFrameworkPath = (frameworksPath as NSString).appendingPathComponent("App.framework")
        if fileManager.fileExists(atPath: appFrameworkPath) {
            return appFrameworkPath
        }
        
        // Search in subdirectories
        guard let contents = try? fileManager.contentsOfDirectory(atPath: frameworksPath) else {
            return nil
        }
        
        for item in contents {
            if item.hasSuffix(".framework") {
                let path = (frameworksPath as NSString).appendingPathComponent(item)
                let appPath = (path as NSString).appendingPathComponent("App")
                if fileManager.fileExists(atPath: appPath) {
                    return path
                }
            }
        }
        
        return nil
    }
}
