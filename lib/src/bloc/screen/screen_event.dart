/// Screen events for ScreenBloc
///
/// This module defines all events that can be dispatched to the [ScreenBloc].
/// Events represent user actions or system events that trigger state changes.
///
/// ## Event Hierarchy
///
/// ```
/// ScreenEvent (abstract base)
///   ├── FetchScreenEvent
///   ├── UpdateScreenEvent
///   ├── HandleWidgetEventEvent
///   ├── ClearScreenEvent
///   └── RetryScreenFetchEvent
/// ```
///
/// ## Usage
///
/// ```dart
/// // Dispatch event to BLoC
/// context.read<ScreenBloc>().add(
///   FetchScreenEvent(screenId: 'home_screen'),
/// );
/// ```
///
/// See also:
/// - [ScreenBloc]: Event handler
/// - [ScreenState]: State definitions

import 'package:equatable/equatable.dart';

/// Base event class for ScreenBloc
///
/// All events dispatched to [ScreenBloc] must extend this class.
/// Uses [Equatable] for equality comparison and value semantics.
///
/// ## Event Lifecycle
///
/// 1. Event created: `FetchScreenEvent(...)`
/// 2. Event added to BLoC: `bloc.add(event)`
/// 3. BLoC receives event: `_onFetchScreen()`
/// 4. New state emitted: `emit(state)`
/// 5. UI updates via `BlocBuilder`
///
/// See also:
/// - [ScreenBloc]: Handles events
/// - [ScreenState]: Resulting states
abstract class ScreenEvent extends Equatable {
  const ScreenEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch a screen by ID
///
/// Triggers loading of a screen definition from the repository.
/// Used when initializing the app or navigating to a new screen.
///
/// ## Parameters
/// - [screenId]: Unique identifier of the screen to fetch
/// - [forceRefresh]: Whether to bypass cache and fetch fresh data
///
/// ## Emits
/// - [ScreenLoading]: When fetch starts
/// - [ScreenLoaded]: When fetch completes successfully
/// - [ScreenError]: When fetch fails
///
/// ## Example
/// ```dart
/// // Fetch screen from cache or remote
/// context.read<ScreenBloc>().add(
///   FetchScreenEvent(screenId: 'home_screen'),
/// );
///
/// // Force refresh from remote
/// context.read<ScreenBloc>().add(
///   FetchScreenEvent(
///     screenId: 'home_screen',
///     forceRefresh: true,
///   ),
/// );
/// ```
///
/// See also:
/// - [UpdateScreenEvent]: For updating existing screen
/// - [RetryScreenFetchEvent]: For retrying failed fetch
class FetchScreenEvent extends ScreenEvent {
  /// Unique identifier of the screen to fetch
  final String screenId;

  /// Whether to bypass cache and fetch fresh data
  ///
  /// When true, ignores locally cached screen and fetches
  /// from remote source (Supabase).
  /// When false (default), uses cache if available.
  final bool forceRefresh;

  const FetchScreenEvent({
    required this.screenId,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [screenId, forceRefresh];
}

/// Event to update the current screen
///
/// Updates the state of the currently loaded screen.
/// Used when receiving real-time updates from the server
/// or when user actions modify the screen state.
///
/// ## Parameters
/// - [screenData]: New screen data to apply
///
/// ## Emits
/// - [ScreenUpdating]: When update starts
/// - [ScreenLoaded]: When update completes
/// - [ScreenError]: When update fails
///
/// ## Example
/// ```dart
/// final newData = {
///   'widgets': [...],
///   'state': {...},
/// };
/// context.read<ScreenBloc>().add(
///   UpdateScreenEvent(newData),
/// );
/// ```
///
/// See also:
/// - [FetchScreenEvent]: For loading new screen
/// - [HandleWidgetEventEvent]: For widget interactions
class UpdateScreenEvent extends ScreenEvent {
  /// New screen data to apply
  ///
  /// Typically contains updated widget configuration,
  /// state values, or other screen-level properties.
  final Map<String, dynamic> screenData;

  const UpdateScreenEvent(this.screenData);

  @override
  List<Object?> get props => [screenData];
}

/// Event to handle screen widget events
///
/// Processes interactions on individual widgets (button taps, form submissions, etc.).
/// The BLoC handles these events and may update state or trigger external actions.
///
/// ## Parameters
/// - [widgetId]: ID of the widget that triggered the event
/// - [eventName]: Name of the event (e.g., 'onPressed', 'onChanged')
/// - [eventData]: Optional data associated with the event
///
/// ## Emits
/// - [ScreenUpdating]: When processing starts
/// - [ScreenLoaded]: When processing completes
/// - [ScreenError]: When processing fails
///
/// ## Example
/// ```dart
/// // Button press event
/// context.read<ScreenBloc>().add(
///   HandleWidgetEventEvent(
///     widgetId: 'submit_button',
///     eventName: 'onPressed',
///   ),
/// );
///
/// // Value change event
/// context.read<ScreenBloc>().add(
///   HandleWidgetEventEvent(
///     widgetId: 'name_field',
///     eventName: 'onChanged',
///     eventData: 'new value',
///   ),
/// );
/// ```
///
/// See also:
/// - [ScreenBloc]: Event processor
/// - [UIRenderer]: Widget event binding
class HandleWidgetEventEvent extends ScreenEvent {
  /// ID of the widget that triggered the event
  ///
  /// Must match the 'id' property in the widget configuration.
  final String widgetId;

  /// Name of the event
  ///
  /// Common values:
  /// - 'onPressed': Button press
  /// - 'onChanged': Value change (input fields, sliders, etc.)
  /// - 'onTap': General tap
  /// - 'onSubmitted': Form submission
  final String eventName;

  /// Optional data associated with the event
  ///
  /// Type depends on event:
  /// - String for text input events
  /// - bool for toggle events
  /// - num for slider events
  /// - Any for custom events
  final dynamic eventData;

  const HandleWidgetEventEvent({
    required this.widgetId,
    required this.eventName,
    this.eventData,
  });

  @override
  List<Object?> get props => [widgetId, eventName, eventData];
}

/// Event to clear the current screen
class ClearScreenEvent extends ScreenEvent {
  const ClearScreenEvent();
}

/// Event to handle errors
class ScreenErrorEvent extends ScreenEvent {
  final String errorMessage;

  const ScreenErrorEvent(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

/// Event to retry fetching
class RetryScreenFetchEvent extends ScreenEvent {
  final String screenId;

  const RetryScreenFetchEvent(this.screenId);

  @override
  List<Object?> get props => [screenId];
}
