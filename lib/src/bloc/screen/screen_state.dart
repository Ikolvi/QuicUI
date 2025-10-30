/// Screen states
import 'package:equatable/equatable.dart';

/// Base state for ScreenBloc
abstract class ScreenState extends Equatable {
  const ScreenState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ScreenInitial extends ScreenState {
  const ScreenInitial();
}

/// Loading state
class ScreenLoading extends ScreenState {
  final String? screenId;

  const ScreenLoading({this.screenId});

  @override
  List<Object?> get props => [screenId];
}

/// Screen loaded successfully
class ScreenLoaded extends ScreenState {
  final Map<String, dynamic> screenData;
  final DateTime loadedAt;

  const ScreenLoaded({
    required this.screenData,
    required this.loadedAt,
  });

  @override
  List<Object?> get props => [screenData, loadedAt];
}

/// Screen error state
class ScreenError extends ScreenState {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;

  const ScreenError({
    required this.message,
    this.error,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, error, stackTrace];
}

/// Widget event handled
class WidgetEventHandled extends ScreenState {
  final String widgetId;
  final String eventName;
  final dynamic eventData;

  const WidgetEventHandled({
    required this.widgetId,
    required this.eventName,
    this.eventData,
  });

  @override
  List<Object?> get props => [widgetId, eventName, eventData];
}

/// Screen cleared
class ScreenCleared extends ScreenState {
  const ScreenCleared();
}

/// Screen updating
class ScreenUpdating extends ScreenState {
  final Map<String, dynamic> previousData;

  const ScreenUpdating(this.previousData);

  @override
  List<Object?> get props => [previousData];
}
