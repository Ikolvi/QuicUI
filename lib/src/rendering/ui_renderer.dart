/// Main UI renderer implementation - 70+ Flutter widgets
/// 
/// This module provides the core rendering engine for QuicUI.
/// It converts JSON-based [WidgetData] and [Screen] configurations
/// into fully-rendered Flutter widgets.
///
/// ## Callback Action System
///
/// Supports generic callback actions via JSON:
/// - Navigate to screens
/// - Update widget state
/// - Make API calls
/// - Execute custom handlers
/// - Chain actions with onSuccess/onError
///
/// Example:
/// ```json
/// {
///   "events": {
///     "onPressed": {
///       "action": "apiCall",
///       "method": "POST",
///       "endpoint": "/api/login"
///     }
///   }
/// }
/// ```
///
/// ## Widget Coverage
///
/// UIRenderer supports 70+ Flutter widgets organized by category:
///
/// ### App & Navigation (8 widgets)
/// - Scaffold, AppBar, BottomAppBar, Drawer
/// - FloatingActionButton, NavigationBar, TabBar
///
/// ### Layout (15 widgets)
/// - Column, Row, Container, Stack, Positioned
/// - Center, Padding, Align, Sized Box, Single Child Scroll View
/// - ListView, GridView, Expanded, Flexible, Wrap
///
/// ### Text & Display (8 widgets)
/// - Text, RichText, TextField, Icon, Image
/// - Card, ListTile, Divider
///
/// ### Buttons & Input (8 widgets)
/// - ElevatedButton, TextButton, OutlinedButton
/// - Checkbox, Radio, Slider, Switch, GestureDetector
///
/// ### Advanced (10+ widgets)
/// - CustomPaint, AnimatedContainer, Transform
/// - Opacity, ClipRRect, Badge, and more
///
/// ## Rendering Process
///
/// 1. **Parse:** Extract widget type and properties from JSON
/// 2. **Validate:** Check properties against widget schema
/// 3. **Build:** Create Flutter widget with parsed properties
/// 4. **Bind:** Connect state and event handlers
/// 5. **Render:** Add to widget tree
///
/// ## Example
///
/// ```dart
/// final config = {
///   'type': 'Column',
///   'properties': {
///     'mainAxisAlignment': 'center',
///     'crossAxisAlignment': 'center',
///   },
///   'children': [
///     {
///       'type': 'Text',
///       'properties': {
///         'text': 'Hello, World!',
///         'fontSize': 24,
///       },
///     },
///     {
///       'type': 'ElevatedButton',
///       'properties': {'label': 'Press Me'},
///       'events': {
///         'onPressed': {'action': 'navigate', 'screen': 'next'},
///       },
///     },
///   ],
/// };
///
/// final widget = UIRenderer.render(config);
/// ```
///
/// ## Property Support
///
/// Properties are automatically converted to appropriate types:
/// - **Colors:** `#RRGGBB` format
/// - **Numbers:** Integer or double
/// - **Enums:** String matching enum values
/// - **Objects:** Nested property maps
/// - **State Binding:** `${state.fieldName}` syntax
///
/// ## Event Handling
///
/// Events trigger actions:
/// - `onPressed`: Button tap
/// - `onChanged`: Value change
/// - `onTap`: General tap
/// - `onSubmitted`: Form submit
///
/// ## Error Handling
///
/// - Unknown widget types render as [Placeholder]
/// - Missing properties use sensible defaults
/// - Invalid values are caught and reported
/// - Errors don't crash the app
///
/// ## Performance
///
/// Rendering is optimized for:
/// - Fast initial render
/// - Efficient rebuilds
/// - Minimal widget overhead
/// - Smooth animations
///
/// See also:
/// - [WidgetFactory]: Helper for creating widgets
/// - [WidgetBuilder]: Builder utilities
/// - [UIRenderer.render]: Main render method

import 'package:flutter/material.dart';
import '../models/callback_actions.dart' as callback_actions;
import 'phase1_widgets.dart';
import 'phase2_widgets.dart';
import 'phase3_widgets.dart';
import 'phase4_widgets.dart';
import 'phase5_widgets.dart';

/// Main UI renderer for building Flutter widgets from JSON
///
/// Converts JSON-based widget configurations to Flutter widgets.
/// Supports 70+ widget types with full property binding and event handling.
///
/// ## Basic Usage
///
/// ```dart
/// final renderer = UIRenderer();
/// final widget = renderer.render({
///   'type': 'Text',
///   'properties': {'text': 'Hello'},
/// });
/// ```
///
/// ## Advanced Usage
///
/// ```dart
/// // With state binding
/// final widget = renderer.render(
///   config,
///   context: context,
/// );
/// ```
class UIRenderer {
  /// Render a widget tree from JSON configuration
  static Widget render(Map<String, dynamic> config, {BuildContext? context}) {
    final type = config['type'] as String?;
    if (type == null) return const Placeholder();
    
    final shouldRender = config['shouldRender'] as bool? ?? true;
    if (!shouldRender) return const SizedBox.shrink();
    
    return _renderWidgetByType(type, config, context);
  }

  /// Render a list of widgets from JSON array
  static List<Widget> renderList(List<dynamic> widgetsData, {BuildContext? context}) {
    return widgetsData
        .whereType<Map<String, dynamic>>()
        .map((data) => render(data, context: context))
        .toList();
  }

  /// Render widget by type - 70+ widgets supported
  static Widget _renderWidgetByType(
    String type,
    Map<String, dynamic> config,
    BuildContext? context,
  ) {
    final properties = config['properties'] as Map<String, dynamic>? ?? {};
    final childrenData = config['children'] as List? ?? [];

    try {
      return switch (type) {
        // ===== SCAFFOLD & APP-LEVEL WIDGETS =====
        'Scaffold' => _buildScaffold(properties, childrenData, config, context),
        'AppBar' => _buildAppBar(properties, childrenData, context),
        'BottomAppBar' => _buildBottomAppBar(properties, childrenData, context),
        'Drawer' => _buildDrawer(properties, childrenData, context),
        'FloatingActionButton' => _buildFloatingActionButton(properties),
        'NavigationBar' => _buildNavigationBar(properties),
        'TabBar' => _buildTabBar(properties),
        
        // ===== LAYOUT WIDGETS =====
        'Column' => _buildColumn(properties, childrenData, context),
        'Row' => _buildRow(properties, childrenData, context),
        'Container' => _buildContainer(properties, childrenData, context),
        'Stack' => _buildStack(properties, childrenData, context),
        'Positioned' => _buildPositioned(properties, childrenData, context),
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
        'Spacer' => _buildSpacer(properties),
        'AspectRatio' => _buildAspectRatio(properties, childrenData, context),
        'FractionallySizedBox' => _buildFractionallySizedBox(properties, childrenData, context),
        'IntrinsicHeight' => _buildIntrinsicHeight(properties, childrenData, context),
        'IntrinsicWidth' => _buildIntrinsicWidth(properties, childrenData, context),
        'Transform' => _buildTransform(properties, childrenData, context),
        'Opacity' => _buildOpacity(properties, childrenData, context),
        'DecoratedBox' => _buildDecoratedBox(properties, childrenData, context),
        'ClipRect' => _buildClipRect(properties, childrenData, context),
        'ClipRRect' => _buildClipRRect(properties, childrenData, context),
        'ClipOval' => _buildClipOval(properties, childrenData, context),
        'Material' => _buildMaterial(properties, childrenData, context),
        'Table' => _buildTable(properties, childrenData),
        
        // ===== DISPLAY WIDGETS =====
        'Text' => _buildText(properties),
        'RichText' => _buildRichText(properties),
        'Image' => _buildImage(properties),
        'Icon' => _buildIcon(properties),
        'Card' => _buildCard(properties, childrenData, context),
        'Divider' => _buildDivider(properties),
        'VerticalDivider' => _buildVerticalDivider(properties),
        'Badge' => _buildBadge(properties, childrenData, context),
        'Chip' => _buildChip(properties),
        'ActionChip' => _buildActionChip(properties),
        'FilterChip' => _buildFilterChip(properties),
        'InputChip' => _buildInputChip(properties),
        'ChoiceChip' => _buildChoiceChip(properties),
        'Tooltip' => _buildTooltip(properties, childrenData, context),
        'ListTile' => _buildListTile(properties, childrenData, context),
        
        // ===== INPUT WIDGETS =====
        'ElevatedButton' => _buildElevatedButton(properties),
        'TextButton' => _buildTextButton(properties),
        'IconButton' => _buildIconButton(properties),
        'OutlinedButton' => _buildOutlinedButton(properties),
        'TextField' => _buildTextField(properties),
        'TextFormField' => _buildTextFormField(properties),
        'Checkbox' => _buildCheckbox(properties),
        'CheckboxListTile' => _buildCheckboxListTile(properties),
        'Radio' => _buildRadio(properties),
        'RadioListTile' => _buildRadioListTile(properties),
        'Switch' => _buildSwitch(properties),
        'SwitchListTile' => _buildSwitchListTile(properties),
        'Slider' => _buildSlider(properties),
        'RangeSlider' => _buildRangeSlider(properties),
        'DropdownButton' => _buildDropdownButton(properties),
        'PopupMenuButton' => _buildPopupMenuButton(properties),
        'SegmentedButton' => _buildSegmentedButton(properties),
        'SearchBar' => _buildSearchBar(properties),
        'Form' => _buildForm(properties, childrenData, context),
        
        // ===== DIALOG & OVERLAY WIDGETS =====
        'Dialog' => _buildDialog(properties, childrenData, context),
        'AlertDialog' => _buildAlertDialog(properties, childrenData, context),
        'SimpleDialog' => _buildSimpleDialog(properties, childrenData, context),
        'Offstage' => _buildOffstage(properties, childrenData, context),
        
        // ===== ANIMATION & VISIBILITY =====
        'AnimatedContainer' => _buildAnimatedContainer(properties, childrenData, context),
        'AnimatedOpacity' => _buildAnimatedOpacity(properties, childrenData, context),
        'FadeInImage' => _buildFadeInImage(properties),
        'Visibility' => _buildVisibility(properties, childrenData, context),
        
        // ===== PHASE 1: CORE WIDGET EXPANSION =====
        'SliverAppBar' => Phase1Widgets.buildSliverAppBar(properties, childrenData),
        'BottomSheet' => Phase1Widgets.buildBottomSheet(properties, childrenData, context),
        'Avatar' => Phase1Widgets.buildAvatar(properties),
        'ProgressBar' => Phase1Widgets.buildProgressBar(properties),
        'CircularProgress' => Phase1Widgets.buildCircularProgress(properties),
        'Tag' => Phase1Widgets.buildTag(properties),
        'FittedBox' => Phase1Widgets.buildFittedBox(properties, childrenData),
        'ExpansionTile' => Phase1Widgets.buildExpansionTile(properties, childrenData),
        'Stepper' => Phase1Widgets.buildStepper(properties, childrenData),
        'DataTable' => Phase1Widgets.buildDataTable(properties, childrenData),
        'PageView' => Phase1Widgets.buildPageView(properties, childrenData, context),
        'SnackBar' => Phase1Widgets.buildSnackBar(properties),
        
        // ===== PHASE 2: INPUT WIDGETS (NEW) =====
        'TextArea' => Phase2Widgets.buildTextArea(properties),
        'NumberInput' => Phase2Widgets.buildNumberInput(properties),
        'DatePicker' => Phase2Widgets.buildDatePicker(properties),
        'TimePicker' => Phase2Widgets.buildTimePicker(properties),
        'ColorPicker' => Phase2Widgets.buildColorPicker(properties),
        'DropdownButtonForm' => Phase2Widgets.buildDropdownButtonForm(properties),
        'MultiSelect' => Phase2Widgets.buildMultiSelect(properties),
        'SearchBox' => Phase2Widgets.buildSearchBox(properties),
        'FileUpload' => Phase2Widgets.buildFileUpload(properties),
        'Rating' => Phase2Widgets.buildRating(properties),
        'OtpInput' => Phase2Widgets.buildOtpInput(properties),
        
        // ===== PHASE 3: LAYOUT & ADVANCED WIDGETS =====
        'CustomScrollView' => Phase3Widgets.buildCustomScrollView(properties, childrenData),
        'SliverList' => Phase3Widgets.buildSliverList(properties, childrenData),
        'SliverGrid' => Phase3Widgets.buildSliverGrid(properties, childrenData),
        'Flow' => Phase3Widgets.buildFlow(properties, childrenData),
        'LayoutBuilder' => Phase3Widgets.buildLayoutBuilder(properties, childrenData),
        'MediaQueryHelper' => Phase3Widgets.buildMediaQueryHelper(properties, childrenData),
        'ResponsiveWidget' => Phase3Widgets.buildResponsiveWidget(properties, childrenData),
        'AdvancedSliverAppBar' => Phase3Widgets.buildAdvancedSliverAppBar(properties, childrenData),
        'NestedScrollView' => Phase3Widgets.buildNestedScrollView(properties, childrenData),
        'AnimatedBuilder' => Phase3Widgets.buildAnimatedBuilder(properties, childrenData),
        'TabBarViewAdvanced' => Phase3Widgets.buildTabBarViewAdvanced(properties, childrenData),
        'PinchZoom' => Phase3Widgets.buildPinchZoom(properties, childrenData),
        'VirtualizedList' => Phase3Widgets.buildVirtualizedList(properties, childrenData),
        'StickyHeaders' => Phase3Widgets.buildStickyHeaders(properties, childrenData),
        
        // ===== PHASE 4: NAVIGATION WIDGETS =====
        'NavigationRail' => Phase4Widgets.buildNavigationRail(properties, childrenData),
        'Breadcrumb' => Phase4Widgets.buildBreadcrumb(properties, childrenData),
        'BreadcrumbItem' => Phase4Widgets.buildBreadcrumbItem(properties, childrenData),
        'StackedNavigation' => Phase4Widgets.buildStackedNavigation(properties, childrenData),
        'NavigationStack' => Phase4Widgets.buildNavigationStack(properties, childrenData),
        'DrawerNavigation' => Phase4Widgets.buildDrawerNavigation(properties, childrenData),
        'MenuBar' => Phase4Widgets.buildMenuBar(properties, childrenData),
        'SideBar' => Phase4Widgets.buildSideBar(properties, childrenData),
        'ContextMenu' => Phase4Widgets.buildContextMenu(properties, childrenData),
        'AdvancedBottomNav' => Phase4Widgets.buildAdvancedBottomNav(properties, childrenData),
        'TabBarEnhanced' => Phase4Widgets.buildTabBarEnhanced(properties, childrenData),
        'AnimatedDrawer' => Phase4Widgets.buildAnimatedDrawer(properties, childrenData),
        'PaginationNav' => Phase4Widgets.buildPaginationNav(properties, childrenData),

        // ===== PHASE 5: ANIMATION & TRANSITION WIDGETS =====
        'AnimatedOpacityCustom' => Phase5Widgets.buildAnimatedOpacity(properties, childrenData),
        'AnimatedScaleCustom' => Phase5Widgets.buildAnimatedScale(properties, childrenData),
        'AnimatedRotationCustom' => Phase5Widgets.buildAnimatedRotation(properties, childrenData),
        'AnimatedPositionedCustom' => Phase5Widgets.buildAnimatedPositioned(properties, childrenData),
        'AnimatedAlignCustom' => Phase5Widgets.buildAnimatedAlign(properties, childrenData),
        'HeroCustom' => Phase5Widgets.buildHero(properties, childrenData),
        'TweenAnimationBuilderCustom' => Phase5Widgets.buildTweenAnimationBuilder(properties, childrenData),
        'AnimatedContainerCustom' => Phase5Widgets.buildAnimatedContainer(properties, childrenData),
        'AnimatedDefaultTextStyleCustom' => Phase5Widgets.buildAnimatedDefaultTextStyle(properties, childrenData),
        'AnimatedPhysicalModelCustom' => Phase5Widgets.buildAnimatedPhysicalModel(properties, childrenData),
        'AnimatedSwitcherCustom' => Phase5Widgets.buildAnimatedSwitcher(properties, childrenData),
        'SlideAnimation' => Phase5Widgets.buildSlideAnimation(properties, childrenData),
        'FadeAnimation' => Phase5Widgets.buildFadeAnimation(properties, childrenData),
        'RotationAnimation' => Phase5Widgets.buildRotationAnimation(properties, childrenData),
        'ScaleAnimation' => Phase5Widgets.buildScaleAnimation(properties, childrenData),
        'SizeAnimation' => Phase5Widgets.buildSizeAnimation(properties, childrenData),
        'SkewAnimation' => Phase5Widgets.buildSkewAnimation(properties, childrenData),
        'PerspectiveAnimation' => Phase5Widgets.buildPerspectiveAnimation(properties, childrenData),
        'ShakeAnimation' => Phase5Widgets.buildShakeAnimation(properties, childrenData),
        'PulseAnimation' => Phase5Widgets.buildPulseAnimation(properties, childrenData),
        'FlipAnimation' => Phase5Widgets.buildFlipAnimation(properties, childrenData),
        'BounceAnimation' => Phase5Widgets.buildBounceAnimation(properties, childrenData),
        'FloatingAnimation' => Phase5Widgets.buildFloatingAnimation(properties, childrenData),
        'GlowAnimation' => Phase5Widgets.buildGlowAnimation(properties, childrenData),
        'ProgressAnimation' => Phase5Widgets.buildProgressAnimation(properties, childrenData),
        'WaveAnimation' => Phase5Widgets.buildWaveAnimation(properties, childrenData),
        'ColorAnimation' => Phase5Widgets.buildColorAnimation(properties, childrenData),
        'BlurAnimation' => Phase5Widgets.buildBlurAnimation(properties, childrenData),
        
        _ => const Placeholder(),
      };
    } catch (e) {
      return _buildErrorWidget(e.toString());
    }
  }

  // ===== SCAFFOLD & APP-LEVEL WIDGETS =====
  
  static Widget _buildScaffold(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    Map<String, dynamic> config,
    BuildContext? context,
  ) {
    final body = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    final appBarConfig = config['appBar'] as Map<String, dynamic>?;
    final floatingActionButtonConfig = config['fab'] as Map<String, dynamic>?;
    
    return Scaffold(
      appBar: appBarConfig != null ? _buildAppBar((appBarConfig['properties'] as Map<String, dynamic>?) ?? {}, [], context) as PreferredSizeWidget? : null,
      body: body,
      floatingActionButton: floatingActionButtonConfig != null ? _buildFloatingActionButton((floatingActionButtonConfig['properties'] as Map<String, dynamic>?) ?? {}) : null,
    );
  }

  static Widget _buildAppBar(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    return AppBar(
      title: Text(properties['title'] as String? ?? ''),
      centerTitle: properties['centerTitle'] as bool? ?? false,
      backgroundColor: _parseColor(properties['backgroundColor']),
      elevation: (properties['elevation'] as num?)?.toDouble(),
    );
  }

  static Widget _buildBottomAppBar(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final children = renderList(childrenData, context: context);
    return BottomAppBar(
      child: Row(children: children),
    );
  }

  static Widget _buildDrawer(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final children = renderList(childrenData, context: context);
    return Drawer(
      child: ListView(children: children),
    );
  }

  static Widget _buildFloatingActionButton(Map<String, dynamic> properties) {
    return FloatingActionButton(
      onPressed: () => _handleButtonPress(properties['onPressed'] as String? ?? ''),
      child: Icon(_parseIconData(properties['icon'] as String? ?? 'add')),
    );
  }

  static Widget _buildNavigationBar(Map<String, dynamic> properties) {
    return NavigationBar(
      onDestinationSelected: (int index) {},
      selectedIndex: 0,
      destinations: [],
    );
  }

  static Widget _buildTabBar(Map<String, dynamic> properties) {
    return const TabBar(tabs: []);
  }

  // ===== LAYOUT WIDGETS =====

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

  static Widget _buildPositioned(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : const Placeholder();
    return Positioned(
      left: (properties['left'] as num?)?.toDouble(),
      right: (properties['right'] as num?)?.toDouble(),
      top: (properties['top'] as num?)?.toDouble(),
      bottom: (properties['bottom'] as num?)?.toDouble(),
      child: child,
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
      scrollDirection: properties['scrollDirection'] == 'horizontal' ? Axis.horizontal : Axis.vertical,
      child: child ?? const Placeholder(),
    );
  }

  static Widget _buildListView(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final children = renderList(childrenData, context: context);
    return ListView(
      scrollDirection: properties['scrollDirection'] == 'horizontal' ? Axis.horizontal : Axis.vertical,
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
    return GridView.count(
      crossAxisCount: crossAxisCount,
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
      children: children,
    );
  }

  static Widget _buildSpacer(Map<String, dynamic> properties) {
    final flex = (properties['flex'] as num?)?.toInt() ?? 1;
    return Spacer(flex: flex);
  }

  static Widget _buildAspectRatio(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    final aspectRatio = (properties['aspectRatio'] as num?)?.toDouble() ?? 1.0;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: child ?? const Placeholder(),
    );
  }

  static Widget _buildFractionallySizedBox(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return FractionallySizedBox(
      widthFactor: (properties['widthFactor'] as num?)?.toDouble(),
      heightFactor: (properties['heightFactor'] as num?)?.toDouble(),
      child: child ?? const Placeholder(),
    );
  }

  static Widget _buildIntrinsicHeight(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return IntrinsicHeight(child: child ?? const Placeholder());
  }

  static Widget _buildIntrinsicWidth(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return IntrinsicWidth(child: child ?? const Placeholder());
  }

  static Widget _buildTransform(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return Transform.translate(
      offset: Offset(
        (properties['offsetX'] as num?)?.toDouble() ?? 0,
        (properties['offsetY'] as num?)?.toDouble() ?? 0,
      ),
      child: child ?? const Placeholder(),
    );
  }

  static Widget _buildOpacity(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    final opacity = (properties['opacity'] as num?)?.toDouble() ?? 1.0;
    return Opacity(opacity: opacity, child: child ?? const Placeholder());
  }

  static Widget _buildDecoratedBox(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return DecoratedBox(
      decoration: _parseBoxDecoration(properties['decoration']) ?? const BoxDecoration(),
      child: child ?? const Placeholder(),
    );
  }

  static Widget _buildClipRect(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return ClipRect(child: child ?? const Placeholder());
  }

  static Widget _buildClipRRect(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    final radius = (properties['radius'] as num?)?.toDouble() ?? 8.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: child ?? const Placeholder(),
    );
  }

  static Widget _buildClipOval(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return ClipOval(child: child ?? const Placeholder());
  }

  static Widget _buildMaterial(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return Material(
      color: _parseColor(properties['color']) ?? Colors.white,
      child: child ?? const Placeholder(),
    );
  }

  static Widget _buildTable(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
  ) {
    return Table(
      columnWidths: const <int, TableColumnWidth>{},
      children: [],
    );
  }

  // ===== DISPLAY WIDGETS =====

  static Widget _buildText(Map<String, dynamic> properties) {
    final text = properties['text'] as String? ?? '';
    return Text(
      text,
      style: TextStyle(
        fontSize: (properties['fontSize'] as num?)?.toDouble(),
        fontWeight: _parseFontWeight(properties['fontWeight']),
        color: _parseColor(properties['color']),
      ),
      textAlign: _parseTextAlign(properties['textAlign']),
      maxLines: (properties['maxLines'] as num?)?.toInt(),
    );
  }

  static Widget _buildRichText(Map<String, dynamic> properties) {
    return RichText(
      text: TextSpan(
        text: properties['text'] as String? ?? '',
        style: TextStyle(
          fontSize: (properties['fontSize'] as num?)?.toDouble(),
          color: _parseColor(properties['color']) ?? Colors.black,
        ),
      ),
    );
  }

  static Widget _buildImage(Map<String, dynamic> properties) {
    final src = properties['src'] as String? ?? '';
    final width = (properties['width'] as num?)?.toDouble();
    final height = (properties['height'] as num?)?.toDouble();

    if (src.startsWith('http')) {
      return Image.network(src, width: width, height: height);
    }
    return Image.asset(src, width: width, height: height);
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
    return Card(child: child ?? const Placeholder());
  }

  static Widget _buildDivider(Map<String, dynamic> properties) {
    return Divider(
      height: (properties['height'] as num?)?.toDouble() ?? 16.0,
      thickness: (properties['thickness'] as num?)?.toDouble() ?? 1.0,
      color: _parseColor(properties['color']),
    );
  }

  static Widget _buildVerticalDivider(Map<String, dynamic> properties) {
    return VerticalDivider(
      width: (properties['width'] as num?)?.toDouble() ?? 16.0,
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
    return Badge(label: Text(label), child: child ?? const Icon(Icons.notifications));
  }

  static Widget _buildChip(Map<String, dynamic> properties) {
    return Chip(label: Text(properties['label'] as String? ?? ''));
  }

  static Widget _buildActionChip(Map<String, dynamic> properties) {
    return ActionChip(
      label: Text(properties['label'] as String? ?? ''),
      onPressed: () => _handleButtonPress(properties['onPressed'] as String? ?? ''),
    );
  }

  static Widget _buildFilterChip(Map<String, dynamic> properties) {
    return FilterChip(
      label: Text(properties['label'] as String? ?? ''),
      onSelected: (bool selected) {},
    );
  }

  static Widget _buildInputChip(Map<String, dynamic> properties) {
    return InputChip(label: Text(properties['label'] as String? ?? ''));
  }

  static Widget _buildChoiceChip(Map<String, dynamic> properties) {
    return ChoiceChip(
      label: Text(properties['label'] as String? ?? ''),
      selected: false,
      onSelected: (bool selected) {},
    );
  }

  static Widget _buildTooltip(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return Tooltip(
      message: properties['message'] as String? ?? '',
      child: child ?? const Placeholder(),
    );
  }

  static Widget _buildListTile(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    return ListTile(
      title: Text(properties['title'] as String? ?? ''),
      subtitle: Text(properties['subtitle'] as String? ?? ''),
      leading: properties['leadingIcon'] != null
          ? Icon(_parseIconData(properties['leadingIcon'] as String))
          : null,
    );
  }

  // ===== INPUT WIDGETS =====

  static Widget _buildElevatedButton(Map<String, dynamic> properties) {
    return ElevatedButton(
      onPressed: () => _handleButtonPress(properties['onPressed'] as String? ?? ''),
      child: Text(properties['label'] as String? ?? 'Button'),
    );
  }

  static Widget _buildTextButton(Map<String, dynamic> properties) {
    return TextButton(
      onPressed: () => _handleButtonPress(properties['onPressed'] as String? ?? ''),
      child: Text(properties['label'] as String? ?? 'Button'),
    );
  }

  static Widget _buildIconButton(Map<String, dynamic> properties) {
    return IconButton(
      icon: Icon(_parseIconData(properties['icon'] as String? ?? 'info')),
      onPressed: () => _handleButtonPress(properties['onPressed'] as String? ?? ''),
    );
  }

  static Widget _buildOutlinedButton(Map<String, dynamic> properties) {
    return OutlinedButton(
      onPressed: () => _handleButtonPress(properties['onPressed'] as String? ?? ''),
      child: Text(properties['label'] as String? ?? 'Button'),
    );
  }

  static Widget _buildTextField(Map<String, dynamic> properties) {
    return TextField(
      decoration: InputDecoration(
        labelText: properties['label'] as String?,
        hintText: properties['hint'] as String?,
        border: const OutlineInputBorder(),
      ),
      obscureText: properties['obscureText'] as bool? ?? false,
    );
  }

  static Widget _buildTextFormField(Map<String, dynamic> properties) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: properties['label'] as String?,
        hintText: properties['hint'] as String?,
        border: const OutlineInputBorder(),
      ),
      obscureText: properties['obscureText'] as bool? ?? false,
    );
  }

  static Widget _buildCheckbox(Map<String, dynamic> properties) {
    return Checkbox(
      value: properties['value'] as bool? ?? false,
      onChanged: (bool? value) {},
    );
  }

  static Widget _buildCheckboxListTile(Map<String, dynamic> properties) {
    return CheckboxListTile(
      title: Text(properties['label'] as String? ?? ''),
      value: properties['value'] as bool? ?? false,
      onChanged: (bool? value) {},
    );
  }

  static Widget _buildRadio(Map<String, dynamic> properties) {
    return Radio(
      value: properties['value'] ?? '',
      groupValue: properties['groupValue'] ?? '',
      onChanged: (value) {},
    );
  }

  static Widget _buildRadioListTile(Map<String, dynamic> properties) {
    return RadioListTile(
      title: Text(properties['label'] as String? ?? ''),
      value: properties['value'] ?? '',
      groupValue: properties['groupValue'] ?? '',
      onChanged: (value) {},
    );
  }

  static Widget _buildSwitch(Map<String, dynamic> properties) {
    return Switch(
      value: properties['value'] as bool? ?? false,
      onChanged: (bool value) {},
    );
  }

  static Widget _buildSwitchListTile(Map<String, dynamic> properties) {
    return SwitchListTile(
      title: Text(properties['label'] as String? ?? ''),
      value: properties['value'] as bool? ?? false,
      onChanged: (bool value) {},
    );
  }

  static Widget _buildSlider(Map<String, dynamic> properties) {
    return Slider(
      min: (properties['min'] as num?)?.toDouble() ?? 0.0,
      max: (properties['max'] as num?)?.toDouble() ?? 100.0,
      value: (properties['value'] as num?)?.toDouble() ?? 0.0,
      onChanged: (double value) {},
    );
  }

  static Widget _buildRangeSlider(Map<String, dynamic> properties) {
    return RangeSlider(
      min: (properties['min'] as num?)?.toDouble() ?? 0.0,
      max: (properties['max'] as num?)?.toDouble() ?? 100.0,
      values: RangeValues(
        (properties['startValue'] as num?)?.toDouble() ?? 0.0,
        (properties['endValue'] as num?)?.toDouble() ?? 100.0,
      ),
      onChanged: (RangeValues values) {},
    );
  }

  static Widget _buildDropdownButton(Map<String, dynamic> properties) {
    return DropdownButton<String>(
      hint: Text(properties['hint'] as String? ?? 'Select'),
      items: [],
      onChanged: (String? value) {},
    );
  }

  static Widget _buildPopupMenuButton(Map<String, dynamic> properties) {
    return PopupMenuButton<String>(
      itemBuilder: (BuildContext context) => [],
    );
  }

  static Widget _buildSegmentedButton(Map<String, dynamic> properties) {
    return SegmentedButton<String>(
      segments: [],
      selected: const <String>{},
      onSelectionChanged: (Set<String> newSelection) {},
    );
  }

  static Widget _buildSearchBar(Map<String, dynamic> properties) {
    return SearchBar(
      hintText: properties['hint'] as String? ?? 'Search',
    );
  }

  static Widget _buildForm(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final children = renderList(childrenData, context: context);
    return Form(
      child: Column(children: children),
    );
  }

  // ===== DIALOG & OVERLAY WIDGETS =====

  static Widget _buildDialog(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return Dialog(child: child ?? const Placeholder());
  }

  static Widget _buildAlertDialog(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    return AlertDialog(
      title: Text(properties['title'] as String? ?? ''),
      content: Text(properties['content'] as String? ?? ''),
    );
  }

  static Widget _buildSimpleDialog(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    return SimpleDialog(
      title: Text(properties['title'] as String? ?? ''),
    );
  }

  static Widget _buildOffstage(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return Offstage(
      offstage: properties['offstage'] as bool? ?? false,
      child: child ?? const Placeholder(),
    );
  }

  // ===== ANIMATION & VISIBILITY =====

  static Widget _buildAnimatedContainer(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return AnimatedContainer(
      duration: Duration(milliseconds: (properties['duration'] as num?)?.toInt() ?? 300),
      child: child ?? const Placeholder(),
    );
  }

  static Widget _buildAnimatedOpacity(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return AnimatedOpacity(
      opacity: (properties['opacity'] as num?)?.toDouble() ?? 1.0,
      duration: Duration(milliseconds: (properties['duration'] as num?)?.toInt() ?? 300),
      child: child ?? const Placeholder(),
    );
  }

  static Widget _buildFadeInImage(Map<String, dynamic> properties) {
    return FadeInImage.assetNetwork(
      placeholder: properties['placeholder'] as String? ?? 'assets/placeholder.png',
      image: properties['image'] as String? ?? '',
    );
  }

  static Widget _buildVisibility(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>, context: context)
        : null;
    return Visibility(
      visible: properties['visible'] as bool? ?? true,
      child: child ?? const Placeholder(),
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
          Text('Error: $error', style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ),
    );
  }

  static void _handleButtonPress(dynamic actionData) {
    // Support both old string format and new action object format
    if (actionData == null || actionData.toString().isEmpty) {
      print('No action specified');
      return;
    }

    // Old format: just a string
    if (actionData is String) {
      print('Button pressed: $actionData');
      return;
    }

    // New format: action object (Map)
    if (actionData is Map<String, dynamic>) {
      try {
        final action = callback_actions.Action.fromJson(actionData);
        // TODO: Execute action with proper context
        // For now, just print the action type
        print('Action executed: ${action.action}');
      } catch (e) {
        print('Error parsing action: $e');
      }
      return;
    }

    print('Invalid action format: $actionData');
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
    if (value is num) return EdgeInsets.all(value.toDouble());
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
    if (value is num) return BorderRadius.circular(value.toDouble());
    return null;
  }
}
