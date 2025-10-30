/// Widget data model for Server-Driven UI
import 'package:equatable/equatable.dart';

/// Represents a widget in the JSON-based UI definition
class WidgetData extends Equatable {
  /// Type of widget (e.g., 'column', 'row', 'text', 'button')
  final String type;

  /// Properties of the widget
  final Map<String, dynamic> properties;

  /// Child widgets (for layout widgets)
  final List<WidgetData>? children;

  /// Event handlers
  final Map<String, dynamic>? events;

  /// Custom ID for reference
  final String? id;

  /// Conditional rendering
  final Map<String, dynamic>? condition;

  const WidgetData({
    required this.type,
    required this.properties,
    this.children,
    this.events,
    this.id,
    this.condition,
  });

  @override
  List<Object?> get props => [type, properties, children, events, id, condition];

  /// Manual JSON deserialization
  factory WidgetData.fromJson(Map<String, dynamic> json) {
    final childrenList = json['children'] as List<dynamic>?;
    return WidgetData(
      type: json['type'] as String,
      properties: json['properties'] as Map<String, dynamic>? ?? {},
      children: childrenList?.map((e) => WidgetData.fromJson(e as Map<String, dynamic>)).toList(),
      events: json['events'] as Map<String, dynamic>?,
      id: json['id'] as String?,
      condition: json['condition'] as Map<String, dynamic>?,
    );
  }

  /// Manual JSON serialization
  Map<String, dynamic> toJson() => {
    'type': type,
    'properties': properties,
    'children': children?.map((e) => e.toJson()).toList(),
    'events': events,
    'id': id,
    'condition': condition,
  };

  /// Creates a copy with modified fields
  WidgetData copyWith({
    String? type,
    Map<String, dynamic>? properties,
    List<WidgetData>? children,
    Map<String, dynamic>? events,
    String? id,
    Map<String, dynamic>? condition,
  }) {
    return WidgetData(
      type: type ?? this.type,
      properties: properties ?? this.properties,
      children: children ?? this.children,
      events: events ?? this.events,
      id: id ?? this.id,
      condition: condition ?? this.condition,
    );
  }

  /// Gets a property value
  T? getProperty<T>(String key, {T? defaultValue}) {
    final value = properties[key];
    if (value is T) return value;
    return defaultValue;
  }

  /// Checks if condition is met (for conditional rendering)
  bool shouldRender(Map<String, dynamic> context) {
    if (condition == null) return true;

    // Simple condition evaluation logic
    // Can be extended for more complex conditions
    final conditionType = condition!['type'] as String?;
    final value = condition!['value'];

    switch (conditionType) {
      case 'equals':
        return context['value'] == value;
      case 'notEquals':
        return context['value'] != value;
      case 'greaterThan':
        final contextValue = context['value'] as num?;
        final condValue = value as num?;
        if (contextValue != null && condValue != null) {
          return contextValue.compareTo(condValue) > 0;
        }
        return false;
      case 'lessThan':
        final contextValue = context['value'] as num?;
        final condValue = value as num?;
        if (contextValue != null && condValue != null) {
          return contextValue.compareTo(condValue) < 0;
        }
        return false;
      case 'contains':
        return (context['value'] as String?)?.contains(value as String) ?? false;
      default:
        return true;
    }
  }

  /// Gets event handler
  dynamic getEventHandler(String eventName) {
    return events?[eventName];
  }

  /// Whether this widget has children
  bool get hasChildren => children != null && children!.isNotEmpty;

  /// Whether this widget has events
  bool get hasEvents => events != null && events!.isNotEmpty;
}
