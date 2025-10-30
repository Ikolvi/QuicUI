import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:quicui/quicui.dart';

void main() {
  group('Widget Rendering - Input Widgets', () {
    group('Button Widgets', () {
      testWidgets('renders ElevatedButton widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'ElevatedButton',
          'properties': {
            'label': 'Press Me',
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<ElevatedButton>());
      });

      testWidgets('renders TextButton widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'TextButton',
          'properties': {
            'label': 'Tap Me',
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<TextButton>());
      });

      testWidgets('renders OutlinedButton widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'OutlinedButton',
          'properties': {
            'label': 'Outlined',
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<OutlinedButton>());
      });

      testWidgets('renders IconButton widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'IconButton',
          'properties': {
            'icon': 'favorite',
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<IconButton>());
      });
    });

    group('TextField Widgets', () {
      testWidgets('renders TextField widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'TextField',
          'properties': {
            'hintText': 'Enter text',
            'labelText': 'Label',
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<TextField>());
      });

      testWidgets('renders TextFormField widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'TextFormField',
          'properties': {
            'hintText': 'Enter text',
            'labelText': 'Label',
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<TextFormField>());
      });

      testWidgets('renders TextField with multiline', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'TextField',
          'properties': {
            'maxLines': 5,
            'hintText': 'Enter multi-line text',
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<TextField>());
      });
    });

    group('Checkbox Widgets', () {
      testWidgets('renders Checkbox widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Checkbox',
          'properties': {
            'value': false,
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<Checkbox>());
      });

      testWidgets('renders CheckboxListTile widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'CheckboxListTile',
          'properties': {
            'title': 'Agree',
            'value': false,
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<CheckboxListTile>());
      });
    });

    group('Radio Widgets', () {
      testWidgets('renders Radio widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Radio',
          'properties': {
            'value': 1,
            'groupValue': 1,
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<Radio>());
      });

      testWidgets('renders RadioListTile widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'RadioListTile',
          'properties': {
            'title': 'Option 1',
            'value': 1,
            'groupValue': 1,
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<RadioListTile>());
      });
    });

    group('Switch Widgets', () {
      testWidgets('renders Switch widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Switch',
          'properties': {
            'value': false,
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<Switch>());
      });

      testWidgets('renders SwitchListTile widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'SwitchListTile',
          'properties': {
            'title': 'Toggle',
            'value': false,
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<SwitchListTile>());
      });
    });

    group('Slider Widgets', () {
      testWidgets('renders Slider widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Slider',
          'properties': {
            'value': 0.5,
            'min': 0,
            'max': 1,
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<Slider>());
      });

      testWidgets('renders RangeSlider widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'RangeSlider',
          'properties': {
            'start': 0.2,
            'end': 0.8,
            'min': 0,
            'max': 1,
          },
        });

        expect(widget, isNotNull);
        // RangeSlider might be wrapped or rendered as a different widget type
      });
    });

    group('Dropdown & Selection', () {
      testWidgets('renders DropdownButton widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'DropdownButton',
          'properties': {
            'value': 'Option 1',
            'items': ['Option 1', 'Option 2', 'Option 3'],
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<DropdownButton>());
      });

      testWidgets('renders SegmentedButton widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'SegmentedButton',
          'properties': {
            'segments': ['All', 'Favorites', 'Recent'],
            'selected': 'All',
          },
        });

        expect(widget, isNotNull);
      });

      testWidgets('renders PopupMenuButton widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'PopupMenuButton',
          'properties': {
            'itemBuilder': ['Edit', 'Delete', 'Share'],
          },
        });

        expect(widget, isNotNull);
        expect(widget, isA<PopupMenuButton>());
      });
    });

    group('Other Input Widgets', () {
      testWidgets('renders SearchBar widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'SearchBar',
          'properties': {
            'hintText': 'Search...',
          },
        });

        expect(widget, isNotNull);
      });

      testWidgets('renders Form widget', (WidgetTester tester) async {
        final widget = UIRenderer.render({
          'type': 'Form',
          'children': [
            {'type': 'TextFormField', 'properties': {'labelText': 'Name'}},
            {'type': 'TextFormField', 'properties': {'labelText': 'Email'}},
          ],
        });

        expect(widget, isNotNull);
        expect(widget, isA<Form>());
      });
    });
  });
}
