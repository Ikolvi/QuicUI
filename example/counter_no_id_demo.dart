import 'package:flutter/material.dart';
import 'package:quicui/quicui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuicUI Counter without ID',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CounterPage(),
    );
  }
}

class CounterPage extends StatefulWidget {
  const CounterPage({Key? key}) : super(key: key);

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int counter = 0;

  // Define counter app structure WITHOUT any id fields
  late final counterAppConfig = WidgetData(
    type: 'Scaffold',
    properties: {'backgroundColor': '#FFFFFF'},
    children: [
      // AppBar - NO ID
      WidgetData(
        type: 'AppBar',
        properties: {
          'title': 'Counter App (No IDs)',
          'backgroundColor': '#2196F3',
        },
      ),
      // Center with Column - NO ID
      WidgetData(
        type: 'Center',
        properties: {},
        children: [
          WidgetData(
            type: 'Column',
            properties: {
              'mainAxisAlignment': 'center',
              'crossAxisAlignment': 'center',
            },
            children: [
              // Description text - NO ID
              WidgetData(
                type: 'Text',
                properties: {
                  'text': 'You have pushed the button this many times:',
                  'style': {'fontSize': 16, 'color': '#666666'},
                },
              ),
              // Counter display - NO ID
              WidgetData(
                type: 'Text',
                properties: {
                  'text': counter.toString(),
                  'style': {
                    'fontSize': 72,
                    'fontWeight': 'bold',
                    'color': '#2196F3',
                  },
                },
              ),
              // Padding spacer - NO ID
              WidgetData(
                type: 'SizedBox',
                properties: {'height': 50},
              ),
              // Button section - NO ID
              WidgetData(
                type: 'Row',
                properties: {
                  'mainAxisAlignment': 'center',
                  'crossAxisAlignment': 'center',
                },
                children: [
                  // Decrement button - NO ID
                  WidgetData(
                    type: 'ElevatedButton',
                    properties: {
                      'label': '-',
                      'backgroundColor': '#FF5722',
                    },
                  ),
                  // Spacer - NO ID
                  WidgetData(
                    type: 'SizedBox',
                    properties: {'width': 20},
                  ),
                  // Increment button - NO ID
                  WidgetData(
                    type: 'ElevatedButton',
                    properties: {
                      'label': '+',
                      'backgroundColor': '#4CAF50',
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuicUI Counter - No ID Fields'),
        backgroundColor: const Color(0xFF2196F3),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WidgetData Structure (NO id fields):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    _buildConfigDisplay(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Counter Value:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Center(
                child: Column(
                  children: [
                    Text(
                      counter.toString(),
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => setState(() => counter--),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5722),
                          ),
                          child: const Text('Decrement', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () => setState(() => counter++),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                          ),
                          child: const Text('Increment', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Test Results:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTestResult(
                      'Root widget has no ID',
                      counterAppConfig.id == null,
                    ),
                    _buildTestResult(
                      'All children have no ID',
                      counterAppConfig.children?.every((w) => w.id == null) ?? false,
                    ),
                    _buildTestResult(
                      'Nested widgets have no ID',
                      _checkAllWidgetsHaveNoId(counterAppConfig),
                    ),
                    _buildTestResult(
                      'Structure is valid',
                      counterAppConfig.type == 'Scaffold' && (counterAppConfig.children?.length ?? 0) >= 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _checkAllWidgetsHaveNoId(WidgetData widget) {
    if (widget.id != null) return false;
    if (widget.children != null) {
      for (final child in widget.children!) {
        if (!_checkAllWidgetsHaveNoId(child)) return false;
      }
    }
    return true;
  }

  Widget _buildTestResult(String label, bool passed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            color: passed ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: passed ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _buildConfigDisplay() {
    return '''
WidgetData(
  type: 'Scaffold',
  id: null,  ✓ Optional
  children: [
    WidgetData(
      type: 'AppBar',
      id: null,  ✓ Optional
      properties: {...}
    ),
    WidgetData(
      type: 'Center',
      id: null,  ✓ Optional
      children: [
        WidgetData(
          type: 'Column',
          id: null,  ✓ Optional
          ...
        )
      ]
    ),
    ...
  ]
)

✓ ALL WIDGETS CREATED 
  WITHOUT ID FIELDS
✓ NO EXCEPTIONS THROWN
✓ STRUCTURE IS VALID
    ''';
  }
}
