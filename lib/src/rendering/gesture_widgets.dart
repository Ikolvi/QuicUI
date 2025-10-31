/// Gesture and touch interaction widgets for QuicUI
///
/// This module provides gesture detection widgets that allow users to interact
/// with the UI through taps, long-presses, drags, and other gestures.
///
/// ## Supported Widgets (Phase 1)
/// - GestureDetector: Low-level gesture detection
/// - InkWell: Material Design tap feedback with ink ripple
/// - InkResponse: Advanced version of InkWell with more customization
///
/// ## Gesture Events Supported
/// - onTap, onDoubleTap, onLongPress
/// - onVerticalDragStart/Update/End
/// - onHorizontalDragStart/Update/End
/// - onPanStart/Update/End
///
/// ## JSON Configuration Example
/// ```json
/// {
///   "type": "GestureDetector",
///   "properties": {"behavior": "opaque"},
///   "events": {"onTap": {"action": "navigate", "screen": "details"}},
///   "child": {"type": "Text", "properties": {"text": "Tap me!"}}
/// }
/// ```

import 'package:flutter/material.dart';
import '../utils/logger_util.dart';

/// Builds a GestureDetector widget from JSON configuration
///
/// Properties:
/// - behavior: HitTestBehavior enum (deferToChild, opaque, translucent)
/// - excludeFromSemantics: bool (default: false)
Widget buildGestureDetector(
  Map<String, dynamic> config,
  Function(dynamic, Map<String, dynamic>)? onCallback,
) {
  LoggerUtil.debug('🖱️ Building GestureDetector');

  final properties = config['properties'] ?? {};
  final behavior = _parseHitTestBehavior(
    properties['behavior'] ?? 'deferToChild',
  );
  final excludeFromSemantics = properties['excludeFromSemantics'] ?? false;

  Widget child = const Placeholder();

  return GestureDetector(
    behavior: behavior,
    excludeFromSemantics: excludeFromSemantics,
    onTap: config['events']?['onTap'] != null
        ? () => onCallback?.call(config['events']['onTap'], config)
        : null,
    onDoubleTap: config['events']?['onDoubleTap'] != null
        ? () => onCallback?.call(config['events']['onDoubleTap'], config)
        : null,
    onLongPress: config['events']?['onLongPress'] != null
        ? () => onCallback?.call(config['events']['onLongPress'], config)
        : null,
    onVerticalDragStart: config['events']?['onVerticalDragStart'] != null
        ? (details) =>
            onCallback?.call(config['events']['onVerticalDragStart'], config)
        : null,
    onVerticalDragUpdate: config['events']?['onVerticalDragUpdate'] != null
        ? (details) =>
            onCallback?.call(config['events']['onVerticalDragUpdate'], config)
        : null,
    onVerticalDragEnd: config['events']?['onVerticalDragEnd'] != null
        ? (details) =>
            onCallback?.call(config['events']['onVerticalDragEnd'], config)
        : null,
    onHorizontalDragStart: config['events']?['onHorizontalDragStart'] != null
        ? (details) =>
            onCallback?.call(config['events']['onHorizontalDragStart'], config)
        : null,
    onHorizontalDragUpdate: config['events']?['onHorizontalDragUpdate'] != null
        ? (details) =>
            onCallback?.call(config['events']['onHorizontalDragUpdate'], config)
        : null,
    onHorizontalDragEnd: config['events']?['onHorizontalDragEnd'] != null
        ? (details) =>
            onCallback?.call(config['events']['onHorizontalDragEnd'], config)
        : null,
    onPanStart: config['events']?['onPanStart'] != null
        ? (details) =>
            onCallback?.call(config['events']['onPanStart'], config)
        : null,
    onPanUpdate: config['events']?['onPanUpdate'] != null
        ? (details) =>
            onCallback?.call(config['events']['onPanUpdate'], config)
        : null,
    onPanEnd: config['events']?['onPanEnd'] != null
        ? (details) => onCallback?.call(config['events']['onPanEnd'], config)
        : null,
    child: child,
  );
}

/// Builds an InkWell widget from JSON configuration
///
/// InkWell provides Material Design tap feedback with ink ripple animation.
/// Ideal for buttons and interactive list items.
///
/// Properties:
/// - splashColor, highlightColor, hoverColor, focusColor: Colors (hex format)
/// - splashFactory: 'splash' or 'noSplash'
/// - radius: double
/// - borderRadius: double or object {topLeft, topRight, bottomLeft, bottomRight}
/// - enableFeedback: bool (default: true)
/// - excludeFromSemantics: bool (default: false)
Widget buildInkWell(
  Map<String, dynamic> config,
  Function(dynamic, Map<String, dynamic>)? onCallback,
) {
  LoggerUtil.debug('🖱️ Building InkWell');

  final properties = config['properties'] ?? {};
  final splashColor = _parseColor(
    properties['splashColor'],
    Colors.grey,
  );
  final highlightColor = _parseColor(
    properties['highlightColor'],
    Colors.grey.withOpacity(0.12),
  );
  final hoverColor = _parseColor(
    properties['hoverColor'],
    Colors.grey.withOpacity(0.04),
  );
  final focusColor = _parseColor(
    properties['focusColor'],
    Colors.grey.withOpacity(0.12),
  );
  final radius = (properties['radius'] as num?)?.toDouble();
  final borderRadius = _parseBorderRadius(properties['borderRadius']);
  final enableFeedback = properties['enableFeedback'] ?? true;
  final excludeFromSemantics = properties['excludeFromSemantics'] ?? false;

  Widget child = const Placeholder();

  return InkWell(
    onTap: config['events']?['onTap'] != null
        ? () => onCallback?.call(config['events']['onTap'], config)
        : null,
    onDoubleTap: config['events']?['onDoubleTap'] != null
        ? () => onCallback?.call(config['events']['onDoubleTap'], config)
        : null,
    onLongPress: config['events']?['onLongPress'] != null
        ? () => onCallback?.call(config['events']['onLongPress'], config)
        : null,
    splashColor: splashColor,
    highlightColor: highlightColor,
    hoverColor: hoverColor,
    focusColor: focusColor,
    radius: radius,
    borderRadius: borderRadius,
    enableFeedback: enableFeedback,
    excludeFromSemantics: excludeFromSemantics,
    child: child,
  );
}

/// Builds an InkResponse widget from JSON configuration
///
/// InkResponse is a more advanced version of InkWell with additional
/// customization options for the visual response to taps.
///
/// Additional properties (beyond InkWell):
/// - containedInkWell: bool (default: false)
/// - highlightShape: 'circle' or 'rectangle'
Widget buildInkResponse(
  Map<String, dynamic> config,
  Function(dynamic, Map<String, dynamic>)? onCallback,
) {
  LoggerUtil.debug('🖱️ Building InkResponse');

  final properties = config['properties'] ?? {};
  final splashColor = _parseColor(
    properties['splashColor'],
    Colors.grey,
  );
  final highlightColor = _parseColor(
    properties['highlightColor'],
    Colors.grey.withOpacity(0.12),
  );
  final hoverColor = _parseColor(
    properties['hoverColor'],
    Colors.grey.withOpacity(0.04),
  );
  final focusColor = _parseColor(
    properties['focusColor'],
    Colors.grey.withOpacity(0.12),
  );
  final radius = (properties['radius'] as num?)?.toDouble();
  final borderRadius = _parseBorderRadius(properties['borderRadius']);
  final enableFeedback = properties['enableFeedback'] ?? true;
  final excludeFromSemantics = properties['excludeFromSemantics'] ?? false;
  final containedInkWell = properties['containedInkWell'] ?? false;
  final highlightShapeStr = properties['highlightShape'] ?? 'rectangle';
  final highlightShape = highlightShapeStr == 'circle'
      ? BoxShape.circle
      : BoxShape.rectangle;

  Widget child = const Placeholder();

  return InkResponse(
    onTap: config['events']?['onTap'] != null
        ? () => onCallback?.call(config['events']['onTap'], config)
        : null,
    onDoubleTap: config['events']?['onDoubleTap'] != null
        ? () => onCallback?.call(config['events']['onDoubleTap'], config)
        : null,
    onLongPress: config['events']?['onLongPress'] != null
        ? () => onCallback?.call(config['events']['onLongPress'], config)
        : null,
    splashColor: splashColor,
    highlightColor: highlightColor,
    hoverColor: hoverColor,
    focusColor: focusColor,
    radius: radius,
    borderRadius: borderRadius,
    containedInkWell: containedInkWell,
    highlightShape: highlightShape,
    enableFeedback: enableFeedback,
    excludeFromSemantics: excludeFromSemantics,
    child: child,
  );
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/// Parses HitTestBehavior from string
HitTestBehavior _parseHitTestBehavior(dynamic value) {
  if (value is String) {
    switch (value.toLowerCase()) {
      case 'opaque':
        return HitTestBehavior.opaque;
      case 'translucent':
        return HitTestBehavior.translucent;
      case 'deferToChild':
      case 'defer_to_child':
      case 'defer-to-child':
        return HitTestBehavior.deferToChild;
      default:
        return HitTestBehavior.deferToChild;
    }
  }
  return HitTestBehavior.deferToChild;
}

/// Parses color from hex string or color name
Color _parseColor(dynamic value, Color defaultColor) {
  if (value == null) return defaultColor;

  if (value is String) {
    if (value.startsWith('#')) {
      try {
        return Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
      } catch (e) {
        LoggerUtil.warning('Invalid color: $value');
        return defaultColor;
      }
    }

    switch (value.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'grey':
        return Colors.grey;
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black;
      default:
        return defaultColor;
    }
  }

  return defaultColor;
}

/// Parses BorderRadius from string or object
BorderRadius? _parseBorderRadius(dynamic value) {
  if (value == null) return null;

  if (value is String) {
    try {
      final radius = double.parse(value);
      return BorderRadius.all(Radius.circular(radius));
    } catch (e) {
      LoggerUtil.warning('Invalid borderRadius: $value');
      return null;
    }
  }

  if (value is Map) {
    final tl = (value['topLeft'] as num?)?.toDouble() ?? 0;
    final tr = (value['topRight'] as num?)?.toDouble() ?? 0;
    final bl = (value['bottomLeft'] as num?)?.toDouble() ?? 0;
    final br = (value['bottomRight'] as num?)?.toDouble() ?? 0;

    return BorderRadius.only(
      topLeft: Radius.circular(tl),
      topRight: Radius.circular(tr),
      bottomLeft: Radius.circular(bl),
      bottomRight: Radius.circular(br),
    );
  }

  return null;
}

// ============================================================================
// PHASE 2: ADVANCED GESTURE WIDGETS (DRAG & DROP)
// ============================================================================

/// Builds a Draggable widget from JSON configuration
///
/// Draggable makes a widget draggable. Typically paired with DragTarget.
///
/// Properties:
/// - data: Object to pass when drag completes (string key to data map)
/// - axis: 'horizontal', 'vertical', or 'free' (default: 'free')
/// - affinity: 'vertical' or 'horizontal'
/// - ignoringFeedbackSemantics: bool (default: true)
Widget buildDraggable(
  Map<String, dynamic> config,
  Function(dynamic, Map<String, dynamic>)? onCallback,
) {
  LoggerUtil.debug('🖱️ Building Draggable');

  final properties = config['properties'] ?? {};
  final data = properties['data'] ?? 'draggable_data';
  final axisStr = properties['axis'] ?? 'free';
  final axis = _parseAxis(axisStr);
  final ignoringFeedback = properties['ignoringFeedbackSemantics'] ?? true;

  Widget child = const SizedBox(
    width: 100,
    height: 100,
    child: Placeholder(),
  );

  Widget feedback = child;
  Widget childWhenDragging = const SizedBox.shrink();

  return Draggable(
    data: data,
    axis: axis,
    ignoringFeedbackSemantics: ignoringFeedback,
    feedback: feedback,
    childWhenDragging: childWhenDragging,
    onDragStarted: config['events']?['onDragStarted'] != null
        ? () => onCallback?.call(config['events']['onDragStarted'], config)
        : null,
    onDraggableCanceled: config['events']?['onDraggableCanceled'] != null
        ? (velocity, offset) =>
            onCallback?.call(config['events']['onDraggableCanceled'], config)
        : null,
    onDragEnd: config['events']?['onDragEnd'] != null
        ? (details) =>
            onCallback?.call(config['events']['onDragEnd'], config)
        : null,
    onDragCompleted: config['events']?['onDragCompleted'] != null
        ? () => onCallback?.call(config['events']['onDragCompleted'], config)
        : null,
    child: child,
  );
}

/// Builds a LongPressDraggable widget from JSON configuration
///
/// LongPressDraggable is a Draggable that only starts dragging on long press.
/// Better UX for most cases than regular Draggable.
///
/// Properties (same as Draggable, plus):
/// - delayMs: int (duration before drag starts, default: 500)
/// - maxSimultaneousDrags: int (default: unlimited)
Widget buildLongPressDraggable(
  Map<String, dynamic> config,
  Function(dynamic, Map<String, dynamic>)? onCallback,
) {
  LoggerUtil.debug('🖱️ Building LongPressDraggable');

  final properties = config['properties'] ?? {};
  final data = properties['data'] ?? 'draggable_data';
  final axisStr = properties['axis'] ?? 'free';
  final axis = _parseAxis(axisStr);
  final ignoringFeedback = properties['ignoringFeedbackSemantics'] ?? true;
  final delayMs = (properties['delayMs'] as int?) ?? 500;
  final maxDrags = properties['maxSimultaneousDrags'] as int?;

  Widget child = const SizedBox(
    width: 100,
    height: 100,
    child: Placeholder(),
  );

  Widget feedback = child;
  Widget childWhenDragging = const SizedBox.shrink();

  return LongPressDraggable(
    data: data,
    axis: axis,
    ignoringFeedbackSemantics: ignoringFeedback,
    delay: Duration(milliseconds: delayMs),
    maxSimultaneousDrags: maxDrags,
    feedback: feedback,
    childWhenDragging: childWhenDragging,
    onDragStarted: config['events']?['onDragStarted'] != null
        ? () => onCallback?.call(config['events']['onDragStarted'], config)
        : null,
    onDraggableCanceled: config['events']?['onDraggableCanceled'] != null
        ? (velocity, offset) =>
            onCallback?.call(config['events']['onDraggableCanceled'], config)
        : null,
    onDragEnd: config['events']?['onDragEnd'] != null
        ? (details) =>
            onCallback?.call(config['events']['onDragEnd'], config)
        : null,
    onDragCompleted: config['events']?['onDragCompleted'] != null
        ? () => onCallback?.call(config['events']['onDragCompleted'], config)
        : null,
    child: child,
  );
}

/// Builds a DragTarget widget from JSON configuration
///
/// DragTarget is a widget that accepts drops from Draggable widgets.
///
/// Properties:
/// - acceptedTypes: List of drag types this target accepts
/// - onWillAccept: bool callback when drag enters target
/// - onAccept: callback when drop accepted
/// - onLeave: callback when drag leaves target
Widget buildDragTarget(
  Map<String, dynamic> config,
  Function(dynamic, Map<String, dynamic>)? onCallback,
) {
  LoggerUtil.debug('🖱️ Building DragTarget');

  // Properties are reserved for future enhancements
  // final properties = config['properties'] ?? {};

  Widget builder(
    BuildContext context,
    List<dynamic> accepted,
    List<dynamic> rejected,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: accepted.isNotEmpty ? Colors.green : Colors.grey,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Placeholder(),
      ),
    );
  }

  return DragTarget(
    builder: builder,
    onWillAccept: config['events']?['onWillAccept'] != null
        ? (data) {
            onCallback?.call(config['events']['onWillAccept'], config);
            return true;
          }
        : null,
    onAccept: config['events']?['onAccept'] != null
        ? (data) =>
            onCallback?.call(config['events']['onAccept'], config)
        : null,
    onLeave: config['events']?['onLeave'] != null
        ? (data) =>
            onCallback?.call(config['events']['onLeave'], config)
        : null,
  );
}

// ============================================================================
// PHASE 2 HELPER FUNCTIONS
// ============================================================================

/// Parses Axis from string
Axis _parseAxis(dynamic value) {
  if (value is String) {
    switch (value.toLowerCase()) {
      case 'horizontal':
        return Axis.horizontal;
      case 'vertical':
        return Axis.vertical;
      case 'free':
      default:
        return Axis.vertical;
    }
  }
  return Axis.vertical;
}
