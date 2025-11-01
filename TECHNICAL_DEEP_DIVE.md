# QuicUI Technical Deep Dive: Implementation Details

**Status**: Technical Reference for Developers
**Date**: November 1, 2025

---

## 1. Flutter SDK Modification Details

### 1.1 Key Files to Modify

#### File 1: `flutter/shell/common/engine.cc`

**Location**: `flutter/engine/src/shell/common/engine.cc`

**Current Flow** (simplified):
```cpp
Engine::Engine(Delegate& delegate, ...) {
  // 1. Initialize Dart VM
  blink::DartVMRef dart_vm = blink::DartVM::Create(settings_);
  
  // 2. Load main isolate
  std::unique_ptr<Shell> shell = Shell::Create(...);
  
  // 3. Run app
  shell->RunEngine(run_configuration);
}
```

**Modified Flow** (with code push):
```cpp
Engine::Engine(Delegate& delegate, ...) {
  // ✨ NEW: Check and load patches BEFORE creating shell
  if (code_push_enabled_) {
    CodePushLoader patch_loader;
    bool has_patch = patch_loader.CheckForPatch();
    if (has_patch) {
      patch_data_ = patch_loader.LoadPatch();  // Load patch data
      // Patch will be applied when VM initializes
    }
  }
  
  // 1. Initialize Dart VM (with patches loaded)
  blink::DartVMRef dart_vm = blink::DartVM::Create(settings_);
  
  // 2. Load main isolate
  std::unique_ptr<Shell> shell = Shell::Create(...);
  
  // 3. Run app
  shell->RunEngine(run_configuration);
}
```

**Implementation Requirements**:
```cpp
// In Engine class declaration
private:
  CodePushLoader code_push_loader_;
  std::optional<std::vector<uint8_t>> patch_data_;
  bool code_push_enabled_;
  
  // Call at startup
  void InitializeCodePush();
  void ApplyPatchedKernels();
```

#### File 2: `flutter/runtime/dart_vm.cc`

**Current kernel loading**:
```cpp
// In dart_vm.cc (simplified)
std::shared_ptr<DartVM> DartVM::Create(...) {
  // Load app kernel from assets
  std::vector<uint8_t> kernel = LoadKernelFromAssets("vm_snapshot_data");
  
  // Create isolate with kernel
  Dart_IsolateGroupCreateCallback create_isolate = 
    [&kernel](Dart_IsolateGroupId group_id, ...) {
      return Dart_CreateIsolateGroup(..., &kernel);
    };
}
```

**Modified to support patches**:
```cpp
std::shared_ptr<DartVM> DartVM::Create(...) {
  // ✨ NEW: Check if we have patched kernel
  std::vector<uint8_t> kernel;
  
  if (ShouldUsePatchedKernel()) {
    kernel = LoadPatchedKernel();  // Apply patches
    LOG(INFO) << "Using patched kernel";
  } else {
    kernel = LoadKernelFromAssets("vm_snapshot_data");
  }
  
  // Rest stays the same
  Dart_IsolateGroupCreateCallback create_isolate = 
    [&kernel](Dart_IsolateGroupId group_id, ...) {
      return Dart_CreateIsolateGroup(..., &kernel);
    };
}

// Helper function
bool ShouldUsePatchedKernel() {
  // Check if patch exists and is valid
  return patch_manager_.HasValidPatch();
}

std::vector<uint8_t> LoadPatchedKernel() {
  // Load base kernel
  auto kernel = LoadKernelFromAssets("vm_snapshot_data");
  
  // Apply patches on top
  auto patch = patch_manager_.GetAppliedPatch();
  kernel = ApplyBinaryPatch(kernel, patch);
  
  return kernel;
}
```

#### File 3: `flutter/lib/src/services/binding.dart`

**Current initialization** (simplified):
```dart
class WidgetsFlutterBinding extends BindingBase {
  @override
  void initInstances() {
    super.initInstances();
    
    // App lifecycle handlers
    _channel.setMethodCallHandler(_handleMethodCall);
    
    // Start app
    _fireSystemMessages();
  }
}
```

**Modified with code push**:
```dart
class WidgetsFlutterBinding extends BindingBase {
  @override
  void initInstances() {
    super.initInstances();
    
    // ✨ NEW: Initialize code push
    unawaited(_initializeCodePush());
    
    // App lifecycle handlers
    _channel.setMethodCallHandler(_handleMethodCall);
    
    // Start app (will use patched code if available)
    _fireSystemMessages();
  }
  
  // ✨ NEW: Initialize code push
  Future<void> _initializeCodePush() async {
    try {
      // Import the code push manager
      final codePush = await _loadCodePushModule();
      
      if (codePush != null) {
        // Check for available patches
        await codePush.initializeAsync();
      }
    } catch (e) {
      // Silently fail - app continues with bundled code
      developer.log('Code push initialization failed: $e',
        level: 1000,
        name: 'flutter.binding',
      );
    }
  }
  
  // Dynamically load code push module
  Future<dynamic>? _loadCodePushModule() async {
    try {
      return rootBundle.load('assets/code_push.dart');
    } catch (_) {
      return null;
    }
  }
}
```

---

### 1.2 New Code: CodePushLoader (C++)

**File**: `flutter/runtime/codepush_loader.cc`

```cpp
#include "flutter/runtime/codepush_loader.h"

#include <fstream>
#include <vector>
#include <openssl/sha.h>
#include <openssl/ed25519.h>

namespace flutter {

CodePushLoader::CodePushLoader() : has_valid_patch_(false) {}

bool CodePushLoader::CheckForPatch() {
  // Check if patch file exists in app's documents directory
  std::string patch_path = GetPatchStoragePath();
  std::ifstream patch_file(patch_path, std::ios::binary);
  
  if (!patch_file.is_open()) {
    FLOG(INFO) << "No patch file found at " << patch_path;
    return false;
  }
  
  // Read patch metadata
  std::string metadata_json;
  std::getline(patch_file, metadata_json);
  
  // Verify patch integrity
  if (!VerifyPatchIntegrity(patch_file, metadata_json)) {
    FLOG(WARNING) << "Patch integrity check failed";
    return false;
  }
  
  has_valid_patch_ = true;
  return true;
}

std::vector<uint8_t> CodePushLoader::LoadPatch() {
  if (!has_valid_patch_) {
    return std::vector<uint8_t>();
  }
  
  std::string patch_path = GetPatchStoragePath();
  std::ifstream patch_file(patch_path, std::ios::binary);
  
  if (!patch_file.is_open()) {
    return std::vector<uint8_t>();
  }
  
  // Skip metadata line
  std::string metadata;
  std::getline(patch_file, metadata);
  
  // Read patch data
  patch_file.seekg(0, std::ios::end);
  size_t file_size = patch_file.tellg();
  patch_file.seekg(metadata.size() + 1);
  
  std::vector<uint8_t> patch_data(file_size - metadata.size() - 1);
  patch_file.read(reinterpret_cast<char*>(patch_data.data()), 
                  patch_data.size());
  
  return patch_data;
}

bool CodePushLoader::VerifyPatchIntegrity(
    std::ifstream& file,
    const std::string& metadata_json) {
  
  // Parse metadata
  auto metadata = rapidjson::Document();
  metadata.Parse(metadata_json.c_str());
  
  // Get expected hash
  std::string expected_hash = 
    metadata["signature"]["hash"].GetString();
  
  // Compute SHA256 of patch data
  unsigned char hash[SHA256_DIGEST_LENGTH];
  SHA256_CTX sha256;
  SHA256_Init(&sha256);
  
  const size_t buf_size = 1024 * 1024; // 1MB chunks
  std::vector<char> buffer(buf_size);
  
  file.seekg(metadata_json.size() + 1);
  while (file.read(buffer.data(), buf_size) || file.gcount() > 0) {
    SHA256_Update(&sha256, buffer.data(), file.gcount());
  }
  
  SHA256_Final(hash, &sha256);
  
  // Compare with expected
  char computed_hash[SHA256_DIGEST_LENGTH * 2 + 1];
  for (int i = 0; i < SHA256_DIGEST_LENGTH; i++) {
    sprintf(computed_hash + i * 2, "%02x", hash[i]);
  }
  
  bool hash_match = (expected_hash == computed_hash);
  
  // Verify signature
  // (signature would verify the metadata was signed by trusted key)
  
  return hash_match;
}

std::string CodePushLoader::GetPatchStoragePath() {
  // On Android: /data/data/com.example.app/app_flutter/patch.bin
  // On iOS: <AppDocuments>/patch.bin
  
  #ifdef __ANDROID__
    return GetAndroidPatchPath();
  #elif __APPLE__
    return GetIOSPatchPath();
  #endif
}

}  // namespace flutter
```

**Header**: `flutter/runtime/codepush_loader.h`

```cpp
#ifndef FLUTTER_RUNTIME_CODEPUSH_LOADER_H_
#define FLUTTER_RUNTIME_CODEPUSH_LOADER_H_

#include <vector>
#include <string>
#include <fstream>

namespace flutter {

/// Handles loading and verification of code push patches
class CodePushLoader {
 public:
  CodePushLoader();
  
  /// Check if a valid patch is available
  bool CheckForPatch();
  
  /// Load patch data into memory
  std::vector<uint8_t> LoadPatch();
  
 private:
  /// Verify patch file integrity and signature
  bool VerifyPatchIntegrity(
    std::ifstream& file,
    const std::string& metadata_json);
    
  /// Get platform-specific patch storage path
  std::string GetPatchStoragePath();
  
  bool has_valid_patch_;
};

}  // namespace flutter

#endif  // FLUTTER_RUNTIME_CODEPUSH_LOADER_H_
```

---

## 2. Dart Compiler Details

### 2.1 Kernel Diffing Algorithm

```dart
// File: packages/quicui_compiler/lib/src/analyzer/kernel_analyzer.dart

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/element/element.dart';
import 'crypto/sha256.dart';

class KernelAnalyzer {
  /// Analyze two kernels and produce diff
  Future<KernelDiff> analyzeDiff(
    String previousKernelPath,
    String currentKernelPath,
  ) async {
    final previous = await _loadKernel(previousKernelPath);
    final current = await _loadKernel(currentKernelPath);
    
    // Compare
    final diff = KernelDiff();
    
    // Find changed libraries
    final changedLibraries = _findChangedLibraries(previous, current);
    diff.changedLibraries = changedLibraries;
    
    // For each changed library, find changed classes
    for (final libUri in changedLibraries) {
      final changedClasses = _findChangedClasses(
        previous.libraries[libUri],
        current.libraries[libUri],
      );
      diff.changedClasses[libUri] = changedClasses;
    }
    
    // Calculate total size reduction
    diff.originalSize = await File(currentKernelPath).length();
    diff.patchSize = _estimatePatchSize(diff);
    
    return diff;
  }
  
  /// Find which libraries changed between versions
  Set<Uri> _findChangedLibraries(Kernel previous, Kernel current) {
    final changed = <Uri>{};
    
    for (final uri in current.libraries.keys) {
      // Skip unchanged libraries
      if (!previous.libraries.containsKey(uri)) {
        changed.add(uri);
        continue;
      }
      
      // Hash libraries to detect changes
      final prevHash = _hashLibrary(previous.libraries[uri]);
      final currHash = _hashLibrary(current.libraries[uri]);
      
      if (prevHash != currHash) {
        changed.add(uri);
      }
    }
    
    // Check for deleted libraries
    for (final uri in previous.libraries.keys) {
      if (!current.libraries.containsKey(uri)) {
        changed.add(uri);
      }
    }
    
    return changed;
  }
  
  /// Find which classes changed in a library
  Set<String> _findChangedClasses(
    Library previousLib,
    Library currentLib,
  ) {
    final changed = <String>{};
    
    for (final className in currentLib.classes.keys) {
      if (!previousLib.classes.containsKey(className)) {
        changed.add(className);
        continue;
      }
      
      final prevHash = _hashClass(previousLib.classes[className]);
      final currHash = _hashClass(currentLib.classes[className]);
      
      if (prevHash != currHash) {
        changed.add(className);
      }
    }
    
    // Check for deleted classes
    for (final className in previousLib.classes.keys) {
      if (!currentLib.classes.containsKey(className)) {
        changed.add(className);
      }
    }
    
    return changed;
  }
  
  /// Hash a library for comparison
  String _hashLibrary(Library lib) {
    final buffer = StringBuffer();
    
    for (final cls in lib.classes.values) {
      buffer.write(_hashClass(cls));
    }
    
    for (final function in lib.functions.values) {
      buffer.write(_hashFunction(function));
    }
    
    return sha256(buffer.toString());
  }
  
  /// Hash a class for comparison
  String _hashClass(Class cls) {
    final buffer = StringBuffer();
    buffer.write('class:${cls.name}');
    
    for (final method in cls.methods.values) {
      buffer.write(_hashFunction(method));
    }
    
    return sha256(buffer.toString());
  }
  
  /// Hash a function for comparison
  String _hashFunction(Function func) {
    // This would hash the function bytecode/AST
    return sha256('${func.name}:${func.body}');
  }
  
  /// Estimate final patch size
  int _estimatePatchSize(KernelDiff diff) {
    // Sum of changed class bytecode sizes
    int total = 0;
    for (final classes in diff.changedClasses.values) {
      for (final cls in classes) {
        // Rough estimate: average method is 1KB
        total += 1024 * (_estimateMethodCount(cls) ?? 5);
      }
    }
    
    // Account for compression (typically 60-80% reduction with brotli)
    return (total * 0.3).toInt();
  }
}

class KernelDiff {
  Set<Uri> changedLibraries = {};
  Map<Uri, Set<String>> changedClasses = {};
  int originalSize = 0;
  int patchSize = 0;
  
  double get compressionRatio => 
    (1 - (patchSize / originalSize)) * 100;
}
```

---

## 3. Backend API Endpoints (OpenAPI/Swagger)

```yaml
openapi: 3.0.0
info:
  title: QuicUI Code Push API
  version: 1.0.0
  description: API for managing patches and deployments

servers:
  - url: https://api.quicui.dev/v1
  - url: http://localhost:8080/v1

paths:
  /apps:
    post:
      summary: Register new app
      tags: [Apps]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                name:
                  type: string
                bundle_id:
                  type: string
              required: [name, bundle_id]
      responses:
        201:
          description: App created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/App'

  /apps/{appId}/patches:
    post:
      summary: Upload new patch
      tags: [Patches]
      parameters:
        - in: path
          name: appId
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          multipart/form-data:
            schema:
              type: object
              properties:
                from_version:
                  type: string
                to_version:
                  type: string
                patch_file:
                  type: string
                  format: binary
                metadata:
                  type: object
              required: [from_version, to_version, patch_file]
      responses:
        201:
          description: Patch uploaded
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Patch'

    get:
      summary: List patches for app
      tags: [Patches]
      parameters:
        - in: path
          name: appId
          required: true
          schema:
            type: string
      responses:
        200:
          description: Patches list
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/Patch'

  /apps/{appId}/check:
    post:
      summary: Check for available patch (called by app)
      tags: [Client]
      parameters:
        - in: path
          name: appId
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                current_version:
                  type: string
                platform:
                  type: string
                  enum: [android, ios]
                device_id:
                  type: string
      responses:
        200:
          description: Patch availability
          content:
            application/json:
              schema:
                type: object
                properties:
                  available:
                    type: boolean
                  patch:
                    $ref: '#/components/schemas/ClientPatch'

  /apps/{appId}/events:
    post:
      summary: Report patch event (download, apply, crash)
      tags: [Analytics]
      parameters:
        - in: path
          name: appId
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                event_type:
                  type: string
                  enum: [patch_downloaded, patch_applied, patch_failed, patch_crashed]
                patch_id:
                  type: string
                device_id:
                  type: string
                timestamp:
                  type: string
                  format: date-time
                error_message:
                  type: string
      responses:
        204:
          description: Event recorded

components:
  schemas:
    App:
      type: object
      properties:
        id:
          type: string
          format: uuid
        name:
          type: string
        bundle_id:
          type: string
        created_at:
          type: string
          format: date-time

    Patch:
      type: object
      properties:
        id:
          type: string
          format: uuid
        app_id:
          type: string
          format: uuid
        from_version:
          type: string
        to_version:
          type: string
        size_bytes:
          type: integer
        download_url:
          type: string
        signature:
          type: string
        created_at:
          type: string
          format: date-time

    ClientPatch:
      type: object
      properties:
        patch_id:
          type: string
        from_version:
          type: string
        to_version:
          type: string
        download_url:
          type: string
        size_bytes:
          type: integer
        requires_restart:
          type: boolean
        signature:
          type: string
```

---

## 4. Cryptographic Signing Implementation

```dart
// File: packages/quicui_compiler/lib/src/signer/code_signer.dart

import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class CodeSigner {
  late Ed25519PrivateKey _privateKey;
  late Ed25519PublicKey _publicKey;
  
  /// Load signing keys from files
  Future<void> loadKeys(String privateKeyPath, String publicKeyPath) async {
    _privateKey = Ed25519PrivateKey.fromPem(
      File(privateKeyPath).readAsStringSync(),
    );
    _publicKey = Ed25519PublicKey.fromPem(
      File(publicKeyPath).readAsStringSync(),
    );
  }
  
  /// Generate new key pair
  Future<void> generateKeyPair(String privateKeyPath, String publicKeyPath) async {
    final random = Random.secure();
    final generator = Ed25519KeyPairGenerator();
    generator.init(KeyGeneratorParameters(random));
    
    final pair = generator.generateKeyPair();
    _privateKey = pair.privateKey as Ed25519PrivateKey;
    _publicKey = pair.publicKey as Ed25519PublicKey;
    
    // Save to files
    await File(privateKeyPath).writeAsString(_privateKey.toPem());
    await File(publicKeyPath).writeAsString(_publicKey.toPem());
  }
  
  /// Sign patch data
  Uint8List signPatch(Uint8List patchData) {
    final signer = Ed25519Signer();
    signer.init(true, PrivateKeyParameter(_privateKey));
    
    final signature = signer.generateSignature(patchData);
    return signature.bytes;
  }
  
  /// Verify patch signature (called on device)
  bool verifyPatchSignature(Uint8List patchData, Uint8List signature) {
    final verifier = Ed25519Signer();
    verifier.init(false, PublicKeyParameter(_publicKey));
    
    try {
      return verifier.verifySignature(patchData, signature);
    } catch (_) {
      return false;
    }
  }
  
  /// Generate patch manifest with signatures
  Future<String> generateManifest(PatchBundle bundle) async {
    final manifest = {
      'patch_id': bundle.id,
      'from_version': bundle.fromVersion,
      'to_version': bundle.toVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'files': {},
      'signature': null,
    };
    
    // Sign each file
    for (final file in bundle.files) {
      final fileData = await File(file.path).readAsBytes();
      final fileSig = signPatch(fileData);
      
      manifest['files'][file.name] = {
        'size': fileData.length,
        'hash': sha256.convert(fileData).toString(),
        'signature': base64.encode(fileSig),
      };
    }
    
    // Sign entire manifest
    final manifestJson = jsonEncode(manifest);
    final manifestSig = signPatch(utf8.encode(manifestJson));
    manifest['signature'] = base64.encode(manifestSig);
    
    return jsonEncode(manifest);
  }
}
```

---

## 5. Patch Application Flow (Device-Side)

```dart
// File: packages/quicui_code_push_client/lib/src/services/patch_service.dart

class PatchService {
  /// Download and apply patch
  Future<void> downloadAndApply(PatchInfo patch) async {
    try {
      // 1. Download patch
      final patchData = await _downloadPatch(patch.downloadUrl);
      
      // 2. Verify signature
      final isValid = await _verifySignature(patchData, patch.signature);
      if (!isValid) {
        throw Exception('Patch signature verification failed');
      }
      
      // 3. Check storage space
      if (patchData.length > _maxPatchSize) {
        throw Exception('Patch too large: ${patchData.length} bytes');
      }
      
      // 4. Save patch
      final patchPath = await _getPatchStoragePath();
      await File(patchPath).writeAsBytes(patchData);
      
      // 5. Mark for application on next startup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_patch_id', patch.patchId);
      await prefs.setString('pending_patch_version', patch.toVersion);
      
      // 6. Inform platform layer
      await _notifyPlatformPatchReady();
      
      // 7. Log event
      await _logEvent('patch_downloaded', patch.patchId);
      
      // 8. Notify user
      _onPatchReady.add(patch);
      
    } catch (e) {
      await _logEvent('patch_failed', patch.patchId, error: e.toString());
      rethrow;
    }
  }
  
  /// Verify patch signature
  Future<bool> _verifySignature(
    Uint8List patchData,
    String signature,
  ) async {
    // Get public key
    final publicKeyPath = await _getPublicKeyPath();
    final publicKeyPem = await File(publicKeyPath).readAsString();
    
    // Verify using crypto library
    return verifySig(
      patchData,
      base64.decode(signature),
      publicKeyPem,
    );
  }
  
  /// Download patch with resume capability
  Future<Uint8List> _downloadPatch(String url) async {
    final file = File('${(await getTemporaryDirectory()).path}/patch.tmp');
    
    var received = 0;
    final response = await http.Client().send(
      http.Request('GET', Uri.parse(url))
        ..followRedirects = true
        ..headers['Range'] = 'bytes=$received-',
    );
    
    // Download with streaming
    final sink = file.openWrite(mode: FileMode.append);
    
    await response.stream.forEach((chunk) {
      sink.add(chunk);
      received += chunk.length;
      _onDownloadProgress.add(received);
    });
    
    await sink.close();
    
    final bytes = await file.readAsBytes();
    await file.delete();
    
    return bytes;
  }
  
  /// Save patch and signal to Flutter engine
  Future<void> _notifyPlatformPatchReady() async {
    const platform = MethodChannel('com.example.app/codepush');
    
    try {
      await platform.invokeMethod('notifyPatchReady');
    } on PlatformException catch (e) {
      print('Failed to notify platform: ${e.message}');
    }
  }
}
```

---

## 6. Testing Strategy

```dart
// File: packages/quicui_compiler/test/compiler_test.dart

import 'package:test/test.dart';
import 'package:quicui_compiler/quicui_compiler.dart';

void main() {
  group('PatchCompiler', () {
    late PatchCompiler compiler;
    
    setUp(() {
      compiler = PatchCompiler();
    });
    
    test('should detect library changes', () async {
      // Create two kernels with one changed library
      final previousKernel = _createTestKernel(
        libraries: {'package:myapp/main.dart': _createLibrary()},
      );
      
      final currentKernel = _createTestKernel(
        libraries: {'package:myapp/main.dart': _createModifiedLibrary()},
      );
      
      // Compile patch
      final patch = await compiler.compilePatch(
        fromVersion: '1.0.0',
        toVersion: '1.0.1',
        kernelA: previousKernel,
        kernelB: currentKernel,
      );
      
      expect(patch.changedLibraries, contains('package:myapp/main.dart'));
    });
    
    test('should compress patches efficiently', () async {
      final patch = await compiler.compilePatch(
        fromVersion: '1.0.0',
        toVersion: '1.0.1',
        kernelA: _createLargeKernel(),
        kernelB: _createSlightlyModifiedKernel(),
      );
      
      // Expect 80%+ compression
      expect(patch.compressionRatio, greaterThan(80));
    });
    
    test('should sign patches correctly', () async {
      final signer = CodeSigner();
      await signer.generateKeyPair('private.pem', 'public.pem');
      
      final patchData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final signature = signer.signPatch(patchData);
      
      final isValid = signer.verifyPatchSignature(patchData, signature);
      expect(isValid, true);
    });
  });
}
```

---

## 7. Performance Benchmarks

Expected performance targets:

```
Operation | Target | Notes
-----------|--------|-------
Patch compilation | < 5 min | Full build with diff
Patch size | < 500 KB | 95% of patches
Compression ratio | > 80% | Brotli + binary diff
Signature verification | < 100ms | On device
Download time (50KB patch on 4G) | ~1-2s |
App startup overhead | < 100ms | With patch checking
Memory usage | < 10 MB | Peak during application
```

---

## 8. Security Considerations

### 8.1 Key Management

```dart
// Never hardcode keys
const String privateKeyPath = '~/.quicui/private_key.pem';

// Protect private key
void protectPrivateKey() {
  // Unix: chmod 600
  // Windows: ACL restrictions
  // Dart: Can't do directly, document requirement
}
```

### 8.2 Patch Validation

```
Validation Steps:
1. Signature verification (Ed25519)
2. Size bounds check
3. Version compatibility check
4. Hash verification
5. Safe mode detection (auto-rollback on crash)
```

---

