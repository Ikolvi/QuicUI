/// Screen events
import 'package:equatable/equatable.dart';

/// Base event class for ScreenBloc
abstract class ScreenEvent extends Equatable {
  const ScreenEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch a screen by ID
class FetchScreenEvent extends ScreenEvent {
  final String screenId;
  final bool forceRefresh;

  const FetchScreenEvent({
    required this.screenId,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [screenId, forceRefresh];
}

/// Event to update the current screen
class UpdateScreenEvent extends ScreenEvent {
  final Map<String, dynamic> screenData;

  const UpdateScreenEvent(this.screenData);

  @override
  List<Object?> get props => [screenData];
}

/// Event to handle screen widget events
class HandleWidgetEventEvent extends ScreenEvent {
  final String widgetId;
  final String eventName;
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
