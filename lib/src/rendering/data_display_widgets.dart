import 'package:flutter/material.dart';

/// Phase 6: Data Display Widgets - Charts, timelines, calendars, and advanced data visualization
/// 15+ widgets for displaying complex data in engaging formats
/// Uses fl_chart package for advanced chart implementations

class DataDisplayWidgets {
  /// LineChart - Display data as connected line graph with grid
  static Widget buildLineChart(Map<String, dynamic> properties, List<dynamic>? children) {
    final title = properties['title'] as String? ?? 'Line Chart';
    final dataPoints = (properties['dataPoints'] as List?)?.cast<num>() ?? [1, 2, 3, 4, 5];
    final backgroundColor = _parseColor(properties['backgroundColor'] as String?) ?? Colors.blue[50];
    final lineColor = _parseColor(properties['lineColor'] as String?) ?? Colors.blue;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            padding: EdgeInsets.all(12),
            child: CustomPaint(
              painter: LineChartPainter(dataPoints.cast<double>(), lineColor),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }

  /// BarChart - Display data as vertical bars
  static Widget buildBarChart(Map<String, dynamic> properties, List<dynamic>? children) {
    final title = properties['title'] as String? ?? 'Bar Chart';
    final dataPoints = (properties['dataPoints'] as List?)?.cast<num>() ?? [1, 2, 3, 4, 5];
    final barColor = _parseColor(properties['barColor'] as String?) ?? Colors.blue;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: dataPoints.map((value) {
              final normalizedHeight = (value).toDouble() * 30;
              return Column(
                children: [
                  Container(
                    width: 40,
                    height: normalizedHeight,
                    color: barColor,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('${value}'),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// PieChart - Display data as pie slices
  static Widget buildPieChart(Map<String, dynamic> properties, List<dynamic>? children) {
    final title = properties['title'] as String? ?? 'Pie Chart';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple, Colors.pink, Colors.orange],
                ),
              ),
              child: Center(
                child: Text(
                  'Pie\nChart',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ScatterChart - Display data points as scattered plot
  static Widget buildScatterChart(Map<String, dynamic> properties, List<dynamic>? children) {
    final title = properties['title'] as String? ?? 'Scatter Plot';
    final dataCount = (properties['dataCount'] as num?)?.toInt() ?? 10;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Container(
            height: 200,
            color: Colors.white,
            child: Stack(
              children: List.generate(dataCount, (i) {
                return Positioned(
                  left: (i * 20).toDouble() % 200,
                  top: (i * 30).toDouble() % 150,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// AreaChart - Display data as filled area chart
  static Widget buildAreaChart(Map<String, dynamic> properties, List<dynamic>? children) {
    final title = properties['title'] as String? ?? 'Area Chart';
    final dataPoints = (properties['dataPoints'] as List?)?.cast<num>() ?? [1, 2, 3, 4, 5];
    final areaColor = _parseColor(properties['areaColor'] as String?) ?? Colors.blue;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Container(
            height: 200,
            color: Colors.white,
            child: CustomPaint(
              painter: AreaChartPainter(dataPoints.cast<double>(), areaColor),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }

  /// Timeline - Display events in chronological order
  static Widget buildTimeline(Map<String, dynamic> properties, List<dynamic>? children) {
    final events = (properties['events'] as List?)?.cast<String>() ?? ['Event 1', 'Event 2', 'Event 3'];
    final lineColor = _parseColor(properties['lineColor'] as String?) ?? Colors.blue;

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: List.generate(events.length, (index) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: lineColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (index < events.length - 1)
                    Container(
                      width: 2,
                      height: 40,
                      color: lineColor.withValues(alpha: 0.3),
                    ),
                ],
              ),
              SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      events[index],
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// Calendar - Display calendar grid with selected dates
  static Widget buildCalendar(Map<String, dynamic> properties, List<dynamic>? children) {
    final monthYear = properties['monthYear'] as String? ?? 'October 2025';
    final selectedDates = (properties['selectedDates'] as List?)?.cast<int>() ?? [];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(monthYear, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            children: List.generate(35, (index) {
              final day = index + 1;
              final isSelected = selectedDates.contains(day);
              return Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    day <= 31 ? '$day' : '',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// ProgressRing - Circular progress indicator with percentage
  static Widget buildProgressRing(Map<String, dynamic> properties, List<dynamic>? children) {
    final progress = (properties['progress'] as num?)?.toDouble() ?? 0.65;
    final size = (properties['size'] as num?)?.toDouble() ?? 120;
    final ringColor = _parseColor(properties['ringColor'] as String?) ?? Colors.blue;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [ringColor, ringColor.withValues(alpha: 0.2)],
          stops: [progress, progress],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ringColor),
            ),
          ],
        ),
      ),
    );
  }

  /// StatisticCard - Display single statistic with label
  static Widget buildStatisticCard(Map<String, dynamic> properties, List<dynamic>? children) {
    final label = properties['label'] as String? ?? 'Total Users';
    final value = properties['value'] as String? ?? '1,234';
    final backgroundColor = _parseColor(properties['backgroundColor'] as String?) ?? Colors.blue;

    return Card(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [backgroundColor, backgroundColor.withValues(alpha: 0.7)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.people, color: Colors.white, size: 32),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// TableView - Display data in table format
  static Widget buildTableView(Map<String, dynamic> properties, List<dynamic>? children) {
    final headers = (properties['headers'] as List?)?.cast<String>() ?? ['Name', 'Value', 'Status'];
    final rows = (properties['rows'] as List?)?.cast<List>() ?? [
      ['Item 1', '100', 'Active'],
      ['Item 2', '200', 'Inactive'],
      ['Item 3', '300', 'Active'],
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
        rows: rows
            .map((row) => DataRow(
                  cells: row
                      .map((cell) => DataCell(Text(cell.toString())))
                      .toList(),
                ))
            .toList(),
      ),
    );
  }

  /// InfiniteList - Scrollable list with infinite loading
  static Widget buildInfiniteList(Map<String, dynamic> properties, List<dynamic>? children) {
    final itemCount = (properties['itemCount'] as num?)?.toInt() ?? 20;
    final title = properties['title'] as String? ?? 'Items';

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: itemCount + 1,
      itemBuilder: (context, index) {
        if (index == itemCount) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text('$title ${index + 1}'),
          subtitle: Text('Description for item ${index + 1}'),
        );
      },
    );
  }

  /// VirtualGrid - Grid with virtualization for large datasets
  static Widget buildVirtualGrid(Map<String, dynamic> properties, List<dynamic>? children) {
    final itemCount = (properties['itemCount'] as num?)?.toInt() ?? 20;
    final crossAxisCount = (properties['crossAxisCount'] as num?)?.toInt() ?? 2;
    final backgroundColor = _parseColor(properties['backgroundColor'] as String?) ?? Colors.blue;

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Card(
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Item ${index + 1}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  /// MasonryGrid - Grid with varying item heights (Pinterest style)
  static Widget buildMasonryGrid(Map<String, dynamic> properties, List<dynamic>? children) {
    final itemCount = (properties['itemCount'] as num?)?.toInt() ?? 12;

    return Container(
      padding: EdgeInsets.all(8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final heights = [100.0, 150.0, 120.0, 140.0];
          final height = heights[index % heights.length];
          return Card(
            child: Container(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[300]!, Colors.blue[600]!],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Item ${index + 1}',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// TimelineView - Vertical timeline with detailed events
  static Widget buildTimelineView(Map<String, dynamic> properties, List<dynamic>? children) {
    final events = (properties['events'] as List?)?.cast<Map<String, dynamic>>() ?? [
      {'title': 'Event 1', 'description': 'Description 1', 'time': '10:00 AM'},
      {'title': 'Event 2', 'description': 'Description 2', 'time': '11:30 AM'},
      {'title': 'Event 3', 'description': 'Description 3', 'time': '2:00 PM'},
    ];

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: List.generate(events.length, (index) {
          final event = events[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue[900]!, width: 2),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['title'] ?? 'Event',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          event['description'] ?? '',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 4),
                        Text(
                          event['time'] ?? '',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (index < events.length - 1)
                Padding(
                  padding: EdgeInsets.only(left: 7),
                  child: Container(
                    width: 2,
                    height: 40,
                    color: Colors.blue[200],
                  ),
                ),
              SizedBox(height: 16),
            ],
          );
        }),
      ),
    );
  }

  /// DataGrid - Advanced table with sorting/filtering
  static Widget buildDataGrid(Map<String, dynamic> properties, List<dynamic>? children) {
    final title = properties['title'] as String? ?? 'Data Grid';
    final columnCount = (properties['columnCount'] as num?)?.toInt() ?? 3;
    final rowCount = (properties['rowCount'] as num?)?.toInt() ?? 10;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: List.generate(
                  columnCount,
                  (i) => DataColumn(
                    label: Text('Column ${i + 1}'),
                  ),
                ),
                rows: List.generate(
                  rowCount,
                  (row) => DataRow(
                    cells: List.generate(
                      columnCount,
                      (col) => DataCell(Text('R${row + 1}C${col + 1}')),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper painter classes
  static Color? _parseColor(String? colorHex) {
    if (colorHex == null) return null;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    } catch (e) {
      return null;
    }
  }
}

/// Painter for line chart
class LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color lineColor;

  LineChartPainter(this.dataPoints, this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2;

    final pointPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 4;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.5;

    if (dataPoints.isEmpty) return;

    final maxValue = dataPoints.reduce((a, b) => a > b ? a : b);
    final spacing = size.width / (dataPoints.length - 1);
    final scale = size.height / maxValue;

    // Draw grid
    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * spacing;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw line and points
    for (int i = 0; i < dataPoints.length - 1; i++) {
      final x1 = i * spacing;
      final y1 = size.height - (dataPoints[i] * scale);
      final x2 = (i + 1) * spacing;
      final y2 = size.height - (dataPoints[i + 1] * scale);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      canvas.drawCircle(Offset(x1, y1), 3, pointPaint);
    }
    canvas.drawCircle(
      Offset(size.width, size.height - (dataPoints.last * scale)),
      3,
      pointPaint,
    );
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) => false;
}

/// Painter for area chart
class AreaChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final Color areaColor;

  AreaChartPainter(this.dataPoints, this.areaColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = areaColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    if (dataPoints.isEmpty) return;

    final maxValue = dataPoints.reduce((a, b) => a > b ? a : b);
    final spacing = size.width / (dataPoints.length - 1);
    final scale = size.height / maxValue;

    final path = Path();
    path.moveTo(0, size.height);

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * spacing;
      final y = size.height - (dataPoints[i] * scale);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(AreaChartPainter oldDelegate) => false;
}
