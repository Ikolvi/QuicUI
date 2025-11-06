// Copyright 2025 QuicUI. All rights reserved.
// High-level wrapper for QuicUI binary patching

import Foundation

/**
 * QuicUI Binary Patcher for iOS
 * 
 * High-level wrapper around BSDiffPatcher that handles:
 * - File I/O
 * - Path resolution
 * - Error handling
 * - Logging
 * - Checksum generation
 * 
 * Usage:
 * ```swift
 * let patcher = QuicUIPatcher()
 * let success = patcher.applyPatch(
 *     originalPath: "/path/to/original/libapp.so",
 *     patchPath: "/path/to/patch.bsdiff",
 *     outputPath: "/path/to/output/libapp.so"
 * )
 * ```
 */
public class QuicUIPatcher {
    
    private let bsDiffPatcher: BSDiffPatcher
    
    public init() {
        self.bsDiffPatcher = BSDiffPatcher()
    }
    
    /**
     * Applies a bsdiff patch to create a new libapp.so
     * 
     * - Parameters:
     *   - originalPath: Path to original libapp.so (from App.framework)
     *   - patchPath: Path to .patch file (bsdiff format)
     *   - outputPath: Path where patched libapp.so will be saved
     * - Returns: true if successful, false otherwise
     */
    public func applyPatch(originalPath: String, patchPath: String, outputPath: String) -> Bool {
        print("[QuicUI] ==========================================")
        print("[QuicUI] Starting patch application...")
        print("[QuicUI] ==========================================")
        print("[QuicUI]   Original: \(originalPath)")
        print("[QuicUI]   Patch:    \(patchPath)")
        print("[QuicUI]   Output:   \(outputPath)")
        
        let startTime = Date()
        
        // Validate input files
        guard FileManager.default.fileExists(atPath: originalPath) else {
            print("[QuicUI] ❌ Error: Original file not found: \(originalPath)")
            return false
        }
        
        guard FileManager.default.fileExists(atPath: patchPath) else {
            print("[QuicUI] ❌ Error: Patch file not found: \(patchPath)")
            return false
        }
        
        // Get file sizes
        let originalSize = getFileSize(originalPath)
        let patchSize = getFileSize(patchPath)
        
        print("[QuicUI] File sizes:")
        print("[QuicUI]   Original: \(formatBytes(originalSize))")
        print("[QuicUI]   Patch:    \(formatBytes(patchSize))")
        
        // Read files
        print("[QuicUI] Reading files...")
        
        guard let originalData = try? Data(contentsOf: URL(fileURLWithPath: originalPath)) else {
            print("[QuicUI] ❌ Error: Failed to read original file")
            return false
        }
        
        guard let patchData = try? Data(contentsOf: URL(fileURLWithPath: patchPath)) else {
            print("[QuicUI] ❌ Error: Failed to read patch file")
            return false
        }
        
        print("[QuicUI] ✓ Files read successfully")
        
        // Apply patch
        print("[QuicUI] Applying binary patch...")
        
        guard let patchedData = bsDiffPatcher.patch(original: originalData, patch: patchData) else {
            print("[QuicUI] ❌ Error: Failed to apply patch")
            return false
        }
        
        print("[QuicUI] ✓ Patch applied successfully")
        
        // Create output directory if needed
        let outputDir = (outputPath as NSString).deletingLastPathComponent
        if !FileManager.default.fileExists(atPath: outputDir) {
            do {
                try FileManager.default.createDirectory(atPath: outputDir,
                                                       withIntermediateDirectories: true,
                                                       attributes: nil)
                print("[QuicUI] Created output directory: \(outputDir)")
            } catch {
                print("[QuicUI] ❌ Error creating output directory: \(error)")
                return false
            }
        }
        
        // Write output
        print("[QuicUI] Writing patched file...")
        
        do {
            try patchedData.write(to: URL(fileURLWithPath: outputPath))
            print("[QuicUI] ✓ Patched file written successfully")
        } catch {
            print("[QuicUI] ❌ Error writing patched file: \(error.localizedDescription)")
            return false
        }
        
        // Generate checksum
        let checksum = sha256(data: patchedData)
        let checksumPath = outputPath + ".sha256"
        
        do {
            try checksum.write(to: URL(fileURLWithPath: checksumPath),
                             atomically: true,
                             encoding: .utf8)
            print("[QuicUI] ✓ Checksum saved: \(checksumPath)")
        } catch {
            print("[QuicUI] ⚠️  Warning: Failed to save checksum: \(error)")
            // Non-fatal error
        }
        
        // Calculate elapsed time
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Summary
        print("[QuicUI] ==========================================")
        print("[QuicUI] ✅ PATCH APPLICATION SUCCESSFUL")
        print("[QuicUI] ==========================================")
        print("[QuicUI] Summary:")
        print("[QuicUI]   Original size: \(formatBytes(originalData.count))")
        print("[QuicUI]   Patch size:    \(formatBytes(patchData.count))")
        print("[QuicUI]   Patched size:  \(formatBytes(patchedData.count))")
        print("[QuicUI]   Reduction:     \(String(format: "%.1f", Float(patchData.count) / Float(patchedData.count) * 100))%")
        print("[QuicUI]   Time elapsed:  \(String(format: "%.2f", elapsed))s")
        print("[QuicUI]   Checksum:      \(checksum)")
        print("[QuicUI] ==========================================")
        
        return true
    }
    
    /**
     * Gets the directory where patches are stored
     * 
     * Returns: NSDocumentDirectory/quicui_patches/
     */
    public static func getPatchDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDir = paths[0]
        let patchDir = (documentsDir as NSString).appendingPathComponent("quicui_patches")
        
        // Create directory if needed
        if !FileManager.default.fileExists(atPath: patchDir) {
            do {
                try FileManager.default.createDirectory(atPath: patchDir,
                                                       withIntermediateDirectories: true,
                                                       attributes: nil)
                print("[QuicUI] Created patch directory: \(patchDir)")
            } catch {
                print("[QuicUI] Warning: Failed to create patch directory: \(error)")
            }
        }
        
        return patchDir
    }
    
    /**
     * Verifies a patched file's integrity
     */
    public func verifyPatch(patchedPath: String) -> Bool {
        print("[QuicUI] Verifying patched file...")
        
        guard FileManager.default.fileExists(atPath: patchedPath) else {
            print("[QuicUI] Error: Patched file not found")
            return false
        }
        
        // Check ELF magic number
        guard let fileHandle = FileHandle(forReadingAtPath: patchedPath),
              let header = try? fileHandle.read(upToCount: 4) else {
            print("[QuicUI] Error: Cannot read file header")
            return false
        }
        
        try? fileHandle.close()
        
        let magic = Array(header)
        let expectedMagic: [UInt8] = [0x7F, 0x45, 0x4C, 0x46]  // 0x7F 'E' 'L' 'F'
        
        guard magic == expectedMagic else {
            print("[QuicUI] Error: Invalid ELF magic number")
            return false
        }
        
        print("[QuicUI] ✓ Patch verification successful")
        return true
    }
    
    /**
     * Deletes all patches (cleanup)
     */
    public static func deleteAllPatches() -> Bool {
        let patchDir = getPatchDirectory()
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: patchDir)
            for file in files {
                let filePath = (patchDir as NSString).appendingPathComponent(file)
                try FileManager.default.removeItem(atPath: filePath)
            }
            print("[QuicUI] ✓ All patches deleted")
            return true
        } catch {
            print("[QuicUI] Error deleting patches: \(error)")
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    private func getFileSize(_ path: String) -> Int64 {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let size = attrs[.size] as? NSNumber else {
            return 0
        }
        return size.int64Value
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        return formatBytes(Int64(bytes))
    }
    
    private func sha256(data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// Import CommonCrypto for SHA256
import CommonCrypto
