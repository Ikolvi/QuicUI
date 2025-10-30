/// Sync states representing synchronization status and data
///
/// This module defines all states representing different stages of the
/// offline-first synchronization process. States transition based on sync
/// events and represent the current sync operation status.
///
/// ## State Architecture
///
/// ```
/// SyncState (Base class)
///   ├→ SyncIdle: No active sync operation
///   ├→ SyncInProgress: Sync running, tracking progress
///   ├→ SyncCompleted: Sync succeeded with results
///   ├→ SyncFailed: Sync encountered error
///   ├→ SyncPaused: Sync paused, can resume
///   ├→ SyncConflict: Conflict detected, resolution needed
///   └→ SyncOffline: No network connection, waiting
/// ```
///
/// ## State Machine
///
/// ```
/// SyncIdle
///    ↓ (StartSyncEvent)
/// SyncInProgress
///    ↓ (success)
/// SyncCompleted
///    ↓ (after 500ms)
/// SyncIdle
///
/// SyncInProgress
///    ↓ (error)
/// SyncFailed
///    ↓ (auto-retry or RetrySyncEvent)
/// SyncInProgress
///
/// SyncInProgress
///    ↓ (PauseSyncEvent)
/// SyncPaused
///    ↓ (ResumeSyncEvent)
/// SyncInProgress
///
/// SyncInProgress
///    ↓ (conflict detected)
/// SyncConflict
///    ↓ (ResolveConflictEvent)
/// SyncInProgress
///
/// Any state
///    ↓ (no network)
/// SyncOffline
///    ↓ (connection restored)
/// SyncIdle
/// ```
///
/// ## UI Patterns
///
/// ### Show/Hide Sync Indicator
/// ```dart
/// BlocBuilder<SyncBloc, SyncState>(
///   builder: (context, state) {
///     if (state is SyncInProgress) {
///       return SizedBox(
///         height: 2,
///         child: LinearProgressIndicator(
///           value: state.progress,
///         ),
///       );
///     }
///     return SizedBox.shrink();
///   },
/// )
/// ```
///
/// ### Handle Sync Errors
/// ```dart
/// BlocListener<SyncBloc, SyncState>(
///   listenWhen: (previous, current) => current is SyncFailed,
///   listener: (context, state) {
///     final failedState = state as SyncFailed;
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text(failedState.errorMessage))
///     );
///   },
/// )
/// ```
///
/// ## Testing States
///
/// ```dart
/// // Mock various sync states
/// test('shows loading on SyncInProgress', () {
///   final state = SyncInProgress(itemsSynced: 5, totalItems: 10);
///   expect(state.progress, 0.5);
/// });
///
/// test('shows completion message', () {
///   final state = SyncCompleted(
///     itemsCount: 15,
///     syncedAt: DateTime.now(),
///     syncDuration: Duration(seconds: 5),
///   );
///   expect(state.itemsCount, 15);
/// });
/// ```
///
/// See also:
/// - [SyncEvent]: Events triggering state changes
/// - [SyncBloc]: State management and event handlers


import 'package:equatable/equatable.dart';

/// Base class for all synchronization states
///
/// All sync states inherit from this abstract class.
/// Represents different stages of the sync lifecycle.
///
/// Uses Equatable for value-based equality:
/// ```dart
/// state1 = SyncIdle(lastSyncAt: time);
/// state2 = SyncIdle(lastSyncAt: time);
/// state1 == state2  // true (same lastSyncAt)
/// ```
///
/// ## State Immutability
///
/// All states are immutable (const constructors):
/// ```dart
/// const state = SyncIdle();
/// // Properties cannot change, must create new instance
/// ```
///
/// ## Usage
///
/// States are typically handled in BlocBuilder:
/// ```dart
/// BlocBuilder<SyncBloc, SyncState>(
///   builder: (context, state) {
///     if (state is SyncInProgress) {
///       return CircularProgressIndicator();
///     }
///     if (state is SyncCompleted) {
///       return Text('Synced ${state.itemsCount} items');
///     }
///     if (state is SyncFailed) {
///       return Text('Error: ${state.errorMessage}');
///     }
///     return SizedBox();
///   },
/// )
/// ```
///
/// See also:
/// - [SyncEvent]: Events causing state transitions
/// - [SyncBloc]: Manages states and transitions
abstract class SyncState extends Equatable {
  /// Creates a sync state
  ///
  /// Base class for all sync states.
  const SyncState();

  /// Equatable props for equality comparison
  ///
  /// Subclasses override with state properties.
  @override
  List<Object?> get props => [];
}

/// No active synchronization operation
///
/// Idle state indicates no sync is in progress. App is ready for new sync.
/// Typically the starting state or final state after sync completes.
///
/// ## Properties
/// - [lastSyncAt]: When last sync completed (null if never synced)
///
/// ## State Entry Points
/// - Application startup
/// - After SyncCompleted (after brief delay)
/// - After SyncFailed (after retries exhausted)
/// - After PauseSyncEvent resume → StartSyncEvent completes
///
/// ## UI Display
/// ```dart
/// if (state is SyncIdle) {
///   final idle = state as SyncIdle;
///   if (idle.lastSyncAt != null) {
///     final timeAgo = DateTime.now().difference(idle.lastSyncAt!);
///     return Text('Last synced ${timeAgo.inMinutes} minutes ago');
///   } else {
///     return Text('Never synced');
///   }
/// }
/// ```
///
/// ## Next States
/// - → SyncInProgress: StartSyncEvent added
/// - → SyncOffline: Connection lost
///
/// ## Metadata
/// - [lastSyncAt]: Timestamp of last successful sync (null if never)
///
/// See also:
/// - [SyncInProgress]: Sync running
/// - [SyncCompleted]: Sync succeeded
class SyncIdle extends SyncState {
  /// Timestamp of last successful synchronization
  ///
  /// - null: Never synced before
  /// - DateTime: When last sync completed
  ///
  /// Used to display "Last synced: X minutes ago" messages.
  final DateTime? lastSyncAt;

  /// Creates idle state
  ///
  /// ## Parameters
  /// - [lastSyncAt]: When last sync completed (optional)
  ///
  /// ## Example
  /// ```dart
  /// const idle = SyncIdle();  // Never synced
  ///
  /// final lastSync = DateTime(2024, 1, 15, 10, 30);
  /// const idle2 = SyncIdle(lastSyncAt: lastSync);
  /// ```
  const SyncIdle({this.lastSyncAt});

  @override
  List<Object?> get props => [lastSyncAt];
}

/// Synchronization currently in progress
///
/// Indicates sync operation is running. Tracks progress of the sync.
/// Show progress indicator or spinner while in this state.
///
/// ## Properties
/// - [itemsSynced]: Number of items synced so far
/// - [totalItems]: Total items to sync
/// - [currentOperation]: Human-readable current operation
/// - [progress]: Computed progress (0.0 to 1.0)
///
/// ## Progress Calculation
/// ```
/// progress = itemsSynced / totalItems (if totalItems > 0)
/// progress = 0.0 (if unknown total)
/// ```
///
/// ## State Entry Points
/// - StartSyncEvent added
/// - RetrySyncEvent added (retry after error)
/// - ResumeSyncEvent added (resume from pause)
/// - ResolveConflictEvent added (continue after conflict resolution)
///
/// ## UI Display
/// ```dart
/// if (state is SyncInProgress) {
///   final inProgress = state as SyncInProgress;
///   return Column(
///     children: [
///       LinearProgressIndicator(value: inProgress.progress),
///       Text('${inProgress.itemsSynced}/${inProgress.totalItems} synced'),
///       if (inProgress.currentOperation != null)
///         Text(inProgress.currentOperation!),
///     ],
///   );
/// }
/// ```
///
/// ## Next States
/// - → SyncCompleted: Sync succeeded
/// - → SyncFailed: Sync encountered error
/// - → SyncPaused: Pause requested
/// - → SyncConflict: Conflict detected
/// - → SyncOffline: Connection lost
///
/// ## Metadata
/// - [itemsSynced]: Items processed (0 to totalItems)
/// - [totalItems]: Total to process (0 if unknown)
/// - [currentOperation]: Current step description
/// - [progress]: Computed percentage
///
/// See also:
/// - [SyncCompleted]: Sync finished successfully
/// - [SyncFailed]: Sync encountered error
class SyncInProgress extends SyncState {
  /// Number of items already synchronized
  ///
  /// Increments as items are processed.
  /// Used to calculate progress percentage.
  final int itemsSynced;

  /// Total number of items to synchronize
  ///
  /// May be unknown initially (0).
  /// Used to calculate progress percentage.
  final int totalItems;

  /// Human-readable description of current operation
  ///
  /// Examples:
  /// - "Uploading local changes..."
  /// - "Downloading remote updates..."
  /// - "Resolving conflicts..."
  ///
  /// null if not tracked.
  final String? currentOperation;

  /// Creates in-progress sync state
  ///
  /// ## Parameters
  /// - [itemsSynced]: Items synced so far (default: 0)
  /// - [totalItems]: Total items (default: 0)
  /// - [currentOperation]: Current step (default: null)
  ///
  /// ## Example
  /// ```dart
  /// const inProgress = SyncInProgress(
  ///   itemsSynced: 5,
  ///   totalItems: 20,
  ///   currentOperation: 'Uploading...',
  /// );
  /// print(inProgress.progress);  // 0.25
  /// ```
  const SyncInProgress({
    this.itemsSynced = 0,
    this.totalItems = 0,
    this.currentOperation,
  });

  /// Calculate progress as percentage (0.0 to 1.0)
  ///
  /// Returns:
  /// - itemsSynced / totalItems: If totalItems > 0
  /// - 0.0: If totalItems is 0 (unknown progress)
  ///
  /// Used for progress bar values.
  ///
  /// ## Example
  /// ```dart
  /// state.itemsSynced = 5;
  /// state.totalItems = 20;
  /// print(state.progress);  // 0.25
  ///
  /// state.totalItems = 0;
  /// print(state.progress);  // 0.0 (indeterminate)
  /// ```
  double get progress =>
      totalItems > 0 ? itemsSynced / totalItems : 0.0;

  @override
  List<Object?> get props => [itemsSynced, totalItems, currentOperation];
}

/// Synchronization completed successfully
///
/// Indicates sync succeeded. Shows how many items were synced and timing info.
/// Emitted after successful sync, then transitions to SyncIdle after brief delay.
///
/// ## Properties
/// - [itemsCount]: Number of items synchronized
/// - [syncedAt]: When sync completed
/// - [syncDuration]: How long sync took
///
/// ## State Entry Points
/// - SyncCompleteEvent added (explicit completion)
/// - SyncInProgress completes successfully
///
/// ## UI Display
/// ```dart
/// if (state is SyncCompleted) {
///   final completed = state as SyncCompleted;
///   return SnackBar(
///     content: Text(
///       'Synced ${completed.itemsCount} items '
///       'in ${completed.syncDuration.inSeconds}s'
///     ),
///     duration: Duration(seconds: 2),
///   );
/// }
/// ```
///
/// ## Auto-Transition
/// SyncBloc automatically transitions to SyncIdle after 500ms:
/// ```dart
/// emit(SyncCompleted(...));
/// await Future.delayed(Duration(milliseconds: 500));
/// emit(SyncIdle(lastSyncAt: syncedAt));
/// ```
///
/// ## Next States
/// - → SyncIdle: After 500ms delay (automatic)
///
/// ## Metadata
/// - [itemsCount]: Items synced
/// - [syncedAt]: Completion timestamp
/// - [syncDuration]: Duration taken
///
/// See also:
/// - [SyncInProgress]: Sync in progress
/// - [SyncFailed]: Sync failed
class SyncCompleted extends SyncState {
  /// Number of items successfully synchronized
  ///
  /// Total count of items (screens, widgets, etc.) that were synced
  /// in this operation.
  final int itemsCount;

  /// Timestamp when sync completed
  ///
  /// Used to display "synced at" and "last synced" timestamps.
  final DateTime syncedAt;

  /// How long the sync operation took
  ///
  /// Useful for performance metrics and display.
  ///
  /// ## Example
  /// ```dart
  /// state.syncDuration.inSeconds   // 45
  /// state.syncDuration.inMilliseconds  // 45000
  /// ```
  final Duration syncDuration;

  /// Creates completed sync state
  ///
  /// ## Parameters
  /// - [itemsCount]: Number of items synced
  /// - [syncedAt]: Completion timestamp
  /// - [syncDuration]: How long it took
  ///
  /// ## Example
  /// ```dart
  /// final state = SyncCompleted(
  ///   itemsCount: 42,
  ///   syncedAt: DateTime.now(),
  ///   syncDuration: Duration(seconds: 5),
  /// );
  /// ```
  const SyncCompleted({
    required this.itemsCount,
    required this.syncedAt,
    required this.syncDuration,
  });

  @override
  List<Object?> get props => [itemsCount, syncedAt, syncDuration];
}

/// Synchronization failed with error
///
/// Indicates sync failed. Includes error details. SyncBloc may auto-retry
/// or wait for user action.
///
/// ## Properties
/// - [errorMessage]: Human-readable error description
/// - [error]: Original error object (for debugging)
/// - [stackTrace]: Stack trace for debugging
///
/// ## Common Error Messages
/// - "Network timeout after 30s"
/// - "Server error: 500"
/// - "No storage space"
/// - "Invalid response format"
/// - "Authentication failed"
///
/// ## State Entry Points
/// - SyncErrorEvent added
/// - SyncInProgress encounters exception
///
/// ## UI Display
/// ```dart
/// if (state is SyncFailed) {
///   final failed = state as SyncFailed;
///   return AlertDialog(
///     title: Text('Sync Failed'),
///     content: Text(failed.errorMessage),
///     actions: [
///       TextButton(
///         onPressed: () => context.read<SyncBloc>().add(RetrySyncEvent()),
///         child: Text('Retry'),
///       ),
///     ],
///   );
/// }
/// ```
///
/// ## Auto-Retry
/// After 2^n seconds where n is retry count (1, 2, 3, 4...):
/// - 1st attempt: Now
/// - 1st error: 2 seconds
/// - 2nd error: 4 seconds
/// - 3rd error: 8 seconds
/// - 4th error: Give up, emit SyncIdle
///
/// ## Debug Information
/// - [error]: Original exception
/// - [stackTrace]: Where error occurred
/// Useful for logging and debugging issues.
///
/// ## Next States
/// - → SyncInProgress: Auto-retry or RetrySyncEvent
/// - → SyncIdle: After max retries exhausted
///
/// See also:
/// - [SyncInProgress]: Sync in progress (can lead to SyncFailed)
/// - [SyncCompleted]: Successful sync
/// - [RetrySyncEvent]: Manual retry
class SyncFailed extends SyncState {
  /// Human-readable error message
  ///
  /// Shown to user to explain what went wrong.
  /// Should be clear and actionable.
  final String errorMessage;

  /// Original error/exception that caused failure
  ///
  /// For debugging and logging. May be:
  /// - Exception
  /// - Error
  /// - String
  /// - null
  final dynamic error;

  /// Stack trace where error occurred
  ///
  /// For debugging. Shows call stack at error point.
  /// null if not available.
  final StackTrace? stackTrace;

  /// Creates failed sync state
  ///
  /// ## Parameters
  /// - [errorMessage]: Error description (required)
  /// - [error]: Original error (optional)
  /// - [stackTrace]: Stack trace (optional)
  ///
  /// ## Example
  /// ```dart
  /// try {
  ///   await sync();
  /// } catch (e, trace) {
  ///   emit(SyncFailed(
  ///     errorMessage: 'Network failed: ${e.message}',
  ///     error: e,
  ///     stackTrace: trace,
  ///   ));
  /// }
  /// ```
  const SyncFailed({
    required this.errorMessage,
    this.error,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [errorMessage, error, stackTrace];
}

/// Synchronization paused by user
///
/// Indicates sync was paused. Can resume from here.
/// Useful for conserving bandwidth or battery.
///
/// ## Properties
/// - [itemsSynced]: Items synced before pause
///
/// ## State Entry Points
/// - PauseSyncEvent added during SyncInProgress
///
/// ## UI Display
/// ```dart
/// if (state is SyncPaused) {
///   final paused = state as SyncPaused;
///   return Row(
///     children: [
///       Icon(Icons.pause),
///       Text('Syncing paused (${paused.itemsSynced} items)'),
///       TextButton(
///         onPressed: () => context.read<SyncBloc>().add(ResumeSyncEvent()),
///         child: Text('Resume'),
///       ),
///     ],
///   );
/// }
/// ```
///
/// ## Resume Process
/// User adds ResumeSyncEvent:
/// ```dart
/// context.read<SyncBloc>().add(ResumeSyncEvent());
/// // Internally triggers: add(const StartSyncEvent());
/// // → SyncInProgress emitted
/// // → Sync continues from where paused
/// ```
///
/// ## Next States
/// - → SyncInProgress: ResumeSyncEvent added
///
/// See also:
/// - [PauseSyncEvent]: Causes pause
/// - [ResumeSyncEvent]: Resume from pause
class SyncPaused extends SyncState {
  /// Number of items synced before pause
  ///
  /// Useful to show progress when resuming.
  final int itemsSynced;

  /// Creates paused sync state
  ///
  /// ## Parameters
  /// - [itemsSynced]: Items done before pause (default: 0)
  ///
  /// ## Example
  /// ```dart
  /// const paused = SyncPaused(itemsSynced: 15);
  /// ```
  const SyncPaused({this.itemsSynced = 0});

  @override
  List<Object?> get props => [itemsSynced];
}

/// Data conflict detected during sync
///
/// Indicates conflicting versions of data. Requires user or programmatic
/// resolution. Shows both versions to user for decision.
///
/// ## Conflict Scenarios
/// - Item modified locally and remotely
/// - Item deleted locally but updated remotely
/// - Item created with same ID locally and remotely
///
/// ## Properties
/// - [conflictId]: ID of conflicting item
/// - [localVersion]: Local version of data
/// - [remoteVersion]: Remote version of data
///
/// ## State Entry Points
/// - Conflict detected during sync merge
/// - ResolveConflictEvent added (may lead back here if unresolved)
///
/// ## UI Display
/// ```dart
/// if (state is SyncConflict) {
///   final conflict = state as SyncConflict;
///   return ConflictResolutionDialog(
///     localVersion: conflict.localVersion,
///     remoteVersion: conflict.remoteVersion,
///     onResolve: (resolution) {
///       context.read<SyncBloc>().add(
///         ResolveConflictEvent(
///           conflictId: conflict.conflictId,
///           resolution: resolution,
///         )
///       );
///     },
///   );
/// }
/// ```
///
/// ## Resolution Strategies
/// - Keep local: Overwrite remote with local
/// - Keep remote: Overwrite local with remote
/// - Merge: Combine both versions
/// - Manual: User selects fields to keep
///
/// ## Next States
/// - → SyncInProgress: After ResolveConflictEvent
///
/// See also:
/// - [ResolveConflictEvent]: Resolves conflict
class SyncConflict extends SyncState {
  /// Unique ID of the item with conflict
  ///
  /// Usually the screen ID or item ID.
  final String conflictId;

  /// Local version of the conflicting data
  ///
  /// What's stored locally on device.
  final Map<String, dynamic> localVersion;

  /// Remote version of the conflicting data
  ///
  /// What's stored on server.
  final Map<String, dynamic> remoteVersion;

  /// Creates conflict state
  ///
  /// ## Parameters
  /// - [conflictId]: ID of conflicting item
  /// - [localVersion]: Local data
  /// - [remoteVersion]: Remote data
  ///
  /// ## Example
  /// ```dart
  /// const conflict = SyncConflict(
  ///   conflictId: 'screen_123',
  ///   localVersion: {'title': 'Local Title', 'updated': now},
  ///   remoteVersion: {'title': 'Remote Title', 'updated': earlier},
  /// );
  /// ```
  const SyncConflict({
    required this.conflictId,
    required this.localVersion,
    required this.remoteVersion,
  });

  @override
  List<Object?> get props => [conflictId, localVersion, remoteVersion];
}

/// Offline - no network connection, waiting for connection
///
/// Indicates device is offline. Sync cannot proceed. Will retry when
/// connection is restored.
///
/// ## Properties
/// - [pendingItems]: Number of items waiting to sync
///
/// ## State Entry Points
/// - SyncInProgress detects no network
/// - Connection lost after sync started
///
/// ## UI Display
/// ```dart
/// if (state is SyncOffline) {
///   final offline = state as SyncOffline;
///   return OfflineNotification(
///     itemsPending: offline.pendingItems,
///   );
/// }
/// ```
///
/// ## Auto-Recovery
/// When connection restored:
/// 1. Connectivity notified
/// 2. SyncBloc auto-triggers StartSyncEvent
/// 3. → SyncInProgress
/// 4. Sync resumes with pending items
///
/// ## Next States
/// - → SyncInProgress: Connection restored, auto-sync triggered
///
/// See also:
/// - [SyncInProgress]: Sync running (can lead to SyncOffline)
class SyncOffline extends SyncState {
  /// Number of items pending synchronization
  ///
  /// Items in queue waiting for connection to sync.
  /// Useful to show "X items waiting to sync" message.
  final int pendingItems;

  /// Creates offline state
  ///
  /// ## Parameters
  /// - [pendingItems]: Items waiting (default: 0)
  ///
  /// ## Example
  /// ```dart
  /// const offline = SyncOffline(pendingItems: 5);
  /// ```
  const SyncOffline({this.pendingItems = 0});

  @override
  List<Object?> get props => [pendingItems];
}
