import Flutter
import Foundation

/// QuicUI Code Push iOS implementation
/// Handles method channel calls from Dart for patch operations
class CodePushMethodHandler: NSObject {
    static func dummyMethodToEnforceBundling() {}
    
    let channel: FlutterMethodChannel
    let fileManager = FileManager.default
    
    private var isInitialized = false
    private var serviceUrl: String = ""
    private var appId: String = ""
    private var appVersion: String = ""
    
    private let queue = DispatchQueue(label: "com.quicui.codepush", qos: .background)
    
    init(with channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("[QuicUICodePush] 🎯 Handler.handle() called with method: \(call.method)")
        switch call.method {
        case "initCodePush":
            handleInitCodePush(call, result: result)
        case "checkPatch":
            handleCheckPatch(call, result: result)
        case "loadPatch":
            handleLoadPatch(call, result: result)
        case "installPatch":
            handleInstallPatch(call, result: result)
        case "hasPatch":
            handleHasPatch(call, result: result)
        case "getInstalledPatchVersion":
            handleGetInstalledPatchVersion(call, result: result)
        case "clearPatch":
            handleClearPatch(call, result: result)
        case "getDeviceArchitecture":
            handleGetDeviceArchitecture(call, result: result)
        case "disableCodePush":
            handleDisableCodePush(call, result: result)
        case "getLoadedPatchVersion":
            handleGetLoadedPatchVersion(call, result: result)
        case "getSDKInfo":
            handleGetSDKInfo(call, result: result)
        case "isQuicUISDK":
            handleIsQuicUISDK(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// Initialize code push with service configuration
    private func handleInitCodePush(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        serviceUrl = args["serviceUrl"] as? String ?? "https://api.quicui.com"
        appId = args["appId"] as? String ?? "com.example.app"
        appVersion = args["appVersion"] as? String ?? "1.0.0"
        
        isInitialized = true
        result(true)
    }
    
    /// Check for available patches from the service
    private func handleCheckPatch(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard isInitialized else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Code push not initialized", details: nil))
            return
        }
        
        queue.async {
            let patchUrl = "\(self.serviceUrl)/api/v1/patches/check?app_id=\(self.appId)&version=\(self.appVersion)"
            
            if let patch = self.fetchPatchMetadata(patchUrl) {
                DispatchQueue.main.async {
                    result(patch)
                }
            } else {
                DispatchQueue.main.async {
                    result(nil)
                }
            }
        }
    }
    
    /// Load a specific patch by version
    private func handleLoadPatch(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let version = args["version"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Version required", details: nil))
            return
        }
        
        guard isInitialized else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Code push not initialized", details: nil))
            return
        }
        
        queue.async {
            let patchFile = self.getPatchFile(version: version)
            
            // Check if patch is cached
            if self.fileManager.fileExists(atPath: patchFile.path) {
                // Set as pending patch (will be applied on next restart)
                QuicUICodePushLoader.shared.setPendingPatch(version: version)
                
                DispatchQueue.main.async {
                    result([
                        "success": true,
                        "message": "Patch loaded from cache (restart required)",
                        "patchVersion": version
                    ])
                }
                return
            }
            
            // Download patch
            let patchUrl = "\(self.serviceUrl)/api/v1/patches/\(version)"
            let success = self.downloadPatch(patchUrl, to: patchFile)
            
            if success {
                // Set as pending patch (will be applied on next restart)
                QuicUICodePushLoader.shared.setPendingPatch(version: version)
            }
            
            DispatchQueue.main.async {
                result([
                    "success": success,
                    "message": success ? "Patch downloaded (restart required)" : "Failed to download patch",
                    "patchVersion": success ? version : nil
                ])
            }
        }
    }
    
    /// Disable code push functionality
    private func handleDisableCodePush(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        isInitialized = false
        serviceUrl = ""
        appId = ""
        appVersion = ""
        result(true)
    }
    
    /// Install a patch file
    private func handleInstallPatch(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("[QuicUI] 🔧 handleInstallPatch called")
        
        guard let args = call.arguments as? [String: Any],
              let patchPath = args["patchPath"] as? String,
              let version = args["version"] as? String else {
            print("[QuicUI] ❌ Invalid arguments for installPatch")
            result(FlutterError(code: "INVALID_ARGS", message: "patchPath and version required", details: nil))
            return
        }
        
        print("[QuicUI] 📦 Installing patch version: \(version)")
        print("[QuicUI] 📁 Source path: \(patchPath)")
        
        queue.async {
            // Get the cache directory for patches
            let cachesDirectory = self.fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let patchesDirectory = cachesDirectory.appendingPathComponent("quicui_patches", isDirectory: true)
            
            do {
                // Create directory if needed
                try self.fileManager.createDirectory(at: patchesDirectory, withIntermediateDirectories: true)
                
                // Get device architecture (arm64 for iOS)
                let arch = args["architecture"] as? String ?? "arm64"
                
                print("[QuicUI] Installing patch: \(version)")
                print("[QuicUI] Patch file: \(patchPath)")
                
                let sourceURL = URL(fileURLWithPath: patchPath)
                let fileExtension = sourceURL.pathExtension
                
                // Determine patch type by file extension
                let isPatchFile = (fileExtension == "quicui" || fileExtension == "patch")
                let isVMCode = (fileExtension == "vmcode")
                
                // Determine final destination based on file type
                let destinationFilename: String
                if isVMCode {
                    // For .vmcode files (iOS interpreter), keep the extension
                    destinationFilename = "\(version).vmcode"
                } else {
                    // For binary patches/shared libraries, use .so extension
                    destinationFilename = "libapp_patched_\(arch).so"
                }
                let destinationURL = patchesDirectory.appendingPathComponent(destinationFilename)
                
                // Remove existing file if present
                if self.fileManager.fileExists(atPath: destinationURL.path) {
                    try self.fileManager.removeItem(at: destinationURL)
                }
                
                if isPatchFile {
                    // Binary patch approach: Apply BsDiff patch to base App
                    print("[QuicUI] Using binary patch approach (.quicui)")
                    
                    guard let baseAppPath = self.getBaseAppFrameworkPath() else {
                        throw NSError(domain: "QuicUI", code: 1, userInfo: [
                            NSLocalizedDescriptionKey: "Could not locate base App.framework binary"
                        ])
                    }
                    
                    print("[QuicUI] Base App framework: \(baseAppPath)")
                    
                    let patchedAppPath = patchesDirectory.appendingPathComponent("App_temp_patched")
                    
                    print("[QuicUI] Applying BsDiff patch...")
                    let loader = QuicUICodePushLoader.shared
                    try loader.applyPatchPublic(
                        oldFile: baseAppPath,
                        patchFile: sourceURL.path,
                        newFile: patchedAppPath.path
                    )
                    
                    print("[QuicUI] Patch applied successfully")
                    
                    // Move patched file to final location
                    try self.fileManager.moveItem(atPath: patchedAppPath.path, toPath: destinationURL.path)
                    
                } else if isVMCode {
                    // Interpreter approach: .vmcode file is ready to load
                    print("[QuicUI] Using interpreter approach (.vmcode)")
                    print("[QuicUI] Copying .vmcode file directly")
                    
                    try self.fileManager.copyItem(at: sourceURL, to: destinationURL)
                    
                } else {
                    // Direct shared library approach (Android .so or pre-patched binary)
                    print("[QuicUI] Using direct library approach (.so or unknown)")
                    print("[QuicUI] Copying file directly")
                    
                    try self.fileManager.copyItem(at: sourceURL, to: destinationURL)
                }
                
                print("[QuicUI] Patched App saved to: \(destinationURL.path)")
                
                // Save metadata file for C++ loader
                let metadataURL = patchesDirectory.appendingPathComponent("metadata.json")
                let hash = args["hash"] as? String ?? ""
                let metadata = """
                {
                  "version": "\(version)",
                  "hash": "\(hash)",
                  "architecture": "\(arch)",
                  "type": "\(fileExtension)"
                }
                """
                try metadata.write(to: metadataURL, atomically: true, encoding: .utf8)
                
                // For .vmcode files, create a "current.vmcode" symlink for engine to find
                if isVMCode {
                    let currentLink = patchesDirectory.appendingPathComponent("current.vmcode")
                    
                    // Remove existing symlink if present
                    if self.fileManager.fileExists(atPath: currentLink.path) {
                        try? self.fileManager.removeItem(at: currentLink)
                    }
                    
                    // Create symlink to the new .vmcode file
                    do {
                        try self.fileManager.createSymbolicLink(at: currentLink, withDestinationURL: destinationURL)
                        print("[QuicUI] ✅ Created current.vmcode symlink")
                    } catch {
                        print("[QuicUI] ⚠️ Failed to create symlink: \(error)")
                    }
                }
                
                print("[QuicUI] ✅ Patch installed successfully!")
                print("[QuicUI] Version: \(version)")
                print("[QuicUI] Type: \(fileExtension)")
                
                DispatchQueue.main.async {
                    result(true)
                }
            } catch {
                print("[QuicUI] ❌ Error installing patch: \(error)")
                DispatchQueue.main.async {
                    result(FlutterError(code: "INSTALL_FAILED", message: "Failed to install patch: \(error.localizedDescription)", details: nil))
                }
            }
        }
    }
    
    /// Get the path to the base App.framework binary
    private func getBaseAppFrameworkPath() -> String? {
        // iOS App.framework location in the app bundle
        guard let frameworksPath = Bundle.main.privateFrameworksPath else {
            return nil
        }
        
        // Path to App.framework/App binary
        let appFrameworkPath = (frameworksPath as NSString).appendingPathComponent("App.framework/App")
        
        if fileManager.fileExists(atPath: appFrameworkPath) {
            return appFrameworkPath
        }
        
        return nil
    }
    
    /// Check if a patch is installed
    private func handleHasPatch(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let patchesDirectory = cachesDirectory.appendingPathComponent("quicui_patches", isDirectory: true)
        
        do {
            let files = try fileManager.contentsOfDirectory(at: patchesDirectory, includingPropertiesForKeys: nil)
            let hasPatch = files.contains { $0.lastPathComponent.hasPrefix("App-") }
            result(hasPatch)
        } catch {
            result(false)
        }
    }
    
    /// Get installed patch version
    private func handleGetInstalledPatchVersion(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let patchesDirectory = cachesDirectory.appendingPathComponent("quicui_patches", isDirectory: true)
        
        do {
            let files = try fileManager.contentsOfDirectory(at: patchesDirectory, includingPropertiesForKeys: nil)
            if let patchFile = files.first(where: { $0.lastPathComponent.hasPrefix("App-") }) {
                let version = patchFile.lastPathComponent.replacingOccurrences(of: "App-", with: "")
                result(version)
            } else {
                result(nil)
            }
        } catch {
            result(nil)
        }
    }
    
    /// Clear installed patch
    private func handleClearPatch(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        queue.async {
            let cachesDirectory = self.fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let patchesDirectory = cachesDirectory.appendingPathComponent("quicui_patches", isDirectory: true)
            
            do {
                try self.fileManager.removeItem(at: patchesDirectory)
                print("[QuicUI] Patches cleared")
                DispatchQueue.main.async {
                    result(true)
                }
            } catch {
                print("[QuicUI] Error clearing patches: \(error)")
                DispatchQueue.main.async {
                    result(false)
                }
            }
        }
    }
    
    /// Get device architecture
    private func handleGetDeviceArchitecture(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // iOS physical devices are arm64, simulators are x86_64 or arm64 (Apple Silicon)
        #if targetEnvironment(simulator)
            #if arch(x86_64)
                result("x86_64_sim")
            #elseif arch(arm64)
                result("arm64_sim")
            #else
                result("unknown")
            #endif
        #else
            result("arm64")
        #endif
    }
    
    /// Get the currently loaded patch version
    private func handleGetLoadedPatchVersion(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let version = QuicUICodePushLoader.shared.loadedPatchVersion ?? ""
        result(version)
    }
    
    // Note: handleGetSDKInfo and handleIsQuicUISDK are defined in QuicUISDKDetection.swift extension
    
    /// Fetch patch metadata from the service
    private func fetchPatchMetadata(_ url: String) -> [String: Any]? {
        let semaphore = DispatchSemaphore(value: 0)
        var patchData: [String: Any]? = nil
        
        guard let url = URL(string: url) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            guard error == nil, let data = data else {
                return
            }
            
            // Simple JSON parsing (in production, use JSONDecoder)
            // This is a placeholder
            patchData = [
                "version": "1.0.1",
                "platform": "ios",
                "patchHash": "abc123",
                "patchSize": 1024,
                "signature": "sig123",
                "critical": false,
                "releaseDate": "2024-11-01T00:00:00Z"
            ]
        }
        
        task.resume()
        semaphore.wait(timeout: .now() + 30)
        
        return patchData
    }
    
    /// Download patch file from service
    private func downloadPatch(_ url: String, to destination: URL) -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var success = false
        
        guard let url = URL(string: url) else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            guard error == nil, let data = data else {
                return
            }
            
            do {
                // Ensure parent directory exists
                try self.fileManager.createDirectory(
                    at: destination.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                
                try data.write(to: destination)
                success = true
            } catch {
                print("Error writing patch file: \(error)")
            }
        }
        
        task.resume()
        semaphore.wait(timeout: .now() + 30)
        
        return success
    }
    
    /// Get the file URL for storing a patch
    private func getPatchFile(version: String) -> URL {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let patchesDirectory = cachesDirectory.appendingPathComponent("quicui_patches", isDirectory: true)
        
        try? fileManager.createDirectory(at: patchesDirectory, withIntermediateDirectories: true)
        
        return patchesDirectory.appendingPathComponent("\(version).patch")
    }
    
    /// Clean up old patches to save storage
    func cleanupOldPatches(keepCount: Int = 3) {
        queue.async {
            let cachesDirectory = self.fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let patchesDirectory = cachesDirectory.appendingPathComponent("quicui_patches", isDirectory: true)
            
            guard let files = try? self.fileManager.contentsOfDirectory(
                at: patchesDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey]
            ) else {
                return
            }
            
            let sortedFiles = files.sorted { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                return date1 > date2
            }
            
            sortedFiles.dropFirst(keepCount).forEach { file in
                try? self.fileManager.removeItem(at: file)
            }
        }
    }
}

/// Register the code push method handler with Flutter
/// Call this from GeneratedPluginRegistrant or your main activity
func registerCodePushHandler(with flutterEngine: FlutterEngine) {
    let channel = FlutterMethodChannel(
        name: "com.quicui/codepush",
        binaryMessenger: flutterEngine.binaryMessenger
    )
    
    let handler = CodePushMethodHandler(with: channel)
    channel.setMethodCallHandler(handler.handle(_:result:))
}
