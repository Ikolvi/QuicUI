# QuicUI Code Push - Complete Testing Plan

**Date:** November 2, 2025  
**Status:** Phase 1 (Binary Diffing) - ✅ COMPLETED

---

## Overview

This document outlines the complete testing plan for QuicUI Code Push functionality, covering:
1. ✅ **Building patches with quicui_compiler** - COMPLETED
2. Deploying backend server
3. Testing download → install → restart flow
4. iOS implementation

### ✅ Phase 1 Completion Status

**BsDiff Implementation:**
- ✅ Complete BsDiff algorithm implemented (480 lines)
- ✅ CLI commands added (diff and patch)
- ✅ Custom .quicui patch format with magic signature
- ✅ SHA256 hash validation
- ✅ Tested with 1MB binary files
- ✅ Achieved 94.89% compression (1MB → 52KB patch)
- ✅ Verified patch integrity (hashes match)

**Test Results:**
```
Old size:        1.00 MB
New size:        1.00 MB
Patch size:      52.35 KB
Compression:     94.89%
Operations:      15
✅ Files are identical after patching
```

---

## Phase 1: Build Patch with quicui_compiler

### Prerequisites

- [x] QuicUI Flutter SDK installed and verified
- [x] test_app_fresh built with version 1.0.0
- [x] quicui_compiler package available
- [x] BsDiff implementation complete and tested
- [ ] Two versions of the app (before and after code changes)

### Step 1.1: Build Baseline Version (v1.0.0)

```bash
cd /Users/admin/Documents/quicui2/test_apps/test_app_fresh

# Ensure using QuicUI SDK
export PATH="/Users/admin/Documents/quicui2/forks/flutter-official/bin:$PATH"

# Clean and build
flutter clean
flutter pub get
flutter build apk --release

# Save the baseline snapshot
cp build/app/intermediates/flutter/release/app.so \
   ~/baseline_v1.0.0_app.so
```

**Expected Output:**
```
✓ Built build/app/outputs/flutter-apk/app-release.apk (44.0MB)
```

### Step 1.2: Make Code Changes for v1.0.1

**Changes to make in lib/main.dart:**

1. Add a version indicator
2. Change UI text
3. Add new functionality

**Example changes:**
```dart
// Add at top of _MyHomePageState
final String appVersion = '1.0.1 (PATCHED)';

// In build method, add version display
Text(
  'Version: $appVersion',
  style: TextStyle(fontSize: 12, color: Colors.grey),
),

// Change existing text
Text(
  'Code Push Update Applied! 🎉',
  style: Theme.of(context).textTheme.headlineMedium,
),

// Add new feature indicator
Container(
  padding: EdgeInsets.all(16),
  margin: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.green.shade100,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    '✨ NEW: This feature was added via Code Push!',
    style: TextStyle(color: Colors.green.shade900),
  ),
),
```

### Step 1.3: Build Updated Version (v1.0.1)

```bash
# Update version in pubspec.yaml
sed -i '' 's/version: 1.0.0+1/version: 1.0.1+2/' pubspec.yaml

# Build new version
flutter clean
flutter pub get
flutter build apk --release

# Save the updated snapshot
cp build/app/intermediates/flutter/release/app.so \
   ~/updated_v1.0.1_app.so
```

### Step 1.4: Generate Patch with quicui_compiler

**Current Challenge:** The quicui_compiler needs to generate a binary diff between the two snapshots.

**Options:**

#### Option A: Use bsdiff (if available)
```bash
# Install bsdiff if not available
brew install bsdiff  # macOS
# or
sudo apt-get install bsdiff  # Linux

# Generate patch
bsdiff ~/baseline_v1.0.0_app.so \
       ~/updated_v1.0.1_app.so \
       ~/patch_1.0.1.patch

# Check patch size
ls -lh ~/patch_1.0.1.patch
```

#### Option B: Implement Simple Diff in quicui_compiler

We need to implement a binary diff tool. For testing purposes, we can:

**Quick Test Approach:**
```bash
# For initial testing, just copy the new snapshot as "patch"
cp ~/updated_v1.0.1_app.so ~/patch_1.0.1.so

# Calculate SHA256 hash
sha256sum ~/patch_1.0.1.so > ~/patch_1.0.1.so.sha256
```

**Note:** This is the full snapshot, not a diff. For production, we need proper binary diffing.

### Step 1.5: Create Patch Metadata

```bash
cat > ~/patch_metadata.json << 'EOF'
{
  "patchId": "patch-v1.0.1",
  "version": "1.0.1",
  "fromVersion": "1.0.0",
  "hash": "$(cat ~/patch_1.0.1.so.sha256 | awk '{print $1}')",
  "size": $(stat -f%z ~/patch_1.0.1.so),
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "architecture": "arm64-v8a",
  "minSdkVersion": "21",
  "description": "Added new features and updated UI"
}
EOF
```

---

## Phase 2: Deploy Backend Server

### Step 2.1: Prepare Backend

```bash
cd /Users/admin/Documents/quicui2/packages/quicui_backend

# Install dependencies
dart pub get

# Create patches directory
mkdir -p patches
cp ~/patch_1.0.1.so patches/
cp ~/patch_metadata.json patches/
```

### Step 2.2: Update Backend to Serve Patches

We need to enhance the backend server to actually serve patches. Let me check the current implementation:

**Required endpoints:**
1. `GET /api/v1/patches/check` - Check for updates
2. `GET /api/v1/patches/download/{patchId}` - Download patch file
3. `GET /api/v1/patches/{patchId}/metadata` - Get patch metadata

### Step 2.3: Start Backend Server

```bash
cd /Users/admin/Documents/quicui2/packages/quicui_backend

# Start server on port 8080
dart run bin/server.dart

# Should output:
# Server listening on port 8080
```

### Step 2.4: Test Backend Endpoints

```bash
# Health check
curl http://localhost:8080/health

# Check for patches
curl -X POST http://localhost:8080/api/v1/patches/check \
  -H "Content-Type: application/json" \
  -d '{
    "appId": "com.quicui.test_app_fresh",
    "currentVersion": "1.0.0",
    "platform": "android",
    "arch": "arm64-v8a"
  }'

# Expected response:
# {
#   "available": true,
#   "patchId": "patch-v1.0.1",
#   "version": "1.0.1",
#   "downloadUrl": "http://localhost:8080/api/v1/patches/download/patch-v1.0.1",
#   "hash": "sha256:...",
#   "size": 12345678
# }
```

---

## Phase 3: Test Download → Install → Restart Flow

### Step 3.1: Update App to Check for Updates

**Add to test_app_fresh/lib/main.dart:**

```dart
import 'package:quicui_code_push_client/quicui_code_push_client.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Add button to check for updates
ElevatedButton(
  onPressed: _checkForUpdates,
  child: Text('Check for Updates'),
),

// Add method
Future<void> _checkForUpdates() async {
  setState(() {
    _statusMessage = 'Checking for updates...';
  });

  try {
    // 1. Check backend for updates
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/api/v1/patches/check'), // Android emulator
      // Uri.parse('http://localhost:8080/api/v1/patches/check'), // iOS simulator
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'appId': 'com.quicui.test_app_fresh',
        'currentVersion': '1.0.0',
        'platform': 'android',
        'arch': 'arm64-v8a',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['available'] == true) {
        setState(() {
          _statusMessage = 'Update available: ${data['version']}';
        });
        
        // 2. Download and install
        final success = await QuicUICodePush.downloadAndInstall(
          patchUrl: data['downloadUrl'],
          version: data['version'],
          hash: data['hash'],
        );
        
        if (success) {
          setState(() {
            _statusMessage = 'Update installed! Restart app to apply.';
          });
          
          // 3. Show restart dialog
          _showRestartDialog();
        } else {
          setState(() {
            _statusMessage = 'Update failed. Please try again.';
          });
        }
      } else {
        setState(() {
          _statusMessage = 'No updates available';
        });
      }
    }
  } catch (e) {
    setState(() {
      _statusMessage = 'Error: $e';
    });
  }
}

void _showRestartDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Update Ready'),
      content: Text('Restart the app to apply the update?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Later'),
        ),
        ElevatedButton(
          onPressed: () {
            // Restart app
            exit(0);
          },
          child: Text('Restart Now'),
        ),
      ],
    ),
  );
}
```

### Step 3.2: Test on Physical Device

```bash
cd /Users/admin/Documents/quicui2/test_apps/test_app_fresh

# Build and install baseline v1.0.0
flutter clean
flutter pub get
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk

# Launch app
adb shell am start -n com.quicui.test_app_fresh/.MainActivity

# Watch logs
adb logcat | grep -i "quicui\|codepush\|flutter"
```

### Step 3.3: Test Update Flow

1. **Launch app** - Should show version 1.0.0
2. **Tap "Check for Updates"** - Should find patch v1.0.1
3. **Download starts** - Progress shown in UI
4. **Installation** - Patch copied to code_cache
5. **Restart prompt** - User taps "Restart Now"
6. **App restarts** - Should load with v1.0.1 changes

### Step 3.4: Verify Patch Applied

```bash
# Check patch file exists
adb shell run-as com.quicui.test_app_fresh ls -la code_cache/quicui_patches/

# Should show:
# libapp_arm64-v8a.so
# patch_metadata.json

# Check metadata
adb shell run-as com.quicui.test_app_fresh cat code_cache/quicui_patches/patch_metadata.json

# Launch app and verify UI changes
adb shell am start -n com.quicui.test_app_fresh/.MainActivity

# Check logs
adb logcat | grep -i "version\|patch"
```

### Step 3.5: Test Rollback

```bash
# In app, add rollback button or use platform channel
await QuicUICodePush.clearPatch();

# Or via adb
adb shell run-as com.quicui.test_app_fresh rm -rf code_cache/quicui_patches/

# Restart app - should revert to v1.0.0
```

---

## Phase 4: iOS Implementation

### Current Status
- ✅ Android implementation complete
- ❌ iOS implementation not started
- ❌ Swift equivalent of QuicUICodePushLoader needed
- ❌ iOS FlutterEngine modifications needed

### Step 4.1: Create iOS QuicUICodePushLoader

**File:** `packages/quicui_code_push_client/ios/Classes/QuicUICodePushLoader.swift`

```swift
import Foundation

public class QuicUICodePushLoader {
    
    private static let patchDir = "quicui_patches"
    
    /// Get path to patched AOT snapshot if it exists
    public static func getPatchedAOTPath(arch: String) -> String? {
        guard let codeCache = getCodeCacheDirectory() else {
            return nil
        }
        
        let patchDirectory = codeCache.appendingPathComponent(patchDir)
        let patchFile = patchDirectory.appendingPathComponent("App.framework")
        
        if FileManager.default.fileExists(atPath: patchFile.path) {
            if validatePatch(patchFile: patchFile) {
                return patchFile.path
            }
        }
        
        return nil
    }
    
    /// Check if patch exists
    public static func hasPatch() -> Bool {
        guard let codeCache = getCodeCacheDirectory() else {
            return false
        }
        
        let patchDirectory = codeCache.appendingPathComponent(patchDir)
        let patchFile = patchDirectory.appendingPathComponent("App.framework")
        
        return FileManager.default.fileExists(atPath: patchFile.path)
    }
    
    /// Clear installed patch (rollback)
    public static func clearPatch() -> Bool {
        guard let codeCache = getCodeCacheDirectory() else {
            return false
        }
        
        let patchDirectory = codeCache.appendingPathComponent(patchDir)
        
        do {
            if FileManager.default.fileExists(atPath: patchDirectory.path) {
                try FileManager.default.removeItem(at: patchDirectory)
            }
            return true
        } catch {
            print("[QuicUI] Error clearing patch: \\(error)")
            return false
        }
    }
    
    /// Install patch from temporary location
    public static func installPatch(
        patchPath: String,
        version: String,
        hash: String
    ) -> Bool {
        guard let codeCache = getCodeCacheDirectory() else {
            return false
        }
        
        let patchDirectory = codeCache.appendingPathComponent(patchDir)
        
        // Create patch directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(
                at: patchDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            print("[QuicUI] Error creating patch directory: \\(error)")
            return false
        }
        
        // Copy patch file
        let destFile = patchDirectory.appendingPathComponent("App.framework")
        let sourceFile = URL(fileURLWithPath: patchPath)
        
        do {
            if FileManager.default.fileExists(atPath: destFile.path) {
                try FileManager.default.removeItem(at: destFile)
            }
            try FileManager.default.copyItem(at: sourceFile, to: destFile)
        } catch {
            print("[QuicUI] Error copying patch: \\(error)")
            return false
        }
        
        // Save metadata
        let metadata: [String: Any] = [
            "version": version,
            "hash": hash,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        let metadataFile = patchDirectory.appendingPathComponent("patch_metadata.json")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: metadata)
            try jsonData.write(to: metadataFile)
        } catch {
            print("[QuicUI] Error saving metadata: \\(error)")
            return false
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    private static func getCodeCacheDirectory() -> URL? {
        guard let cacheDir = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }
        
        return cacheDir
    }
    
    private static func validatePatch(patchFile: URL) -> Bool {
        guard let metadataFile = patchFile.deletingLastPathComponent()
            .appendingPathComponent("patch_metadata.json") as URL? else {
            return false
        }
        
        do {
            let metadataData = try Data(contentsOf: metadataFile)
            let metadata = try JSONSerialization.jsonObject(with: metadataData) as? [String: Any]
            
            guard let expectedHash = metadata?["hash"] as? String else {
                return false
            }
            
            // Calculate actual hash
            let patchData = try Data(contentsOf: patchFile)
            let actualHash = sha256(data: patchData)
            
            return actualHash == expectedHash
            
        } catch {
            print("[QuicUI] Error validating patch: \\(error)")
            return false
        }
    }
    
    private static func sha256(data: Data) -> String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
```

### Step 4.2: Update iOS Plugin

**File:** `packages/quicui_code_push_client/ios/Classes/QuicuiCodePushClientPlugin.swift`

```swift
import Flutter
import UIKit

public class QuicuiCodePushClientPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
        name: "dev.quicui.code_push",
        binaryMessenger: registrar.messenger()
    )
    let instance = QuicuiCodePushClientPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "installPatch":
        handleInstallPatch(call, result: result)
    case "hasPatch":
        handleHasPatch(result: result)
    case "clearPatch":
        handleClearPatch(result: result)
    default:
        result(FlutterMethodNotImplemented)
    }
  }
    
  private func handleInstallPatch(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      guard let args = call.arguments as? [String: Any],
            let patchPath = args["patchPath"] as? String,
            let version = args["version"] as? String,
            let hash = args["hash"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
          return
      }
      
      let success = QuicUICodePushLoader.installPatch(
          patchPath: patchPath,
          version: version,
          hash: hash
      )
      
      result(success)
  }
  
  private func handleHasPatch(result: @escaping FlutterResult) {
      let hasPatch = QuicUICodePushLoader.hasPatch()
      result(hasPatch)
  }
  
  private func handleClearPatch(result: @escaping FlutterResult) {
      let cleared = QuicUICodePushLoader.clearPatch()
      result(cleared)
  }
}
```

### Step 4.3: Modify iOS Flutter Engine

**This requires modifying the QuicUI Flutter fork's iOS engine code.**

**File to create:** `forks/flutter-official/shell/platform/darwin/ios/framework/Source/QuicUICodePushLoader.h`

```objective-c
#ifndef QUICUI_CODE_PUSH_LOADER_H_
#define QUICUI_CODE_PUSH_LOADER_H_

#import <Foundation/Foundation.h>

@interface QuicUICodePushLoader : NSObject

+ (NSString* _Nullable)getPatchedAOTPathForArchitecture:(NSString* _Nonnull)arch;
+ (BOOL)hasPatch;
+ (BOOL)clearPatch;

@end

#endif  // QUICUI_CODE_PUSH_LOADER_H_
```

### Step 4.4: Modify FlutterEngine (iOS)

**File to modify:** `forks/flutter-official/shell/platform/darwin/ios/framework/Source/FlutterEngine.mm`

Add check for patched AOT at startup (similar to Android).

### Step 4.5: Test on iOS Device

**Prerequisites:**
- iOS device connected
- Xcode installed
- Apple Developer account configured

```bash
cd /Users/admin/Documents/quicui2/test_apps/test_app_fresh

# Build for iOS
flutter build ios --release

# Open in Xcode
open ios/Runner.xcworkspace

# Deploy to device via Xcode
# Test update flow (same as Android)
```

---

## Testing Checklist

### Android
- [ ] Build baseline v1.0.0 APK
- [ ] Install and verify SDK detection works
- [ ] Build updated v1.0.1 APK
- [ ] Generate patch file
- [ ] Start backend server
- [ ] Test check for updates
- [ ] Test download patch
- [ ] Test install patch
- [ ] Test app restart with patch
- [ ] Verify UI changes applied
- [ ] Test rollback to original
- [ ] Test hash validation failure

### iOS
- [ ] Port QuicUICodePushLoader to Swift
- [ ] Update iOS plugin
- [ ] Modify iOS FlutterEngine
- [ ] Build iOS app
- [ ] Test on iOS device
- [ ] Verify patch loading works
- [ ] Test complete update flow

---

## Known Limitations

1. **Binary Diff Not Implemented**
   - Currently using full snapshot as "patch"
   - Need to implement bsdiff/bspatch or similar
   - Patch sizes will be large without proper diffing

2. **Backend Not Production-Ready**
   - Simple in-memory implementation
   - No database persistence
   - No authentication/authorization
   - No CDN for patch distribution

3. **iOS Engine Modification Required**
   - Need to modify QuicUI Flutter fork for iOS
   - Requires rebuilding Flutter engine
   - Need to test AOT loading on iOS

4. **Network Configuration**
   - Android emulator: Use 10.0.2.2 for localhost
   - Physical device: Need local network IP or deployed server
   - iOS simulator: Use localhost

---

## Next Steps

### Immediate Actions

1. **Implement Binary Diffing**
   - Research bsdiff/bspatch integration
   - Or implement custom diff algorithm
   - Add to quicui_compiler

2. **Enhance Backend**
   - Add file storage
   - Implement patch serving
   - Add proper error handling
   - Add logging

3. **Complete Android Testing**
   - Build both versions
   - Generate patch
   - Test full update flow
   - Document results

4. **Start iOS Implementation**
   - Create Swift loader
   - Modify iOS engine
   - Test on iOS device

### Future Enhancements

- Implement incremental updates
- Add patch compression
- Implement signature verification
- Add analytics tracking
- Create web dashboard
- Add automated testing
- Implement rollback detection

---

**Status:** Plan created, ready to execute phase by phase.
