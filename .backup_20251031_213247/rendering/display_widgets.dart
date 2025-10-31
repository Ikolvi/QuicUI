import 'package:flutter/material.dart';
import 'parse_utils.dart';

/// Display Widget Builders
/// 
/// Extracted from UIRenderer, provides builders for all display-related widgets
/// including Text, Images, Icons, Cards, Badges, Chips, and more.
/// 
/// All methods are static and can be imported independently for use in other contexts.
/// 
/// Each builder accepts a [properties] map and optional [childrenData] and [context].
/// Uses [ParseUtils] for all parsing operations (colors, text styles, alignments, etc.)
class DisplayWidgets {
  DisplayWidgets._(); // Private constructor - static methods only

  /// Builds a Text widget with optional styling
  /// 
  /// Properties:
  /// - text: String
  /// - fontSize: double
  /// - fontWeight: String (bold, w700, normal, etc.)
  /// - color: String (hex color)
  /// - textAlign: String (left, center, right, justify)
  /// - maxLines: int
  static Widget buildText(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
  }) {
    var text = properties['text'] as String? ?? '';
    
    return Text(
      text,
      style: TextStyle(
        fontSize: ParseUtils.parseDouble(properties['fontSize']),
        fontWeight: ParseUtils.parseFontWeight(properties['fontWeight']),
        color: ParseUtils.parseColor(properties['color']),
      ),
      textAlign: ParseUtils.parseTextAlign(properties['textAlign']),
      maxLines: (properties['maxLines'] as num?)?.toInt(),
    );
  }

  /// Builds a RichText widget with styled text spans
  /// 
  /// Properties:
  /// - text: String (main text)
  /// - fontSize: double
  /// - color: String (hex color)
  static Widget buildRichText(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
  }) {
    return RichText(
      text: TextSpan(
        text: properties['text'] as String? ?? '',
        style: TextStyle(
          fontSize: ParseUtils.parseDouble(properties['fontSize']),
          color: ParseUtils.parseColor(properties['color']) ?? Colors.black,
        ),
      ),
    );
  }

  /// Builds an Image widget from URL or asset
  /// 
  /// Properties:
  /// - src: String (URL or asset path)
  /// - width: double
  /// - height: double
  /// - fit: String (cover, contain, fill, fitWidth, fitHeight, none, scaleDown)
  static Widget buildImage(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
  }) {
    final src = properties['src'] as String? ?? '';
    final width = ParseUtils.parseDouble(properties['width']);
    final height = ParseUtils.parseDouble(properties['height']);
    final fit = _parseImageFit(properties['fit']);

    if (src.startsWith('http')) {
      return Image.network(src, width: width, height: height, fit: fit);
    }
    return Image.asset(src, width: width, height: height, fit: fit);
  }

  /// Builds an Icon widget
  /// 
  /// Properties:
  /// - icon: String (icon name, e.g., 'info', 'edit', 'delete')
  /// - size: double
  /// - color: String (hex color)
  static Widget buildIcon(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
  }) {
    final iconName = properties['icon'] as String? ?? 'info';
    final size = ParseUtils.parseDouble(properties['size']) ?? 24.0;
    final color = ParseUtils.parseColor(properties['color']) ?? Colors.black;
    
    return Icon(ParseUtils.parseIconData(iconName), size: size, color: color);
  }

  /// Builds a Card widget with optional child
  /// 
  /// Properties:
  /// - elevation: double
  /// - color: String (hex color)
  /// - shadowColor: String (hex color)
  /// - margin: String (padding as number)
  static Widget buildCard(
    Map<String, dynamic> properties,
    List<dynamic> childrenData, {
    BuildContext? context,
    Widget Function(Map<String, dynamic>, List<dynamic>?, {BuildContext? context})? render,
  }) {
    // Note: render callback will be passed from UIRenderer
    // For now using placeholder - will be resolved in Phase 3
    final child = childrenData.isNotEmpty && render != null
        ? render(childrenData.first as Map<String, dynamic>, null, context: context)
        : null;
    
    return Card(
      elevation: ParseUtils.parseDouble(properties['elevation']) ?? 1.0,
      color: ParseUtils.parseColor(properties['color']),
      shadowColor: ParseUtils.parseColor(properties['shadowColor']),
      child: child ?? const Placeholder(),
    );
  }

  /// Builds a Divider widget
  /// 
  /// Properties:
  /// - height: double
  /// - thickness: double
  /// - color: String (hex color)
  static Widget buildDivider(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
  }) {
    return Divider(
      height: ParseUtils.parseDouble(properties['height']) ?? 16.0,
      thickness: ParseUtils.parseDouble(properties['thickness']) ?? 1.0,
      color: ParseUtils.parseColor(properties['color']),
    );
  }

  /// Builds a VerticalDivider widget
  /// 
  /// Properties:
  /// - width: double
  /// - thickness: double
  /// - color: String (hex color)
  static Widget buildVerticalDivider(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
  }) {
    return VerticalDivider(
      width: ParseUtils.parseDouble(properties['width']) ?? 16.0,
      thickness: ParseUtils.parseDouble(properties['thickness']) ?? 1.0,
      color: ParseUtils.parseColor(properties['color']),
    );
  }

  /// Builds a Badge widget
  /// 
  /// Properties:
  /// - label: String
  /// - backgroundColor: String (hex color)
  /// - textColor: String (hex color)
  static Widget buildBadge(
    Map<String, dynamic> properties,
    List<dynamic> childrenData, {
    BuildContext? context,
    Widget Function(Map<String, dynamic>, List<dynamic>?, {BuildContext? context})? render,
  }) {
    final label = properties['label'] as String? ?? '';
    // Note: render callback will be passed from UIRenderer
    final child = childrenData.isNotEmpty && render != null
        ? render(childrenData.first as Map<String, dynamic>, null, context: context)
        : null;
    
    return Badge(
      label: Text(label),
      backgroundColor: ParseUtils.parseColor(properties['backgroundColor']),
      textColor: ParseUtils.parseColor(properties['textColor']),
      child: child ?? const Icon(Icons.notifications),
    );
  }

  /// Builds a Chip widget
  /// 
  /// Properties:
  /// - label: String
  /// - backgroundColor: String (hex color)
  /// - deleteIcon: String (icon name for delete button)
  static Widget buildChip(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
  }) {
    return Chip(
      label: Text(properties['label'] as String? ?? ''),
      backgroundColor: ParseUtils.parseColor(properties['backgroundColor']),
    );
  }

  /// Builds an ActionChip widget
  /// 
  /// Properties:
  /// - label: String
  /// - icon: String (icon name)
  /// - onPressed: callback event
  static Widget buildActionChip(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Function(String?)? onCallback,
  }) {
    return ActionChip(
      label: Text(properties['label'] as String? ?? ''),
      onPressed: () {
        if (onCallback != null) {
          onCallback(properties['onPressed'] as String?);
        }
      },
    );
  }

  /// Builds a FilterChip widget
  /// 
  /// Properties:
  /// - label: String
  /// - selected: bool
  static Widget buildFilterChip(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
  }) {
    return FilterChip(
      label: Text(properties['label'] as String? ?? ''),
      selected: properties['selected'] as bool? ?? false,
      onSelected: (bool selected) {},
    );
  }

  /// Builds an InputChip widget
  /// 
  /// Properties:
  /// - label: String
  /// - deleteIcon: String (icon name)
  static Widget buildInputChip(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
  }) {
    return InputChip(
      label: Text(properties['label'] as String? ?? ''),
      deleteIcon: properties['deleteIcon'] != null
          ? Icon(ParseUtils.parseIconData(properties['deleteIcon'] as String))
          : null,
    );
  }

  /// Builds a ChoiceChip widget
  /// 
  /// Properties:
  /// - label: String
  /// - selected: bool
  /// - value: String
  static Widget buildChoiceChip(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
  }) {
    return ChoiceChip(
      label: Text(properties['label'] as String? ?? ''),
      selected: properties['selected'] as bool? ?? false,
      onSelected: (bool selected) {},
    );
  }

  /// Builds a Tooltip widget
  /// 
  /// Properties:
  /// - message: String
  static Widget buildTooltip(
    Map<String, dynamic> properties,
    List<dynamic> childrenData, {
    BuildContext? context,
    Widget Function(Map<String, dynamic>, List<dynamic>?, {BuildContext? context})? render,
  }) {
    // Note: render callback will be passed from UIRenderer
    final child = childrenData.isNotEmpty && render != null
        ? render(childrenData.first as Map<String, dynamic>, null, context: context)
        : null;
    
    return Tooltip(
      message: properties['message'] as String? ?? '',
      child: child ?? const Placeholder(),
    );
  }

  /// Builds a ListTile widget
  /// 
  /// Properties:
  /// - title: String
  /// - subtitle: String
  /// - leadingIcon: String (icon name)
  /// - trailingIcon: String (icon name)
  static Widget buildListTile(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
  }) {
    return ListTile(
      title: Text(properties['title'] as String? ?? ''),
      subtitle: properties['subtitle'] != null
          ? Text(properties['subtitle'] as String)
          : null,
      leading: properties['leadingIcon'] != null
          ? Icon(ParseUtils.parseIconData(properties['leadingIcon'] as String))
          : null,
      trailing: properties['trailingIcon'] != null
          ? Icon(ParseUtils.parseIconData(properties['trailingIcon'] as String))
          : null,
    );
  }

  // ===== HELPER METHODS =====

  /// Parses image fit value
  static BoxFit? _parseImageFit(dynamic value) {
    if (value == null) return null;
    
    final str = value.toString().toLowerCase().trim();
    switch (str) {
      case 'cover':
        return BoxFit.cover;
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitwidth':
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitheight':
      case 'fitHeight':
        return BoxFit.fitHeight;
      case 'none':
        return BoxFit.none;
      case 'scaledown':
      case 'scaleDown':
        return BoxFit.scaleDown;
      default:
        return null;
    }
  }
}
