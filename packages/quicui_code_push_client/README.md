# QuicUI - Code Push for Flutter

A Flutter plugin for Over-The-Air (OTA) updates using QuicUI Code Push system. This package allows Flutter applications to receive and install code updates without going through the app store review process.

## ⚠️ Important Notice

**This package requires a custom Flutter engine to function.** The standard Flutter SDK from pub.dev will not enable code push functionality. See [Installation](#installation) for details.

## Features

- 🚀 **Over-the-air updates**: Deploy updates instantly without app store review
- 🔒 **Secure patching**: Uses BsDiff binary patching with signature verification
- 📦 **Small patch sizes**: Only downloads differences between versions
- ✅ **Rollback support**: Automatic rollback on update failures
- 🎯 **Targeted releases**: Deploy to specific versions or user segments
- 📊 **Update tracking**: Monitor patch installation and success rates

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  quicui: ^2.0.0
```

Then run:

```bash
flutter pub get
```

### Custom Engine Requirement

**For code push to work**, you need to use a custom-built Flutter engine. This package works in two modes:

1. **Standard Mode** (with stock Flutter): Package works but code push is **disabled**
2. **Code Push Mode** (with custom engine): Full OTA update functionality

To enable code push:
- Download pre-built custom engine from [GitHub Releases](https://github.com/Ikolvi/QuicUICodepush/releases)
- Or build it yourself following the [Engine Build Guide](https://github.com/Ikolvi/QuicUICodepush/blob/develop/docs/ENGINE_BUILD_GUIDE.md)

## Usage

### Basic Setup

```dart
import 'package:quicui/quicui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize QuicUI Code Push
  final quicui = QuicUICodePush(
    appId: 'com.yourcompany.app',
    clientSecret: 'your-client-secret',
    appVersion: '1.0.0',
  );
  
  await quicui.initialize();
  
  runApp(MyApp());
}
```

### Check for Updates

```dart
// Create QuicUI instance
final quicui = QuicUICodePush(
  appId: 'com.yourcompany.app',
  clientSecret: 'your-client-secret',
  appVersion: '1.0.0',
);

await quicui.initialize();

// Check if an update is available
final updateAvailable = await quicui.checkForUpdates();

if (updateAvailable != null) {
  print('Update available: ${updateAvailable.version}');
}
```

### Download and Install Update

```dart
// Download and install the update
final success = await quicui.downloadAndInstall(updateInfo);

if (success) {
  print('Update installed! Restart app to apply.');
  // Show restart prompt to user
}
```

### Full Update Flow

```dart
Future<void> checkAndApplyUpdates() async {
  try {
    final quicui = QuicUICodePush(
      appId: 'com.yourcompany.app',
      clientSecret: 'your-client-secret',
      appVersion: '1.0.0',
    );
    
    await quicui.initialize();
    
    // Check for updates
    final patchInfo = await quicui.checkForUpdates();
    
    if (patchInfo != null) {
      print('Update ${patchInfo.version} available');
      
      // Download and install
      final success = await quicui.downloadAndInstall(patchInfo);
      
      if (success) {
        // Show dialog to restart
        showRestartDialog();
      }
    }
  } catch (e) {
    print('Update failed: $e');
  }
}
```

### Configuration Options

```dart
final quicui = QuicUICodePush(
  appId: 'com.yourcompany.app',
  clientSecret: 'your-client-secret',
  appVersion: '1.0.0',
  
  // Optional: Verify patch signatures
  publicKey: 'your-rsa-public-key',
  
  // Optional: Auto-check on app start
  autoCheckOnStart: true,
  
  // Optional: Custom update check interval (in seconds)
  checkIntervalSeconds: 3600, // 1 hour
  
  // Optional: Maximum patch size
  maxPatchSize: 10 * 1024 * 1024, // 10 MB
);

await quicui.initialize();

// To use a custom backend server (for testing):
// Set environment variable: QUICUI_SERVER_URL=https://your-backend.com
// Or use --dart-define during build:
// flutter build apk --dart-define=QUICUI_SERVER_URL=https://your-backend.com
```

## Backend Setup

This client requires a QuicUI Code Push backend server. You can:

1. Use the official `quicui_backend` package:
   ```bash
   dart pub global activate quicui_backend
   quicui_backend start
   ```

2. Or deploy your own backend following the [Backend Setup Guide](https://github.com/Ikolvi/QuicUICodepush/blob/develop/docs/BACKEND_SETUP.md)

## How It Works

1. **Client checks** for updates from backend server
2. **Backend compares** client version with latest available
3. **BsDiff patch** is generated (binary difference between versions)
4. **Client downloads** the small patch file
5. **Patch is applied** to create new `libapp.so` (AOT compiled Dart code)
6. **On next restart**, Flutter engine loads the patched version

## Platform Support

| Platform | Support | Status |
|----------|---------|--------|
| Android  | ✅ Full | Custom engine required |
| iOS      | 🚧 WIP  | Coming soon |
| Web      | ❌ No   | Not applicable |
| Desktop  | ❌ No   | Not yet supported |

## Example

See the [example](example/) directory for a complete working app demonstrating:
- Update checking
- Progress tracking
- Installation flow
- Error handling

Run the example:

```bash
cd example
flutter run
```

## Contributing

Contributions are welcome! Please read our [Contributing Guide](../../CONTRIBUTING.md) first.

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE](../../LICENSE) file for details.

## Resources

- [Documentation](https://github.com/Ikolvi/QuicUICodepush/tree/develop/docs)
- [Backend Setup](https://github.com/Ikolvi/QuicUICodepush/blob/develop/docs/BACKEND_SETUP.md)
- [Engine Build Guide](https://github.com/Ikolvi/QuicUICodepush/blob/develop/docs/ENGINE_BUILD_GUIDE.md)
- [API Reference](https://pub.dev/documentation/quicui_code_push_client/latest/)
- [Issue Tracker](https://github.com/Ikolvi/QuicUICodepush/issues)

## Support

- 📧 Email: support@quicui.dev
- 💬 Discord: [Join our community](https://discord.gg/quicui)
- 🐛 Bug reports: [GitHub Issues](https://github.com/Ikolvi/QuicUICodepush/issues)

## Comparison with Alternatives

| Feature | QuicUI | Shorebird | CodePush |
|---------|--------|-----------|----------|
| Self-hosted | ✅ Yes | ❌ No | ✅ Yes |
| Flutter Support | ✅ Native | ✅ Native | ❌ React Native |
| Custom Backend | ✅ Yes | ❌ No | ✅ Yes |
| Cost | Free | Paid | Free |

---

**Made with ❤️ by the QuicUI Team**
