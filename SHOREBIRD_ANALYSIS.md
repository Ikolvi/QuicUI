# QuicUI Technical Analysis: Shorebird Architecture Breakdown

**Status**: Analysis & Design Reference
**Date**: November 1, 2025

---

## 1. Shorebird's Approach - High-Level Overview

Shorebird operates as a **managed code push service** with these core components:

### 1.1 Component Stack

```
┌─────────────────────────────────────────────────────┐
│ Developer (shorebird CLI) → Build Dart/Flutter App │
└──────────────┬──────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────┐
│ Shorebird's Private Compiler Infrastructure         │
│ - Kernel compilation                                │
│ - Delta diff generation                             │
│ - Signature generation                              │
└──────────────┬──────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────┐
│ Shorebird's Backend (console.shorebird.dev)        │
│ - Version management                                │
│ - Release orchestration                             │
│ - Analytics & monitoring                            │
└──────────────┬──────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────┐
│ Modified Flutter Engine + Runtime                   │
│ - Code loading & verification                       │
│ - Patch application                                 │
└──────────────┬──────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────┐
│ User's Device - App receives patches OTA            │
└──────────────────────────────────────────────────────┘
```

---

## 2. Key Modifications in Shorebird's Flutter Fork

### 2.1 Engine-Level Changes (C++/Platform Layer)

Shorebird modifies the Flutter engine to add a **"Code Push" initialization phase**:

```
NORMAL FLUTTER STARTUP:
1. Load Flutter engine
2. Load Dart VM
3. Execute main()
4. Render UI

SHOREBIRD FLUTTER STARTUP:
1. Load Flutter engine
2. Check for available patches
3. Download & verify patch (if available)
4. Load patch into Dart VM
5. Load Dart VM
6. Execute main()
7. Render UI
```

**Files modified:**
- `flutter/shell/common/engine.cc` - Add patch checking on startup
- `flutter/shell/platform/android/` - Android patch loader implementation
- `flutter/shell/platform/ios/` - iOS patch loader implementation
- `flutter/runtime/dart_vm.cc` - VM initialization with patches

### 2.2 Dart VM Modifications

The Dart VM needs to support **loading compiled code (kernels/snapshots) at runtime**:

```c++
// Key modification in dart_vm.cc (pseudo-code)
void DartVM::Initialize(const DartVMSettings& settings) {
  // Standard initialization
  InitializeVM(settings);
  
  // NEW: Load patches before executing app
  if (HasPendingPatch()) {
    LoadPatchedKernel();  // Load modified kernel
    ApplyPatchedSnapshots(); // Replace method snapshots
  }
  
  // Standard app execution
  RunEntrypointMain();
}
```

### 2.3 Flutter Framework Additions (Dart)

```dart
// NEW: flutter/lib/src/code_push/
class CodePushManager {
  static Future<void> initialize() async {
    // Called from main.dart before app runs
    final patch = await _checkForAvailablePatch();
    if (patch != null) {
      await _downloadAndApplyPatch(patch);
    }
  }
  
  static Future<void> _checkForAvailablePatch() async {
    // Connect to Shorebird backend
    // Verify device/app eligibility
    // Return available patch or null
  }
}

// In flutter/lib/src/services/binding.dart
class WidgetsFlutterBinding extends BindingBase {
  @override
  void initInstances() {
    super.initInstances();
    
    // NEW: Initialize code push before anything else
    CodePushManager.initialize().then((_) {
      _appLifecycleState.didFinishLaunching();
    });
  }
}
```

### 2.4 Key Design Decisions in Shorebird

| Decision | What They Did | Why |
|----------|--------------|-----|
| **Patch Scope** | Only Dart code, not native | Easier to verify & sandbox |
| **Application Timing** | On app startup (not hot reload) | Safer, more predictable |
| **Verification** | Ed25519 signatures + version checks | Prevent tampering & rollback issues |
| **Rollout** | Staged percentage rollout | Catch issues early, A/B test |
| **Fallback** | Use bundled code if patch fails | Graceful degradation |
| **Storage** | Local cache + server source of truth | Minimize downloads, offline support |

---

## 3. QuicUI's Differentiation Strategy

### 3.1 What We Should Keep From Shorebird

✅ **Core Architecture Concepts**
- Modified Flutter engine approach
- Patch verification via cryptographic signatures
- Backend service for version/patch management
- CLI tool for developers
- Client library for app developers

✅ **Best Practices**
- Staged rollout mechanism
- Crash detection & automatic rollback
- Version compatibility checking
- Size optimization through delta compression
- Platform-specific implementations (iOS/Android)

### 3.2 Where We Can Differentiate

🎯 **Self-Hosted Alternative**
- **Shorebird's Model**: Managed service (you use their backend)
- **QuicUI's Model**: Open-source, self-hostable (you control the backend)

🎯 **Architecture**
- **Shorebird**: Proprietary compiler, closed backend
- **QuicUI**: Open-source everything, clear architecture

🎯 **Cost Model**
- **Shorebird**: Subscription-based ($$$)
- **QuicUI**: Free & open-source

🎯 **Customization**
- **Shorebird**: Limited customization (use their tools)
- **QuicUI**: Full control over compilation, deployment, storage

---

## 4. Detailed Implementation Architecture for QuicUI

### 4.1 Modified Flutter SDK Structure

```
quicui-flutter/
├── engine/                        # Forked from flutter/engine
│   └── src/
│       ├── runtime/
│       │   ├── codepush_loader.cc          # ✨ NEW
│       │   ├── codepush_loader.h           # ✨ NEW
│       │   ├── patch_manager.cc            # ✨ NEW
│       │   └── patch_manager.h             # ✨ NEW
│       ├── platform/
│       │   ├── android/
│       │   │   └── codepush_channel.cc     # ✨ NEW
│       │   └── ios/
│       │       └── CodePushChannel.mm      # ✨ NEW
│       └── vm/
│           ├── dart_isolate.cc             # MODIFIED
│           └── dart_vm.cc                  # MODIFIED
│
└── flutter/                       # Forked from flutter/flutter
    └── lib/
        ├── src/
        │   ├── services/
        │   │   └── binding.dart            # MODIFIED (add code push init)
        │   └── code_push/                  # ✨ NEW directory
        │       ├── code_push_manager.dart
        │       ├── patch_loader.dart
        │       ├── signature_verifier.dart
        │       └── storage_manager.dart
        └── foundation/
            └── diagnostics.dart             # MODIFIED (for logging)
```

### 4.2 Patch Compilation Pipeline

**Shorebird's Approach:**
```
Source Code Changes
        ↓
Compile to Kernel (full)
        ↓
Snapshot Generation
        ↓
Binary Diffing (proprietary algorithm)
        ↓
Compression + Signing
        ↓
Upload to Shorebird's CDN
```

**QuicUI's Approach (More Transparent):**
```
Source Code Changes
        ↓
Compare with previous pubspec.lock + version
        ↓
Use Dart analyzer to find changed libraries
        ↓
Generate new Kernel for changed libs
        ↓
Binary diff against previous kernel
        ↓
Use BSDIFF + Brotli compression
        ↓
Ed25519 sign + generate manifest
        ↓
Output patch bundle (metadata + diff + signature)
        ↓
Upload to backend (self-hosted CDN)
```

### 4.3 Backend Service Structure

```
quicui-backend/
├── bin/
│   └── server.dart                    # Entry point
├── lib/
│   ├── handlers/
│   │   ├── app_handler.dart           # App registration
│   │   ├── version_handler.dart       # Version management
│   │   ├── patch_handler.dart         # Patch upload/download
│   │   ├── release_handler.dart       # Release orchestration
│   │   └── analytics_handler.dart     # Event tracking
│   ├── models/
│   │   ├── app_model.dart
│   │   ├── version_model.dart
│   │   ├── patch_model.dart
│   │   └── release_model.dart
│   ├── services/
│   │   ├── auth_service.dart          # JWT authentication
│   │   ├── storage_service.dart       # CDN storage abstraction
│   │   ├── database_service.dart      # Postgres access
│   │   └── analytics_service.dart     # Event processing
│   ├── middleware/
│   │   ├── auth_middleware.dart
│   │   ├── rate_limit_middleware.dart
│   │   ├── cors_middleware.dart
│   │   └── error_handler_middleware.dart
│   ├── database/
│   │   ├── migrations/
│   │   │   ├── 001_initial_schema.sql
│   │   │   ├── 002_add_indexes.sql
│   │   │   └── 003_analytics_tables.sql
│   │   └── models.dart
│   └── server.dart                    # Server setup
├── test/
│   ├── handlers/
│   ├── services/
│   └── integration/
└── pubspec.yaml
```

### 4.4 CLI Tool Architecture

```
quicui-cli/
├── bin/
│   └── quicui.dart                    # CLI entry point
├── lib/
│   ├── commands/
│   │   ├── auth/
│   │   │   ├── login_command.dart
│   │   │   ├── logout_command.dart
│   │   │   └── whoami_command.dart
│   │   ├── init/
│   │   │   └── init_command.dart
│   │   ├── build/
│   │   │   ├── build_command.dart
│   │   │   ├── patch_command.dart
│   │   │   └── compile_command.dart
│   │   ├── release/
│   │   │   ├── push_command.dart
│   │   │   ├── activate_command.dart
│   │   │   └── rollback_command.dart
│   │   ├── keys/
│   │   │   ├── generate_command.dart
│   │   │   └── list_command.dart
│   │   ├── config/
│   │   │   ├── set_command.dart
│   │   │   └── show_command.dart
│   │   └── analytics/
│   │       ├── show_command.dart
│   │       └── monitor_command.dart
│   ├── services/
│   │   ├── api_client.dart            # Backend communication
│   │   ├── compiler_service.dart      # Orchestrates compilation
│   │   ├── storage_service.dart       # Upload to CDN
│   │   ├── config_service.dart        # Local configuration
│   │   ├── auth_service.dart          # Token management
│   │   └── process_service.dart       # Run external commands
│   ├── models/
│   │   ├── patch_info.dart
│   │   ├── release_info.dart
│   │   └── analytics_data.dart
│   └── utils/
│       ├── logger.dart
│       ├── progress_indicator.dart
│       ├── error_messages.dart
│       └── validators.dart
├── test/
│   ├── commands/
│   ├── services/
│   └── integration/
└── pubspec.yaml
```

---

## 5. Shorebird Code Push Protocol (Reverse Engineered)

### 5.1 Client-Server Communication

**1. Check for Updates (Client → Backend)**

```http
GET /api/v1/release/latest?app_id=com.example.app&platform=android&version=1.0.0

Response:
{
  "release": {
    "id": "release_123",
    "version": "1.0.1",
    "patch": {
      "id": "patch_456",
      "url": "https://cdn.shorebird.dev/patches/patch_456.zip",
      "hash": "abc123...",
      "size": 245120,
      "requires_restart": false
    }
  },
  "status": "available"
}
```

**2. Download Patch**

```
GET https://cdn.shorebird.dev/patches/patch_456.zip

Response: Binary patch file
```

**3. Verify & Apply Patch**

```dart
// On device:
1. Download patch_456.zip
2. Verify signature: Ed25519.verify(patch_data, signature, public_key)
3. Extract patch contents
4. Merge with existing kernel
5. Restart app or hot-apply
```

### 5.2 Patch Bundle Format

```
patch_456.zip:
├── metadata.json
│   {
│     "version": "1.0.1",
│     "patch_number": 1,
│     "requires_restart": false,
│     "compatibility": {
│       "min_app_version": "1.0.0",
│       "max_app_version": "2.0.0"
│     }
│   }
├── patches/
│   ├── base.kernel (or kernel.patch if delta)
│   ├── isolate.kernel
│   └── assets.tar.gz
├── signature.txt
│   (Ed25519 signature of above files)
└── manifest.json
   {
     "files": {
       "patches/base.kernel": "sha256:...",
       "patches/isolate.kernel": "sha256:...",
       "patches/assets.tar.gz": "sha256:..."
     }
   }
```

---

## 6. QuicUI Implementation Priorities

### Priority 1: MVP (Weeks 1-8)

**Critical Path:**
1. ✅ Fork Flutter & add minimal patch loader hook
2. ✅ Build compiler that generates diffs
3. ✅ Build CLI to orchestrate the process
4. ✅ Build backend to serve patches
5. ✅ Build client library for app integration
6. ✅ End-to-end test on real device

**Success**: Can push patch through all stages and app applies it

### Priority 2: Production Hardening (Weeks 9-14)

**Must Have:**
- Reliable signature verification
- Crash detection & auto-rollback
- Staged rollout support
- Analytics & monitoring
- Error recovery
- Documentation

### Priority 3: Optimization (Weeks 15-16)

**Nice to Have:**
- Better compression algorithms
- Faster compilation
- Monitoring dashboard
- API rate limiting
- Performance profiling

---

## 7. Quick Reference: Key Integration Points

### 7.1 Modified Flutter Startup Flow

```dart
// flutter/lib/src/services/binding.dart (MODIFIED)

class WidgetsFlutterBinding extends BindingBase
    with SchedulerBinding, GestureBinding, ServicesBinding, PaintingBinding,
    SemanticsBinding, RendererBinding, WidgetsBinding {
          
  @override
  void initInstances() {
    super.initInstances();
    
    // ✨ NEW: Initialize code push first
    _initializeCodePush().then((_) {
      _handleLifecycleMessage(const AppLifecycleMessage.resumed());
    }).catchError((error) {
      // Fallback to normal execution if patch fails
      _handleLifecycleMessage(const AppLifecycleMessage.resumed());
    });
  }
  
  Future<void> _initializeCodePush() async {
    if (!_isCodePushEnabled()) return; // Feature flag
    
    final codePush = CodePushManager.instance;
    try {
      final patch = await codePush.checkForUpdates();
      if (patch != null) {
        await codePush.downloadAndApply(patch);
      }
    } catch (e) {
      print('Code push error: $e');
      // Continue with app
    }
  }
  
  bool _isCodePushEnabled() {
    // Can be controlled via:
    // 1. Environment variable
    // 2. Config file
    // 3. Flutter settings
    return const bool.fromEnvironment('ENABLE_CODE_PUSH', defaultValue: true);
  }
}
```

### 7.2 App Developer Integration

```dart
// User's app/main.dart
import 'package:quicui_code_push_client/quicui_code_push_client.dart';

void main() async {
  // Initialize code push BEFORE runApp
  await QuicUICodePush.initialize(
    config: QuicUIConfig(
      appId: 'com.example.myapp',
      backendUrl: 'https://quicui-backend.example.com',
      publicKeyPath: 'assets/public_key.pem',
      enableAutoCheck: true,
      checkInterval: Duration(hours: 1),
    ),
  );
  
  runApp(MyApp());
}

// Optional: Manual check in app
class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _checkForUpdates() async {
    final patch = await QuicUICodePush.instance.checkForUpdates();
    if (patch != null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Update Available'),
            content: Text('Update to ${patch.toVersion}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later'),
              ),
              TextButton(
                onPressed: () {
                  QuicUICodePush.instance.downloadAndApply(patch);
                  Navigator.pop(context);
                },
                child: const Text('Update Now'),
              ),
            ],
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Check for Updates'),
            onTap: _checkForUpdates,
          ),
        ],
      ),
    );
  }
}
```

---

## 8. Success Indicators

You'll know you're on the right track when:

1. ✅ **Can build patches** that are <500KB (vs 5-10MB for full app)
2. ✅ **Patches are cryptographically signed** and verified
3. ✅ **App receives patch** and applies on next restart
4. ✅ **No app crashes** from bad patches (with rollback)
5. ✅ **Backend tracks versions** and patch distribution
6. ✅ **CLI makes it simple** for developers
7. ✅ **Performance overhead < 100ms** on startup
8. ✅ **Documentation clear** for app developers

---

## Appendix: File Comparison Helper

To see exact diffs in Shorebird's fork, you can:

```bash
# Get all commits in Shorebird's fork
cd flutter-shorebird
git log --oneline origin/master..shorebird/dev

# See changes in specific file
git diff origin/master..shorebird/dev -- shell/common/engine.cc

# See all modified files
git diff --name-only origin/master..shorebird/dev

# Get statistics
git diff --stat origin/master..shorebird/dev
```

---

