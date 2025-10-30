import 'package:quicui/quicui.dart';

/// Abstract interface for real-time data sources
///
/// Backend implementations that support real-time updates should implement
/// this interface for streaming updates. Implementations that don't support
/// real-time can throw [UnimplementedError].
abstract class RealtimeSource {
  /// Subscribe to screen creation events
  ///
  /// Emits whenever a new screen is created.
  /// Throws [DataSourceException] if subscription fails.
  Stream<Screen> onScreenCreated();

  /// Subscribe to screen changes (updates)
  ///
  /// Emits whenever a screen is updated.
  /// Only emits update events, not creates or deletes.
  /// Throws [DataSourceException] if subscription fails.
  Stream<RealtimeEvent<Screen>> onScreenChanged();

  /// Subscribe to screen deletion events
  ///
  /// Emits screen ID when a screen is deleted.
  /// Throws [DataSourceException] if subscription fails.
  Stream<String> onScreenDeleted();

  /// Subscribe to all screen-related events
  ///
  /// Emits all types of events (create, update, delete) in one stream.
  /// Throws [DataSourceException] if subscription fails.
  Stream<RealtimeEvent> allEvents();

  /// Unsubscribe from all real-time events
  ///
  /// Cleans up all active subscriptions and closes streams.
  /// Safe to call multiple times.
  Future<void> unsubscribeAll();
}
