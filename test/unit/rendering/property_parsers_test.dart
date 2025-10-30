import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:quicui/quicui.dart';

void main() {
  group('Widget Rendering - Text Widget', () {
    testWidgets('renders Text widget with data', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'Text',
        'properties': {
          'data': 'Hello, World!',
        },
      });

      expect(widget, isNotNull);
      expect(widget, isA<Text>());
    });

    testWidgets('renders Text widget with style properties', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'Text',
        'properties': {
          'data': 'Styled Text',
          'fontSize': 24,
          'fontWeight': 'w700',
          'color': 'red',
        },
      });

      expect(widget, isNotNull);
      expect(widget, isA<Text>());
    });

    testWidgets('renders Text widget with null data', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'Text',
      });

      expect(widget, isNotNull);
      expect(widget, isA<Text>());
    });

    testWidgets('renders Text with textAlign', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'Text',
        'properties': {
          'data': 'Centered Text',
          'textAlign': 'center',
        },
      });

      expect(widget, isNotNull);
      expect(widget, isA<Text>());
    });
  });

  group('Widget Rendering - Container Widget', () {
    testWidgets('renders Container widget with size', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'Container',
        'properties': {
          'width': 100,
          'height': 100,
        },
      });

      expect(widget, isNotNull);
      expect(widget, isA<Container>());
    });

    testWidgets('Container with decoration', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'Container',
        'properties': {
          'width': 100,
          'height': 100,
          'color': 'blue',
        },
      });

      expect(widget, isNotNull);
      expect(widget, isA<Container>());
    });
  });

  group('Widget Rendering - Column Widget', () {
    testWidgets('renders Column widget', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'Column',
        'children': [
          {'type': 'Text', 'properties': {'data': 'Item 1'}},
          {'type': 'Text', 'properties': {'data': 'Item 2'}},
        ],
      });

      expect(widget, isNotNull);
      expect(widget, isA<Column>());
    });

    testWidgets('Column with alignment', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'Column',
        'properties': {
          'mainAxisAlignment': 'center',
          'crossAxisAlignment': 'center',
        },
        'children': [],
      });

      expect(widget, isNotNull);
      expect(widget, isA<Column>());
    });
  });

  group('Widget Rendering - Row Widget', () {
    testWidgets('renders Row widget', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'Row',
        'children': [
          {'type': 'Text', 'properties': {'data': 'Item 1'}},
          {'type': 'Text', 'properties': {'data': 'Item 2'}},
        ],
      });

      expect(widget, isNotNull);
      expect(widget, isA<Row>());
    });
  });

  group('Widget Rendering - Icon Widget', () {
    testWidgets('renders Icon widget', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'Icon',
        'properties': {
          'icon': 'home',
          'size': 24,
          'color': 'blue',
        },
      });

      expect(widget, isNotNull);
      expect(widget, isA<Icon>());
    });
  });

  group('Widget Rendering - Image Widget', () {
    testWidgets('renders Image widget', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'Image',
        'properties': {
          'src': 'https://example.com/image.png',
          'width': 100,
          'height': 100,
        },
      });

      expect(widget, isNotNull);
      // Image or error widget for invalid URL
    });
  });

  group('Error Handling', () {
    testWidgets('handles missing type gracefully', (WidgetTester tester) async {
      final widget = UIRenderer.render({});

      expect(widget, isNotNull);
      // Should render placeholder or error widget
    });

    testWidgets('handles unknown widget type', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'UnknownWidget',
      });

      expect(widget, isNotNull);
      // Should render error widget
    });

    testWidgets('handles shouldRender false', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'Text',
        'shouldRender': false,
        'properties': {
          'data': 'Hidden Text',
        },
      });

      expect(widget, isNotNull);
      expect(widget, isA<SizedBox>());
    });
  });
}
