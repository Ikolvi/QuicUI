/// App-Level Widget Builders
/// 
/// Handles rendering of top-level application widgets:
/// - MaterialApp: Application root
/// - Scaffold: Material Design layout
/// - AppBar and bottom app bar widgets
/// - Navigation and drawer widgets
/// - Tab and bottom navigation

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'parse_utils.dart';

/// Provides app-level widget rendering
/// 
/// These are typically used at the root or top-level of the application
class AppLevelWidgets {
  /// Build MaterialApp - Application root
  static Widget buildMaterialApp(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    Map<String, dynamic> config,
    BuildContext? context,
  ) {
    // Check for explicit "home" key in config first
    Widget? home;
    if (config['home'] is Map<String, dynamic>) {
      final homeConfig = Map<String, dynamic>.from(config['home'] as Map<String, dynamic>);
      if (config['onNavigateTo'] != null) {
        homeConfig['onNavigateTo'] = config['onNavigateTo'];
      }
      if (config['navigationData'] != null) {
        homeConfig['navigationData'] = config['navigationData'];
      }
      // Note: render() must be called from UIRenderer context
      home = _renderFromConfig(homeConfig, context);
    } else if (childrenData.isNotEmpty) {
      final childConfig = Map<String, dynamic>.from(childrenData.first as Map<String, dynamic>);
      if (config['onNavigateTo'] != null) {
        childConfig['onNavigateTo'] = config['onNavigateTo'];
      }
      if (config['navigationData'] != null) {
        childConfig['navigationData'] = config['navigationData'];
      }
      home = _renderFromConfig(childConfig, context);
    }

    // Theme configuration
    final themeConfig = config['theme'] as Map<String, dynamic>?;
    ThemeData? theme;

    if (themeConfig != null) {
      final primaryColorStr = themeConfig['primaryColor'] as String? ?? '#1E88E5';
      final primaryColor = ParseUtils.parseColor(primaryColorStr) ?? Colors.blue;
      final useMaterial3 = themeConfig['useMaterial3'] as bool? ?? true;
      final brightness = themeConfig['brightness'] == 'dark' ? Brightness.dark : Brightness.light;

      theme = ThemeData(
        primarySwatch: ParseUtils.colorToMaterialColor(primaryColor),
        useMaterial3: useMaterial3,
        brightness: brightness,
      );
    }

    return MaterialApp(
      title: properties['title'] as String? ?? 'QuicUI App',
      theme: theme ?? ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: home ?? const Scaffold(body: Placeholder()),
      debugShowCheckedModeBanner: properties['debugShowCheckedModeBanner'] as bool? ?? false,
    );
  }

  /// Build Scaffold - Material Design layout with app bar, body, FAB, etc.
  static Widget buildScaffold(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    Map<String, dynamic> config,
    BuildContext? context,
  ) {
    PreferredSizeWidget? appBar;
    Widget? body;
    Widget? floatingActionButton;
    Widget? bottomNavigationBar;

    for (final child in childrenData) {
      final childMap = Map<String, dynamic>.from(child as Map<String, dynamic>);

      // Pass navigation callbacks to children
      if (config['onNavigateTo'] != null) {
        childMap['onNavigateTo'] = config['onNavigateTo'];
      }
      if (config['onFlowNavigate'] != null) {
        childMap['onFlowNavigate'] = config['onFlowNavigate'];
      }
      if (config['onExecuteCallback'] != null) {
        childMap['onExecuteCallback'] = config['onExecuteCallback'];
      }
      if (config['onUpdateNavigationData'] != null) {
        childMap['onUpdateNavigationData'] = config['onUpdateNavigationData'];
      }
      if (config['onGoBack'] != null) {
        childMap['onGoBack'] = config['onGoBack'];
      }
      if (config['navigationData'] != null) {
        childMap['navigationData'] = config['navigationData'];
      }

      final type = childMap['type'] as String;

      switch (type) {
        case 'AppBar':
          appBar = _renderFromConfig(childMap, context) as PreferredSizeWidget?;
          break;
        case 'FloatingActionButton':
          floatingActionButton = _renderFromConfig(childMap, context);
          break;
        case 'BottomNavigationBar':
          bottomNavigationBar = _renderFromConfig(childMap, context);
          break;
        default:
          body = _renderFromConfig(childMap, context);
          break;
      }
    }

    // Handle legacy config format
    final appBarConfig = config['appBar'] as Map<String, dynamic>?;
    final floatingActionButtonConfig = config['fab'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: appBar ?? (appBarConfig != null ? buildAppBar((appBarConfig['properties'] as Map<String, dynamic>?) ?? {}, [], context) as PreferredSizeWidget? : null),
      body: body,
      floatingActionButton: floatingActionButton ?? (floatingActionButtonConfig != null ? buildFloatingActionButton((floatingActionButtonConfig['properties'] as Map<String, dynamic>?) ?? {}) : null),
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  /// Build AppBar - Material Design application bar
  static Widget buildAppBar(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    return AppBar(
      title: Text(properties['title'] as String? ?? ''),
      centerTitle: properties['centerTitle'] as bool? ?? false,
      backgroundColor: ParseUtils.parseColor(properties['backgroundColor']),
      elevation: (properties['elevation'] as num?)?.toDouble(),
    );
  }

  /// Build BottomAppBar - Material Design bottom app bar
  static Widget buildBottomAppBar(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    // Note: renderList() must be called from UIRenderer context
    final children = _renderListFromConfigs(childrenData, context);
    return BottomAppBar(
      child: Row(children: children),
    );
  }

  /// Build Drawer - Navigation drawer
  static Widget buildDrawer(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final children = _renderListFromConfigs(childrenData, context);
    return Drawer(
      child: ListView(children: children),
    );
  }

  /// Build FloatingActionButton - Material Design FAB
  static Widget buildFloatingActionButton(Map<String, dynamic> properties) {
    return FloatingActionButton(
      onPressed: () => _handleButtonPress(properties['onPressed'] as String? ?? ''),
      child: Icon(ParseUtils.parseIconData(properties['icon'] as String? ?? 'add')),
    );
  }

  /// Build NavigationBar - Material 3 navigation bar
  static Widget buildNavigationBar(Map<String, dynamic> properties) {
    return NavigationBar(
      onDestinationSelected: (int index) {},
      selectedIndex: 0,
      destinations: [],
    );
  }

  /// Build TabBar - Material Design tab bar
  static Widget buildTabBar(Map<String, dynamic> properties) {
    return const TabBar(tabs: []);
  }

  // ===== PRIVATE HELPER METHODS =====

  /// Placeholder for rendering widget from config
  /// This should be injected or called through UIRenderer
  static Widget _renderFromConfig(Map<String, dynamic> config, BuildContext? context) {
    // This is a placeholder - in real implementation, this would call UIRenderer.render()
    // For now, return a placeholder
    return const Placeholder();
  }

  /// Placeholder for rendering list of widgets from configs
  static List<Widget> _renderListFromConfigs(List<dynamic> configs, BuildContext? context) {
    // Placeholder - would call UIRenderer.renderList() in real implementation
    return [];
  }

  /// Handle button press actions
  static void _handleButtonPress(String action) {
    // Placeholder for button press handling
    if (kDebugMode) {
      print('Button pressed: $action');
    }
  }
}
