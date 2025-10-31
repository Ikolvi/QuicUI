import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:quicui/quicui.dart';

void main() {
  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({Key? key}) : super(key: key);

  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  Map<String, dynamic>? appConfig;
  String currentScreenId = 'tasks_home';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final jsonString =
          await rootBundle.loadString('example/task_manager_app/screens.json');
      final config = jsonDecode(jsonString);
      setState(() {
        appConfig = config;
      });
    } catch (e) {
      print('Error loading config: $e');
    }
  }

  void _onNavigation(String screenId) {
    setState(() {
      currentScreenId = screenId;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (appConfig == null) {
      return MaterialApp(
        title: 'TaskManager Pro',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Get current screen config (already contains complete Scaffold)
    final screens = appConfig!['screens'] as List? ?? [];
    final screenConfig = screens.firstWhere(
      (s) => s['id'] == currentScreenId,
      orElse: () => screens.isNotEmpty ? screens.first : {},
    ) as Map<String, dynamic>;

    // Add navigation callback to screen config
    screenConfig['onNavigation'] = _onNavigation;

    return MaterialApp(
      title: appConfig!['appName'] ?? 'TaskManager Pro',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: UIRenderer.render(screenConfig),
    );
  }

  ThemeData _buildTheme() {
    final theme = appConfig!['theme'] as Map? ?? {};
    final primaryColor = _parseColor(theme['primaryColor']);
    
    return ThemeData(
      primaryColor: primaryColor,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
    );
  }

  Color _parseColor(dynamic colorValue) {
    if (colorValue == null) return Colors.blue;
    if (colorValue is String) {
      try {
        return Color(int.parse(colorValue.replaceFirst('#', '0xFF')));
      } catch (e) {
        return Colors.blue;
      }
    }
    return Colors.blue;
  }
}
