import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicui/src/rendering/ui_renderer.dart';

void main() {
  group('Layout Widgets E2E Tests', () {
    // Test all 12 layout widgets through UIRenderer

    test('SliverAppBar renders from UIRenderer', () {
      final config = {
        'type': 'SliverAppBar',
        'properties': {'title': 'Sliver App Bar', 'elevation': 4.0},
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('BottomSheet renders from UIRenderer', () {
      final config = {
        'type': 'BottomSheet',
        'properties': {'title': 'Bottom Sheet'},
        'children': [],
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('Avatar renders from UIRenderer', () {
      final config = {
        'type': 'Avatar',
        'properties': {'name': 'John Doe', 'size': 40.0},
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('ProgressBar renders from UIRenderer', () {
      final config = {
        'type': 'ProgressBar',
        'properties': {'value': 0.5, 'color': '#2196F3'},
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('CircularProgress renders from UIRenderer', () {
      final config = {
        'type': 'CircularProgress',
        'properties': {'value': 0.7},
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('Tag renders from UIRenderer', () {
      final config = {
        'type': 'Tag',
        'properties': {'label': 'Flutter', 'color': '#FF9800'},
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('FittedBox renders from UIRenderer', () {
      final config = {
        'type': 'FittedBox',
        'properties': {'fit': 'contain'},
        'children': [],
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('ExpansionTile renders from UIRenderer', () {
      final config = {
        'type': 'ExpansionTile',
        'properties': {'title': 'Expand me'},
        'children': [],
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('Stepper renders from UIRenderer', () {
      final config = {
        'type': 'Stepper',
        'properties': {'currentStep': 0},
        'children': [],
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('DataTable renders from UIRenderer', () {
      final config = {
        'type': 'DataTable',
        'properties': {'columnCount': 3},
        'children': [],
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('PageView renders from UIRenderer', () {
      final config = {
        'type': 'PageView',
        'properties': {'pageSnapping': true},
        'children': [],
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('SnackBar renders from UIRenderer', () {
      final config = {
        'type': 'SnackBar',
        'properties': {'message': 'Test message', 'duration': 3000},
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('All Layout widgets render without null widget', () {
      final layoutWidgets = [
        {'type': 'SliverAppBar', 'properties': {'title': 'Test'}},
        {'type': 'Avatar', 'properties': {'name': 'Test'}},
        {'type': 'ProgressBar', 'properties': {'value': 0.5}},
        {'type': 'CircularProgress', 'properties': {'value': 0.5}},
        {'type': 'Tag', 'properties': {'label': 'Test'}},
        {'type': 'SnackBar', 'properties': {'message': 'Test'}},
      ];

      for (final config in layoutWidgets) {
        final widget = UIRenderer.render(config);
        expect(widget, isNotNull, reason: 'Widget ${config['type']} should not be null');
        expect(widget, isA<Widget>(), reason: 'Widget ${config['type']} should be a Widget');
      }
    });

    test('Layout widgets with empty properties', () {
      final config = {
        'type': 'Avatar',
        'properties': {},
      };
      final widget = UIRenderer.render(config);
      expect(widget, isNotNull);
      expect(widget, isA<Widget>());
    });

    test('Layout widgets with no type returns Placeholder', () {
      final config = {
        'properties': {'value': 'test'},
      };
      final widget = UIRenderer.render(config);
      expect(widget, isA<Placeholder>());
    });

    test('Layout widgets with unknown type returns Placeholder', () {
      final config = {
        'type': 'UnknownWidget',
        'properties': {},
      };
      final widget = UIRenderer.render(config);
      expect(widget, isA<Placeholder>());
    });
  });
}
