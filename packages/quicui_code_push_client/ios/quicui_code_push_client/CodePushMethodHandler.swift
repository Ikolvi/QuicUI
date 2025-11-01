import Flutter

/// QuicUI Code Push iOS implementation
/// Handles method channel calls from Dart for patch operations
class CodePushMethodHandler: NSObject, FlutterMethodCallDelegate {
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
        switch call.method {
        case "initCodePush":
            handleInitCodePush(call, result: result)
        case "checkPatch":
            handleCheckPatch(call, result: result)
        case "loadPatch":
            handleLoadPatch(call, result: result)
        case "disableCodePush":
            handleDisableCodePush(call, result: result)
        case "getLoadedPatchVersion":
            handleGetLoadedPatchVersion(call, result: result)
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
                DispatchQueue.main.async {
                    result([
                        "success": true,
                        "message": "Patch loaded from cache",
                        "patchVersion": version
                    ])
                }
                return
            }
            
            // Download patch
            let patchUrl = "\(self.serviceUrl)/api/v1/patches/\(version)"
            let success = self.downloadPatch(patchUrl, to: patchFile)
            
            DispatchQueue.main.async {
                result([
                    "success": success,
                    "message": success ? "Patch loaded successfully" : "Failed to download patch",
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
    
    /// Get the currently loaded patch version
    private func handleGetLoadedPatchVersion(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // TODO: Implement based on your patch loading mechanism
        result("")
    }
    
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
                try fileManager.createDirectory(
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
