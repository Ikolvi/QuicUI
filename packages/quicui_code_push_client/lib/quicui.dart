/// QuicUI - Code Push for Flutter
/// 
/// A Flutter package that provides code push functionality for QuicUI-enabled applications.
/// 
/// ## Usage
/// 
/// ```dart
/// import 'package:quicui/quicui.dart';
/// 
/// void main() {
///   runApp(const MyApp());
/// }
/// 
/// class MyApp extends StatefulWidget {
///   const MyApp({Key? key}) : super(key: key);
/// 
///   @override
///   State<MyApp> createState() => _MyAppState();
/// }
/// 
/// class _MyAppState extends State<MyApp> {
///   final _quicui = QuicUICodePush(
///     apiUrl: 'https://api.quicui.com',
///     appId: 'com.example.app',
///     clientSecret: 'your-client-secret',
///   );
/// 
///   @override
///   void initState() {
///     super.initState();
///     _quicui.initialize();
///   }
/// 
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       title: 'QuicUI Example',
///       home: Scaffold(
///         body: Center(
///           child: ElevatedButton(
///             onPressed: () => _quicui.checkForUpdates(),
///             child: const Text('Check for Updates'),
///           ),
///         ),
///       ),
///     );
///   }
/// }
/// ```

library quicui;

export 'src/quicui_code_push.dart';
export 'src/models/patch_info.dart';
export 'src/models/config.dart';
export 'src/models/sdk_info.dart';
export 'src/services/patch_service.dart';
export 'src/services/signature_verifier.dart';
export 'src/services/storage_service.dart';
export 'src/services/sdk_info_service.dart';
export 'src/services/method_channel.dart';
export 'src/constants/build_sdk_info.dart';
export 'src/binding.dart';
