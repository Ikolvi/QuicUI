# QuicUI

<p align="center">
  <img src="https://raw.githubusercontent.com/Ikolvi/QuicUICodepush/main/logo.png" alt="QuicUI Logo" width="200">
</p>

[![pub package](https://img.shields.io/pub/v/quicui.svg)](https://pub.dev/packages/quicui)
[![License](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](LICENSE)

A Flutter plugin for instant Over-The-Air (OTA) code updates. Push Dart code changes to your users in seconds.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Complete Setup Guide](#complete-setup-guide)
- [Usage](#usage)
- [API Reference](#api-reference)
- [Platform Support](#platform-support)
- [Troubleshooting](#troubleshooting)
- [Related Projects](#related-projects)

## Features

- 🚀 **Instant OTA Updates** — Deploy Dart code changes in seconds
- 🔐 **Secure** — Signature verification and hash validation
- 📦 **Small Downloads** — XZ/GZIP compression (~95% smaller)
- ✅ **Rollback Support** — Automatic rollback on failures
- 🎯 **YAML Configuration** — Auto-loads from `quicui.yaml`
- 🔒 **Hidden Secrets** — Server URL and API keys are internal only
- 📱 **Android Support** — Full production support (iOS coming soon)

## Quick Start

### 1. Install CLI & Initialize

```bash
# Install CLI from pub.dev
dart pub global activate quicui_cli

# Initialize in your Flutter project
cd your_flutter_app
quicui init
```

### 2. Download QuicUI SDK

```bash
quicui engine download
```

### 3. Add this package

```yaml
# pubspec.yaml
dependencies:
  quicui: ^2.0.6
```

### 4. Initialize in your app

```dart
import 'package:quicui/quicui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await QuicUICodePush.instance.initialize();
  runApp(MyApp());
}
```

### 5. Create release & push updates

```bash
# First release (baseline)
quicui release --version 1.0.0

# After making changes, push update
quicui patch --version 1.0.1
```

That's it! Users receive updates on next app launch.

---

## Complete Setup Guide

### Prerequisites

| Requirement | Version |
|-------------|---------|
| Flutter | 3.0.0+ |
| Dart | 3.0.0+ |
| QuicUI CLI | Latest |
| QuicUI Flutter SDK | Required |

> ⚠️ **Important**: This package requires the QuicUI-patched Flutter SDK. Standard Flutter SDK will not support code push functionality.

### Step 1: Install QuicUI CLI

```bash
# Install from pub.dev (recommended)
dart pub global activate quicui_cli

# Or install from source
git clone https://github.com/Ikolvi/quicui-cli.git
cd quicui-cli
dart pub get
dart pub global activate --source path .

# Verify installation
quicui --version
```

### Step 2: Initialize Your Project

```bash
cd your_flutter_app
quicui init
```

This will:
1. Detect your app ID from `android/app/build.gradle`
2. **Auto-generate a unique API key** from the QuicUI server
3. Create `quicui.yaml` with your configuration

```
🚀 QuicUI Initialization
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔑 Generating API key...
   ✅ API key generated successfully
✅ Created quicui.yaml
```

### Step 3: Download QuicUI Flutter SDK

```bash
quicui engine download
```

The SDK is downloaded to `~/.quicui/flutter/` — completely isolated from your system Flutter installation.

### Step 4: Add the Package

```yaml
# pubspec.yaml
dependencies:
  quicui: ^2.0.6
```

```bash
flutter pub get
```

### Step 5: Configuration

Your `quicui.yaml` (auto-generated):

```yaml
# QuicUI Code Push Configuration

server:
  url: "https://pcaxvanjhtfaeimflgfk.supabase.co/functions/v1"
  api_key: "quicui_abc123..."  # Auto-generated

app:
  id: "com.example.myapp"
  name: "My App"

version:
  current: "1.0.0"

build:
  architectures:
    - arm64-v8a
    # - armeabi-v7a  # Uncomment for 32-bit support

patch:
  compression: xz  # Options: xz, gzip, none
```

### Step 6: Create Your First Release

```bash
quicui release --version 1.0.0
```

This builds your app with the QuicUI SDK and uploads the baseline binary.

### Step 7: Publish to Play Store

Build and publish your app normally:

```bash
quicui build-aab --project .
```

Upload the resulting AAB to Google Play Store.

### Step 8: Push Updates

After making code changes:

```bash
quicui patch --version 1.0.1 --notes "Bug fixes"
```

Users receive the update on next app launch!

---

## Usage

### Basic Usage

```dart
import 'package:quicui/quicui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize (auto-loads from quicui.yaml)
  await QuicUICodePush.instance.initialize();
  
  runApp(const MyApp());
}
```

### Manual Update Check

```dart
import 'package:quicui/quicui.dart';

Future<void> checkForUpdates() async {
  final quicui = QuicUICodePush.instance;
  
  // Check for updates
  final patch = await quicui.checkForUpdates();
  
  if (patch != null) {
    print('Update available: ${patch.version}');
    
    // Download and install
    final success = await quicui.downloadAndInstall(patch);
    
    if (success) {
      // Restart to apply the update
      await quicui.restartApp();
    }
  }
}
```

### Background Update Check

```dart
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdates();
    }
  }

  Future<void> _checkForUpdates() async {
    final quicui = QuicUICodePush.instance;
    
    final patch = await quicui.checkForUpdates();
    if (patch != null) {
      _showUpdateDialog(patch);
    }
  }

  void _showUpdateDialog(PatchInfo patch) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: Text('Version ${patch.version} is available.\n\n${patch.releaseNotes ?? ""}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await QuicUICodePush.instance.downloadAndInstall(patch);
              if (success) {
                await QuicUICodePush.instance.restartApp();
              }
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
```

### Error Handling

```dart
import 'package:quicui/quicui.dart';

Future<void> initWithErrorHandling() async {
  try {
    await QuicUICodePush.instance.initialize();
    
  } on QuicUIConfigNotFoundException catch (e) {
    // quicui.yaml not found - run "quicui init"
    print('Config not found: ${e.message}');
    
  } on QuicUIConfigInvalidException catch (e) {
    // Invalid configuration
    print('Invalid config: ${e.message}');
    print('Missing fields: ${e.missingFields}');
    
  } on QuicUIException catch (e) {
    // Generic QuicUI error
    print('QuicUI error: ${e.message} (code: ${e.code})');
  }
}
```

### Silent Updates

```dart
// Check and install updates silently in background
Future<void> silentUpdate() async {
  final quicui = QuicUICodePush.instance;
  
  final patch = await quicui.checkForUpdates();
  if (patch != null && !patch.critical) {
    // Download in background
    await quicui.downloadAndInstall(patch);
    // Will apply on next app restart
  }
}
```

### Critical Updates

```dart
Future<void> handleCriticalUpdate() async {
  final quicui = QuicUICodePush.instance;
  
  final patch = await quicui.checkForUpdates();
  if (patch != null && patch.critical) {
    // Force update for critical patches
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Critical Update Required'),
        content: const Text('This update is required to continue using the app.'),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final success = await quicui.downloadAndInstall(patch);
              if (success) {
                await quicui.restartApp();
              }
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}
```

---

## API Reference

### QuicUICodePush

| Method | Description |
|--------|-------------|
| `QuicUICodePush.instance` | Get singleton instance |
| `initialize()` | Initialize the client (required first) |
| `checkForUpdates()` | Check for available patches |
| `downloadAndInstall(patch)` | Download and install a patch |
| `restartApp()` | Restart app to apply installed patch |
| `getCurrentPatch()` | Get currently applied patch info |
| `rollback()` | Rollback to previous version |

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `isInitialized` | `bool` | Whether client is initialized |
| `currentVersion` | `String?` | Current app version |

### PatchInfo

| Property | Type | Description |
|----------|------|-------------|
| `version` | `String` | Patch version |
| `downloadUrl` | `String` | URL to download patch |
| `hash` | `String` | SHA-256 hash for verification |
| `size` | `int` | Compressed size in bytes |
| `releaseNotes` | `String?` | Optional release notes |
| `critical` | `bool` | Whether update is critical |

### Exceptions

| Exception | Description |
|-----------|-------------|
| `QuicUIConfigNotFoundException` | `quicui.yaml` not found |
| `QuicUIConfigInvalidException` | Invalid configuration |
| `QuicUIException` | Generic error |

---

## Platform Support

| Platform | Architecture | Status |
|----------|--------------|--------|
| Android | arm64-v8a | ✅ Production Ready |
| Android | armeabi-v7a | ✅ Production Ready |
| Android | x86_64 | ⚠️ Emulator only |
| iOS | arm64 | 🚧 Coming Soon |
| Web | — | ❌ Not Supported |
| Desktop | — | ❌ Not Supported |

---

## Environment Variables

| Variable | Description |
|----------|-------------|
| `QUICUI_API_KEY` | Override API key from yaml |

```bash
export QUICUI_API_KEY="your-custom-api-key"
```

---

## Troubleshooting

### "quicui.yaml not found"

Run `quicui init` in your Flutter project root:

```bash
cd your_flutter_app
quicui init
```

### "API key missing"

Either:
1. Re-run `quicui init` to regenerate
2. Set environment variable: `export QUICUI_API_KEY="your-key"`
3. Add manually to `quicui.yaml` under `server.api_key`

### "SDK incompatible" / Updates not working

You need the QuicUI Flutter SDK:

```bash
quicui engine download
```

Then build with: `quicui release --version 1.0.0`

### Updates not applying

Make sure to call `restartApp()` after successful `downloadAndInstall()`:

```dart
final success = await quicui.downloadAndInstall(patch);
if (success) {
  await quicui.restartApp();  // Don't forget this!
}
```

### Network errors

Check your server URL in `quicui.yaml` and ensure the device has internet access.

---

## How It Works

```
┌─────────────────┐                    ┌─────────────────┐
│   Your App      │                    │  QuicUI Server  │
│  (with client)  │                    │   (Supabase)    │
└────────┬────────┘                    └────────┬────────┘
         │                                      │
         │  1. Check for updates                │
         │ ────────────────────────────────────▶│
         │                                      │
         │  2. Patch info (version, URL, hash)  │
         │ ◀────────────────────────────────────│
         │                                      │
         │  3. Download patch file              │
         │ ────────────────────────────────────▶│
         │                                      │
         │  4. Compressed patch (~200KB)        │
         │ ◀────────────────────────────────────│
         │                                      │
         ▼                                      │
┌─────────────────┐                             │
│ Decompress &    │                             │
│ Apply bspatch   │                             │
└────────┬────────┘                             │
         │                                      │
         ▼                                      │
┌─────────────────┐                             │
│ Restart with    │                             │
│ new code        │                             │
└─────────────────┘
```

---

## Security

- **Hash Validation** — SHA-256 verification before installation
- **Secure Transport** — HTTPS for all API calls
- **Signature Verification** — Patches can be signed
- **Automatic Rollback** — Reverts on installation failure
- **No Exposed Secrets** — API keys stored securely

---

## Related Projects

| Project | Description | Link |
|---------|-------------|------|
| **QuicUI CLI** | Command-line tool for building & deploying | [github.com/Ikolvi/quicui-cli](https://github.com/Ikolvi/quicui-cli) |
| **QuicUI Server** | Supabase backend for patches | [github.com/Ikolvi/QuicUiServer](https://github.com/Ikolvi/QuicUiServer) |
| **This Package** | Flutter client SDK | [github.com/Ikolvi/QuicUICodepush](https://github.com/Ikolvi/QuicUICodepush) |
| **pub.dev** | Package on pub.dev | [pub.dev/packages/quicui](https://pub.dev/packages/quicui) |

---

## Example

See the [example](example/) directory for a complete working app.

```bash
cd example
flutter run
```

---

## Contributing

Contributions are welcome! Please check our [GitHub Issues](https://github.com/Ikolvi/QuicUICodepush/issues).

---

## License

BSD 3-Clause License - see [LICENSE](LICENSE) for details.

---

**Made with ❤️ by the QuicUI Team**
