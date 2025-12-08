// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "QuicUICodePushLoader.h"
#import <UIKit/UIKit.h>
#include "flutter/shell/common/quicui_patch_loader.h"

NS_ASSUME_NONNULL_BEGIN

@implementation QuicUICodePushLoader {
  flutter::QuicUIPatchLoader* _patchLoader;
  NSString* _cacheDirectory;
  NSString* _architecture;
}

- (instancetype)initWithCacheDirectory:(NSString*)cacheDir {
  self = [super init];
  if (self) {
    _cacheDirectory = cacheDir;
    _architecture = [self detectArchitecture];
    _patchLoader = new flutter::QuicUIPatchLoader();
    _patchLoader->SetCodeCacheDir([cacheDir UTF8String]);
    
    NSLog(@"[QuicUI] iOS Code Push Loader initialized");
    NSLog(@"[QuicUI] Cache directory: %@", cacheDir);
    NSLog(@"[QuicUI] Architecture: %@", _architecture);
  }
  return self;
}

- (void)dealloc {
  if (_patchLoader) {
    delete _patchLoader;
    _patchLoader = nullptr;
  }
}

/**
 * Detect iOS device architecture
 */
- (NSString*)detectArchitecture {
#if TARGET_CPU_ARM64
  return @"arm64";      // iPhone 5S and later (64-bit)
#elif TARGET_CPU_ARM
  return @"armv7";      // Older iPhones (32-bit, deprecated)
#elif TARGET_CPU_X86_64
  return @"x86_64";     // iOS Simulator on Intel Mac
#elif TARGET_CPU_ARM64 && TARGET_OS_SIMULATOR
  return @"arm64_sim";  // iOS Simulator on Apple Silicon
#else
  return @"unknown";
#endif
}

/**
 * Get path to patched AOT snapshot if available
 * 
 * @return Path to patched App binary, or nil if no valid patch
 */
- (nullable NSString*)getPatchedAOTPath {
  @try {
    NSLog(@"[QuicUI] Checking for patches via C++ loader...");
    
    // Call C++ patch loader
    std::string patchPath = _patchLoader->GetPatchedAOTPath([_architecture UTF8String]);
    
    if (!patchPath.empty()) {
      NSString* nsPath = [NSString stringWithUTF8String:patchPath.c_str()];
      
      // Verify file exists
      NSFileManager* fileManager = [NSFileManager defaultManager];
      if ([fileManager fileExistsAtPath:nsPath]) {
        NSLog(@"[QuicUI] ✅ Found valid patch at: %@", nsPath);
        
        // Get file size
        NSError* error = nil;
        NSDictionary* attributes = [fileManager attributesOfItemAtPath:nsPath error:&error];
        if (attributes) {
          unsigned long long fileSize = [attributes fileSize];
          NSLog(@"[QuicUI] Patch size: %llu bytes (%.2f MB)", 
                fileSize, fileSize / 1024.0 / 1024.0);
        }
        
        return nsPath;
      } else {
        NSLog(@"[QuicUI] ⚠️ C++ returned path but file doesn't exist: %@", nsPath);
        return nil;
      }
    } else {
      NSLog(@"[QuicUI] No patch found (C++ returned empty string)");
      return nil;
    }
  } @catch (NSException* exception) {
    NSLog(@"[QuicUI] ❌ Error getting patched AOT path: %@", exception.reason);
    return nil;
  }
}

/**
 * Clear any installed patches (rollback)
 * 
 * @return YES if patches cleared successfully, NO otherwise
 */
- (BOOL)clearPatch {
  @try {
    NSLog(@"[QuicUI] Clearing patches via C++...");
    bool success = _patchLoader->ClearInstalledPatch();
    
    if (success) {
      NSLog(@"[QuicUI] ✅ Patches cleared successfully");
    } else {
      NSLog(@"[QuicUI] ⚠️ Failed to clear patches");
    }
    
    return success ? YES : NO;
  } @catch (NSException* exception) {
    NSLog(@"[QuicUI] ❌ Error clearing patches: %@", exception.reason);
    return NO;
  }
}

/**
 * Get patch information for debugging
 * 
 * @return Dictionary with patch metadata, or nil if no patch
 */
- (nullable NSDictionary*)getPatchInfo {
  @try {
    std::string infoJSON = _patchLoader->GetPatchInfoJSON();
    
    if (!infoJSON.empty()) {
      NSString* jsonString = [NSString stringWithUTF8String:infoJSON.c_str()];
      NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
      
      NSError* error = nil;
      NSDictionary* info = [NSJSONSerialization JSONObjectWithData:jsonData 
                                                           options:0 
                                                             error:&error];
      
      if (error) {
        NSLog(@"[QuicUI] ⚠️ Failed to parse patch info JSON: %@", error.localizedDescription);
        return nil;
      }
      
      NSLog(@"[QuicUI] Patch info: %@", info);
      return info;
    }
    
    return nil;
  } @catch (NSException* exception) {
    NSLog(@"[QuicUI] ❌ Error getting patch info: %@", exception.reason);
    return nil;
  }
}

@end

NS_ASSUME_NONNULL_END
