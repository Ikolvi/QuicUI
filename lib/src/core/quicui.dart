/// Main QuicUI entry point and API
///
/// This class provides the primary API for QuicUI framework.
/// It acts as a clean, simple interface for rendering JSON-based UIs.
///
/// ## Usage
///
/// ### Basic rendering:
/// ```dart
/// final widget = QuicUI.render(jsonConfig);
/// ```
///
/// ### With context:
/// ```dart
/// final widget = QuicUI.render(jsonConfig, context: context);
/// ```
///
/// ### Complete app:
/// ```dart
/// runApp(QuicUI.render({
///   "type": "MaterialApp",
///   "properties": {"title": "My App"},
///   "children": [screenConfig]
/// }));
/// ```

import 'package:flutter/material.dart';
import '../rendering/ui_renderer.dart';

/// Main QuicUI class providing the primary API for the framework
class QuicUI {
  /// Renders a Flutter widget from JSON configuration
  ///
  /// This is the main entry point for QuicUI rendering.
  /// Takes a JSON configuration and returns a Flutter [Widget].
  ///
  /// **Parameters:**
  /// - [config]: JSON configuration map defining the widget structure
  /// - [context]: Optional BuildContext for context-dependent widgets
  ///
  /// **Returns:**
  /// A fully rendered Flutter [Widget] based on the JSON configuration
  ///
  /// **Example:**
  /// ```dart
  /// final config = {
  ///   "type": "MaterialApp",
  ///   "properties": {
  ///     "title": "My App",
  ///     "debugShowCheckedModeBanner": false
  ///   },
  ///   "children": [
  ///     {
  ///       "type": "Scaffold",
  ///       "children": [
  ///         {
  ///           "type": "Text",
  ///           "properties": {"text": "Hello QuicUI!"}
  ///         }
  ///       ]
  ///     }
  ///   ]
  /// };
  ///
  /// final app = QuicUI.render(config);
  /// runApp(app);
  /// ```
  static Widget render(Map<String, dynamic> config, {BuildContext? context}) {
    return UIRenderer.render(config, context: context);
  }

  /// Gets the current version of QuicUI
  static String get version => '1.0.4';

  /// Gets framework information
  static Map<String, dynamic> get info => {
    'name': 'QuicUI',
    'version': version,
    'description': 'Server-Driven UI Framework for Flutter',
    'supportedWidgets': 70,
    'jsonDriven': true,
  };
}