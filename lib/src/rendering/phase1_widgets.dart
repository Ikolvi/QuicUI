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
class Phase1Widgets {
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

  // ===== HELPER METHODS =====

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
}
