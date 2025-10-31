/// Shared parsing utilities for widget configuration
/// 
/// Centralizes all JSON parsing methods used across widget builders.
/// This allows the UIRenderer to delegate parsing to a dedicated utility class.

import 'package:flutter/material.dart';

/// Centralized parsing utilities for widget properties
/// 
/// Provides static methods to parse common properties from JSON:
/// - Colors, sizes, dimensions
/// - Alignments, offsets, positions
/// - Borders, shadows, decorations
/// - Font properties, text styles
/// - Icon data and other Flutter types
class ParseUtils {
  // ===== NUMERIC & BASIC TYPES =====

  /// Parse double from dynamic value (number or string)
  static double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  /// Parse integer from dynamic value
  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  // ===== ALIGNMENT PARSING =====

  /// Parse MainAxisAlignment (start, center, end, spaceBetween, spaceAround, spaceEvenly)
  static MainAxisAlignment parseMainAxisAlignment(dynamic value) {
    return switch (value) {
      'center' => MainAxisAlignment.center,
      'end' => MainAxisAlignment.end,
      'spaceBetween' => MainAxisAlignment.spaceBetween,
      'spaceAround' => MainAxisAlignment.spaceAround,
      'spaceEvenly' => MainAxisAlignment.spaceEvenly,
      _ => MainAxisAlignment.start,
    };
  }

  /// Parse CrossAxisAlignment (start, center, end, stretch, baseline)
  static CrossAxisAlignment parseCrossAxisAlignment(dynamic value) {
    return switch (value) {
      'center' => CrossAxisAlignment.center,
      'end' => CrossAxisAlignment.end,
      'stretch' => CrossAxisAlignment.stretch,
      'baseline' => CrossAxisAlignment.baseline,
      _ => CrossAxisAlignment.start,
    };
  }

  /// Parse Alignment (9 preset positions or custom x,y)
  static Alignment parseAlignment(dynamic value) {
    return switch (value) {
      'topLeft' => Alignment.topLeft,
      'topCenter' => Alignment.topCenter,
      'topRight' => Alignment.topRight,
      'centerLeft' => Alignment.centerLeft,
      'center' => Alignment.center,
      'centerRight' => Alignment.centerRight,
      'bottomLeft' => Alignment.bottomLeft,
      'bottomCenter' => Alignment.bottomCenter,
      'bottomRight' => Alignment.bottomRight,
      _ => Alignment.center,
    };
  }

  /// Parse Alignment from string or map with x,y coordinates
  static Alignment parseAlignmentFromValue(dynamic value) {
    if (value == null) return Alignment.center;

    if (value is String) {
      // Handle both camelCase and lowercase formats
      final normalized =
          value.toLowerCase().replaceAll('_', '').replaceAll('-', '');
      switch (normalized) {
        case 'topleft':
          return Alignment.topLeft;
        case 'topcenter':
          return Alignment.topCenter;
        case 'topright':
          return Alignment.topRight;
        case 'centerleft':
          return Alignment.centerLeft;
        case 'center':
          return Alignment.center;
        case 'centerright':
          return Alignment.centerRight;
        case 'bottomleft':
          return Alignment.bottomLeft;
        case 'bottomcenter':
          return Alignment.bottomCenter;
        case 'bottomright':
          return Alignment.bottomRight;
        default:
          return Alignment.center;
      }
    }

    if (value is Map) {
      final x = (value['x'] as num?)?.toDouble() ?? 0.0;
      final y = (value['y'] as num?)?.toDouble() ?? 0.0;
      return Alignment(x, y);
    }

    return Alignment.center;
  }

  // ===== TEXT PARSING =====

  /// Parse TextAlign (left, center, right, justify, end)
  static TextAlign parseTextAlign(dynamic value) {
    return switch (value) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      'justify' => TextAlign.justify,
      'end' => TextAlign.end,
      _ => TextAlign.left,
    };
  }

  /// Parse FontWeight (normal, bold, w300, w400, w500, w600, w700, w900)
  static FontWeight parseFontWeight(dynamic value) {
    return switch (value) {
      'bold' => FontWeight.bold,
      'w300' => FontWeight.w300,
      'w400' => FontWeight.w400,
      'w500' => FontWeight.w500,
      'w600' => FontWeight.w600,
      'w700' => FontWeight.w700,
      'w900' => FontWeight.w900,
      _ => FontWeight.normal,
    };
  }

  /// Parse TextStyle from configuration
  static TextStyle? parseTextStyle(dynamic value) {
    if (value == null || value is! Map) return null;

    return TextStyle(
      color: parseColor(value['color']),
      fontSize: parseDouble(value['fontSize']),
      fontWeight: parseFontWeight(value['fontWeight']),
      fontStyle: value['fontStyle'] == 'italic' ? FontStyle.italic : null,
      letterSpacing: parseDouble(value['letterSpacing']),
      wordSpacing: parseDouble(value['wordSpacing']),
      height: parseDouble(value['height']),
      decoration: value['textDecoration'] == 'underline'
          ? TextDecoration.underline
          : value['textDecoration'] == 'lineThrough'
              ? TextDecoration.lineThrough
              : null,
    );
  }

  // ===== COLOR PARSING =====

  /// Parse color from hex string or color name
  /// 
  /// Supports:
  /// - Hex: "#FF0000", "#FF0000FF" (with alpha)
  /// - Names: "red", "blue", "green", etc.
  static Color? parseColor(dynamic value) {
    if (value is String) {
      if (value.startsWith('#')) {
        final hexColor = value.replaceFirst('#', '');
        // If 6-digit hex, add full opacity; if 8-digit, use as-is
        final colorString = hexColor.length == 6
            ? 'FF$hexColor'
            : hexColor.padLeft(8, '0');
        return Color(int.parse('0x$colorString'));
      }
      return switch (value.toLowerCase()) {
        'red' => Colors.red,
        'green' => Colors.green,
        'blue' => Colors.blue,
        'white' => Colors.white,
        'black' => Colors.black,
        'grey' => Colors.grey,
        'amber' => Colors.amber,
        'orange' => Colors.orange,
        'yellow' => Colors.yellow,
        'pink' => Colors.pink,
        'purple' => Colors.purple,
        'cyan' => Colors.cyan,
        _ => null,
      };
    }
    return null;
  }

  /// Convert Color to MaterialColor for theming
  static MaterialColor colorToMaterialColor(Color color) {
    final int red = (color.r * 255.0).round() & 0xff;
    final int green = (color.g * 255.0).round() & 0xff;
    final int blue = (color.b * 255.0).round() & 0xff;

    final Map<int, Color> shades = {
      50: Color.fromRGBO(red, green, blue, .1),
      100: Color.fromRGBO(red, green, blue, .2),
      200: Color.fromRGBO(red, green, blue, .3),
      300: Color.fromRGBO(red, green, blue, .4),
      400: Color.fromRGBO(red, green, blue, .5),
      500: Color.fromRGBO(red, green, blue, .6),
      600: Color.fromRGBO(red, green, blue, .7),
      700: Color.fromRGBO(red, green, blue, .8),
      800: Color.fromRGBO(red, green, blue, .9),
      900: Color.fromRGBO(red, green, blue, 1),
    };

    return MaterialColor(color.toARGB32(), shades);
  }

  // ===== SPACING & DIMENSIONS =====

  /// Parse EdgeInsets from number, map, or shorthand notation
  /// 
  /// Supports:
  /// - number: applies to all sides
  /// - {"all": 8}
  /// - {"horizontal": 8, "vertical": 16}
  /// - {"left": 8, "top": 16, "right": 8, "bottom": 16}
  static EdgeInsets? parseEdgeInsets(dynamic value) {
    if (value == null) return null;
    if (value is num) return EdgeInsets.all(value.toDouble());
    if (value is Map) {
      // Handle "all" property for uniform padding
      if (value.containsKey('all')) {
        final allValue = (value['all'] as num?)?.toDouble() ?? 0;
        return EdgeInsets.all(allValue);
      }

      // Handle horizontal and vertical shorthand
      if (value.containsKey('horizontal') || value.containsKey('vertical')) {
        final horizontal = (value['horizontal'] as num?)?.toDouble() ?? 0;
        final vertical = (value['vertical'] as num?)?.toDouble() ?? 0;
        return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
      }

      // Handle individual sides (LTRB)
      return EdgeInsets.fromLTRB(
        (value['left'] as num?)?.toDouble() ?? 0,
        (value['top'] as num?)?.toDouble() ?? 0,
        (value['right'] as num?)?.toDouble() ?? 0,
        (value['bottom'] as num?)?.toDouble() ?? 0,
      );
    }
    return null;
  }

  /// Parse Offset from map {"dx": x, "dy": y}
  static Offset parseOffset(dynamic value) {
    if (value is Map) {
      final dx = (value['dx'] as num?)?.toDouble() ?? 0.0;
      final dy = (value['dy'] as num?)?.toDouble() ?? 0.0;
      return Offset(dx, dy);
    }
    return Offset.zero;
  }

  // ===== BORDER & DECORATION =====

  /// Parse BorderRadius from number or detailed configuration
  /// 
  /// Supports:
  /// - number: all corners
  /// - {"all": 8}
  /// - {"topLeft": 8, "topRight": 4, ...}
  static BorderRadius? parseBorderRadius(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return BorderRadius.circular(value.toDouble());
    }

    if (value is Map) {
      // Check for "all" property
      if (value.containsKey('all')) {
        final radius = (value['all'] as num?)?.toDouble() ?? 0.0;
        return BorderRadius.circular(radius);
      }

      // Individual corner radii
      final topLeft = (value['topLeft'] as num?)?.toDouble() ?? 0.0;
      final topRight = (value['topRight'] as num?)?.toDouble() ?? 0.0;
      final bottomLeft = (value['bottomLeft'] as num?)?.toDouble() ?? 0.0;
      final bottomRight = (value['bottomRight'] as num?)?.toDouble() ?? 0.0;

      return BorderRadius.only(
        topLeft: Radius.circular(topLeft),
        topRight: Radius.circular(topRight),
        bottomLeft: Radius.circular(bottomLeft),
        bottomRight: Radius.circular(bottomRight),
      );
    }

    return null;
  }

  /// Parse Border from configuration
  static Border? parseBorder(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      // Check if simple border (all sides same)
      if (value.containsKey('color') || value.containsKey('width')) {
        final color = parseColor(value['color']) ?? Colors.black;
        final width = (value['width'] as num?)?.toDouble() ?? 1.0;
        return Border.all(color: color, width: width);
      }

      // Complex border with individual sides
      return Border(
        left: parseBorderSide(value['left']) ?? BorderSide.none,
        right: parseBorderSide(value['right']) ?? BorderSide.none,
        top: parseBorderSide(value['top']) ?? BorderSide.none,
        bottom: parseBorderSide(value['bottom']) ?? BorderSide.none,
      );
    }
    return null;
  }

  /// Parse BorderSide from configuration
  static BorderSide? parseBorderSide(dynamic value) {
    if (value is Map) {
      final color = parseColor(value['color']) ?? Colors.black;
      final width = (value['width'] as num?)?.toDouble() ?? 1.0;
      final style = parseBorderStyle(value['style']);

      return BorderSide(color: color, width: width, style: style);
    }
    return null;
  }

  /// Parse BorderStyle from string
  static BorderStyle parseBorderStyle(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'solid':
          return BorderStyle.solid;
        case 'none':
          return BorderStyle.none;
        default:
          return BorderStyle.solid;
      }
    }
    return BorderStyle.solid;
  }

  /// Parse BoxShape from string
  static BoxShape parseBoxShape(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'circle':
          return BoxShape.circle;
        case 'rectangle':
          return BoxShape.rectangle;
        default:
          return BoxShape.rectangle;
      }
    }
    return BoxShape.rectangle;
  }

  /// Parse BoxDecoration from configuration
  static BoxDecoration? parseBoxDecoration(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return BoxDecoration(
        color: parseColor(value['color']),
        gradient: parseGradient(value['gradient']),
        border: parseBorder(value['border']),
        borderRadius: parseBorderRadius(value['borderRadius']),
        boxShadow: parseBoxShadow(value['boxShadow']),
        shape: parseBoxShape(value['shape']),
      );
    }
    return null;
  }

  // ===== GRADIENT & SHADOW =====

  /// Parse Gradient from configuration
  /// 
  /// Supports linear, radial, and sweep gradients
  /// with colors, stops, and positioning
  static Gradient? parseGradient(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      final type = value['type'] as String? ?? 'linear';
      final colors = (value['colors'] as List?)
          ?.map((c) => parseColor(c))
          .where((c) => c != null)
          .cast<Color>()
          .toList() ?? [];

      if (colors.isEmpty) return null;

      final stops = (value['stops'] as List?)
          ?.map((s) => (s as num).toDouble())
          .toList();

      switch (type.toLowerCase()) {
        case 'linear':
          return LinearGradient(
            colors: colors,
            stops: stops,
            begin: parseAlignmentFromValue(value['begin']),
            end: parseAlignmentFromValue(value['end']),
          );

        case 'radial':
          return RadialGradient(
            colors: colors,
            stops: stops,
            center: parseAlignmentFromValue(value['center']),
            radius: (value['radius'] as num?)?.toDouble() ?? 0.5,
          );

        case 'sweep':
          return SweepGradient(
            colors: colors,
            stops: stops,
            center: parseAlignmentFromValue(value['center']),
            startAngle: (value['startAngle'] as num?)?.toDouble() ?? 0.0,
            endAngle: (value['endAngle'] as num?)?.toDouble() ?? 6.28318530718, // 2π
          );

        default:
          return LinearGradient(colors: colors, stops: stops);
      }
    }
    return null;
  }

  /// Parse box shadows from list of shadow configurations
  static List<BoxShadow>? parseBoxShadow(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .map((shadow) => parseSingleBoxShadow(shadow))
          .where((shadow) => shadow != null)
          .cast<BoxShadow>()
          .toList();
    }
    return null;
  }

  /// Parse single BoxShadow from configuration
  static BoxShadow? parseSingleBoxShadow(dynamic value) {
    if (value is Map) {
      return BoxShadow(
        color: parseColor(value['color']) ?? Colors.black26,
        blurRadius: (value['blurRadius'] as num?)?.toDouble() ?? 0.0,
        spreadRadius: (value['spreadRadius'] as num?)?.toDouble() ?? 0.0,
        offset: parseOffset(value['offset']),
      );
    }
    return null;
  }

  // ===== ICON PARSING =====

  /// Parse IconData from string name
  /// 
  /// Supports Material Design icon names
  static IconData parseIconData(String iconName) {
    return switch (iconName.toLowerCase()) {
      'home' => Icons.home,
      'settings' => Icons.settings,
      'search' => Icons.search,
      'add' => Icons.add,
      'delete' => Icons.delete,
      'edit' => Icons.edit,
      'close' => Icons.close,
      'check' => Icons.check,
      'menu' => Icons.menu,
      'back' => Icons.arrow_back,
      'forward' => Icons.arrow_forward,
      'info' => Icons.info,
      'warning' => Icons.warning,
      'error' => Icons.error,
      'success' => Icons.check_circle,
      'favorite' => Icons.favorite,
      'star' => Icons.star,
      'share' => Icons.share,
      'download' => Icons.download,
      'upload' => Icons.upload,
      'camera' => Icons.camera,
      'photo' => Icons.photo,
      'phone' => Icons.phone,
      'email' => Icons.email,
      'location' => Icons.location_on,
      'notifications' => Icons.notifications,
      'save' => Icons.save,
      'refresh' => Icons.refresh,
      'filter' => Icons.filter_list,
      'sort' => Icons.sort,
      'more' => Icons.more_vert,
      'logout' => Icons.logout,
      'login' => Icons.login,
      _ => Icons.widgets,
    };
  }
}
