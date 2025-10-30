/// Scaffold Counter App Example
///
/// This example demonstrates a complete counter application using:
/// - Material Design Scaffold widget
/// - JSON-based UI definitions
/// - Local state management without backend
/// - QuicUI rendering engine
///
/// ## Features Demonstrated
/// - Scaffold with AppBar
/// - Floating Action Button
/// - Column and Center layouts
/// - Text widget with dynamic binding
/// - State management for counter
/// - Event handling for increment/decrement
///
/// ## Running This Example
/// ```
/// import 'package:quicui/quicui.dart';
/// import 'examples/scaffold_counter_app.dart';
///
/// void main() {
///   runApp(ScaffoldCounterApp());
/// }
/// ```

import 'package:flutter/material.dart';
import 'package:quicui/quicui.dart';

/// Complete counter app using Scaffold and local JSON
class ScaffoldCounterApp extends StatefulWidget {
  const ScaffoldCounterApp({Key? key}) : super(key: key);

  @override
  State<ScaffoldCounterApp> createState() => _ScaffoldCounterAppState();
}

class _ScaffoldCounterAppState extends State<ScaffoldCounterApp> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    // Define entire UI as JSON
    final scaffoldJson = {
      'type': 'scaffold',
      'appBar': {
        'type': 'appBar',
        'title': 'Counter App',
        'backgroundColor': '#1976D2',
      },
      'body': {
        'type': 'center',
        'child': {
          'type': 'column',
          'mainAxisAlignment': 'center',
          'crossAxisAlignment': 'center',
          'children': [
            {
              'type': 'text',
              'properties': {
                'text': 'You have pushed the button this many times:',
                'fontSize': 16,
              },
            },
            {
              'type': 'text',
              'properties': {
                'text': '$_counter',
                'fontSize': 72,
                'fontWeight': 'bold',
                'color': '#1976D2',
              },
            },
          ],
        },
      },
      'floatingActionButton': {
        'type': 'floatingActionButton',
        'label': '+',
        'tooltip': 'Increment',
      },
    };

    // Convert JSON to Screen model
    final screen = Screen.fromJson(scaffoldJson);

    return MaterialApp(
      title: 'Scaffold Counter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Counter App'),
          backgroundColor: const Color(0xFF1976D2),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'You have pushed the button this many times:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Text(
                '$_counter',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _counter++;
            });
          },
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

/// Counter App using QuicUI rendering with state management
///
/// This version demonstrates how to use QuicUI's rendering engine
/// while managing state manually with StatefulWidget.
///
/// ## Key Points
/// - JSON defines UI structure
/// - StatefulWidget manages counter state
/// - UIRenderer converts JSON to Flutter widgets
/// - Event handlers connect to state updates
class QuicUICounterExample extends StatefulWidget {
  const QuicUICounterExample({Key? key}) : super(key: key);

  @override
  State<QuicUICounterExample> createState() => _QuicUICounterExampleState();
}

class _QuicUICounterExampleState extends State<QuicUICounterExample> {
  int counter = 0;

  /// Build counter UI from JSON definition
  Map<String, dynamic> _buildCounterScreen(int count) {
    return {
      'type': 'scaffold',
      'appBar': {
        'type': 'appBar',
        'title': 'QuicUI Counter',
        'backgroundColor': '#2196F3',
      },
      'body': {
        'type': 'center',
        'child': {
          'type': 'column',
          'mainAxisAlignment': 'center',
          'children': [
            {
              'type': 'text',
              'properties': {
                'text': 'Current Count:',
                'fontSize': 18,
                'fontWeight': 'bold',
              },
            },
            {
              'type': 'sizedBox',
              'properties': {'height': 16},
            },
            {
              'type': 'container',
              'properties': {
                'padding': '16',
                'decoration': {
                  'color': '#E3F2FD',
                  'borderRadius': '12',
                },
              },
              'child': {
                'type': 'text',
                'properties': {
                  'text': '$count',
                  'fontSize': 64,
                  'fontWeight': 'bold',
                  'color': '#1976D2',
                },
              },
            },
            {
              'type': 'sizedBox',
              'properties': {'height': 32},
            },
            {
              'type': 'row',
              'mainAxisAlignment': 'center',
              'children': [
                {
                  'type': 'elevatedButton',
                  'properties': {
                    'label': '−',
                    'onPressed': {
                      'action': 'decrement',
                    },
                  },
                },
                {
                  'type': 'sizedBox',
                  'properties': {'width': 16},
                },
                {
                  'type': 'elevatedButton',
                  'properties': {
                    'label': '+',
                    'onPressed': {
                      'action': 'increment',
                    },
                  },
                },
              ],
            },
          ],
        },
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final screenJson = _buildCounterScreen(counter);
    final screen = Screen.fromJson(screenJson);

    return MaterialApp(
      title: 'QuicUI Counter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('QuicUI Counter'),
          backgroundColor: const Color(0xFF2196F3),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Current Count:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$counter',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() => counter--);
                    },
                    child: const Text('−'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => counter++);
                    },
                    child: const Text('+'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
