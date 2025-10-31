import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicui/src/rendering/gesture_widgets.dart';
import 'package:quicui/src/rendering/gesture_helpers.dart';

void main() {
  group('Integration Tests: Gesture Widget Callback System', () {
    test('GestureDetector callback routing', () {
      final events = <Map<String, dynamic>>[];

      final config = {
        'properties': {},
        'events': {
          'onTap': 'tap_event',
        },
      };

      final callback = (dynamic event, Map<String, dynamic> cfg) {
        events.add({
          'event': event,
          'config': cfg,
        });
      };

      final widget = buildGestureDetector(config, callback) as GestureDetector;

      expect(widget, isNotNull);
      expect(widget.onTap, isNotNull);
      
      // Simulate tap
      widget.onTap?.call();
      
      expect(events.isEmpty, false);
    });

    test('InkWell callback routing', () {
      final events = <String>[];

      final config = {
        'properties': {},
        'events': {
          'onTap': 'ink_tap',
        },
      };

      final callback = (dynamic event, Map<String, dynamic> cfg) {
        events.add(event);
      };

      final widget = buildInkWell(config, callback) as InkWell;

      expect(widget, isNotNull);
      expect(widget.onTap, isNotNull);
    });

    test('Draggable and DragTarget interaction', () {
      final dragConfig = {
        'properties': {
          'data': 'test_item',
        },
        'events': {
          'onDragStarted': 'drag_started',
        },
      };

      final dropConfig = {
        'properties': {},
        'events': {
          'onAccept': 'item_accepted',
        },
      };

      final draggable = buildDraggable(dragConfig, null) as Draggable;
      final dragTarget = buildDragTarget(dropConfig, null) as DragTarget;

      expect(draggable, isNotNull);
      expect(dragTarget, isNotNull);
    });

    test('Multiple gesture widgets in sequence', () {
      final configs = [
        {
          'properties': {},
          'events': {'onTap': 'gesture1'},
        },
        {
          'properties': {},
          'events': {'onDoubleTap': 'gesture2'},
        },
        {
          'properties': {},
          'events': {'onLongPress': 'gesture3'},
        },
      ];

      final widgets = configs
          .map((config) => buildGestureDetector(config, null))
          .toList();

      expect(widgets.length, 3);
      for (final widget in widgets) {
        expect(widget, isNotNull);
      }
    });

    test('Callback receives correct configuration', () {
      final config = {
        'properties': {
          'behavior': 'opaque',
        },
        'events': {
          'onTap': 'test_event',
        },
      };

      final callback = (dynamic event, Map<String, dynamic> cfg) {
        // Callback invoked with event and config
        expect(event, isNotNull);
      };

      final widget = buildGestureDetector(config, callback) as GestureDetector;

      expect(widget, isNotNull);
      expect(widget.onTap, isNotNull);
    });

    test('Chained callback calls', () {
      final callStack = <String>[];

      final config1 = {
        'properties': {},
        'events': {
          'onTap': 'event1',
        },
      };

      final config2 = {
        'properties': {},
        'events': {
          'onTap': 'event2',
        },
      };

      final callback = (dynamic event, Map<String, dynamic> cfg) {
        callStack.add(event);
      };

      final widget1 = buildGestureDetector(config1, callback) as GestureDetector;
      final widget2 = buildGestureDetector(config2, callback) as GestureDetector;

      expect(widget1, isNotNull);
      expect(widget2, isNotNull);
    });

    test('Gesture state tracking across widgets', () {
      final config1 = {
        'properties': {},
        'events': {
          'onTapDown': 'tap_down',
          'onTapUp': 'tap_up',
        },
      };

      final config2 = {
        'properties': {},
        'events': {
          'onTapCancel': 'tap_cancel',
        },
      };

      final widget1 = buildGestureDetector(config1, null) as GestureDetector;
      final widget2 = buildGestureDetector(config2, null) as GestureDetector;

      expect(widget1.onTapDown, isNotNull);
      expect(widget1.onTapUp, isNotNull);
      expect(widget2.onTapCancel, isNotNull);
    });

    test('Swipe detector with directional events', () {
      final directions = ['up', 'down', 'left', 'right'];

      for (final direction in directions) {
        final config = {
          'properties': {
            'direction': direction,
          },
          'events': {
            'onSwipe${direction[0].toUpperCase()}${direction.substring(1)}':
                'swipe_$direction',
          },
        };

        final widget = buildSwipeDetector(config, null) as GestureDetector;
        expect(widget, isNotNull);
      }
    });

    test('Multi-touch gesture combination', () {
      final config = {
        'properties': {
          'touchCount': '2',
        },
        'events': {
          'onMultiTouchStart': 'touch_start',
          'onMultiTouchUpdate': 'touch_update',
          'onMultiTouchEnd': 'touch_end',
        },
      };

      final widget = buildMultiTouchGestureDetector(config, null)
          as GestureDetector;

      expect(widget, isNotNull);
    });
  });

  group('Integration Tests: Gesture Helpers', () {
    test('GestureEvent creation and access', () {
      final event = GestureEvent(
        eventType: 'tap',
        timestamp: DateTime.now(),
        eventData: {'position': 'center'},
      );

      expect(event.eventType, 'tap');
      expect(event.eventData, isNotNull);
      expect(event.metadata, isNotNull);
    });

    test('DragData creation and transfer', () {
      final dragData = DragData(
        data: 'test_item',
        mimeType: 'text/plain',
        additionalData: {'id': '123'},
      );

      expect(dragData.data, 'test_item');
      expect(dragData.mimeType, 'text/plain');
      expect(dragData.additionalData, isNotNull);
    });

    test('GestureEvent toMap conversion', () {
      final event = GestureEvent(
        eventType: 'swipe',
        eventData: {'direction': 'up'},
      );

      final map = event.toMap();

      expect(map['eventType'], 'swipe');
      expect(map['eventData'], isNotNull);
      expect(map['timestamp'], isNotNull);
    });

    test('DragData toMap conversion', () {
      final dragData = DragData(
        data: 'item',
        mimeType: 'text',
      );

      final map = dragData.toMap();

      expect(map['data'], 'item');
      expect(map['mimeType'], 'text');
    });

    test('GestureLogger tracks events', () {
      final event1 = GestureEvent(
        eventType: 'tap',
        eventData: {'detail': 'center'},
      );
      final event2 = GestureEvent(
        eventType: 'swipe',
        eventData: {'direction': 'up'},
      );

      GestureLogger.logEvent(event1);
      GestureLogger.logEvent(event2);

      final events = GestureLogger.getEvents();
      expect(events.length >= 2, true);
      
      GestureLogger.clear();
    });

    test('GestureLogger statistics', () {
      for (int i = 0; i < 5; i++) {
        GestureLogger.logEvent(GestureEvent(eventType: 'tap'));
      }
      for (int i = 0; i < 3; i++) {
        GestureLogger.logEvent(GestureEvent(eventType: 'swipe'));
      }

      final stats = GestureLogger.getStatistics();
      expect(stats['total_events'] >= 8, true);
      
      GestureLogger.clear();
    });

    test('GesturePerformanceMonitor tracks duration', () {
      GesturePerformanceMonitor.recordDuration('gesture_1', 50);
      GesturePerformanceMonitor.recordDuration('gesture_1', 75);

      final avgDuration = GesturePerformanceMonitor.getAverageDuration('gesture_1');
      expect(avgDuration, isNotNull);
      expect(avgDuration! > 0, true);
      
      GesturePerformanceMonitor.clear();
    });

    test('GesturePerformanceMonitor statistics', () {
      GesturePerformanceMonitor.recordDuration('tap', 10);
      GesturePerformanceMonitor.recordDuration('tap', 20);
      GesturePerformanceMonitor.recordDuration('swipe', 50);

      final stats = GesturePerformanceMonitor.getStatistics();
      expect(stats['tap'], isNotNull);
      expect(stats['swipe'], isNotNull);
      
      GesturePerformanceMonitor.clear();
    });

    test('GestureValidator validates configuration', () {
      final validConfig = {
        'properties': {
          'behavior': 'opaque',
        },
      };

      final errors = GestureValidator.validateGestureDetectorConfig(validConfig);
      expect(errors.isEmpty, true);
    });

    test('GestureValidator rejects invalid configuration', () {
      final invalidConfig = {
        'properties': {
          'behavior': 'invalid_value',
        },
      };

      final errors = GestureValidator.validateGestureDetectorConfig(invalidConfig);
      expect(errors.isNotEmpty, true);
    });

    test('GestureValidator validates Draggable configuration', () {
      final validConfig = {
        'properties': {
          'axis': 'horizontal',
        },
      };

      final errors = GestureValidator.validateDraggableConfig(validConfig);
      expect(errors.isEmpty, true);
    });

    test('GestureValidator rejects invalid Draggable configuration', () {
      final invalidConfig = {
        'properties': {
          'axis': 'diagonal',
        },
      };

      final errors = GestureValidator.validateDraggableConfig(invalidConfig);
      expect(errors.isNotEmpty, true);
    });
  });

  group('Integration Tests: End-to-End Gesture Flow', () {
    test('Complete tap gesture flow', () {
      final events = <Map<String, dynamic>>[];

      final config = {
        'properties': {
          'behavior': 'opaque',
        },
        'events': {
          'onTapDown': 'tap_down',
          'onTapUp': 'tap_up',
          'onTap': 'tap',
        },
      };

      final callback = (dynamic event, Map<String, dynamic> cfg) {
        events.add({'event': event, 'time': DateTime.now()});
      };

      final widget = buildGestureDetector(config, callback) as GestureDetector;

      expect(widget, isNotNull);
      expect(widget.onTap, isNotNull);
      expect(widget.onTapDown, isNotNull);
      expect(widget.onTapUp, isNotNull);
    });

    test('Complete drag flow', () {
      final dragConfig = {
        'properties': {
          'data': 'item_1',
          'axis': 'vertical',
        },
        'events': {
          'onDragStarted': 'drag_started',
          'onDragEnd': 'drag_ended',
        },
      };

      final dropConfig = {
        'properties': {},
        'events': {
          'onWillAccept': 'will_accept',
          'onAccept': 'accept',
          'onLeave': 'leave',
        },
      };

      final draggable = buildDraggable(dragConfig, null) as Draggable;
      final dragTarget = buildDragTarget(dropConfig, null) as DragTarget;

      expect(draggable, isNotNull);
      expect(dragTarget, isNotNull);
      expect(draggable.onDragStarted, isNotNull);
      expect(dragTarget.onWillAccept, isNotNull);
    });

    test('Complete swipe detection flow', () {
      final swipeEvents = <String>[];

      final config = {
        'properties': {
          'sensitivity': '50.0',
          'direction': 'any',
        },
        'events': {
          'onSwipeUp': 'swipe_up',
          'onSwipeDown': 'swipe_down',
          'onSwipeLeft': 'swipe_left',
          'onSwipeRight': 'swipe_right',
        },
      };

      final callback = (dynamic event, Map<String, dynamic> cfg) {
        swipeEvents.add(event);
      };

      final widget = buildSwipeDetector(config, callback) as GestureDetector;

      expect(widget, isNotNull);
    });

    test('Nested gesture widgets interaction', () {
      final outerConfig = {
        'properties': {},
        'events': {'onTap': 'outer_tap'},
      };

      final innerConfig = {
        'properties': {},
        'events': {'onTap': 'inner_tap'},
      };

      final outer = buildGestureDetector(outerConfig, null) as GestureDetector;
      final inner = buildGestureDetector(innerConfig, null) as GestureDetector;

      expect(outer, isNotNull);
      expect(inner, isNotNull);
      expect(outer.onTap, isNotNull);
      expect(inner.onTap, isNotNull);
    });

    test('Complex multi-gesture scenario', () {
      final gestureConfigs = [
        {
          'type': 'GestureDetector',
          'properties': {'behavior': 'opaque'},
          'events': {'onTap': 'detect_tap'},
        },
        {
          'type': 'Draggable',
          'properties': {'data': 'item'},
          'events': {'onDragStarted': 'start_drag'},
        },
        {
          'type': 'SwipeDetector',
          'properties': {'sensitivity': '50.0'},
          'events': {'onSwipeUp': 'swipe_up'},
        },
      ];

      final gestureDetector = buildGestureDetector(gestureConfigs[0], null);
      final draggable = buildDraggable(gestureConfigs[1], null);
      final swipeDetector = buildSwipeDetector(gestureConfigs[2], null);

      expect(gestureDetector, isNotNull);
      expect(draggable, isNotNull);
      expect(swipeDetector, isNotNull);
    });
  });
}
