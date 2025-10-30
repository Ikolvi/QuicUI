/// Main UI renderer implementation
/// 
/// Converts JSON configuration to Flutter widgets with support for:
/// - 25+ built-in Flutter widgets across all categories
/// - Event handling and callbacks
/// - Theme integration
/// - Conditional rendering
/// - Layout, display, and input widgets

import 'package:flutter/material.dart';

/// Main UI renderer for building Flutter widgets from JSON
class UIRenderer {
  /// Render a widget tree from JSON configuration
  /// 
  /// Supports nested widgets with full Flutter widget library
  static Widget render(Map<String, dynamic> config, {BuildContext? context}) {
    final type = config['type'] as String?;
    if (type == null) {
      return const Placeholder();
    }

    // Handle conditional rendering
    final shouldRender = config['shouldRender'] as bool? ?? true;
    if (!shouldRender) {
      return const SizedBox.shrink();
    }

    return _renderWidgetByType(type, config, context);
  }

  /// Render a list of widgets from JSON array
  static List<Widget> renderList(List<dynamic> widgetsData, {BuildContext? context}) {
    return widgetsData
        .whereType<Map<String, dynamic>>()
        .map((data) => render(data, context: context))
        .toList();
  }

  /// Render widget by type with configuration
  static Widget _renderWidgetByType(
    String type,
    Map<String, dynamic> config,
    BuildContext? context,
  ) {
    final properties = config['properties'] as Map<String, dynamic>? ?? {};
    final childrenData = config['children'] as List? ?? [];

    try {
      return switch (type) {
        // ===== LAYOUT WIDGETS =====
        'Column' => _buildColumn(properties, childrenData, context),
        'Row' => _buildRow(properties, childrenData, context),
        'Container' => _buildContainer(properties, childrenData, context),
        'Stack' => _buildStack(properties, childrenData, context),
        'Center' => _buildCenter(properties, childrenData, context),
        'Padding' => _buildPadding(properties, childrenData, context),
        'Align' => _buildAlign(properties, childrenData, context),
        'Expanded' => _buildExpanded(properties, childrenData, context),
        'Flexible' => _buildFlexible(properties, childrenData, context),
        'SizedBox' => _buildSizedBox(properties, childrenData, context),
        'SingleChildScrollView' => _buildSingleChildScrollView(properties, childrenData, context),
        'ListView' => _buildListView(properties, childrenData, context),
        'GridView' => _buildGridView(properties, childrenData, context),
        'Wrap' => _buildWrap(properties, childrenData, context),
        
        // ===== DISPLAY WIDGETS =====
        'Text' => _buildText(properties),
        'Image' => _buildImage(properties),
        'Icon' => _buildIcon(properties),
        'Card' => _buildCard(properties, childrenData, context),
        'Divider' => _buildDivider(properties),
        'Badge' => _buildBadge(properties, childrenData, context),
        
        // ===== INPUT WIDGETS =====
        'ElevatedButton' => _buildElevatedButton(properties),
        'TextButton' => _buildTextButton(properties),
        'IconButton' => _buildIconButton(properties),
        'TextField' => _buildTextField(properties),
        'Checkbox' => _buildCheckbox(properties),
        'Radio' => _buildRadio(properties),
        'Switch' => _buildSwitch(properties),
        'Slider' => _buildSlider(properties),
        
        _ => const Placeholder(),
      };
    } catch (e) {
      return _buildErrorWidget(e.toString());
    }
  }

  // ===== LAYOUT WIDGET BUILDERS =====

  static Widget _buildColumn(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final children = renderList(childrenData, context: context);
    return Column(
      mainAxisAlignment: _parseMainAxisAlignment(properties['mainAxisAlignment']),
      crossAxisAlignment: _parseCrossAxisAlignment(properties['crossAxisAlignment']),
      mainAxisSize: properties['mainAxisSize'] == 'min' ? MainAxisSize.min : MainAxisSize.max,
      children: children,
    );
  }

  static Widget _buildRow(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final children = renderList(childrenData, context: context);
    return Row(
      mainAxisAlignment: _parseMainAxisAlignment(properties['mainAxisAlignment']),
      crossAxisAlignment: _parseCrossAxisAlignment(properties['crossAxisAlignment']),
      mainAxisSize: properties['mainAxisSize'] == 'min' ? MainAxisSize.min : MainAxisSize.max,
      children: children,
    );
  }

  static Widget _buildContainer(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return Container(
      width: (properties['width'] as num?)?.toDouble(),
      height: (properties['height'] as num?)?.toDouble(),
      color: _parseColor(properties['color']),
      padding: _parseEdgeInsets(properties['padding']),
      margin: _parseEdgeInsets(properties['margin']),
      decoration: _parseBoxDecoration(properties['decoration']),
      child: child,
    );
  }

  static Widget _buildStack(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final children = renderList(childrenData, context: context);
    return Stack(
      alignment: _parseAlignment(properties['alignment']),
      fit: properties['fit'] == 'expand' ? StackFit.expand : StackFit.loose,
      children: children,
    );
  }

  static Widget _buildCenter(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return Center(child: child ?? const Placeholder());
  }

  static Widget _buildPadding(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return Padding(
      padding: _parseEdgeInsets(properties['padding']) ?? EdgeInsets.zero,
      child: child ?? const Placeholder(),
    );
  }

  static Widget _buildAlign(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return Align(
      alignment: _parseAlignment(properties['alignment']),
      child: child ?? const Placeholder(),
    );
  }

  static Widget _buildExpanded(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    final flex = (properties['flex'] as num?)?.toInt() ?? 1;
    return Expanded(
      flex: flex,
      child: child ?? const Placeholder(),
    );
  }

  static Widget _buildFlexible(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    final flex = (properties['flex'] as num?)?.toInt() ?? 1;
    return Flexible(
      flex: flex,
      fit: properties['fit'] == 'tight' ? FlexFit.tight : FlexFit.loose,
      child: child ?? const Placeholder(),
    );
  }

  static Widget _buildSizedBox(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return SizedBox(
      width: (properties['width'] as num?)?.toDouble(),
      height: (properties['height'] as num?)?.toDouble(),
      child: child,
    );
  }

  static Widget _buildSingleChildScrollView(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return SingleChildScrollView(
      scrollDirection:
          properties['scrollDirection'] == 'horizontal' ? Axis.horizontal : Axis.vertical,
      child: child ?? const Placeholder(),
    );
  }

  static Widget _buildListView(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final children = renderList(childrenData, context: context);
    final scrollDirection =
        properties['scrollDirection'] == 'horizontal' ? Axis.horizontal : Axis.vertical;
    return ListView(
      scrollDirection: scrollDirection,
      shrinkWrap: properties['shrinkWrap'] as bool? ?? false,
      children: children,
    );
  }

  static Widget _buildGridView(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final children = renderList(childrenData, context: context);
    final crossAxisCount = (properties['crossAxisCount'] as num?)?.toInt() ?? 2;
    final childAspectRatio = (properties['childAspectRatio'] as num?)?.toDouble() ?? 1.0;
    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      shrinkWrap: properties['shrinkWrap'] as bool? ?? false,
      children: children,
    );
  }

  static Widget _buildWrap(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final children = renderList(childrenData, context: context);
    return Wrap(
      spacing: (properties['spacing'] as num?)?.toDouble() ?? 8.0,
      runSpacing: (properties['runSpacing'] as num?)?.toDouble() ?? 8.0,
      direction: properties['direction'] == 'horizontal' ? Axis.horizontal : Axis.vertical,
      children: children,
    );
  }

  // ===== DISPLAY WIDGET BUILDERS =====

  static Widget _buildText(Map<String, dynamic> properties) {
    final text = properties['text'] as String? ?? '';
    final maxLines = (properties['maxLines'] as num?)?.toInt();
    return Text(
      text,
      style: TextStyle(
        fontSize: (properties['fontSize'] as num?)?.toDouble(),
        fontWeight: _parseFontWeight(properties['fontWeight']),
        color: _parseColor(properties['color']),
        letterSpacing: (properties['letterSpacing'] as num?)?.toDouble(),
        height: (properties['lineHeight'] as num?)?.toDouble(),
      ),
      textAlign: _parseTextAlign(properties['textAlign']),
      overflow: properties['overflow'] == 'ellipsis' ? TextOverflow.ellipsis : TextOverflow.clip,
      maxLines: maxLines,
    );
  }

  static Widget _buildImage(Map<String, dynamic> properties) {
    final src = properties['src'] as String? ?? '';
    final width = (properties['width'] as num?)?.toDouble();
    final height = (properties['height'] as num?)?.toDouble();

    if (src.startsWith('http')) {
      return Image.network(
        src,
        width: width,
        height: height,
        fit: _parseBoxFit(properties['fit']),
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported),
          );
        },
      );
    } else {
      return Image.asset(
        src,
        width: width,
        height: height,
        fit: _parseBoxFit(properties['fit']),
      );
    }
  }

  static Widget _buildIcon(Map<String, dynamic> properties) {
    final iconName = properties['icon'] as String? ?? 'info';
    final size = (properties['size'] as num?)?.toDouble() ?? 24.0;
    final color = _parseColor(properties['color']) ?? Colors.black;
    return Icon(_parseIconData(iconName), size: size, color: color);
  }

  static Widget _buildCard(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    final elevation = (properties['elevation'] as num?)?.toDouble() ?? 1.0;
    return Card(
      elevation: elevation,
      child: child ?? const Placeholder(),
    );
  }

  static Widget _buildDivider(Map<String, dynamic> properties) {
    return Divider(
      height: (properties['height'] as num?)?.toDouble() ?? 16.0,
      thickness: (properties['thickness'] as num?)?.toDouble() ?? 1.0,
      color: _parseColor(properties['color']),
    );
  }

  static Widget _buildBadge(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final label = properties['label'] as String? ?? '';
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return Badge(
      label: Text(label),
      child: child ?? const Icon(Icons.notifications),
    );
  }

  // ===== INPUT WIDGET BUILDERS =====

  static Widget _buildElevatedButton(Map<String, dynamic> properties) {
    final label = properties['label'] as String? ?? 'Button';
    final onPressed = properties['onPressed'] as String?;
    return ElevatedButton(
      onPressed: onPressed != null ? () => _handleButtonPress(onPressed) : null,
      child: Text(label),
    );
  }

  static Widget _buildTextButton(Map<String, dynamic> properties) {
    final label = properties['label'] as String? ?? 'Button';
    final onPressed = properties['onPressed'] as String?;
    return TextButton(
      onPressed: onPressed != null ? () => _handleButtonPress(onPressed) : null,
      child: Text(label),
    );
  }

  static Widget _buildIconButton(Map<String, dynamic> properties) {
    final iconName = properties['icon'] as String? ?? 'info';
    final onPressed = properties['onPressed'] as String?;
    return IconButton(
      icon: Icon(_parseIconData(iconName)),
      onPressed: onPressed != null ? () => _handleButtonPress(onPressed) : null,
    );
  }

  static Widget _buildTextField(Map<String, dynamic> properties) {
    final label = properties['label'] as String? ?? '';
    final hint = properties['hint'] as String? ?? '';
    final obscureText = properties['obscureText'] as bool? ?? false;
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      obscureText: obscureText,
    );
  }

  static Widget _buildCheckbox(Map<String, dynamic> properties) {
    final label = properties['label'] as String? ?? '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: properties['value'] as bool? ?? false,
          onChanged: (value) {},
        ),
        if (label.isNotEmpty) Text(label),
      ],
    );
  }

  static Widget _buildRadio(Map<String, dynamic> properties) {
    final label = properties['label'] as String? ?? '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio(
          value: properties['value'] ?? '',
          groupValue: properties['groupValue'] ?? '',
          onChanged: (value) {},
        ),
        if (label.isNotEmpty) Text(label),
      ],
    );
  }

  static Widget _buildSwitch(Map<String, dynamic> properties) {
    final label = properties['label'] as String? ?? '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: properties['value'] as bool? ?? false,
          onChanged: (value) {},
        ),
        if (label.isNotEmpty) Text(label),
      ],
    );
  }

  static Widget _buildSlider(Map<String, dynamic> properties) {
    final min = (properties['min'] as num?)?.toDouble() ?? 0.0;
    final max = (properties['max'] as num?)?.toDouble() ?? 100.0;
    final value = (properties['value'] as num?)?.toDouble() ?? min;
    return Slider(
      min: min,
      max: max,
      value: value,
      onChanged: (newValue) {},
    );
  }

  // ===== HELPER METHODS =====

  static Widget _buildErrorWidget(String error) {
    return Container(
      color: Colors.red[50],
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(height: 8),
          Text('Error: $error', style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  static void _handleButtonPress(String action) {
    // Handle button press actions - can be extended for navigation, etc.
    print('Button pressed: $action');
  }

  static MainAxisAlignment _parseMainAxisAlignment(dynamic value) {
    return switch (value) {
      'center' => MainAxisAlignment.center,
      'end' => MainAxisAlignment.end,
      'spaceBetween' => MainAxisAlignment.spaceBetween,
      'spaceAround' => MainAxisAlignment.spaceAround,
      'spaceEvenly' => MainAxisAlignment.spaceEvenly,
      _ => MainAxisAlignment.start,
    };
  }

  static CrossAxisAlignment _parseCrossAxisAlignment(dynamic value) {
    return switch (value) {
      'center' => CrossAxisAlignment.center,
      'end' => CrossAxisAlignment.end,
      'stretch' => CrossAxisAlignment.stretch,
      'baseline' => CrossAxisAlignment.baseline,
      _ => CrossAxisAlignment.start,
    };
  }

  static TextAlign _parseTextAlign(dynamic value) {
    return switch (value) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      'justify' => TextAlign.justify,
      'end' => TextAlign.end,
      _ => TextAlign.left,
    };
  }

  static FontWeight _parseFontWeight(dynamic value) {
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

  static Color? _parseColor(dynamic value) {
    if (value is String) {
      if (value.startsWith('#')) {
        final hexColor = value.replaceFirst('#', '');
        return Color(int.parse('0x${hexColor.padLeft(8, '0')}'));
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

  static EdgeInsets? _parseEdgeInsets(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      return EdgeInsets.all(value.toDouble());
    }
    if (value is Map) {
      return EdgeInsets.fromLTRB(
        (value['left'] as num?)?.toDouble() ?? 0,
        (value['top'] as num?)?.toDouble() ?? 0,
        (value['right'] as num?)?.toDouble() ?? 0,
        (value['bottom'] as num?)?.toDouble() ?? 0,
      );
    }
    return null;
  }

  static Alignment _parseAlignment(dynamic value) {
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

  static BoxFit _parseBoxFit(dynamic value) {
    return switch (value) {
      'fill' => BoxFit.fill,
      'contain' => BoxFit.contain,
      'cover' => BoxFit.cover,
      'fitWidth' => BoxFit.fitWidth,
      'fitHeight' => BoxFit.fitHeight,
      'scaleDown' => BoxFit.scaleDown,
      _ => BoxFit.contain,
    };
  }

  static IconData _parseIconData(String iconName) {
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
      _ => Icons.widgets,
    };
  }

  static BoxDecoration? _parseBoxDecoration(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return BoxDecoration(
        color: _parseColor(value['color']),
        border: _parseBorder(value['border']),
        borderRadius: _parseBorderRadius(value['borderRadius']),
      );
    }
    return null;
  }

  static Border? _parseBorder(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      final color = _parseColor(value['color']) ?? Colors.black;
      final width = (value['width'] as num?)?.toDouble() ?? 1.0;
      return Border.all(color: color, width: width);
    }
    return null;
  }

  static BorderRadius? _parseBorderRadius(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      return BorderRadius.circular(value.toDouble());
    }
    return null;
  }
}
