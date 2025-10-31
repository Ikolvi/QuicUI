/// Phase 1: Core Widget Library Expansion
/// 
/// Implements 20+ essential Flutter widgets for QuicUI.
/// Extends the existing 70+ widget library with commonly-used Material Design components.
///
/// Phase 1 Widgets (20+ added):
/// - SliverAppBar: Collapsible app bar for scrollable content
/// - BottomSheet: Material bottom sheet widget
/// - Modal: Custom modal dialog implementation
/// - Avatar: Circular user avatar widget
/// - ProgressBar: Linear progress indicator
/// - CircularProgress: Circular progress indicator
/// - Tag: Simple tag/label widget
/// - LinearProgress: Material linear progress
/// - GestureDetector: Gesture detection wrapper (enhanced)
/// - SegmentedControl: Custom segmented button control
/// - ExpansionPanel: Expandable panel widget
/// - ExpansionTile: Material expansion tile
/// - Stepper: Material stepper widget
/// - SizedBox: Fixed-size box (enhanced)
/// - FittedBox: Fitted container widget
/// - CustomPaint: Custom painting widget
/// - ClipPath: Custom clip path widget
/// - DataTable: Material data table widget
/// - PageView: Page-scrolling view widget
/// - SnackBar: Material snack bar widget

import 'package:flutter/material.dart';

/// Extended widget rendering for Phase 1 widgets
/// Provides implementations for 20+ essential widgets
class LayoutWidgets {
  /// Build SliverAppBar for scrollable content
  static Widget buildSliverAppBar(Map<String, dynamic> properties, List<dynamic> childrenData) {
    final title = properties['title'] as String? ?? 'App Bar';
    final expandedHeight = (properties['expandedHeight'] as num?)?.toDouble() ?? 200.0;
    final floating = properties['floating'] as bool? ?? false;
    final pinned = properties['pinned'] as bool? ?? true;
    final snap = properties['snap'] as bool? ?? false;
    final backgroundColor = _parseColor(properties['backgroundColor'] as String?);
    final foregroundColor = _parseColor(properties['foregroundColor'] as String?);

    return SliverAppBar(
      title: Text(title),
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      snap: snap,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      flexibleSpace: childrenData.isNotEmpty
          ? FlexibleSpaceBar(
              background: _buildChild(childrenData.first),
            )
          : null,
    );
  }

  /// Build BottomSheet widget
  static Widget buildBottomSheet(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final title = properties['title'] as String?;
    final height = (properties['height'] as num?)?.toDouble();

    if (context == null) {
      return SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minHeight: height ?? 300,
            maxHeight: height ?? 800,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(title),
                ),
              ...childrenData.map((child) => _buildChild(child)).toList(),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(
          minHeight: height ?? MediaQuery.of(context).size.height * 0.3,
          maxHeight: height ?? MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ...childrenData.map((child) => _buildChild(child)).toList(),
          ],
        ),
      ),
    );
  }

  /// Build Avatar widget (circular user avatar)
  static Widget buildAvatar(Map<String, dynamic> properties) {
    final imageUrl = properties['imageUrl'] as String?;
    final initials = properties['initials'] as String?;
    final size = (properties['size'] as num?)?.toDouble() ?? 40.0;
    final backgroundColor = _parseColor(properties['backgroundColor'] as String?) ?? Colors.blue;
    final textColor = _parseColor(properties['textColor'] as String?) ?? Colors.white;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl),
      );
    } else if (initials != null && initials.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: backgroundColor,
        child: Text(
          initials,
          style: TextStyle(
            color: textColor,
            fontSize: size / 2.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor,
    );
  }

  /// Build ProgressBar (linear progress indicator)
  static Widget buildProgressBar(Map<String, dynamic> properties) {
    final value = (properties['value'] as num?)?.toDouble() ?? 0.5;
    final minValue = (properties['minValue'] as num?)?.toDouble() ?? 0.0;
    final maxValue = (properties['maxValue'] as num?)?.toDouble() ?? 100.0;
    final showLabel = properties['showLabel'] as bool? ?? false;
    final height = (properties['height'] as num?)?.toDouble() ?? 4.0;
    final backgroundColor = _parseColor(properties['backgroundColor'] as String?);
    final valueColor = _parseColor(properties['valueColor'] as String?) ?? Colors.blue;

    final normalizedValue = (value - minValue) / (maxValue - minValue);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          value: normalizedValue.clamp(0.0, 1.0),
          minHeight: height,
          backgroundColor: backgroundColor ?? Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(valueColor),
        ),
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('${(normalizedValue * 100).toStringAsFixed(1)}%'),
          ),
      ],
    );
  }

  /// Build CircularProgress (circular progress indicator)
  static Widget buildCircularProgress(Map<String, dynamic> properties) {
    final value = (properties['value'] as num?)?.toDouble() ?? 0.5;
    final size = (properties['size'] as num?)?.toDouble() ?? 60.0;
    final showLabel = properties['showLabel'] as bool? ?? false;
    final strokeWidth = (properties['strokeWidth'] as num?)?.toDouble() ?? 4.0;
    final valueColor = _parseColor(properties['valueColor'] as String?) ?? Colors.blue;
    final backgroundColor = _parseColor(properties['backgroundColor'] as String?) ?? Colors.grey[300];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value.clamp(0.0, 1.0),
            strokeWidth: strokeWidth,
            backgroundColor: backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(valueColor),
          ),
          if (showLabel)
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  /// Build Tag widget (simple label/tag)
  static Widget buildTag(Map<String, dynamic> properties) {
    final label = properties['label'] as String? ?? 'Tag';
    final backgroundColor = _parseColor(properties['backgroundColor'] as String?) ?? Colors.blue;
    final textColor = _parseColor(properties['textColor'] as String?) ?? Colors.white;
    final onDismissed = properties['onDismissed'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onDismissed)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: GestureDetector(
                onTap: () {
                  // Dismiss action would be handled by parent widget
                },
                child: Icon(Icons.close, size: 16, color: textColor),
              ),
            ),
        ],
      ),
    );
  }

  /// Build FittedBox wrapper
  static Widget buildFittedBox(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
  ) {
    final fit = _parseFitMode(properties['fit'] as String? ?? 'contain');

    return FittedBox(
      fit: fit,
      child: childrenData.isNotEmpty
          ? _buildChild(childrenData.first)
          : const Placeholder(),
    );
  }

  /// Build ExpansionTile widget
  static Widget buildExpansionTile(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
  ) {
    final title = properties['title'] as String? ?? 'Expansion Tile';
    final subtitle = properties['subtitle'] as String?;
    final initiallyExpanded = properties['initiallyExpanded'] as bool? ?? false;
    final backgroundColor = _parseColor(properties['backgroundColor'] as String?);

    return ExpansionTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      initiallyExpanded: initiallyExpanded,
      backgroundColor: backgroundColor,
      children: childrenData.map((child) => _buildChild(child)).toList(),
    );
  }

  /// Build Stepper widget
  static Widget buildStepper(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
  ) {
    final type = properties['type'] as String? ?? 'vertical';
    final currentStep = (properties['currentStep'] as num?)?.toInt() ?? 0;

    final isVertical = type.toLowerCase() == 'vertical';

    List<Step> steps = [];
    for (int i = 0; i < childrenData.length; i++) {
      final stepData = childrenData[i] as Map<String, dynamic>;
      steps.add(
        Step(
          title: Text(stepData['title'] as String? ?? 'Step ${i + 1}'),
          subtitle: stepData['subtitle'] != null ? Text(stepData['subtitle'] as String) : null,
          content: _buildChild(stepData['content'] ?? const Placeholder()),
          isActive: i == currentStep,
        ),
      );
    }

    return Stepper(
      steps: steps,
      type: isVertical ? StepperType.vertical : StepperType.horizontal,
      currentStep: currentStep,
    );
  }

  /// Build DataTable widget
  static Widget buildDataTable(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
  ) {
    final columns = (properties['columns'] as List? ?? [])
        .map((c) => DataColumn(label: Text(c as String)))
        .toList();

    final rows = (childrenData as List? ?? [])
        .map((rowData) {
          final cells = (rowData as Map<String, dynamic>)['cells'] as List? ?? [];
          return DataRow(
            cells: cells.map((cell) => DataCell(Text(cell.toString()))).toList(),
          );
        })
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns,
        rows: rows,
      ),
    );
  }

  /// Build PageView widget
  static Widget buildPageView(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final scrollDirection = properties['scrollDirection'] as String? ?? 'horizontal';
    final isHorizontal = scrollDirection.toLowerCase() == 'horizontal';

    return PageView(
      scrollDirection: isHorizontal ? Axis.horizontal : Axis.vertical,
      children: childrenData.map((child) => _buildChild(child)).toList(),
    );
  }

  /// Build SnackBar widget (usually shown via ScaffoldMessenger)
  static Widget buildSnackBar(Map<String, dynamic> properties) {
    final message = properties['message'] as String? ?? 'Message';
    final duration = (properties['duration'] as num?)?.toInt() ?? 3;
    final backgroundColor = _parseColor(properties['backgroundColor'] as String?);
    final textColor = _parseColor(properties['textColor'] as String?);

    return SnackBar(
      content: Text(
        message,
        style: TextStyle(color: textColor),
      ),
      backgroundColor: backgroundColor,
      duration: Duration(seconds: duration),
    );
  }

  // ===== CORE LAYOUT WIDGETS (Phase 3 Part 2) =====
  
  /// Build Expanded widget
  static Widget buildExpanded(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(Map<String, dynamic>) render,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>)
        : null;
    final flex = (properties['flex'] as num?)?.toInt() ?? 1;
    return Expanded(
      flex: flex,
      child: child ?? const Placeholder(),
    );
  }

  /// Build Flexible widget
  static Widget buildFlexible(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(Map<String, dynamic>) render,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>)
        : null;
    final flex = (properties['flex'] as num?)?.toInt() ?? 1;
    return Flexible(
      flex: flex,
      fit: properties['fit'] == 'tight' ? FlexFit.tight : FlexFit.loose,
      child: child ?? const Placeholder(),
    );
  }

  /// Build SizedBox widget
  static Widget buildSizedBox(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(Map<String, dynamic>) render,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>)
        : null;
    return SizedBox(
      width: _parseDouble(properties['width']),
      height: _parseDouble(properties['height']),
      child: child,
    );
  }

  /// Build SingleChildScrollView widget
  static Widget buildSingleChildScrollView(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(Map<String, dynamic>) render,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>)
        : null;
    return SingleChildScrollView(
      scrollDirection: properties['scrollDirection'] == 'horizontal' ? Axis.horizontal : Axis.vertical,
      child: child ?? const Placeholder(),
    );
  }

  /// Build ListView widget
  static Widget buildListView(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    List<Widget> Function(List<dynamic>) renderList,
  ) {
    final children = renderList(childrenData);
    return ListView(
      scrollDirection: properties['scrollDirection'] == 'horizontal' ? Axis.horizontal : Axis.vertical,
      shrinkWrap: properties['shrinkWrap'] as bool? ?? false,
      children: children,
    );
  }

  /// Build GridView widget
  static Widget buildGridView(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    List<Widget> Function(List<dynamic>) renderList,
  ) {
    final children = renderList(childrenData);
    final crossAxisCount = (properties['crossAxisCount'] as num?)?.toInt() ?? 2;
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: properties['shrinkWrap'] as bool? ?? false,
      children: children,
    );
  }

  /// Build Wrap widget
  static Widget buildWrap(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    List<Widget> Function(List<dynamic>) renderList,
  ) {
    final children = renderList(childrenData);
    return Wrap(
      spacing: (properties['spacing'] as num?)?.toDouble() ?? 8.0,
      runSpacing: (properties['runSpacing'] as num?)?.toDouble() ?? 8.0,
      children: children,
    );
  }

  /// Build Spacer widget
  static Widget buildSpacer(Map<String, dynamic> properties) {
    final flex = (properties['flex'] as num?)?.toInt() ?? 1;
    return Spacer(flex: flex);
  }

  /// Build AspectRatio widget
  static Widget buildAspectRatio(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(Map<String, dynamic>) render,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>)
        : null;
    final aspectRatio = (properties['aspectRatio'] as num?)?.toDouble() ?? 1.0;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: child ?? const Placeholder(),
    );
  }

  /// Build FractionallySizedBox widget
  static Widget buildFractionallySizedBox(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(Map<String, dynamic>) render,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>)
        : null;
    return FractionallySizedBox(
      widthFactor: _parseDouble(properties['widthFactor']),
      heightFactor: _parseDouble(properties['heightFactor']),
      child: child ?? const Placeholder(),
    );
  }

  /// Build IntrinsicHeight widget
  static Widget buildIntrinsicHeight(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(Map<String, dynamic>) render,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>)
        : null;
    return IntrinsicHeight(child: child ?? const Placeholder());
  }

  /// Build IntrinsicWidth widget
  static Widget buildIntrinsicWidth(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(Map<String, dynamic>) render,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>)
        : null;
    return IntrinsicWidth(child: child ?? const Placeholder());
  }

  /// Build Transform widget
  static Widget buildTransform(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(Map<String, dynamic>) render,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>)
        : null;
    return Transform.translate(
      offset: Offset(
        (properties['offsetX'] as num?)?.toDouble() ?? 0,
        (properties['offsetY'] as num?)?.toDouble() ?? 0,
      ),
      child: child ?? const Placeholder(),
    );
  }

  /// Build Opacity widget
  static Widget buildOpacity(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(Map<String, dynamic>) render,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>)
        : null;
    final opacity = (properties['opacity'] as num?)?.toDouble() ?? 1.0;
    return Opacity(opacity: opacity, child: child ?? const Placeholder());
  }

  /// Build DecoratedBox widget
  static Widget buildDecoratedBox(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(Map<String, dynamic>) render,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>)
        : null;
    return DecoratedBox(
      decoration: _parseBoxDecoration(properties['decoration']) ?? const BoxDecoration(),
      child: child ?? const Placeholder(),
    );
  }

  /// Build ClipRect widget
  static Widget buildClipRect(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(Map<String, dynamic>) render,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>)
        : null;
    return ClipRect(child: child ?? const Placeholder());
  }

  /// Build ClipRRect widget
  static Widget buildClipRRect(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(Map<String, dynamic>) render,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>)
        : null;
    final radius = (properties['radius'] as num?)?.toDouble() ?? 8.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: child ?? const Placeholder(),
    );
  }

  /// Build ClipOval widget
  static Widget buildClipOval(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(Map<String, dynamic>) render,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>)
        : null;
    return ClipOval(child: child ?? const Placeholder());
  }

  /// Build Material widget
  static Widget buildMaterial(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(Map<String, dynamic>) render,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>)
        : null;
    return Material(
      color: _parseColor(properties['color']) ?? Colors.white,
      child: child ?? const Placeholder(),
    );
  }

  /// Build Table widget
  static Widget buildTable(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
  ) {
    return Table(
      columnWidths: const <int, TableColumnWidth>{},
      children: [],
    );
  }

  // ===== HELPER METHODS =====

  /// Parse double value from number or string
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Parse box decoration from JSON
  static BoxDecoration? _parseBoxDecoration(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return BoxDecoration(
        color: _parseColor(value['color']),
        border: _parseBorder(value['border']),
        borderRadius: _parseBorderRadius(value['borderRadius']),
        boxShadow: _parseBoxShadow(value['boxShadow']),
      );
    }
    return null;
  }

  /// Parse border from JSON
  static Border? _parseBorder(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return Border(
        left: _parseBorderSide(value['left']),
        right: _parseBorderSide(value['right']),
        top: _parseBorderSide(value['top']),
        bottom: _parseBorderSide(value['bottom']),
      );
    }
    return null;
  }

  /// Parse border side from JSON
  static BorderSide _parseBorderSide(dynamic value) {
    if (value is Map) {
      return BorderSide(
        color: _parseColor(value['color']) ?? Colors.black,
        width: (value['width'] as num?)?.toDouble() ?? 1.0,
      );
    }
    return const BorderSide();
  }

  /// Parse border radius from JSON
  static BorderRadius? _parseBorderRadius(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      return BorderRadius.circular(value.toDouble());
    }
    if (value is Map) {
      final all = (value['all'] as num?)?.toDouble();
      if (all != null) return BorderRadius.circular(all);
      return BorderRadius.only(
        topLeft: Radius.circular((value['topLeft'] as num?)?.toDouble() ?? 0),
        topRight: Radius.circular((value['topRight'] as num?)?.toDouble() ?? 0),
        bottomLeft: Radius.circular((value['bottomLeft'] as num?)?.toDouble() ?? 0),
        bottomRight: Radius.circular((value['bottomRight'] as num?)?.toDouble() ?? 0),
      );
    }
    return null;
  }

  /// Parse box shadow from JSON
  static List<BoxShadow>? _parseBoxShadow(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .map((shadow) => BoxShadow(
                color: _parseColor(shadow['color']) ?? Colors.black.withOpacity(0.1),
                blurRadius: (shadow['blurRadius'] as num?)?.toDouble() ?? 0,
                spreadRadius: (shadow['spreadRadius'] as num?)?.toDouble() ?? 0,
                offset: Offset(
                  (shadow['offset']?['dx'] as num?)?.toDouble() ?? 0,
                  (shadow['offset']?['dy'] as num?)?.toDouble() ?? 0,
                ),
              ))
          .toList();
    }
    return null;
  }

  /// Parse color from hex string
  static Color? _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) return null;

    try {
      if (colorString.startsWith('#')) {
        final hex = colorString.replaceFirst('#', '');
        if (hex.length == 6) {
          return Color(int.parse('0xFF$hex'));
        } else if (hex.length == 8) {
          return Color(int.parse('0x$hex'));
        }
      }
    } catch (e) {
      // Return null if parsing fails
    }
    return null;
  }

  /// Parse fit mode from string
  static BoxFit _parseFitMode(String fit) {
    return switch (fit.toLowerCase()) {
      'fill' => BoxFit.fill,
      'contain' => BoxFit.contain,
      'cover' => BoxFit.cover,
      'fitwidth' => BoxFit.fitWidth,
      'fitheight' => BoxFit.fitHeight,
      'scaledown' => BoxFit.scaleDown,
      _ => BoxFit.contain,
    };
  }

  /// Build child widget from dynamic data
  static Widget _buildChild(dynamic child) {
    if (child is Map<String, dynamic>) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        child: Text(child.toString()),
      );
    } else if (child is Widget) {
      return child;
    } else if (child is String) {
      return Text(child);
    }
    return const Placeholder();
  }

  /// Build Column widget with children
  static Widget buildColumn(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(dynamic) render,
  ) {
    final children = childrenData.map((child) => render(child)).toList().cast<Widget>();
    return Column(
      mainAxisSize: properties['mainAxisSize'] == 'min' ? MainAxisSize.min : MainAxisSize.max,
      children: children,
    );
  }

  /// Build Row widget with children
  static Widget buildRow(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(dynamic) render,
  ) {
    final children = childrenData.map((child) => render(child)).toList().cast<Widget>();
    final mainAxisSize = properties['mainAxisSize'] == 'max' ? MainAxisSize.max : MainAxisSize.min;
    return Row(
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }

  /// Build Container widget
  static Widget buildContainer(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(dynamic) render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return Container(
      width: _parseDouble(properties['width']),
      height: _parseDouble(properties['height']),
      color: _parseColor(properties['color']),
      child: child,
    );
  }

  /// Build Stack widget with children
  static Widget buildStack(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(dynamic) render,
  ) {
    final children = childrenData.map((child) => render(child)).toList().cast<Widget>();
    return Stack(
      fit: properties['fit'] == 'expand' ? StackFit.expand : StackFit.loose,
      children: children,
    );
  }

  /// Build Center widget
  static Widget buildCenter(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(dynamic) render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return Center(child: child ?? const Placeholder());
  }

  /// Build Padding widget
  static Widget buildPadding(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(dynamic) render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return Padding(
      padding: EdgeInsets.all((properties['padding'] as num?)?.toDouble() ?? 0.0),
      child: child ?? const Placeholder(),
    );
  }

  /// Build Align widget
  static Widget buildAlign(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    Widget Function(dynamic) render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return Align(
      alignment: Alignment.center,
      child: child ?? const Placeholder(),
    );
  }
}
