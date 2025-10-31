import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quicui/quicui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<Widget> _appFuture;

  @override
  void initState() {
    super.initState();
    _appFuture = _loadApp();
  }

  Future<Widget> _loadApp() async {
    final jsonString = await rootBundle.loadString('assets/screens.json');
    final appJson = jsonDecode(jsonString) as Map<String, dynamic>;
    return UIRenderer.render(appJson);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _appFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading app...'),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Error loading app'),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString()),
                  ],
                ),
              ),
            ),
          );
        }

        return snapshot.data ?? const SizedBox();
      },
    );
  }
}
