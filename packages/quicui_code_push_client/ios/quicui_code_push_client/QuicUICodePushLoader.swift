import Flutter
import Foundation
import CommonCrypto

/// QuicUI Code Push Loader for iOS
/// Handles patch loading and application at app startup
/// Similar to Android's QuicUICodePushLoader.kt
class QuicUICodePushLoader {
    
    static let shared = QuicUICodePushLoader()
    
    private let fileManager = FileManager.default
    private let userDefaults = UserDefaults.standard
    
    // Constants
    private let PREF_KEY_LOADED_PATCH_VERSION = "quicui_loaded_patch_version"
    private let PREF_KEY_PENDING_PATCH_VERSION = "quicui_pending_patch_version"
    private let PREF_KEY_CODE_PUSH_ENABLED = "quicui_code_push_enabled"
    
    private init() {}
    
    // MARK: - Public API
    
    /// Check if code push is enabled
    var isCodePushEnabled: Bool {
        return userDefaults.bool(forKey: PREF_KEY_CODE_PUSH_ENABLED)
    }
    
    /// Enable or disable code push
    func setCodePushEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: PREF_KEY_CODE_PUSH_ENABLED)
        userDefaults.synchronize()
    }
    
    /// Get the currently loaded patch version
    var loadedPatchVersion: String? {
        return userDefaults.string(forKey: PREF_KEY_LOADED_PATCH_VERSION)
    }
    
    /// Get the pending patch version (to be loaded on next restart)
    var pendingPatchVersion: String? {
        return userDefaults.string(forKey: PREF_KEY_PENDING_PATCH_VERSION)
    }
    
    /// Set the pending patch version
    func setPendingPatch(version: String) {
        userDefaults.set(version, forKey: PREF_KEY_PENDING_PATCH_VERSION)
        userDefaults.synchronize()
    }
    
    /// Clear the pending patch
    func clearPendingPatch() {
        userDefaults.removeObject(forKey: PREF_KEY_PENDING_PATCH_VERSION)
        userDefaults.synchronize()
    }
    
    /// Load and apply patch at app startup (called before Flutter engine starts)
    /// Returns the path to the patched snapshot, or nil if no patch available
    func loadPatchedSnapshot() -> String? {
        guard isCodePushEnabled else {
            print("[QuicUICodePush] Code push is disabled")
            return nil
        }
        
        guard let pendingVersion = pendingPatchVersion else {
            print("[QuicUICodePush] No pending patch")
            return nil
        }
        
        print("[QuicUICodePush] Loading pending patch: \(pendingVersion)")
        
        // Get paths
        guard let baseSnapshotPath = getBaseSnapshotPath(),
              let patchPath = getPatchPath(version: pendingVersion),
              let outputPath = getPatchedSnapshotPath() else {
            print("[QuicUICodePush] Failed to get paths")
            return nil
        }
        
        // Check if patch file exists
        guard fileManager.fileExists(atPath: patchPath) else {
            print("[QuicUICodePush] Patch file not found: \(patchPath)")
            return nil
        }
        
        do {
            // Apply patch
            print("[QuicUICodePush] Applying patch...")
            print("[QuicUICodePush] Base: \(baseSnapshotPath)")
            print("[QuicUICodePush] Patch: \(patchPath)")
            print("[QuicUICodePush] Output: \(outputPath)")
            
            try applyPatch(
                oldFile: baseSnapshotPath,
                patchFile: patchPath,
                newFile: outputPath
            )
            
            // Verify the patched file
            guard fileManager.fileExists(atPath: outputPath) else {
                print("[QuicUICodePush] Patched file not created")
                return nil
            }
            
            // Update loaded version
            userDefaults.set(pendingVersion, forKey: PREF_KEY_LOADED_PATCH_VERSION)
            clearPendingPatch()
            userDefaults.synchronize()
            
            print("[QuicUICodePush] ✅ Patch applied successfully!")
            print("[QuicUICodePush] Loaded patch version: \(pendingVersion)")
            
            return outputPath
            
        } catch {
            print("[QuicUICodePush] ❌ Failed to apply patch: \(error)")
            
            // Clean up failed patch
            try? fileManager.removeItem(atPath: outputPath)
            clearPendingPatch()
            
            return nil
        }
    }
    
    /// Check if running with patched snapshot
    func isRunningWithPatch() -> Bool {
        return loadedPatchVersion != nil
    }
    
    /// Rollback to base snapshot (remove patch)
    func rollbackToBase() {
        if let patchedPath = getPatchedSnapshotPath() {
            try? fileManager.removeItem(atPath: patchedPath)
        }
        
        userDefaults.removeObject(forKey: PREF_KEY_LOADED_PATCH_VERSION)
        clearPendingPatch()
        userDefaults.synchronize()
        
        print("[QuicUICodePush] Rolled back to base snapshot")
    }
    
    // MARK: - Path Helpers
    
    /// Get the base (original) Flutter snapshot path
    private func getBaseSnapshotPath() -> String? {
        // iOS Flutter AOT snapshot location
        // Framework/App.framework/flutter_assets/isolate_snapshot_data
        guard let frameworkPath = Bundle.main.privateFrameworksPath else {
            return nil
        }
        
        let snapshotPath = "\(frameworkPath)/App.framework/flutter_assets/isolate_snapshot_data"
        
        if fileManager.fileExists(atPath: snapshotPath) {
            return snapshotPath
        }
        
        // Alternative location for older Flutter versions
        let altPath = "\(frameworkPath)/App.framework/flutter_assets/kernel_blob.bin"
        if fileManager.fileExists(atPath: altPath) {
            return altPath
        }
        
        return nil
    }
    
    /// Get the patch file path for a version
    private func getPatchPath(version: String) -> String? {
        guard let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let patchesDir = cachesDir.appendingPathComponent("quicui_patches", isDirectory: true)
        return patchesDir.appendingPathComponent("\(version).quicui").path
    }
    
    /// Get the output path for the patched snapshot
    private func getPatchedSnapshotPath() -> String? {
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let patchedDir = documentsDir.appendingPathComponent("quicui_snapshots", isDirectory: true)
        
        // Create directory if needed
        try? fileManager.createDirectory(at: patchedDir, withIntermediateDirectories: true)
        
        return patchedDir.appendingPathComponent("isolate_snapshot_data.patched").path
    }
    
    // MARK: - Patch Application
    
    /// Apply BsDiff patch to create new snapshot (public API)
    func applyPatchPublic(oldFile: String, patchFile: String, newFile: String) throws {
        try applyPatch(oldFile: oldFile, patchFile: patchFile, newFile: newFile)
    }
    
    /// Apply BsDiff patch to create new snapshot
    private func applyPatch(oldFile: String, patchFile: String, newFile: String) throws {
        // Read patch file
        let patchData = try Data(contentsOf: URL(fileURLWithPath: patchFile))
        
        // Parse patch
        let patch = try parsePatch(data: patchData)
        
        // Read old file
        let oldData = try Data(contentsOf: URL(fileURLWithPath: oldFile))
        
        // Validate old file hash
        let oldHash = sha256(data: oldData)
        guard oldHash == patch.oldHash else {
            throw CodePushError.hashMismatch("Old file hash mismatch")
        }
        
        // Apply patch operations
        var newData = Data()
        newData.reserveCapacity(patch.newSize)
        
        for operation in patch.operations {
            switch operation.type {
            case .copy:
                // Copy bytes from old file
                let start = operation.oldOffset
                let end = start + operation.length
                guard end <= oldData.count else {
                    throw CodePushError.invalidPatch("Copy operation out of bounds")
                }
                newData.append(oldData[start..<end])
                
            case .add:
                // Add new bytes
                guard let data = operation.data else {
                    throw CodePushError.invalidPatch("Add operation missing data")
                }
                newData.append(data)
            }
        }
        
        // Validate new file size
        guard newData.count == patch.newSize else {
            throw CodePushError.invalidPatch("New file size mismatch")
        }
        
        // Validate new file hash
        let newHash = sha256(data: newData)
        guard newHash == patch.newHash else {
            throw CodePushError.hashMismatch("New file hash mismatch")
        }
        
        // Write new file
        try newData.write(to: URL(fileURLWithPath: newFile))
    }
    
    /// Parse .quicui patch file format
    private func parsePatch(data: Data) throws -> Patch {
        var data = data
        var offset = 0
        
        // Read magic signature (8 bytes)
        guard data.count >= 8 else {
            throw CodePushError.invalidPatch("File too small")
        }
        
        let magic = String(data: data[offset..<offset+8], encoding: .utf8) ?? ""
        offset += 8
        
        guard magic == "QUICUI01" else {
            throw CodePushError.invalidPatch("Invalid magic signature: \(magic)")
        }
        
        // Read header (24 bytes)
        guard data.count >= offset + 24 else {
            throw CodePushError.invalidPatch("Header too small")
        }
        
        let oldSize = data.readInt64(at: &offset)
        let newSize = data.readInt64(at: &offset)
        let operationCount = data.readInt64(at: &offset)
        
        // Read hashes (128 bytes)
        guard data.count >= offset + 128 else {
            throw CodePushError.invalidPatch("Hashes section too small")
        }
        
        let oldHash = String(data: data[offset..<offset+64], encoding: .utf8) ?? ""
        offset += 64
        
        let newHash = String(data: data[offset..<offset+64], encoding: .utf8) ?? ""
        offset += 64
        
        // Read operations
        var operations: [PatchOperation] = []
        operations.reserveCapacity(Int(operationCount))
        
        for _ in 0..<operationCount {
            guard data.count >= offset + 1 else {
                throw CodePushError.invalidPatch("Operation header too small")
            }
            
            let typeByte = data[offset]
            offset += 1
            
            guard data.count >= offset + 16 else {
                throw CodePushError.invalidPatch("Operation data too small")
            }
            
            let opOffset = data.readInt64(at: &offset)
            let length = data.readInt64(at: &offset)
            
            let opType: OperationType
            var opData: Data? = nil
            
            if typeByte == 0 {
                // Copy operation
                opType = .copy
            } else if typeByte == 1 {
                // Add operation - read data
                opType = .add
                
                guard data.count >= offset + Int(length) else {
                    throw CodePushError.invalidPatch("Add operation data too small")
                }
                
                opData = data[offset..<offset+Int(length)]
                offset += Int(length)
            } else {
                throw CodePushError.invalidPatch("Invalid operation type: \(typeByte)")
            }
            
            operations.append(PatchOperation(
                type: opType,
                oldOffset: Int(opOffset),
                length: Int(length),
                data: opData
            ))
        }
        
        return Patch(
            oldSize: Int(oldSize),
            newSize: Int(newSize),
            oldHash: oldHash,
            newHash: newHash,
            operations: operations
        )
    }
    
    /// Calculate SHA256 hash of data
    private func sha256(data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Data Types
    
    struct Patch {
        let oldSize: Int
        let newSize: Int
        let oldHash: String
        let newHash: String
        let operations: [PatchOperation]
    }
    
    struct PatchOperation {
        let type: OperationType
        let oldOffset: Int
        let length: Int
        let data: Data?
    }
    
    enum OperationType {
        case copy
        case add
    }
    
    enum CodePushError: Error {
        case invalidPatch(String)
        case hashMismatch(String)
        case fileNotFound(String)
    }
}

// MARK: - Data Extension

extension Data {
    /// Read Int64 from data at offset (little endian)
    mutating func readInt64(at offset: inout Int) -> Int64 {
        let value = self.withUnsafeBytes { bytes -> Int64 in
            bytes.load(fromByteOffset: offset, as: Int64.self)
        }
        offset += 8
        return value
    }
}
