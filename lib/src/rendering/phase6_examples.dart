/// Phase 6 Examples - Data Display Widget Showcase
/// Demonstrates usage of all 15 Phase 6 widgets with practical JSON configurations
/// Ready to be used with UIRenderer for JSON-based widget instantiation

class Phase6Examples {
  /// LineChart Examples
  static final lineChartExamples = [
    {
      'name': 'Basic Line Chart',
      'type': 'LineChart',
      'properties': {
        'title': 'Sales Trend',
        'dataPoints': [10, 25, 15, 30, 20, 35, 28],
        'backgroundColor': '#FFFFFF',
        'lineColor': '#2196F3'
      }
    },
    {
      'name': 'Line Chart with Custom Color',
      'type': 'LineChart',
      'properties': {
        'title': 'Temperature',
        'dataPoints': [15, 18, 22, 25, 24, 20, 16],
        'backgroundColor': '#FAFAFA',
        'lineColor': '#FF6B35'
      }
    },
    {
      'name': 'High Volume Data',
      'type': 'LineChart',
      'properties': {
        'title': 'Daily Users',
        'dataPoints': [100, 250, 180, 320, 290, 350, 330, 380, 420],
        'backgroundColor': '#F5F5F5',
        'lineColor': '#1976D2'
      }
    },
  ];

  /// BarChart Examples
  static final barChartExamples = [
    {
      'name': 'Basic Bar Chart',
      'type': 'BarChart',
      'properties': {
        'title': 'Monthly Revenue',
        'dataPoints': [12, 25, 18, 30, 22, 28],
        'barColor': '#2196F3'
      }
    },
    {
      'name': 'Bar Chart with Custom Color',
      'type': 'BarChart',
      'properties': {
        'title': 'Product Sales',
        'dataPoints': [45, 60, 30, 75, 50, 65],
        'barColor': '#4ECDC4'
      }
    },
    {
      'name': 'Comparison Chart',
      'type': 'BarChart',
      'properties': {
        'title': 'Q1 vs Q2',
        'dataPoints': [50, 65, 40, 80, 55, 70],
        'barColor': '#00BCD4'
      }
    },
  ];

  /// PieChart Examples
  static final pieChartExamples = [
    {
      'name': 'Market Share',
      'type': 'PieChart',
      'properties': {
        'title': 'Market Distribution',
        'dataPoints': [30, 25, 20, 15, 10]
      }
    },
    {
      'name': 'Budget Allocation',
      'type': 'PieChart',
      'properties': {
        'title': 'Budget Split',
        'dataPoints': [40, 30, 20, 10]
      }
    },
    {
      'name': 'User Categories',
      'type': 'PieChart',
      'properties': {
        'title': 'User Types',
        'dataPoints': [35, 25, 20, 15, 5]
      }
    },
  ];

  /// ScatterChart Examples
  static final scatterChartExamples = [
    {
      'name': 'Correlation Plot',
      'type': 'ScatterChart',
      'properties': {
        'title': 'Price vs Demand',
        'dataCount': 20
      }
    },
    {
      'name': 'Random Distribution',
      'type': 'ScatterChart',
      'properties': {
        'title': 'Data Distribution',
        'dataCount': 30
      }
    },
    {
      'name': 'Outlier Detection',
      'type': 'ScatterChart',
      'properties': {
        'title': 'Outliers',
        'dataCount': 25
      }
    },
  ];

  /// AreaChart Examples
  static final areaChartExamples = [
    {
      'name': 'Sales Progression',
      'type': 'AreaChart',
      'properties': {
        'title': 'Cumulative Sales',
        'dataPoints': [10, 25, 35, 50, 65, 80, 95],
        'areaColor': '#81C784'
      }
    },
    {
      'name': 'User Growth',
      'type': 'AreaChart',
      'properties': {
        'title': 'Active Users',
        'dataPoints': [50, 100, 180, 250, 320, 400],
        'areaColor': '#95E1D3'
      }
    },
    {
      'name': 'Bandwidth Usage',
      'type': 'AreaChart',
      'properties': {
        'title': 'Network Traffic',
        'dataPoints': [20, 45, 60, 75, 85, 90, 88],
        'areaColor': '#64B5F6'
      }
    },
  ];

  /// Timeline Examples
  static final timelineExamples = [
    {
      'name': 'Project Milestones',
      'type': 'Timeline',
      'properties': {
        'events': ['Design Phase', 'Development', 'Testing', 'Launch'],
        'lineColor': '#2196F3'
      }
    },
    {
      'name': 'Product Roadmap',
      'type': 'Timeline',
      'properties': {
        'events': ['Q1 Planning', 'Q2 Development', 'Q3 Beta', 'Q4 Release'],
        'lineColor': '#FF9800'
      }
    },
    {
      'name': 'Order Timeline',
      'type': 'Timeline',
      'properties': {
        'events': ['Order Placed', 'Processing', 'Shipped', 'Delivered'],
        'lineColor': '#4ECDC4'
      }
    },
  ];

  /// Calendar Examples
  static final calendarExamples = [
    {
      'name': 'October Calendar',
      'type': 'Calendar',
      'properties': {
        'monthYear': 'October 2025',
        'selectedDates': [5, 12, 15, 22, 28]
      }
    },
    {
      'name': 'November Calendar',
      'type': 'Calendar',
      'properties': {
        'monthYear': 'November 2025',
        'selectedDates': [10, 17, 24]
      }
    },
    {
      'name': 'December Calendar',
      'type': 'Calendar',
      'properties': {
        'monthYear': 'December 2025',
        'selectedDates': [1, 8, 15, 22, 25, 31]
      }
    },
  ];

  /// ProgressRing Examples
  static final progressRingExamples = [
    {
      'name': 'Download Progress',
      'type': 'ProgressRing',
      'properties': {
        'progress': 0.65,
        'size': 120,
        'ringColor': '#2196F3'
      }
    },
    {
      'name': 'Installation Complete',
      'type': 'ProgressRing',
      'properties': {
        'progress': 1.0,
        'size': 120,
        'ringColor': '#4ECDC4'
      }
    },
    {
      'name': 'Processing Half',
      'type': 'ProgressRing',
      'properties': {
        'progress': 0.5,
        'size': 100,
        'ringColor': '#FF9800'
      }
    },
  ];

  /// StatisticCard Examples
  static final statisticCardExamples = [
    {
      'name': 'Revenue Card',
      'type': 'StatisticCard',
      'properties': {
        'label': 'Total Revenue',
        'value': '\$125,400',
        'backgroundColor': '#FF6B35'
      }
    },
    {
      'name': 'Users Card',
      'type': 'StatisticCard',
      'properties': {
        'label': 'Active Users',
        'value': '8,543',
        'backgroundColor': '#4ECDC4'
      }
    },
    {
      'name': 'Growth Card',
      'type': 'StatisticCard',
      'properties': {
        'label': 'Growth Rate',
        'value': '+23.5%',
        'backgroundColor': '#95E1D3'
      }
    },
  ];

  /// TableView Examples
  static final tableViewExamples = [
    {
      'name': 'Sales Table',
      'type': 'TableView',
      'properties': {
        'headers': ['Product', 'Q1', 'Q2', 'Q3'],
        'rows': [
          ['Widget A', '250', '320', '380'],
          ['Widget B', '180', '220', '260'],
          ['Widget C', '320', '350', '410']
        ]
      }
    },
    {
      'name': 'User Statistics',
      'type': 'TableView',
      'properties': {
        'headers': ['Name', 'Email', 'Status'],
        'rows': [
          ['John Doe', 'john@example.com', 'Active'],
          ['Jane Smith', 'jane@example.com', 'Active'],
          ['Bob Johnson', 'bob@example.com', 'Inactive']
        ]
      }
    },
    {
      'name': 'Inventory Table',
      'type': 'TableView',
      'properties': {
        'headers': ['Item', 'Stock', 'Price'],
        'rows': [
          ['Item 1', '45', '\$25'],
          ['Item 2', '32', '\$40'],
          ['Item 3', '58', '\$35']
        ]
      }
    },
  ];

  /// InfiniteList Examples
  static final infiniteListExamples = [
    {
      'name': 'News Feed',
      'type': 'InfiniteList',
      'properties': {
        'itemCount': 50,
        'title': 'News Item'
      }
    },
    {
      'name': 'Product List',
      'type': 'InfiniteList',
      'properties': {
        'itemCount': 100,
        'title': 'Product'
      }
    },
    {
      'name': 'Comment Thread',
      'type': 'InfiniteList',
      'properties': {
        'itemCount': 75,
        'title': 'Comment'
      }
    },
  ];

  /// VirtualGrid Examples
  static final virtualGridExamples = [
    {
      'name': 'Photo Grid',
      'type': 'VirtualGrid',
      'properties': {
        'itemCount': 50,
        'crossAxisCount': 3,
        'backgroundColor': '#FFFFFF'
      }
    },
    {
      'name': 'Product Gallery',
      'type': 'VirtualGrid',
      'properties': {
        'itemCount': 40,
        'crossAxisCount': 2,
        'backgroundColor': '#E8F4F8'
      }
    },
    {
      'name': 'Icon Grid',
      'type': 'VirtualGrid',
      'properties': {
        'itemCount': 60,
        'crossAxisCount': 4,
        'backgroundColor': '#F5F5F5'
      }
    },
  ];

  /// MasonryGrid Examples
  static final masonryGridExamples = [
    {
      'name': 'Pinterest Style',
      'type': 'MasonryGrid',
      'properties': {
        'itemCount': 30
      }
    },
    {
      'name': 'Image Collection',
      'type': 'MasonryGrid',
      'properties': {
        'itemCount': 25
      }
    },
    {
      'name': 'Content Feed',
      'type': 'MasonryGrid',
      'properties': {
        'itemCount': 40
      }
    },
  ];

  /// TimelineView Examples
  static final timelineViewExamples = [
    {
      'name': 'Project History',
      'type': 'TimelineView',
      'properties': {
        'events': [
          {
            'title': 'Project Started',
            'description': 'Initial kickoff meeting',
            'time': '09:00 AM'
          },
          {
            'title': 'Design Review',
            'description': 'UI/UX design approved',
            'time': '02:00 PM'
          },
          {
            'title': 'Development Begins',
            'description': 'Team starts coding',
            'time': '04:30 PM'
          }
        ]
      }
    },
    {
      'name': 'Order Timeline',
      'type': 'TimelineView',
      'properties': {
        'events': [
          {
            'title': 'Order Confirmed',
            'description': 'Payment received',
            'time': '10:15 AM'
          },
          {
            'title': 'Processing',
            'description': 'Preparing shipment',
            'time': '11:45 AM'
          },
          {
            'title': 'Shipped',
            'description': 'In transit',
            'time': '03:20 PM'
          }
        ]
      }
    },
    {
      'name': 'User Journey',
      'type': 'TimelineView',
      'properties': {
        'events': [
          {
            'title': 'Sign Up',
            'description': 'Account created',
            'time': 'Day 1'
          },
          {
            'title': 'First Purchase',
            'description': 'Bought premium plan',
            'time': 'Day 3'
          },
          {
            'title': 'Milestone Reached',
            'description': '100 items saved',
            'time': 'Day 15'
          }
        ]
      }
    },
  ];

  /// DataGrid Examples
  static final dataGridExamples = [
    {
      'name': 'Analytics Dashboard',
      'type': 'DataGrid',
      'properties': {
        'title': 'Performance Metrics',
        'columnCount': 4,
        'rowCount': 5
      }
    },
    {
      'name': 'Sales Report',
      'type': 'DataGrid',
      'properties': {
        'title': 'Monthly Sales',
        'columnCount': 5,
        'rowCount': 6
      }
    },
    {
      'name': 'User Management',
      'type': 'DataGrid',
      'properties': {
        'title': 'Active Users',
        'columnCount': 3,
        'rowCount': 8
      }
    },
  ];

  /// Get all examples
  static final allExamples = {
    'LineChart': lineChartExamples,
    'BarChart': barChartExamples,
    'PieChart': pieChartExamples,
    'ScatterChart': scatterChartExamples,
    'AreaChart': areaChartExamples,
    'Timeline': timelineExamples,
    'Calendar': calendarExamples,
    'ProgressRing': progressRingExamples,
    'StatisticCard': statisticCardExamples,
    'TableView': tableViewExamples,
    'InfiniteList': infiniteListExamples,
    'VirtualGrid': virtualGridExamples,
    'MasonryGrid': masonryGridExamples,
    'TimelineView': timelineViewExamples,
    'DataGrid': dataGridExamples,
  };

  /// Get example by type and index
  static Map<String, dynamic>? getExample(String type, int index) {
    final examples = allExamples[type];
    if (examples != null && index >= 0 && index < examples.length) {
      return examples[index];
    }
    return null;
  }

  /// Get all example names by type
  static List<String> getExampleNames(String type) {
    final examples = allExamples[type];
    if (examples != null) {
      return examples.map((e) => e['name'] as String).toList();
    }
    return [];
  }
}
