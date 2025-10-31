import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quicui/quicui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final jsonString = await rootBundle.loadString('assets/screens.json');
  final appJson = jsonDecode(jsonString) as Map<String, dynamic>;
  runApp(QuicUIApp(config: appJson));
}

class QuicUIApp extends StatefulWidget {
  final Map<String, dynamic> config;
  const QuicUIApp({required this.config, super.key});

  @override
  State<QuicUIApp> createState() => _QuicUIAppState();
}

class _QuicUIAppState extends State<QuicUIApp> {
  late String currentScreen;
  Map<String, dynamic> navigationData = {};

  @override
  void initState() {
    super.initState();
    currentScreen = widget.config['home'] as String? ?? 'home';
  }

  void navigateToScreen(String screenName, {Map<String, dynamic>? data}) {
    setState(() {
      currentScreen = screenName;
      navigationData = data ?? {};
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = widget.config['screens'] as Map<String, dynamic>? ?? {};
    final screenConfig = screens[currentScreen] as Map<String, dynamic>?;

    if (screenConfig == null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Screen "$currentScreen" not found')),
        ),
      );
    }

    final enhancedConfig = Map<String, dynamic>.from(screenConfig);
    enhancedConfig['onNavigateTo'] = (String screen, {Map<String, dynamic>? data}) {
      navigateToScreen(screen, data: data);
    };
    enhancedConfig['navigationData'] = navigationData;

    return MaterialApp(
      title: widget.config['properties']?['title'] ?? 'App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: UIRenderer.render(enhancedConfig, context: context),
    );
  }
}
