/// Phase 4 Schema Definitions: Navigation Widgets JSON Schema Validation
/// Provides type checking and property validation for all navigation widgets

class Phase4Schemas {
  /// Navigation Rail schema with destinations and styling
  static Map<String, dynamic> navigationRailSchema = {
    'type': 'object',
    'properties': {
      'destinations': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'label': {'type': 'string'},
            'icon': {'type': 'string'},
          },
          'required': ['label', 'icon'],
        },
      },
      'selectedIndex': {'type': 'integer', 'minimum': 0},
      'extended': {'type': 'boolean'},
      'groupAlignment': {'type': 'number', 'minimum': -1, 'maximum': 1},
      'backgroundColor': {'type': 'string', 'pattern': r'^#[0-9A-Fa-f]{6}$'},
      'minWidth': {'type': 'number', 'minimum': 50},
      'minExtendedWidth': {'type': 'number', 'minimum': 150},
      'leading': {'type': 'boolean'},
      'trailing': {'type': 'boolean'},
    },
    'required': ['destinations'],
  };

  /// Breadcrumb schema for hierarchical navigation
  static Map<String, dynamic> breadcrumbSchema = {
    'type': 'object',
    'properties': {
      'items': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'label': {'type': 'string'},
            'onTap': {'type': 'boolean'},
          },
          'required': ['label'],
        },
      },
      'separator': {'type': 'string'},
      'fontSize': {'type': 'number', 'minimum': 8, 'maximum': 48},
      'spacing': {'type': 'number', 'minimum': 0},
    },
    'required': ['items'],
  };

  /// Breadcrumb Item schema
  static Map<String, dynamic> breadcrumbItemSchema = {
    'type': 'object',
    'properties': {
      'label': {'type': 'string'},
      'isClickable': {'type': 'boolean'},
    },
    'required': ['label'],
  };

  /// Stacked Navigation schema with screen definitions
  static Map<String, dynamic> stackedNavigationSchema = {
    'type': 'object',
    'properties': {
      'screens': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'title': {'type': 'string'},
            'content': {'type': 'string'},
          },
          'required': ['title'],
        },
      },
      'currentIndex': {'type': 'integer', 'minimum': 0},
      'animationDuration': {'type': 'integer', 'minimum': 0, 'maximum': 5000},
    },
    'required': ['screens'],
  };

  /// Navigation Stack schema for back navigation
  static Map<String, dynamic> navigationStackSchema = {
    'type': 'object',
    'properties': {
      'stack': {
        'type': 'array',
        'items': {'type': 'string'},
      },
    },
    'required': ['stack'],
  };

  /// Drawer Navigation schema with menu items
  static Map<String, dynamic> drawerNavigationSchema = {
    'type': 'object',
    'properties': {
      'items': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'label': {'type': 'string'},
            'icon': {'type': 'string'},
          },
          'required': ['label'],
        },
      },
      'headerTitle': {'type': 'string'},
      'backgroundColor': {'type': 'string', 'pattern': r'^#[0-9A-Fa-f]{6}$'},
    },
    'required': ['items'],
  };

  /// Menu Bar schema with menu items and submenus
  static Map<String, dynamic> menuBarSchema = {
    'type': 'object',
    'properties': {
      'items': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'label': {'type': 'string'},
            'subItems': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'label': {'type': 'string'},
                },
              },
            },
          },
          'required': ['label'],
        },
      },
      'backgroundColor': {'type': 'string', 'pattern': r'^#[0-9A-Fa-f]{6}$'},
      'height': {'type': 'number', 'minimum': 40, 'maximum': 100},
    },
    'required': ['items'],
  };

  /// Side Bar schema with collapsible items
  static Map<String, dynamic> sideBarSchema = {
    'type': 'object',
    'properties': {
      'items': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'label': {'type': 'string'},
            'expanded': {'type': 'boolean'},
            'subItems': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'label': {'type': 'string'},
                },
              },
            },
          },
          'required': ['label'],
        },
      },
      'width': {'type': 'number', 'minimum': 150, 'maximum': 500},
      'backgroundColor': {'type': 'string', 'pattern': r'^#[0-9A-Fa-f]{6}$'},
    },
    'required': ['items'],
  };

  /// Context Menu schema with action items
  static Map<String, dynamic> contextMenuSchema = {
    'type': 'object',
    'properties': {
      'items': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'label': {'type': 'string'},
            'icon': {'type': 'string'},
          },
          'required': ['label'],
        },
      },
      'triggerText': {'type': 'string'},
    },
    'required': ['items'],
  };

  /// Advanced Bottom Navigation schema with badges
  static Map<String, dynamic> advancedBottomNavSchema = {
    'type': 'object',
    'properties': {
      'items': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'label': {'type': 'string'},
            'icon': {'type': 'string'},
            'badge': {'type': 'string'},
          },
          'required': ['label', 'icon'],
        },
      },
      'selectedIndex': {'type': 'integer', 'minimum': 0},
      'backgroundColor': {'type': 'string', 'pattern': r'^#[0-9A-Fa-f]{6}$'},
    },
    'required': ['items'],
  };

  /// Enhanced TabBar schema with animated indicators
  static Map<String, dynamic> tabBarEnhancedSchema = {
    'type': 'object',
    'properties': {
      'tabs': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'label': {'type': 'string'},
          },
          'required': ['label'],
        },
      },
      'selectedIndex': {'type': 'integer', 'minimum': 0},
      'indicatorColor': {'type': 'string', 'pattern': r'^#[0-9A-Fa-f]{6}$'},
      'backgroundColor': {'type': 'string', 'pattern': r'^#[0-9A-Fa-f]{6}$'},
    },
    'required': ['tabs'],
  };

  /// Animated Drawer schema with smooth transitions
  static Map<String, dynamic> animatedDrawerSchema = {
    'type': 'object',
    'properties': {
      'items': {
        'type': 'array',
        'items': {'type': 'string'},
      },
      'isOpen': {'type': 'boolean'},
      'animationDuration': {'type': 'integer', 'minimum': 0, 'maximum': 5000},
    },
    'required': ['items'],
  };

  /// Pagination Navigation schema
  static Map<String, dynamic> paginationNavSchema = {
    'type': 'object',
    'properties': {
      'currentPage': {'type': 'integer', 'minimum': 1},
      'totalPages': {'type': 'integer', 'minimum': 1},
      'maxButtons': {'type': 'integer', 'minimum': 1, 'maximum': 20},
      'backgroundColor': {'type': 'string', 'pattern': r'^#[0-9A-Fa-f]{6}$'},
    },
    'required': ['currentPage', 'totalPages'],
  };

  /// Validate widget properties against schema
  static Map<String, dynamic> validateProperties(
    String widgetType,
    Map<String, dynamic> properties,
  ) {
    final schemas = {
      'NavigationRail': navigationRailSchema,
      'Breadcrumb': breadcrumbSchema,
      'BreadcrumbItem': breadcrumbItemSchema,
      'StackedNavigation': stackedNavigationSchema,
      'NavigationStack': navigationStackSchema,
      'DrawerNavigation': drawerNavigationSchema,
      'MenuBar': menuBarSchema,
      'SideBar': sideBarSchema,
      'ContextMenu': contextMenuSchema,
      'AdvancedBottomNav': advancedBottomNavSchema,
      'TabBarEnhanced': tabBarEnhancedSchema,
      'AnimatedDrawer': animatedDrawerSchema,
      'PaginationNav': paginationNavSchema,
    };

    final schema = schemas[widgetType];
    if (schema == null) {
      return {'valid': false, 'error': 'Unknown widget type: $widgetType'};
    }

    // Validate required properties
    final requiredFields = schema['required'] as List<dynamic>? ?? [];
    for (final field in requiredFields) {
      if (!properties.containsKey(field)) {
        return {'valid': false, 'error': 'Missing required field: $field'};
      }
    }

    // Validate property types
    final propSchemas = schema['properties'] as Map<String, dynamic>? ?? {};
    for (final entry in properties.entries) {
      final key = entry.key;
      final value = entry.value;
      final propSchema = propSchemas[key] as Map<String, dynamic>?;

      if (propSchema != null) {
        final typeError = _validateType(key, value, propSchema);
        if (typeError != null) {
          return {'valid': false, 'error': typeError};
        }
      }
    }

    return {'valid': true, 'message': 'Properties valid for $widgetType'};
  }

  static String? _validateType(String key, dynamic value, Map<String, dynamic> schema) {
    final type = schema['type'] as String?;

    if (type == 'array' && value is! List) {
      return 'Property $key must be an array';
    }
    if (type == 'object' && value is! Map) {
      return 'Property $key must be an object';
    }
    if (type == 'string' && value is! String) {
      return 'Property $key must be a string';
    }
    if (type == 'integer' && value is! int && value is! num) {
      return 'Property $key must be an integer';
    }
    if (type == 'number' && value is! num) {
      return 'Property $key must be a number';
    }
    if (type == 'boolean' && value is! bool) {
      return 'Property $key must be a boolean';
    }

    // Validate numeric ranges
    if (schema.containsKey('minimum') && value is num) {
      final min = schema['minimum'] as num;
      if (value < min) {
        return 'Property $key must be >= $min';
      }
    }
    if (schema.containsKey('maximum') && value is num) {
      final max = schema['maximum'] as num;
      if (value > max) {
        return 'Property $key must be <= $max';
      }
    }

    // Validate patterns
    if (schema.containsKey('pattern') && value is String) {
      final pattern = RegExp(schema['pattern'] as String);
      if (!pattern.hasMatch(value)) {
        return 'Property $key does not match required pattern';
      }
    }

    return null;
  }

  /// Get all Phase 4 schemas
  static Map<String, Map<String, dynamic>> getAllSchemas() => {
    'NavigationRail': navigationRailSchema,
    'Breadcrumb': breadcrumbSchema,
    'BreadcrumbItem': breadcrumbItemSchema,
    'StackedNavigation': stackedNavigationSchema,
    'NavigationStack': navigationStackSchema,
    'DrawerNavigation': drawerNavigationSchema,
    'MenuBar': menuBarSchema,
    'SideBar': sideBarSchema,
    'ContextMenu': contextMenuSchema,
    'AdvancedBottomNav': advancedBottomNavSchema,
    'TabBarEnhanced': tabBarEnhancedSchema,
    'AnimatedDrawer': animatedDrawerSchema,
    'PaginationNav': paginationNavSchema,
  };
}
