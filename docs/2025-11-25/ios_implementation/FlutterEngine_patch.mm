// Patch for FlutterEngine.mm
// This shows the modifications needed to trigger patch detection

// File: flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine.mm

// ==================== LOCATE METHOD: runWithEntrypoint: ====================

- (BOOL)runWithEntrypoint:(NSString*)entrypoint {
  return [self runWithEntrypoint:entrypoint libraryURI:nil];
}

- (BOOL)runWithEntrypoint:(NSString*)entrypoint libraryURI:(NSString*)uri {
  return [self runWithEntrypoint:entrypoint libraryURI:uri initialRoute:nil];
}

- (BOOL)runWithEntrypoint:(NSString*)entrypoint
               libraryURI:(NSString*)libraryURI
             initialRoute:(NSString*)initialRoute {
  if ([self createShell:entrypoint libraryURI:libraryURI initialRoute:initialRoute]) {
    [self launchEngine:entrypoint libraryURI:libraryURI];
  }
  
  return YES;
}

// ==================== LOCATE METHOD: createShell: ====================

- (BOOL)createShell:(NSString*)entrypoint
         libraryURI:(NSString*)libraryURI
       initialRoute:(NSString*)initialRoute {
  
  // ... existing validation code ...
  
  // QuicUI Code Push: Check for patches BEFORE creating shell
  NSLog(@"[QuicUI] Checking for code push patches...");
  [_dartProject checkForCodePushPatches];
  
  // ... rest of existing code to create FlutterProjectArgs ...
  
  flutter::Settings settings = [_dartProject settings];
  
  // QuicUI: The aotLibraryPath method in FlutterDartProject will now
  // return the patched path if available, or original if not.
  // No additional code needed here - it's handled in FlutterDartProject.
  
  // ... rest of existing shell creation code ...
  
  return YES;
}

// ==================== ALTERNATIVE: Modify launchEngine: ====================

/**
 * If modifications to createShell are complex, can also add check here.
 * This is called right before the engine starts.
 */
- (void)launchEngine:(NSString*)entrypoint
          libraryURI:(NSString*)libraryURI {
  
  // QuicUI Code Push: Check for patches before launching
  if (!_dartProject.patchedAOTPath) {
    NSLog(@"[QuicUI] No patch detected, checking one more time...");
    [_dartProject checkForCodePushPatches];
  }
  
  // ... existing engine launch code ...
}

// ==================== ADD DEBUG METHOD (Optional) ====================

/**
 * Debug method to manually trigger patch check and reload
 * Useful for testing without app restart
 */
- (void)quicuiCheckForPatchesAndReload {
  NSLog(@"[QuicUI] Manual patch check triggered");
  
  // Check for patches
  [_dartProject checkForCodePushPatches];
  
  if (_dartProject.patchedAOTPath) {
    NSLog(@"[QuicUI] Patch detected, restart app to apply");
    
    // Could trigger app restart here, or just log for now
    UIAlertController* alert = [UIAlertController 
      alertControllerWithTitle:@"Update Available"
      message:@"A new update has been installed. Please restart the app to apply."
      preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" 
                                             style:UIAlertActionStyleDefault 
                                           handler:nil]];
    
    // Show alert on root view controller
    UIWindow* keyWindow = [UIApplication sharedApplication].keyWindow;
    if (keyWindow) {
      [keyWindow.rootViewController presentViewController:alert 
                                                 animated:YES 
                                               completion:nil];
    }
  } else {
    NSLog(@"[QuicUI] No patch available");
  }
}
