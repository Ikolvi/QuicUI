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
      title: 'QuicUI Code Push Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'QuicUI Code Push Demo'),
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
  String _sdkInfo = 'Checking SDK...';
  bool _isQuicUI = false;

  @override
  void initState() {
    super.initState();
    _checkSDK();
  }

  Future<void> _checkSDK() async {
    try {
      final isQuicUI = BuildSDKInfo.isQuicUI;
      final sdkString = BuildSDKInfo.getSDKString();
      final detailedInfo = BuildSDKInfo.getDetailedInfo();
      
      setState(() {
        _isQuicUI = isQuicUI;
        _sdkInfo = detailedInfo;
      });
      
      print('='.repeat(70));
      print('SDK Detection Result:');
      print('='.repeat(70));
      print(detailedInfo);
      print('='.repeat(70));
    } catch (e) {
      setState(() {
        _sdkInfo = 'Error detecting SDK: $e';
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                _isQuicUI ? Icons.check_circle : Icons.warning,
                size: 80,
                color: _isQuicUI ? Colors.green : Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                _isQuicUI ? 'QuicUI SDK Detected! ✅' : 'Standard Flutter SDK ⚠️',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _isQuicUI ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SDK Information:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          _sdkInfo,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isQuicUI)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.rocket_launch, color: Colors.green, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Code Push Ready!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'This app can receive OTA updates',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'QuicUI SDK Required',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Please use QuicUI Flutter SDK for Code Push',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringRepeat on String {
  String repeat(int count) => List.filled(count, this).join();
}
