/// Sync events for synchronization with backend
import 'package:equatable/equatable.dart';

/// Base sync event
abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

/// Event to start synchronization
class StartSyncEvent extends SyncEvent {
  final bool isManual;

  const StartSyncEvent({this.isManual = true});

  @override
  List<Object?> get props => [isManual];
}

/// Event triggered when sync completes
class SyncCompleteEvent extends SyncEvent {
  final int itemsCount;
  final DateTime syncedAt;

  const SyncCompleteEvent({
    required this.itemsCount,
    required this.syncedAt,
  });

  @override
  List<Object?> get props => [itemsCount, syncedAt];
}

/// Event for sync error
class SyncErrorEvent extends SyncEvent {
  final String errorMessage;

  const SyncErrorEvent(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

/// Event to retry failed sync
class RetrySyncEvent extends SyncEvent {
  const RetrySyncEvent();
}

/// Event to pause sync
class PauseSyncEvent extends SyncEvent {
  const PauseSyncEvent();
}

/// Event to resume sync
class ResumeSyncEvent extends SyncEvent {
  const ResumeSyncEvent();
}

/// Event for conflict resolution
class ResolveConflictEvent extends SyncEvent {
  final String conflictId;
  final Map<String, dynamic> resolution;

  const ResolveConflictEvent({
    required this.conflictId,
    required this.resolution,
  });

  @override
  List<Object?> get props => [conflictId, resolution];
}

/// Event to clear sync state
class ClearSyncStateEvent extends SyncEvent {
  const ClearSyncStateEvent();
}
