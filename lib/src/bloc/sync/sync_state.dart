/// Sync states for synchronization management
import 'package:equatable/equatable.dart';

/// Base sync state
abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

/// Sync idle state
class SyncIdle extends SyncState {
  final DateTime? lastSyncAt;

  const SyncIdle({this.lastSyncAt});

  @override
  List<Object?> get props => [lastSyncAt];
}

/// Sync in progress
class SyncInProgress extends SyncState {
  final int itemsSynced;
  final int totalItems;
  final String? currentOperation;

  const SyncInProgress({
    this.itemsSynced = 0,
    this.totalItems = 0,
    this.currentOperation,
  });

  @override
  List<Object?> get props => [itemsSynced, totalItems, currentOperation];

  double get progress =>
      totalItems > 0 ? itemsSynced / totalItems : 0.0;
}

/// Sync completed successfully
class SyncCompleted extends SyncState {
  final int itemsCount;
  final DateTime syncedAt;
  final Duration syncDuration;

  const SyncCompleted({
    required this.itemsCount,
    required this.syncedAt,
    required this.syncDuration,
  });

  @override
  List<Object?> get props => [itemsCount, syncedAt, syncDuration];
}

/// Sync failed with error
class SyncFailed extends SyncState {
  final String errorMessage;
  final dynamic error;
  final StackTrace? stackTrace;

  const SyncFailed({
    required this.errorMessage,
    this.error,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [errorMessage, error, stackTrace];
}

/// Sync paused
class SyncPaused extends SyncState {
  final int itemsSynced;

  const SyncPaused({this.itemsSynced = 0});

  @override
  List<Object?> get props => [itemsSynced];
}

/// Conflict detected during sync
class SyncConflict extends SyncState {
  final String conflictId;
  final Map<String, dynamic> localVersion;
  final Map<String, dynamic> remoteVersion;

  const SyncConflict({
    required this.conflictId,
    required this.localVersion,
    required this.remoteVersion,
  });

  @override
  List<Object?> get props => [conflictId, localVersion, remoteVersion];
}

/// Offline - waiting for connection
class SyncOffline extends SyncState {
  final int pendingItems;

  const SyncOffline({this.pendingItems = 0});

  @override
  List<Object?> get props => [pendingItems];
}
