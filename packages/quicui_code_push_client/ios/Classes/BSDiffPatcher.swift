// Copyright 2025 QuicUI. All rights reserved.
// Swift implementation of bsdiff patch algorithm

import Foundation
import Compression

/**
 * BSDiff patch algorithm implementation in Swift
 * 
 * Based on bsdiff algorithm by Colin Percival
 * Applies binary patches in bsdiff format to create new files
 * 
 * bsdiff Format:
 * - Header (32 bytes):
 *   - Magic: "BSDIFF40" (8 bytes)
 *   - New file size: int64 (8 bytes)
 *   - Control block length: int64 (8 bytes)
 *   - Diff block length: int64 (8 bytes)
 * - Control block: Compressed (bzip2/lzma) control data
 * - Diff block: Compressed diff data
 * - Extra block: Compressed extra data
 * 
 * Algorithm:
 * 1. Read and validate header
 * 2. Decompress control, diff, and extra blocks
 * 3. Apply patch by reading control data and applying diffs
 * 4. Verify output size matches expected
 */
public class BSDiffPatcher {
    
    // BSDIFF40 magic number
    private let BSDIFF_MAGIC: [UInt8] = [0x42, 0x53, 0x44, 0x49, 0x46, 0x46, 0x34, 0x30]
    
    // Header size
    private let HEADER_SIZE = 32
    
    public init() {}
    
    /**
     * Applies a bsdiff patch to original data
     * 
     * - Parameters:
     *   - original: Original file data
     *   - patch: Patch file data (bsdiff format)
     * - Returns: Patched data, or nil if failed
     */
    public func patch(original: Data, patch: Data) -> Data? {
        print("[BSDiff] Starting patch application...")
        print("[BSDiff] Original size: \(original.count) bytes")
        print("[BSDiff] Patch size: \(patch.count) bytes")
        
        // Parse patch header
        guard patch.count >= HEADER_SIZE else {
            print("[BSDiff] Error: Patch too small (need at least \(HEADER_SIZE) bytes)")
            return nil
        }
        
        // Verify magic number
        let magic = Array(patch[0..<8])
        guard magic == BSDIFF_MAGIC else {
            print("[BSDiff] Error: Invalid magic number")
            print("[BSDiff]   Expected: \(BSDIFF_MAGIC.map { String(format: "%02X", $0) }.joined(separator: " "))")
            print("[BSDiff]   Got:      \(magic.map { String(format: "%02X", $0) }.joined(separator: " "))")
            return nil
        }
        
        print("[BSDiff] ✓ Magic number verified")
        
        // Read header values
        let newSize = readInt64(from: patch, at: 8)
        let controlLength = readInt64(from: patch, at: 16)
        let diffLength = readInt64(from: patch, at: 24)
        
        guard newSize > 0, controlLength > 0, diffLength > 0 else {
            print("[BSDiff] Error: Invalid header values")
            print("[BSDiff]   newSize: \(newSize)")
            print("[BSDiff]   controlLength: \(controlLength)")
            print("[BSDiff]   diffLength: \(diffLength)")
            return nil
        }
        
        print("[BSDiff] Header: newSize=\(newSize), controlLen=\(controlLength), diffLen=\(diffLength)")
        
        // Extract compressed blocks
        let controlStart = HEADER_SIZE
        let diffStart = controlStart + Int(controlLength)
        let extraStart = diffStart + Int(diffLength)
        
        guard patch.count >= extraStart else {
            print("[BSDiff] Error: Patch truncated (need \(extraStart) bytes, have \(patch.count))")
            return nil
        }
        
        let controlBlock = patch.subdata(in: controlStart..<diffStart)
        let diffBlock = patch.subdata(in: diffStart..<extraStart)
        let extraBlock = patch.subdata(in: extraStart..<patch.count)
        
        print("[BSDiff] Decompressing blocks...")
        
        // Decompress blocks
        guard let controlData = decompress(controlBlock, label: "control") else {
            return nil
        }
        
        guard let diffData = decompress(diffBlock, label: "diff") else {
            return nil
        }
        
        guard let extraData = decompress(extraBlock, label: "extra") else {
            return nil
        }
        
        print("[BSDiff] ✓ All blocks decompressed successfully")
        print("[BSDiff]   Control: \(controlData.count) bytes")
        print("[BSDiff]   Diff: \(diffData.count) bytes")
        print("[BSDiff]   Extra: \(extraData.count) bytes")
        
        // Apply patch
        print("[BSDiff] Applying patch...")
        
        var newData = Data()
        newData.reserveCapacity(Int(newSize))
        
        var oldPos = 0
        var newPos = 0
        var controlPos = 0
        
        var iteration = 0
        
        while newPos < newSize {
            iteration += 1
            
            // Read control data (3 int64 values per iteration)
            guard controlPos + 24 <= controlData.count else {
                print("[BSDiff] Error: Truncated control data at iteration \(iteration)")
                return nil
            }
            
            let diffLen = readInt64(from: controlData, at: controlPos)
            let extraLen = readInt64(from: controlData, at: controlPos + 8)
            let seekAmount = readInt64(from: controlData, at: controlPos + 16)
            controlPos += 24
            
            // Validate values
            guard diffLen >= 0, extraLen >= 0 else {
                print("[BSDiff] Error: Invalid control values at iteration \(iteration)")
                return nil
            }
            
            // Apply diff block
            for _ in 0..<diffLen {
                guard newPos < newSize else { break }
                
                let oldByte: UInt8 = oldPos < original.count ? original[oldPos] : 0
                let diffByte: UInt8 = newPos < diffData.count ? diffData[newPos] : 0
                
                let newByte = UInt8(truncatingIfNeeded: Int(oldByte) + Int(diffByte))
                
                newData.append(newByte)
                oldPos += 1
                newPos += 1
            }
            
            // Apply extra block
            for _ in 0..<extraLen {
                guard newPos < newSize else { break }
                
                if newPos < extraData.count {
                    newData.append(extraData[newPos])
                } else {
                    newData.append(0)
                }
                
                newPos += 1
            }
            
            // Seek in old file
            oldPos = Int(Int64(oldPos) + seekAmount)
            
            // Progress logging (every 1000 iterations)
            if iteration % 1000 == 0 {
                let progress = Float(newPos) / Float(newSize) * 100.0
                print("[BSDiff] Progress: \(String(format: "%.1f", progress))% (iteration \(iteration))")
            }
        }
        
        // Verify output size
        guard newData.count == newSize else {
            print("[BSDiff] Error: Size mismatch!")
            print("[BSDiff]   Expected: \(newSize) bytes")
            print("[BSDiff]   Got:      \(newData.count) bytes")
            return nil
        }
        
        print("[BSDiff] ✅ Patch applied successfully!")
        print("[BSDiff] Final size: \(newData.count) bytes")
        print("[BSDiff] Total iterations: \(iteration)")
        
        return newData
    }
    
    /**
     * Reads a little-endian int64 from Data
     */
    private func readInt64(from data: Data, at offset: Int) -> Int64 {
        guard offset + 8 <= data.count else {
            return 0
        }
        
        let bytes = Array(data[offset..<(offset + 8)])
        var value: Int64 = 0
        
        for i in 0..<8 {
            value |= Int64(bytes[i]) << (i * 8)
        }
        
        return value
    }
    
    /**
     * Decompresses data using LZMA algorithm
     * 
     * iOS supports LZMA decompression via Compression framework
     */
    private func decompress(_ data: Data, label: String) -> Data? {
        // Try multiple decompression algorithms
        
        // 1. Try LZMA (xz format) - QuicUI default
        if let decompressed = decompressWithAlgorithm(data, algorithm: COMPRESSION_LZMA) {
            print("[BSDiff] ✓ Decompressed \(label) block with LZMA")
            return decompressed
        }
        
        // 2. Try LZ4
        if let decompressed = decompressWithAlgorithm(data, algorithm: COMPRESSION_LZ4) {
            print("[BSDiff] ✓ Decompressed \(label) block with LZ4")
            return decompressed
        }
        
        // 3. Try ZLIB
        if let decompressed = decompressWithAlgorithm(data, algorithm: COMPRESSION_ZLIB) {
            print("[BSDiff] ✓ Decompressed \(label) block with ZLIB")
            return decompressed
        }
        
        // 4. Try LZFSE
        if let decompressed = decompressWithAlgorithm(data, algorithm: COMPRESSION_LZFSE) {
            print("[BSDiff] ✓ Decompressed \(label) block with LZFSE")
            return decompressed
        }
        
        print("[BSDiff] Error: Failed to decompress \(label) block with any algorithm")
        return nil
    }
    
    /**
     * Attempts decompression with a specific algorithm
     */
    private func decompressWithAlgorithm(_ data: Data, algorithm: compression_algorithm) -> Data? {
        // Estimate decompressed size (typically 5-10x compressed size)
        let estimatedSize = data.count * 10
        var decompressed = Data(count: estimatedSize)
        
        var actualSize = 0
        
        actualSize = decompressed.withUnsafeMutableBytes { destBuffer in
            data.withUnsafeBytes { srcBuffer in
                compression_decode_buffer(
                    destBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    estimatedSize,
                    srcBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    data.count,
                    nil,
                    algorithm
                )
            }
        }
        
        guard actualSize > 0 else {
            return nil
        }
        
        decompressed.count = actualSize
        return decompressed
    }
}
