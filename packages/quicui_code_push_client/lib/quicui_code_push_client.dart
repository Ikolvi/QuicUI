/// QuicUI - Code Push for Flutter
/// 
/// A Flutter package that provides over-the-air (OTA) code push functionality.
/// Configuration is loaded automatically from quicui.yaml.
/// 
/// ## Quick Start
/// 
/// 1. Create a quicui.yaml in your project root:
/// ```yaml
/// server:
///   url: "https://your-server.com"
/// app:
///   id: "com.example.app"
/// version:
///   current: "1.0.0"
/// ```
/// 
/// 2. Set QUICUI_API_KEY environment variable or add to quicui.yaml
/// 
/// 3. Use in your app:
/// ```dart
/// import 'package:quicui_code_push_client/quicui_code_push_client.dart';
/// 
/// void main() async {
///   final client = await QuicUICodePush.create();
///   await client.initialize();
///   
///   final patch = await client.checkForUpdates();
///   if (patch != null) {
///     await client.downloadAndInstall(patch);
///     await client.restartApp();
///   }
///   
///   runApp(const MyApp());
/// }
/// ```

library quicui;

// Main client - the only class users need to interact with
export 'src/quicui_code_push.dart' show QuicUICodePush;

// Exceptions for error handling
export 'src/exceptions.dart';

// Models that users may need to interact with
export 'src/models/patch_info.dart' show PatchInfo;
export 'src/models/sdk_info.dart' show SDKInfo;

