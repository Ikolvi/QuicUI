import 'package:flutter/material.dart';
import 'package:quicui/quicui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await QuicUIManager.initialize();
  runApp(const QuicUIExampleApp());
}

class QuicUIExampleApp extends StatelessWidget {
  const QuicUIExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuicUI Examples',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ExampleSelector(),
    );
  }
}

class ExampleSelector extends StatefulWidget {
  const ExampleSelector({Key? key}) : super(key: key);

  @override
  State<ExampleSelector> createState() => _ExampleSelectorState();
}

class _ExampleSelectorState extends State<ExampleSelector> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuicUI Examples'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildExampleCard(
            context,
            'Counter App',
            'Simple state management with QuicUI',
            _getCounterJson(),
          ),
          _buildExampleCard(
            context,
            'Form App',
            'Input handling and validation',
            _getFormJson(),
          ),
          _buildExampleCard(
            context,
            'Todo App',
            'CRUD operations and list management',
            _getTodoJson(),
          ),
          _buildExampleCard(
            context,
            'Dashboard',
            'Complex layouts and data binding',
            _getDashboardJson(),
          ),
          _buildExampleCard(
            context,
            'Offline Sync',
            'Offline-first with synchronization',
            _getOfflineSyncJson(),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context,
    String title,
    String description,
    String json,
  ) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: ListTile(
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExampleScreen(
                title: title,
                jsonData: json,
              ),
            ),
          );
        },
      ),
    );
  }

  String _getCounterJson() {
    return '''
    {
      "type": "scaffold",
      "appBar": {
        "type": "appbar",
        "title": "Counter App"
      },
      "body": {
        "type": "column",
        "properties": {
          "padding": "16",
          "mainAxisAlignment": "center"
        },
        "children": [
          {
            "type": "text",
            "properties": {
              "text": "You have pushed the button this many times:",
              "fontSize": 18
            }
          },
          {
            "type": "text",
            "properties": {
              "text": "0",
              "fontSize": 54,
              "fontWeight": "bold",
              "color": "#6366F1"
            }
          },
          {
            "type": "button",
            "properties": {
              "label": "Increment"
            }
          }
        ]
      }
    }
    ''';
  }

  String _getFormJson() {
    return '''
    {
      "type": "scaffold",
      "appBar": {
        "type": "appbar",
        "title": "Form Example"
      },
      "body": {
        "type": "column",
        "properties": {
          "padding": "16"
        },
        "children": [
          {
            "type": "text",
            "properties": {
              "text": "Contact Form",
              "fontSize": 24,
              "fontWeight": "bold"
            }
          },
          {
            "type": "textfield",
            "properties": {
              "label": "Name",
              "hint": "Enter your name"
            }
          },
          {
            "type": "textfield",
            "properties": {
              "label": "Email",
              "hint": "Enter your email"
            }
          },
          {
            "type": "button",
            "properties": {
              "label": "Submit"
            }
          }
        ]
      }
    }
    ''';
  }

  String _getTodoJson() {
    return '''
    {
      "type": "scaffold",
      "appBar": {
        "type": "appbar",
        "title": "Todo List"
      },
      "body": {
        "type": "column",
        "children": [
          {
            "type": "listview",
            "children": [
              {
                "type": "card",
                "child": {
                  "type": "row",
                  "properties": {"padding": "12"},
                  "children": [
                    {
                      "type": "checkbox",
                      "properties": {"value": false}
                    },
                    {
                      "type": "text",
                      "properties": {"text": "Sample Todo Item"}
                    }
                  ]
                }
              }
            ]
          }
        ]
      }
    }
    ''';
  }

  String _getDashboardJson() {
    return '''
    {
      "type": "scaffold",
      "appBar": {
        "type": "appbar",
        "title": "Dashboard"
      },
      "body": {
        "type": "column",
        "properties": {"padding": "16"},
        "children": [
          {
            "type": "text",
            "properties": {
              "text": "Dashboard",
              "fontSize": 28,
              "fontWeight": "bold"
            }
          },
          {
            "type": "row",
            "children": [
              {
                "type": "card",
                "properties": {"flex": 1},
                "child": {
                  "type": "column",
                  "properties": {"padding": "12"},
                  "children": [
                    {
                      "type": "text",
                      "properties": {"text": "Users"}
                    },
                    {
                      "type": "text",
                      "properties": {
                        "text": "1,234",
                        "fontSize": 24,
                        "fontWeight": "bold"
                      }
                    }
                  ]
                }
              }
            ]
          }
        ]
      }
    }
    ''';
  }

  String _getOfflineSyncJson() {
    return '''
    {
      "type": "scaffold",
      "appBar": {
        "type": "appbar",
        "title": "Offline Sync"
      },
      "body": {
        "type": "column",
        "properties": {"padding": "16"},
        "children": [
          {
            "type": "text",
            "properties": {
              "text": "Offline-First Example",
              "fontSize": 24,
              "fontWeight": "bold"
            }
          },
          {
            "type": "text",
            "properties": {
              "text": "Data is cached locally and synced when online"
            }
          },
          {
            "type": "button",
            "properties": {
              "label": "Sync Now"
            }
          }
        ]
      }
    }
    ''';
  }
}

class ExampleScreen extends StatelessWidget {
  final String title;
  final String jsonData;

  const ExampleScreen({
    Key? key,
    required this.title,
    required this.jsonData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'JSON Configuration:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    jsonData,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'This example demonstrates how to define UI with JSON.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
