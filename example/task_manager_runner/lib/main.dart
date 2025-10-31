import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quicui/quicui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _loadJsonApp(),
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

  Future<Widget> _loadJsonApp() async {
    // Load and parse JSON in compute isolate for better performance
    final jsonString = await rootBundle.loadString('assets/screens.json');
    
    return compute(_buildJsonApp, jsonString);
  }

  static Future<Widget> _buildJsonApp(String jsonString) async {
    final screenData = jsonDecode(jsonString) as Map<String, dynamic>;
    
    // Extract app configuration
    final appName = screenData['appName'] ?? 'QuicUI App';
    final theme = screenData['theme'] as Map<String, dynamic>? ?? {};
    
    // Get the first screen
    final screens = (screenData['screens'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final firstScreen = screens.isNotEmpty ? screens[0] : <String, dynamic>{};
    
    // Build MaterialApp as a Dart widget with JSON rendered home
    return _MaterialAppWithJsonHome(
      title: appName,
      theme: theme,
      homeJson: firstScreen,
    );
  }
}

class _MaterialAppWithJsonHome extends StatelessWidget {
  final String title;
  final Map<String, dynamic> theme;
  final Map<String, dynamic> homeJson;

  const _MaterialAppWithJsonHome({
    required this.title,
    required this.theme,
    required this.homeJson,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: _parseColor(theme['primaryColor'] as String? ?? '#1E88E5'),
        scaffoldBackgroundColor: _parseColor(theme['backgroundColor'] as String? ?? '#FAFAFA'),
      ),
      home: UIRenderer.render(homeJson),
    );
  }

  Color _parseColor(String colorString) {
    if (!colorString.startsWith('#')) return Colors.blue;
    final hexString = colorString.substring(1);
    return Color(int.parse('FF$hexString', radix: 16));
  }
}
