# QuicUI Code Push - Complete Architecture

**Last Updated:** November 1, 2025

## Executive Summary

QuicUI Code Push enables Flutter apps to download and apply code updates without going through app store review processes. This is achieved by:

1. **Modifying the Flutter SDK** to support loading patched AOT snapshots
2. **Creating a plugin** that communicates with the modified engine
3. **Building a backend** to serve and manage code patches
4. **Implementing SDK detection** to ensure apps are built with the correct Flutter fork

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Flutter SDK Modifications](#flutter-sdk-modifications)
3. [Plugin Architecture](#plugin-architecture)
4. [SDK Detection Mechanism](#sdk-detection-mechanism)
5. [Runtime Flow](#runtime-flow)
6. [File Structure](#file-structure)
7. [Build & Distribution](#build--distribution)
8. [Migration Guide](#migration-guide)

---

## System Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter Application                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Dart Code (User Application)                   │ │
│  │  - Uses QuicUICodePush.downloadAndInstall()                │ │
│  │  - Checks BuildSDKInfo.isQuicUI at startup                 │ │
│  └────────────────┬───────────────────────────────────────────┘ │
│                   │ Platform Channel: dev.quicui.code_push      │
│  ┌────────────────▼───────────────────────────────────────────┐ │
│  │          Plugin Layer (Kotlin/Swift)                        │ │
│  │  - CodePushMethodHandler.kt                                │ │
│  │  - QuicUICodePushLoader.java                               │ │
│  │  - File system operations in code_cache/                   │ │
│  └────────────────┬───────────────────────────────────────────┘ │
└───────────────────┼─────────────────────────────────────────────┘
                    │ JNI / Native Interface
┌───────────────────▼─────────────────────────────────────────────┐
│              Flutter Engine (Modified)                           │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  FlutterLoader.java (Modified)                             │ │
│  │  - checkForQuicUIPatch() called at startup                 │ │
│  │  - Checks for patched snapshot in code_cache/              │ │
│  │  - Sets --aot-shared-library-name if patch exists          │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  codepush_loader.h/cc (New C++ Code)                       │ │
│  │  - Validates patch integrity                                │ │
│  │  - Loads AOT snapshot from custom path                     │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                    │ Network / File System
┌───────────────────▼─────────────────────────────────────────────┐
│                    Backend Server (Dart)                         │
│  - Serves patches via REST API                                  │
│  - Validates app version compatibility                          │
│  - Manages patch rollout & rollback                             │
└─────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Language |
|-----------|---------------|----------|
| **Flutter SDK Fork** | Load patched AOT snapshots at app startup | C++, Java |
| **Code Push Plugin** | Download patches, validate, install to code_cache | Dart, Kotlin |
| **SDK Detection** | Identify QuicUI fork at runtime | Dart |
| **Backend Server** | Serve patches, manage versions, analytics | Dart (Shelf) |
| **User App** | Request updates, restart with patch | Dart (Flutter) |

---

## Flutter SDK Modifications

### Overview

The QuicUI Flutter fork is based on official Flutter with minimal, surgical changes to support code push functionality. All modifications are contained in the `quicui-v1.0.0-engine` git tag.

### Modified Files

#### 1. **packages/flutter/lib/src/services/flutter_version.dart**

**Purpose:** Enable runtime SDK detection

**Changes:**
```dart
// BEFORE (Standard Flutter):
static const String? version = bool.hasEnvironment('FLUTTER_VERSION')
    ? String.fromEnvironment('FLUTTER_VERSION')
    : null;

// AFTER (QuicUI Fork):
static const String? version = bool.hasEnvironment('FLUTTER_VERSION')
    ? '${String.fromEnvironment('FLUTTER_VERSION')} • quicui'
    : null;

// Added constants:
static const String? quicuiMarker = 'quicui';
static const bool isQuicUIFork = true;
```

**Why this matters:**
- Apps can detect the fork by checking: `FlutterVersion.version.contains('quicui')`
- No compilation errors with standard Flutter SDK
- Enables graceful degradation (show warning if built with wrong SDK)

**Example version strings:**
- QuicUI Fork: `"3.27.0 • quicui"`
- Standard Flutter: `"3.27.0"`

#### 2. **engine/src/flutter/shell/platform/android/.../FlutterLoader.java**

**Purpose:** Check for patches at app startup

**Changes:**
```java
import io.flutter.embedding.engine.loader.QuicUICodePushLoader;

private void checkForQuicUIPatch() {
  if (shellArgs.containsKey(FlutterLoader.AOT_SHARED_LIBRARY_NAME)) {
    return; // Already set
  }
  
  String arch = android.os.Build.SUPPORTED_ABIS[0];
  String patchedPath = QuicUICodePushLoader.getPatchedAOTPath(
    applicationContext, 
    arch
  );
  
  if (patchedPath != null) {
    shellArgs.put(FlutterLoader.AOT_SHARED_LIBRARY_NAME, patchedPath);
  }
}

// Called during initialization:
ensureInitializationCompleteAsync(...) {
  // ... existing code ...
  checkForQuicUIPatch();  // ← NEW
  // ... existing code ...
}
```

**Flow:**
1. App starts
2. `FlutterLoader` initialization begins
3. `checkForQuicUIPatch()` called
4. If patch exists in `code_cache/quicui_patches/`, use it
5. Otherwise, use default snapshot from APK

#### 3. **engine/src/flutter/shell/common/codepush_loader.h/cc** (NEW FILES)

**Purpose:** C++ engine support for loading custom AOT snapshots

**Key functions:**
```cpp
// codepush_loader.h
namespace flutter {
namespace codepush {

bool LoadPatchedSnapshot(const std::string& patch_path);
bool ValidatePatchIntegrity(const std::string& patch_path);

}  // namespace codepush
}  // namespace flutter
```

**Responsibilities:**
- Validate patch file integrity
- Load AOT snapshot from custom path
- Handle errors gracefully (fallback to original)

#### 4. **engine/src/flutter/shell/platform/android/.../QuicUICodePushLoader.java** (NEW FILE)

**Purpose:** Android platform bridge for patch management

**Key methods:**
```java
public class QuicUICodePushLoader {
  private static final String PATCH_DIR = "quicui_patches";
  
  // Get path to patched snapshot if it exists
  public static String getPatchedAOTPath(Context context, String arch) {
    File patchDir = new File(context.getCodeCacheDir(), PATCH_DIR);
    File patchFile = new File(patchDir, "libapp_" + arch + ".so");
    
    if (patchFile.exists() && validatePatch(patchFile)) {
      return patchFile.getAbsolutePath();
    }
    return null;
  }
  
  // Check if patch exists
  public static boolean hasPatch(Context context) { ... }
  
  // Clear patch (rollback)
  public static boolean clearPatch(Context context) { ... }
  
  // Validate patch integrity
  private static boolean validatePatch(File patchFile) {
    // Check SHA256 hash from metadata.json
  }
}
```

### New Files Added

#### 5. **packages/flutter/lib/src/quicui_sdk_marker.dart** (NEW FILE)

```dart
// QuicUI SDK marker file
// This file's presence indicates a QuicUI fork
const String quicuiFlutterVersion = '3.38.0-1.0.pre-350';
const bool isQuicUIFork = true;
```

#### 6. **.quicui_marker** (NEW FILE - root of SDK)

```
quicui-fork-v1.0.0
```

Simple file marker for shell scripts and tools to detect the fork.

### Git Tag Structure

```bash
# Single tag contains ALL modifications:
git checkout quicui-v1.0.0-engine

# Includes:
# - Engine C++ files (codepush_loader.h/cc)
# - Android platform files (QuicUICodePushLoader.java, FlutterLoader.java)
# - SDK version detection (flutter_version.dart, quicui_sdk_marker.dart)
# - Marker file (.quicui_marker)
```

**Critical:** When cherry-picking to new Flutter versions, use the ENTIRE tag to get both engine patches AND version detection.

---

## Plugin Architecture

### Code Push Plugin Structure

```
packages/quicui_code_push_client/
├── lib/
│   ├── quicui_code_push_client.dart         # Public API
│   ├── src/
│   │   ├── quicui_code_push.dart            # Main implementation
│   │   ├── services/
│   │   │   └── method_channel.dart           # Platform channel
│   │   ├── constants/
│   │   │   └── build_sdk_info.dart           # SDK detection
│   │   └── models/
│   │       └── patch_info.dart               # Patch metadata
├── android/
│   ├── src/main/kotlin/com/quicui/codepush/
│   │   ├── QuicuiCodePushClientPlugin.kt    # Plugin entry point
│   │   └── CodePushMethodHandler.kt          # Method channel handler
│   └── src/main/AndroidManifest.xml
└── ios/
    └── Classes/
        └── QuicuiCodePushClientPlugin.swift  # iOS implementation
```

### Key Classes

#### 1. **BuildSDKInfo** (Dart - SDK Detection)

**File:** `lib/src/constants/build_sdk_info.dart`

```dart
class BuildSDKInfo {
  /// Check if running on QuicUI fork
  static bool get isQuicUI {
    final version = flutterVersion ?? '';
    return version.contains('quicui');
  }
  
  /// Get Flutter version from Platform
  static String? get flutterVersion {
    try {
      return FlutterVersion.version;
    } catch (e) {
      return null;
    }
  }
  
  /// Get detailed SDK info for debugging
  static String getDetailedInfo() {
    return '''
SDK Detection Info:
  Type: ${isQuicUI ? 'QUICUI' : 'FLUTTER'}
  Is QuicUI Fork: $isQuicUI
  Flutter Version: ${flutterVersion ?? 'unknown'}
  Dart Version: ${dartVersion ?? 'unknown'}
  Channel: ${channel ?? 'unknown'}
''';
  }
}
```

**Usage in apps:**
```dart
void main() {
  if (!BuildSDKInfo.isQuicUI) {
    print('⚠️ Warning: Built with standard Flutter');
    print('Code Push will not work');
  }
  runApp(MyApp());
}
```

#### 2. **QuicUICodePush** (Dart - Main API)

**File:** `lib/src/quicui_code_push.dart`

```dart
class QuicUICodePush {
  /// Download and install a patch
  static Future<bool> downloadAndInstall({
    required String patchUrl,
    required String version,
    required String hash,
  }) async {
    // 1. Download patch file
    final tempDir = await getTemporaryDirectory();
    final patchFile = File('${tempDir.path}/quicui_patch_$version.so');
    await _downloadPatch(patchUrl, patchFile);
    
    // 2. Validate hash
    final actualHash = await _calculateHash(patchFile);
    if (actualHash != hash) {
      throw Exception('Hash mismatch');
    }
    
    // 3. Install via platform channel
    final installed = await CodePushMethodChannel.installPatch(
      patchFile.path,
      version,
      hash,
    );
    
    return installed;
  }
  
  /// Check if patch is installed
  static Future<bool> hasPatch() async {
    return await CodePushMethodChannel.hasPatch();
  }
  
  /// Remove installed patch
  static Future<bool> clearPatch() async {
    return await CodePushMethodChannel.clearPatch();
  }
}
```

#### 3. **CodePushMethodChannel** (Dart - Platform Bridge)

**File:** `lib/src/services/method_channel.dart`

```dart
class CodePushMethodChannel {
  static const _channel = MethodChannel('dev.quicui.code_push');
  
  static Future<bool> installPatch(
    String patchPath,
    String version,
    String hash,
  ) async {
    try {
      final result = await _channel.invokeMethod('installPatch', {
        'patchPath': patchPath,
        'version': version,
        'hash': hash,
      });
      return result == true;
    } catch (e) {
      print('[QuicUI] Install patch error: $e');
      return false;
    }
  }
  
  static Future<bool> hasPatch() async {
    try {
      final result = await _channel.invokeMethod('hasPatch');
      return result == true;
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> clearPatch() async {
    try {
      final result = await _channel.invokeMethod('clearPatch');
      return result == true;
    } catch (e) {
      return false;
    }
  }
}
```

#### 4. **CodePushMethodHandler** (Kotlin - Android Implementation)

**File:** `android/src/main/kotlin/com/quicui/codepush/CodePushMethodHandler.kt`

```kotlin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.loader.QuicUICodePushLoader

class CodePushMethodHandler(private val context: Context) {
  
  fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "installPatch" -> installPatch(call, result)
      "hasPatch" -> hasPatch(result)
      "clearPatch" -> clearPatch(result)
      else -> result.notImplemented()
    }
  }
  
  private fun installPatch(call: MethodCall, result: MethodChannel.Result) {
    val patchPath = call.argument<String>("patchPath")
    val version = call.argument<String>("version")
    val hash = call.argument<String>("hash")
    
    // 1. Get code cache directory
    val codeCache = context.codeCacheDir
    val patchDir = File(codeCache, "quicui_patches")
    patchDir.mkdirs()
    
    // 2. Copy patch file
    val arch = Build.SUPPORTED_ABIS[0]
    val destFile = File(patchDir, "libapp_${arch}.so")
    File(patchPath).copyTo(destFile, overwrite = true)
    
    // 3. Save metadata
    val metadata = JSONObject().apply {
      put("version", version)
      put("hash", hash)
      put("timestamp", System.currentTimeMillis())
    }
    File(patchDir, "patch_metadata.json").writeText(metadata.toString())
    
    result.success(true)
  }
  
  private fun hasPatch(result: MethodChannel.Result) {
    val hasPatch = QuicUICodePushLoader.hasPatch(context)
    result.success(hasPatch)
  }
  
  private fun clearPatch(result: MethodChannel.Result) {
    val cleared = QuicUICodePushLoader.clearPatch(context)
    result.success(cleared)
  }
}
```

**Key fix:** Added `import io.flutter.plugin.common.MethodCall` - this was missing and caused 30+ compilation errors!

---

## SDK Detection Mechanism

### Why SDK Detection is Critical

**Problem:** Apps built with standard Flutter SDK cannot use code push (engine doesn't support it).

**Solution:** Detect SDK at runtime and show appropriate warnings.

### Detection Flow

```
App Startup
    ↓
Check FlutterVersion.version
    ↓
version.contains('quicui')?
    ↓
Yes → QuicUI SDK        No → Standard Flutter
    ↓                       ↓
Enable code push        Show warning
Show ✅ icon            Show ⚠️ icon
"Code Push Ready"       "QuicUI SDK Required"
```

### Implementation Approaches (Tried & Rejected)

#### ❌ Approach 1: Compile-time constant
```dart
// Tried:
if (FlutterVersion.isQuicUIFork) { ... }

// Problem: Causes compilation error with standard Flutter SDK
// Error: "Undefined name 'isQuicUIFork'"
```

#### ❌ Approach 2: Path-based detection
```dart
// Tried:
String sdkPath = Platform.environment['FLUTTER_ROOT'];
if (sdkPath?.contains('quicui')) { ... }

// Problem: Unreliable, users can rename directories
```

#### ❌ Approach 3: Dart-define flags
```bash
flutter build apk --dart-define=IS_QUICUI=true
```
```dart
const isQuicUI = bool.fromEnvironment('IS_QUICUI');
```
**Problem:** Requires manual configuration, easy to forget

#### ✅ Approach 4: Version string check (CHOSEN)
```dart
static bool get isQuicUI {
  final version = flutterVersion ?? '';
  return version.contains('quicui');
}
```

**Why this works:**
- ✅ QuicUI fork appends `• quicui` to version string
- ✅ Standard Flutter doesn't have this marker
- ✅ No compilation errors with either SDK
- ✅ Automatic, no manual configuration
- ✅ Works at both edit time and runtime

### Version String Examples

```dart
// QuicUI Fork:
FlutterVersion.version = "3.27.0 • quicui"
BuildSDKInfo.isQuicUI = true

// Standard Flutter:
FlutterVersion.version = "3.27.0"
BuildSDKInfo.isQuicUI = false
```

### User Experience

**Built with QuicUI SDK:**
```
┌─────────────────────────────────┐
│  ✅ QuicUI Flutter SDK          │
│  Code Push Ready!               │
│  Version: 3.27.0 • quicui       │
│  [Check for Updates]            │
└─────────────────────────────────┘
```

**Built with Standard SDK:**
```
┌─────────────────────────────────┐
│  ⚠️ Standard Flutter SDK         │
│  QuicUI SDK Required            │
│  Code push not available        │
│  Please rebuild with QuicUI SDK │
└─────────────────────────────────┘
```

---

## Runtime Flow

### Complete Update Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. APP STARTUP (First Launch)                                   │
└─────────────────────────────────────────────────────────────────┘
App launches
    ↓
FlutterLoader.checkForQuicUIPatch() called
    ↓
No patch in code_cache/quicui_patches/
    ↓
Load default snapshot from APK
    ↓
App runs normally (version 1.0.0)

┌─────────────────────────────────────────────────────────────────┐
│ 2. CHECK FOR UPDATES (User Action)                              │
└─────────────────────────────────────────────────────────────────┘
User taps "Check for Updates"
    ↓
App calls: QuicUICodePush.checkForUpdate(
  serverUrl: 'https://api.example.com',
  appId: 'com.example.app',
  currentVersion: '1.0.0'
)
    ↓
Backend responds:
{
  "available": true,
  "patchVersion": "1.0.1",
  "downloadUrl": "https://cdn.../patch_1.0.1.so",
  "hash": "sha256:abc123...",
  "size": 2048576
}

┌─────────────────────────────────────────────────────────────────┐
│ 3. DOWNLOAD PATCH                                                │
└─────────────────────────────────────────────────────────────────┘
QuicUICodePush.downloadAndInstall() called
    ↓
Download patch to temporary directory
/data/data/com.example.app/cache/quicui_patch_1.0.1.so
    ↓
Calculate SHA256 hash
    ↓
Compare with expected hash
    ↓
✓ Hash matches

┌─────────────────────────────────────────────────────────────────┐
│ 4. INSTALL PATCH (Platform Channel)                             │
└─────────────────────────────────────────────────────────────────┘
Call platform channel: installPatch(
  patchPath: '/data/.../quicui_patch_1.0.1.so',
  version: '1.0.1',
  hash: 'sha256:abc123...'
)
    ↓
Kotlin code receives call
    ↓
Copy to code cache:
FROM: /data/data/com.example.app/cache/quicui_patch_1.0.1.so
TO:   /data/data/com.example.app/code_cache/quicui_patches/libapp_arm64-v8a.so
    ↓
Write metadata:
/data/data/com.example.app/code_cache/quicui_patches/patch_metadata.json
{
  "version": "1.0.1",
  "hash": "sha256:abc123...",
  "timestamp": 1730476800000
}
    ↓
Return success to Dart

┌─────────────────────────────────────────────────────────────────┐
│ 5. RESTART APP                                                   │
└─────────────────────────────────────────────────────────────────┘
Show dialog: "Update installed. Restart app?"
    ↓
User taps "Restart"
    ↓
Dart calls: SystemNavigator.pop()
OR         exit(0)
    ↓
App process terminates

┌─────────────────────────────────────────────────────────────────┐
│ 6. APP STARTUP (After Update)                                   │
└─────────────────────────────────────────────────────────────────┘
User launches app again
    ↓
FlutterLoader.checkForQuicUIPatch() called
    ↓
Finds: /data/.../code_cache/quicui_patches/libapp_arm64-v8a.so
    ↓
Validates hash from metadata.json
    ↓
✓ Hash valid
    ↓
Sets engine flag:
shellArgs.put(
  FlutterLoader.AOT_SHARED_LIBRARY_NAME,
  "/data/.../code_cache/quicui_patches/libapp_arm64-v8a.so"
)
    ↓
Flutter engine loads PATCHED snapshot instead of default
    ↓
App runs with new code (version 1.0.1) 🎉

┌─────────────────────────────────────────────────────────────────┐
│ 7. ROLLBACK (If Issues Occur)                                   │
└─────────────────────────────────────────────────────────────────┘
If app crashes or user reports issues:
    ↓
Call: QuicUICodePush.clearPatch()
    ↓
Platform channel removes patch:
- Delete libapp_arm64-v8a.so
- Delete patch_metadata.json
    ↓
Restart app
    ↓
Loads original snapshot from APK
    ↓
Back to version 1.0.0 ✓
```

### File System Layout

```
/data/data/com.example.app/
├── app_flutter/                          # Original APK files
│   └── libapp.so                         # Original AOT snapshot
├── code_cache/                           # Code Push directory
│   └── quicui_patches/
│       ├── libapp_arm64-v8a.so          # Patched snapshot
│       └── patch_metadata.json          # Version, hash, timestamp
└── cache/                                # Temporary downloads
    └── quicui_patch_1.0.1.so           # Downloaded patch (temp)
```

### Error Handling & Fallback

**Hash validation fails:**
```
Download patch → Verify hash → ❌ Mismatch
    ↓
Delete temp file
    ↓
Show error to user
    ↓
DO NOT install
```

**Patch is corrupt:**
```
App startup → checkForQuicUIPatch()
    ↓
Find patch file
    ↓
Read metadata.json
    ↓
Calculate actual hash
    ↓
❌ Hash doesn't match
    ↓
Delete corrupt patch
    ↓
Load original snapshot from APK
    ↓
App runs normally (automatic rollback)
```

**Platform channel error:**
```
Dart: installPatch() called
    ↓
Platform channel error
    ↓
Catch exception in Dart
    ↓
Return false
    ↓
Show error to user
```

---

## File Structure

### QuicUI Repository Layout

```
quicui2/
├── packages/
│   ├── quicui_code_push_client/         # Flutter plugin
│   │   ├── lib/
│   │   │   ├── quicui_code_push_client.dart
│   │   │   └── src/
│   │   │       ├── quicui_code_push.dart
│   │   │       ├── services/
│   │   │       │   └── method_channel.dart
│   │   │       ├── constants/
│   │   │       │   └── build_sdk_info.dart  # 🔑 SDK detection
│   │   │       └── models/
│   │   │           └── patch_info.dart
│   │   ├── android/
│   │   │   └── src/main/kotlin/com/quicui/codepush/
│   │   │       ├── QuicuiCodePushClientPlugin.kt
│   │   │       └── CodePushMethodHandler.kt  # 🔑 Fixed import
│   │   └── ios/
│   │       └── Classes/
│   │           └── QuicuiCodePushClientPlugin.swift
│   │
│   ├── quicui_backend/                  # Backend server
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   │   ├── routes/
│   │   │   │   │   └── patch_routes.dart
│   │   │   │   ├── services/
│   │   │   │   │   ├── patch_service.dart
│   │   │   │   │   └── storage_service.dart
│   │   │   │   └── models/
│   │   │   │       ├── patch.dart
│   │   │   │       └── app_info.dart
│   │   │   └── quicui_backend.dart
│   │   └── bin/
│   │       └── server.dart
│   │
│   └── quicui_compiler/                 # Patch compiler
│       └── bin/
│           └── quicui_compiler.dart
│
├── forks/
│   └── flutter-official/                # 🔑 Modified Flutter SDK
│       ├── .quicui_marker               # Fork identification
│       ├── .quicui/
│       │   ├── README.md                # Documentation index
│       │   ├── MIGRATION_GUIDE.md       # Cherry-pick instructions
│       │   ├── VERSION_DETECTION.md     # SDK detection explained
│       │   └── verify_quicui_patch.sh   # Automated verification
│       ├── packages/flutter/lib/src/
│       │   ├── services/
│       │   │   └── flutter_version.dart # 🔑 Modified: adds ' • quicui'
│       │   └── quicui_sdk_marker.dart   # 🔑 New: fork marker
│       └── engine/src/flutter/
│           ├── shell/common/
│           │   ├── codepush_loader.h    # 🔑 New: C++ loader
│           │   └── codepush_loader.cc   # 🔑 New: C++ implementation
│           └── shell/platform/android/.../
│               ├── QuicUICodePushLoader.java  # 🔑 New: Android loader
│               └── FlutterLoader.java         # 🔑 Modified: startup check
│
├── test_apps/
│   ├── test_app_fresh/                  # 🔑 SDK detection test app
│   │   ├── lib/
│   │   │   └── main.dart                # Shows SDK status UI
│   │   ├── android/
│   │   │   └── local.properties         # Points to QuicUI SDK
│   │   └── pubspec.yaml
│   │
│   └── quicui_test_app_v1/             # Integration test app
│       └── ...
│
├── scripts/
│   ├── build-with-sdk-detection.sh
│   ├── install_and_launch.sh
│   └── run_complete_patch_test.sh
│
└── docs/
    ├── ARCHITECTURE.md                  # 🔑 This file
    ├── MIGRATION_GUIDE.md
    ├── FLUTTER_SDK_PATCHES.md
    └── DEPLOYMENT_GUIDE.md
```

### Critical Files

| File | Purpose | Type |
|------|---------|------|
| **CodePushMethodHandler.kt** | Android platform channel handler | Fix |
| **build_sdk_info.dart** | Runtime SDK detection | Feature |
| **flutter_version.dart** | Version string with 'quicui' marker | Modification |
| **FlutterLoader.java** | Startup patch check | Modification |
| **QuicUICodePushLoader.java** | Android patch loader | New |
| **codepush_loader.h/cc** | C++ engine loader | New |

---

## Build & Distribution

### Building Apps with QuicUI SDK

#### 1. Set Up QuicUI Flutter SDK

```bash
# Clone QuicUI fork
git clone git@github.com:Ikolvi/QuicUIFlutterSDK.git
cd QuicUIFlutterSDK

# Checkout QuicUI branch
git checkout quicui/main

# Verify patch is present
./.quicui/verify_quicui_patch.sh

# Add to PATH
export PATH="$(pwd)/bin:$PATH"

# Verify
flutter --version
# Should show QuicUI fork information
```

#### 2. Configure Flutter Project

**pubspec.yaml:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  quicui_code_push_client:
    path: ../packages/quicui_code_push_client

environment:
  sdk: ^3.5.0  # Compatible with QuicUI fork
```

**android/local.properties:**
```properties
sdk.dir=/Users/username/Library/Android/sdk
flutter.sdk=/path/to/QuicUIFlutterSDK
```

#### 3. Build Release APK

```bash
# Clean previous builds
flutter clean
flutter pub get

# Build release APK with QuicUI SDK
flutter build apk --release

# Output:
# ✓ Built build/app/outputs/flutter-apk/app-release.apk (44.0MB)
```

#### 4. Verify SDK Detection

**In your app's main.dart:**
```dart
import 'package:quicui_code_push_client/src/constants/build_sdk_info.dart';

void main() {
  print('='.repeat(50));
  print('SDK Detection:');
  print(BuildSDKInfo.getDetailedInfo());
  print('='.repeat(50));
  
  if (BuildSDKInfo.isQuicUI) {
    print('✅ QuicUI SDK - Code Push enabled');
  } else {
    print('⚠️ Standard Flutter - Code Push disabled');
  }
  
  runApp(MyApp());
}
```

**Expected output (with QuicUI SDK):**
```
==================================================
SDK Detection:
SDK Detection Info:
  Type: QUICUI
  Is QuicUI Fork: true
  Flutter Version: 3.27.0 • quicui
  Dart Version: 3.5.4
  Channel: stable
==================================================
✅ QuicUI SDK - Code Push enabled
```

### Testing with Standard Flutter SDK

To verify graceful degradation:

```bash
# Switch to standard Flutter SDK
export PATH="/path/to/standard/flutter/bin:$PATH"

# Update local.properties
flutter.sdk=/path/to/standard/flutter

# Update SDK constraint if needed
# pubspec.yaml:
environment:
  sdk: ^3.5.0  # Lower constraint for standard SDK

# Build
flutter clean
flutter pub get
flutter build apk --release

# Install and check logs
adb install build/app/outputs/flutter-apk/app-release.apk
adb logcat | grep "SDK"

# Expected output:
# ⚠️ Standard Flutter SDK detected - QuicUI SDK required
```

---

## Migration Guide

### Applying QuicUI Patch to New Flutter Versions

When a new Flutter stable version is released (e.g., 3.28.0):

#### Step 1: Clone and Checkout

```bash
git clone https://github.com/flutter/flutter.git flutter-3.28-quicui
cd flutter-3.28-quicui
git checkout 3.28.0
```

#### Step 2: Add QuicUI Remote

```bash
git remote add quicui git@github.com:Ikolvi/QuicUIFlutterSDK.git
git fetch quicui
```

#### Step 3: Cherry-pick QuicUI Patch

```bash
# This tag includes EVERYTHING (engine + version detection)
git cherry-pick quicui-v1.0.0-engine
```

#### Step 4: Resolve Conflicts (if any)

**Common conflict: FlutterLoader.java**

Manually add:
```java
import io.flutter.embedding.engine.loader.QuicUICodePushLoader;

private void checkForQuicUIPatch() {
  // ... implementation from MIGRATION_GUIDE.md
}
```

**Critical conflict: flutter_version.dart**

Ensure version string includes marker:
```dart
static const String? version = bool.hasEnvironment('FLUTTER_VERSION')
    ? '${String.fromEnvironment('FLUTTER_VERSION')} • quicui'
    : null;
```

#### Step 5: Verify Patch

```bash
# Automated verification
./.quicui/verify_quicui_patch.sh

# Expected output:
# ✓ All checks passed!
```

#### Step 6: Test

```bash
# Build test app
flutter create test_app
cd test_app

# Add code push plugin
flutter pub add quicui_code_push_client --path=/path/to/plugin

# Build
flutter build apk --release

# Test SDK detection
adb install build/app/outputs/flutter-apk/app-release.apk
adb logcat | grep "SDK"

# Should show: "QuicUI Flutter SDK detected"
```

#### Step 7: Tag and Release

```bash
git tag -a quicui-v1.1.0-engine -m "QuicUI patch for Flutter 3.28.0"
git push quicui quicui/main --tags
```

### What Gets Cherry-Picked

The `quicui-v1.0.0-engine` tag includes:

1. **Engine files** (C++/Java):
   - `codepush_loader.h/cc`
   - `QuicUICodePushLoader.java`
   - `FlutterLoader.java` modifications

2. **SDK detection** (Dart):
   - `flutter_version.dart` (adds ' • quicui')
   - `quicui_sdk_marker.dart`
   - `.quicui_marker`

3. **Documentation**:
   - `.quicui/MIGRATION_GUIDE.md`
   - `.quicui/VERSION_DETECTION.md`
   - `.quicui/verify_quicui_patch.sh`

**⚠️ Critical:** Don't cherry-pick engine files alone. The version detection changes are REQUIRED for runtime SDK detection to work!

---

## Summary

### Key Innovations

1. **Minimal SDK Modifications**
   - Only 4 files modified in Flutter SDK
   - 3 new files added for code push
   - All changes in single git tag for easy cherry-picking

2. **Automatic SDK Detection**
   - Version string marker: `"3.27.0 • quicui"`
   - No compilation errors with standard Flutter
   - Graceful degradation with clear warnings

3. **Secure Patch Loading**
   - SHA256 hash validation
   - Automatic rollback on corruption
   - Isolated in code_cache directory

4. **Cross-Platform Ready**
   - Android fully implemented
   - iOS architecture defined (TBD)
   - Web/Desktop could follow same pattern

### Critical Fixes Made

1. **CodePushMethodHandler.kt**
   - Added missing `MethodCall` import
   - Fixed 30+ compilation errors
   - Now compiles with both SDKs

2. **build_sdk_info.dart**
   - Simplified from `isQuicUIFork` constant
   - To `version.contains('quicui')` string check
   - Works at edit time with standard SDK

3. **Plugin Portability**
   - Removed hardcoded `settings.gradle`
   - Cleaned up android directory
   - Plugin now works in any Flutter project

### Architecture Benefits

- **Separation of Concerns**: Engine, plugin, backend are independent
- **Testability**: Can test with standard SDK (shows warnings)
- **Maintainability**: Minimal SDK changes, easy to update
- **Reliability**: Hash validation, automatic fallback
- **Developer Experience**: Clear SDK detection, good error messages

### Next Steps

1. **Complete iOS Implementation**
   - Port QuicUICodePushLoader to Swift
   - Modify iOS FlutterEngine startup
   - Test on iOS devices

2. **Backend Deployment**
   - Deploy patch server
   - Set up CDN for patch distribution
   - Implement analytics

3. **Production Testing**
   - Test with real apps
   - Monitor crash rates
   - Gather performance metrics

4. **Documentation**
   - API documentation
   - Tutorial videos
   - Example apps

---

## Appendix

### Verification Checklist

Before releasing a QuicUI SDK version:

- [ ] Run `.quicui/verify_quicui_patch.sh` - all checks pass
- [ ] Build test app with QuicUI SDK - shows "QuicUI detected"
- [ ] Build test app with standard SDK - shows "Standard Flutter"
- [ ] Test code push download and install
- [ ] Test patch validation (wrong hash rejected)
- [ ] Test automatic rollback (corrupt patch)
- [ ] Update MIGRATION_GUIDE.md version table
- [ ] Create git tag `quicui-vX.Y.Z-engine`
- [ ] Push to GitHub with tags

### Troubleshooting

**Q: SDK detection shows "Standard Flutter" even with QuicUI SDK**

A: Run verification script:
```bash
cd /path/to/flutter-sdk
./.quicui/verify_quicui_patch.sh
```

Check flutter_version.dart has the marker:
```bash
grep "quicui" packages/flutter/lib/src/services/flutter_version.dart
```

**Q: Compilation errors in plugin with standard Flutter SDK**

A: Ensure you're using string check, not direct constant access:
```dart
// ❌ Wrong:
if (FlutterVersion.isQuicUIFork) { ... }

// ✅ Correct:
if (BuildSDKInfo.isQuicUI) { ... }
```

**Q: App crashes after installing patch**

A: Check hash validation in logs:
```bash
adb logcat | grep "QuicUI"
```

If hash mismatch, engine will automatically delete patch and load original.

### References

- **Flutter Engine Architecture**: https://github.com/flutter/flutter/wiki/The-Engine-architecture
- **Platform Channels**: https://docs.flutter.dev/platform-integration/platform-channels
- **AOT Snapshots**: https://github.com/flutter/flutter/wiki/Flutter's-modes
- **QuicUI Repository**: https://github.com/Ikolvi/QuicUICodepush
- **QuicUI Flutter Fork**: https://github.com/Ikolvi/QuicUIFlutterSDK

---

**Document Version:** 1.0  
**Last Updated:** November 1, 2025  
**Author:** QuicUI Team
