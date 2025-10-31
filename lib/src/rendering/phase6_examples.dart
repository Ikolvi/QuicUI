/// Phase 6 Examples - Data Display Widget Showcase
/// Demonstrates usage of all 15 Phase 6 widgets with practical examples

import 'package:flutter/material.dart';
import 'phase6_widgets.dart';

class Phase6Examples {
  /// LineChart Examples
  static final lineChartExamples = [
    {
      'name': 'Basic Line Chart',
      'widget': Phase6Widgets.buildLineChart({
        'title': 'Sales Trend',
        'dataPoints': [10, 25, 15, 30, 20, 35, 28],
        'backgroundColor': '#FFFFFF',
        'lineColor': '#2196F3'
      }, null)
    },
    {
      'name': 'Line Chart with Custom Color',
      'widget': Phase6Widgets.buildLineChart({
        'title': 'Temperature',
        'dataPoints': [15, 18, 22, 25, 24, 20, 16],
        'backgroundColor': '#FAFAFA',
        'lineColor': '#FF6B35'
      }, null)
    },
    {
      'name': 'High Volume Data',
      'widget': Phase6Widgets.buildLineChart({
        'title': 'Daily Users',
        'dataPoints': [100, 250, 180, 320, 290, 350, 330, 380, 420],
        'backgroundColor': '#F5F5F5',
        'lineColor': '#1976D2'
      }, null)
    },
  ];

  /// BarChart Examples
  static final barChartExamples = [
    {
      'name': 'Basic Bar Chart',
      'widget': Phase6Widgets.buildBarChart({
        'title': 'Monthly Revenue',
        'dataPoints': [12, 25, 18, 30, 22, 28],
        'barColor': '#2196F3'
      }, null)
    },
    {
      'name': 'Bar Chart with Custom Color',
      'widget': Phase6Widgets.buildBarChart({
        'title': 'Product Sales',
        'dataPoints': [45, 60, 30, 75, 50, 65],
        'barColor': '#4ECDC4'
      }, null)
    },
    {
      'name': 'Comparison Chart',
      'widget': Phase6Widgets.buildBarChart({
        'title': 'Q1 vs Q2',
        'dataPoints': [50, 65, 40, 80, 55, 70],
        'barColor': '#00BCD4'
      }, null)
    },
  ];

  /// PieChart Examples
  static final pieChartExamples = [
    {
      'name': 'Market Share',
      'widget': Phase6Widgets.buildPieChart({
        'title': 'Market Distribution',
        'dataPoints': [30, 25, 20, 15, 10]
      }, null)
    },
    {
      'name': 'Budget Allocation',
      'widget': Phase6Widgets.buildPieChart({
        'title': 'Budget Split',
        'dataPoints': [40, 30, 20, 10]
      }, null)
    },
    {
      'name': 'User Categories',
      'widget': Phase6Widgets.buildPieChart({
        'title': 'User Types',
        'dataPoints': [35, 25, 20, 15, 5]
      }, null)
    },
  ];

  /// ScatterChart Examples
  static final scatterChartExamples = [
    {
      'name': 'Correlation Plot',
      'widget': Phase6Widgets.buildScatterChart({
        'title': 'Price vs Demand',
        'dataCount': 20
      }, null)
    },
    {
      'name': 'Random Distribution',
      'widget': Phase6Widgets.buildScatterChart({
        'title': 'Data Distribution',
        'dataCount': 30
      }, null)
    },
    {
      'name': 'Outlier Detection',
      'widget': Phase6Widgets.buildScatterChart({
        'title': 'Outliers',
        'dataCount': 25
      }, null)
    },
  ];

  /// AreaChart Examples
  static final areaChartExamples = [
    {
      'name': 'Sales Progression',
      'widget': Phase6Widgets.buildAreaChart({
        'title': 'Cumulative Sales',
        'dataPoints': [10, 25, 35, 50, 65, 80, 95],
        'areaColor': '#81C784'
      }, null)
    },
    {
      'name': 'User Growth',
      'widget': Phase6Widgets.buildAreaChart({
        'title': 'Active Users',
        'dataPoints': [50, 100, 180, 250, 320, 400],
        'areaColor': '#95E1D3'
      }, null)
    },
    {
      'name': 'Bandwidth Usage',
      'widget': Phase6Widgets.buildAreaChart({
        'title': 'Network Traffic',
        'dataPoints': [20, 45, 60, 75, 85, 90, 88],
        'areaColor': '#64B5F6'
      }, null)
    },
  ];

  /// Timeline Examples
  static final timelineExamples = [
    {
      'name': 'Project Milestones',
      'widget': Phase6Widgets.buildTimeline({
        'events': [
          'Design Phase',
          'Development',
          'Testing',
          'Launch'
        ],
        'lineColor': '#2196F3'
      }, null)
    },
    {
      'name': 'Product Roadmap',
      'widget': Phase6Widgets.buildTimeline({
        'events': [
          'Q1 Planning',
          'Q2 Development',
          'Q3 Beta',
          'Q4 Release'
        ],
        'lineColor': '#FF9800'
      }, null)
    },
    {
      'name': 'Order Timeline',
      'widget': Phase6Widgets.buildTimeline({
        'events': [
          'Order Placed',
          'Processing',
          'Shipped',
          'Delivered'
        ],
        'lineColor': '#4ECDC4'
      }, null)
    },
  ];

  /// Calendar Examples
  static final calendarExamples = [
    {
      'name': 'October Calendar',
      'widget': Phase6Widgets.buildCalendar({
        'monthYear': 'October 2025',
        'selectedDates': [5, 12, 15, 22, 28]
      }, null)
    },
    {
      'name': 'November Calendar',
      'widget': Phase6Widgets.buildCalendar({
        'monthYear': 'November 2025',
        'selectedDates': [10, 17, 24]
      }, null)
    },
    {
      'name': 'December Calendar',
      'widget': Phase6Widgets.buildCalendar({
        'monthYear': 'December 2025',
        'selectedDates': [1, 8, 15, 22, 25, 31]
      }, null)
    },
  ];

  /// ProgressRing Examples
  static final progressRingExamples = [
    {
      'name': 'Download Progress',
      'widget': Phase6Widgets.buildProgressRing({
        'progress': 0.65,
        'size': 120,
        'ringColor': '#2196F3'
      }, null)
    },
    {
      'name': 'Installation Complete',
      'widget': Phase6Widgets.buildProgressRing({
        'progress': 1.0,
        'size': 120,
        'ringColor': '#4ECDC4'
      }, null)
    },
    {
      'name': 'Processing Half',
      'widget': Phase6Widgets.buildProgressRing({
        'progress': 0.5,
        'size': 100,
        'ringColor': '#FF9800'
      }, null)
    },
  ];

  /// StatisticCard Examples
  static final statisticCardExamples = [
    {
      'name': 'Revenue Card',
      'widget': Phase6Widgets.buildStatisticCard({
        'label': 'Total Revenue',
        'value': '\$125,400',
        'backgroundColor': '#FF6B35'
      }, null)
    },
    {
      'name': 'Users Card',
      'widget': Phase6Widgets.buildStatisticCard({
        'label': 'Active Users',
        'value': '8,543',
        'backgroundColor': '#4ECDC4'
      }, null)
    },
    {
      'name': 'Growth Card',
      'widget': Phase6Widgets.buildStatisticCard({
        'label': 'Growth Rate',
        'value': '+23.5%',
        'backgroundColor': '#95E1D3'
      }, null)
    },
  ];

  /// TableView Examples
  static final tableViewExamples = [
    {
      'name': 'Sales Table',
      'widget': Phase6Widgets.buildTableView({
        'headers': ['Product', 'Q1', 'Q2', 'Q3'],
        'rows': [
          ['Widget A', '250', '320', '380'],
          ['Widget B', '180', '220', '260'],
          ['Widget C', '320', '350', '410']
        ]
      }, null)
    },
    {
      'name': 'User Statistics',
      'widget': Phase6Widgets.buildTableView({
        'headers': ['Name', 'Email', 'Status'],
        'rows': [
          ['John Doe', 'john@example.com', 'Active'],
          ['Jane Smith', 'jane@example.com', 'Active'],
          ['Bob Johnson', 'bob@example.com', 'Inactive']
        ]
      }, null)
    },
    {
      'name': 'Inventory Table',
      'widget': Phase6Widgets.buildTableView({
        'headers': ['Item', 'Stock', 'Price'],
        'rows': [
          ['Item 1', '45', '\$25'],
          ['Item 2', '32', '\$40'],
          ['Item 3', '58', '\$35']
        ]
      }, null)
    },
  ];

  /// InfiniteList Examples
  static final infiniteListExamples = [
    {
      'name': 'News Feed',
      'widget': Phase6Widgets.buildInfiniteList({
        'itemCount': 50,
        'title': 'News Item'
      }, null)
    },
    {
      'name': 'Product List',
      'widget': Phase6Widgets.buildInfiniteList({
        'itemCount': 100,
        'title': 'Product'
      }, null)
    },
    {
      'name': 'Comment Thread',
      'widget': Phase6Widgets.buildInfiniteList({
        'itemCount': 75,
        'title': 'Comment'
      }, null)
    },
  ];

  /// VirtualGrid Examples
  static final virtualGridExamples = [
    {
      'name': 'Photo Grid',
      'widget': Phase6Widgets.buildVirtualGrid({
        'itemCount': 50,
        'crossAxisCount': 3,
        'backgroundColor': '#FFFFFF'
      }, null)
    },
    {
      'name': 'Product Gallery',
      'widget': Phase6Widgets.buildVirtualGrid({
        'itemCount': 40,
        'crossAxisCount': 2,
        'backgroundColor': '#E8F4F8'
      }, null)
    },
    {
      'name': 'Icon Grid',
      'widget': Phase6Widgets.buildVirtualGrid({
        'itemCount': 60,
        'crossAxisCount': 4,
        'backgroundColor': '#F5F5F5'
      }, null)
    },
  ];

  /// MasonryGrid Examples
  static final masonryGridExamples = [
    {
      'name': 'Pinterest Style',
      'widget': Phase6Widgets.buildMasonryGrid({
        'itemCount': 30
      }, null)
    },
    {
      'name': 'Image Collection',
      'widget': Phase6Widgets.buildMasonryGrid({
        'itemCount': 25
      }, null)
    },
    {
      'name': 'Content Feed',
      'widget': Phase6Widgets.buildMasonryGrid({
        'itemCount': 40
      }, null)
    },
  ];

  /// TimelineView Examples
  static final timelineViewExamples = [
    {
      'name': 'Project History',
      'widget': Phase6Widgets.buildTimelineView({
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
      }, null)
    },
    {
      'name': 'Order Timeline',
      'widget': Phase6Widgets.buildTimelineView({
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
      }, null)
    },
    {
      'name': 'User Journey',
      'widget': Phase6Widgets.buildTimelineView({
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
      }, null)
    },
  ];

  /// DataGrid Examples
  static final dataGridExamples = [
    {
      'name': 'Analytics Dashboard',
      'widget': Phase6Widgets.buildDataGrid({
        'title': 'Performance Metrics',
        'columnCount': 4,
        'rowCount': 5
      }, null)
    },
    {
      'name': 'Sales Report',
      'widget': Phase6Widgets.buildDataGrid({
        'title': 'Monthly Sales',
        'columnCount': 5,
        'rowCount': 6
      }, null)
    },
    {
      'name': 'User Management',
      'widget': Phase6Widgets.buildDataGrid({
        'title': 'Active Users',
        'columnCount': 3,
        'rowCount': 8
      }, null)
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

  /// Dashboard showcasing multiple Phase 6 widgets
  static Widget buildShowcaseDashboard() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Charts Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data Visualizations',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Phase6Widgets.buildLineChart({
                  'title': 'Sales Trend',
                  'dataPoints': [10, 25, 15, 30, 20, 35, 28]
                }, null),
                SizedBox(height: 20),
                Phase6Widgets.buildBarChart({
                  'title': 'Monthly Revenue',
                  'dataPoints': [12, 25, 18, 30, 22, 28]
                }, null),
                SizedBox(height: 20),
                Phase6Widgets.buildPieChart({
                  'title': 'Market Share',
                  'dataPoints': [30, 25, 20, 15, 10]
                }, null),
              ],
            ),
          ),
          // Statistics Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Key Metrics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Expanded(
                      child: Phase6Widgets.buildStatisticCard({
                        'label': 'Revenue',
                        'value': '\$125K',
                        'backgroundColor': '#FF6B35'
                      }, null),
                    ),
                    Expanded(
                      child: Phase6Widgets.buildStatisticCard({
                        'label': 'Users',
                        'value': '8.5K',
                        'backgroundColor': '#4ECDC4'
                      }, null),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Timeline Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progress Timeline',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Phase6Widgets.buildTimeline({
                  'events': ['Design', 'Development', 'Testing', 'Launch']
                }, null),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
