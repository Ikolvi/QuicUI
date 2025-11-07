import 'package:flutter/material.dart';
import 'package:quicui_code_push_client/quicui_code_push_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuicUI v1 Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'QuicUI v1 Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _patchStatus = 'Initializing...';
  String _currentVersion = '1.0.0';
  bool _isChecking = false;
  late QuicUICodePush _quicui;

  @override
  void initState() {
    super.initState();
    _initQuicUI();
  }

  Future<void> _initQuicUI() async {
    try {
      _quicui = QuicUICodePush(
        appId: 'com.quicui.quicui_v1_test',
        clientSecret: 'test-secret-123',
        appVersion: _currentVersion,
      );
      
      await _quicui.initialize();
      
      setState(() {
        _patchStatus = 'Ready - Tap button to check for updates';
      });
    } catch (e) {
      setState(() {
        _patchStatus = 'Error: $e';
      });
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
      _patchStatus = 'Checking for updates...';
    });

    try {
      final patch = await _quicui.checkForUpdates();
      
      if (patch != null) {
        setState(() {
          _patchStatus = 'Update available: ${patch.version}\nDownloading...';
        });
        
        final success = await _quicui.downloadAndInstall(patch);
        
        setState(() {
          if (success) {
            _patchStatus = 'Update installed! Restart app to apply.';
          } else {
            _patchStatus = 'Update download failed';
          }
        });
      } else {
        setState(() {
          _patchStatus = 'No updates available';
        });
      }
    } catch (e) {
      setState(() {
        _patchStatus = 'Check failed: $e';
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.system_update,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 32),
              Text(
                '✨ PATCH v13.0.0 SUCCESS! ✨',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '🎉 Code Push Works! 🎉',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Current Version: $_currentVersion',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _patchStatus,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isChecking ? null : _checkForUpdates,
                icon: _isChecking 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isChecking ? 'Checking...' : 'Check for Updates'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
