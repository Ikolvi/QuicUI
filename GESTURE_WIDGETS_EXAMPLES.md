/// Gesture Widgets Examples and Documentation
///
/// This file demonstrates how to use all gesture widgets in QuicUI
/// with complete JSON configuration examples.

// ============================================================================
// PHASE 1: CORE GESTURE WIDGETS EXAMPLES
// ============================================================================

/// GestureDetector - Low-level gesture detection
///
/// Best for: Custom gesture handling, complex multi-gesture interactions
///
/// Example JSON:
final gestureDetectorExample = {
  'type': 'GestureDetector',
  'properties': {
    'behavior': 'opaque',  // deferToChild, opaque, or translucent
    'excludeFromSemantics': false,
  },
  'events': {
    'onTap': {
      'action': 'navigate',
      'screen': 'details',
    },
    'onDoubleTap': {
      'action': 'executeCallback',
      'callback': 'onDoubleTapAction',
    },
    'onLongPress': {
      'action': 'showDialog',
      'title': 'Long press detected!',
    },
    'onPanStart': {
      'action': 'executeCallback',
      'callback': 'onPanStarted',
    },
    'onPanUpdate': {
      'action': 'executeCallback',
      'callback': 'onPanUpdated',
    },
    'onVerticalDragStart': {
      'action': 'executeCallback',
      'callback': 'onVerticalDragStarted',
    },
  },
  'child': {
    'type': 'Container',
    'properties': {
      'color': '#FF5E5E',
      'width': 200,
      'height': 100,
    },
    'child': {
      'type': 'Text',
      'properties': {
        'text': 'Tap, double-tap, or long-press me!',
      },
    },
  },
};

/// InkWell - Material Design tap feedback
///
/// Best for: Buttons, list items, interactive card elements
///
/// Example JSON:
final inkWellExample = {
  'type': 'InkWell',
  'properties': {
    'splashColor': '#2196F3',
    'highlightColor': '#E3F2FD',
    'hoverColor': '#BBDEFB',
    'focusColor': '#90CAF9',
    'radius': 8.0,
    'enableFeedback': true,
    'excludeFromSemantics': false,
  },
  'events': {
    'onTap': {
      'action': 'navigate',
      'screen': 'next_screen',
    },
    'onLongPress': {
      'action': 'showDialog',
      'title': 'Options',
      'content': 'What would you like to do?',
    },
  },
  'child': {
    'type': 'Container',
    'properties': {
      'padding': 16,
    },
    'child': {
      'type': 'Row',
      'properties': {
        'mainAxisAlignment': 'center',
      },
      'children': [
        {
          'type': 'Icon',
          'properties': {
            'icon': 'favorite',
            'color': '#2196F3',
          },
        },
        {
          'type': 'SizedBox',
          'properties': {'width': 8},
        },
        {
          'type': 'Text',
          'properties': {
            'text': 'Tap here',
            'fontSize': 16,
          },
        },
      ],
    },
  },
};

/// InkResponse - Advanced Material Design feedback
///
/// Best for: Custom ripple effects, circular buttons, specialized interactions
///
/// Example JSON:
final inkResponseExample = {
  'type': 'InkResponse',
  'properties': {
    'splashColor': '#4CAF50',
    'highlightColor': '#C8E6C9',
    'focusColor': '#A5D6A7',
    'radius': 50.0,
    'highlightShape': 'circle',  // circle or rectangle
    'containedInkWell': false,
  },
  'events': {
    'onTap': {
      'action': 'executeCallback',
      'callback': 'onCircleButtonTapped',
    },
  },
  'child': {
    'type': 'Container',
    'properties': {
      'width': 100,
      'height': 100,
      'decoration': {
        'shape': 'circle',
        'color': '#4CAF50',
      },
    },
    'child': {
      'type': 'Center',
      'child': {
        'type': 'Icon',
        'properties': {
          'icon': 'check',
          'color': '#FFFFFF',
          'size': 40,
        },
      },
    },
  },
};

// ============================================================================
// PHASE 2: ADVANCED GESTURE WIDGETS - DRAG & DROP EXAMPLES
// ============================================================================

/// Draggable - Basic drag support
///
/// Best for: Simple drag operations, free-form repositioning
///
/// Example JSON:
final draggableExample = {
  'type': 'Draggable',
  'properties': {
    'data': 'item_123',  // Data to pass on drop
    'axis': 'free',  // horizontal, vertical, or free
    'ignoringFeedbackSemantics': true,
  },
  'events': {
    'onDragStarted': {
      'action': 'executeCallback',
      'callback': 'onDragStarted',
    },
    'onDragCompleted': {
      'action': 'executeCallback',
      'callback': 'onDragCompleted',
    },
    'onDraggableCanceled': {
      'action': 'executeCallback',
      'callback': 'onDragCanceled',
    },
  },
  'child': {
    'type': 'Container',
    'properties': {
      'width': 80,
      'height': 80,
      'color': '#FF9800',
      'borderRadius': 8,
    },
    'child': {
      'type': 'Center',
      'child': {
        'type': 'Icon',
        'properties': {
          'icon': 'drag_indicator',
          'color': '#FFFFFF',
        },
      },
    },
  },
};

/// LongPressDraggable - Long press triggered drag
///
/// Best for: UX-friendly dragging, avoiding accidental drags
///
/// Example JSON:
final longPressDraggableExample = {
  'type': 'LongPressDraggable',
  'properties': {
    'data': 'card_456',
    'axis': 'vertical',
    'delayMs': 500,
    'maxSimultaneousDrags': 1,
    'ignoringFeedbackSemantics': true,
  },
  'events': {
    'onDragStarted': {
      'action': 'executeCallback',
      'callback': 'onCardDragStarted',
    },
    'onDragCompleted': {
      'action': 'executeCallback',
      'callback': 'onCardPlaced',
    },
  },
  'child': {
    'type': 'Card',
    'properties': {
      'elevation': 4,
      'margin': 8,
    },
    'child': {
      'type': 'Padding',
      'properties': {'padding': 16},
      'child': {
        'type': 'Column',
        'children': [
          {
            'type': 'Text',
            'properties': {
              'text': 'Long press to drag',
              'fontSize': 16,
              'fontWeight': 'bold',
            },
          },
          {
            'type': 'SizedBox',
            'properties': {'height': 8},
          },
          {
            'type': 'Text',
            'properties': {
              'text': 'Drag to reorder items',
              'fontSize': 12,
            },
          },
        ],
      },
    },
  },
};

/// DragTarget - Accepts drops
///
/// Best for: Drop zones, reordering lists, drag-to-action
///
/// Example JSON:
final dragTargetExample = {
  'type': 'DragTarget',
  'properties': {
    'acceptedTypes': ['item_123', 'card_456'],
  },
  'events': {
    'onWillAccept': {
      'action': 'executeCallback',
      'callback': 'onDragEntered',
    },
    'onAccept': {
      'action': 'executeCallback',
      'callback': 'onItemDropped',
    },
    'onLeave': {
      'action': 'executeCallback',
      'callback': 'onDragExited',
    },
  },
  // No child needed - DragTarget has internal builder
};

// ============================================================================
// COMPLETE EXAMPLE: DRAG-AND-DROP TASK LIST
// ============================================================================

final taskListExample = {
  'type': 'Column',
  'properties': {
    'children': [
      {
        'type': 'Text',
        'properties': {
          'text': 'Drag tasks to reorder',
          'fontSize': 18,
          'fontWeight': 'bold',
        },
      },
      {
        'type': 'SizedBox',
        'properties': {'height': 16},
      },
      // Task 1 - Draggable
      {
        'type': 'LongPressDraggable',
        'properties': {
          'data': 'task_1',
          'axis': 'vertical',
        },
        'events': {
          'onDragStarted': {
            'action': 'executeCallback',
            'callback': 'taskDragStart',
          },
        },
        'child': {
          'type': 'Card',
          'child': {
            'type': 'Padding',
            'properties': {'padding': 12},
            'child': {
              'type': 'Text',
              'properties': {
                'text': 'Task 1: Complete',
              },
            },
          },
        },
      },
      // Drop zone
      {
        'type': 'DragTarget',
        'events': {
          'onAccept': {
            'action': 'executeCallback',
            'callback': 'taskDropped',
          },
        },
      },
    ],
  },
};

// ============================================================================
// HELPER FUNCTION EXAMPLES
// ============================================================================

/// Example: Accessing Gesture Helpers
/// 
/// In your callback handlers:
/// ```dart
/// // Get gesture event log
/// final events = GestureLogger.getEvents();
/// 
/// // Get drag/drop state
/// if (DragDropManager.isDragging) {
///   final source = DragDropManager.currentSource;
///   final data = DragDropManager.currentData;
/// }
/// 
/// // Track gesture performance
/// GesturePerformanceMonitor.recordDuration('onTap', 150);
/// final stats = GesturePerformanceMonitor.getStatistics();
/// ```
final helperExampleCode = '''
// Example usage in callbacks

// 1. Log gesture events
import '../src/rendering/gesture_helpers.dart';

void onTap(Map<String, dynamic> event) {
  final gestureEvent = GestureEvent(
    eventType: 'tap',
    eventData: event,
  );
  GestureLogger.logEvent(gestureEvent);
}

// 2. Manage drag/drop state
void onDragStart(String source, dynamic data) {
  DragDropManager.onDragStart(source, data);
}

// 3. Route gesture callbacks
void routeGestureCallback(String type, Map<String, dynamic> config) {
  GestureCallbackRouter.routeCallback(
    type,
    config,
    _handleCallback,
    widgetConfig,
  );
}

// 4. Validate gesture configuration
void validateConfig(Map<String, dynamic> config) {
  final errors = GestureValidator.validateGestureDetectorConfig(config);
  if (errors.isNotEmpty) {
    print('Validation errors: $errors');
  }
}

// 5. Monitor performance
void trackGesturePerformance() {
  GesturePerformanceMonitor.recordDuration('onTap', 125);
  final stats = GesturePerformanceMonitor.getStatistics();
  print('Gesture performance: $stats');
}
''';

// ============================================================================
// GESTURE PROPERTIES REFERENCE
// ============================================================================

final gesturePropertiesReference = '''
## Gesture Widget Properties Reference

### GestureDetector
- behavior: HitTestBehavior (deferToChild, opaque, translucent)
- excludeFromSemantics: bool

### InkWell / InkResponse
- splashColor: Color (hex format)
- highlightColor: Color (hex format)
- hoverColor: Color (hex format)
- focusColor: Color (hex format)
- radius: double
- borderRadius: double | {topLeft, topRight, bottomLeft, bottomRight}
- enableFeedback: bool (default: true)
- excludeFromSemantics: bool
- containedInkWell: bool (InkResponse only)
- highlightShape: 'circle' | 'rectangle' (InkResponse only)

### Draggable / LongPressDraggable
- data: object (pass on drop)
- axis: 'horizontal' | 'vertical' | 'free'
- delayMs: int (LongPressDraggable only)
- maxSimultaneousDrags: int
- ignoringFeedbackSemantics: bool

### DragTarget
- acceptedTypes: List<String>

## Gesture Events Reference

### Tap Gestures
- onTap
- onDoubleTap
- onLongPress

### Drag Gestures (Directional)
- onVerticalDragStart
- onVerticalDragUpdate
- onVerticalDragEnd
- onHorizontalDragStart
- onHorizontalDragUpdate
- onHorizontalDragEnd

### Pan Gestures (Any Direction)
- onPanStart
- onPanUpdate
- onPanEnd

### Drag & Drop
- onDragStarted
- onDraggableCanceled
- onDragEnd
- onDragCompleted
- onWillAccept (DragTarget)
- onAccept (DragTarget)
- onLeave (DragTarget)
''';
