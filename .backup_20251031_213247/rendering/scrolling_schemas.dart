/// Phase 3 Widget Schemas
/// 
/// Complete JSON schema definitions for all Phase 3 layout and advanced widgets

class Phase3Schemas {
  /// CustomScrollView Schema
  static const Map<String, dynamic> customScrollViewSchema = {
    'type': 'CustomScrollView',
    'description': 'Advanced scrolling with mixed scroll effects',
    'properties': {
      'slivers': {
        'type': 'array',
        'description': 'Array of sliver widgets',
        'default': [],
      },
    }
  };

  /// SliverList Schema
  static const Map<String, dynamic> sliverListSchema = {
    'type': 'SliverList',
    'description': 'Efficient list of items in CustomScrollView',
    'properties': {
      'itemCount': {
        'type': 'number',
        'description': 'Number of items in list',
        'default': 0,
      },
      'itemExtent': {
        'type': 'number',
        'description': 'Height of each item',
        'default': null,
      },
    }
  };

  /// SliverGrid Schema
  static const Map<String, dynamic> sliverGridSchema = {
    'type': 'SliverGrid',
    'description': 'Efficient grid of items in CustomScrollView',
    'properties': {
      'crossAxisCount': {
        'type': 'number',
        'description': 'Number of columns',
        'default': 2,
      },
      'childAspectRatio': {
        'type': 'number',
        'description': 'Aspect ratio of grid items',
        'default': 1.0,
      },
      'crossAxisSpacing': {
        'type': 'number',
        'description': 'Horizontal spacing between items',
        'default': 8.0,
      },
      'mainAxisSpacing': {
        'type': 'number',
        'description': 'Vertical spacing between items',
        'default': 8.0,
      },
    }
  };

  /// Flow Schema
  static const Map<String, dynamic> flowSchema = {
    'type': 'Flow',
    'description': 'Advanced layout for overlapping widgets',
    'properties': {
      'offsetX': {
        'type': 'number',
        'description': 'X offset for children',
        'default': 0.0,
      },
      'offsetY': {
        'type': 'number',
        'description': 'Y offset for children',
        'default': 0.0,
      },
      'spacing': {
        'type': 'number',
        'description': 'Spacing between children',
        'default': 10.0,
      },
    }
  };

  /// LayoutBuilder Schema
  static const Map<String, dynamic> layoutBuilderSchema = {
    'type': 'LayoutBuilder',
    'description': 'Responsive layout based on parent constraints',
    'properties': {
      'backgroundColor': {
        'type': 'color',
        'description': 'Background color (hex)',
        'default': '#FFFFFF',
      },
      'padding': {
        'type': 'number',
        'description': 'Padding around content',
        'default': 16.0,
      },
      'gapWidth': {
        'type': 'number',
        'description': 'Gap between wide layout sections',
        'default': 16.0,
      },
    }
  };

  /// MediaQuery Helper Schema
  static const Map<String, dynamic> mediaQueryHelperSchema = {
    'type': 'MediaQueryHelper',
    'description': 'Responsive design widget using MediaQuery',
    'properties': {
      'child': {
        'type': 'object',
        'description': 'Child widget',
        'default': null,
      },
    }
  };

  /// ResponsiveWidget Schema
  static const Map<String, dynamic> responsiveWidgetSchema = {
    'type': 'ResponsiveWidget',
    'description': 'Automatically adapts to screen size',
    'properties': {
      'backgroundColor': {
        'type': 'color',
        'description': 'Background color (hex)',
        'default': '#FFFFFF',
      },
      'padding': {
        'type': 'number',
        'description': 'Padding',
        'default': 16.0,
      },
      'fontSize': {
        'type': 'number',
        'description': 'Font size for display text',
        'default': 16.0,
      },
    }
  };

  /// Advanced SliverAppBar Schema
  static const Map<String, dynamic> advancedSliverAppBarSchema = {
    'type': 'AdvancedSliverAppBar',
    'description': 'Advanced app bar with scroll effects',
    'properties': {
      'title': {
        'type': 'string',
        'description': 'AppBar title',
        'default': 'Title',
      },
      'expandedHeight': {
        'type': 'number',
        'description': 'Height when expanded',
        'default': 200.0,
      },
      'floating': {
        'type': 'boolean',
        'description': 'AppBar floats back on scroll up',
        'default': false,
      },
      'pinned': {
        'type': 'boolean',
        'description': 'AppBar stays at top',
        'default': true,
      },
      'snap': {
        'type': 'boolean',
        'description': 'AppBar snaps in/out',
        'default': false,
      },
      'backgroundColor': {
        'type': 'color',
        'description': 'Background color (hex)',
        'default': '#2196F3',
      },
      'description': {
        'type': 'string',
        'description': 'Content description below',
        'default': 'Content below',
      },
    }
  };

  /// NestedScrollView Schema
  static const Map<String, dynamic> nestedScrollViewSchema = {
    'type': 'NestedScrollView',
    'description': 'Multiple scroll controllers in nested layout',
    'properties': {
      'title': {
        'type': 'string',
        'description': 'AppBar title',
        'default': 'Nested Scroll',
      },
      'bodyText': {
        'type': 'string',
        'description': 'Body content text',
        'default': 'Body content here',
      },
    }
  };

  /// AnimatedBuilder Schema
  static const Map<String, dynamic> animatedBuilderSchema = {
    'type': 'AnimatedBuilder',
    'description': 'Custom animations with builder pattern',
    'properties': {
      'duration': {
        'type': 'number',
        'description': 'Animation duration in milliseconds',
        'default': 500,
      },
      'animationType': {
        'type': 'enum',
        'values': ['rotate', 'slide', 'fade', 'scale'],
        'description': 'Type of animation',
        'default': 'rotate',
      },
    }
  };

  /// TabBarView Advanced Schema
  static const Map<String, dynamic> tabBarViewAdvancedSchema = {
    'type': 'TabBarViewAdvanced',
    'description': 'Swipeable tabs with TabController',
    'properties': {
      'title': {
        'type': 'string',
        'description': 'Page title',
        'default': 'Tabs',
      },
      'tabCount': {
        'type': 'number',
        'description': 'Number of tabs',
        'default': 3,
      },
    }
  };

  /// PinchZoom Schema
  static const Map<String, dynamic> pinchZoomSchema = {
    'type': 'PinchZoom',
    'description': 'Pinch to zoom image/content',
    'properties': {
      'minScale': {
        'type': 'number',
        'description': 'Minimum zoom scale',
        'default': 0.5,
      },
      'maxScale': {
        'type': 'number',
        'description': 'Maximum zoom scale',
        'default': 4.0,
      },
      'backgroundColor': {
        'type': 'color',
        'description': 'Background color (hex)',
        'default': '#F5F5F5',
      },
      'text': {
        'type': 'string',
        'description': 'Display text',
        'default': 'Pinch to zoom',
      },
      'fontSize': {
        'type': 'number',
        'description': 'Font size',
        'default': 18.0,
      },
    }
  };

  /// VirtualizedList Schema
  static const Map<String, dynamic> virtualizedListSchema = {
    'type': 'VirtualizedList',
    'description': 'Efficient large list with virtualization',
    'properties': {
      'itemCount': {
        'type': 'number',
        'description': 'Total number of items',
        'default': 100,
      },
    }
  };

  /// Sticky Headers Schema
  static const Map<String, dynamic> stickyHeadersSchema = {
    'type': 'StickyHeaders',
    'description': 'Headers that stick to top while scrolling',
    'properties': {
      'sections': {
        'type': 'array',
        'description': 'Array of sections with headers',
        'default': [],
      },
    }
  };

  /// Get all schemas as a map
  static Map<String, Map<String, dynamic>> getAllSchemas() => {
    'customScrollView': customScrollViewSchema,
    'sliverList': sliverListSchema,
    'sliverGrid': sliverGridSchema,
    'flow': flowSchema,
    'layoutBuilder': layoutBuilderSchema,
    'mediaQueryHelper': mediaQueryHelperSchema,
    'responsiveWidget': responsiveWidgetSchema,
    'advancedSliverAppBar': advancedSliverAppBarSchema,
    'nestedScrollView': nestedScrollViewSchema,
    'animatedBuilder': animatedBuilderSchema,
    'tabBarViewAdvanced': tabBarViewAdvancedSchema,
    'pinchZoom': pinchZoomSchema,
    'virtualizedList': virtualizedListSchema,
    'stickyHeaders': stickyHeadersSchema,
  };

  /// Validate widget properties against schema
  static Map<String, dynamic> validateProperties(
    String widgetType,
    Map<String, dynamic> properties,
  ) {
    final schema = getAllSchemas()[widgetType];
    
    if (schema == null) {
      return {
        'isValid': false,
        'errors': ['Unknown widget type: $widgetType'],
      };
    }

    final errors = <String>[];
    final schemaProps = (schema['properties'] as Map<String, dynamic>?) ?? {};

    // Basic type validation
    for (final entry in properties.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (!schemaProps.containsKey(key)) {
        errors.add('Unknown property: $key');
        continue;
      }

      final propSchema = schemaProps[key] as Map<String, dynamic>;
      final expectedType = propSchema['type'] as String? ?? 'dynamic';

      // Type checking
      if (expectedType == 'number' && value is! num) {
        errors.add('Property $key must be a number');
      } else if (expectedType == 'string' && value is! String) {
        errors.add('Property $key must be a string');
      } else if (expectedType == 'boolean' && value is! bool) {
        errors.add('Property $key must be a boolean');
      } else if (expectedType == 'array' && value is! List) {
        errors.add('Property $key must be an array');
      } else if (expectedType == 'color' && value is! String) {
        errors.add('Property $key must be a color string');
      }
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
    };
  }
}
