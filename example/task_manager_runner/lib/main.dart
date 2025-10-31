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
    // Set initial screen from config
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
          body: Center(
            child: Text('Screen "$currentScreen" not found'),
          ),
        ),
      );
    }

    // Build the app with navigation callback
    return MaterialApp(
      title: widget.config['properties']?['title'] ?? 'App',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(widget.config),
      home: _buildScreen(screenConfig, navigationData, context),
    );
  }

  Widget _buildScreen(
    Map<String, dynamic> screenConfig,
    Map<String, dynamic> navData,
    BuildContext context,
  ) {
    // Inject navigation callback into the screen config
    final enhancedConfig = Map<String, dynamic>.from(screenConfig);
    enhancedConfig['onNavigateTo'] = (String screen, {Map<String, dynamic>? data}) {
      navigateToScreen(screen, data: data);
    };
    enhancedConfig['navigationData'] = navData;

    return UIRenderer.render(enhancedConfig, context: context);
  }

  ThemeData _buildTheme(Map<String, dynamic> config) {
    final themeConfig = config['theme'] as Map<String, dynamic>?;
    if (themeConfig != null) {
      final primaryColorStr = themeConfig['primaryColor'] as String? ?? '#6366F1';
      final primaryColor = _parseColor(primaryColorStr) ?? Colors.indigo;

      return ThemeData(
        primarySwatch: _colorToMaterialColor(primaryColor),
        useMaterial3: true,
        brightness: Brightness.light,
      );
    }
    return ThemeData(primarySwatch: Colors.blue, useMaterial3: true);
  }

  Color? _parseColor(String? colorStr) {
    if (colorStr == null) return null;
    if (colorStr.startsWith('#')) {
      final hexColor = colorStr.replaceFirst('#', '');
      final colorString = hexColor.length == 6 ? 'FF$hexColor' : hexColor.padLeft(8, '0');
      return Color(int.parse('0x$colorString'));
    }
    return null;
  }

  MaterialColor _colorToMaterialColor(Color color) {
    final int red = (color.r * 255.0).round() & 0xff;
    final int green = (color.g * 255.0).round() & 0xff;
    final int blue = (color.b * 255.0).round() & 0xff;

    final Map<int, Color> shades = {
      50: Color.fromRGBO(red, green, blue, .1),
      100: Color.fromRGBO(red, green, blue, .2),
      200: Color.fromRGBO(red, green, blue, .3),
      300: Color.fromRGBO(red, green, blue, .4),
      400: Color.fromRGBO(red, green, blue, .5),
      500: Color.fromRGBO(red, green, blue, .6),
      600: Color.fromRGBO(red, green, blue, .7),
      700: Color.fromRGBO(red, green, blue, .8),
      800: Color.fromRGBO(red, green, blue, .9),
      900: Color.fromRGBO(red, green, blue, 1),
    };

    return MaterialColor(color.toARGB32(), shades);
  }
}
