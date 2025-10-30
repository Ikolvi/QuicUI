import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicui/quicui.dart';

void main() {
  group('Integration - Data Binding', () {
    test('Text widget with static data renders correctly', () {
      final json = {
        'type': 'Text',
        'text': 'Hello World',
        'style': {
          'fontSize': 16,
          'fontWeight': 'bold'
        }
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Text>());
    });

    test('Container with color binding from property', () {
      final json = {
        'type': 'Container',
        'color': '#FF5733',
        'width': 100,
        'height': 100,
        'child': {'type': 'Text', 'text': 'Colored'}
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Container>());
    });

    test('Column with conditional child visibility', () {
      final json = {
        'type': 'Column',
        'children': [
          {'type': 'Text', 'text': 'Always visible'},
          {
            'type': 'Visibility',
            'visible': true,
            'child': {'type': 'Text', 'text': 'Conditionally visible'}
          },
          {'type': 'Text', 'text': 'Also always visible'}
        ]
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Column>());
    });

    test('ListView with data-bound item structure', () {
      final json = {
        'type': 'ListView',
        'children': [
          {
            'type': 'ListTile',
            'title': {'type': 'Text', 'text': 'Item Title 1'},
            'subtitle': {'type': 'Text', 'text': 'Subtitle 1'}
          },
          {
            'type': 'ListTile',
            'title': {'type': 'Text', 'text': 'Item Title 2'},
            'subtitle': {'type': 'Text', 'text': 'Subtitle 2'}
          },
          {
            'type': 'ListTile',
            'title': {'type': 'Text', 'text': 'Item Title 3'},
            'subtitle': {'type': 'Text', 'text': 'Subtitle 3'}
          }
        ]
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
    });

    test('Slider widget with value binding', () {
      final json = {
        'type': 'Column',
        'children': [
          {'type': 'Text', 'text': 'Select a value:'},
          {
            'type': 'Slider',
            'min': 0,
            'max': 100,
            'value': 50,
            'divisions': 10
          },
          {'type': 'Text', 'text': 'Value: 50'}
        ]
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Column>());
    });

    test('TextField with placeholder and input binding', () {
      final json = {
        'type': 'Column',
        'children': [
          {
            'type': 'TextField',
            'hintText': 'Enter your name',
            'label': 'Name'
          },
          {
            'type': 'TextField',
            'hintText': 'Enter your email',
            'label': 'Email',
            'keyboardType': 'emailAddress'
          }
        ]
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Column>());
    });
  });
}
