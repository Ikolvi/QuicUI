/// Widget data model for Server-Driven UI
///
/// This module defines the core data structures for JSON-based UI definitions.
/// [WidgetData] represents individual widgets that can be composed into screens.

import 'package:equatable/equatable.dart';

/// Represents a widget in the JSON-based UI definition.
///
/// WidgetData is the fundamental building block of QuicUI. It represents:
/// - A single Flutter widget
/// - Its properties and configuration
/// - Child widgets (for layout widgets)
/// - Event handlers and actions
/// - Conditional rendering logic
///
/// ## Supported Widget Types
///
/// ### Layout Widgets
/// - `column`: Vertical layout
/// - `row`: Horizontal layout
/// - `center`: Center content
/// - `container`: Container with decoration
/// - `stack`: Overlay widgets
/// - `listview`: Scrollable list
/// - `gridview`: Grid layout
/// - `padding`: Add padding
/// - `expanded`: Flexible expansion
///
/// ### Text & Input
/// - `text`: Static text
/// - `textfield`: Text input
/// - `richtext`: Rich formatted text
/// - `checkbox`: Checkbox input
/// - `radiobutton`: Radio button
///
/// ### Buttons & Interactions
/// - `button`: Standard button
/// - `floatingactionbutton`: FAB
/// - `iconbutton`: Icon button
/// - `gesturedetector`: Gesture handler
///
/// ### Display
/// - `image`: Display image
/// - `icon`: Display icon
/// - `card`: Material card
/// - `listtile`: List item
/// - `divider`: Visual divider
///
/// ### Other
/// - `scaffold`: App structure
/// - `appbar`: Top app bar
/// - `drawer`: Side navigation
/// - `badge`: Badge display
///
/// ## Example Usage
///
/// ```dart
/// // Simple text widget
/// const textWidget = WidgetData(
///   type: 'text',
///   properties: {
///     'text': 'Hello, World!',
///     'style': {
///       'fontSize': 24,
///       'fontWeight': 'bold',
///     },
///   },
/// );
///
/// // Button with action
/// const buttonWidget = WidgetData(
///   type: 'button',
///   properties: {
///     'label': 'Click Me',
///     'backgroundColor': '#2196F3',
///   },
///   events: {
///     'onPressed': {
///       'action': 'navigate',
///       'screen': 'detail_screen',
///     },
///   },
/// );
///
/// // Column with children
/// const column = WidgetData(
///   type: 'column',
///   properties: {'mainAxisAlignment': 'start'},
///   children: [textWidget, buttonWidget],
/// );
/// ```
///
/// ## Properties
///
/// Widget properties are type-safe and validated:
/// - Colors: `#RRGGBB` or `#RRGGBBAA` format
/// - Numbers: Integer or double values
/// - Enums: String values matching allowed options
/// - Objects: Nested property maps
/// - Arrays: Lists of values
///
/// ## State Binding
///
/// Properties can bind to application state:
/// ```dart
/// const binding = WidgetData(
///   type: 'text',
///   properties: {
///     'text': '\${state.userName}',  // Binds to state
///   },
/// );
/// ```
///
/// ## Event Handling
///
/// Events trigger actions:
/// ```dart
/// const eventWidget = WidgetData(
///   type: 'button',
///   properties: {'label': 'Save'},
///   events: {
///     'onPressed': {
///       'action': 'submitForm',
///       'formId': 'user_form',
///     },
///   },
/// );
/// ```
///
/// ## Conditional Rendering
///
/// Widgets can render conditionally:
/// ```dart
/// const conditionalWidget = WidgetData(
///   type: 'text',
///   properties: {'text': 'Premium User'},
///   condition: {
///     'field': 'isPremium',
///     'operator': 'equals',
///     'value': true,
///   },
/// );
/// ```
///
/// See also:
/// - [Screen]: Top-level screen definition
/// - [UIRenderer]: For rendering widgets to Flutter
/// - [WidgetFactory]: For creating Flutter widgets
class WidgetData extends Equatable {
  /// Type of widget (e.g., 'column', 'row', 'text', 'button')
  ///
  /// Determines which Flutter widget will be created.
  /// Must be one of the supported widget types.
  ///
  /// Common types:
  /// - Layout: column, row, center, container, stack, listview, gridview
  /// - Text: text, richtext, textfield
  /// - Input: checkbox, radiobutton
  /// - Button: button, floatingactionbutton, iconbutton
  /// - Display: image, icon, card, listtile
  final String type;

  /// Properties of the widget
  ///
  /// Maps property names to their values. Common properties:
  /// - `text`: Text content
  /// - `fontSize`: Font size in points
  /// - `backgroundColor`: Background color
  /// - `padding`: Padding values
  /// - `margin`: Margin values
  /// - `mainAxisAlignment`: For row/column
  /// - `crossAxisAlignment`: For row/column
  ///
  /// Property validation is performed during rendering.
  final Map<String, dynamic> properties;

  /// Child widgets (for layout widgets)
  ///
  /// Used by container widgets like:
  /// - Column/Row: Ordered children
  /// - Stack: Layered children
  /// - ListView: Scrollable children
  /// - Container: Single child
  ///
  /// null for widgets that don't support children (Text, Button, etc.)
  final List<WidgetData>? children;

  /// Event handlers
  ///
  /// Maps event names to their handlers:
  /// - `onPressed`: Button press
  /// - `onChanged`: Value changed
  /// - `onSubmitted`: Form submission
  /// - `onTap`: Tap gesture
  ///
  /// Each handler specifies:
  /// - `action`: Type of action (navigate, submitForm, etc.)
  /// - Additional parameters specific to the action
  final Map<String, dynamic>? events;

  /// Custom ID for reference
  ///
  /// Used to:
  /// - Reference widget in tests
  /// - Bind state to specific widget
  /// - Track user interactions
  ///
  /// Should be unique within the screen.
  final String? id;

  /// Conditional rendering
  ///
  /// Determines if widget should be rendered:
  /// - `field`: State field to check
  /// - `operator`: Comparison operator (equals, contains, etc.)
  /// - `value`: Expected value
  ///
  /// Widget is rendered only if condition evaluates to true.
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
