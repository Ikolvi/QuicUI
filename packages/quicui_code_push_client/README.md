# QuicUI Code Push Client

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
  quicui_code_push_client: ^0.1.0
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
import 'package:quicui_code_push_client/quicui_code_push_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize QuicUI Code Push
  await QuicUICodePush.initialize(
    apiUrl: 'https://your-backend.com',
    appId: 'com.yourcompany.app',
  );
  
  runApp(MyApp());
}
```

### Check for Updates

```dart
// Check if an update is available
final updateAvailable = await QuicUICodePush.checkForUpdate();

if (updateAvailable) {
  print('Update available!');
}
```

### Download and Install Update

```dart
// Download the update
await QuicUICodePush.downloadUpdate(
  onProgress: (progress) {
    print('Download progress: ${progress * 100}%');
  },
);

// Install the update (will take effect on next app restart)
await QuicUICodePush.installUpdate();

// Restart the app to apply the update
QuicUICodePush.restartApp();
```

### Full Update Flow

```dart
Future<void> checkAndApplyUpdates() async {
  try {
    // Check for updates
    final updateInfo = await QuicUICodePush.checkForUpdate();
    
    if (updateInfo.isAvailable) {
      print('Update ${updateInfo.version} available');
      
      // Download with progress tracking
      await QuicUICodePush.downloadUpdate(
        onProgress: (progress) {
          setState(() {
            downloadProgress = progress;
          });
        },
      );
      
      // Install the update
      await QuicUICodePush.installUpdate();
      
      // Show dialog to restart
      showRestartDialog();
    }
  } catch (e) {
    print('Update failed: $e');
  }
}
```

### Configuration Options

```dart
await QuicUICodePush.initialize(
  apiUrl: 'https://your-backend.com',
  appId: 'com.yourcompany.app',
  
  // Optional: Check for updates automatically
  autoCheckOnLaunch: true,
  
  // Optional: Verify patch signatures
  publicKey: 'your-rsa-public-key',
  
  // Optional: Custom update check interval
  checkInterval: Duration(hours: 6),
);
```

## Backend Setup

This client requires a QuicUI Code Push backend server. You can:

1. Use the official `quicui_backend` package:
   ```bash
   dart pub global activate quicui_backend
   quicui_backend start
   ```

2. Or deploy your own backend following the [Backend Setup Guide](https://github.com/Ikolvi/QuicUICodepush/blob/develop/docs/BACKEND_SETUP.md)

## Compliance & Store Policies

**⚠️ Important Legal Notice:**

This package enables downloading and executing native code, which may violate:
- **Google Play Store** policy on downloading executable code
- **Apple App Store** guideline 2.5.2 on downloading code

### Recommended Use Cases:

✅ **Enterprise/Internal Apps**: Not distributed through public app stores  
✅ **Beta Testing**: Closed testing groups  
✅ **Development/Staging**: Internal testing environments  
❌ **Consumer Apps**: Public app store distribution (high risk of rejection)

### Compliance Alternative:

For consumer apps requiring app store compliance, consider:
- Use this package for **beta testing only**
- Submit full app updates through app stores for production
- Or use server-driven UI approach (separate package coming soon)

See [Compliance Documentation](https://github.com/Ikolvi/QuicUICodepush/blob/develop/docs/COMPLIANCE.md) for detailed policy analysis.

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
| Open Source | ✅ Yes | ❌ No | ✅ Yes |
| Self-hosted | ✅ Yes | ❌ No | ✅ Yes |
| Flutter Support | ✅ Native | ✅ Native | ❌ React Native |
| Store Compliance | ⚠️ Enterprise | ⚠️ Enterprise | ⚠️ Enterprise |
| Custom Backend | ✅ Yes | ❌ No | ✅ Yes |
| Cost | Free | Paid | Free |

---

**Made with ❤️ by the QuicUI Team**
