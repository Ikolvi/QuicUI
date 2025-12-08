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
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '💜 QUIC PATCH v1.0.1 - PURPLE MAGIC! ✨'),
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
  int _counter = 0;
  String _statusMessage = 'Initializing QuicUI...';
  bool _isChecking = false;
  late QuicUICodePush _codePush;

  @override
  void initState() {
    super.initState();
    _initializeCodePush();
  }

  Future<void> _initializeCodePush() async {
    try {
      _codePush = QuicUICodePush(
        appId: 'com.example.quicuiProductionTest',
        clientSecret: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjYXh2YW5qaHRmYWVpbWZsZ2ZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNzE3MzIsImV4cCI6MjA3ODk0NzczMn0.XqPTK5bw2IukeGs-XBv0pfLHKAqkGKRmQUEvE1L14lU',
        appVersion: '1.0.0',
      );
      
      await _codePush.initialize();
      
      setState(() {
        _statusMessage = 'QuicUI initialized successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to initialize: $e';
      });
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
      _statusMessage = 'Checking for updates...';
    });

    try {
      final patchInfo = await _codePush.checkForUpdates();
      
      if (patchInfo != null) {
        setState(() {
          _statusMessage = 'Update available! Downloading and installing...';
        });
        
        final success = await _codePush.downloadAndInstall(patchInfo);
        
        if (success) {
          setState(() {
            _statusMessage = 'Update installed! Please restart the app to apply.';
          });
        } else {
          setState(() {
            _statusMessage = 'Failed to install update';
          });
        }
      } else {
        setState(() {
          _statusMessage = 'No updates available. You\'re on the latest version!';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('v1.0.1 - PATCHED! 🚀'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade700,
              Colors.deepPurple.shade500,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'v1.0.1 - OTA UPDATE SUCCESS! 🎉',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'You have pushed the button this many times:',
                style: TextStyle(color: Colors.white),
              ),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isChecking ? null : _checkForUpdates,
                      child: _isChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Check for Updates'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
