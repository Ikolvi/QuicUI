import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicui/quicui.dart';

void main() {
  group('Integration - State Management', () {
    test('Form widget with multiple fields', () {
      final json = {
        'type': 'Form',
        'child': {
          'type': 'Column',
          'children': [
            {
              'type': 'TextField',
              'label': 'Name',
              'hintText': 'Enter your name'
            },
            {'type': 'SizedBox', 'height': 16},
            {
              'type': 'TextField',
              'label': 'Email',
              'hintText': 'Enter your email'
            },
            {'type': 'SizedBox', 'height': 16},
            {
              'type': 'ElevatedButton',
              'label': 'Submit'
            }
          ]
        }
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Form>());
    });

    test('Widget hierarchy with shared state container', () {
      final json = {
        'type': 'Column',
        'children': [
          {
            'type': 'Container',
            'color': '#E8F5E9',
            'padding': 16,
            'child': {
              'type': 'Column',
              'children': [
                {'type': 'Text', 'text': 'Form Header'},
                {'type': 'Divider'},
                {
                  'type': 'TextField',
                  'label': 'Username'
                }
              ]
            }
          },
          {
            'type': 'Container',
            'color': '#FFF3E0',
            'padding': 16,
            'child': {
              'type': 'Column',
              'children': [
                {'type': 'Text', 'text': 'Preview'},
                {'type': 'Divider'},
                {'type': 'Text', 'text': 'Username: [Input value]'}
              ]
            }
          }
        ]
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Column>());
    });

    test('ListTile with selection state representation', () {
      final json = {
        'type': 'ListView',
        'children': [
          {
            'type': 'ListTile',
            'title': {'type': 'Text', 'text': 'Option 1'},
            'trailing': {'type': 'Radio'},
            'selected': true
          },
          {
            'type': 'ListTile',
            'title': {'type': 'Text', 'text': 'Option 2'},
            'trailing': {'type': 'Radio'},
            'selected': false
          },
          {
            'type': 'ListTile',
            'title': {'type': 'Text', 'text': 'Option 3'},
            'trailing': {'type': 'Radio'},
            'selected': false
          }
        ]
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
    });

    test('Checkbox with title and description showing state', () {
      final json = {
        'type': 'Column',
        'children': [
          {
            'type': 'CheckboxListTile',
            'title': {'type': 'Text', 'text': 'Accept terms'},
            'subtitle': {'type': 'Text', 'text': 'I agree to the terms and conditions'},
            'value': false
          },
          {
            'type': 'CheckboxListTile',
            'title': {'type': 'Text', 'text': 'Subscribe to newsletter'},
            'subtitle': {'type': 'Text', 'text': 'Get updates via email'},
            'value': true
          }
        ]
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Column>());
    });

    test('Complex form with validation state representation', () {
      final json = {
        'type': 'Form',
        'child': {
          'type': 'Column',
          'children': [
            {
              'type': 'TextField',
              'label': 'Email',
              'hintText': 'user@example.com',
              'errorText': ''
            },
            {'type': 'SizedBox', 'height': 8},
            {
              'type': 'TextField',
              'label': 'Password',
              'hintText': 'Enter password',
              'obscureText': true,
              'errorText': ''
            },
            {'type': 'SizedBox', 'height': 16},
            {
              'type': 'ElevatedButton',
              'label': 'Login'
            }
          ]
        }
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Form>());
    });
  });
}
