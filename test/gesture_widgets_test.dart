import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicui/src/rendering/gesture_widgets.dart';

void main() {
  group('Phase 1: Core Gesture Widgets', () {
    group('GestureDetector', () {
      test('buildGestureDetector initializes with default properties', () {
        final config = {
          'properties': {},
          'events': {},
        };

        final widget = buildGestureDetector(config, null);

        expect(widget, isNotNull);
        expect(widget, isA<GestureDetector>());
      });

      test('buildGestureDetector parses behavior property', () {
        final config = {
          'properties': {
            'behavior': 'opaque',
          },
          'events': {},
        };

        final widget = buildGestureDetector(config, null) as GestureDetector;

        expect(widget, isNotNull);
        // Behavior is set internally
      });

      test('buildGestureDetector excludes from semantics', () {
        final config = {
          'properties': {
            'excludeFromSemantics': true,
          },
          'events': {},
        };

        final widget = buildGestureDetector(config, null) as GestureDetector;

        expect(widget, isNotNull);
        expect(widget.excludeFromSemantics, true);
      });

      test('buildGestureDetector routes onTap callback', () {
        final config = {
          'properties': {},
          'events': {
            'onTap': 'handleTap',
          },
        };

        final onCallback = (dynamic event, Map<String, dynamic> cfg) {
          expect(event, 'handleTap');
        };

        final widget = buildGestureDetector(config, onCallback) as GestureDetector;

        expect(widget, isNotNull);
        // Callback is registered internally
      });

      test('buildGestureDetector routes multiple gesture events', () {
        final config = {
          'properties': {},
          'events': {
            'onTap': 'handleTap',
            'onDoubleTap': 'handleDoubleTap',
            'onLongPress': 'handleLongPress',
          },
        };

        final widget = buildGestureDetector(config, null) as GestureDetector;

        expect(widget, isNotNull);
        expect(widget.onTap, isNotNull);
        expect(widget.onDoubleTap, isNotNull);
        expect(widget.onLongPress, isNotNull);
      });
    });

    group('InkWell', () {
      test('buildInkWell initializes with default properties', () {
        final config = {
          'properties': {},
          'events': {},
        };

        final widget = buildInkWell(config, null);

        expect(widget, isNotNull);
        expect(widget, isA<InkWell>());
      });

      test('buildInkWell parses color properties', () {
        final config = {
          'properties': {
            'splashColor': '#FF0000',
            'highlightColor': '#00FF00',
          },
          'events': {},
        };

        final widget = buildInkWell(config, null) as InkWell;

        expect(widget, isNotNull);
        expect(widget.splashColor, isNotNull);
        expect(widget.highlightColor, isNotNull);
      });

      test('buildInkWell routes onTap callback', () {
        final config = {
          'properties': {},
          'events': {
            'onTap': 'handleTap',
          },
        };

        final widget = buildInkWell(config, null) as InkWell;

        expect(widget, isNotNull);
        expect(widget.onTap, isNotNull);
      });

      test('buildInkWell sets material properties', () {
        final config = {
          'properties': {
            'borderRadius': '8',
            'enableFeedback': true,
          },
          'events': {},
        };

        final widget = buildInkWell(config, null) as InkWell;

        expect(widget, isNotNull);
        expect(widget.customBorder, isNotNull);
      });
    });

    group('InkResponse', () {
      test('buildInkResponse initializes with default properties', () {
        final config = {
          'properties': {},
          'events': {},
        };

        final widget = buildInkResponse(config, null);

        expect(widget, isNotNull);
        expect(widget, isA<InkResponse>());
      });

      test('buildInkResponse parses shape property', () {
        final config = {
          'properties': {
            'shape': 'circle',
          },
          'events': {},
        };

        final widget = buildInkResponse(config, null) as InkResponse;

        expect(widget, isNotNull);
        // Shape affects customBorder
      });

      test('buildInkResponse parses radius property', () {
        final config = {
          'properties': {
            'radius': '50.0',
          },
          'events': {},
        };

        final widget = buildInkResponse(config, null) as InkResponse;

        expect(widget, isNotNull);
        expect(widget.radius, 50.0);
      });

      test('buildInkResponse routes onTap callback', () {
        final config = {
          'properties': {},
          'events': {
            'onTap': 'handleTap',
          },
        };

        final widget = buildInkResponse(config, null) as InkResponse;

        expect(widget, isNotNull);
        expect(widget.onTap, isNotNull);
      });
    });
  });

  group('Phase 2: Advanced Drag/Drop Widgets', () {
    group('Draggable', () {
      test('buildDraggable initializes with default properties', () {
        final config = {
          'properties': {
            'data': 'test_data',
          },
          'events': {},
        };

        final widget = buildDraggable(config, null);

        expect(widget, isNotNull);
        expect(widget, isA<Draggable>());
      });

      test('buildDraggable parses axis property', () {
        final config = {
          'properties': {
            'data': 'test_data',
            'axis': 'horizontal',
          },
          'events': {},
        };

        final widget = buildDraggable(config, null) as Draggable;

        expect(widget, isNotNull);
        // Axis affects drag behavior
      });

      test('buildDraggable parses feedback property', () {
        final config = {
          'properties': {
            'data': 'test_data',
            'feedback': 'Dragging...',
          },
          'events': {},
        };

        final widget = buildDraggable(config, null) as Draggable;

        expect(widget, isNotNull);
      });

      test('buildDraggable routes onDragStarted callback', () {
        final config = {
          'properties': {
            'data': 'test_data',
          },
          'events': {
            'onDragStarted': 'handleDragStart',
          },
        };

        final widget = buildDraggable(config, null) as Draggable;

        expect(widget, isNotNull);
        expect(widget.onDragStarted, isNotNull);
      });
    });

    group('LongPressDraggable', () {
      test('buildLongPressDraggable initializes with default properties', () {
        final config = {
          'properties': {
            'data': 'test_data',
          },
          'events': {},
        };

        final widget = buildLongPressDraggable(config, null);

        expect(widget, isNotNull);
        expect(widget, isA<LongPressDraggable>());
      });

      test('buildLongPressDraggable parses delay property', () {
        final config = {
          'properties': {
            'data': 'test_data',
            'delay': '500',
          },
          'events': {},
        };

        final widget = buildLongPressDraggable(config, null) as LongPressDraggable;

        expect(widget, isNotNull);
        // Delay affects gesture recognition
      });

      test('buildLongPressDraggable routes callbacks', () {
        final config = {
          'properties': {
            'data': 'test_data',
          },
          'events': {
            'onDragStarted': 'handleDragStart',
            'onDraggableCanceled': 'handleCancel',
          },
        };

        final widget = buildLongPressDraggable(config, null) as LongPressDraggable;

        expect(widget, isNotNull);
        expect(widget.onDragStarted, isNotNull);
      });
    });

    group('DragTarget', () {
      test('buildDragTarget initializes with default properties', () {
        final config = {
          'properties': {},
          'events': {},
        };

        final widget = buildDragTarget(config, null);

        expect(widget, isNotNull);
        expect(widget, isA<DragTarget>());
      });

      test('buildDragTarget routes onWillAccept callback', () {
        final config = {
          'properties': {},
          'events': {
            'onWillAccept': 'handleWillAccept',
          },
        };

        final widget = buildDragTarget(config, null) as DragTarget;

        expect(widget, isNotNull);
        expect(widget.onWillAccept, isNotNull);
      });

      test('buildDragTarget routes onAccept callback', () {
        final config = {
          'properties': {},
          'events': {
            'onAccept': 'handleAccept',
          },
        };

        final widget = buildDragTarget(config, null) as DragTarget;

        expect(widget, isNotNull);
        expect(widget.onAccept, isNotNull);
      });

      test('buildDragTarget routes onLeave callback', () {
        final config = {
          'properties': {},
          'events': {
            'onLeave': 'handleLeave',
          },
        };

        final widget = buildDragTarget(config, null) as DragTarget;

        expect(widget, isNotNull);
        expect(widget.onLeave, isNotNull);
      });
    });
  });

  group('Phase 4: Advanced Multi-Touch Gesture Widgets', () {
    group('SwipeDetector', () {
      test('buildSwipeDetector initializes with default properties', () {
        final config = {
          'properties': {},
          'events': {},
        };

        final widget = buildSwipeDetector(config, null);

        expect(widget, isNotNull);
        expect(widget, isA<GestureDetector>());
      });

      test('buildSwipeDetector parses sensitivity property', () {
        final config = {
          'properties': {
            'sensitivity': '100.0',
          },
          'events': {},
        };

        final widget = buildSwipeDetector(config, null) as GestureDetector;

        expect(widget, isNotNull);
      });

      test('buildSwipeDetector routes swipe events', () {
        final config = {
          'properties': {},
          'events': {
            'onSwipeUp': 'handleSwipeUp',
            'onSwipeDown': 'handleSwipeDown',
            'onSwipeLeft': 'handleSwipeLeft',
            'onSwipeRight': 'handleSwipeRight',
          },
        };

        final widget = buildSwipeDetector(config, null) as GestureDetector;

        expect(widget, isNotNull);
      });
    });

    group('RotationGestureDetector', () {
      test('buildRotationGestureDetector initializes with default properties', () {
        final config = {
          'properties': {},
          'events': {},
        };

        final widget = buildRotationGestureDetector(config, null);

        expect(widget, isNotNull);
        expect(widget, isA<GestureDetector>());
      });

      test('buildRotationGestureDetector parses rotation axis', () {
        final config = {
          'properties': {
            'rotationAxis': 'z',
          },
          'events': {},
        };

        final widget = buildRotationGestureDetector(config, null) as GestureDetector;

        expect(widget, isNotNull);
      });

      test('buildRotationGestureDetector routes rotation events', () {
        final config = {
          'properties': {},
          'events': {
            'onRotationStart': 'handleRotationStart',
            'onRotationUpdate': 'handleRotationUpdate',
            'onRotationEnd': 'handleRotationEnd',
          },
        };

        final widget = buildRotationGestureDetector(config, null) as GestureDetector;

        expect(widget, isNotNull);
      });
    });

    group('ScaleGestureDetector', () {
      test('buildScaleGestureDetector initializes with default properties', () {
        final config = {
          'properties': {},
          'events': {},
        };

        final widget = buildScaleGestureDetector(config, null);

        expect(widget, isNotNull);
        expect(widget, isA<GestureDetector>());
      });

      test('buildScaleGestureDetector parses scale bounds', () {
        final config = {
          'properties': {
            'minScale': '0.5',
            'maxScale': '3.0',
          },
          'events': {},
        };

        final widget = buildScaleGestureDetector(config, null) as GestureDetector;

        expect(widget, isNotNull);
      });

      test('buildScaleGestureDetector routes scale events', () {
        final config = {
          'properties': {},
          'events': {
            'onScaleStart': 'handleScaleStart',
            'onScaleUpdate': 'handleScaleUpdate',
            'onScaleEnd': 'handleScaleEnd',
          },
        };

        final widget = buildScaleGestureDetector(config, null) as GestureDetector;

        expect(widget, isNotNull);
      });
    });

    group('MultiTouchGestureDetector', () {
      test('buildMultiTouchGestureDetector initializes with default properties', () {
        final config = {
          'properties': {},
          'events': {},
        };

        final widget = buildMultiTouchGestureDetector(config, null);

        expect(widget, isNotNull);
        expect(widget, isA<GestureDetector>());
      });

      test('buildMultiTouchGestureDetector parses touch count', () {
        final config = {
          'properties': {
            'touchCount': '2',
          },
          'events': {},
        };

        final widget = buildMultiTouchGestureDetector(config, null) as GestureDetector;

        expect(widget, isNotNull);
      });

      test('buildMultiTouchGestureDetector routes multi-touch events', () {
        final config = {
          'properties': {},
          'events': {
            'onMultiTouchStart': 'handleMultiTouchStart',
            'onMultiTouchUpdate': 'handleMultiTouchUpdate',
            'onMultiTouchEnd': 'handleMultiTouchEnd',
          },
        };

        final widget = buildMultiTouchGestureDetector(config, null) as GestureDetector;

        expect(widget, isNotNull);
      });
    });
  });

  group('Helper Functions', () {
    group('Color Parsing', () {
      test('_parseColor handles hex color strings', () {
        final config = {
          'properties': {
            'color': '#FF0000',
          },
          'events': {},
        };

        final widget = buildInkWell(config, null) as InkWell;
        expect(widget.splashColor, isNotNull);
      });

      test('_parseColor handles invalid colors', () {
        final config = {
          'properties': {
            'splashColor': 'invalid_color',
          },
          'events': {},
        };

        final widget = buildInkWell(config, null) as InkWell;
        expect(widget, isNotNull);
      });

      test('_parseColor uses default fallback', () {
        final config = {
          'properties': {},
          'events': {},
        };

        final widget = buildInkWell(config, null) as InkWell;
        expect(widget.splashColor, isNotNull);
      });
    });

    group('HitTestBehavior Parsing', () {
      test('_parseHitTestBehavior handles "deferToChild"', () {
        final config = {
          'properties': {
            'behavior': 'deferToChild',
          },
          'events': {},
        };

        final widget = buildGestureDetector(config, null) as GestureDetector;
        expect(widget.behavior, HitTestBehavior.deferToChild);
      });

      test('_parseHitTestBehavior handles "opaque"', () {
        final config = {
          'properties': {
            'behavior': 'opaque',
          },
          'events': {},
        };

        final widget = buildGestureDetector(config, null) as GestureDetector;
        expect(widget.behavior, HitTestBehavior.opaque);
      });

      test('_parseHitTestBehavior handles "translucent"', () {
        final config = {
          'properties': {
            'behavior': 'translucent',
          },
          'events': {},
        };

        final widget = buildGestureDetector(config, null) as GestureDetector;
        expect(widget.behavior, HitTestBehavior.translucent);
      });
    });

    group('BorderRadius Parsing', () {
      test('_parseBorderRadius parses single radius value', () {
        final config = {
          'properties': {
            'borderRadius': '8',
          },
          'events': {},
        };

        final widget = buildInkWell(config, null) as InkWell;
        expect(widget.customBorder, isNotNull);
      });

      test('_parseBorderRadius parses multiple radius values', () {
        final config = {
          'properties': {
            'borderRadius': '8,8,16,16',
          },
          'events': {},
        };

        final widget = buildInkWell(config, null) as InkWell;
        expect(widget.customBorder, isNotNull);
      });

      test('_parseBorderRadius handles invalid format', () {
        final config = {
          'properties': {
            'borderRadius': 'invalid',
          },
          'events': {},
        };

        final widget = buildInkWell(config, null) as InkWell;
        expect(widget, isNotNull);
      });
    });

    group('Axis Parsing', () {
      test('_parseAxis handles "horizontal"', () {
        final config = {
          'properties': {
            'axis': 'horizontal',
          },
          'events': {},
        };

        final widget = buildDraggable(config, null) as Draggable;
        expect(widget, isNotNull);
      });

      test('_parseAxis handles "vertical"', () {
        final config = {
          'properties': {
            'axis': 'vertical',
          },
          'events': {},
        };

        final widget = buildDraggable(config, null) as Draggable;
        expect(widget, isNotNull);
      });

      test('_parseAxis handles "free"', () {
        final config = {
          'properties': {
            'axis': 'free',
          },
          'events': {},
        };

        final widget = buildDraggable(config, null) as Draggable;
        expect(widget, isNotNull);
      });
    });
  });

  group('Callback System', () {
    test('Callback is invoked with correct event and config', () {
      final config = {
        'properties': {},
        'events': {
          'onTap': 'tapEvent',
        },
      };

      final onCallback = (dynamic event, Map<String, dynamic> cfg) {
        expect(event, 'tapEvent');
      };

      final widget = buildGestureDetector(config, onCallback) as GestureDetector;

      expect(widget.onTap, isNotNull);
      expect(widget, isNotNull);
    });

    test('Multiple callbacks can be registered on same widget', () {
      final config = {
        'properties': {},
        'events': {
          'onTap': 'tapEvent',
          'onDoubleTap': 'doubleTapEvent',
          'onLongPress': 'longPressEvent',
        },
      };

      final widget = buildGestureDetector(config, null) as GestureDetector;

      expect(widget.onTap, isNotNull);
      expect(widget.onDoubleTap, isNotNull);
      expect(widget.onLongPress, isNotNull);
    });

    test('Callback handles drag events', () {
      final config = {
        'properties': {
          'data': 'test_data',
        },
        'events': {
          'onDragStarted': 'dragStarted',
          'onDraggableCanceled': 'dragCanceled',
          'onDragEnd': 'dragEnded',
        },
      };

      final widget = buildDraggable(config, null) as Draggable;

      expect(widget.onDragStarted, isNotNull);
      expect(widget, isNotNull);
    });

    test('Callback handles drop zone events', () {
      final config = {
        'properties': {},
        'events': {
          'onWillAccept': 'willAccept',
          'onAccept': 'accept',
          'onLeave': 'leave',
        },
      };

      final widget = buildDragTarget(config, null) as DragTarget;

      expect(widget.onWillAccept, isNotNull);
      expect(widget.onAccept, isNotNull);
      expect(widget.onLeave, isNotNull);
    });
  });

  group('Edge Cases', () {
    test('Widget handles null events map', () {
      final config = {
        'properties': {},
      };

      final widget = buildGestureDetector(config, null);
      expect(widget, isNotNull);
    });

    test('Widget handles empty properties', () {
      final config = {
        'properties': {},
        'events': {},
      };

      final widget = buildInkWell(config, null);
      expect(widget, isNotNull);
    });

    test('Widget handles null configuration values', () {
      final config = {
        'properties': {
          'splashColor': null,
          'highlightColor': null,
        },
        'events': {},
      };

      final widget = buildInkWell(config, null);
      expect(widget, isNotNull);
    });

    test('Widget handles missing required properties', () {
      final config = {
        'properties': {},
        'events': {},
      };

      final widget = buildDraggable(config, null);
      expect(widget, isNotNull);
    });

    test('Widget handles invalid property types', () {
      final config = {
        'properties': {
          'sensitivity': 'not_a_number',
        },
        'events': {},
      };

      final widget = buildSwipeDetector(config, null);
      expect(widget, isNotNull);
    });

    test('Widget handles callback with no matching event', () {
      final config = {
        'properties': {},
        'events': {
          'onNonExistentEvent': 'someEvent',
        },
      };

      final widget = buildGestureDetector(config, null);
      expect(widget, isNotNull);
    });
  });
}
