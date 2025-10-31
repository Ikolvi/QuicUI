/// Gesture and touch interaction helper utilities for QuicUI
///
/// This module provides utility functions and helpers for gesture widgets.
/// Includes gesture event parsing, data routing, and callback management.

import 'package:flutter/material.dart';
import '../utils/logger_util.dart';

// ============================================================================
// GESTURE EVENT DATA STRUCTURES
// ============================================================================

/// Represents a gesture event with context and metadata
class GestureEvent {
  final String eventType;
  final dynamic eventData;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  GestureEvent({
    required this.eventType,
    this.eventData,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'eventType': eventType,
    'eventData': eventData,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  @override
  String toString() => 'GestureEvent(type: $eventType, timestamp: $timestamp)';
}

/// Represents drag and drop data transfer
class DragData {
  final dynamic data;
  final String? mimeType;
  final Map<String, dynamic>? additionalData;

  DragData({
    required this.data,
    this.mimeType,
    this.additionalData,
  });

  Map<String, dynamic> toMap() => {
    'data': data,
    'mimeType': mimeType,
    'additionalData': additionalData,
  };
}

// ============================================================================
// GESTURE EVENT PARSING UTILITIES
// ============================================================================

/// Parses gesture event configuration from JSON
GestureEvent parseGestureEvent(
  String eventType,
  Map<String, dynamic>? eventConfig,
) {
  LoggerUtil.debug('📊 Parsing gesture event: $eventType');

  return GestureEvent(
    eventType: eventType,
    eventData: eventConfig,
    metadata: {
      'source': 'gesture_widget',
      'config_keys': eventConfig?.keys.toList(),
    },
  );
}

/// Extracts callback action from gesture event configuration
Map<String, dynamic>? extractCallbackAction(
  Map<String, dynamic>? eventConfig,
) {
  if (eventConfig == null) return null;

  // Events can contain action definitions directly
  // or reference existing actions by ID
  if (eventConfig['action'] != null) {
    LoggerUtil.debug('📍 Found action in event config');
    return {
      'action': eventConfig['action'],
      'target': eventConfig['target'],
      'data': eventConfig['data'],
      'onSuccess': eventConfig['onSuccess'],
      'onError': eventConfig['onError'],
    };
  }

  return null;
}

// ============================================================================
// GESTURE STATE MANAGEMENT
// ============================================================================

/// Manages gesture state for widgets requiring state persistence
class GestureStateManager {
  static final Map<String, dynamic> _gestureStates = {};

  /// Store gesture state by widget key
  static void setState(String key, Map<String, dynamic> state) {
    _gestureStates[key] = state;
    LoggerUtil.debug('💾 Stored gesture state for key: $key');
  }

  /// Retrieve gesture state by widget key
  static Map<String, dynamic>? getState(String key) {
    return _gestureStates[key];
  }

  /// Update specific field in gesture state
  static void updateState(String key, String field, dynamic value) {
    final state = _gestureStates[key] ??= {};
    state[field] = value;
    LoggerUtil.debug('🔄 Updated gesture state [$key].$field = $value');
  }

  /// Clear gesture state
  static void clearState(String key) {
    _gestureStates.remove(key);
    LoggerUtil.debug('🗑️ Cleared gesture state for key: $key');
  }

  /// Clear all gesture states
  static void clearAll() {
    _gestureStates.clear();
    LoggerUtil.debug('🗑️ Cleared all gesture states');
  }
}

// ============================================================================
// DRAG & DROP UTILITIES
// ============================================================================

/// Manages drag and drop operations
class DragDropManager {
  static String? _currentDragSource;
  static dynamic _currentDragData;
  static DateTime? _dragStartTime;

  /// Called when drag starts
  static void onDragStart(String source, dynamic data) {
    _currentDragSource = source;
    _currentDragData = data;
    _dragStartTime = DateTime.now();
    LoggerUtil.info('🎯 Drag started from: $source, data: $data');
  }

  /// Called when drag ends
  static void onDragEnd() {
    if (_dragStartTime != null) {
      final duration = DateTime.now().difference(_dragStartTime!);
      LoggerUtil.info(
        '🎯 Drag ended after ${duration.inMilliseconds}ms',
      );
    }
    _currentDragSource = null;
    _currentDragData = null;
    _dragStartTime = null;
  }

  /// Check if drag is currently active
  static bool get isDragging => _currentDragSource != null;

  /// Get current drag source
  static String? get currentSource => _currentDragSource;

  /// Get current drag data
  static dynamic get currentData => _currentDragData;

  /// Get drag duration so far
  static Duration? get dragDuration {
    if (_dragStartTime == null) return null;
    return DateTime.now().difference(_dragStartTime!);
  }
}

// ============================================================================
// GESTURE CALLBACK ROUTING
// ============================================================================

/// Routes gesture callbacks to appropriate handlers
class GestureCallbackRouter {
  /// Routes a gesture callback to the appropriate action
  static void routeCallback(
    String gestureType,
    Map<String, dynamic> eventConfig,
    Function(dynamic, Map<String, dynamic>)? onCallback,
    Map<String, dynamic> widgetConfig,
  ) {
    LoggerUtil.debug('📌 Routing gesture callback: $gestureType');

    final action = extractCallbackAction(eventConfig);
    if (action != null) {
      // Execute callback with action
      onCallback?.call(action, widgetConfig);
    } else {
      // Execute callback with raw event config
      onCallback?.call(eventConfig, widgetConfig);
    }
  }

  /// Chains multiple gesture callbacks
  static Future<void> chainCallbacks(
    List<Map<String, dynamic>> callbacks,
    Function(dynamic, Map<String, dynamic>)? onCallback,
    Map<String, dynamic> widgetConfig,
  ) async {
    LoggerUtil.debug('⛓️ Chaining ${callbacks.length} callbacks');

    for (final callback in callbacks) {
      try {
        onCallback?.call(callback, widgetConfig);
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        LoggerUtil.error('❌ Error in callback chain: $e');
        rethrow;
      }
    }
  }
}

// ============================================================================
// GESTURE VALIDATION & CONSTRAINTS
// ============================================================================

/// Validates gesture configuration
class GestureValidator {
  /// Validates GestureDetector configuration
  static List<String> validateGestureDetectorConfig(
    Map<String, dynamic> config,
  ) {
    final errors = <String>[];

    final properties = config['properties'] ?? {};
    if (properties['behavior'] != null) {
      final behavior = properties['behavior'].toString().toLowerCase();
      if (!['opaque', 'translucent', 'deferToChild', 'defer_to_child', 'defer-to-child']
          .contains(behavior)) {
        errors.add('Invalid behavior value: ${properties['behavior']}');
      }
    }

    return errors;
  }

  /// Validates Draggable configuration
  static List<String> validateDraggableConfig(
    Map<String, dynamic> config,
  ) {
    final errors = <String>[];

    final properties = config['properties'] ?? {};
    if (properties['axis'] != null) {
      final axis = properties['axis'].toString().toLowerCase();
      if (!['horizontal', 'vertical', 'free'].contains(axis)) {
        errors.add('Invalid axis value: ${properties['axis']}');
      }
    }

    if (properties['maxSimultaneousDrags'] != null) {
      if (properties['maxSimultaneousDrags'] is! int) {
        errors.add('maxSimultaneousDrags must be an integer');
      }
    }

    return errors;
  }

  /// Validates DragTarget configuration
  static List<String> validateDragTargetConfig(
    Map<String, dynamic> config,
  ) {
    // DragTarget has minimal required configuration
    // Validation can be extended as needed
    return [];
  }
}

// ============================================================================
// GESTURE EVENT LOGGING
// ============================================================================

/// Provides gesture event logging and debugging utilities
class GestureLogger {
  static final List<GestureEvent> _eventLog = [];
  static const int _maxLogSize = 100;

  /// Log a gesture event
  static void logEvent(GestureEvent event) {
    _eventLog.add(event);
    if (_eventLog.length > _maxLogSize) {
      _eventLog.removeAt(0);
    }
    LoggerUtil.debug('📝 Logged gesture event: ${event.eventType}');
  }

  /// Get all logged events
  static List<GestureEvent> getEvents() => List.from(_eventLog);

  /// Get events of specific type
  static List<GestureEvent> getEventsByType(String type) =>
      _eventLog.where((e) => e.eventType == type).toList();

  /// Clear event log
  static void clear() {
    _eventLog.clear();
    LoggerUtil.debug('📝 Cleared gesture event log');
  }

  /// Get event log statistics
  static Map<String, dynamic> getStatistics() {
    final eventTypes = <String, int>{};
    for (final event in _eventLog) {
      eventTypes[event.eventType] = (eventTypes[event.eventType] ?? 0) + 1;
    }

    return {
      'total_events': _eventLog.length,
      'event_types': eventTypes,
      'oldest_event': _eventLog.isNotEmpty ? _eventLog.first.timestamp : null,
      'newest_event': _eventLog.isNotEmpty ? _eventLog.last.timestamp : null,
    };
  }
}

// ============================================================================
// GESTURE PERFORMANCE MONITORING
// ============================================================================

/// Monitors gesture performance and metrics
class GesturePerformanceMonitor {
  static final Map<String, List<int>> _performanceMetrics = {};

  /// Record gesture event duration
  static void recordDuration(String eventType, int durationMs) {
    _performanceMetrics.putIfAbsent(eventType, () => []).add(durationMs);
    LoggerUtil.debug('⏱️ Recorded $eventType duration: ${durationMs}ms');
  }

  /// Get average duration for gesture type
  static double? getAverageDuration(String eventType) {
    final durations = _performanceMetrics[eventType];
    if (durations == null || durations.isEmpty) return null;
    return durations.reduce((a, b) => a + b) / durations.length;
  }

  /// Get performance statistics
  static Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{};
    _performanceMetrics.forEach((type, durations) {
      if (durations.isNotEmpty) {
        stats[type] = {
          'count': durations.length,
          'average': durations.reduce((a, b) => a + b) / durations.length,
          'min': durations.reduce((a, b) => a < b ? a : b),
          'max': durations.reduce((a, b) => a > b ? a : b),
        };
      }
    });
    return stats;
  }

  /// Clear all metrics
  static void clear() {
    _performanceMetrics.clear();
    LoggerUtil.debug('⏱️ Cleared gesture performance metrics');
  }
}
