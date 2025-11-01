# QuicUI Code Push: Dart → Engine Architecture

**Date**: November 1, 2025  
**Status**: 🚧 IMPLEMENTATION IN PROGRESS

---

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     DART APPLICATION LAYER                       │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  quicui_code_push_client Package                       │    │
│  │  ├─ Check for updates (HTTP API)                       │    │
│  │  ├─ Download patch file                                │    │
│  │  ├─ Verify hash & signature                            │    │
│  │  └─ Call platform method: installPatch()               │    │
│  └────────────────────────────────────────────────────────┘    │
│                            ↓                                     │
│                     Platform Channel                             │
│                            ↓                                     │
└─────────────────────────────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                    PLATFORM CHANNEL LAYER                        │
│                                                                   │
│  Method: "installPatch"                                          │
│  Arguments: { patchPath, version, hash, architecture }           │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                   NATIVE PLATFORM LAYER                          │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  QuicUICodePushPlugin (Android/iOS)                    │    │
│  │  ├─ Receives patch file path from Dart                 │    │
│  │  ├─ Calls CodePushLoader.InstallPatch()                │    │
│  │  └─ Returns success/failure to Dart                    │    │
│  └────────────────────────────────────────────────────────┘    │
│                            ↓                                     │
└─────────────────────────────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                    FLUTTER ENGINE LAYER                          │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  CodePushLoader (C++)                                  │    │
│  │  ├─ InstallPatch() - Copy to code cache                │    │
│  │  ├─ SaveMetadata() - Store patch info                  │    │
│  │  └─ Return success                                     │    │
│  └────────────────────────────────────────────────────────┘    │
│                            ↓                                     │
│                    Code Cache Directory                          │
│                /data/data/<pkg>/code_cache/quicui_patches/       │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                             ↓
                      APP RESTART
                             ↓
┌─────────────────────────────────────────────────────────────────┐
│                      NEXT APP STARTUP                            │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  FlutterLoader (Java/ObjC)                             │    │
│  │  ├─ Check code cache for patches                       │    │
│  │  ├─ Validate patch integrity                           │    │
│  │  └─ Load patched libapp.so instead of original         │    │
│  └────────────────────────────────────────────────────────┘    │
│                            ↓                                     │
│                   PATCHED CODE RUNNING ✨                       │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📋 Implementation Steps

### Step 1: Dart Client Package (quicui_code_push_client)

**File**: `packages/quicui_code_push_client/lib/src/code_push.dart`

```dart
class QuicUICodePush {
  static const MethodChannel _channel = 
      MethodChannel('dev.quicui.code_push');
  
  /// Download and install patch
  Future<bool> downloadAndInstall(PatchInfo patch) async {
    // 1. Download patch to temp directory
    final patchFile = await _downloadPatch(patch);
    
    // 2. Verify hash
    if (!await _verifyHash(patchFile, patch.hash)) {
      throw Exception('Hash verification failed');
    }
    
    // 3. Verify signature
    if (!await _verifySignature(patchFile, patch.signature)) {
      throw Exception('Signature verification failed');
    }
    
    // 4. Call native method to install
    final result = await _channel.invokeMethod('installPatch', {
      'patchPath': patchFile.path,
      'version': patch.version,
      'hash': patch.hash,
      'architecture': patch.architecture,
      'signature': patch.signature,
    });
    
    return result == true;
  }
}
```

### Step 2: Platform Channel Plugin (Native Side)

**Android**: `android/src/main/kotlin/dev/quicui/code_push/QuicUICodePushPlugin.kt`

```kotlin
class QuicUICodePushPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  
  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "installPatch" -> {
        val patchPath = call.argument<String>("patchPath")
        val version = call.argument<String>("version")
        val hash = call.argument<String>("hash")
        val architecture = call.argument<String>("architecture")
        val signature = call.argument<String>("signature")
        
        if (patchPath == null || version == null) {
          result.error("INVALID_ARGS", "Missing required arguments", null)
          return
        }
        
        // Call C++ engine code
        val success = installPatchNative(
          patchPath, version, hash, architecture, signature
        )
        
        result.success(success)
      }
      else -> result.notImplemented()
    }
  }
  
  // JNI call to C++ engine
  private external fun installPatchNative(
    patchPath: String,
    version: String,
    hash: String?,
    architecture: String?,
    signature: String?
  ): Boolean
}
```

### Step 3: JNI Bridge (C++)

**File**: `android/src/main/jni/code_push_jni.cc`

```cpp
#include <jni.h>
#include "flutter/shell/common/codepush_loader.h"

extern "C" JNIEXPORT jboolean JNICALL
Java_dev_quicui_code_1push_QuicUICodePushPlugin_installPatchNative(
    JNIEnv* env,
    jobject /* this */,
    jstring j_patch_path,
    jstring j_version,
    jstring j_hash,
    jstring j_architecture,
    jstring j_signature) {
  
  // Convert Java strings to C++ strings
  const char* patch_path_c = env->GetStringUTFChars(j_patch_path, nullptr);
  const char* version_c = env->GetStringUTFChars(j_version, nullptr);
  const char* hash_c = j_hash ? env->GetStringUTFChars(j_hash, nullptr) : "";
  const char* arch_c = j_architecture ? 
      env->GetStringUTFChars(j_architecture, nullptr) : "arm64-v8a";
  const char* sig_c = j_signature ? 
      env->GetStringUTFChars(j_signature, nullptr) : "";
  
  std::string patch_path(patch_path_c);
  std::string version(version_c);
  std::string hash(hash_c);
  std::string architecture(arch_c);
  std::string signature(sig_c);
  
  // Release Java strings
  env->ReleaseStringUTFChars(j_patch_path, patch_path_c);
  env->ReleaseStringUTFChars(j_version, version_c);
  if (j_hash) env->ReleaseStringUTFChars(j_hash, hash_c);
  if (j_architecture) env->ReleaseStringUTFChars(j_architecture, arch_c);
  if (j_signature) env->ReleaseStringUTFChars(j_signature, sig_c);
  
  // Get CodePushLoader instance
  flutter::CodePushLoader* loader = flutter::CodePushLoader::GetInstance();
  if (!loader) {
    return JNI_FALSE;
  }
  
  // Create patch metadata
  flutter::CodePushPatch patch;
  patch.version = version;
  patch.patch_hash = hash;
  patch.architecture = architecture;
  patch.signature = signature;
  patch.requires_restart = true;
  
  // Install patch
  bool success = false;
  loader->InstallPatch(patch, [&success](bool result, const std::string& msg) {
    success = result;
  });
  
  return success ? JNI_TRUE : JNI_FALSE;
}
```

### Step 4: Engine Singleton Access

**File**: `codepush_loader.h`

```cpp
class CodePushLoader {
 public:
  // Singleton access for platform channels
  static CodePushLoader* GetInstance();
  
  // ... existing methods ...
  
 private:
  static CodePushLoader* instance_;
};
```

**File**: `codepush_loader.cc`

```cpp
// Static instance
CodePushLoader* CodePushLoader::instance_ = nullptr;

CodePushLoader* CodePushLoader::GetInstance() {
  if (!instance_) {
    instance_ = new CodePushLoader();
  }
  return instance_;
}
```

---

## 🔄 Complete Flow

### Installation Flow:

```
User Action: "Check for Updates"
     ↓
[DART] QuicUICodePush.checkForUpdate()
     ↓ HTTP Request
[SERVER] Returns PatchInfo { version, url, hash, signature }
     ↓
[DART] QuicUICodePush.downloadAndInstall(patch)
     ↓
[DART] Download patch to temp: /data/data/<pkg>/cache/patch.so
     ↓
[DART] Verify hash (SHA256)
     ↓
[DART] Verify signature (Ed25519)
     ↓
[DART] MethodChannel.invokeMethod('installPatch', {
         patchPath: '/cache/patch.so',
         version: '1.0.1',
         hash: 'abc123...',
         architecture: 'arm64-v8a',
         signature: 'def456...'
       })
     ↓
[KOTLIN] QuicUICodePushPlugin.onMethodCall()
     ↓
[JNI] installPatchNative() bridge
     ↓
[C++] CodePushLoader::InstallPatch()
     ↓
[C++] Copy: /cache/patch.so → /code_cache/quicui_patches/libapp_patched_arm64-v8a.so
     ↓
[C++] SavePatchMetadata() → /code_cache/quicui_patches/patch_metadata.json
     ↓
[C++] Return success
     ↓
[KOTLIN] result.success(true)
     ↓
[DART] Show "Update Ready - Restart App" dialog
     ↓
User: Clicks "Restart Now"
     ↓
[DART] RestartApp() or SystemNavigator.pop()
```

### Restart & Load Flow:

```
APP RESTART
     ↓
[JAVA] FlutterLoader.ensureInitializationCompleteAsync()
     ↓
[JAVA] checkForQuicUIPatch(context)
     ↓
[JAVA] QuicUICodePushLoader.getPatchedAOTPath("arm64-v8a")
     ↓
[JAVA] Check: /code_cache/quicui_patches/libapp_patched_arm64-v8a.so
     ↓
[JAVA] LoadPatchMetadata() from JSON
     ↓
[JAVA] ValidateChecksum(libapp_patched_arm64-v8a.so, expected_hash)
     ↓
[JAVA] Return: "/data/data/<pkg>/code_cache/quicui_patches/libapp_patched_arm64-v8a.so"
     ↓
[JAVA] shellArgs.add("--aot-shared-library-name=" + patchedPath)
     ↓
[C++] Flutter Engine loads patched libapp.so
     ↓
[DART] App runs with patched code ✨
```

---

## 📁 File Structure

```
packages/quicui_code_push_client/
├── lib/
│   ├── src/
│   │   ├── code_push.dart              ← Add installPatch() method
│   │   ├── method_channel.dart         ← NEW: Platform channel
│   │   ├── models/
│   │   │   └── patch_info.dart         ← Patch metadata
│   │   └── utils/
│   │       ├── hash_validator.dart     ← SHA256 verification
│   │       └── signature_validator.dart ← Ed25519 verification
│   └── quicui_code_push_client.dart
│
├── android/
│   ├── src/main/
│   │   ├── kotlin/dev/quicui/code_push/
│   │   │   └── QuicUICodePushPlugin.kt ← Platform channel handler
│   │   └── jni/
│   │       ├── code_push_jni.cc        ← JNI bridge to C++
│   │       └── CMakeLists.txt          ← Build config
│   └── build.gradle                    ← Add JNI dependencies
│
└── ios/
    ├── Classes/
    │   ├── QuicUICodePushPlugin.swift  ← iOS platform channel
    │   └── CodePushBridge.mm           ← Objective-C++ bridge
    └── quicui_code_push_client.podspec
```

---

## 🔧 Implementation Checklist

### Phase 1: Dart Client
- [ ] Add MethodChannel to QuicUICodePush class
- [ ] Implement downloadAndInstall() method
- [ ] Add hash verification (SHA256)
- [ ] Add signature verification (Ed25519)
- [ ] Add restart helper method

### Phase 2: Android Platform Channel
- [ ] Create QuicUICodePushPlugin.kt
- [ ] Implement installPatch method handler
- [ ] Create JNI bridge (code_push_jni.cc)
- [ ] Link with Flutter engine
- [ ] Test platform channel communication

### Phase 3: Engine Integration
- [ ] Add GetInstance() singleton to CodePushLoader
- [ ] Ensure InstallPatch() works via JNI
- [ ] Test patch installation via platform channel

### Phase 4: iOS Support
- [ ] Create QuicUICodePushPlugin.swift
- [ ] Create Objective-C++ bridge
- [ ] Implement iOS-specific code cache handling

### Phase 5: Testing
- [ ] Unit test Dart side
- [ ] Unit test platform channel
- [ ] Integration test: Download → Install → Restart → Verify
- [ ] Test rollback on corruption
- [ ] Test signature verification

---

## 🎯 Benefits of This Architecture

### ✅ Advantages

1. **Clean Separation**: Dart handles downloads, Engine handles installation
2. **Reusable**: Platform channel can be used by any Flutter app
3. **Testable**: Each layer can be tested independently
4. **Secure**: Verification happens in Dart before native code
5. **Platform-Agnostic**: Same Dart API for Android/iOS/Desktop

### 🔒 Security Flow

```
[Dart] Download patch
   ↓
[Dart] Verify hash (first line of defense)
   ↓
[Dart] Verify signature (second line of defense)
   ↓ Only if both pass
[Native] Install to code cache
   ↓
[Native] Validate again on startup (third line of defense)
   ↓ Only if valid
[Engine] Load patched code
```

---

## 📊 Data Flow

### PatchInfo (from API)

```json
{
  "version": "1.0.1",
  "url": "https://api.example.com/patches/v1.0.1/arm64-v8a.so",
  "hash": "abc123def456...",
  "signature": "ed25519_signature_base64",
  "size": 3145728,
  "architecture": "arm64-v8a",
  "releaseDate": "2025-11-01T10:30:00Z",
  "critical": false
}
```

### Platform Channel Message

```dart
{
  "patchPath": "/data/data/com.example.app/cache/patch_temp.so",
  "version": "1.0.1",
  "hash": "abc123def456...",
  "architecture": "arm64-v8a",
  "signature": "ed25519_signature_base64"
}
```

### Metadata JSON (saved by engine)

```json
{
  "version": "1.0.1",
  "platform": "android",
  "architecture": "arm64-v8a",
  "patch_hash": "abc123def456...",
  "patch_size": 3145728,
  "signature": "ed25519_signature_base64",
  "install_date": "2025-11-01T10:35:00Z",
  "requires_restart": true
}
```

---

## 🚀 Next Steps

1. **Implement Dart side** (MethodChannel integration)
2. **Create Android plugin** (Kotlin + JNI)
3. **Add singleton to engine** (GetInstance())
4. **Test end-to-end** (Download → Install → Restart)
5. **Add iOS support**
6. **Production hardening** (error handling, logging)

---

**Status**: 📝 Architecture defined - Ready for implementation  
**Estimated Time**: 1-2 days for complete Android implementation

