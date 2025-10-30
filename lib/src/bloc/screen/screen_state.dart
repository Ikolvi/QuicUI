/// Screen states for ScreenBloc
///
/// This module defines all states that [ScreenBloc] can emit.
/// States represent the current UI state and contain data needed by widgets.
///
/// ## State Hierarchy
///
/// ```
/// ScreenState (abstract base)
///   ├── ScreenInitial
///   ├── ScreenLoading
///   ├── ScreenLoaded (success)
///   ├── ScreenUpdating
///   ├── ScreenError (failure)
///   ├── WidgetEventHandled
///   └── ScreenCleared
/// ```
///
/// ## State Flow Diagram
///
/// ```
/// ScreenInitial
///   ↓
/// ScreenLoading → ScreenError (retry)
///   ↓
/// ScreenLoaded ← ScreenUpdating (incremental updates)
///   ↓
/// ScreenCleared (cleanup)
/// ```
///
/// ## Usage
///
/// ```dart
/// BlocBuilder<ScreenBloc, ScreenState>(
///   builder: (context, state) {
///     if (state is ScreenLoading) {
///       return LoadingWidget();
///     } else if (state is ScreenLoaded) {
///       return UIRenderer(screenData: state.screenData);
///     } else if (state is ScreenError) {
///       return ErrorWidget(message: state.message);
///     }
///     return SizedBox.shrink();
///   },
/// );
/// ```
///
/// See also:
/// - [ScreenEvent]: Events that trigger state changes
/// - [ScreenBloc]: State manager

import 'package:equatable/equatable.dart';

/// Base state for ScreenBloc
///
/// All states emitted by [ScreenBloc] extend this class.
/// Uses [Equatable] for efficient state comparison and value semantics.
///
/// ## State Properties
///
/// State comparison is based on `props`:
/// - Two states with same props are equal
/// - UI updates only when state changes (different props)
/// - Enables efficient widget rebuilds
///
/// See also:
/// - [ScreenEvent]: Triggers state changes
/// - [ScreenBloc]: Emits states
abstract class ScreenState extends Equatable {
  const ScreenState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any screen is loaded
///
/// Emitted when [ScreenBloc] is first created.
/// Indicates no screen is currently loaded and no operations are in progress.
///
/// ## Typical Lifecycle
/// ```
/// BlocBuilder sees ScreenInitial
///   ↓
/// Add FetchScreenEvent
///   ↓
/// Bloc emits ScreenLoading
///   ↓
/// Bloc emits ScreenLoaded (or ScreenError)
/// ```
///
/// ## Example
/// ```dart
/// if (state is ScreenInitial) {
///   // Optionally show splash screen or trigger initial load
///   context.read<ScreenBloc>().add(
///     FetchScreenEvent(screenId: 'home_screen'),
///   );
///   return SplashScreen();
/// }
/// ```
///
/// See also:
/// - [ScreenLoading]: Next typical state
/// - [FetchScreenEvent]: Event to transition from initial state
class ScreenInitial extends ScreenState {
  const ScreenInitial();
}

/// Loading state while fetching or updating screen
///
/// Emitted when:
/// - [FetchScreenEvent] starts loading a screen
/// - [UpdateScreenEvent] starts updating the screen
/// - [HandleWidgetEventEvent] starts processing an event
///
/// Indicates an async operation is in progress.
/// The UI should show a loading indicator while in this state.
///
/// ## Parameters
/// - [screenId]: Optional ID of the screen being loaded (for progress tracking)
///
/// ## Example
/// ```dart
/// if (state is ScreenLoading) {
///   return Center(
///     child: CircularProgressIndicator(),
///   );
/// }
/// ```
///
/// ## Timeline
/// - Duration: Typically 100ms - 5 seconds
/// - Followed by: ScreenLoaded or ScreenError
///
/// See also:
/// - [ScreenLoaded]: Success state
/// - [ScreenError]: Failure state
class ScreenLoading extends ScreenState {
  /// Optional ID of the screen being loaded
  ///
  /// Useful for:
  /// - Progress tracking in multi-screen apps
  /// - Logging and debugging
  /// - Showing which screen is loading
  final String? screenId;

  const ScreenLoading({this.screenId});

  @override
  List<Object?> get props => [screenId];
}

/// Screen successfully loaded and ready for display
///
/// Emitted when:
/// - Screen fetch completes successfully
/// - Screen update completes successfully
/// - Widget event handling completes successfully
///
/// Contains the screen data needed to render the UI.
/// This is the "happy path" state where UI is displayed normally.
///
/// ## Parameters
/// - [screenData]: Complete screen configuration and state
///   - `widgets`: Array of widget configurations
///   - `layout`: Screen layout structure
///   - `state`: Current screen state values
///   - `metadata`: Screen metadata (title, theme, etc.)
/// - [loadedAt]: Timestamp when screen was loaded (for cache validation)
///
/// ## Example
/// ```dart
/// if (state is ScreenLoaded) {
///   return UIRenderer(
///     screenData: state.screenData,
///     onWidgetEvent: (widgetId, eventName, eventData) {
///       context.read<ScreenBloc>().add(
///         HandleWidgetEventEvent(
///           widgetId: widgetId,
///           eventName: eventName,
///           eventData: eventData,
///         ),
///       );
///     },
///   );
/// }
/// ```
///
/// ## Data Structure
/// ```json
/// {
///   "id": "home_screen",
///   "title": "Home",
///   "widgets": [...],
///   "layout": {...},
///   "state": {...},
///   "metadata": {...}
/// }
/// ```
///
/// See also:
/// - [ScreenLoading]: Loading state
/// - [ScreenUpdating]: Incremental update state
/// - [UIRenderer]: Renders this data
class ScreenLoaded extends ScreenState {
  /// Complete screen configuration and state
  ///
  /// Contains all data needed to render widgets and manage UI state.
  /// Structure depends on screen type but typically includes:
  /// - Widget definitions
  /// - Layout information
  /// - Current state values
  /// - Metadata and styling
  final Map<String, dynamic> screenData;

  /// Timestamp when screen was loaded
  ///
  /// Used for:
  /// - Cache validation
  /// - Refresh timeout detection
  /// - Stale data warnings
  final DateTime loadedAt;

  const ScreenLoaded({
    required this.screenData,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [screenData, loadedAt];
}

/// Error state when screen operation fails
///
/// Emitted when:
/// - Screen fetch fails (network error, not found, etc.)
/// - Screen update fails
/// - Widget event handling fails
///
/// Indicates an error occurred. UI should display error message and recovery options.
///
/// ## Parameters
/// - [message]: User-friendly error description
/// - [error]: Original error object (for logging)
/// - [stackTrace]: Stack trace for debugging
///
/// ## Error Types
/// - Network errors: No internet, timeout
/// - Server errors: 404, 500, etc.
/// - Data errors: Invalid JSON, missing fields
/// - Local errors: File I/O, database errors
///
/// ## Example
/// ```dart
/// if (state is ScreenError) {
///   return ErrorScreen(
///     message: state.message,
///     onRetry: () {
///       context.read<ScreenBloc>().add(
///         RetryScreenFetchEvent(),
///       );
///     },
///   );
/// }
/// ```
///
/// ## Recovery
/// User can retry via [RetryScreenFetchEvent] or pull-to-refresh.
///
/// See also:
/// - [RetryScreenFetchEvent]: Event to retry failed operation
/// - [ScreenLoading]: Retry will transition through this
class ScreenError extends ScreenState {
  /// User-friendly error description
  ///
  /// Should be suitable for display in UI:
  /// - ✓ "Network timeout - please try again"
  /// - ✗ "SocketException: connection failed"
  final String message;

  /// Original error object for logging
  ///
  /// May be Exception, Error, or other throwable.
  /// Use for analytics and debugging.
  final dynamic error;

  /// Stack trace for debugging
  ///
  /// Captured when error occurred.
  /// Use for log aggregation services.
  final StackTrace? stackTrace;

  const ScreenError({
    required this.message,
    this.error,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, error, stackTrace];
}

/// State indicating screen is being updated
///
/// Emitted when:
/// - [UpdateScreenEvent] starts incremental update
/// - Real-time updates received from server
/// - Batch updates applied
///
/// Indicates partial update is in progress. Previous state data is preserved.
/// UI may show updated and unchanged widgets simultaneously.
///
/// ## Parameters
/// - [previousData]: Screen data before update (for rollback if needed)
///
/// ## Use Cases
/// - Real-time collaboration (multiple users editing)
/// - Form field validation updates
/// - Conditional widget visibility changes
/// - State synchronization with server
///
/// ## Example
/// ```dart
/// if (state is ScreenUpdating) {
///   return TransitionWidget(
///     to: state,
///     child: UIRenderer(screenData: state.previousData),
///   );
/// }
/// ```
///
/// ## Typical Flow
/// ```
/// ScreenLoaded(oldData)
///   ↓
/// ScreenUpdating(previousData: oldData)
///   ↓
/// ScreenLoaded(newData)
/// ```
///
/// See also:
/// - [ScreenLoaded]: State after update completes
/// - [UpdateScreenEvent]: Triggers updates
class ScreenUpdating extends ScreenState {
  /// Screen data before update
  ///
  /// Preserved during update for:
  /// - Rollback on error
  /// - Transition animation reference
  /// - Diff calculation
  final Map<String, dynamic> previousData;

  const ScreenUpdating(this.previousData);

  @override
  List<Object?> get props => [previousData];
}

/// State after a widget event is handled
///
/// Emitted after [HandleWidgetEventEvent] completes successfully.
/// Includes details about which widget event was handled.
///
/// ## Parameters
/// - [widgetId]: ID of widget that triggered the event
/// - [eventName]: Name of the event (onPressed, onChanged, etc.)
/// - [eventData]: Optional data from the event
///
/// ## Purpose
/// - Confirmation that event was processed
/// - State restoration after side effects
/// - Event tracking and analytics
///
/// ## Example
/// ```dart
/// if (state is WidgetEventHandled) {
///   ScaffoldMessenger.of(context).showSnackBar(
///     SnackBar(
///       content: Text('Button ${state.widgetId} pressed'),
///     ),
///   );
/// }
/// ```
///
/// ## Follow-up
/// UI typically transitions to [ScreenLoaded] after showing confirmation.
///
/// See also:
/// - [HandleWidgetEventEvent]: Event that triggers this
/// - [ScreenLoaded]: Typical next state
class WidgetEventHandled extends ScreenState {
  /// ID of widget that triggered the event
  final String widgetId;

  /// Name of the event
  final String eventName;

  /// Optional data from the event
  final dynamic eventData;

  const WidgetEventHandled({
    required this.widgetId,
    required this.eventName,
    this.eventData,
  });

  @override
  List<Object?> get props => [widgetId, eventName, eventData];
}

/// State indicating screen has been cleared
///
/// Emitted when:
/// - User navigates away from screen
/// - [ClearScreenEvent] is dispatched
/// - App goes to background (optional)
///
/// Indicates screen is no longer needed and resources can be released.
///
/// ## Cleanup Operations
/// - Cancel pending network requests
/// - Clear event listeners
/// - Release memory
/// - Stop animations
///
/// ## Example
/// ```dart
/// if (state is ScreenCleared) {
///   return SizedBox.shrink(); // Hide UI
/// }
/// ```
///
/// ## Typical Use Case
/// ```
/// BlocBuilder<ScreenBloc, ScreenState>(
///   builder: (context, state) {
///     if (state is ScreenCleared) {
///       return SizedBox.shrink();
///     }
///     // ... render other states
///   },
/// );
/// ```
///
/// See also:
/// - [ClearScreenEvent]: Event to transition to cleared state
/// - [ScreenInitial]: Typical next state after navigation
class ScreenCleared extends ScreenState {
  const ScreenCleared();
}
