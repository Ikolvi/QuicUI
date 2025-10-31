/// Main UI renderer implementation - 70+ Flutter widgets
/// 
/// This module provides the core rendering engine for QuicUI.
/// It converts JSON-based [WidgetData] and [Screen] configurations
/// into fully-rendered Flutter widgets.
///
/// ## Callback Action System
///
/// Supports generic callback actions via JSON:
/// - Navigate to screens
/// - Update widget state
/// - Make API calls
/// - Execute custom handlers
/// - Chain actions with onSuccess/onError
///
/// Example:
/// ```json
/// {
///   "events": {
///     "onPressed": {
///       "action": "apiCall",
library;

///       "method": "POST",
///       "endpoint": "/api/login"
///     }
///   }
/// }
/// ```
///
/// ## Widget Coverage
///
/// UIRenderer supports 70+ Flutter widgets organized by category:
///
/// ### App & Navigation (8 widgets)
/// - Scaffold, AppBar, BottomAppBar, Drawer
/// - FloatingActionButton, NavigationBar, TabBar
///
/// ### Layout (15 widgets)
/// - Column, Row, Container, Stack, Positioned
/// - Center, Padding, Align, Sized Box, Single Child Scroll View
/// - ListView, GridView, Expanded, Flexible, Wrap
///
/// ### Text & Display (8 widgets)
/// - Text, RichText, TextField, Icon, Image
/// - Card, ListTile, Divider
///
/// ### Buttons & Input (8 widgets)
/// - ElevatedButton, TextButton, OutlinedButton
/// - Checkbox, Radio, Slider, Switch, GestureDetector
///
/// ### Advanced (10+ widgets)
/// - CustomPaint, AnimatedContainer, Transform
/// - Opacity, ClipRRect, Badge, and more
///
/// ## Rendering Process
///
/// 1. **Parse:** Extract widget type and properties from JSON
/// 2. **Validate:** Check properties against widget schema
/// 3. **Build:** Create Flutter widget with parsed properties
/// 4. **Bind:** Connect state and event handlers
/// 5. **Render:** Add to widget tree
///
/// ## Example
///
/// ```dart
/// final config = {
///   'type': 'Column',
///   'properties': {
///     'mainAxisAlignment': 'center',
///     'crossAxisAlignment': 'center',
///   },
///   'children': [
///     {
///       'type': 'Text',
///       'properties': {
///         'text': 'Hello, World!',
///         'fontSize': 24,
///       },
///     },
///     {
///       'type': 'ElevatedButton',
///       'properties': {'label': 'Press Me'},
///       'events': {
///         'onPressed': {'action': 'navigate', 'screen': 'next'},
///       },
///     },
///   ],
/// };
///
/// final widget = UIRenderer.render(config);
/// ```
///
/// ## Property Support
///
/// Properties are automatically converted to appropriate types:
/// - **Colors:** `#RRGGBB` format
/// - **Numbers:** Integer or double
/// - **Enums:** String matching enum values
/// - **Objects:** Nested property maps
/// - **State Binding:** `${state.fieldName}` syntax
///
/// ## Event Handling
///
/// Events trigger actions:
/// - `onPressed`: Button tap
/// - `onChanged`: Value change
/// - `onTap`: General tap
/// - `onSubmitted`: Form submit
///
/// ## Error Handling
///
/// - Unknown widget types render as [Placeholder]
/// - Missing properties use sensible defaults
/// - Invalid values are caught and reported
/// - Errors don't crash the app
///
/// ## Performance
///
/// Rendering is optimized for:
/// - Fast initial render
/// - Efficient rebuilds
/// - Minimal widget overhead
/// - Smooth animations
///
/// See also:
/// - [WidgetFactory]: Helper for creating widgets
/// - [WidgetBuilder]: Builder utilities
/// - [UIRenderer.render]: Main render method

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/callback_actions.dart' as callback_actions;
import '../utils/logger_util.dart';
import '../utils/error_handler.dart';
import 'display_widgets.dart';
import 'widget_factory_registry.dart';

/// Main UI renderer for building Flutter widgets from JSON
///
/// Converts JSON-based widget configurations to Flutter widgets.
/// Supports 70+ widget types with full property binding and event handling.
///
/// ## Basic Usage
///
/// ```dart
/// final renderer = UIRenderer();
/// final widget = renderer.render({
///   'type': 'Text',
///   'properties': {'text': 'Hello'},
/// });
/// ```
///
/// ## Advanced Usage
///
/// ```dart
/// // With state binding
/// final widget = renderer.render(
///   config,
///   context: context,
/// );
/// ```
class UIRenderer {
  /// Global map to store field values from TextFields
  static final Map<String, TextEditingController> _fieldControllers = {};
  
  /// Render a widget tree from JSON configuration
  static Widget render(Map<String, dynamic> config, {BuildContext? context}) {
    try {
      // Validate JSON structure only in debug mode for better performance in production
      if (kDebugMode) {
        final validation = JsonValidator.validateWidgetJson(config);
        if (!validation.isValid) {
          ErrorHandler.handleValidationErrors(validation.errors, config);
          // Continue with rendering but log validation issues
        }
      }

      final type = config['type'] as String?;
      if (type == null) {
        LoggerUtil.warning('Widget type is null, rendering placeholder', config);
        return const Placeholder();
      }
      
      final shouldRender = config['shouldRender'] as bool? ?? true;
      if (!shouldRender) return const SizedBox.shrink();
      
      // CRITICAL: Log for debugging callback propagation
      LoggerUtil.debug('render() called for type: $type, has onNavigateTo: ${config['onNavigateTo'] != null}');
      
      return _renderWidgetByType(type, config, context);
    } catch (error, stackTrace) {
      return ErrorHandler.handleRenderingError(
        error,
        config,
        context: {
          'method': 'UIRenderer.render',
          'widget_type': config['type'],
        },
        stackTrace: stackTrace,
      );
    }
  }

  /// Render a list of widgets from JSON array
  static List<Widget> renderList(
    List<dynamic> widgetsData, {
    BuildContext? context,
    Map<String, dynamic>? parentConfig,
  }) {
    final widgets = <Widget>[];
    
    for (int i = 0; i < widgetsData.length; i++) {
      final data = widgetsData[i];
      if (data is Map<String, dynamic>) {
        try {
          // Inject parent config callbacks into child if not already present
          final childData = Map<String, dynamic>.from(data);
          if (parentConfig != null) {
            if (childData['onNavigateTo'] == null && parentConfig['onNavigateTo'] != null) {
              childData['onNavigateTo'] = parentConfig['onNavigateTo'];
              LoggerUtil.debug('✅ renderList injected onNavigateTo to child type: ${childData['type']}');
            }
            if (childData['onFlowNavigate'] == null && parentConfig['onFlowNavigate'] != null) {
              childData['onFlowNavigate'] = parentConfig['onFlowNavigate'];
              LoggerUtil.debug('✅ renderList injected onFlowNavigate to child type: ${childData['type']}');
            }
            if (childData['onExecuteCallback'] == null && parentConfig['onExecuteCallback'] != null) {
              childData['onExecuteCallback'] = parentConfig['onExecuteCallback'];
              LoggerUtil.debug('✅ renderList injected onExecuteCallback to child type: ${childData['type']}');
            }
            if (childData['onUpdateNavigationData'] == null && parentConfig['onUpdateNavigationData'] != null) {
              childData['onUpdateNavigationData'] = parentConfig['onUpdateNavigationData'];
              LoggerUtil.debug('✅ renderList injected onUpdateNavigationData to child type: ${childData['type']}');
            }
            if (childData['onGoBack'] == null && parentConfig['onGoBack'] != null) {
              childData['onGoBack'] = parentConfig['onGoBack'];
              LoggerUtil.debug('✅ renderList injected onGoBack to child type: ${childData['type']}');
            }
            if (childData['navigationData'] == null && parentConfig['navigationData'] != null) {
              childData['navigationData'] = parentConfig['navigationData'];
              LoggerUtil.debug('✅ renderList injected navigationData to child type: ${childData['type']}, data: ${parentConfig['navigationData']}');
            }
          }
          
          final widget = render(childData, context: context);
          widgets.add(widget);
        } catch (error, stackTrace) {
          LoggerUtil.error(
            'Failed to render widget at index $i',
            error,
            stackTrace,
          );
          // Add error widget but continue with other widgets
          widgets.add(ErrorHandler.handleRenderingError(
            error,
            data,
            context: {
              'method': 'UIRenderer.renderList',
              'widget_index': i,
              'total_widgets': widgetsData.length,
            },
            stackTrace: stackTrace,
          ));
        }
      } else {
        LoggerUtil.warning(
          'Invalid widget data at index $i: expected Map, got ${data.runtimeType}',
          data,
        );
      }
    }
    
    return widgets;
  }

  /// Helper to inject parent config into a single child config before rendering
  static Widget renderChild(
    Map<String, dynamic> childData,
    Map<String, dynamic> parentConfig,
    {BuildContext? context}
  ) {
    final data = Map<String, dynamic>.from(childData);
    if (parentConfig['onNavigateTo'] != null && data['onNavigateTo'] == null) {
      data['onNavigateTo'] = parentConfig['onNavigateTo'];
      LoggerUtil.debug('✅ renderChild injected onNavigateTo to type: ${data['type']}');
    }
    if (parentConfig['onFlowNavigate'] != null && data['onFlowNavigate'] == null) {
      data['onFlowNavigate'] = parentConfig['onFlowNavigate'];
      LoggerUtil.debug('✅ renderChild injected onFlowNavigate to type: ${data['type']}');
    }
    if (parentConfig['onExecuteCallback'] != null && data['onExecuteCallback'] == null) {
      data['onExecuteCallback'] = parentConfig['onExecuteCallback'];
      LoggerUtil.debug('✅ renderChild injected onExecuteCallback to type: ${data['type']}');
    }
    if (parentConfig['onUpdateNavigationData'] != null && data['onUpdateNavigationData'] == null) {
      data['onUpdateNavigationData'] = parentConfig['onUpdateNavigationData'];
      LoggerUtil.debug('✅ renderChild injected onUpdateNavigationData to type: ${data['type']}');
    }
    if (parentConfig['onGoBack'] != null && data['onGoBack'] == null) {
      data['onGoBack'] = parentConfig['onGoBack'];
      LoggerUtil.debug('✅ renderChild injected onGoBack to type: ${data['type']}');
    }
    if (parentConfig['navigationData'] != null && data['navigationData'] == null) {
      data['navigationData'] = parentConfig['navigationData'];
    }
    return render(data, context: context);
  }

  /// Render widget by type - 70+ widgets supported
  static Widget _renderWidgetByType(
    String type,
    Map<String, dynamic> config,
    BuildContext? context,
  ) {
    try {
      dynamic propsRaw = config['properties'];
      final Map<String, dynamic> properties = propsRaw is Map ? Map<String, dynamic>.from(propsRaw) : {};
      final childrenData = config['children'] as List? ?? [];

      // Inject callback functions into properties for buttons and interactive widgets
      LoggerUtil.debug('Before injection - properties keys: ${properties.keys.toList()}');
      LoggerUtil.debug('Config has onNavigateTo: ${config['onNavigateTo'] != null}');
      
      if (config['onNavigateTo'] != null) {
        properties['onNavigateTo'] = config['onNavigateTo'];
        LoggerUtil.debug('✅ Injected onNavigateTo into properties');
      }
      if (config['onFlowNavigate'] != null) {
        properties['onFlowNavigate'] = config['onFlowNavigate'];
        LoggerUtil.debug('✅ Injected onFlowNavigate into properties');
      }
      if (config['onExecuteCallback'] != null) {
        properties['onExecuteCallback'] = config['onExecuteCallback'];
        LoggerUtil.debug('✅ Injected onExecuteCallback into properties');
      }
      if (config['onUpdateNavigationData'] != null) {
        properties['onUpdateNavigationData'] = config['onUpdateNavigationData'];
        LoggerUtil.debug('✅ Injected onUpdateNavigationData into properties');
      }
      if (config['onGoBack'] != null) {
        properties['onGoBack'] = config['onGoBack'];
        LoggerUtil.debug('✅ Injected onGoBack into properties');
      }
      if (config['navigationData'] != null) {
        properties['navigationData'] = config['navigationData'];
        LoggerUtil.debug('✅ Injected navigationData into properties: ${config['navigationData']}');
      } else {
        LoggerUtil.debug('⚠️ config[navigationData] was null, not injecting');
      }
      
      LoggerUtil.debug('After injection - properties keys: ${properties.keys.toList()}');

      // Log debug information for widget rendering
      LoggerUtil.debug('Rendering widget: $type', {
        'properties_count': properties.length,
        'children_count': childrenData.length,
        'config_keys': config.keys.toList(),
        'has_callback': properties['onNavigateTo'] != null,
      });

      // Try registry first for consolidated widgets
      final registryBuilder = WidgetFactoryRegistry.getBuilder(type);
      if (registryBuilder != null) {
        LoggerUtil.debug('✅ Using WidgetFactoryRegistry for widget: $type');
        if (context != null) {
          return registryBuilder(properties, childrenData, context, render);
        } else {
          LoggerUtil.warning('Registry builder called without BuildContext for type: $type');
          return const Placeholder();
        }
      }

      // All basic widgets are handled by registry.
      // Fallback to error widget for unknown types
      LoggerUtil.warning(
        'Unsupported widget type: $type (not in registry)',
        {
          'widget_type': type,
          'available_properties': properties.keys.toList(),
          'suggestion': 'Check widget type spelling or register widget in WidgetFactoryRegistry',
        },
      );

      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          border: Border.all(color: Colors.orange, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, color: Colors.orange[700], size: 16),
            const SizedBox(height: 4),
            Text(
              'Unsupported: $type',
              style: TextStyle(
                color: Colors.orange[800],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } catch (error, stackTrace) {
      return ErrorHandler.handleRenderingError(
        error,
        config,
        context: {
          'method': '_renderWidgetByType',
          'widget_type': type,
          'properties_count': config['properties'] != null ? (config['properties'] as Map).length : 0,
          'children_count': config['children'] != null ? (config['children'] as List).length : 0,
        },
        stackTrace: stackTrace,
      );
    }
  }

  // ===== APP-LEVEL WIDGETS =====

}
