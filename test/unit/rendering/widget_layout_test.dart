import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:quicui/quicui.dart';

void main() {
  group('Widget Rendering - Layout Widgets', () {
    group('Stack & Positioned', () {
      testWidgets('renders Stack widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Stack',
          'children': [
            {'type': 'Text', 'properties': {'data': 'Background'}},
            {
              'type': 'Positioned',
              'properties': {
                'top': 10,
                'left': 10,
                'right': 10,
                'bottom': 10,
              },
              'children': [
                {'type': 'Text', 'properties': {'data': 'Positioned'}},
              ],
            },
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<Stack>());
      });

      testWidgets('renders Positioned widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Positioned',
          'properties': {
            'top': 10,
            'left': 20,
          },
          'children': [
            {'type': 'Text', 'properties': {'data': 'Positioned Text'}},
          ],
        });

        expect(widget, isNotNull);
      });
    });

    group('Center & Align', () {
      testWidgets('renders Center widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Center',
          'children': [
            {'type': 'Text', 'properties': {'data': 'Centered'}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<Center>());
      });

      testWidgets('renders Align widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Align',
          'properties': {
            'alignment': 'topRight',
          },
          'children': [
            {'type': 'Text', 'properties': {'data': 'Aligned'}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<Align>());
      });
    });

    group('Padding & Spacing', () {
      testWidgets('renders Padding widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Padding',
          'properties': {
            'padding': {'all': 16},
          },
          'children': [
            {'type': 'Text', 'properties': {'data': 'Padded'}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<Padding>());
      });

      testWidgets('renders Spacer widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Spacer',
          'properties': {
            'flex': 1,
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<Spacer>());
      });
    });

    group('Flex Widgets', () {
      testWidgets('renders Expanded widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Expanded',
          'properties': {
            'flex': 1,
          },
          'children': [
            {'type': 'Text', 'properties': {'data': 'Expanded'}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<Expanded>());
      });

      testWidgets('renders Flexible widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Flexible',
          'properties': {
            'flex': 1,
            'fit': 'loose',
          },
          'children': [
            {'type': 'Text', 'properties': {'data': 'Flexible'}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<Flexible>());
      });
    });

    group('Sized Widgets', () {
      testWidgets('renders SizedBox widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'SizedBox',
          'properties': {
            'width': 100,
            'height': 100,
          },
          'children': [
            {'type': 'Text', 'properties': {'data': 'Sized'}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<SizedBox>());
      });

      testWidgets('renders AspectRatio widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'AspectRatio',
          'properties': {
            'aspectRatio': 16 / 9,
          },
          'children': [
            {'type': 'Text', 'properties': {'data': 'AspectRatio'}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<AspectRatio>());
      });
    });

    group('Scroll Widgets', () {
      testWidgets('renders SingleChildScrollView widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'SingleChildScrollView',
          'children': [
            {'type': 'Text', 'properties': {'data': 'Scrollable content'}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<SingleChildScrollView>());
      });

      testWidgets('renders ListView widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'ListView',
          'children': [
            {'type': 'Text', 'properties': {'data': 'Item 1'}},
            {'type': 'Text', 'properties': {'data': 'Item 2'}},
            {'type': 'Text', 'properties': {'data': 'Item 3'}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<ListView>());
      });

      testWidgets('renders GridView widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'GridView',
          'properties': {
            'crossAxisCount': 2,
          },
          'children': [
            {'type': 'Container', 'properties': {'width': 100, 'height': 100}},
            {'type': 'Container', 'properties': {'width': 100, 'height': 100}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<GridView>());
      });
    });

    group('Wrap & Flow', () {
      testWidgets('renders Wrap widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Wrap',
          'properties': {
            'spacing': 8,
            'runSpacing': 8,
          },
          'children': [
            {'type': 'Chip', 'properties': {'label': 'Tag 1'}},
            {'type': 'Chip', 'properties': {'label': 'Tag 2'}},
            {'type': 'Chip', 'properties': {'label': 'Tag 3'}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<Wrap>());
      });
    });

    group('Transform Widgets', () {
      testWidgets('renders Transform widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Transform',
          'properties': {
            'scaleX': 1.5,
            'scaleY': 1.5,
          },
          'children': [
            {'type': 'Text', 'properties': {'data': 'Scaled'}},
          ],
        });

        expect(widget, isNotNull);
      });

      testWidgets('renders Opacity widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Opacity',
          'properties': {
            'opacity': 0.5,
          },
          'children': [
            {'type': 'Text', 'properties': {'data': 'Semi-transparent'}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<Opacity>());
      });
    });

    group('Clip Widgets', () {
      testWidgets('renders ClipRect widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'ClipRect',
          'children': [
            {'type': 'Text', 'properties': {'data': 'Clipped'}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<ClipRect>());
      });

      testWidgets('renders ClipRRect widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'ClipRRect',
          'properties': {
            'borderRadius': 8,
          },
          'children': [
            {'type': 'Text', 'properties': {'data': 'Rounded clipped'}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<ClipRRect>());
      });

      testWidgets('renders ClipOval widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'ClipOval',
          'children': [
            {'type': 'Container', 'properties': {'width': 100, 'height': 100}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<ClipOval>());
      });
    });

    group('Other Layout Widgets', () {
      testWidgets('renders DecoratedBox widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'DecoratedBox',
          'properties': {
            'decoration': {
              'color': 'blue',
              'borderRadius': 8,
            },
          },
          'children': [
            {'type': 'Text', 'properties': {'data': 'Decorated'}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<DecoratedBox>());
      });

      testWidgets('renders IntrinsicHeight widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'IntrinsicHeight',
          'children': [
            {'type': 'Text', 'properties': {'data': 'Intrinsic'}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<IntrinsicHeight>());
      });

      testWidgets('renders IntrinsicWidth widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'IntrinsicWidth',
          'children': [
            {'type': 'Text', 'properties': {'data': 'Intrinsic'}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<IntrinsicWidth>());
      });
    });
  });
}
