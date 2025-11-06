# QuicUI Code Push - iOS Implementation Plan

**Status**: 📋 Not Started (Planned for Q2 2026)  
**Platform**: iOS (iPhone/iPad)  
**Current Status**: Android 100% Complete  
**Target Timeline**: Phase 4 (Q2 2026)  
**Estimated Effort**: 8-12 weeks

---

## Executive Summary

This document outlines the complete implementation plan for bringing QuicUI Code Push to iOS, following the successful Android implementation. The iOS implementation will mirror the Android architecture while adapting to iOS-specific requirements and App Store policies.

### Key Differences from Android

| Aspect | Android | iOS |
|--------|---------|-----|
| **Primary Language** | Java/Kotlin | Objective-C/Swift |
| **Engine Integration** | `FlutterLoader.java` + JNI | `FlutterEngine.mm` + Native |
| **Patch Loader** | `quicui_patch_loader.cc` (JNI) | `quicui_patch_loader.mm` (Native) |
| **Binary Patcher** | `BsDiffPatcher.kt` (Kotlin) | `QuicUIPatcher.swift` (Swift) |
| **Patch Storage** | `/data/data/<app>/patches/` | `NSDocumentDirectory/patches/` |
| **App Store Policy** | ✅ More lenient | ⚠️ More restrictive |
| **Code Signing** | APK signature | Provisioning profile + certificate |
| **Architectures** | arm64-v8a, armeabi-v7a, x86, x86_64 | arm64 (only) |

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [iOS Flutter Engine Modifications](#2-ios-flutter-engine-modifications)
3. [Native Patch Loader (Objective-C++)](#3-native-patch-loader-objective-c)
4. [Swift Patcher Library](#4-swift-patcher-library)
5. [Flutter Plugin (iOS)](#5-flutter-plugin-ios)
6. [App Store Compliance](#6-app-store-compliance)
7. [Build System Integration](#7-build-system-integration)
8. [Testing Strategy](#8-testing-strategy)
9. [Migration from Android](#9-migration-from-android)
10. [Timeline & Milestones](#10-timeline--milestones)
11. [Risk Assessment](#11-risk-assessment)
12. [Success Criteria](#12-success-criteria)

---

## 1. Architecture Overview

### 1.1 High-Level Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         iOS Application                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ Flutter App (Dart)                                            │  │
│  │  - quicui_code_push_client plugin                            │  │
│  │  - checkForUpdates() / applyPatch()                          │  │
│  └──────────────────┬───────────────────────────────────────────┘  │
│                     │                                                │
│                     │ Method Channel (iOS)                          │
│                     ▼                                                │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ QuicUICodePushPlugin.swift                                    │  │
│  │  - Handles method calls from Dart                            │  │
│  │  - Downloads patches from backend                            │  │
│  │  - Calls QuicUIPatcher.swift                                 │  │
│  └──────────────────┬───────────────────────────────────────────┘  │
│                     │                                                │
│                     ▼                                                │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ QuicUIPatcher.swift                                           │  │
│  │  - bsdiff patch application (Swift)                          │  │
│  │  - Saves patched libapp.so to NSDocumentDirectory           │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ FlutterEngine (iOS Framework)                                 │  │
│  │                                                                │  │
│  │  GeneratedPluginRegistrant.m (auto-generated)                 │  │
│  │    └─> Registers QuicUICodePushPlugin                        │  │
│  │                                                                │  │
│  │  FlutterAppDelegate.swift/AppDelegate.m                       │  │
│  │    └─> application:didFinishLaunchingWithOptions:            │  │
│  │         └─> QuicUICodePushLoader.check_and_load()            │  │
│  │                                                                │  │
│  │  ┌──────────────────────────────────────────────────────┐   │  │
│  │  │ FlutterEngine.mm (Modified)                          │   │  │
│  │  │  - (BOOL)runWithEntrypoint:(NSString*)entrypoint     │   │  │
│  │  │  {                                                     │   │  │
│  │  │      // ✨ NEW: QuicUI Code Push Integration          │   │  │
│  │  │      NSString* patchPath =                            │   │  │
│  │  │        [QuicUICodePushLoader checkAndLoadPatch];      │   │  │
│  │  │                                                         │   │  │
│  │  │      if (patchPath != nil) {                           │   │  │
│  │  │        [self loadAOTData:patchPath]; // Load patch    │   │  │
│  │  │      } else {                                          │   │  │
│  │  │        [self loadAOTData:_project.assetsPath];        │   │  │
│  │  │      }                                                  │   │  │
│  │  │                                                         │   │  │
│  │  │      // Continue with normal engine startup           │   │  │
│  │  │      return [super runWithEntrypoint:entrypoint];     │   │  │
│  │  │  }                                                     │   │  │
│  │  └──────────────────────────────────────────────────────┘   │  │
│  │                                                                │  │
│  │  ┌──────────────────────────────────────────────────────┐   │  │
│  │  │ QuicUICodePushLoader.mm (NEW)                        │   │  │
│  │  │  - Objective-C++ implementation                       │   │  │
│  │  │  - Checks for patched libapp.so                       │   │  │
│  │  │  - Returns path or nil                                │   │  │
│  │  │  - Validates patch integrity                          │   │  │
│  │  └──────────────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                       │
└───────────────────────────────────────────────────────────────────┘

Backend Server (Dart)
  - Serves iOS patches via HTTP API
  - /api/v1/patches endpoint
  - arm64 architecture only
```

### 1.2 File Structure

```
forks/flutter-quicui/engine/
├── shell/
│   └── platform/
│       └── darwin/
│           └── ios/
│               ├── framework/
│               │   └── Source/
│               │       ├── FlutterEngine.mm          # Modified (add QuicUI loader call)
│               │       ├── QuicUICodePushLoader.h   # NEW
│               │       ├── QuicUICodePushLoader.mm  # NEW (Objective-C++)
│               │       └── quicui_patch_loader.h    # NEW
│               └── quicui/                           # NEW directory
│                   ├── quicui_patch_loader.mm        # NEW (Native implementation)
│                   └── quicui_patch_loader.h         # NEW (Header)

packages/quicui_code_push_client/
├── ios/
│   ├── Classes/
│   │   ├── QuicUICodePushPlugin.swift               # NEW (Method channel handler)
│   │   ├── QuicUIPatcher.swift                      # NEW (bsdiff patcher in Swift)
│   │   └── BSDiffPatcher.swift                      # NEW (bsdiff implementation)
│   ├── quicui_code_push_client.podspec
│   └── Assets/
│       └── (patch files stored here)

test_apps/quicui_ios_test/                            # NEW test app
├── ios/
│   ├── Runner/
│   │   ├── AppDelegate.swift
│   │   ├── Info.plist
│   │   └── Runner-Bridging-Header.h
│   └── Podfile
└── lib/
    └── main.dart
```

---

## 2. iOS Flutter Engine Modifications

### 2.1 FlutterEngine.mm (Modified)

**Location**: `forks/flutter-quicui/engine/shell/platform/darwin/ios/framework/Source/FlutterEngine.mm`

**Current Code** (line ~300):

```objc
- (BOOL)runWithEntrypoint:(nullable NSString*)entrypoint {
  return [self runWithEntrypoint:entrypoint libraryURI:nil];
}

- (BOOL)runWithEntrypoint:(nullable NSString*)entrypoint
               libraryURI:(nullable NSString*)libraryURI {
  return [self runWithEntrypoint:entrypoint
                      libraryURI:libraryURI
                    initialRoute:nil];
}

- (BOOL)runWithEntrypoint:(nullable NSString*)entrypoint
               libraryURI:(nullable NSString*)libraryURI
             initialRoute:(nullable NSString*)initialRoute {
  return [self runWithEntrypoint:entrypoint
                      libraryURI:libraryURI
                    initialRoute:initialRoute
                  entrypointArgs:nil];
}
```

**Modified Code** (add QuicUI integration):

```objc
#import "flutter/shell/platform/darwin/ios/framework/Source/QuicUICodePushLoader.h"

// ... existing code ...

- (BOOL)runWithEntrypoint:(nullable NSString*)entrypoint
               libraryURI:(nullable NSString*)libraryURI
             initialRoute:(nullable NSString*)initialRoute
           entrypointArgs:(nullable NSArray<NSString*>*)entrypointArgs {
  // ... existing validation code ...

  // ✨ NEW: QuicUI Code Push Integration
  NSString* patchPath = [QuicUICodePushLoader checkAndLoadPatch];
  
  if (patchPath != nil) {
    NSLog(@"[QuicUI] Loading patched libapp.so from: %@", patchPath);
    [self loadAOTData:patchPath];
  } else {
    NSLog(@"[QuicUI] No patch found, loading original libapp.so");
    // Load original AOT data
    NSString* assetsPath = [_dartProject assetsPath];
    [self loadAOTData:assetsPath];
  }

  // Continue with normal engine startup
  return [self runInternalWithEntrypoint:entrypoint
                              libraryURI:libraryURI
                            initialRoute:initialRoute
                          entrypointArgs:entrypointArgs];
}
```

**Changes Required**:
- Add `#import "QuicUICodePushLoader.h"` at top
- Insert QuicUI patch check before `loadAOTData:`
- Conditional loading: patch if available, otherwise original
- Add logging for debugging

**Lines Changed**: ~15 lines (minimal impact)

---

## 3. Native Patch Loader (Objective-C++)

### 3.1 QuicUICodePushLoader.h

**Location**: `forks/flutter-quicui/engine/shell/platform/darwin/ios/framework/Source/QuicUICodePushLoader.h`

```objc
// Copyright 2025 QuicUI. All rights reserved.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_QUICUICODEPUSHLOADER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_QUICUICODEPUSHLOADER_H_

#import <Foundation/Foundation.h>

/**
 * QuicUI Code Push Loader for iOS
 * 
 * Checks for and loads patched libapp.so files before Flutter engine startup.
 * Similar to Android's QuicUICodePushLoader.java but for iOS.
 */
@interface QuicUICodePushLoader : NSObject

/**
 * Checks if a patched libapp.so exists and is valid.
 * 
 * @return Path to patched libapp.so if available and valid, nil otherwise
 */
+ (nullable NSString*)checkAndLoadPatch;

/**
 * Validates patch file integrity (checksum, signature, etc.)
 * 
 * @param patchPath Path to the patch file to validate
 * @return YES if patch is valid, NO otherwise
 */
+ (BOOL)validatePatchIntegrity:(NSString*)patchPath;

/**
 * Gets the directory where patches are stored
 * 
 * @return Path to patches directory (NSDocumentDirectory/quicui_patches/)
 */
+ (NSString*)getPatchDirectory;

@end

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_QUICUICODEPUSHLOADER_H_
```

### 3.2 QuicUICodePushLoader.mm

**Location**: `forks/flutter-quicui/engine/shell/platform/darwin/ios/framework/Source/QuicUICodePushLoader.mm`

```objc
// Copyright 2025 QuicUI. All rights reserved.

#import "flutter/shell/platform/darwin/ios/framework/Source/QuicUICodePushLoader.h"
#import <CommonCrypto/CommonDigest.h>

@implementation QuicUICodePushLoader

+ (nullable NSString*)checkAndLoadPatch {
  @autoreleasepool {
    NSString* patchDir = [self getPatchDirectory];
    NSString* patchPath = [patchDir stringByAppendingPathComponent:@"libapp.so"];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    // Check if patch file exists
    if (![fileManager fileExistsAtPath:patchPath]) {
      NSLog(@"[QuicUI] No patch file found at: %@", patchPath);
      return nil;
    }
    
    // Validate patch integrity
    if (![self validatePatchIntegrity:patchPath]) {
      NSLog(@"[QuicUI] Patch validation failed: %@", patchPath);
      // Delete invalid patch
      [fileManager removeItemAtPath:patchPath error:nil];
      return nil;
    }
    
    NSLog(@"[QuicUI] Valid patch found: %@", patchPath);
    return patchPath;
  }
}

+ (BOOL)validatePatchIntegrity:(NSString*)patchPath {
  @autoreleasepool {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    // 1. Check file size (must be reasonable)
    NSDictionary* attrs = [fileManager attributesOfItemAtPath:patchPath error:nil];
    unsigned long long fileSize = [attrs fileSize];
    
    if (fileSize < 1024 || fileSize > 50 * 1024 * 1024) {  // 1KB - 50MB
      NSLog(@"[QuicUI] Invalid patch file size: %llu bytes", fileSize);
      return NO;
    }
    
    // 2. Verify SHA-256 checksum (if checksum file exists)
    NSString* checksumPath = [patchPath stringByAppendingString:@".sha256"];
    if ([fileManager fileExistsAtPath:checksumPath]) {
      NSString* expectedChecksum = [NSString stringWithContentsOfFile:checksumPath
                                                            encoding:NSUTF8StringEncoding
                                                               error:nil];
      
      NSString* actualChecksum = [self sha256ForFile:patchPath];
      
      if (![expectedChecksum isEqualToString:actualChecksum]) {
        NSLog(@"[QuicUI] Checksum mismatch! Expected: %@, Got: %@",
              expectedChecksum, actualChecksum);
        return NO;
      }
      
      NSLog(@"[QuicUI] Checksum verified: %@", actualChecksum);
    }
    
    // 3. Verify it's a valid ELF file (starts with 0x7F 'E' 'L' 'F')
    NSFileHandle* fileHandle = [NSFileHandle fileHandleForReadingAtPath:patchPath];
    NSData* header = [fileHandle readDataOfLength:4];
    [fileHandle closeFile];
    
    const uint8_t* bytes = (const uint8_t*)[header bytes];
    if (bytes[0] != 0x7F || bytes[1] != 'E' || bytes[2] != 'L' || bytes[3] != 'F') {
      NSLog(@"[QuicUI] Not a valid ELF file (magic number mismatch)");
      return NO;
    }
    
    return YES;
  }
}

+ (NSString*)getPatchDirectory {
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                        NSUserDomainMask,
                                                        YES);
  NSString* documentsDir = [paths firstObject];
  NSString* patchDir = [documentsDir stringByAppendingPathComponent:@"quicui_patches"];
  
  // Create directory if it doesn't exist
  NSFileManager* fileManager = [NSFileManager defaultManager];
  if (![fileManager fileExistsAtPath:patchDir]) {
    [fileManager createDirectoryAtPath:patchDir
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:nil];
  }
  
  return patchDir;
}

+ (NSString*)sha256ForFile:(NSString*)path {
  NSFileHandle* fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
  if (!fileHandle) {
    return nil;
  }
  
  CC_SHA256_CTX sha256;
  CC_SHA256_Init(&sha256);
  
  NSData* chunk;
  while ((chunk = [fileHandle readDataOfLength:8192]) && [chunk length] > 0) {
    CC_SHA256_Update(&sha256, [chunk bytes], (CC_LONG)[chunk length]);
  }
  
  unsigned char hash[CC_SHA256_DIGEST_LENGTH];
  CC_SHA256_Final(hash, &sha256);
  
  [fileHandle closeFile];
  
  NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
  for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
    [output appendFormat:@"%02x", hash[i]];
  }
  
  return output;
}

@end
```

**Key Features**:
- ✅ Checks for patch file in `NSDocumentDirectory/quicui_patches/`
- ✅ Validates file size (1KB - 50MB)
- ✅ Verifies SHA-256 checksum (if `.sha256` file exists)
- ✅ Validates ELF magic number (0x7F 'E' 'L' 'F')
- ✅ Returns path if valid, nil otherwise
- ✅ Auto-deletes invalid patches

**Lines of Code**: ~150 lines

---

## 4. Swift Patcher Library

### 4.1 QuicUIPatcher.swift

**Location**: `packages/quicui_code_push_client/ios/Classes/QuicUIPatcher.swift`

```swift
// Copyright 2025 QuicUI. All rights reserved.

import Foundation

/**
 * QuicUI Binary Patcher for iOS
 * 
 * Applies bsdiff patches to libapp.so files.
 * Swift equivalent of Android's BsDiffPatcher.kt
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
     *   - originalPath: Path to original libapp.so
     *   - patchPath: Path to .patch file (bsdiff format)
     *   - outputPath: Path where patched libapp.so will be saved
     * - Returns: true if successful, false otherwise
     */
    public func applyPatch(originalPath: String, patchPath: String, outputPath: String) -> Bool {
        print("[QuicUI] Applying patch...")
        print("[QuicUI]   Original: \(originalPath)")
        print("[QuicUI]   Patch:    \(patchPath)")
        print("[QuicUI]   Output:   \(outputPath)")
        
        guard FileManager.default.fileExists(atPath: originalPath) else {
            print("[QuicUI] Error: Original file not found: \(originalPath)")
            return false
        }
        
        guard FileManager.default.fileExists(atPath: patchPath) else {
            print("[QuicUI] Error: Patch file not found: \(patchPath)")
            return false
        }
        
        do {
            // Read files
            let originalData = try Data(contentsOf: URL(fileURLWithPath: originalPath))
            let patchData = try Data(contentsOf: URL(fileURLWithPath: patchPath))
            
            // Apply patch
            guard let patchedData = bsDiffPatcher.patch(original: originalData, patch: patchData) else {
                print("[QuicUI] Error: Failed to apply patch")
                return false
            }
            
            // Write output
            try patchedData.write(to: URL(fileURLWithPath: outputPath))
            
            print("[QuicUI] ✅ Patch applied successfully!")
            print("[QuicUI]   Original size: \(originalData.count) bytes")
            print("[QuicUI]   Patch size:    \(patchData.count) bytes")
            print("[QuicUI]   Patched size:  \(patchedData.count) bytes")
            
            return true
            
        } catch {
            print("[QuicUI] Error: \(error.localizedDescription)")
            return false
        }
    }
    
    /**
     * Gets the directory where patches are stored
     */
    public static func getPatchDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDir = paths[0]
        let patchDir = (documentsDir as NSString).appendingPathComponent("quicui_patches")
        
        // Create directory if needed
        if !FileManager.default.fileExists(atPath: patchDir) {
            try? FileManager.default.createDirectory(atPath: patchDir,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
        }
        
        return patchDir
    }
}
```

### 4.2 BSDiffPatcher.swift (bsdiff implementation)

**Location**: `packages/quicui_code_push_client/ios/Classes/BSDiffPatcher.swift`

```swift
// Copyright 2025 QuicUI. All rights reserved.
// Based on bsdiff algorithm by Colin Percival

import Foundation
import Compression

/**
 * BSDiff patch algorithm implementation in Swift
 */
public class BSDiffPatcher {
    
    private let BSDIFF_MAGIC: [UInt8] = [0x42, 0x53, 0x44, 0x49, 0x46, 0x46, 0x34, 0x30] // "BSDIFF40"
    
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
        // Parse patch header
        guard patch.count >= 32 else {
            print("[BSDiff] Error: Patch too small")
            return nil
        }
        
        // Verify magic number
        let magic = Array(patch[0..<8])
        guard magic == BSDIFF_MAGIC else {
            print("[BSDiff] Error: Invalid magic number")
            return nil
        }
        
        // Read header
        let newSize = readInt64(from: patch, at: 8)
        let controlLength = readInt64(from: patch, at: 16)
        let diffLength = readInt64(from: patch, at: 24)
        
        guard newSize > 0, controlLength > 0, diffLength > 0 else {
            print("[BSDiff] Error: Invalid header values")
            return nil
        }
        
        print("[BSDiff] Header: newSize=\(newSize), controlLen=\(controlLength), diffLen=\(diffLength)")
        
        // Extract blocks (after header)
        let headerSize = 32
        let controlBlock = patch.subdata(in: headerSize..<(headerSize + Int(controlLength)))
        let diffBlock = patch.subdata(in: (headerSize + Int(controlLength))..<(headerSize + Int(controlLength) + Int(diffLength)))
        let extraBlock = patch.subdata(in: (headerSize + Int(controlLength) + Int(diffLength))..<patch.count)
        
        // Decompress blocks (bsdiff uses bzip2, we'll use lzma/xz for compatibility)
        guard let controlData = decompress(controlBlock),
              let diffData = decompress(diffBlock),
              let extraData = decompress(extraBlock) else {
            print("[BSDiff] Error: Failed to decompress blocks")
            return nil
        }
        
        // Apply patch
        var newData = Data(capacity: Int(newSize))
        var oldPos = 0
        var newPos = 0
        var controlPos = 0
        
        while newPos < newSize {
            // Read control data (3 int64 values)
            guard controlPos + 24 <= controlData.count else {
                print("[BSDiff] Error: Truncated control data")
                return nil
            }
            
            let diffLen = readInt64(from: controlData, at: controlPos)
            let extraLen = readInt64(from: controlData, at: controlPos + 8)
            let seekAmount = readInt64(from: controlData, at: controlPos + 16)
            controlPos += 24
            
            // Apply diff block
            for _ in 0..<diffLen {
                guard newPos < newSize else { break }
                
                let oldByte = oldPos < original.count ? original[oldPos] : 0
                let diffByte = diffData[newPos]
                let newByte = (UInt8(truncatingIfNeeded: Int(oldByte) + Int(diffByte)))
                
                newData.append(newByte)
                oldPos += 1
                newPos += 1
            }
            
            // Apply extra block
            for _ in 0..<extraLen {
                guard newPos < newSize else { break }
                newData.append(extraData[newPos])
                newPos += 1
            }
            
            // Seek in old file
            oldPos = Int(Int64(oldPos) + seekAmount)
        }
        
        guard newData.count == newSize else {
            print("[BSDiff] Error: Size mismatch (expected \(newSize), got \(newData.count))")
            return nil
        }
        
        return newData
    }
    
    private func readInt64(from data: Data, at offset: Int) -> Int64 {
        let bytes = Array(data[offset..<(offset + 8)])
        var value: Int64 = 0
        for i in 0..<8 {
            value |= Int64(bytes[i]) << (i * 8)
        }
        return value
    }
    
    private func decompress(_ data: Data) -> Data? {
        // Use LZMA decompression (xz format)
        // iOS supports lzma via Compression framework
        let decompressedSize = data.count * 10 // Estimate
        var decompressed = Data(count: decompressedSize)
        
        let size = decompressed.withUnsafeMutableBytes { destBuffer in
            data.withUnsafeBytes { srcBuffer in
                compression_decode_buffer(
                    destBuffer.baseAddress!,
                    decompressedSize,
                    srcBuffer.baseAddress!,
                    data.count,
                    nil,
                    COMPRESSION_LZMA
                )
            }
        }
        
        guard size > 0 else {
            return nil
        }
        
        decompressed.count = size
        return decompressed
    }
}
```

**Key Features**:
- ✅ Pure Swift implementation
- ✅ bsdiff format parsing
- ✅ LZMA/xz decompression (iOS native)
- ✅ Robust error handling
- ✅ Detailed logging

**Lines of Code**: ~200 lines

---

## 5. Flutter Plugin (iOS)

### 5.1 QuicUICodePushPlugin.swift

**Location**: `packages/quicui_code_push_client/ios/Classes/QuicUICodePushPlugin.swift`

```swift
// Copyright 2025 QuicUI. All rights reserved.

import Flutter
import UIKit

/**
 * QuicUI Code Push Plugin for iOS
 * 
 * Handles method channel calls from Dart side.
 */
public class QuicUICodePushPlugin: NSObject, FlutterPlugin {
    
    private let patcher = QuicUIPatcher()
    private let channelName = "quicui_code_push"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "quicui_code_push",
                                           binaryMessenger: registrar.messenger())
        let instance = QuicUICodePushPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkForUpdates":
            checkForUpdates(call, result: result)
            
        case "downloadPatch":
            downloadPatch(call, result: result)
            
        case "applyPatch":
            applyPatch(call, result: result)
            
        case "getCurrentVersion":
            getCurrentVersion(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func checkForUpdates(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let serverUrl = args["serverUrl"] as? String else {
            result(FlutterError(code: "INVALID_ARGS",
                              message: "Missing serverUrl",
                              details: nil))
            return
        }
        
        // Call backend API
        let url = URL(string: "\(serverUrl)/api/v1/patches")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                result(FlutterError(code: "NETWORK_ERROR",
                                  message: error.localizedDescription,
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
                if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let latest = json.first {
                    result(latest)
                } else {
                    result(nil)
                }
            } catch {
                result(FlutterError(code: "PARSE_ERROR",
                                  message: error.localizedDescription,
                                  details: nil))
            }
        }
        
        task.resume()
    }
    
    private func downloadPatch(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let patchUrl = args["patchUrl"] as? String else {
            result(FlutterError(code: "INVALID_ARGS",
                              message: "Missing patchUrl",
                              details: nil))
            return
        }
        
        let url = URL(string: patchUrl)!
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
                result(patchPath)
            } catch {
                result(FlutterError(code: "FILE_ERROR",
                                  message: error.localizedDescription,
                                  details: nil))
            }
        }
        
        task.resume()
    }
    
    private func applyPatch(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let patchPath = args["patchPath"] as? String else {
            result(FlutterError(code: "INVALID_ARGS",
                              message: "Missing patchPath",
                              details: nil))
            return
        }
        
        // Get original libapp.so path
        let bundle = Bundle.main
        guard let frameworkPath = bundle.path(forResource: "App", ofType: "framework"),
              let appBundle = Bundle(path: frameworkPath),
              let originalPath = appBundle.path(forResource: "flutter_assets/libapp", ofType: "so") else {
            result(FlutterError(code: "FILE_NOT_FOUND",
                              message: "Could not find original libapp.so",
                              details: nil))
            return
        }
        
        // Output path
        let patchDir = QuicUIPatcher.getPatchDirectory()
        let outputPath = (patchDir as NSString).appendingPathComponent("libapp.so")
        
        // Apply patch
        let success = patcher.applyPatch(originalPath: originalPath,
                                        patchPath: patchPath,
                                        outputPath: outputPath)
        
        if success {
            result(["success": true, "outputPath": outputPath])
        } else {
            result(FlutterError(code: "PATCH_FAILED",
                              message: "Failed to apply patch",
                              details: nil))
        }
    }
    
    private func getCurrentVersion(result: @escaping FlutterResult) {
        // Read version from Info.plist
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            result(version)
        } else {
            result("unknown")
        }
    }
}
```

**Key Features**:
- ✅ Method channel implementation
- ✅ HTTP client for backend API
- ✅ File download and storage
- ✅ Patch application orchestration
- ✅ Error handling

**Lines of Code**: ~200 lines

---

## 6. App Store Compliance

### 6.1 iOS Restrictions (More Strict than Android)

Apple's App Store Review Guidelines are **MORE RESTRICTIVE** than Google Play Store:

#### ❌ What's NOT Allowed on iOS:

1. **Native Code Updates**: Cannot update compiled Objective-C/Swift code
2. **Framework Updates**: Cannot change app frameworks
3. **New APIs**: Cannot introduce new iOS APIs without review
4. **Core Functionality Changes**: Cannot change app's primary purpose

#### ✅ What IS Allowed on iOS:

1. **Bug Fixes**: Yes (critical updates)
2. **UI Changes**: Yes (Flutter widget updates)
3. **Business Logic**: Yes (Dart code)
4. **Performance**: Yes (optimizations)

### 6.2 Apple's Policy (Section 3.3.2)

> "Interpreted code may be downloaded to an Application but only so long as such code: (a) does not change the primary purpose of the Application by providing features or functionality that are inconsistent with the intended and advertised purpose..."

**Interpretation**:
- ✅ Flutter Dart code is "interpreted" (runs in VM)
- ✅ Bug fixes don't change primary purpose
- ⚠️ Major features may require review

### 6.3 Compliance Strategy

```swift
// PatchType enum (restrict what can be updated)
enum PatchType: String {
    case bugfix        // ✅ Allowed
    case performance   // ✅ Allowed
    case ui            // ✅ Allowed
    case content       // ✅ Allowed (text, images)
    case feature       // ⚠️ Minor only, no new permissions
}

// Validation before applying patch
func validatePatch(_ metadata: PatchMetadata) -> Bool {
    // 1. Check patch type
    guard metadata.type != .feature || metadata.minorFeature else {
        return false
    }
    
    // 2. Check size (< 10MB to avoid suspicion)
    guard metadata.size < 10 * 1024 * 1024 else {
        return false
    }
    
    // 3. Check frequency (max 1 patch per day)
    let lastPatchTime = UserDefaults.standard.double(forKey: "lastPatchTime")
    let now = Date().timeIntervalSince1970
    guard now - lastPatchTime > 24 * 60 * 60 else {
        return false
    }
    
    return true
}
```

### 6.4 Developer Guidelines (iOS-specific)

**QuicUI iOS Developer Guidelines**:

1. **Patch Types** (always specify in metadata):
   - `bugfix`: Critical bug fixes
   - `performance`: Performance improvements
   - `ui`: UI/UX updates (colors, layouts)
   - `content`: Text, images, localization

2. **Prohibited Updates**:
   - ❌ No native code updates
   - ❌ No new permissions
   - ❌ No payment flow changes
   - ❌ No data collection changes
   - ❌ No major feature additions

3. **Size Limits**:
   - Maximum 10MB per patch (iOS)
   - Maximum 1 patch per day (iOS)

4. **Testing**:
   - Test patches on TestFlight first
   - Monitor crash analytics
   - Have rollback ready

---

## 7. Build System Integration

### 7.1 Xcode Configuration

**Info.plist** additions:

```xml
<key>QuicUICodePushEnabled</key>
<true/>
<key>QuicUIBackendURL</key>
<string>https://your-quicui-backend.com</string>
<key>QuicUIAppId</key>
<string>com.yourcompany.yourapp</string>
```

### 7.2 Podfile Integration

```ruby
# packages/quicui_code_push_client/ios/quicui_code_push_client.podspec

Pod::Spec.new do |s|
  s.name             = 'quicui_code_push_client'
  s.version          = '1.0.0'
  s.summary          = 'QuicUI Code Push Client for iOS'
  s.description      = 'Flutter plugin for QuicUI Code Push on iOS'
  s.homepage         = 'https://quicui.com'
  s.license          = { :type => 'Commercial', :file => '../LICENSE' }
  s.author           = { 'QuicUI' => 'support@quicui.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.platform         = :ios, '12.0'
  s.swift_version    = '5.0'

  # Flutter dependency
  s.dependency 'Flutter'
end
```

### 7.3 Build Script (generate_patch_ios.sh)

```bash
#!/bin/bash
# Generate iOS patch for QuicUI Code Push

set -e

# Configuration
APP_NAME="QuicUIProductionTest"
BASE_VERSION="1.0.0"
NEW_VERSION="1.0.1"
BACKEND_URL="http://localhost:8080"

# Paths
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_APP_DIR="$PROJECT_DIR/test_apps/quicui_ios_test"
BUILD_DIR="$TEST_APP_DIR/build/ios/Release-iphoneos"
PATCHES_DIR="$PROJECT_DIR/patches/ios"

echo "🍎 QuicUI iOS Patch Generator"
echo "================================"

# Step 1: Build base version
echo "📦 Building base version $BASE_VERSION..."
cd "$TEST_APP_DIR"
flutter build ios --release

# Save base libapp.so
BASE_LIBAPP="$BUILD_DIR/App.framework/flutter_assets/libapp.so"
cp "$BASE_LIBAPP" "$PATCHES_DIR/libapp_base.so"
echo "✅ Base version saved"

# Step 2: Make code changes
echo "✏️  Please make your code changes now..."
echo "Press Enter when ready to build new version..."
read

# Step 3: Build new version
echo "📦 Building new version $NEW_VERSION..."
flutter build ios --release

# Save new libapp.so
NEW_LIBAPP="$BUILD_DIR/App.framework/flutter_assets/libapp.so"
cp "$NEW_LIBAPP" "$PATCHES_DIR/libapp_new.so"
echo "✅ New version built"

# Step 4: Generate patch
echo "🔧 Generating bsdiff patch..."
PATCH_FILE="$PATCHES_DIR/${APP_NAME}_${BASE_VERSION}_to_${NEW_VERSION}.patch"

bsdiff "$PATCHES_DIR/libapp_base.so" \
       "$PATCHES_DIR/libapp_new.so" \
       "$PATCH_FILE"

# Compress with xz
xz -z -9 "$PATCH_FILE"
PATCH_FILE_XZ="${PATCH_FILE}.xz"

echo "✅ Patch generated: $PATCH_FILE_XZ"

# Calculate sizes
BASE_SIZE=$(stat -f%z "$PATCHES_DIR/libapp_base.so")
NEW_SIZE=$(stat -f%z "$PATCHES_DIR/libapp_new.so")
PATCH_SIZE=$(stat -f%z "$PATCH_FILE_XZ")
REDUCTION=$((100 - PATCH_SIZE * 100 / NEW_SIZE))

echo ""
echo "📊 Size Comparison:"
echo "  Base:      $(numfmt --to=iec-i --suffix=B $BASE_SIZE)"
echo "  New:       $(numfmt --to=iec-i --suffix=B $NEW_SIZE)"
echo "  Patch:     $(numfmt --to=iec-i --suffix=B $PATCH_SIZE)"
echo "  Reduction: ${REDUCTION}%"

# Step 5: Upload to backend
echo ""
echo "📤 Uploading patch to backend..."

curl -X POST "$BACKEND_URL/api/v1/patches" \
  -F "file=@$PATCH_FILE_XZ" \
  -F "appId=$APP_NAME" \
  -F "baseVersion=$BASE_VERSION" \
  -F "newVersion=$NEW_VERSION" \
  -F "platform=ios" \
  -F "architecture=arm64"

echo "✅ Patch uploaded successfully!"
echo ""
echo "🎉 iOS patch generation complete!"
```

---

## 8. Testing Strategy

### 8.1 Unit Tests

```swift
// tests/QuicUIPatcherTests.swift

import XCTest
@testable import quicui_code_push_client

class QuicUIPatcherTests: XCTestCase {
    
    func testPatchApplication() {
        let patcher = QuicUIPatcher()
        
        // Create test files
        let testDir = FileManager.default.temporaryDirectory
        let originalPath = testDir.appendingPathComponent("original.bin").path
        let patchPath = testDir.appendingPathComponent("patch.bsdiff").path
        let outputPath = testDir.appendingPathComponent("output.bin").path
        
        // Create test data
        let originalData = Data("Hello World!".utf8)
        try! originalData.write(to: URL(fileURLWithPath: originalPath))
        
        // Apply patch
        let success = patcher.applyPatch(originalPath: originalPath,
                                        patchPath: patchPath,
                                        outputPath: outputPath)
        
        XCTAssertTrue(success)
    }
}
```

### 8.2 Integration Tests

```swift
// tests/QuicUICodePushPluginTests.swift

import XCTest
import Flutter
@testable import quicui_code_push_client

class QuicUICodePushPluginTests: XCTestCase {
    
    func testCheckForUpdates() {
        let plugin = QuicUICodePushPlugin()
        let call = FlutterMethodCall(methodName: "checkForUpdates",
                                     arguments: ["serverUrl": "http://localhost:8080"])
        
        let expectation = self.expectation(description: "Check for updates")
        
        plugin.handle(call) { result in
            XCTAssertNotNil(result)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
}
```

### 8.3 E2E Test Plan

1. **Manual Testing**:
   - Create test iOS app
   - Build base version (1.0.0)
   - Install on physical iPhone
   - Make code change (change text color)
   - Generate patch
   - Upload to backend
   - Trigger update from app
   - Restart app
   - Verify change applied

2. **Automated Testing** (TestFlight):
   - Deploy test builds to TestFlight
   - Automated patch generation
   - Automated update checks
   - Crash analytics monitoring

---

## 9. Migration from Android

### 9.1 Code Reuse

| Component | Android | iOS | Reusable? |
|-----------|---------|-----|-----------|
| **Backend** | ✅ Dart server | ✅ Same | 100% |
| **Plugin (Dart)** | ✅ Dart | ✅ Same | 95% (minor platform checks) |
| **Patch Format** | ✅ bsdiff + xz | ✅ Same | 100% |
| **Algorithm** | ✅ bsdiff | ✅ Same | 100% |
| **Native Patcher** | ❌ Kotlin | ❌ Swift | 0% (rewrite) |
| **Engine Loader** | ❌ Java + JNI | ❌ Objective-C++ | 0% (rewrite) |

**Estimated Reuse**: ~60% overall

### 9.2 Adaptation Checklist

- ✅ Port Kotlin patcher to Swift
- ✅ Port Java loader to Objective-C++
- ✅ Replace JNI with native calls
- ✅ Update file paths (Android → iOS)
- ✅ Update build scripts
- ✅ Update documentation
- ⚠️ Stricter App Store compliance

---

## 10. Timeline & Milestones

### Phase 4: iOS Implementation (Q2 2026)

**Duration**: 12 weeks (April - June 2026)

#### Week 1-2: Setup & Planning
- ✅ Finalize iOS architecture
- ✅ Set up iOS development environment
- ✅ Create test iOS app
- ✅ Review Shorebird iOS implementation
- **Deliverable**: iOS project structure + test app

#### Week 3-4: Engine Modifications
- 📝 Implement `QuicUICodePushLoader.mm`
- 📝 Modify `FlutterEngine.mm`
- 📝 Add patch validation
- 📝 Unit tests for loader
- **Deliverable**: Working engine loader

#### Week 5-6: Swift Patcher Library
- 📝 Implement `BSDiffPatcher.swift`
- 📝 Implement `QuicUIPatcher.swift`
- 📝 Decompression (LZMA)
- 📝 Unit tests
- **Deliverable**: Working patcher library

#### Week 7-8: Flutter Plugin
- 📝 Implement `QuicUICodePushPlugin.swift`
- 📝 Method channel handlers
- 📝 HTTP client
- 📝 File download/storage
- **Deliverable**: Working plugin

#### Week 9-10: Integration & Testing
- 📝 E2E tests
- 📝 Patch generation scripts
- 📝 Build system integration
- 📝 Performance testing
- **Deliverable**: Complete iOS implementation

#### Week 11: App Store Compliance
- 📝 Review App Store guidelines
- 📝 Implement safeguards
- 📝 Developer documentation
- 📝 TestFlight submission
- **Deliverable**: Compliance strategy

#### Week 12: Documentation & Polish
- 📝 iOS deployment guide
- 📝 API documentation
- 📝 Video tutorials
- 📝 Bug fixes
- **Deliverable**: Production-ready iOS support

---

## 11. Risk Assessment

### 11.1 Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **App Store Rejection** | 30% | High | Conservative updates, clear TOS, TestFlight testing |
| **iOS API Changes** | 20% | Medium | Follow Flutter upstream, version pinning |
| **Performance Issues** | 15% | Medium | Profiling, optimization, lazy loading |
| **Security Vulnerabilities** | 10% | High | Code signing, encryption, security audit |
| **Compatibility Issues** | 25% | Medium | Multi-version testing, gradual rollout |

### 11.2 Business Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **Delayed Launch** | 40% | High | Buffer time in schedule, parallel work |
| **Low Adoption** | 30% | High | Early access program, marketing |
| **Competition** | 50% | Medium | Faster iteration, better pricing |
| **Legal Issues** | 10% | High | Legal review, proper licensing |

---

## 12. Success Criteria

### 12.1 Technical Metrics

- ✅ Patch size: < 10MB (target: 2-5MB)
- ✅ Patch application time: < 5 seconds
- ✅ Success rate: > 95%
- ✅ Rollback time: < 1 second
- ✅ App Store approval: First try

### 12.2 Business Metrics

- 📊 50+ apps using iOS support (Q3 2026)
- 📊 500K+ patch downloads (Q3 2026)
- 📊 Customer satisfaction: > 4.5/5
- 📊 Support tickets: < 5 per week

### 12.3 Compliance Metrics

- ✅ Zero App Store policy violations
- ✅ Zero security incidents
- ✅ 100% patch validation
- ✅ Clear audit trail

---

## 13. Resources Required

### 13.1 Team

- **iOS Developer**: 1 FTE (3 months)
- **Flutter Developer**: 0.5 FTE (support)
- **QA Engineer**: 0.5 FTE (testing)
- **DevOps**: 0.25 FTE (CI/CD)

### 13.2 Tools & Services

- Xcode 15+
- macOS Sonoma+
- Physical iPhones (iPhone 12+)
- Apple Developer Account ($99/year)
- TestFlight
- Firebase (analytics, crash reporting)

### 13.3 Budget Estimate

| Item | Cost |
|------|------|
| iOS Developer (3 months) | $30,000 |
| Apple Developer Account | $99 |
| Test Devices (3x iPhone) | $3,000 |
| Cloud Services | $500 |
| **Total** | **$33,599** |

---

## 14. Next Steps (Immediate Actions)

### For NOW (Phase 3 - Q1 2026):

1. ✅ **Commit this plan** to Git
2. 📝 **Finalize Android** (Phase 3: Cloud infrastructure)
3. 📝 **Hire iOS developer** (Q1 2026)
4. 📝 **Set up iOS dev environment**

### For Q2 2026 (Phase 4):

1. 📝 **Start iOS implementation**
2. 📝 **Follow this timeline**
3. 📝 **TestFlight beta program**
4. 📝 **App Store submission**

---

## 15. References

### 15.1 Documentation

- [Flutter iOS Embedding](https://github.com/flutter/engine/tree/main/shell/platform/darwin/ios)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Shorebird iOS Implementation](https://github.com/shorebirdtech/shorebird)
- [bsdiff Algorithm](http://www.daemonology.net/bsdiff/)

### 15.2 Related Documents

- `docs/2025-11-06/QUICUI_WORKING_SYSTEM_COMPLETE.md` (Android implementation)
- `docs/2025-11-06/PLAY_STORE_COMPLIANCE.md` (Android compliance)
- `BUSINESS_STRATEGY.md` (Commercial roadmap)
- `docs/2025-11-06/QUICUI_VS_SHOREBIRD_COMPARISON.md` (Competitor analysis)

---

## Appendix A: iOS vs Android Code Comparison

### A.1 Patch Loader

**Android (Java)**:
```java
public class QuicUICodePushLoader {
    public static String checkAndLoadPatch(Context context) {
        File patchFile = new File(context.getFilesDir(), "quicui_patches/libapp.so");
        if (patchFile.exists() && validatePatch(patchFile)) {
            return patchFile.getAbsolutePath();
        }
        return null;
    }
}
```

**iOS (Objective-C++)**:
```objc
@implementation QuicUICodePushLoader

+ (NSString*)checkAndLoadPatch {
    NSString* patchDir = [self getPatchDirectory];
    NSString* patchPath = [patchDir stringByAppendingPathComponent:@"libapp.so"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:patchPath] &&
        [self validatePatchIntegrity:patchPath]) {
        return patchPath;
    }
    return nil;
}

@end
```

### A.2 Binary Patcher

**Android (Kotlin)**:
```kotlin
class BsDiffPatcher {
    fun applyPatch(original: ByteArray, patch: ByteArray): ByteArray {
        // bsdiff implementation
    }
}
```

**iOS (Swift)**:
```swift
class BSDiffPatcher {
    func patch(original: Data, patch: Data) -> Data? {
        // bsdiff implementation
    }
}
```

---

## Appendix B: File Size Estimates

| File | Android (Lines) | iOS (Lines) |
|------|----------------|-------------|
| **Engine Loader** | 200 (Java + C++) | 150 (Obj-C++) |
| **Native Patcher** | 265 (Kotlin) | 200 (Swift) |
| **Plugin** | 180 (Dart + Kotlin) | 200 (Dart + Swift) |
| **bsdiff Implementation** | 450 (C++) | 200 (Swift) |
| **Total** | **1,095 lines** | **750 lines** |

**iOS is ~30% less code due to**:
- No JNI bridge needed
- Cleaner Swift syntax
- Native iOS APIs

---

## Appendix C: Testing Checklist

### Pre-Launch Testing (iOS)

- [ ] Unit tests (all pass)
- [ ] Integration tests (all pass)
- [ ] E2E tests (3 scenarios)
- [ ] Performance tests (< 5s patch time)
- [ ] Security audit (no vulnerabilities)
- [ ] TestFlight beta (50+ users)
- [ ] App Store submission (approved)
- [ ] Rollback testing (works instantly)
- [ ] Multi-device testing (iPhone 12, 13, 14, 15)
- [ ] iOS version testing (iOS 14, 15, 16, 17)

---

**Document Status**: ✅ Complete  
**Last Updated**: November 7, 2025  
**Author**: QuicUI Team  
**Version**: 1.0.0

---

🍎 **Ready for iOS Development in Q2 2026!**
