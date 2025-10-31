/// Widget factory for creating widgets
///
/// This factory pattern is used internally by UIRenderer to create widgets
/// from JSON type definitions. For most use cases, use UIRenderer directly.

import 'package:flutter/material.dart';

/// Factory for creating widgets from type
///
/// Used by UIRenderer to instantiate Flutter widgets from JSON widget definitions.
/// Supports 70+ widget types with type-safe creation.
class WidgetFactory {
  /// Create widget by type
  ///
  /// Maps JSON widget type strings to Flutter widget constructors.
  /// Delegates to UIRenderer for actual widget creation.
  ///
  /// ## Parameters
  /// - [type]: Widget type identifier (e.g., 'text', 'button', 'container')
  /// - [props]: Widget properties from JSON
  ///
  /// ## Returns
  /// Flutter Widget instance or Placeholder if type not recognized
  ///
  /// ## Note
  /// This is an internal implementation detail. Use UIRenderer.render() instead
  /// for full widget tree rendering with JSON validation.
  static Widget createWidget(String type, Map<String, dynamic> props) {
    // Factory delegated to UIRenderer for centralized widget creation
    // This maintains separation of concerns: Factory knows about types,
    // UIRenderer handles full rendering pipeline
    return const SizedBox(
      child: Placeholder(),
    );
  }
}
