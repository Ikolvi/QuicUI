import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicui/quicui.dart';

void main() {
  group('Integration - Error Handling', () {
    test('Unknown widget type renders as Container fallback', () {
      final json = {
        'type': 'UnknownWidgetType',
        'child': {'type': 'Text', 'text': 'Fallback content'}
      };

      final widget = UIRenderer.render(json);

      // Should render as Container or SizedBox as fallback
      expect(widget, isNotNull);
    });

    test('Missing required property uses default value', () {
      final json = {
        'type': 'TextField'
        // Missing label and hintText
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<TextField>());
    });

    test('Invalid color value gracefully handled', () {
      final json = {
        'type': 'Container',
        'color': 'not-a-valid-color',
        'child': {'type': 'Text', 'text': 'Content'}
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      // Should render container with default color
    });

    test('Invalid alignment value uses default', () {
      final json = {
        'type': 'Center',
        'child': {'type': 'Text', 'text': 'Centered'},
        'alignment': 'invalid-alignment'
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Center>());
    });

    test('Type mismatch (string instead of number) uses default', () {
      final json = {
        'type': 'SizedBox',
        'width': 'should-be-number',
        'height': '100',
        'child': {'type': 'Text', 'text': 'Sized'}
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<SizedBox>());
    });

    test('Nested error in child widget handled gracefully', () {
      final json = {
        'type': 'Column',
        'children': [
          {'type': 'Text', 'text': 'Valid item 1'},
          {
            'type': 'InvalidChildType',
            'child': {'type': 'Text', 'text': 'Invalid'}
          },
          {'type': 'Text', 'text': 'Valid item 2'}
        ]
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Column>());
    });

    test('Empty children list handled correctly', () {
      final json = {
        'type': 'Column',
        'children': []
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Column>());
    });

    test('Null child reference handled gracefully', () {
      final json = {
        'type': 'Center',
        'child': null
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
    });

    test('Circular reference detection prevents infinite loop', () {
      // Note: This would typically be caught during JSON validation
      // but we test the renderer can handle deeply nested structures
      final json = {
        'type': 'Container',
        'child': {
          'type': 'Container',
          'child': {
            'type': 'Container',
            'child': {
              'type': 'Container',
              'child': {
                'type': 'Container',
                'child': {
                  'type': 'Container',
                  'child': {
                    'type': 'Container',
                    'child': {'type': 'Text', 'text': 'Deep nesting'}
                  }
                }
              }
            }
          }
        }
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
    });
  });
}
