import 'package:flutter/material.dart';
import 'package:quicui_code_push_client/quicui_code_push_client.dart';

/// Example E2E test app demonstrating full Code Push workflow
void main() {
  runApp(const CodePushDemoApp());
}

class CodePushDemoApp extends StatelessWidget {
  const CodePushDemoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuicUI Code Push Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const CodePushDemoScreen(),
    );
  }
}

class CodePushDemoScreen extends StatefulWidget {
  const CodePushDemoScreen({Key? key}) : super(key: key);

  @override
  State<CodePushDemoScreen> createState() => _CodePushDemoScreenState();
}

class _CodePushDemoScreenState extends State<CodePushDemoScreen> {
  late CodePushClient _codePushClient;
  String _status = 'Initializing...';
  String _patchVersion = 'Unknown';
  bool _isInitialized = false;
  bool _isLoading = false;
  Map<String, dynamic>? _latestPatch;

  @override
  void initState() {
    super.initState();
    _initializeCodePush();
  }

  /// Initialize Code Push client with service configuration
  Future<void> _initializeCodePush() async {
    try {
      _codePushClient = CodePushClient();

      final config = CodePushConfig(
        serviceUrl: 'https://api.quicui.dev',
        appId: 'com.example.codepush.demo',
        appVersion: '1.0.0',
      );

      final success = await _codePushClient.initialize(config);

      if (success) {
        setState(() {
          _isInitialized = true;
          _status = 'Code Push initialized successfully';
        });

        // Get loaded patch version
        await _updatePatchVersion();
      } else {
        setState(() {
          _status = 'Failed to initialize Code Push';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error initializing Code Push: $e';
      });
    }
  }

  /// Update the displayed patch version
  Future<void> _updatePatchVersion() async {
    try {
      final version = await _codePushClient.getLoadedPatchVersion();
      setState(() {
        _patchVersion = version ?? 'None';
      });
    } catch (e) {
      print('Error getting patch version: $e');
    }
  }

  /// Check for available patches from the service
  Future<void> _checkForPatches() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code Push not initialized')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Checking for patches...';
    });

    try {
      final patch = await _codePushClient.checkForPatch();

      setState(() {
        _isLoading = false;
        if (patch != null) {
          _latestPatch = patch;
          _status = 'Patch available: ${patch['version'] ?? 'Unknown'}';
        } else {
          _status = 'No patches available';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error checking patches: $e';
      });
    }
  }

  /// Load a specific patch by version
  Future<void> _loadPatch(String version) async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code Push not initialized')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Loading patch $version...';
    });

    try {
      final result = await _codePushClient.loadPatch(version);

      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _patchVersion = version;
          _status = 'Patch $version loaded successfully';
        } else {
          _status = 'Failed to load patch: ${result['message']}';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_status)),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error loading patch: $e';
      });
    }
  }

  /// Disable Code Push functionality
  Future<void> _disableCodePush() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Code Push?'),
        content: const Text('Are you sure you want to disable Code Push?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _status = 'Disabling Code Push...';
    });

    try {
      final success = await _codePushClient.disableCodePush();

      setState(() {
        _isLoading = false;
        _isInitialized = false;
        if (success) {
          _status = 'Code Push disabled';
        } else {
          _status = 'Failed to disable Code Push';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error disabling Code Push: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuicUI Code Push Demo'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _status,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isInitialized ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isInitialized ? 'Initialized' : 'Not initialized',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Patch Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Patch',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Version: $_patchVersion'),
                    if (_latestPatch != null) ...[
                      const SizedBox(height: 8),
                      Text('Available: ${_latestPatch!['version'] ?? 'Unknown'}'),
                      Text('Size: ${_latestPatch!['patchSize'] ?? 'Unknown'} bytes'),
                      Text('Critical: ${_latestPatch!['critical'] ?? false}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Check for patches button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _checkForPatches,
                icon: const Icon(Icons.cloud_download),
                label: const Text('Check for Patches'),
              ),
            ),
            const SizedBox(height: 8),

            // Load patch button (if patch available)
            if (_latestPatch != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _loadPatch(_latestPatch!['version'] ?? ''),
                  icon: const Icon(Icons.download),
                  label: Text('Load Patch ${_latestPatch!['version'] ?? ''}'),
                ),
              ),
            const SizedBox(height: 8),

            // Disable Code Push button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _disableCodePush,
                icon: const Icon(Icons.close),
                label: const Text('Disable Code Push'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Loading indicator
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),

            // Debug info
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Debug Info',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'App ID: com.example.codepush.demo',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'App Version: 1.0.0',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Service URL: https://api.quicui.dev',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
