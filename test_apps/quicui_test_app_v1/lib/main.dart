import 'package:flutter/material.dart';
import 'package:quicui_code_push_client/quicui_code_push_client.dart';

void main() {
  runApp(const QuicUITestApp());
}

class QuicUITestApp extends StatelessWidget {
  const QuicUITestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuicUI Code Push Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Config codePushConfig;
  String appVersion = '1.0.0';
  String patchStatus = 'Initializing...';
  String availablePatchVersion = 'None';
  String sdkInfo = 'Detecting...';
  String sdkStatus = 'Loading SDK info...';
  bool isCheckingForPatches = false;
  bool isPatchApplied = false;

  @override
  void initState() {
    super.initState();
    _initializeCodePush();
  }

  Future<void> _initializeCodePush() async {
    try {
      // Initialize code push configuration with local network endpoint
      // PC Address: 192.168.20.100:8080
      codePushConfig = Config(
        apiUrl: 'http://192.168.20.100:8080',
        appId: 'com.quicui.testapp',
        clientSecret: 'test-secret-key-12345',
        appVersion: appVersion,
        enableDebugLogging: true,
        includeSDKInfo: true,
      );

      // Detect SDK info
      await _detectSDKInfo();

      setState(() {
        patchStatus = 'Ready - Waiting for patches';
      });

      // Check for patches
      await _checkForPatches();
    } catch (e) {
      setState(() {
        patchStatus = 'Error: $e';
      });
    }
  }

  Future<void> _detectSDKInfo() async {
    try {
      // Detect SDK info directly from Flutter SDK using SDKInfoService
      final flutterVersion = await SDKInfoService.getFlutterSDKVersion();
      final channel = await SDKInfoService.getFlutterSDKChannel();
      final isQuicUI = await SDKInfoService.isQuicUISDK();
      
      final statusIcon = isQuicUI ? '✅' : '❌';
      final sdkType = isQuicUI ? 'QuicUI (Custom Fork)' : 'Flutter (Standard)';
      final shortInfo = '$flutterVersion ($channel)';
      
      setState(() {
        sdkInfo = shortInfo;
        sdkStatus = '$sdkType $statusIcon';
      });
    } catch (e) {
      setState(() {
        sdkInfo = 'Unknown';
        sdkStatus = 'Error detecting SDK: $e';
      });
    }
  }

  Future<void> _checkForPatches() async {
    if (isCheckingForPatches) return;

    setState(() {
      isCheckingForPatches = true;
      patchStatus = 'Checking for patches...';
    });

    try {
      // In a real app, this would fetch from backend
      // For now, we simulate the check
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        patchStatus = 'Ready - No patches available yet';
        isCheckingForPatches = false;
      });
    } catch (e) {
      setState(() {
        patchStatus = 'Error checking patches: $e';
        isCheckingForPatches = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('QuicUI Code Push Test'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Welcome text
                const Text(
                  'Welcome to QuicUI Code Push v1.0.1 🚀',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // App Info Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow('App Version:', appVersion),
                        _InfoRow('SDK Status:', sdkStatus),
                        _InfoRow('SDK Info:', sdkInfo),
                        _InfoRow('Patch Status:', patchStatus),
                        _InfoRow('Available Patch:', availablePatchVersion),
                        _InfoRow('Patch Applied:', isPatchApplied ? 'Yes ✅' : 'No'),
                        _InfoRow('Patch Version:', 'v1.0.1'),
                        _InfoRow('Features:', 'OTA Updates ✨'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                ElevatedButton(
                  onPressed: isCheckingForPatches ? null : _checkForPatches,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: isCheckingForPatches
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Check for Patches'),
                  ),
                ),
                const SizedBox(height: 12),

                // Info text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'This app uses the QuicUI Code Push system to receive and apply '
                    'binary patches over-the-air without requiring app store updates.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // Configuration info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configuration:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ConfigItem('Server', 'localhost:8080'),
                      _ConfigItem('Backend', 'Dart/Shelf REST API'),
                      _ConfigItem('Compiler', 'quicui_compiler'),
                      _ConfigItem('SDK Fork', 'v3.35.7-quicui-0.9.0'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 1,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 1,
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigItem extends StatelessWidget {
  final String label;
  final String value;

  const _ConfigItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '• $label: ',
            style: const TextStyle(fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
