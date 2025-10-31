import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicui/src/rendering/ui_renderer.dart';

void main() {
  group('Nullable Properties Tests - Container-like Widgets', () {
    test('Widget renders with completely null properties', () {
      final config = {
        'type': 'Container',
        // No 'properties' key at all
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('Widget renders with empty properties object', () {
      final config = {
        'type': 'Container',
        'properties': {},
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('Widget renders with null properties value', () {
      final config = {
        'type': 'Container',
        'properties': null,
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('Column renders without properties', () {
      final config = {
        'type': 'Column',
        'children': [
          {'type': 'Text', 'properties': {'text': 'Child 1'}},
        ],
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('Row renders without properties', () {
      final config = {
        'type': 'Row',
        'children': [],
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('Stack renders without properties', () {
      final config = {
        'type': 'Stack',
        'children': [],
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('Scaffold renders without properties', () {
      final config = {
        'type': 'Scaffold',
        // No properties
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('Avatar renders with empty properties', () {
      final config = {
        'type': 'Avatar',
        'properties': {},
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('ProgressBar renders with empty properties', () {
      final config = {
        'type': 'ProgressBar',
        'properties': {},
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('Tag renders with empty properties', () {
      final config = {
        'type': 'Tag',
        'properties': {},
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('SnackBar renders with minimal properties', () {
      final config = {
        'type': 'SnackBar',
        'properties': {},
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('Multiple nested widgets with no properties', () {
      final config = {
        'type': 'Scaffold',
        'children': [
          {
            'type': 'Container',
            // No properties
            'children': [
              {
                'type': 'Column',
                'children': [
                  {
                    'type': 'Text',
                    'properties': {},
                  },
                ],
              },
            ],
          },
        ],
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('ListView renders without properties', () {
      final config = {
        'type': 'ListView',
        'children': [],
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('GridView renders without properties', () {
      final config = {
        'type': 'GridView',
        'children': [],
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('Center renders without properties', () {
      final config = {
        'type': 'Center',
        'children': [],
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('Padding renders without properties', () {
      final config = {
        'type': 'Padding',
        'children': [],
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('Expanded renders without properties', () {
      final config = {
        'type': 'Expanded',
        'children': [],
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('SizedBox renders without properties', () {
      final config = {
        'type': 'SizedBox',
        'children': [],
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('Wrap renders without properties', () {
      final config = {
        'type': 'Wrap',
        'children': [],
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('All layout widgets handle null/empty properties gracefully', () {
      final layoutWidgets = [
        'Column',
        'Row',
        'Container',
        'Stack',
        'Center',
        'Padding',
        'Align',
        'Expanded',
        'Flexible',
        'SizedBox',
        'SingleChildScrollView',
        'ListView',
        'GridView',
        'Wrap',
        'Spacer',
      ];

      for (final widgetType in layoutWidgets) {
        final configWithNull = {
          'type': widgetType,
          'properties': null,
          'children': [],
        };
        
        final configWithEmpty = {
          'type': widgetType,
          'properties': {},
          'children': [],
        };

        final configWithoutProps = {
          'type': widgetType,
          'children': [],
        };

        expect(
          UIRenderer.render(configWithNull),
          isA<Widget>(),
          reason: '$widgetType should handle null properties',
        );

        expect(
          UIRenderer.render(configWithEmpty),
          isA<Widget>(),
          reason: '$widgetType should handle empty properties',
        );

        expect(
          UIRenderer.render(configWithoutProps),
          isA<Widget>(),
          reason: '$widgetType should handle missing properties',
        );
      }
    });

    test('All form widgets handle null/empty properties', () {
      final formWidgets = [
        'TextArea',
        'NumberInput',
        'DatePicker',
        'TimePicker',
        'ColorPicker',
        'SearchBox',
        'Rating',
        'OtpInput',
      ];

      for (final widgetType in formWidgets) {
        final config = {
          'type': widgetType,
          'properties': null,
        };
        
        expect(
          UIRenderer.render(config),
          isA<Widget>(),
          reason: '$widgetType should handle null properties',
        );
      }
    });

    test('Properties access uses null-safe pattern throughout', () {
      // This test verifies that no widget crashes when properties is null/empty
      final stressTestConfigs = [
        {'type': 'Container'},
        {'type': 'Container', 'properties': null},
        {'type': 'Container', 'properties': {}},
        {'type': 'Text'},
        {'type': 'Text', 'properties': null},
        {'type': 'AppBar'},
        {'type': 'AppBar', 'properties': null},
        {'type': 'FloatingActionButton'},
        {'type': 'FloatingActionButton', 'properties': null},
      ];

      for (final config in stressTestConfigs) {
        expect(
          UIRenderer.render(config),
          isNotNull,
          reason: 'Widget ${config['type']} should not crash with ${config['properties'] ?? 'no'} properties',
        );
      }
    });
  });
}
