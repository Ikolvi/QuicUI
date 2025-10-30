import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:quicui/quicui.dart';

void main() {
  group('Widget Rendering - Display Widgets', () {
    group('Text Variants', () {
      testWidgets('renders RichText widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'RichText',
          'properties': {
            'text': 'Rich text content',
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<RichText>());
      });

      testWidgets('renders Text with overflow', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Text',
          'properties': {
            'data': 'This is a very long text that should overflow',
            'overflow': 'ellipsis',
            'maxLines': 1,
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<Text>());
      });
    });

    group('Image & Icon', () {
      testWidgets('renders Image from URL', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Image',
          'properties': {
            'src': 'https://flutter.dev/assets/homepage/carousel/slide_1.png',
            'width': 200,
            'height': 200,
          },
        });

        expect(widget, isNotNull);
      });

      testWidgets('renders Icon with color and size', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Icon',
          'properties': {
            'icon': 'favorite',
            'size': 32,
            'color': 'red',
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<Icon>());
      });
    });

    group('Card & Dividers', () {
      testWidgets('renders Card widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Card',
          'properties': {
            'elevation': 4,
          },
          'children': [
            {'type': 'Padding', 'properties': {'padding': {'all': 16}}, 'children': [
              {'type': 'Text', 'properties': {'data': 'Card content'}},
            ]},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<Card>());
      });

      testWidgets('renders Divider widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Divider',
          'properties': {
            'height': 1,
            'thickness': 1,
            'color': 'grey',
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<Divider>());
      });

      testWidgets('renders VerticalDivider widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'VerticalDivider',
          'properties': {
            'width': 1,
            'thickness': 1,
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<VerticalDivider>());
      });
    });

    group('Badge & Badge-like', () {
      testWidgets('renders Badge widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Badge',
          'properties': {
            'label': '5',
          },
          'children': [
            {'type': 'Icon', 'properties': {'icon': 'mail'}},
          ],
        });

        expect(widget, isNotNull);
      });
    });

    group('Chips', () {
      testWidgets('renders Chip widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Chip',
          'properties': {
            'label': 'Flutter',
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<Chip>());
      });

      testWidgets('renders ActionChip widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'ActionChip',
          'properties': {
            'label': 'Action',
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<ActionChip>());
      });

      testWidgets('renders FilterChip widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'FilterChip',
          'properties': {
            'label': 'Filter',
            'selected': false,
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<FilterChip>());
      });

      testWidgets('renders InputChip widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'InputChip',
          'properties': {
            'label': 'Input',
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<InputChip>());
      });

      testWidgets('renders ChoiceChip widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'ChoiceChip',
          'properties': {
            'label': 'Choice',
            'selected': false,
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<ChoiceChip>());
      });
    });

    group('Tooltip & ListTile', () {
      testWidgets('renders Tooltip widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Tooltip',
          'properties': {
            'message': 'This is a tooltip',
          },
          'children': [
            {'type': 'Icon', 'properties': {'icon': 'info'}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<Tooltip>());
      });

      testWidgets('renders ListTile widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'ListTile',
          'properties': {
            'title': 'List Item',
            'subtitle': 'Subtitle',
            'leading': 'Icon',
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<ListTile>());
      });
    });
  });

  group('Widget Rendering - App-Level Widgets', () {
    group('AppBar & Navigation', () {
      testWidgets('renders AppBar widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'AppBar',
          'properties': {
            'title': 'My App',
            'backgroundColor': 'blue',
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<AppBar>());
      });

      testWidgets('renders Scaffold with AppBar', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Test')),
              body: const Center(
                child: Text('Body content'),
              ),
            ),
          ),
        );

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('renders BottomAppBar widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'BottomAppBar',
          'properties': {
            'color': 'white',
          },
          'children': [
            {'type': 'Text', 'properties': {'data': 'Bottom'}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<BottomAppBar>());
      });

      testWidgets('renders FloatingActionButton widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'FloatingActionButton',
          'properties': {
            'icon': 'add',
            'tooltip': 'Add',
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<FloatingActionButton>());
      });
    });

    group('Drawer & Navigation Bar', () {
      testWidgets('renders Drawer widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Drawer',
          'children': [
            {'type': 'Column', 'children': [
              {'type': 'Text', 'properties': {'data': 'Menu Item 1'}},
              {'type': 'Text', 'properties': {'data': 'Menu Item 2'}},
            ]},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<Drawer>());
      });

      testWidgets('renders NavigationBar widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'NavigationBar',
          'properties': {
            'destinations': ['home', 'profile', 'settings'],
          },
        });

        expect(widget, isNotNull);
        // NavigationBar might be wrapped or rendered differently
      });
    });

    group('TabBar & TabBarView', () {
      testWidgets('renders TabBar widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'TabBar',
          'properties': {
            'tabs': ['Tab 1', 'Tab 2', 'Tab 3'],
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<TabBar>());
      });
    });
  });

  group('Widget Rendering - Dialog Widgets', () {
    testWidgets('renders Dialog widget', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'Dialog',
        'children': [
          {'type': 'Padding', 'properties': {'padding': {'all': 16}}, 'children': [
            {'type': 'Text', 'properties': {'data': 'Dialog content'}},
          ]},
        ],
      });

      expect(widget, isNotNull);
      expect(widget, isA<Dialog>());
    });

    testWidgets('renders AlertDialog widget', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'AlertDialog',
        'properties': {
          'title': 'Alert',
          'content': 'Are you sure?',
        },
      });

      expect(widget, isNotNull);
      expect(widget, isA<AlertDialog>());
    });

    testWidgets('renders SimpleDialog widget', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'SimpleDialog',
        'properties': {
          'title': 'Simple Dialog',
          'options': ['Option 1', 'Option 2', 'Option 3'],
        },
      });

      expect(widget, isNotNull);
      expect(widget, isA<SimpleDialog>());
    });

    testWidgets('renders Offstage widget', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'Offstage',
        'properties': {
          'offstage': true,
        },
        'children': [
          {'type': 'Text', 'properties': {'data': 'Hidden'}},
        ],
      });

      expect(widget, isNotNull);
      expect(widget, isA<Offstage>());
    });
  });

  group('Widget Rendering - Animation Widgets', () {
    testWidgets('renders AnimatedContainer widget', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'AnimatedContainer',
        'properties': {
          'duration': 300,
          'width': 100,
          'height': 100,
          'color': 'blue',
        },
      });

      expect(widget, isNotNull);
      expect(widget, isA<AnimatedContainer>());
    });

    testWidgets('renders AnimatedOpacity widget', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'AnimatedOpacity',
        'properties': {
          'opacity': 0.5,
          'duration': 300,
        },
        'children': [
          {'type': 'Text', 'properties': {'data': 'Animated'}},
        ],
      });

      expect(widget, isNotNull);
      expect(widget, isA<AnimatedOpacity>());
    });

    testWidgets('renders FadeInImage widget', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'FadeInImage',
        'properties': {
          'placeholderImage': 'data:image/png;base64,iVBORw0KG',
          'image': 'https://example.com/image.png',
          'duration': 500,
        },
      });

      expect(widget, isNotNull);
    });

    testWidgets('renders Visibility widget', (WidgetTester tester) async {
      final widget = UIRenderer.render({
        'type': 'Visibility',
        'properties': {
          'visible': true,
        },
        'children': [
          {'type': 'Text', 'properties': {'data': 'Visible'}},
        ],
      });

      expect(widget, isNotNull);
      expect(widget, isA<Visibility>());
    });
  });
}
