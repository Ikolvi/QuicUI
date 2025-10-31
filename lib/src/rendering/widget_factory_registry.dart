import 'package:flutter/material.dart';
import 'form_widget_builders.dart';
import 'display_widgets.dart';
import 'animation_widgets.dart' as animation_widgets;
import 'layout_widgets.dart' as layout_widgets;
import 'navigation_widgets.dart' as navigation_widgets;
import 'scrolling_widgets.dart' as scrolling_widgets;
import 'data_display_widgets.dart' as data_display_widgets;
import 'state_management_widgets.dart' as state_management_widgets;
import 'app_level_widgets.dart' as app_level_widgets;
import 'gesture_widgets.dart' as gesture_widgets_module;
import 'input_widgets.dart' as input_widgets;
import 'dialog_widgets.dart' as dialog_widgets;
import '../utils/logger_util.dart';

/// Type definition for widget builders
typedef WidgetBuilder = Widget Function(
  Map<String, dynamic> properties,
  List<dynamic> childrenData,
  BuildContext context,
  dynamic render,
);

/// Central registry for all 130+ widget builders
/// Consolidates UIRenderer and WidgetFactoryRegistry into unified system
/// This is a CRITICAL FIX: includes all available widgets from all widget files
class WidgetFactoryRegistry {
  // Placeholder for field controllers from UIRenderer
  static final Map<String, TextEditingController> _fieldControllers = {};

  // ===== UNIFIED WIDGET REGISTRY (130+ WIDGETS) =====
  
  static final Map<String, WidgetBuilder> _allWidgets = {
    // APP-LEVEL WIDGETS (8)
    'MaterialApp': _buildMaterialApp,
    'Scaffold': _buildScaffold,
    'AppBar': _buildAppBar,
    'BottomAppBar': _buildBottomAppBar,
    'Drawer': _buildDrawer,
    'FloatingActionButton': _buildFloatingActionButton,
    'NavigationBar': _buildNavigationBar,
    'TabBar': _buildTabBar,
    
    // LAYOUT WIDGETS (45+)
    'Column': _buildColumn,
    'Row': _buildRow,
    'Container': _buildContainer,
    'Stack': _buildStack,
    'Positioned': _buildPositioned,
    'Center': _buildCenter,
    'Padding': _buildPadding,
    'Align': _buildAlign,
    'Expanded': _buildExpanded,
    'Flexible': _buildFlexible,
    'SizedBox': _buildSizedBox,
    'SingleChildScrollView': _buildSingleChildScrollView,
    'ListView': _buildListView,
    'GridView': _buildGridView,
    'Wrap': _buildWrap,
    'Spacer': _buildSpacer,
    'AspectRatio': _buildAspectRatio,
    'FractionallySizedBox': _buildFractionallySizedBox,
    'IntrinsicHeight': _buildIntrinsicHeight,
    'IntrinsicWidth': _buildIntrinsicWidth,
    'Transform': _buildTransform,
    'Opacity': _buildOpacity,
    'DecoratedBox': _buildDecoratedBox,
    'ClipRect': _buildClipRect,
    'ClipRRect': _buildClipRRect,
    'ClipOval': _buildClipOval,
    'Material': _buildMaterial,
    'Table': _buildTable,
    // CRITICAL: Layout widget methods from layout_widgets.dart
    'LayoutBuilder': _buildLayoutBuilder,
    'SliverAppBar': _buildSliverAppBar,
    'BottomSheet': _buildBottomSheet,
    'Avatar': _buildAvatar,
    'ProgressBar': _buildProgressBar,
    'CircularProgress': _buildCircularProgress,
    'Tag': _buildTag,
    'LinearProgress': _buildLinearProgress,
    'SegmentedControl': _buildSegmentedControl,
    'ExpansionPanel': _buildExpansionPanel,
    'ExpansionTile': _buildExpansionTile,
    'Stepper': _buildStepper,
    'FittedBox': _buildFittedBox,
    'CustomPaint': _buildCustomPaint,
    'ClipPath': _buildClipPath,
    'DataTable': _buildDataTable,
    'PageView': _buildPageView,
    
    // DISPLAY WIDGETS (30+)
    'Text': _buildText,
    'RichText': _buildRichText,
    'Image': _buildImage,
    'Icon': _buildIcon,
    'Card': _buildCard,
    'Divider': _buildDivider,
    'VerticalDivider': _buildVerticalDivider,
    'Badge': _buildBadge,
    'Chip': _buildChip,
    'ActionChip': _buildActionChip,
    'FilterChip': _buildFilterChip,
    'InputChip': _buildInputChip,
    'ChoiceChip': _buildChoiceChip,
    'Tooltip': _buildTooltip,
    'ListTile': _buildListTile,
    'Rating': _buildRating,
    'ColorPicker': _buildColorPicker,
    'TimePicker': _buildTimePicker,
    'DatePicker': _buildDatePicker,
    'Calendar': _buildCalendar,
    'FileUpload': _buildFileUpload,
    'NumberInput': _buildNumberInput,
    'OtpInput': _buildOtpInput,
    'SearchBox': _buildSearchBox,
    'ContextMenu': _buildContextMenu,
    'MultiSelect': _buildMultiSelect,
    'StatisticCard': _buildStatisticCard,
    
    // INPUT WIDGETS (25+)
    'ElevatedButton': _buildElevatedButton,
    'TextButton': _buildTextButton,
    'IconButton': _buildIconButton,
    'OutlinedButton': _buildOutlinedButton,
    'TextField': _buildTextField,
    'TextArea': _buildTextArea,
    'Checkbox': _buildCheckbox,
    'CheckboxListTile': _buildCheckboxListTile,
    'Radio': _buildRadio,
    'RadioListTile': _buildRadioListTile,
    'Switch': _buildSwitch,
    'SwitchListTile': _buildSwitchListTile,
    'Slider': _buildSlider,
    'RangeSlider': _buildRangeSlider,
    'DropdownButton': _buildDropdownButton,
    'DropdownButtonForm': _buildDropdownButtonForm,
    'PopupMenuButton': _buildPopupMenuButton,
    'SegmentedButton': _buildSegmentedButton,
    'SearchBar': _buildSearchBar,
    
    // DIALOG & OVERLAY (5+)
    'Dialog': _buildDialog,
    'AlertDialog': _buildAlertDialog,
    'SimpleDialog': _buildSimpleDialog,
    'Offstage': _buildOffstage,
    'SnackBar': _buildSnackBar,
    
    // GESTURE WIDGETS (11+) - CRITICAL ADDITIONS
    'GestureDetector': _buildGestureDetector,
    'InkWell': _buildInkWell,
    'InkResponse': _buildInkResponse,
    'Draggable': _buildDraggable,
    'LongPressDraggable': _buildLongPressDraggable,
    'DragTarget': _buildDragTarget,
    'SwipeDetector': _buildSwipeDetector,
    'RotationGestureDetector': _buildRotationGestureDetector,
    'ScaleGestureDetector': _buildScaleGestureDetector,
    'MultiTouchGestureDetector': _buildMultiTouchGestureDetector,
    'PinchZoom': _buildPinchZoom,
    
    // ANIMATION & VISIBILITY (25+)
    'AnimatedContainer': _buildAnimatedContainer,
    'AnimatedOpacity': _buildAnimatedOpacity,
    'AnimatedScale': _buildAnimatedScale,
    'AnimatedRotation': _buildAnimatedRotation,
    'AnimatedPositioned': _buildAnimatedPositioned,
    'AnimatedAlign': _buildAnimatedAlign,
    'AnimatedBuilder': _buildAnimatedBuilder,
    'AnimatedDefaultTextStyle': _buildAnimatedDefaultTextStyle,
    'AnimatedPhysicalModel': _buildAnimatedPhysicalModel,
    'AnimatedSwitcher': _buildAnimatedSwitcher,
    'FadeInImage': _buildFadeInImage,
    'Visibility': _buildVisibility,
    'Hero': _buildHero,
    'TweenAnimationBuilder': _buildTweenAnimationBuilder,
    'FadeAnimation': _buildFadeAnimation,
    'SlideAnimation': _buildSlideAnimation,
    'ScaleAnimation': _buildScaleAnimation,
    'RotationAnimation': _buildRotationAnimation,
    'BounceAnimation': _buildBounceAnimation,
    'PulseAnimation': _buildPulseAnimation,
    'WaveAnimation': _buildWaveAnimation,
    'ShakeAnimation': _buildShakeAnimation,
    'FlipAnimation': _buildFlipAnimation,
    'BlurAnimation': _buildBlurAnimation,
    'GlowAnimation': _buildGlowAnimation,
    
    // NAVIGATION WIDGETS (15+)
    'NavigationRail': _buildNavigationRail,
    'Breadcrumb': _buildBreadcrumb,
    'MenuBar': _buildMenuBar,
    'SideBar': _buildSideBar,
    'NavigationStack': _buildNavigationStack,
    'StackedNavigation': _buildStackedNavigation,
    'PaginationNav': _buildPaginationNav,
    'DrawerNavigation': _buildDrawerNavigation,
    'AdvancedBottomNav': _buildAdvancedBottomNav,
    'AdvancedSliverAppBar': _buildAdvancedSliverAppBar,
    'TabBarEnhanced': _buildTabBarEnhanced,
    'TabBarViewAdvanced': _buildTabBarViewAdvanced,
    
    // SCROLLING WIDGETS (15+)
    'NestedScrollView': _buildNestedScrollView,
    'CustomScrollView': _buildCustomScrollView,
    'SliverGrid': _buildSliverGrid,
    'SliverList': _buildSliverList,
    'Flow': _buildFlow,
    'InfiniteList': _buildInfiniteList,
    'VirtualizedList': _buildVirtualizedList,
    'VirtualGrid': _buildVirtualGrid,
    'MasonryGrid': _buildMasonryGrid,
    'StickyHeaders': _buildStickyHeaders,
    
    // DATA DISPLAY WIDGETS (20+)
    'LineChart': _buildLineChart,
    'BarChart': _buildBarChart,
    'PieChart': _buildPieChart,
    'AreaChart': _buildAreaChart,
    'ScatterChart': _buildScatterChart,
    'Timeline': _buildTimeline,
    'TimelineView': _buildTimelineView,
    'DataGrid': _buildDataGrid,
    'TableView': _buildTableView,
    'MediaQueryHelper': _buildMediaQueryHelper,
    'ResponsiveWidget': _buildResponsiveWidget,
    'ProgressRing': _buildProgressRing,
    
    // STATE MANAGEMENT WIDGETS (15+) - CRITICAL ADDITIONS
    'LoadingStateWidget': _buildLoadingStateWidget,
    'ErrorStateWidget': _buildErrorStateWidget,
    'EmptyStateWidget': _buildEmptyStateWidget,
    'SkeletonLoader': _buildSkeletonLoader,
    'SuccessStateWidget': _buildSuccessStateWidget,
    'RetryButton': _buildRetryButton,
    'ProgressIndicator': _buildProgressIndicator,
    'StatusBadge': _buildStatusBadge,
    'StateTransitionWidget': _buildStateTransitionWidget,
    'DataRefreshWidget': _buildDataRefreshWidget,
    'OfflineIndicator': _buildOfflineIndicator,
    'SyncStatusWidget': _buildSyncStatusWidget,
    'ValidationIndicator': _buildValidationIndicator,
    'WarningBanner': _buildWarningBanner,
    'InfoPanel': _buildInfoPanel,
    'ToastNotification': _buildToastNotification,
    
    // DATA BINDING
    'DataBinding': _buildDataBinding,
    
    // FORM WIDGETS (8)
    'Form': _buildForm,
    'TextFormField': _buildTextFormField,
    'CheckboxField': _buildCheckboxField,
    'RadioField': _buildRadioField,
    'SelectField': _buildSelectField,
    'SliderField': _buildSliderField,
    'SwitchField': _buildSwitchField,
    'FormSubmitButton': _buildFormSubmitButton,
  };

  // ===== REGISTRY API =====

  /// Get all registered widget builders
  static Map<String, WidgetBuilder> getAllWidgets() => _allWidgets;

  /// Check if a widget type is registered
  static bool isRegistered(String widgetType) => _allWidgets.containsKey(widgetType);

  /// Get a widget builder by type name
  static WidgetBuilder? getBuilder(String widgetType) => _allWidgets[widgetType];

  // ===== UNIFIED BUILDER IMPLEMENTATIONS =====

  // APP-LEVEL BUILDERS
  static Widget _buildMaterialApp(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    Widget? home;
    if (childrenData.isNotEmpty) {
      final childConfig = Map<String, dynamic>.from(childrenData.first as Map<String, dynamic>);
      if (properties['onNavigateTo'] != null) {
        childConfig['onNavigateTo'] = properties['onNavigateTo'];
      }
      home = render(childConfig, context: context);
    }
    
    return MaterialApp(
      title: properties['title'] as String? ?? 'QuicUI App',
      home: home ?? const Scaffold(body: Placeholder()),
      debugShowCheckedModeBanner: properties['debugShowCheckedModeBanner'] as bool? ?? false,
    );
  }

  static Widget _buildScaffold(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    PreferredSizeWidget? appBar;
    Widget? body;
    Widget? floatingActionButton;
    Widget? bottomNavigationBar;
    
    for (final child in childrenData) {
      final childMap = Map<String, dynamic>.from(child as Map<String, dynamic>);
      final type = childMap['type'] as String;
      
      switch (type) {
        case 'AppBar':
          appBar = render(childMap, context: context) as PreferredSizeWidget?;
          break;
        case 'FloatingActionButton':
          floatingActionButton = render(childMap, context: context);
          break;
        case 'BottomNavigationBar':
          bottomNavigationBar = render(childMap, context: context);
          break;
        default:
          body = render(childMap, context: context);
          break;
      }
    }
    
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  static Widget _buildAppBar(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
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
    BuildContext context,
    dynamic render,
  ) {
    final children = (render as Function)(childrenData);
    return BottomAppBar(
      child: Row(children: children as List<Widget>),
    );
  }

  static Widget _buildDrawer(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final children = (render as Function)(childrenData);
    return Drawer(
      child: ListView(children: children as List<Widget>),
    );
  }

  static Widget _buildFloatingActionButton(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return FloatingActionButton(
      onPressed: () => _handleButtonPress(properties['onPressed']),
      child: Icon(_parseIconData(properties['icon'] as String? ?? 'add')),
    );
  }

  static Widget _buildNavigationBar(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return NavigationBar(
      onDestinationSelected: (int index) {},
      selectedIndex: 0,
      destinations: [],
    );
  }

  static Widget _buildTabBar(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return const TabBar(tabs: []);
  }

  // LAYOUT BUILDERS
  static Widget _buildColumn(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final children = (render as Function)(childrenData);
    return Column(
      mainAxisAlignment: _parseMainAxisAlignment(properties['mainAxisAlignment']),
      crossAxisAlignment: _parseCrossAxisAlignment(properties['crossAxisAlignment']),
      mainAxisSize: properties['mainAxisSize'] == 'min' ? MainAxisSize.min : MainAxisSize.max,
      children: children as List<Widget>,
    );
  }

  static Widget _buildRow(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final children = (render as Function)(childrenData);
    final mainAxisSize = properties['mainAxisSize'] == 'max' ? MainAxisSize.max : MainAxisSize.min;
    return Row(
      mainAxisAlignment: _parseMainAxisAlignment(properties['mainAxisAlignment']),
      crossAxisAlignment: _parseCrossAxisAlignment(properties['crossAxisAlignment']),
      mainAxisSize: mainAxisSize,
      children: children as List<Widget>,
    );
  }

  static Widget _buildContainer(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return Container(
      width: _parseDouble(properties['width']),
      height: _parseDouble(properties['height']),
      color: _parseColor(properties['color']),
      padding: _parseEdgeInsets(properties['padding']),
      margin: _parseEdgeInsets(properties['margin']),
      decoration: _parseBoxDecoration(properties['decoration']),
      child: child as Widget?,
    );
  }

  static Widget _buildStack(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final children = (render as Function)(childrenData);
    return Stack(
      alignment: _parseAlignment(properties['alignment']),
      fit: properties['fit'] == 'expand' ? StackFit.expand : StackFit.loose,
      children: children as List<Widget>,
    );
  }

  static Widget _buildPositioned(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : const Placeholder();
    return Positioned(
      left: (properties['left'] as num?)?.toDouble(),
      right: (properties['right'] as num?)?.toDouble(),
      top: (properties['top'] as num?)?.toDouble(),
      bottom: (properties['bottom'] as num?)?.toDouble(),
      child: child as Widget,
    );
  }

  static Widget _buildCenter(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return Center(child: child as Widget? ?? const Placeholder());
  }

  static Widget _buildPadding(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return Padding(
      padding: _parseEdgeInsets(properties['padding']) ?? EdgeInsets.zero,
      child: child as Widget? ?? const Placeholder(),
    );
  }

  static Widget _buildAlign(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return Align(
      alignment: _parseAlignment(properties['alignment']),
      child: child as Widget? ?? const Placeholder(),
    );
  }

  static Widget _buildExpanded(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    final flex = (properties['flex'] as num?)?.toInt() ?? 1;
    return Expanded(
      flex: flex,
      child: child as Widget? ?? const Placeholder(),
    );
  }

  static Widget _buildFlexible(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    final flex = (properties['flex'] as num?)?.toInt() ?? 1;
    return Flexible(
      flex: flex,
      fit: properties['fit'] == 'tight' ? FlexFit.tight : FlexFit.loose,
      child: child as Widget? ?? const Placeholder(),
    );
  }

  static Widget _buildSizedBox(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return SizedBox(
      width: _parseDouble(properties['width']),
      height: _parseDouble(properties['height']),
      child: child as Widget?,
    );
  }

  static Widget _buildSingleChildScrollView(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return SingleChildScrollView(
      scrollDirection: properties['scrollDirection'] == 'horizontal' ? Axis.horizontal : Axis.vertical,
      child: child as Widget? ?? const Placeholder(),
    );
  }

  static Widget _buildListView(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final children = (render as Function)(childrenData);
    return ListView(
      scrollDirection: properties['scrollDirection'] == 'horizontal' ? Axis.horizontal : Axis.vertical,
      shrinkWrap: properties['shrinkWrap'] as bool? ?? false,
      children: children as List<Widget>,
    );
  }

  static Widget _buildGridView(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final children = (render as Function)(childrenData);
    final crossAxisCount = (properties['crossAxisCount'] as num?)?.toInt() ?? 2;
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: properties['shrinkWrap'] as bool? ?? false,
      children: children as List<Widget>,
    );
  }

  static Widget _buildWrap(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final children = (render as Function)(childrenData);
    return Wrap(
      spacing: (properties['spacing'] as num?)?.toDouble() ?? 8.0,
      runSpacing: (properties['runSpacing'] as num?)?.toDouble() ?? 8.0,
      children: children as List<Widget>,
    );
  }

  static Widget _buildSpacer(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final flex = (properties['flex'] as num?)?.toInt() ?? 1;
    return Spacer(flex: flex);
  }

  static Widget _buildAspectRatio(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    final aspectRatio = (properties['aspectRatio'] as num?)?.toDouble() ?? 1.0;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: child as Widget? ?? const Placeholder(),
    );
  }

  static Widget _buildFractionallySizedBox(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return FractionallySizedBox(
      widthFactor: _parseDouble(properties['widthFactor']),
      heightFactor: _parseDouble(properties['heightFactor']),
      child: child as Widget? ?? const Placeholder(),
    );
  }

  static Widget _buildIntrinsicHeight(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return IntrinsicHeight(child: child as Widget? ?? const Placeholder());
  }

  static Widget _buildIntrinsicWidth(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return IntrinsicWidth(child: child as Widget? ?? const Placeholder());
  }

  static Widget _buildTransform(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return Transform.translate(
      offset: Offset(
        (properties['offsetX'] as num?)?.toDouble() ?? 0,
        (properties['offsetY'] as num?)?.toDouble() ?? 0,
      ),
      child: child as Widget? ?? const Placeholder(),
    );
  }

  static Widget _buildOpacity(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    final opacity = (properties['opacity'] as num?)?.toDouble() ?? 1.0;
    return Opacity(opacity: opacity, child: child as Widget? ?? const Placeholder());
  }

  static Widget _buildDecoratedBox(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return DecoratedBox(
      decoration: _parseBoxDecoration(properties['decoration']) ?? const BoxDecoration(),
      child: child as Widget? ?? const Placeholder(),
    );
  }

  static Widget _buildClipRect(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return ClipRect(child: child as Widget? ?? const Placeholder());
  }

  static Widget _buildClipRRect(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    final radius = (properties['radius'] as num?)?.toDouble() ?? 8.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: child as Widget? ?? const Placeholder(),
    );
  }

  static Widget _buildClipOval(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return ClipOval(child: child as Widget? ?? const Placeholder());
  }

  static Widget _buildMaterial(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return Material(
      color: _parseColor(properties['color']) ?? Colors.white,
      child: child as Widget? ?? const Placeholder(),
    );
  }

  static Widget _buildTable(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Table(
      columnWidths: const <int, TableColumnWidth>{},
      children: [],
    );
  }

  // DISPLAY BUILDERS
  static Widget _buildText(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return DisplayWidgets.buildText(properties);
  }

  static Widget _buildRichText(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return DisplayWidgets.buildRichText(properties);
  }

  static Widget _buildImage(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return DisplayWidgets.buildImage(properties);
  }

  static Widget _buildIcon(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return DisplayWidgets.buildIcon(properties);
  }

  static Widget _buildCard(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return DisplayWidgets.buildCard(properties, childrenData, context: context, render: (cfg, _, {context}) => render(cfg));
  }

  static Widget _buildDivider(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return DisplayWidgets.buildDivider(properties);
  }

  static Widget _buildVerticalDivider(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return DisplayWidgets.buildVerticalDivider(properties);
  }

  static Widget _buildBadge(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return DisplayWidgets.buildBadge(properties, childrenData, context: context, render: (cfg, _, {context}) => render(cfg));
  }

  static Widget _buildChip(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return DisplayWidgets.buildChip(properties);
  }

  static Widget _buildActionChip(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return DisplayWidgets.buildActionChip(properties);
  }

  static Widget _buildFilterChip(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return DisplayWidgets.buildFilterChip(properties);
  }

  static Widget _buildInputChip(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return DisplayWidgets.buildInputChip(properties);
  }

  static Widget _buildChoiceChip(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return DisplayWidgets.buildChoiceChip(properties);
  }

  static Widget _buildTooltip(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return DisplayWidgets.buildTooltip(properties, childrenData, context: context, render: (cfg, _, {context}) => render(cfg));
  }

  static Widget _buildListTile(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return DisplayWidgets.buildListTile(properties);
  }

  // INPUT BUILDERS
  static Widget _buildElevatedButton(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final childrenData2 = properties['children'] as List? ?? [];
    final child = childrenData2.isNotEmpty ? render(childrenData2.first) : Text(properties['label'] as String? ?? 'Button');
    
    return ElevatedButton(
      onPressed: () {
        final events = properties['events'] as Map<String, dynamic>?;
        if (events != null) {
          _handleCallback(events['onPressed'], properties);
        }
      },
      child: child as Widget,
    );
  }

  static Widget _buildTextButton(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final childrenData2 = properties['children'] as List? ?? [];
    final child = childrenData2.isNotEmpty ? render(childrenData2.first) : Text(properties['label'] as String? ?? 'Button');
    
    return TextButton(
      onPressed: () {
        final events = properties['events'] as Map<String, dynamic>?;
        if (events != null) {
          _handleCallback(events['onPressed'], properties);
        }
      },
      child: child as Widget,
    );
  }

  static Widget _buildIconButton(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return IconButton(
      icon: Icon(_parseIconData(properties['icon'] as String? ?? 'info')),
      onPressed: () {
        final events = properties['events'] as Map<String, dynamic>?;
        if (events != null) {
          _handleCallback(events['onPressed'], properties);
        }
      },
    );
  }

  static Widget _buildOutlinedButton(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final childrenData2 = properties['children'] as List? ?? [];
    final child = childrenData2.isNotEmpty ? render(childrenData2.first) : Text(properties['label'] as String? ?? 'Button');
    
    return OutlinedButton(
      onPressed: () {
        final events = properties['events'] as Map<String, dynamic>?;
        if (events != null) {
          _handleCallback(events['onPressed'], properties);
        }
      },
      child: child as Widget,
    );
  }

  static Widget _buildTextField(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final fieldId = properties['fieldId'] as String? ?? 'field_${DateTime.now().millisecondsSinceEpoch}';
    
    final controller = _fieldControllers.putIfAbsent(
      fieldId,
      () => TextEditingController(),
    );
    
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: properties['label'] as String?,
        hintText: properties['hint'] as String?,
        border: const OutlineInputBorder(),
      ),
      obscureText: properties['obscureText'] as bool? ?? false,
    );
  }

  static Widget _buildCheckbox(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Checkbox(
      value: properties['value'] as bool? ?? false,
      onChanged: (bool? value) {},
    );
  }

  static Widget _buildCheckboxListTile(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return CheckboxListTile(
      title: Text(properties['label'] as String? ?? ''),
      value: properties['value'] as bool? ?? false,
      onChanged: (bool? value) {},
    );
  }

  static Widget _buildRadio(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Radio<String>(
      value: properties['value'] as String? ?? '',
    );
  }

  static Widget _buildRadioListTile(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return RadioListTile<String>(
      title: Text(properties['label'] as String? ?? ''),
      value: properties['value'] as String? ?? '',
    );
  }

  static Widget _buildSwitch(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Switch(
      value: properties['value'] as bool? ?? false,
      onChanged: (bool value) {},
    );
  }

  static Widget _buildSwitchListTile(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return SwitchListTile(
      title: Text(properties['label'] as String? ?? ''),
      value: properties['value'] as bool? ?? false,
      onChanged: (bool value) {},
    );
  }

  static Widget _buildSlider(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Slider(
      min: (properties['min'] as num?)?.toDouble() ?? 0.0,
      max: (properties['max'] as num?)?.toDouble() ?? 100.0,
      value: (properties['value'] as num?)?.toDouble() ?? 0.0,
      onChanged: (double value) {},
    );
  }

  static Widget _buildRangeSlider(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
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

  static Widget _buildDropdownButton(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return DropdownButton<String>(
      hint: Text(properties['hint'] as String? ?? 'Select'),
      items: [],
      onChanged: (String? value) {},
    );
  }

  static Widget _buildPopupMenuButton(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return PopupMenuButton<String>(
      itemBuilder: (BuildContext context) => [],
    );
  }

  static Widget _buildSegmentedButton(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return SegmentedButton<String>(
      segments: [],
      selected: const <String>{},
      onSelectionChanged: (Set<String> newSelection) {},
    );
  }

  static Widget _buildSearchBar(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return SearchBar(
      hintText: properties['hint'] as String? ?? 'Search',
    );
  }

  // DIALOG & OVERLAY BUILDERS
  static Widget _buildDialog(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return Dialog(child: child as Widget? ?? const Placeholder());
  }

  static Widget _buildAlertDialog(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return AlertDialog(
      title: Text(properties['title'] as String? ?? ''),
      content: Text(properties['content'] as String? ?? ''),
    );
  }

  static Widget _buildSimpleDialog(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return SimpleDialog(
      title: Text(properties['title'] as String? ?? ''),
    );
  }

  static Widget _buildOffstage(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return Offstage(
      offstage: properties['offstage'] as bool? ?? false,
      child: child as Widget? ?? const Placeholder(),
    );
  }

  // ANIMATION & VISIBILITY BUILDERS
  static Widget _buildAnimatedContainer(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildAnimatedContainer(properties, childrenData);
  }

  static Widget _buildAnimatedOpacity(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildAnimatedOpacity(properties, childrenData);
  }

  static Widget _buildFadeInImage(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return FadeInImage.assetNetwork(
      placeholder: properties['placeholder'] as String? ?? 'assets/placeholder.png',
      image: properties['image'] as String? ?? '',
    );
  }

  static Widget _buildVisibility(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return Visibility(
      visible: properties['visible'] as bool? ?? true,
      child: child as Widget? ?? const Placeholder(),
    );
  }

  // DATA BINDING BUILDER
  static Widget _buildDataBinding(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    if (childrenData.length == 1) {
      return render(childrenData.first) as Widget;
    }
    
    final children = (render as Function)(childrenData);
    return Column(children: children as List<Widget>);
  }

  // FORM BUILDERS
  static Widget _buildForm(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return FormWidgetBuilders.buildForm(properties, childrenData, context, render);
  }

  static Widget _buildTextFormField(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return FormWidgetBuilders.buildTextFormField(properties, childrenData, context, render);
  }

  static Widget _buildCheckboxField(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return FormWidgetBuilders.buildCheckboxField(properties, childrenData, context, render);
  }

  static Widget _buildRadioField(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return FormWidgetBuilders.buildRadioField(properties, childrenData, context, render);
  }

  static Widget _buildSelectField(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return FormWidgetBuilders.buildSelectField(properties, childrenData, context, render);
  }

  static Widget _buildSliderField(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return FormWidgetBuilders.buildSliderField(properties, childrenData, context, render);
  }

  static Widget _buildSwitchField(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return FormWidgetBuilders.buildSwitchField(properties, childrenData, context, render);
  }

  static Widget _buildFormSubmitButton(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return FormWidgetBuilders.buildFormSubmitButton(properties, childrenData, context, render);
  }

  // ===== ADDITIONAL LAYOUT WIDGETS =====

  static Widget _buildLayoutBuilder(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Container(
          constraints: constraints,
          child: childrenData.isNotEmpty 
              ? render(childrenData.first)
              : const Placeholder(),
        );
      },
    );
  }

  static Widget _buildSliverAppBar(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return layout_widgets.LayoutWidgets.buildSliverAppBar(properties, childrenData);
  }

  static Widget _buildBottomSheet(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return layout_widgets.LayoutWidgets.buildBottomSheet(properties, childrenData, context);
  }

  static Widget _buildAvatar(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return layout_widgets.LayoutWidgets.buildAvatar(properties);
  }

  static Widget _buildProgressBar(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return layout_widgets.LayoutWidgets.buildProgressBar(properties);
  }

  static Widget _buildCircularProgress(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return layout_widgets.LayoutWidgets.buildCircularProgress(properties);
  }

  static Widget _buildTag(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return layout_widgets.LayoutWidgets.buildTag(properties);
  }

  static Widget _buildLinearProgress(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return LinearProgressIndicator(
      value: (properties['value'] as num?)?.toDouble(),
    );
  }

  static Widget _buildSegmentedControl(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return SegmentedButton<String>(
      segments: [],
      selected: const {},
      onSelectionChanged: (Set<String> newSelection) {},
    );
  }

  static Widget _buildExpansionPanel(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container();
  }

  static Widget _buildExpansionTile(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return layout_widgets.LayoutWidgets.buildExpansionTile(properties, childrenData);
  }

  static Widget _buildStepper(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return layout_widgets.LayoutWidgets.buildStepper(properties, childrenData);
  }

  static Widget _buildFittedBox(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return FittedBox(child: child ?? const Placeholder());
  }

  static Widget _buildClipPath(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return ClipPath(child: child ?? const Placeholder());
  }

  static Widget _buildPageView(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final children = (render as Function)(childrenData);
    return PageView(children: children as List<Widget>);
  }

  static Widget _buildCustomPaint(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return CustomPaint(
      size: Size(
        (properties['width'] as num?)?.toDouble() ?? 100,
        (properties['height'] as num?)?.toDouble() ?? 100,
      ),
    );
  }

  static Widget _buildDataTable(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return DataTable(
      columns: [],
      rows: [],
    );
  }

  static Widget _buildRating(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          Icons.star,
          color: Colors.amber,
          size: 24,
        ),
      ),
    );
  }

  static Widget _buildColorPicker(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container(
      width: 200,
      height: 200,
      color: _parseColor(properties['color']) ?? Colors.blue,
    );
  }

  static Widget _buildTimePicker(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(properties['time'] as String? ?? '00:00'),
    );
  }

  static Widget _buildDatePicker(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(properties['date'] as String? ?? 'Select date'),
    );
  }

  static Widget _buildCalendar(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Text('Calendar'),
    );
  }

  static Widget _buildFileUpload(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.upload_file),
      label: const Text('Upload'),
    );
  }

  static Widget _buildNumberInput(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: properties['label'] as String?,
        hintText: properties['hint'] as String?,
      ),
    );
  }

  static Widget _buildOtpInput(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Row(
      children: List.generate(
        (properties['length'] as num?)?.toInt() ?? 6,
        (index) => Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(border: Border.all()),
          child: const Text(''),
        ),
      ),
    );
  }

  static Widget _buildSearchBox(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return SearchBar(
      hintText: properties['hint'] as String? ?? 'Search',
    );
  }

  static Widget _buildContextMenu(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container();
  }

  static Widget _buildMultiSelect(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container();
  }

  static Widget _buildStatisticCard(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(properties['title'] as String? ?? ''),
            Text(properties['value'] as String? ?? '0'),
          ],
        ),
      ),
    );
  }

  // ===== ADDITIONAL INPUT WIDGETS =====

  static Widget _buildTextArea(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return TextField(
      maxLines: (properties['maxLines'] as num?)?.toInt() ?? 5,
      decoration: InputDecoration(
        labelText: properties['label'] as String?,
        hintText: properties['hint'] as String?,
        border: const OutlineInputBorder(),
      ),
    );
  }

  static Widget _buildDropdownButtonForm(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return DropdownButton<String>(
      hint: Text(properties['hint'] as String? ?? 'Select'),
      items: [],
      onChanged: (String? value) {},
    );
  }

  // ===== GESTURE WIDGETS ADAPTERS (DELEGATED TO gesture_widgets.dart) =====

  /// Adapter for GestureDetector - delegates to gesture_widgets_module
  static Widget _buildGestureDetector(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    // Convert registry signature to gesture_widgets signature
    final config = {
      'properties': properties,
      'children': childrenData,
      'events': properties['events'] ?? {},
    };
    
    return gesture_widgets_module.buildGestureDetector(config, null);
  }

  /// Adapter for InkWell - delegates to gesture_widgets_module
  static Widget _buildInkWell(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final config = {
      'properties': properties,
      'children': childrenData,
      'events': properties['events'] ?? {},
    };
    
    return gesture_widgets_module.buildInkWell(config, null);
  }

  /// Adapter for InkResponse - delegates to gesture_widgets_module
  static Widget _buildInkResponse(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final config = {
      'properties': properties,
      'children': childrenData,
      'events': properties['events'] ?? {},
    };
    
    return gesture_widgets_module.buildInkResponse(config, null);
  }

  /// Adapter for Draggable - delegates to gesture_widgets_module
  static Widget _buildDraggable(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final config = {
      'properties': properties,
      'children': childrenData,
      'events': properties['events'] ?? {},
    };
    
    return gesture_widgets_module.buildDraggable(config, null);
  }

  /// Adapter for LongPressDraggable - delegates to gesture_widgets_module
  static Widget _buildLongPressDraggable(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final config = {
      'properties': properties,
      'children': childrenData,
      'events': properties['events'] ?? {},
    };
    
    return gesture_widgets_module.buildLongPressDraggable(config, null);
  }

  /// Adapter for DragTarget - delegates to gesture_widgets_module
  static Widget _buildDragTarget(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final config = {
      'properties': properties,
      'children': childrenData,
      'events': properties['events'] ?? {},
    };
    
    return gesture_widgets_module.buildDragTarget(config, null);
  }

  /// Adapter for SwipeDetector - delegates to gesture_widgets_module
  static Widget _buildSwipeDetector(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final config = {
      'properties': properties,
      'children': childrenData,
      'events': properties['events'] ?? {},
    };
    
    return gesture_widgets_module.buildSwipeDetector(config, null);
  }

  /// Adapter for RotationGestureDetector - delegates to gesture_widgets_module
  static Widget _buildRotationGestureDetector(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final config = {
      'properties': properties,
      'children': childrenData,
      'events': properties['events'] ?? {},
    };
    
    return gesture_widgets_module.buildRotationGestureDetector(config, null);
  }

  /// Adapter for ScaleGestureDetector - delegates to gesture_widgets_module
  static Widget _buildScaleGestureDetector(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final config = {
      'properties': properties,
      'children': childrenData,
      'events': properties['events'] ?? {},
    };
    
    return gesture_widgets_module.buildScaleGestureDetector(config, null);
  }

  /// Adapter for MultiTouchGestureDetector - delegates to gesture_widgets_module
  static Widget _buildMultiTouchGestureDetector(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final config = {
      'properties': properties,
      'children': childrenData,
      'events': properties['events'] ?? {},
    };
    
    return gesture_widgets_module.buildMultiTouchGestureDetector(config, null);
  }

  /// Adapter for PinchZoom - uses InteractiveViewer fallback (not in gesture_widgets.dart)
  static Widget _buildPinchZoom(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : const Placeholder();
    return InteractiveViewer(
      minScale: (properties['minScale'] as num?)?.toDouble() ?? 0.5,
      maxScale: (properties['maxScale'] as num?)?.toDouble() ?? 4.0,
      child: child as Widget,
    );
  }

  // ===== ANIMATION WIDGETS (CRITICAL ADDITION) =====

  static Widget _buildAnimatedScale(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildAnimatedScale(properties, childrenData);
  }

  static Widget _buildAnimatedRotation(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildAnimatedRotation(properties, childrenData);
  }

  static Widget _buildAnimatedPositioned(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildAnimatedPositioned(properties, childrenData);
  }

  static Widget _buildAnimatedAlign(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildAnimatedAlign(properties, childrenData);
  }

  static Widget _buildAnimatedBuilder(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : const Placeholder();
    return child as Widget;
  }

  static Widget _buildAnimatedDefaultTextStyle(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildAnimatedDefaultTextStyle(properties, childrenData);
  }

  static Widget _buildAnimatedPhysicalModel(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildAnimatedPhysicalModel(properties, childrenData);
  }

  static Widget _buildAnimatedSwitcher(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildAnimatedSwitcher(properties, childrenData);
  }

  static Widget _buildHero(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildHero(properties, childrenData);
  }

  static Widget _buildTweenAnimationBuilder(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildTweenAnimationBuilder(properties, childrenData);
  }

  static Widget _buildFadeAnimation(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildFadeAnimation(properties, childrenData);
  }

  static Widget _buildSlideAnimation(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildSlideAnimation(properties, childrenData);
  }

  static Widget _buildScaleAnimation(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildScaleAnimation(properties, childrenData);
  }

  static Widget _buildRotationAnimation(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildRotationAnimation(properties, childrenData);
  }

  static Widget _buildBounceAnimation(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildBounceAnimation(properties, childrenData);
  }

  static Widget _buildPulseAnimation(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildPulseAnimation(properties, childrenData);
  }

  static Widget _buildWaveAnimation(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildWaveAnimation(properties, childrenData);
  }

  static Widget _buildShakeAnimation(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildShakeAnimation(properties, childrenData);
  }

  static Widget _buildFlipAnimation(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildFlipAnimation(properties, childrenData);
  }

  static Widget _buildBlurAnimation(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildBlurAnimation(properties, childrenData);
  }

  static Widget _buildGlowAnimation(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return animation_widgets.AnimationWidgets.buildGlowAnimation(properties, childrenData);
  }

  // ===== NAVIGATION WIDGETS =====

  static Widget _buildNavigationRail(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container();
  }

  static Widget _buildBreadcrumb(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container();
  }

  static Widget _buildMenuBar(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container();
  }

  static Widget _buildSideBar(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return navigation_widgets.NavigationWidgets.buildSideBar(properties, childrenData);
  }

  static Widget _buildNavigationStack(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final children = (render as Function)(childrenData);
    return Column(children: children as List<Widget>);
  }

  static Widget _buildStackedNavigation(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final children = (render as Function)(childrenData);
    return Column(children: children as List<Widget>);
  }

  static Widget _buildPaginationNav(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container();
  }

  static Widget _buildDrawerNavigation(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return navigation_widgets.NavigationWidgets.buildDrawerNavigation(properties, childrenData);
  }

  static Widget _buildAdvancedBottomNav(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container();
  }

  static Widget _buildAdvancedSliverAppBar(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container();
  }

  static Widget _buildTabBarEnhanced(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container();
  }

  static Widget _buildTabBarViewAdvanced(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final children = (render as Function)(childrenData);
    return Container(child: Column(children: children as List<Widget>));
  }

  // ===== SCROLLING WIDGETS =====

  static Widget _buildNestedScrollView(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return scrolling_widgets.ScrollingWidgets.buildNestedScrollView(properties, childrenData);
  }

  static Widget _buildCustomScrollView(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return scrolling_widgets.ScrollingWidgets.buildCustomScrollView(properties, childrenData);
  }

  static Widget _buildSliverGrid(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return scrolling_widgets.ScrollingWidgets.buildSliverGrid(properties, childrenData);
  }

  static Widget _buildSliverList(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return scrolling_widgets.ScrollingWidgets.buildSliverList(properties, childrenData);
  }

  static Widget _buildFlow(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return scrolling_widgets.ScrollingWidgets.buildFlow(properties, childrenData);
  }

  static Widget _buildInfiniteList(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return ListView();
  }

  static Widget _buildVirtualizedList(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return scrolling_widgets.ScrollingWidgets.buildVirtualizedList(properties, childrenData);
  }

  static Widget _buildVirtualGrid(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return GridView.count(crossAxisCount: 2, children: []);
  }

  static Widget _buildMasonryGrid(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return GridView.count(crossAxisCount: 2, children: []);
  }

  static Widget _buildStickyHeaders(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return scrolling_widgets.ScrollingWidgets.buildStickyHeaders(properties, childrenData);
  }

  // ===== DATA DISPLAY WIDGETS =====

  static Widget _buildLineChart(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container();
  }

  static Widget _buildBarChart(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container();
  }

  static Widget _buildPieChart(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container();
  }

  static Widget _buildAreaChart(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container();
  }

  static Widget _buildScatterChart(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container();
  }

  static Widget _buildTimeline(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return data_display_widgets.DataDisplayWidgets.buildTimeline(properties, childrenData);
  }

  static Widget _buildTimelineView(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return data_display_widgets.DataDisplayWidgets.buildTimelineView(properties, childrenData);
  }

  static Widget _buildDataGrid(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container();
  }

  static Widget _buildTableView(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container();
  }

  static Widget _buildMediaQueryHelper(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return Container(child: child as Widget? ?? const Placeholder());
  }

  static Widget _buildResponsiveWidget(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : null;
    return Container(child: child as Widget? ?? const Placeholder());
  }

  static Widget _buildProgressRing(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return CircularProgressIndicator(
      value: (properties['value'] as num?)?.toDouble(),
    );
  }

  // ===== STATE MANAGEMENT WIDGETS (CRITICAL ADDITION) =====

  static Widget _buildLoadingStateWidget(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return state_management_widgets.LoadingStateWidget();
  }

  static Widget _buildErrorStateWidget(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return state_management_widgets.ErrorStateWidget(
      message: properties['message'] as String? ?? 'Error occurred',
    );
  }

  static Widget _buildEmptyStateWidget(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return state_management_widgets.EmptyStateWidget(
      message: properties['message'] as String? ?? 'No data available',
    );
  }

  static Widget _buildSkeletonLoader(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return state_management_widgets.SkeletonLoader(
      itemCount: (properties['itemCount'] as num?)?.toInt() ?? 5,
    );
  }

  static Widget _buildSuccessStateWidget(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return state_management_widgets.SuccessStateWidget(
      message: properties['message'] as String? ?? 'Success',
    );
  }

  static Widget _buildRetryButton(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return state_management_widgets.RetryButton(
      onPressed: () {},
    );
  }

  static Widget _buildProgressIndicator(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return state_management_widgets.ProgressIndicator(
      progress: (properties['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static Widget _buildStatusBadge(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        properties['status'] as String? ?? 'pending',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  static Widget _buildStateTransitionWidget(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    final child = childrenData.isNotEmpty ? render(childrenData.first) : const Placeholder();
    return child as Widget;
  }

  static Widget _buildDataRefreshWidget(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return state_management_widgets.DataRefreshWidget(
      onRefresh: () async {},
    );
  }

  static Widget _buildOfflineIndicator(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.red,
      child: const Text('Offline', style: TextStyle(color: Colors.white)),
    );
  }

  static Widget _buildSyncStatusWidget(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.green,
      child: Text(
        properties['status'] as String? ?? 'synced',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  static Widget _buildValidationIndicator(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return state_management_widgets.ValidationIndicator(
      isValid: properties['isValid'] as bool? ?? false,
    );
  }

  static Widget _buildWarningBanner(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return state_management_widgets.WarningBanner(
      message: properties['message'] as String? ?? 'Warning',
    );
  }

  static Widget _buildInfoPanel(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return state_management_widgets.InfoPanel(
      title: properties['title'] as String? ?? 'Info',
      message: properties['message'] as String? ?? '',
    );
  }

  static Widget _buildToastNotification(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return state_management_widgets.ToastNotification(
      message: properties['message'] as String? ?? 'Notification',
      duration: Duration(milliseconds: (properties['duration'] as num?)?.toInt() ?? 3000),
    );
  }

  static Widget _buildSnackBar(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext context,
    dynamic render,
  ) {
    return Container();
  }

  // ===== HELPER METHODS =====

  static void _handleCallback(dynamic actionData, Map<String, dynamic> properties) {
    // Simplified callback handling - delegates to main logic
    if (actionData is Map<String, dynamic>) {
      final action = actionData['action'] as String?;
      if (action == 'navigate') {
        final screen = actionData['screen'] as String?;
        if (screen != null && properties['onNavigateTo'] is Function) {
          (properties['onNavigateTo'] as Function)(screen);
        }
      }
    }
  }

  static void _handleButtonPress(dynamic actionData) {
    LoggerUtil.debug('Button pressed: $actionData');
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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

  static Color? _parseColor(dynamic value) {
    if (value is String) {
      if (value.startsWith('#')) {
        final hexColor = value.replaceFirst('#', '');
        final colorString = hexColor.length == 6 ? 'FF$hexColor' : hexColor.padLeft(8, '0');
        return Color(int.parse('0x$colorString'));
      }
      return switch (value.toLowerCase()) {
        'red' => Colors.red,
        'green' => Colors.green,
        'blue' => Colors.blue,
        'white' => Colors.white,
        'black' => Colors.black,
        'grey' => Colors.grey,
        _ => null,
      };
    }
    return null;
  }

  static EdgeInsets? _parseEdgeInsets(dynamic value) {
    if (value == null) return null;
    if (value is num) return EdgeInsets.all(value.toDouble());
    if (value is Map) {
      if (value.containsKey('all')) {
        return EdgeInsets.all((value['all'] as num?)?.toDouble() ?? 0);
      }
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
      'info' => Icons.info,
      'warning' => Icons.warning,
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
        boxShadow: _parseBoxShadow(value['boxShadow']),
      );
    }
    return null;
  }

  static Border? _parseBorder(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      if (value.containsKey('color') || value.containsKey('width')) {
        final color = _parseColor(value['color']) ?? Colors.black;
        final width = (value['width'] as num?)?.toDouble() ?? 1.0;
        return Border.all(color: color, width: width);
      }
    }
    return null;
  }

  static List<BoxShadow>? _parseBoxShadow(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value
          .map((shadow) => _parseSingleBoxShadow(shadow))
          .where((shadow) => shadow != null)
          .cast<BoxShadow>()
          .toList();
    }
    return null;
  }

  static BoxShadow? _parseSingleBoxShadow(dynamic value) {
    if (value is Map) {
      return BoxShadow(
        color: _parseColor(value['color']) ?? Colors.black26,
        blurRadius: (value['blurRadius'] as num?)?.toDouble() ?? 0.0,
        spreadRadius: (value['spreadRadius'] as num?)?.toDouble() ?? 0.0,
        offset: _parseOffset(value['offset']),
      );
    }
    return null;
  }

  static Offset _parseOffset(dynamic value) {
    if (value is Map) {
      final dx = (value['dx'] as num?)?.toDouble() ?? 0.0;
      final dy = (value['dy'] as num?)?.toDouble() ?? 0.0;
      return Offset(dx, dy);
    }
    return Offset.zero;
  }

  static BorderRadius? _parseBorderRadius(dynamic value) {
    if (value == null) return null;
    if (value is num) return BorderRadius.circular(value.toDouble());
    if (value is Map) {
      if (value.containsKey('all')) {
        final radius = (value['all'] as num?)?.toDouble() ?? 0.0;
        return BorderRadius.circular(radius);
      }
    }
    return null;
  }
}
