import 'package:flutter/material.dart';
import 'package:quicui/quicui.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuicUI Error Handling Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ErrorHandlingDemo(),
    );
  }
}

class ErrorHandlingDemo extends StatelessWidget {
  const ErrorHandlingDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuicUI Error Handling Demo'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Working example
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✅ Working JSON Example',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This demonstrates proper JSON rendering with error handling:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildWorkingExample(),
                ],
              ),
            ),
          ),
          
          // Error examples
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ Error Handling Examples',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These demonstrate graceful error handling:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  _buildErrorExamples(),
                ],
              ),
            ),
          ),
          
          // Validation info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔍 JSON Validation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use the CLI tool to validate JSON files:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'dart run quicui:validate\ndart run quicui:validate --file error_test.json\ndart run quicui:validate --watch',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingExample() {
    // Valid JSON configuration
    const validJson = {
      "type": "Container",
      "properties": {
        "padding": {"all": 12},
        "decoration": {
          "color": "#E8F5E8",
          "borderRadius": 8
        }
      },
      "children": [
        {
          "type": "Column",
          "properties": {
            "mainAxisSize": "min"
          },
          "children": [
            {
              "type": "Text",
              "properties": {
                "text": "✅ This text renders correctly",
                "style": {
                  "fontSize": 16,
                  "color": "#2E7D32"
                }
              }
            },
            {
              "type": "SizedBox",
              "properties": {"height": 8}
            },
            {
              "type": "ElevatedButton",
              "properties": {
                "text": "Working Button",
                "style": {
                  "backgroundColor": "#4CAF50"
                }
              }
            }
          ]
        }
      ]
    };

    return UIRenderer.render(validJson);
  }

  Widget _buildErrorExamples() {
    return Column(
      children: [
        // Missing required field example
        _buildErrorSection(
          'Missing Required Field',
          {
            "type": "Text",
            "properties": {
              // Missing "text" property - should show fallback
              "style": {"color": "#F44336"}
            }
          },
        ),
        
        const SizedBox(height: 16),
        
        // Invalid property type example
        _buildErrorSection(
          'Invalid Property Types',
          {
            "type": "Text",
            "properties": {
              "text": "Text with invalid properties",
              "fontSize": "not_a_number", // Invalid type
              "color": "#INVALID_COLOR", // Invalid color
            }
          },
        ),
        
        const SizedBox(height: 16),
        
        // Unsupported widget example
        _buildErrorSection(
          'Unsupported Widget Type',
          {
            "type": "NonExistentWidget",
            "properties": {
              "someProperty": "someValue"
            }
          },
        ),
      ],
    );
  }

  Widget _buildErrorSection(String title, Map<String, dynamic> errorJson) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[50],
            border: Border.all(color: Colors.red[200]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: UIRenderer.render(errorJson), // This will use our error handling
        ),
      ],
    );
  }
}
