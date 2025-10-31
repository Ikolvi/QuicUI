/// Phase 1 Widget JSON Schemas
/// 
/// Defines JSON structure and properties for Phase 1 widgets
/// These schemas ensure proper validation and type safety

class Phase1WidgetSchemas {
  /// SliverAppBar schema
  /// 
  /// JSON Example:
  /// ```json
  /// {
  ///   "type": "SliverAppBar",
  ///   "properties": {
  ///     "title": "My App",
  ///     "expandedHeight": 200.0,
  ///     "floating": false,
  ///     "pinned": true,
  ///     "snap": false,
  ///     "backgroundColor": "#2196F3",
  ///     "foregroundColor": "#FFFFFF"
  ///   },
  ///   "children": [
  ///     {
  ///       "type": "FlexibleSpaceBar",
  ///       "properties": {"background": "..."}
  ///     }
  ///   ]
  /// }
  /// ```
  static const Map<String, dynamic> sliverAppBarSchema = {
    'title': 'SliverAppBar',
    'type': 'widget',
    'properties': {
      'title': {'type': 'string', 'required': true},
      'expandedHeight': {'type': 'number', 'default': 200.0},
      'floating': {'type': 'boolean', 'default': false},
      'pinned': {'type': 'boolean', 'default': true},
      'snap': {'type': 'boolean', 'default': false},
      'backgroundColor': {'type': 'color', 'default': '#2196F3'},
      'foregroundColor': {'type': 'color', 'default': '#FFFFFF'},
    },
    'children': {'min': 0, 'max': 1},
    'events': ['onScroll'],
  };

  /// BottomSheet schema
  static const Map<String, dynamic> bottomSheetSchema = {
    'title': 'BottomSheet',
    'type': 'widget',
    'properties': {
      'title': {'type': 'string', 'required': false},
      'isDismissible': {'type': 'boolean', 'default': true},
      'enableDrag': {'type': 'boolean', 'default': true},
      'height': {'type': 'number', 'required': false},
      'backgroundColor': {'type': 'color'},
    },
    'children': {'min': 1, 'max': -1},
    'events': ['onDismissed'],
  };

  /// Avatar schema
  static const Map<String, dynamic> avatarSchema = {
    'title': 'Avatar',
    'type': 'widget',
    'properties': {
      'imageUrl': {'type': 'string', 'required': false},
      'initials': {'type': 'string', 'required': false},
      'size': {'type': 'number', 'default': 40.0},
      'backgroundColor': {'type': 'color', 'default': '#2196F3'},
      'textColor': {'type': 'color', 'default': '#FFFFFF'},
    },
    'children': {'min': 0, 'max': 0},
  };

  /// ProgressBar schema
  static const Map<String, dynamic> progressBarSchema = {
    'title': 'ProgressBar',
    'type': 'widget',
    'properties': {
      'value': {'type': 'number', 'default': 0.5, 'min': 0, 'max': 1},
      'minValue': {'type': 'number', 'default': 0.0},
      'maxValue': {'type': 'number', 'default': 100.0},
      'showLabel': {'type': 'boolean', 'default': false},
      'height': {'type': 'number', 'default': 4.0},
      'backgroundColor': {'type': 'color'},
      'valueColor': {'type': 'color', 'default': '#2196F3'},
    },
    'children': {'min': 0, 'max': 0},
  };

  /// CircularProgress schema
  static const Map<String, dynamic> circularProgressSchema = {
    'title': 'CircularProgress',
    'type': 'widget',
    'properties': {
      'value': {'type': 'number', 'default': 0.5, 'min': 0, 'max': 1},
      'size': {'type': 'number', 'default': 60.0},
      'showLabel': {'type': 'boolean', 'default': false},
      'strokeWidth': {'type': 'number', 'default': 4.0},
      'valueColor': {'type': 'color', 'default': '#2196F3'},
      'backgroundColor': {'type': 'color'},
    },
    'children': {'min': 0, 'max': 0},
  };

  /// Tag schema
  static const Map<String, dynamic> tagSchema = {
    'title': 'Tag',
    'type': 'widget',
    'properties': {
      'label': {'type': 'string', 'default': 'Tag'},
      'backgroundColor': {'type': 'color', 'default': '#2196F3'},
      'textColor': {'type': 'color', 'default': '#FFFFFF'},
      'onDismissed': {'type': 'boolean', 'default': false},
    },
    'children': {'min': 0, 'max': 0},
    'events': ['onDismissed'],
  };

  /// FittedBox schema
  static const Map<String, dynamic> fittedBoxSchema = {
    'title': 'FittedBox',
    'type': 'widget',
    'properties': {
      'fit': {
        'type': 'enum',
        'default': 'contain',
        'values': ['fill', 'contain', 'cover', 'fitwidth', 'fitheight', 'scaledown']
      },
    },
    'children': {'min': 1, 'max': 1},
  };

  /// ExpansionTile schema
  static const Map<String, dynamic> expansionTileSchema = {
    'title': 'ExpansionTile',
    'type': 'widget',
    'properties': {
      'title': {'type': 'string', 'required': true},
      'subtitle': {'type': 'string', 'required': false},
      'initiallyExpanded': {'type': 'boolean', 'default': false},
      'backgroundColor': {'type': 'color'},
      'collapsedBackgroundColor': {'type': 'color'},
    },
    'children': {'min': 1, 'max': -1},
    'events': ['onExpansionChanged'],
  };

  /// Stepper schema
  static const Map<String, dynamic> stepperSchema = {
    'title': 'Stepper',
    'type': 'widget',
    'properties': {
      'type': {
        'type': 'enum',
        'default': 'vertical',
        'values': ['vertical', 'horizontal']
      },
      'currentStep': {'type': 'number', 'default': 0},
    },
    'children': {'min': 1, 'max': -1},
    'description': 'Each child should have: title (string), subtitle (string), content (widget)',
    'events': ['onStepTapped', 'onStepContinue', 'onStepCancel'],
  };

  /// DataTable schema
  static const Map<String, dynamic> dataTableSchema = {
    'title': 'DataTable',
    'type': 'widget',
    'properties': {
      'columns': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Column headers'
      },
    },
    'children': {'min': 1, 'max': -1},
    'description': 'Each child should be a row with cells array',
    'events': ['onSelectAll'],
  };

  /// PageView schema
  static const Map<String, dynamic> pageViewSchema = {
    'title': 'PageView',
    'type': 'widget',
    'properties': {
      'scrollDirection': {
        'type': 'enum',
        'default': 'horizontal',
        'values': ['horizontal', 'vertical']
      },
    },
    'children': {'min': 1, 'max': -1},
    'events': ['onPageChanged'],
  };

  /// SnackBar schema
  static const Map<String, dynamic> snackBarSchema = {
    'title': 'SnackBar',
    'type': 'widget',
    'properties': {
      'message': {'type': 'string', 'required': true},
      'duration': {'type': 'number', 'default': 3},
      'backgroundColor': {'type': 'color'},
      'textColor': {'type': 'color'},
    },
    'children': {'min': 0, 'max': 0},
  };

  /// Get all Phase 1 widget schemas
  static Map<String, Map<String, dynamic>> getAllSchemas() {
    return {
      'SliverAppBar': sliverAppBarSchema,
      'BottomSheet': bottomSheetSchema,
      'Avatar': avatarSchema,
      'ProgressBar': progressBarSchema,
      'CircularProgress': circularProgressSchema,
      'Tag': tagSchema,
      'FittedBox': fittedBoxSchema,
      'ExpansionTile': expansionTileSchema,
      'Stepper': stepperSchema,
      'DataTable': dataTableSchema,
      'PageView': pageViewSchema,
      'SnackBar': snackBarSchema,
    };
  }

  /// Validate widget properties against schema
  static ({bool isValid, List<String> errors}) validateProperties(
    String widgetType,
    Map<String, dynamic> properties,
  ) {
    final schemas = getAllSchemas();
    final schema = schemas[widgetType];

    if (schema == null) {
      return (isValid: false, errors: ['Widget type "$widgetType" not found in Phase 1 schemas']);
    }

    final errors = <String>[];
    final schemaProps = schema['properties'] as Map<String, dynamic>? ?? {};

    for (final entry in schemaProps.entries) {
      final key = entry.key;
      final propSchema = entry.value;
      final propDef = propSchema as Map<String, dynamic>;
      final isRequired = propDef['required'] as bool? ?? false;
      final value = properties[key];

      if (isRequired && (value == null)) {
        errors.add('Required property "$key" is missing');
      }
    }

    return (isValid: errors.isEmpty, errors: errors);
  }
}
