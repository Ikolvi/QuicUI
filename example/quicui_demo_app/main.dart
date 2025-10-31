import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:quicui/quicui.dart';

void main() {
  runApp(const QuicUIExampleApp());
}

class QuicUIExampleApp extends StatefulWidget {
  const QuicUIExampleApp({Key? key}) : super(key: key);

  @override
  State<QuicUIExampleApp> createState() => _QuicUIExampleAppState();
}

class _QuicUIExampleAppState extends State<QuicUIExampleApp> {
  Map<String, dynamic>? appConfig;
  String currentScreenId = 'home';
  int currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAppConfig();
  }

  Future<void> _loadAppConfig() async {
    try {
      final jsonString =
          await rootBundle.loadString('example/quicui_demo_app/app_screens.json');
      final config = jsonDecode(jsonString);
      setState(() {
        appConfig = config;
      });
    } catch (e) {
      print('Error loading app config: $e');
    }
  }

  void _onTabChanged(int index) {
    if (appConfig != null && appConfig!['navigation'] != null) {
      final tabs = appConfig!['navigation']['tabs'] as List;
      if (index < tabs.length) {
        final screenId = tabs[index]['screenId'];
        setState(() {
          currentTabIndex = index;
          currentScreenId = screenId;
        });
      }
    }
  }

  Widget _buildScreen(Map<String, dynamic> screenConfig) {
    final screenType = screenConfig['type'] as String?;
    final children = screenConfig['children'] as List? ?? [];

    if (screenType == 'Scaffold' && children.isNotEmpty) {
      return Scaffold(
        appBar: _buildAppBar(children),
        body: _buildBody(children),
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(screenConfig['name'] ?? 'Screen')),
      body: Center(child: Text('Unknown screen type: $screenType')),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget? _buildAppBar(List<dynamic> children) {
    for (final child in children) {
      if (child is Map<String, dynamic> && child['type'] == 'AppBar') {
        return UIRenderer.render(child) as PreferredSizeWidget?;
      }
    }
    return null;
  }

  Widget _buildBody(List<dynamic> children) {
    for (final child in children) {
      if (child is Map<String, dynamic> && child['type'] != 'AppBar') {
        return UIRenderer.render(child);
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildBottomNav() {
    if (appConfig?['navigation'] == null) {
      return const SizedBox.shrink();
    }

    final tabs = (appConfig!['navigation']['tabs'] as List?)?.cast<Map>() ?? [];

    return BottomNavigationBar(
      currentIndex: currentTabIndex,
      onTap: _onTabChanged,
      items: tabs
          .map((tab) => BottomNavigationBarItem(
                icon: Icon(_getIconData(tab['icon'] ?? 'home')),
                label: tab['label'] ?? '',
              ))
          .toList(),
    );
  }

  IconData _getIconData(String iconName) {
    const iconMap = {
      'home': Icons.home,
      'dashboard': Icons.dashboard,
      'widgets': Icons.widgets,
      'description': Icons.description,
      'settings': Icons.settings,
      'person': Icons.person,
      'shopping_cart': Icons.shopping_cart,
      'notifications': Icons.notifications,
    };
    return iconMap[iconName] ?? Icons.help;
  }

  @override
  Widget build(BuildContext context) {
    if (appConfig == null) {
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('QuicUI Example')),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final screens =
        (appConfig!['screens'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final currentScreen = screens.isNotEmpty
        ? screens.firstWhere(
            (s) => s['id'] == currentScreenId,
            orElse: () => screens.first,
          )
        : <String, dynamic>{};

    return MaterialApp(
      title: appConfig!['appName'] ?? 'QuicUI Demo',
      theme: ThemeData(
        primaryColor: _parseColor(appConfig!['theme']?['primaryColor']),
        useMaterial3: true,
      ),
      home: _buildScreen(currentScreen),
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
