import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:quicui/quicui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final jsonString =
      await rootBundle.loadString('assets/screens.json');
  final appConfig = jsonDecode(jsonString);
  runApp(QuicUIApp(config: appConfig));
}

class QuicUIApp extends StatefulWidget {
  final Map<String, dynamic> config;

  const QuicUIApp({Key? key, required this.config}) : super(key: key);

  @override
  State<QuicUIApp> createState() => _QuicUIAppState();
}

class _QuicUIAppState extends State<QuicUIApp> {
  late String currentScreenId;
  late List<dynamic> screens;

  @override
  void initState() {
    super.initState();
    screens = widget.config['screens'] as List? ?? [];
    currentScreenId = screens.isNotEmpty ? screens[0]['id'] : 'home';
  }

  void _handleNavigation(String screenId) {
    setState(() {
      currentScreenId = screenId;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get current screen
    final currentScreen = screens.firstWhere(
      (s) => s['id'] == currentScreenId,
      orElse: () => screens.isNotEmpty ? screens[0] : {},
    ) as Map<String, dynamic>;

    // Use the app-level MaterialApp config from JSON, inject current screen as home
    final appConfig = widget.config['app'] as Map<String, dynamic>? ?? {};
    final materialAppConfig = Map<String, dynamic>.from(appConfig);
    materialAppConfig['children'] = [currentScreen];

    // Inject navigation callback into the app config for screen switching
    materialAppConfig['onNavigateTo'] = (String screenId) {
      _handleNavigation(screenId);
    };

    // Render MaterialApp from JSON using QuicUI
    return QuicUI.render(materialAppConfig);
  }
}
