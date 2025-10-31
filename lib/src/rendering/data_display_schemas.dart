/// Phase 6 Schema Definitions - Data Display Widgets
/// Validates JSON structure for all 15 data display widgets

class Phase6Schemas {
  /// Schema for LineChart widget
  static final lineChartSchema = {
    'type': 'object',
    'properties': {
      'title': {'type': 'string', 'description': 'Chart title'},
      'dataPoints': {
        'type': 'array',
        'items': {'type': 'number'},
        'description': 'Array of numeric data points'
      },
      'backgroundColor': {
        'type': 'string',
        'pattern': r'^#[0-9A-Fa-f]{6}$',
        'description': 'Background color in hex format'
      },
      'lineColor': {
        'type': 'string',
        'pattern': r'^#[0-9A-Fa-f]{6}$',
        'description': 'Line color in hex format'
      }
    },
    'additionalProperties': false
  };

  /// Schema for BarChart widget
  static final barChartSchema = {
    'type': 'object',
    'properties': {
      'title': {'type': 'string', 'description': 'Chart title'},
      'dataPoints': {
        'type': 'array',
        'items': {'type': 'number'},
        'description': 'Array of bar heights'
      },
      'barColor': {
        'type': 'string',
        'pattern': r'^#[0-9A-Fa-f]{6}$',
        'description': 'Bar color in hex format'
      }
    },
    'additionalProperties': false
  };

  /// Schema for PieChart widget
  static final pieChartSchema = {
    'type': 'object',
    'properties': {
      'title': {'type': 'string', 'description': 'Chart title'},
      'dataPoints': {
        'type': 'array',
        'items': {'type': 'number'},
        'description': 'Array of pie slice values'
      }
    },
    'additionalProperties': false
  };

  /// Schema for ScatterChart widget
  static final scatterChartSchema = {
    'type': 'object',
    'properties': {
      'title': {'type': 'string', 'description': 'Chart title'},
      'dataCount': {
        'type': 'integer',
        'minimum': 1,
        'description': 'Number of data points to display'
      }
    },
    'additionalProperties': false
  };

  /// Schema for AreaChart widget
  static final areaChartSchema = {
    'type': 'object',
    'properties': {
      'title': {'type': 'string', 'description': 'Chart title'},
      'dataPoints': {
        'type': 'array',
        'items': {'type': 'number'},
        'description': 'Array of area data points'
      },
      'areaColor': {
        'type': 'string',
        'pattern': r'^#[0-9A-Fa-f]{6}$',
        'description': 'Area fill color in hex format'
      }
    },
    'additionalProperties': false
  };

  /// Schema for Timeline widget
  static final timelineSchema = {
    'type': 'object',
    'properties': {
      'events': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Array of event descriptions'
      },
      'lineColor': {
        'type': 'string',
        'pattern': r'^#[0-9A-Fa-f]{6}$',
        'description': 'Timeline line color in hex format'
      }
    },
    'additionalProperties': false
  };

  /// Schema for Calendar widget
  static final calendarSchema = {
    'type': 'object',
    'properties': {
      'monthYear': {
        'type': 'string',
        'description': 'Month and year display (e.g., "October 2025")'
      },
      'selectedDates': {
        'type': 'array',
        'items': {'type': 'integer'},
        'description': 'Array of selected date numbers (1-31)'
      }
    },
    'additionalProperties': false
  };

  /// Schema for ProgressRing widget
  static final progressRingSchema = {
    'type': 'object',
    'properties': {
      'progress': {
        'type': 'number',
        'minimum': 0,
        'maximum': 1,
        'description': 'Progress value from 0 to 1'
      },
      'size': {
        'type': 'number',
        'minimum': 50,
        'description': 'Ring size in pixels'
      },
      'ringColor': {
        'type': 'string',
        'pattern': r'^#[0-9A-Fa-f]{6}$',
        'description': 'Ring color in hex format'
      }
    },
    'additionalProperties': false
  };

  /// Schema for StatisticCard widget
  static final statisticCardSchema = {
    'type': 'object',
    'properties': {
      'label': {'type': 'string', 'description': 'Card label'},
      'value': {'type': 'string', 'description': 'Statistic value'},
      'backgroundColor': {
        'type': 'string',
        'pattern': r'^#[0-9A-Fa-f]{6}$',
        'description': 'Background color in hex format'
      }
    },
    'additionalProperties': false
  };

  /// Schema for TableView widget
  static final tableViewSchema = {
    'type': 'object',
    'properties': {
      'headers': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Table header names'
      },
      'rows': {
        'type': 'array',
        'items': {'type': 'array'},
        'description': 'Array of table rows (each row is array of values)'
      }
    },
    'additionalProperties': false
  };

  /// Schema for InfiniteList widget
  static final infiniteListSchema = {
    'type': 'object',
    'properties': {
      'itemCount': {
        'type': 'integer',
        'minimum': 1,
        'description': 'Number of list items'
      },
      'title': {'type': 'string', 'description': 'List item title prefix'}
    },
    'additionalProperties': false
  };

  /// Schema for VirtualGrid widget
  static final virtualGridSchema = {
    'type': 'object',
    'properties': {
      'itemCount': {
        'type': 'integer',
        'minimum': 1,
        'description': 'Number of grid items'
      },
      'crossAxisCount': {
        'type': 'integer',
        'minimum': 1,
        'description': 'Number of columns'
      },
      'backgroundColor': {
        'type': 'string',
        'pattern': r'^#[0-9A-Fa-f]{6}$',
        'description': 'Item background color in hex format'
      }
    },
    'additionalProperties': false
  };

  /// Schema for MasonryGrid widget
  static final masonryGridSchema = {
    'type': 'object',
    'properties': {
      'itemCount': {
        'type': 'integer',
        'minimum': 1,
        'description': 'Number of masonry items'
      }
    },
    'additionalProperties': false
  };

  /// Schema for TimelineView widget
  static final timelineViewSchema = {
    'type': 'object',
    'properties': {
      'events': {
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'title': {'type': 'string'},
            'description': {'type': 'string'},
            'time': {'type': 'string'}
          }
        },
        'description': 'Array of timeline events'
      }
    },
    'additionalProperties': false
  };

  /// Schema for DataGrid widget
  static final dataGridSchema = {
    'type': 'object',
    'properties': {
      'title': {'type': 'string', 'description': 'Grid title'},
      'columnCount': {
        'type': 'integer',
        'minimum': 1,
        'description': 'Number of columns'
      },
      'rowCount': {
        'type': 'integer',
        'minimum': 1,
        'description': 'Number of rows'
      }
    },
    'additionalProperties': false
  };

  // Validation methods
  static bool validateLineChart(Map<String, dynamic> properties) {
    return (properties['title'] is String || properties['title'] == null) &&
           (properties['dataPoints'] is List || properties['dataPoints'] == null);
  }

  static bool validateBarChart(Map<String, dynamic> properties) {
    return (properties['title'] is String || properties['title'] == null) &&
           (properties['dataPoints'] is List || properties['dataPoints'] == null);
  }

  static bool validatePieChart(Map<String, dynamic> properties) {
    return properties['title'] is String || properties['title'] == null;
  }

  static bool validateScatterChart(Map<String, dynamic> properties) {
    return (properties['title'] is String || properties['title'] == null) &&
           (properties['dataCount'] is int || properties['dataCount'] == null);
  }

  static bool validateAreaChart(Map<String, dynamic> properties) {
    return (properties['title'] is String || properties['title'] == null) &&
           (properties['dataPoints'] is List || properties['dataPoints'] == null);
  }

  static bool validateTimeline(Map<String, dynamic> properties) {
    return properties['events'] is List || properties['events'] == null;
  }

  static bool validateCalendar(Map<String, dynamic> properties) {
    return (properties['monthYear'] is String || properties['monthYear'] == null) &&
           (properties['selectedDates'] is List || properties['selectedDates'] == null);
  }

  static bool validateProgressRing(Map<String, dynamic> properties) {
    final progress = properties['progress'] as num?;
    return (progress == null || (progress >= 0 && progress <= 1));
  }

  static bool validateStatisticCard(Map<String, dynamic> properties) {
    return (properties['label'] is String || properties['label'] == null) &&
           (properties['value'] is String || properties['value'] == null);
  }

  static bool validateTableView(Map<String, dynamic> properties) {
    return (properties['headers'] is List || properties['headers'] == null) &&
           (properties['rows'] is List || properties['rows'] == null);
  }

  static bool validateInfiniteList(Map<String, dynamic> properties) {
    return (properties['itemCount'] is int || properties['itemCount'] == null) &&
           (properties['title'] is String || properties['title'] == null);
  }

  static bool validateVirtualGrid(Map<String, dynamic> properties) {
    return (properties['itemCount'] is int || properties['itemCount'] == null) &&
           (properties['crossAxisCount'] is int || properties['crossAxisCount'] == null);
  }

  static bool validateMasonryGrid(Map<String, dynamic> properties) {
    return properties['itemCount'] is int || properties['itemCount'] == null;
  }

  static bool validateTimelineView(Map<String, dynamic> properties) {
    return properties['events'] is List || properties['events'] == null;
  }

  static bool validateDataGrid(Map<String, dynamic> properties) {
    return (properties['title'] is String || properties['title'] == null) &&
           (properties['columnCount'] is int || properties['columnCount'] == null) &&
           (properties['rowCount'] is int || properties['rowCount'] == null);
  }
}
