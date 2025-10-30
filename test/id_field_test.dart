import 'package:flutter_test/flutter_test.dart';
import 'package:quicui/quicui.dart';

void main() {
  group('WidgetData ID Field Tests', () {
    test('WidgetData can be created without id field', () {
      // This test verifies that id is optional
      final widget = WidgetData(
        type: 'text',
        properties: {'text': 'Hello'},
      );

      expect(widget, isNotNull);
      expect(widget.type, equals('text'));
      expect(widget.id, isNull); // ID should be null
      expect(widget.properties['text'], equals('Hello'));
    });

    test('WidgetData can be created with id field', () {
      final widget = WidgetData(
        type: 'text',
        id: 'my_text',
        properties: {'text': 'Hello'},
      );

      expect(widget, isNotNull);
      expect(widget.id, equals('my_text'));
    });

    test('WidgetData.fromJson works without id field', () {
      final json = {
        'type': 'text',
        'properties': {'text': 'Hello'},
      };

      final widget = WidgetData.fromJson(json);

      expect(widget, isNotNull);
      expect(widget.type, equals('text'));
      expect(widget.id, isNull);
      expect(widget.properties['text'], equals('Hello'));
    });

    test('WidgetData.fromJson works with id field', () {
      final json = {
        'type': 'text',
        'id': 'my_text',
        'properties': {'text': 'Hello'},
      };

      final widget = WidgetData.fromJson(json);

      expect(widget, isNotNull);
      expect(widget.id, equals('my_text'));
    });

    test('Complex widget tree without any id fields', () {
      final column = WidgetData(
        type: 'column',
        properties: {},
        children: [
          WidgetData(
            type: 'text',
            properties: {'text': 'Title'},
          ),
          WidgetData(
            type: 'button',
            properties: {'label': 'Click Me'},
          ),
        ],
      );

      expect(column, isNotNull);
      expect(column.id, isNull);
      expect(column.children, hasLength(2));
      expect(column.children?[0].id, isNull);
      expect(column.children?[1].id, isNull);
    });

    test('toJson preserves null id', () {
      final widget = WidgetData(
        type: 'text',
        properties: {'text': 'Hello'},
      );

      final json = widget.toJson();

      // id might not be in the json if it's null, but it should work
      expect(json['type'], equals('text'));
      expect(json['properties']['text'], equals('Hello'));
    });

    test('copyWith handles null id', () {
      final widget1 = WidgetData(
        type: 'text',
        properties: {'text': 'Hello'},
      );

      final widget2 = widget1.copyWith(
        properties: {'text': 'World'},
      );

      expect(widget2.id, isNull);
      expect(widget2.properties['text'], equals('World'));
    });

    test('Widget equality works without id', () {
      final widget1 = WidgetData(
        type: 'text',
        properties: {'text': 'Hello'},
      );

      final widget2 = WidgetData(
        type: 'text',
        properties: {'text': 'Hello'},
      );

      expect(widget1, equals(widget2));
    });

    test('Nested widget tree without any id fields renders correctly', () {
      // Verify that the counter app example from the project works without IDs
      final counterApp = WidgetData(
        type: 'Scaffold',
        properties: {'backgroundColor': '#FFFFFF'},
        children: [
          WidgetData(
            type: 'AppBar',
            properties: {
              'title': 'Counter App',
              'backgroundColor': '#2196F3',
            },
          ),
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
                  WidgetData(
                    type: 'Text',
                    properties: {
                      'text': 'Count:',
                      'style': {'fontSize': 16},
                    },
                  ),
                  WidgetData(
                    type: 'Text',
                    properties: {
                      'text': '0',
                      'style': {
                        'fontSize': 72,
                        'fontWeight': 'bold',
                        'color': '#2196F3',
                      },
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      // All widgets should have no id field
      expect(counterApp.id, isNull);
      expect(counterApp.children?[0].id, isNull);
      expect(counterApp.children?[1].id, isNull);
      expect(counterApp.children?[1].children?[0].id, isNull);
      
      // Verify structure is intact
      expect(counterApp.type, equals('Scaffold'));
      expect(counterApp.children, hasLength(2));
      expect(counterApp.children?[1].children?[0].children, hasLength(2));
    });
  });
}
