# QuicUI - Code Push for Flutter

A Flutter plugin for Over-The-Air (OTA) updates using QuicUI Code Push system. Deploy code updates to your Flutter applications instantly.

## Features

- 🚀 **Over-the-air updates**: Deploy updates instantly
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
```

## Platform Support

| Platform | Support | Status |
|----------|---------|--------|
| Android  | ✅ Full | Production ready |
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

- [Documentation](https://quicui.com/docs)
- [API Reference](https://pub.dev/documentation/quicui/latest/)
- [Issue Tracker](https://github.com/Ikolvi/QuicUICodepush/issues)

## Support

- 📧 Email: support@quicui.com
- 💬 Discord: [Join our community](https://discord.gg/quicui)
- 🌐 Website: [https://quicui.com](https://quicui.com)
- 🐛 Bug reports: [GitHub Issues](https://github.com/Ikolvi/QuicUICodepush/issues)

---

**Made with ❤️ by the QuicUI Team**
