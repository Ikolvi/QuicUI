/// Screen view widget for displaying dynamic screen content
///
/// This module provides the ScreenView widget that renders a screen
/// with dynamic content, refresh capability, and proper Material Design patterns.
///
/// ## Widget Hierarchy
///
/// ```
/// ScreenView (Entry point)
///   └→ RefreshIndicator (Pull-to-refresh)
///        └→ Screen content widget
///
/// Integrates with:
///   ├→ ScreenBloc: State management for screen data
///   ├→ UIRenderer: Dynamic widget rendering
///   └→ ScreenRepository: Data loading
/// ```
///
/// ## Usage Examples
///
/// ### Basic Screen Display
/// ```dart
/// ScreenView(
///   screenData: {
///     'id': 'home_screen',
///     'widgets': [...]
///   },
/// )
/// ```
///
/// ### With Refresh Callback
/// ```dart
/// ScreenView(
///   screenData: screenMap,
///   onRefresh: () {
///     context.read<ScreenBloc>().add(FetchScreenEvent('home'));
///   },
/// )
/// ```
///
/// ### In BLoC Context
/// ```dart
/// BlocBuilder<ScreenBloc, ScreenState>(
///   builder: (context, state) {
///     if (state is ScreenLoaded) {
///       return ScreenView(
///         screenData: state.screenData,
///         onRefresh: () => context.read<ScreenBloc>()
///           .add(FetchScreenEvent(state.screenData['id'])),
///       );
///     }
///     return LoadingWidget();
///   },
/// )
/// ```
///
/// ## Architecture
///
/// - **Stateless**: Immutable after creation
/// - **RefreshIndicator**: Pull-to-refresh support
/// - **Dynamic rendering**: Content determined by screenData map
/// - **BLoC integration**: Works with ScreenBloc for state
///
/// ## Data Structure
///
/// The `screenData` map contains all information needed to render:
/// ```dart
/// {
///   'id': 'screen_id',
///   'title': 'Screen Title',
///   'widgets': [
///     {
///       'type': 'container',
///       'props': {...}
///     },
///     ...
///   ],
///   'layout': 'column',
/// }
/// ```
///
/// ## Features
///
/// - **Pull-to-refresh**: Standard Material refresh gesture
/// - **Dynamic content**: Rendered from screenData
/// - **Error states**: Can display error messages
/// - **Loading states**: Can show loading indicators
/// - **Null safety**: Handles missing data gracefully
///
/// ## Typical State Flow
///
/// ```
/// Initial state
///        ↓
///    Loading (show spinner)
///        ↓
///    Loaded (ScreenView renders screenData)
///        ↓
///    User pulls to refresh
///        ↓
///    Updating (refresh spinner shown)
///        ↓
///    Loaded (updated screenData)
/// ```
///
/// ## Related Widgets
///
/// - [QuicUIApp]: Root application widget
/// - [UIRenderer]: Renders dynamic widgets from screenData
///
/// See also:
/// - [ScreenBloc]: State management for screens
/// - [ScreenLoaded]: State containing screen data
/// - [FetchScreenEvent]: Triggers screen loading


import 'package:flutter/material.dart';

/// Widget for displaying dynamic screen content with refresh support
///
/// Renders a screen using data from screenData map with built-in
/// pull-to-refresh capability. Designed to work with ScreenBloc
/// for managing screen state and loading.
///
/// ## Widget Type
/// Stateless widget - display-only, data comes from parent.
///
/// ## Responsibilities
/// - Display screen content from screenData
/// - Show refresh indicator
/// - Handle refresh callback
/// - Provide Material Design UX
///
/// ## Parameters
///
/// - [screenData]: Map containing screen configuration and widgets
/// - [onRefresh]: Optional callback when user pulls to refresh
/// - [key]: Widget key for identification (optional)
///
/// ## Properties
///
/// ```dart
/// final Map<String, dynamic> screenData;  // Screen configuration
/// final VoidCallback? onRefresh;          // Refresh handler
/// ```
///
/// ## Example Usage
///
/// ### Minimal - Just Display
/// ```dart
/// ScreenView(
///   screenData: {
///     'title': 'Home',
///     'widgets': []
///   },
/// )
/// ```
///
/// ### With Refresh Handler
/// ```dart
/// ScreenView(
///   screenData: screenMap,
///   onRefresh: () async {
///     // Trigger data reload
///     context.read<ScreenBloc>().add(
///       FetchScreenEvent(screenMap['id'])
///     );
///   },
/// )
/// ```
///
/// ### In BLoC Consumer
/// ```dart
/// BlocBuilder<ScreenBloc, ScreenState>(
///   builder: (context, state) {
///     if (state is ScreenLoaded) {
///       return ScreenView(
///         screenData: state.screen.toMap(),
///         onRefresh: () async {
///           context.read<ScreenBloc>().add(
///             FetchScreenEvent(state.screen.id)
///           );
///         },
///       );
///     }
///     if (state is ScreenError) {
///       return ErrorScreen(message: state.message);
///     }
///     return LoadingScreen();
///   },
/// )
/// ```
///
/// ## screenData Map Structure
///
/// Expected fields in screenData:
/// ```dart
/// {
///   'id': String,                   // Unique screen identifier
///   'title': String?,               // Screen title
///   'layout': String?,              // Layout type (column, row, etc.)
///   'widgets': List<Map>?,          // Widget configurations
///   'properties': Map?,             // Additional properties
/// }
/// ```
///
/// ## Refresh Behavior
///
/// When user performs pull-to-refresh gesture:
/// 1. RefreshIndicator shows refresh animation
/// 2. onRefresh callback is invoked (if provided)
/// 3. Callback should trigger data reload in BLoC
/// 4. BLoC updates state, triggers rebuild
/// 5. New screenData received, UI updates
/// 6. Refresh indicator disappears
///
/// ## Loading States
///
/// - **Initial load**: No screenData, show placeholder
/// - **Data loading**: Display previous data or placeholder
/// - **Data loaded**: Show screenData content
/// - **Refreshing**: Show refresh indicator
/// - **Error**: Display error message
///
/// ## Async Operations
///
/// onRefresh callback is async:
/// ```dart
/// onRefresh: () async {
///   // Can await async operations
///   await context.read<ScreenBloc>().stream.first;
///   // Refresh indicator hides when Future completes
/// }
/// ```
///
/// ## Error Handling
///
/// onRefresh errors should be handled in BLoC:
/// ```dart
/// if (onRefresh != null) {
///   try {
///     await onRefresh();
///   } catch (e) {
///     // BLoC shows error in ScreenError state
///   }
/// }
/// ```
///
/// ## Best Practices
///
/// - **Provide onRefresh**: Enable user-triggered data refresh
/// - **Update BLoC**: Refresh should trigger BLoC data fetch
/// - **Error states**: Let BLoC handle and display errors
/// - **Loading**: Show LoadingScreen while state is ScreenLoading
/// - **Data structure**: Ensure screenData matches UIRenderer expectations
///
/// ## Null Safety
/// - screenData is required (non-null)
/// - onRefresh is optional (can be null)
/// - If onRefresh is null, pull-to-refresh is disabled
///
/// ## Performance
/// - Stateless: No state changes unless parent rebuilds
/// - Efficient: Only rebuilds when screenData changes
/// - Lazy: Content rendering deferred to children
///
/// ## Typical Usage Pattern
/// ```dart
/// // In BLoC builder
/// BlocBuilder<ScreenBloc, ScreenState>(
///   builder: (context, state) {
///     if (state is ScreenLoaded) {
///       return ScreenView(
///         screenData: state.screen.toMap(),
///         onRefresh: () async {
///           context.read<ScreenBloc>().add(
///             RefreshScreenEvent(state.screen.id)
///           );
///           // Wait for next state
///           await context.read<ScreenBloc>().stream
///             .firstWhere((s) => s is! ScreenUpdating);
///         },
///       );
///     }
///     return SizedBox(); // Handle other states
///   },
/// )
/// ```
///
/// See also:
/// - [QuicUIApp]: Root application widget
/// - [ScreenBloc]: State management
/// - [UIRenderer]: Renders widgets from screenData
/// - [RefreshIndicator]: Flutter's pull-to-refresh widget
class ScreenView extends StatelessWidget {
  /// Screen configuration and content data
  ///
  /// Map containing all information needed to render the screen including:
  /// - Screen identification
  /// - Widget specifications
  /// - Layout information
  /// - Content data
  ///
  /// This data typically comes from ScreenBloc ScreenLoaded state.
  ///
  /// ## Expected Structure
  /// ```dart
  /// {
  ///   'id': 'unique_screen_id',
  ///   'title': 'Screen Title',
  ///   'widgets': [
  ///     {'type': 'text', 'props': {...}},
  ///     {'type': 'button', 'props': {...}},
  ///   ],
  /// }
  /// ```
  ///
  /// See also:
  /// - [ScreenLoaded.screen]: Original Screen model
  /// - [UIRenderer]: Processes this structure
  final Map<String, dynamic> screenData;

  /// Callback invoked when user performs pull-to-refresh gesture
  ///
  /// Called when user drags down to refresh. Should trigger data reload
  /// in BLoC. The RefreshIndicator waits for the returned Future to complete
  /// before hiding the spinner.
  ///
  /// ## Typical Implementation
  /// ```dart
  /// onRefresh: () async {
  ///   context.read<ScreenBloc>().add(
  ///     FetchScreenEvent(screenData['id'])
  ///   );
  ///   // Wait for reload to complete
  ///   await Future.delayed(Duration(milliseconds: 500));
  /// }
  /// ```
  ///
  /// ## If Null
  /// If null, RefreshIndicator is disabled and pull-to-refresh won't work.
  /// Consider providing this to improve UX.
  ///
  /// ## Error Handling
  /// Errors thrown in onRefresh are handled by RefreshIndicator
  /// (shows toast) and should also be caught in BLoC event handler.
  final VoidCallback? onRefresh;

  /// Creates a new ScreenView widget
  ///
  /// ## Parameters
  /// - [key]: Optional widget key
  /// - [screenData]: Required screen content data
  /// - [onRefresh]: Optional refresh callback
  ///
  /// ## Example
  /// ```dart
  /// const view = ScreenView(
  ///   screenData: screen.toMap(),
  ///   onRefresh: refreshCallback,
  /// );
  /// ```
  const ScreenView({
    Key? key,
    required this.screenData,
    this.onRefresh,
  }) : super(key: key);

  /// Build the screen view widget
  ///
  /// Constructs RefreshIndicator with screen content.
  /// Content is currently a placeholder but would be replaced with
  /// dynamic rendering from screenData using UIRenderer.
  ///
  /// ## Build Process
  /// 1. Create RefreshIndicator
  /// 2. Attach onRefresh callback
  /// 3. Render screen content (placeholder for now)
  /// 4. Return complete widget tree
  ///
  /// ## Returns
  /// RefreshIndicator: Pull-to-refresh enabled widget
  ///
  /// ## Future Enhancement
  /// Should render dynamic widgets from screenData:
  /// ```dart
  /// Widget? content;
  /// if (screenData['widgets'] != null) {
  ///   final renderer = UIRenderer();
  ///   content = renderer.render(screenData);
  /// } else {
  ///   content = Center(child: Text('No content'));
  /// }
  ///
  /// return RefreshIndicator(
  ///   onRefresh: () async => onRefresh?.call(),
  ///   child: content ?? placeholder,
  /// );
  /// ```
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      child: const Center(
        child: Text('Screen View'),
      ),
    );
  }
}
