// Patch for FlutterDartProject.mm
// This shows the modifications needed to add QuicUI code push support

// File: flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject.mm

// ==================== ADD TO IMPORTS ====================
#import "QuicUICodePushLoader.mm"  // Import QuicUI loader

// ==================== ADD TO @interface FlutterDartProject () ====================
@interface FlutterDartProject ()
// ... existing properties ...

// NEW: Add patch-related property
@property(nonatomic, strong, nullable) NSString* patchedAOTPath;

@end

// ==================== ADD NEW METHOD ====================

/**
 * Check for QuicUI code push patches
 * 
 * This method should be called before the engine starts to detect
 * if a patched AOT snapshot is available.
 */
- (void)checkForCodePushPatches {
  // Get iOS cache directory
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, 
                                                       NSUserDomainMask, 
                                                       YES);
  NSString* cacheDir = [paths firstObject];
  
  if (!cacheDir) {
    NSLog(@"[QuicUI] Failed to get cache directory, patches disabled");
    return;
  }
  
  // Append quicui_patches subdirectory (will be created by patch installer)
  NSString* quicuiCacheDir = cacheDir;
  NSLog(@"[QuicUI] QuicUI cache directory: %@", quicuiCacheDir);
  
  // Create QuicUI patch loader
  QuicUICodePushLoader* loader = [[QuicUICodePushLoader alloc] 
                                   initWithCacheDirectory:quicuiCacheDir];
  
  // Check for patched AOT
  NSString* patchedPath = [loader getPatchedAOTPath];
  
  if (patchedPath) {
    self.patchedAOTPath = patchedPath;
    NSLog(@"[QuicUI] ✅ Will use patched AOT from: %@", patchedPath);
    
    // Log patch info for debugging
    NSDictionary* patchInfo = [loader getPatchInfo];
    if (patchInfo) {
      NSLog(@"[QuicUI] Patch version: %@", patchInfo[@"version"]);
      NSLog(@"[QuicUI] Patch architecture: %@", patchInfo[@"architecture"]);
    }
  } else {
    NSLog(@"[QuicUI] No patch found, using original AOT from app bundle");
    self.patchedAOTPath = nil;
  }
}

// ==================== MODIFY EXISTING METHOD ====================

/**
 * Get the AOT library path
 * 
 * MODIFICATION: Return patched path if available, otherwise return original
 */
- (NSString*)aotLibraryPath {
  // QuicUI: Check for patched AOT first
  if (self.patchedAOTPath) {
    NSLog(@"[QuicUI] Using patched AOT library: %@", self.patchedAOTPath);
    return self.patchedAOTPath;
  }
  
  // Original logic: Get App framework from bundle
  NSString* bundlePath = [[NSBundle mainBundle] pathForResource:@"App" 
                                                         ofType:@"framework"];
  if (!bundlePath) {
    NSLog(@"[QuicUI] Warning: App.framework not found in bundle");
    return nil;
  }
  
  NSString* appBinaryPath = [bundlePath stringByAppendingPathComponent:@"App"];
  NSLog(@"[QuicUI] Using original AOT library: %@", appBinaryPath);
  
  return appBinaryPath;
}
