import 'package:flutter/material.dart';

/// Dialog Widget Builders
/// 
/// Extracted from UIRenderer, provides builders for dialog and overlay widgets
/// including Dialog, AlertDialog, SimpleDialog, and Offstage.
/// 
/// All methods are static and can be imported independently for use in other contexts.
/// 
/// Each builder accepts a [properties] map and optional [childrenData] and [context].
class DialogWidgets {
  DialogWidgets._(); // Private constructor - static methods only

  /// Builds a Dialog widget
  /// 
  /// Properties:
  /// - title: String
  /// - backgroundColor: String (hex color)
  static Widget buildDialog(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Widget Function(Map<String, dynamic>, {List<dynamic>? childrenData, BuildContext? context})? render,
  }) {
    // Note: render callback will be passed from UIRenderer
    final child = childrenData != null && childrenData.isNotEmpty && render != null
        ? render(childrenData.first as Map<String, dynamic>, childrenData: null, context: context)
        : null;

    return Dialog(
      child: child ?? const Placeholder(),
    );
  }

  /// Builds an AlertDialog widget
  /// 
  /// Properties:
  /// - title: String
  /// - message: String (content/body text)
  /// - positiveButtonLabel: String (confirm button text)
  /// - negativeButtonLabel: String (cancel button text)
  static Widget buildAlertDialog(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Function(String)? onButtonPressed,
  }) {
    final title = properties['title'] as String? ?? 'Alert';
    final message = properties['message'] as String? ?? '';
    final positiveLabel = properties['positiveButtonLabel'] as String? ?? 'OK';
    final negativeLabel = properties['negativeButtonLabel'] as String? ?? 'Cancel';

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            if (onButtonPressed != null) {
              onButtonPressed('negative');
            }
          },
          child: Text(negativeLabel),
        ),
        TextButton(
          onPressed: () {
            if (onButtonPressed != null) {
              onButtonPressed('positive');
            }
          },
          child: Text(positiveLabel),
        ),
      ],
    );
  }

  /// Builds a SimpleDialog widget
  /// 
  /// Properties:
  /// - title: String
  /// - options: List<String> (dialog option buttons)
  static Widget buildSimpleDialog(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Function(String)? onOptionSelected,
  }) {
    final title = properties['title'] as String? ?? 'Choose an option';
    final options = properties['options'] as List? ?? [];

    return SimpleDialog(
      title: Text(title),
      children: options
          .map((option) => SimpleDialogOption(
                onPressed: () {
                  if (onOptionSelected != null) {
                    onOptionSelected(option.toString());
                  }
                },
                child: Text(option.toString()),
              ))
          .toList(),
    );
  }

  /// Builds an Offstage widget (hides/shows child without taking space)
  /// 
  /// Properties:
  /// - offstage: bool (true = hidden, false = visible)
  static Widget buildOffstage(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Widget Function(Map<String, dynamic>, {List<dynamic>? childrenData, BuildContext? context})? render,
  }) {
    // Note: render callback will be passed from UIRenderer
    final child = childrenData != null && childrenData.isNotEmpty && render != null
        ? render(childrenData.first as Map<String, dynamic>, childrenData: null, context: context)
        : null;

    return Offstage(
      offstage: properties['offstage'] as bool? ?? false,
      child: child ?? const Placeholder(),
    );
  }

  /// Builds a Visibility widget (controls visibility and space)
  /// 
  /// Properties:
  /// - visible: bool (true = visible, false = hidden)
  /// - maintainSize: bool (whether to maintain space when hidden)
  /// - maintainAnimation: bool
  /// - maintainState: bool
  static Widget buildVisibility(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Widget Function(Map<String, dynamic>, {List<dynamic>? childrenData, BuildContext? context})? render,
  }) {
    // Note: render callback will be passed from UIRenderer
    final child = childrenData != null && childrenData.isNotEmpty && render != null
        ? render(childrenData.first as Map<String, dynamic>, childrenData: null, context: context)
        : null;

    return Visibility(
      visible: properties['visible'] as bool? ?? true,
      maintainSize: properties['maintainSize'] as bool? ?? false,
      maintainAnimation: properties['maintainAnimation'] as bool? ?? false,
      maintainState: properties['maintainState'] as bool? ?? false,
      child: child ?? const Placeholder(),
    );
  }

  /// Builds a SnackBar widget - notification at bottom of screen
  /// 
  /// Properties:
  /// - message: String (notification text)
  /// - duration: int (milliseconds, default 4000)
  /// - actionLabel: String (action button text)
  /// - backgroundColor: String (hex color)
  static Widget buildSnackBar(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
  }) {
    final message = properties['message'] as String? ?? 'SnackBar';
    final backgroundColor = _parseColor(properties['backgroundColor'] as String?) ?? Colors.grey[800]!;
    final actionLabel = properties['actionLabel'] as String?;

    return Container(
      height: 48,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: () {},
              child: Text(
                actionLabel,
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds an ExpansionPanel - collapsible panel widget
  /// 
  /// Properties:
  /// - title: String (header text)
  /// - isExpanded: bool (whether expanded by default)
  /// - backgroundColor: String (hex color)
  static Widget buildExpansionPanel(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Widget Function(Map<String, dynamic>, {List<dynamic>? childrenData, BuildContext? context})? render,
  }) {
    final title = properties['title'] as String? ?? 'Expansion Panel';
    final children = childrenData != null && render != null
        ? (render as Function)(childrenData) as List<Widget>
        : <Widget>[];
    final backgroundColor = _parseColor(properties['backgroundColor'] as String?) ?? Colors.white;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
        color: backgroundColor,
      ),
      child: ExpansionTile(
        title: Text(title),
        children: children.cast<Widget>(),
      ),
    );
  }

  // Helper methods
  static Color? _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return null;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    } catch (e) {
      return null;
    }
  }
}
