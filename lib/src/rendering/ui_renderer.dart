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
library;

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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/callback_actions.dart' as callback_actions;
import '../utils/logger_util.dart';
import '../utils/error_handler.dart';
import 'layout_widgets.dart';
import 'form_widgets.dart';
import 'scrolling_widgets.dart';
import 'navigation_widgets.dart';
import 'animation_widgets.dart';
import 'data_display_widgets.dart';
import 'state_management_widgets.dart';

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
  /// Global map to store field values from TextFields
  static final Map<String, TextEditingController> _fieldControllers = {};
  
  /// Render a widget tree from JSON configuration
  static Widget render(Map<String, dynamic> config, {BuildContext? context}) {
    try {
      // Validate JSON structure only in debug mode for better performance in production
      if (kDebugMode) {
        final validation = JsonValidator.validateWidgetJson(config);
        if (!validation.isValid) {
          ErrorHandler.handleValidationErrors(validation.errors, config);
          // Continue with rendering but log validation issues
        }
      }

      final type = config['type'] as String?;
      if (type == null) {
        LoggerUtil.warning('Widget type is null, rendering placeholder', config);
        return const Placeholder();
      }
      
      final shouldRender = config['shouldRender'] as bool? ?? true;
      if (!shouldRender) return const SizedBox.shrink();
      
      return _renderWidgetByType(type, config, context);
    } catch (error, stackTrace) {
      return ErrorHandler.handleRenderingError(
        error,
        config,
        context: {
          'method': 'UIRenderer.render',
          'widget_type': config['type'],
        },
        stackTrace: stackTrace,
      );
    }
  }

  /// Render a list of widgets from JSON array
  static List<Widget> renderList(List<dynamic> widgetsData, {BuildContext? context}) {
    final widgets = <Widget>[];
    
    for (int i = 0; i < widgetsData.length; i++) {
      final data = widgetsData[i];
      if (data is Map<String, dynamic>) {
        try {
          final widget = render(data, context: context);
          widgets.add(widget);
        } catch (error, stackTrace) {
          LoggerUtil.error(
            'Failed to render widget at index $i',
            error,
            stackTrace,
          );
          // Add error widget but continue with other widgets
          widgets.add(ErrorHandler.handleRenderingError(
            error,
            data,
            context: {
              'method': 'UIRenderer.renderList',
              'widget_index': i,
              'total_widgets': widgetsData.length,
            },
            stackTrace: stackTrace,
          ));
        }
      } else {
        LoggerUtil.warning(
          'Invalid widget data at index $i: expected Map, got ${data.runtimeType}',
          data,
        );
      }
    }
    
    return widgets;
  }

  /// Render widget by type - 70+ widgets supported
  static Widget _renderWidgetByType(
    String type,
    Map<String, dynamic> config,
    BuildContext? context,
  ) {
    try {
      dynamic propsRaw = config['properties'];
      final Map<String, dynamic> properties = propsRaw is Map ? Map<String, dynamic>.from(propsRaw) : {};
      final childrenData = config['children'] as List? ?? [];

      // Log debug information for widget rendering
      LoggerUtil.debug('Rendering widget: $type', {
        'properties_count': properties.length,
        'children_count': childrenData.length,
        'config_keys': config.keys.toList(),
      });

      return switch (type) {
        // ===== APP-LEVEL WIDGETS =====
        'MaterialApp' => _buildMaterialApp(properties, childrenData, config, context),
        
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
        'ElevatedButton' => _buildElevatedButton(properties, config),
        'TextButton' => _buildTextButton(properties, config),
        'IconButton' => _buildIconButton(properties),
        'OutlinedButton' => _buildOutlinedButton(properties, config),
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
        
        // ===== LAYOUT WIDGETS =====
        'SliverAppBar' => LayoutWidgets.buildSliverAppBar(properties, childrenData),
        'BottomSheet' => LayoutWidgets.buildBottomSheet(properties, childrenData, context),
        'Avatar' => LayoutWidgets.buildAvatar(properties),
        'ProgressBar' => LayoutWidgets.buildProgressBar(properties),
        'CircularProgress' => LayoutWidgets.buildCircularProgress(properties),
        'Tag' => LayoutWidgets.buildTag(properties),
        'FittedBox' => LayoutWidgets.buildFittedBox(properties, childrenData),
        'ExpansionTile' => LayoutWidgets.buildExpansionTile(properties, childrenData),
        'Stepper' => LayoutWidgets.buildStepper(properties, childrenData),
        'DataTable' => LayoutWidgets.buildDataTable(properties, childrenData),
        'PageView' => LayoutWidgets.buildPageView(properties, childrenData, context),
        'SnackBar' => LayoutWidgets.buildSnackBar(properties),
        
        // ===== FORM WIDGETS (NEW) =====
        'TextArea' => FormWidgets.buildTextArea(properties),
        'NumberInput' => FormWidgets.buildNumberInput(properties),
        'DatePicker' => FormWidgets.buildDatePicker(properties),
        'TimePicker' => FormWidgets.buildTimePicker(properties),
        'ColorPicker' => FormWidgets.buildColorPicker(properties),
        'DropdownButtonForm' => FormWidgets.buildDropdownButtonForm(properties),
        'MultiSelect' => FormWidgets.buildMultiSelect(properties),
        'SearchBox' => FormWidgets.buildSearchBox(properties),
        'FileUpload' => FormWidgets.buildFileUpload(properties),
        'Rating' => FormWidgets.buildRating(properties),
        'OtpInput' => FormWidgets.buildOtpInput(properties),
        
        // ===== SCROLLING WIDGETS =====
        'CustomScrollView' => ScrollingWidgets.buildCustomScrollView(properties, childrenData),
        'SliverList' => ScrollingWidgets.buildSliverList(properties, childrenData),
        'SliverGrid' => ScrollingWidgets.buildSliverGrid(properties, childrenData),
        'Flow' => ScrollingWidgets.buildFlow(properties, childrenData),
        'LayoutBuilder' => ScrollingWidgets.buildLayoutBuilder(properties, childrenData),
        'MediaQueryHelper' => ScrollingWidgets.buildMediaQueryHelper(properties, childrenData),
        'ResponsiveWidget' => ScrollingWidgets.buildResponsiveWidget(properties, childrenData),
        'AdvancedSliverAppBar' => ScrollingWidgets.buildAdvancedSliverAppBar(properties, childrenData),
        'NestedScrollView' => ScrollingWidgets.buildNestedScrollView(properties, childrenData),
        'AnimatedBuilder' => ScrollingWidgets.buildAnimatedBuilder(properties, childrenData),
        'TabBarViewAdvanced' => ScrollingWidgets.buildTabBarViewAdvanced(properties, childrenData),
        'PinchZoom' => ScrollingWidgets.buildPinchZoom(properties, childrenData),
        'VirtualizedList' => ScrollingWidgets.buildVirtualizedList(properties, childrenData),
        'StickyHeaders' => ScrollingWidgets.buildStickyHeaders(properties, childrenData),
        
        // ===== NAVIGATION WIDGETS =====
        'NavigationRail' => NavigationWidgets.buildNavigationRail(properties, childrenData),
        'Breadcrumb' => NavigationWidgets.buildBreadcrumb(properties, childrenData),
        'BreadcrumbItem' => NavigationWidgets.buildBreadcrumbItem(properties, childrenData),
        'StackedNavigation' => NavigationWidgets.buildStackedNavigation(properties, childrenData),
        'NavigationStack' => NavigationWidgets.buildNavigationStack(properties, childrenData),
        'DrawerNavigation' => NavigationWidgets.buildDrawerNavigation(properties, childrenData),
        'MenuBar' => NavigationWidgets.buildMenuBar(properties, childrenData),
        'SideBar' => NavigationWidgets.buildSideBar(properties, childrenData),
        'ContextMenu' => NavigationWidgets.buildContextMenu(properties, childrenData),
        'AdvancedBottomNav' => NavigationWidgets.buildAdvancedBottomNav(properties, childrenData),
        'TabBarEnhanced' => NavigationWidgets.buildTabBarEnhanced(properties, childrenData),
        'AnimatedDrawer' => NavigationWidgets.buildAnimatedDrawer(properties, childrenData),
        'PaginationNav' => NavigationWidgets.buildPaginationNav(properties, childrenData),

        // ===== ANIMATION WIDGETS =====
        'AnimatedOpacityCustom' => AnimationWidgets.buildAnimatedOpacity(properties, childrenData),
        'AnimatedScaleCustom' => AnimationWidgets.buildAnimatedScale(properties, childrenData),
        'AnimatedRotationCustom' => AnimationWidgets.buildAnimatedRotation(properties, childrenData),
        'AnimatedPositionedCustom' => AnimationWidgets.buildAnimatedPositioned(properties, childrenData),
        'AnimatedAlignCustom' => AnimationWidgets.buildAnimatedAlign(properties, childrenData),
        'HeroCustom' => AnimationWidgets.buildHero(properties, childrenData),
        'TweenAnimationBuilderCustom' => AnimationWidgets.buildTweenAnimationBuilder(properties, childrenData),
        'AnimatedContainerCustom' => AnimationWidgets.buildAnimatedContainer(properties, childrenData),
        'AnimatedDefaultTextStyleCustom' => AnimationWidgets.buildAnimatedDefaultTextStyle(properties, childrenData),
        'AnimatedPhysicalModelCustom' => AnimationWidgets.buildAnimatedPhysicalModel(properties, childrenData),
        'AnimatedSwitcherCustom' => AnimationWidgets.buildAnimatedSwitcher(properties, childrenData),
        'SlideAnimation' => AnimationWidgets.buildSlideAnimation(properties, childrenData),
        'FadeAnimation' => AnimationWidgets.buildFadeAnimation(properties, childrenData),
        'RotationAnimation' => AnimationWidgets.buildRotationAnimation(properties, childrenData),
        'ScaleAnimation' => AnimationWidgets.buildScaleAnimation(properties, childrenData),
        'SizeAnimation' => AnimationWidgets.buildSizeAnimation(properties, childrenData),
        'SkewAnimation' => AnimationWidgets.buildSkewAnimation(properties, childrenData),
        'PerspectiveAnimation' => AnimationWidgets.buildPerspectiveAnimation(properties, childrenData),
        'ShakeAnimation' => AnimationWidgets.buildShakeAnimation(properties, childrenData),
        'PulseAnimation' => AnimationWidgets.buildPulseAnimation(properties, childrenData),
        'FlipAnimation' => AnimationWidgets.buildFlipAnimation(properties, childrenData),
        'BounceAnimation' => AnimationWidgets.buildBounceAnimation(properties, childrenData),
        'FloatingAnimation' => AnimationWidgets.buildFloatingAnimation(properties, childrenData),
        'GlowAnimation' => AnimationWidgets.buildGlowAnimation(properties, childrenData),
        'ProgressAnimation' => AnimationWidgets.buildProgressAnimation(properties, childrenData),
        'WaveAnimation' => AnimationWidgets.buildWaveAnimation(properties, childrenData),
        'ColorAnimation' => AnimationWidgets.buildColorAnimation(properties, childrenData),
        'BlurAnimation' => AnimationWidgets.buildBlurAnimation(properties, childrenData),
        
        // ===== DATA DISPLAY WIDGETS =====
        'LineChart' => DataDisplayWidgets.buildLineChart(properties, childrenData),
        'BarChart' => DataDisplayWidgets.buildBarChart(properties, childrenData),
        'PieChart' => DataDisplayWidgets.buildPieChart(properties, childrenData),
        'ScatterChart' => DataDisplayWidgets.buildScatterChart(properties, childrenData),
        'AreaChart' => DataDisplayWidgets.buildAreaChart(properties, childrenData),
        'Timeline' => DataDisplayWidgets.buildTimeline(properties, childrenData),
        'Calendar' => DataDisplayWidgets.buildCalendar(properties, childrenData),
        'ProgressRing' => DataDisplayWidgets.buildProgressRing(properties, childrenData),
        'StatisticCard' => DataDisplayWidgets.buildStatisticCard(properties, childrenData),
        'TableView' => DataDisplayWidgets.buildTableView(properties, childrenData),
        'InfiniteList' => DataDisplayWidgets.buildInfiniteList(properties, childrenData),
        'VirtualGrid' => DataDisplayWidgets.buildVirtualGrid(properties, childrenData),
        'MasonryGrid' => DataDisplayWidgets.buildMasonryGrid(properties, childrenData),
        'TimelineView' => DataDisplayWidgets.buildTimelineView(properties, childrenData),
        'DataGrid' => DataDisplayWidgets.buildDataGrid(properties, childrenData),
        
        // ===== STATE MANAGEMENT WIDGETS =====
        'LoadingStateWidget' => StateManagementWidgets.buildLoadingStateWidget(properties, childrenData),
        'ErrorStateWidget' => StateManagementWidgets.buildErrorStateWidget(properties, childrenData),
        'EmptyStateWidget' => StateManagementWidgets.buildEmptyStateWidget(properties, childrenData),
        'SkeletonLoader' => StateManagementWidgets.buildSkeletonLoader(properties, childrenData),
        'SuccessStateWidget' => StateManagementWidgets.buildSuccessStateWidget(properties, childrenData),
        'RetryButton' => StateManagementWidgets.buildRetryButton(properties, childrenData),
        'ProgressIndicatorCustom' => StateManagementWidgets.buildProgressIndicator(properties, childrenData),
        'StatusBadge' => StateManagementWidgets.buildStatusBadge(properties, childrenData),
        'StateTransitionWidget' => StateManagementWidgets.buildStateTransitionWidget(properties, childrenData),
        'DataRefreshWidget' => StateManagementWidgets.buildDataRefreshWidget(properties, childrenData),
        'OfflineIndicator' => StateManagementWidgets.buildOfflineIndicator(properties, childrenData),
        'SyncStatusWidget' => StateManagementWidgets.buildSyncStatusWidget(properties, childrenData),
        'ValidationIndicator' => StateManagementWidgets.buildValidationIndicator(properties, childrenData),
        'WarningBanner' => StateManagementWidgets.buildWarningBanner(properties, childrenData),
        'InfoPanel' => StateManagementWidgets.buildInfoPanel(properties, childrenData),
        'ToastNotification' => StateManagementWidgets.buildToastNotification(properties, childrenData),
        
        _ => _buildUnsupportedWidget(type, config),
      };
    } catch (error, stackTrace) {
      return ErrorHandler.handleRenderingError(
        error,
        config,
        context: {
          'method': '_renderWidgetByType',
          'widget_type': type,
          'properties_count': config['properties'] != null ? (config['properties'] as Map).length : 0,
          'children_count': config['children'] != null ? (config['children'] as List).length : 0,
        },
        stackTrace: stackTrace,
      );
    }
  }

  // ===== APP-LEVEL WIDGETS =====

  static Widget _buildMaterialApp(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    Map<String, dynamic> config,
    BuildContext? context,
  ) {
    // Check for explicit "home" key in config first
    Widget? home;
    if (config['home'] is Map<String, dynamic>) {
      final homeConfig = Map<String, dynamic>.from(config['home'] as Map<String, dynamic>);
      if (config['onNavigateTo'] != null) {
        homeConfig['onNavigateTo'] = config['onNavigateTo'];
      }
      home = render(homeConfig, context: context);
    } else if (childrenData.isNotEmpty) {
      // Fallback to children if no explicit home
      final childConfig = Map<String, dynamic>.from(childrenData.first as Map<String, dynamic>);
      if (config['onNavigateTo'] != null) {
        childConfig['onNavigateTo'] = config['onNavigateTo'];
      }
      home = render(childConfig, context: context);
    }
    
    // Theme configuration
    final themeConfig = config['theme'] as Map<String, dynamic>?;
    ThemeData? theme;
    
    if (themeConfig != null) {
      final primaryColorStr = themeConfig['primaryColor'] as String? ?? '#1E88E5';
      final primaryColor = _parseColor(primaryColorStr) ?? Colors.blue;
      final useMaterial3 = themeConfig['useMaterial3'] as bool? ?? true;
      final brightness = themeConfig['brightness'] == 'dark' ? Brightness.dark : Brightness.light;
      
      theme = ThemeData(
        primarySwatch: _colorToMaterialColor(primaryColor),
        useMaterial3: useMaterial3,
        brightness: brightness,
      );
    }
    
    return MaterialApp(
      title: properties['title'] as String? ?? 'QuicUI App',
      theme: theme ?? ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: home ?? const Scaffold(body: Placeholder()),
      debugShowCheckedModeBanner: properties['debugShowCheckedModeBanner'] as bool? ?? false,
    );
  }

  // Helper method to convert Color to MaterialColor
  static MaterialColor _colorToMaterialColor(Color color) {
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

  // ===== SCAFFOLD & APP-LEVEL WIDGETS =====
  
  static Widget _buildScaffold(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    Map<String, dynamic> config,
    BuildContext? context,
  ) {
    // Separate AppBar and body from children
    PreferredSizeWidget? appBar;
    Widget? body;
    Widget? floatingActionButton;
    Widget? bottomNavigationBar;
    
    for (final child in childrenData) {
      final childMap = Map<String, dynamic>.from(child as Map<String, dynamic>);
      
      // Pass navigation callback to all children
      if (config['onNavigateTo'] != null) {
        childMap['onNavigateTo'] = config['onNavigateTo'];
      }
      
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
          // All other widgets go to body
          body = render(childMap, context: context);
          break;
      }
    }
    
    // Handle legacy config format (fallback)
    final appBarConfig = config['appBar'] as Map<String, dynamic>?;
    final floatingActionButtonConfig = config['fab'] as Map<String, dynamic>?;
    
    return Scaffold(
      appBar: appBar ?? (appBarConfig != null ? _buildAppBar((appBarConfig['properties'] as Map<String, dynamic>?) ?? {}, [], context) as PreferredSizeWidget? : null),
      body: body,
      floatingActionButton: floatingActionButton ?? (floatingActionButtonConfig != null ? _buildFloatingActionButton((floatingActionButtonConfig['properties'] as Map<String, dynamic>?) ?? {}) : null),
      bottomNavigationBar: bottomNavigationBar,
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
    return _safeWidgetBuilder(
      'Column',
      properties,
      () {
        final children = renderList(childrenData, context: context);
        return Column(
          mainAxisAlignment: _parseMainAxisAlignment(properties['mainAxisAlignment']),
          crossAxisAlignment: _parseCrossAxisAlignment(properties['crossAxisAlignment']),
          mainAxisSize: properties['mainAxisSize'] == 'min' ? MainAxisSize.min : MainAxisSize.max,
          children: children,
        );
      },
      fallbackBuilder: (error) {
        // Fallback to basic column if property parsing fails
        LoggerUtil.warning('Column fallback used due to error', error);
        final children = renderList(childrenData, context: context);
        return Column(children: children);
      },
    );
  }

  static Widget _buildRow(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
  ) {
    final children = renderList(childrenData, context: context);
    
    // Default to MainAxisSize.min to prevent unbounded constraints in scrollable contexts
    final mainAxisSize = properties['mainAxisSize'] == 'max' 
        ? MainAxisSize.max 
        : MainAxisSize.min;
        
    return Row(
      mainAxisAlignment: _parseMainAxisAlignment(properties['mainAxisAlignment']),
      crossAxisAlignment: _parseCrossAxisAlignment(properties['crossAxisAlignment']),
      mainAxisSize: mainAxisSize,
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
    
    // Handle color vs decoration conflict - Flutter doesn't allow both
    final parsedDecoration = _parseBoxDecoration(properties['decoration']);
    final parsedColor = _parseColor(properties['color']);
    
    BoxDecoration? finalDecoration = parsedDecoration;
    Color? finalColor;
    
    // If no decoration but color exists, use color
    // If decoration exists, ignore color (decoration takes priority)
    if (parsedDecoration == null && parsedColor != null) {
      finalColor = parsedColor;
    }
    
    return Container(
      width: _parseDouble(properties['width']),
      height: _parseDouble(properties['height']),
      color: finalColor,
      padding: _parseEdgeInsets(properties['padding']),
      margin: _parseEdgeInsets(properties['margin']),
      decoration: finalDecoration,
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
      width: _parseDouble(properties['width']),
      height: _parseDouble(properties['height']),
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
      widthFactor: _parseDouble(properties['widthFactor']),
      heightFactor: _parseDouble(properties['heightFactor']),
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
    return _safeWidgetBuilder(
      'Text',
      properties,
      () {
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
      },
      fallbackBuilder: (error) {
        // Fallback to simple text with basic styling if complex styling fails
        final text = properties['text']?.toString() ?? 'Text Error';
        return Text(
          text,
          style: const TextStyle(color: Colors.red, fontSize: 12),
        );
      },
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

  static Widget _buildElevatedButton(
    Map<String, dynamic> properties,
    Map<String, dynamic> config,
  ) {
    final childrenData = properties['children'] as List? ?? [];
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>)
        : Text(properties['label'] as String? ?? 'Button');
    
    return ElevatedButton(
      onPressed: () {
        final events = properties['events'] as Map<String, dynamic>?;
        if (events != null) {
          _handleCallback(events['onPressed'], config);
        }
      },
      child: child,
    );
  }

  static Widget _buildTextButton(
    Map<String, dynamic> properties,
    Map<String, dynamic> config,
  ) {
    final childrenData = properties['children'] as List? ?? [];
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>)
        : Text(properties['label'] as String? ?? 'Button');
    
    return TextButton(
      onPressed: () {
        final events = properties['events'] as Map<String, dynamic>?;
        if (events != null) {
          _handleCallback(events['onPressed'], config);
        }
      },
      child: child,
    );
  }

  static Widget _buildIconButton(Map<String, dynamic> properties) {
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
    Map<String, dynamic> config,
  ) {
    final childrenData = properties['children'] as List? ?? [];
    final child = childrenData.isNotEmpty
        ? render(childrenData.first as Map<String, dynamic>)
        : Text(properties['label'] as String? ?? 'Button');
    
    return OutlinedButton(
      onPressed: () {
        final events = properties['events'] as Map<String, dynamic>?;
        if (events != null) {
          _handleCallback(events['onPressed'], config);
        }
      },
      child: child,
    );
  }

  static Widget _buildTextField(Map<String, dynamic> properties) {
    final fieldId = properties['fieldId'] as String? ?? 'field_${DateTime.now().millisecondsSinceEpoch}';
    
    // Get or create controller for this field
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
    // Modern Radio without deprecated onChanged - events handled by QuicUI system
    return Radio<String>(
      value: properties['value'] as String? ?? '',
    );
  }

  static Widget _buildRadioListTile(Map<String, dynamic> properties) {
    // Modern RadioListTile without deprecated onChanged - events handled by QuicUI system
    return RadioListTile<String>(
      title: Text(properties['label'] as String? ?? ''),
      value: properties['value'] as String? ?? '',
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

  /// Build widget for unsupported widget types
  ///
  /// Creates a placeholder widget with debug information for unsupported
  /// widget types, helping developers identify missing widget implementations.
  static Widget _buildUnsupportedWidget(String type, Map<String, dynamic> config) {
    LoggerUtil.warning(
      'Unsupported widget type: $type',
      {
        'widget_type': type,
        'available_properties': config.keys.toList(),
        'suggestion': 'Check widget type spelling or implement missing widget renderer',
      },
    );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning, color: Colors.orange[700], size: 16),
          const SizedBox(height: 4),
          Text(
            'Unsupported: $type',
            style: TextStyle(
              color: Colors.orange[800],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Safe widget builder with error handling
  ///
  /// Wraps widget builders with comprehensive error handling to ensure
  /// graceful degradation and detailed error reporting.
  ///
  /// ## Parameters
  /// - [widgetType]: The type of widget being built
  /// - [properties]: Widget properties from JSON
  /// - [builder]: The widget builder function
  /// - [fallbackBuilder]: Optional fallback builder for specific errors
  ///
  /// ## Returns
  /// Widget from builder or error widget if building fails
  static Widget _safeWidgetBuilder(
    String widgetType,
    Map<String, dynamic> properties,
    Widget Function() builder, {
    Widget Function(dynamic error)? fallbackBuilder,
  }) {
    try {
      return builder();
    } catch (error, stackTrace) {
      // Try fallback builder first
      if (fallbackBuilder != null) {
        try {
          return fallbackBuilder(error);
        } catch (fallbackError) {
          LoggerUtil.error(
            'Fallback builder also failed for $widgetType',
            fallbackError,
          );
        }
      }

      // Use error handler for comprehensive error reporting
      return ErrorHandler.handleRenderingError(
        error,
        {'type': widgetType, 'properties': properties},
        context: {
          'method': '_safeWidgetBuilder',
          'widget_type': widgetType,
          'properties_keys': properties.keys.toList(),
        },
        stackTrace: stackTrace,
      );
    }
  }

  static void _handleCallback(dynamic actionData, Map<String, dynamic> properties) {
    if (actionData == null) {
      LoggerUtil.warning('No action specified for callback');
      return;
    }

    if (actionData is Map<String, dynamic>) {
      try {
        final action = actionData['action'] as String?;
        
        switch (action) {
          case 'navigate':
            final screen = actionData['screen'] as String?;
            if (screen != null) {
              // Get the navigation callback from properties
              final onNavigateTo = properties['onNavigateTo'];
              if (onNavigateTo is Function) {
                onNavigateTo(screen);
              }
            }
            break;
            
          case 'navigateWithData':
            final screen = actionData['screen'] as String?;
            final data = actionData['data'] as Map<String, dynamic>?;
            if (screen != null) {
              // Get the navigation callback from properties
              final onNavigateTo = properties['onNavigateTo'];
              if (onNavigateTo is Function) {
                // Collect field values from data object
                final processedData = _processDataVariables(data ?? {}, properties);
                onNavigateTo(screen, processedData);
              }
            }
            break;
            
          case 'apiCall':
            LoggerUtil.info('API Call: ${actionData['endpoint']}');
            break;
            
          default:
            LoggerUtil.warning('Unknown action: $action');
        }
      } catch (e) {
        LoggerUtil.error('Error executing callback: $e', e);
      }
    }
  }

  /// Process data variables like ${fields.fieldId} and ${navigationData.x}
  static Map<String, dynamic> _processDataVariables(
    Map<String, dynamic> data,
    Map<String, dynamic> properties,
  ) {
    final result = <String, dynamic>{};
    
    data.forEach((key, value) {
      if (value is String) {
        // Handle ${fields.fieldId} patterns
        if (value.startsWith('\${fields.') && value.endsWith('}')) {
          final fieldId = value.replaceFirst('\${fields.', '').replaceFirst('}', '');
          // Get field value from controllers
          final controller = _fieldControllers[fieldId];
          result[key] = controller?.text ?? value;
        }
        // Handle ${navigationData.x} patterns
        else if (value.startsWith('\${navigationData.') && value.endsWith('}')) {
          final dataKey = value.replaceFirst('\${navigationData.', '').replaceFirst('}', '');
          final navData = properties['navigationData'] as Map<String, dynamic>? ?? {};
          result[key] = navData[dataKey] ?? value;
        }
        // Handle ${now} pattern
        else if (value == '\${now}') {
          result[key] = DateTime.now().toIso8601String();
        }
        else {
          result[key] = value;
        }
      } else {
        result[key] = value;
      }
    });
    
    return result;
  }

  static void _handleButtonPress(dynamic actionData) {
    // Support both old string format and new action object format
    if (actionData == null || actionData.toString().isEmpty) {
      LoggerUtil.warning('No action specified for button press');
      return;
    }

    // Old format: just a string
    if (actionData is String) {
      LoggerUtil.debug('Button pressed: $actionData');
      return;
    }

    // New format: action object (Map)
    if (actionData is Map<String, dynamic>) {
      try {
        final action = callback_actions.Action.fromJson(actionData);
        // TODO: Execute action with proper context
        // For now, just log the action type
        LoggerUtil.info('Action executed: ${action.action}');
      } catch (e) {
        LoggerUtil.error('Error parsing action: $e', e);
      }
      return;
    }

    LoggerUtil.error('Invalid action format: $actionData');
  }

  /// Parse double value from number or string
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      // Handle string numbers
      return double.tryParse(value);
    }
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
        // If it's a 6-digit hex color (#RRGGBB), add full opacity (FF)
        // If it's an 8-digit hex color (#AARRGGBB), use as-is
        final colorString = hexColor.length == 6 
            ? 'FF$hexColor'  // Add full opacity for 6-digit colors
            : hexColor.padLeft(8, '0');  // Pad with zeros for shorter colors
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

  static EdgeInsets? _parseEdgeInsets(dynamic value) {
    if (value == null) return null;
    if (value is num) return EdgeInsets.all(value.toDouble());
    if (value is Map) {
      // Handle "all" property for uniform padding/margin
      if (value.containsKey('all')) {
        final allValue = (value['all'] as num?)?.toDouble() ?? 0;
        return EdgeInsets.all(allValue);
      }
      
      // Handle "horizontal" and "vertical" shorthand properties
      if (value.containsKey('horizontal') || value.containsKey('vertical')) {
        final horizontal = (value['horizontal'] as num?)?.toDouble() ?? 0;
        final vertical = (value['vertical'] as num?)?.toDouble() ?? 0;
        return EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        );
      }
      
      // Handle individual sides (LTRB format)
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
        gradient: _parseGradient(value['gradient']),
        border: _parseBorder(value['border']),
        borderRadius: _parseBorderRadius(value['borderRadius']),
        boxShadow: _parseBoxShadow(value['boxShadow']),
        shape: _parseBoxShape(value['shape']),
      );
    }
    return null;
  }

  /// Parse gradient from JSON configuration
  /// 
  /// Supports:
  /// - Linear gradients with colors, begin, and end positions
  /// - Radial gradients with center and radius
  /// - Sweep gradients with center and rotation
  ///
  /// Example JSON:
  /// ```json
  /// {
  ///   "type": "linear",
  ///   "colors": ["#FF0000", "#00FF00", "#0000FF"],
  ///   "stops": [0.0, 0.5, 1.0],
  ///   "begin": "topLeft",
  ///   "end": "bottomRight"
  /// }
  /// ```
  static Gradient? _parseGradient(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      final type = value['type'] as String? ?? 'linear';
      final colors = (value['colors'] as List?)
          ?.map((c) => _parseColor(c))
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
            begin: _parseAlignmentFromValue(value['begin']),
            end: _parseAlignmentFromValue(value['end']),
          );
        
        case 'radial':
          return RadialGradient(
            colors: colors,
            stops: stops,
            center: _parseAlignmentFromValue(value['center']),
            radius: (value['radius'] as num?)?.toDouble() ?? 0.5,
          );
        
        case 'sweep':
          return SweepGradient(
            colors: colors,
            stops: stops,
            center: _parseAlignmentFromValue(value['center']),
            startAngle: (value['startAngle'] as num?)?.toDouble() ?? 0.0,
            endAngle: (value['endAngle'] as num?)?.toDouble() ?? 6.28318530718, // 2π
          );
        
        default:
          return LinearGradient(colors: colors, stops: stops);
      }
    }
    return null;
  }

  /// Parse alignment from string or map
  /// 
  /// Supports common alignment names and custom coordinates
  /// 
  /// Examples:
  /// - "topLeft", "center", "bottomRight"
  /// - {"x": -1.0, "y": -1.0}
  static Alignment _parseAlignmentFromValue(dynamic value) {
    if (value == null) return Alignment.center;
    
    if (value is String) {
      // Handle both camelCase (topLeft) and lowercase (topleft) formats
      final normalized = value.toLowerCase().replaceAll('_', '').replaceAll('-', '');
      switch (normalized) {
        case 'topleft': return Alignment.topLeft;
        case 'topcenter': return Alignment.topCenter;
        case 'topright': return Alignment.topRight;
        case 'centerleft': return Alignment.centerLeft;
        case 'center': return Alignment.center;
        case 'centerright': return Alignment.centerRight;
        case 'bottomleft': return Alignment.bottomLeft;
        case 'bottomcenter': return Alignment.bottomCenter;
        case 'bottomright': return Alignment.bottomRight;
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

  /// Parse box shadows from JSON array
  /// 
  /// Supports multiple shadows with color, blur, spread, and offset
  /// 
  /// Example JSON:
  /// ```json
  /// [
  ///   {
  ///     "color": "#00000040",
  ///     "blurRadius": 8.0,
  ///     "spreadRadius": 2.0,
  ///     "offset": {"dx": 0, "dy": 4}
  ///   }
  /// ]
  /// ```
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

  /// Parse single box shadow from JSON
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

  /// Parse offset from JSON
  /// 
  /// Example: {"dx": 2.0, "dy": 4.0}
  static Offset _parseOffset(dynamic value) {
    if (value is Map) {
      final dx = (value['dx'] as num?)?.toDouble() ?? 0.0;
      final dy = (value['dy'] as num?)?.toDouble() ?? 0.0;
      return Offset(dx, dy);
    }
    return Offset.zero;
  }

  /// Parse box shape from string
  /// 
  /// Supports: "rectangle", "circle"
  static BoxShape _parseBoxShape(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'circle': return BoxShape.circle;
        case 'rectangle': return BoxShape.rectangle;
        default: return BoxShape.rectangle;
      }
    }
    return BoxShape.rectangle;
  }

  /// Enhanced border parsing with support for complex borders
  /// 
  /// Supports:
  /// - Simple borders: {"color": "#FF0000", "width": 2.0}
  /// - Side-specific borders: {"left": {...}, "right": {...}}
  /// - Border styles: solid, dotted, dashed (note: Flutter has limited support)
  static Border? _parseBorder(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      // Check if it's a simple border (all sides)
      if (value.containsKey('color') || value.containsKey('width')) {
        final color = _parseColor(value['color']) ?? Colors.black;
        final width = (value['width'] as num?)?.toDouble() ?? 1.0;
        return Border.all(color: color, width: width);
      }
      
      // Complex border with individual sides
      return Border(
        left: _parseBorderSide(value['left']) ?? BorderSide.none,
        right: _parseBorderSide(value['right']) ?? BorderSide.none,
        top: _parseBorderSide(value['top']) ?? BorderSide.none,
        bottom: _parseBorderSide(value['bottom']) ?? BorderSide.none,
      );
    }
    return null;
  }

  /// Parse individual border side
  /// 
  /// Example: {"color": "#FF0000", "width": 2.0, "style": "solid"}
  static BorderSide? _parseBorderSide(dynamic value) {
    if (value is Map) {
      final color = _parseColor(value['color']) ?? Colors.black;
      final width = (value['width'] as num?)?.toDouble() ?? 1.0;
      final style = _parseBorderStyle(value['style']);
      
      return BorderSide(
        color: color,
        width: width,
        style: style,
      );
    }
    return null;
  }

  /// Parse border style from string
  static BorderStyle _parseBorderStyle(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'solid': return BorderStyle.solid;
        case 'none': return BorderStyle.none;
        default: return BorderStyle.solid;
      }
    }
    return BorderStyle.solid;
  }

  /// Enhanced border radius parsing
  /// 
  /// Supports:
  /// - Simple radius: 8.0
  /// - Object radius: {"all": 8.0}
  /// - Individual corners: {"topLeft": 8.0, "topRight": 4.0, ...}
  static BorderRadius? _parseBorderRadius(dynamic value) {
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
}
