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
