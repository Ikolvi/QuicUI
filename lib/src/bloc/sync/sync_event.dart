/// Sync events for offline-first data synchronization
///
/// This module defines all events that trigger synchronization state changes
/// in the SyncBloc. Events represent user actions, system events, and automatic
/// operations related to offline/online data synchronization.
///
/// ## Event Architecture
///
/// ```
/// SyncEvent (Base class)
///   ├→ StartSyncEvent: Trigger synchronization (manual or automatic)
///   ├→ SyncCompleteEvent: Sync finished successfully
///   ├→ SyncErrorEvent: Sync encountered error
///   ├→ RetrySyncEvent: Retry failed synchronization
///   ├→ PauseSyncEvent: Pause ongoing sync
///   ├→ ResumeSyncEvent: Resume paused sync
///   ├→ ResolveConflictEvent: Resolve sync conflict
///   └→ ClearSyncStateEvent: Clear sync history
/// ```
///
/// ## Event Flow
///
/// ```
/// User Action
///    ↓
/// SyncEvent (e.g., StartSyncEvent)
///    ↓
/// SyncBloc.add(event)
///    ↓
/// Event handler called (_onStartSync, etc.)
///    ↓
/// State emission (SyncInProgress → SyncCompleted/SyncFailed)
///    ↓
/// UI updates via BlocListener/BlocBuilder
/// ```
///
/// ## Usage Examples
///
/// ### Manual Sync (User Initiated)
/// ```dart
/// context.read<SyncBloc>().add(
///   StartSyncEvent(isManual: true)
/// );
/// ```
///
/// ### Automatic Sync (System Initiated)
/// ```dart
/// syncBloc.add(StartSyncEvent(isManual: false));
/// ```
///
/// ### Handle Sync Error
/// ```dart
/// syncBloc.add(
///   SyncErrorEvent('Network timeout')
/// );
/// ```
///
/// ### Resolve Data Conflict
/// ```dart
/// syncBloc.add(
///   ResolveConflictEvent(
///     conflictId: 'screen_123',
///     resolution: {'preferLocal': false}
///   )
/// );
/// ```
///
/// ## Equatable Implementation
///
/// All events extend Equatable for value-based equality:
/// - Two events with same properties are considered equal
/// - Allows BLoC deduplication
/// - Prevents duplicate event processing
///
/// ## Retry Strategy
///
/// RetrySyncEvent works with exponential backoff:
/// ```
/// 1st attempt: Immediate
/// 2nd attempt: After 2 seconds  (1 << 1)
/// 3rd attempt: After 4 seconds  (1 << 2)
/// 4th attempt: After 8 seconds  (1 << 3)
/// Max: 3 retries, then give up
/// ```
///
/// See also:
/// - [SyncState]: States corresponding to these events
/// - [SyncBloc]: Event handlers and state management
/// - [SyncRepository]: Actual sync implementation


import 'package:equatable/equatable.dart';

/// Base class for all synchronization events
///
/// All sync events inherit from this abstract base class.
/// Uses Equatable for value-based equality comparison.
///
/// ## Event Pattern
///
/// Events are immutable data classes that trigger state changes:
/// ```dart
/// // Bad: Direct state manipulation
/// syncState = SyncInProgress();
///
/// // Good: Add event to BLoC
/// syncBloc.add(StartSyncEvent());
/// ```
///
/// ## Equality
///
/// Events are compared by properties (Equatable):
/// ```dart
/// event1 = StartSyncEvent(isManual: true);
/// event2 = StartSyncEvent(isManual: true);
/// event1 == event2  // true (same properties)
/// ```
///
/// This prevents accidental duplicate processing.
///
/// ## Immutability
///
/// All event instances are immutable (const constructors):
/// ```dart
/// // Must use 'const' for compile-time constants
/// const event = StartSyncEvent();
///
/// // Properties cannot be modified after creation
/// // To change: create new event instance
/// ```
///
/// See also:
/// - [StartSyncEvent]: Start sync operation
/// - [SyncCompleteEvent]: Sync completed
/// - [SyncErrorEvent]: Sync error occurred
abstract class SyncEvent extends Equatable {
  /// Creates a sync event
  ///
  /// All sync events inherit from this constructor.
  /// Marked const to ensure immutability.
  const SyncEvent();

  /// Equatable props for equality comparison
  ///
  /// Subclasses override to include event properties.
  /// Events with same props are considered equal.
  @override
  List<Object?> get props => [];
}

/// Trigger data synchronization with backend
///
/// Initiates sync operation. Can be manual (user-triggered) or automatic
/// (system-triggered on connection change, timer, etc.).
///
/// ## Parameters
/// - [isManual]: true if user initiated, false if automatic
///
/// ## Event Handling
///
/// When added to SyncBloc:
/// 1. BLoC emits SyncInProgress state
/// 2. Calls RepositorySyncRepository.syncData()
/// 3. On success: emits SyncCompleted
/// 4. On failure: emits SyncFailed, may trigger auto-retry
///
/// ## Manual vs Automatic
///
/// **Manual Sync** (isManual: true)
/// - User pulls to refresh or taps sync button
/// - May show UI feedback/spinner
/// - Single attempt, no auto-retry
/// - Example: Pull-to-refresh gesture
///
/// **Automatic Sync** (isManual: false)
/// - System-triggered on connection restored
/// - Silent operation, minimal UI change
/// - May retry with exponential backoff
/// - Example: Network connectivity restored
///
/// ## Lifecycle
///
/// ```
/// StartSyncEvent created
///       ↓
/// add() to SyncBloc
///       ↓
/// _onStartSync handler called
///       ↓
/// SyncInProgress emitted
///       ↓
/// Fetch pending items from local DB
///       ↓
/// Upload to backend
///       ↓
/// Download remote changes
///       ↓
/// Merge/update local DB
///       ↓
/// SyncCompleted emitted (success)
/// OR
/// SyncFailed emitted (failure)
/// ```
///
/// ## Usage Examples
///
/// ### Pull-to-Refresh Sync
/// ```dart
/// ScreenView(
///   onRefresh: () async {
///     context.read<SyncBloc>().add(
///       StartSyncEvent(isManual: true)
///     );
///   },
/// )
/// ```
///
/// ### Automatic Sync on Connection
/// ```dart
/// _connectionSubscription = Connectivity()
///   .onConnectivityChanged
///   .listen((result) {
///     if (result != ConnectivityResult.none) {
///       syncBloc.add(StartSyncEvent(isManual: false));
///     }
///   });
/// ```
///
/// ### Periodic Sync
/// ```dart
/// Timer.periodic(Duration(minutes: 5), (_) {
///   syncBloc.add(StartSyncEvent(isManual: false));
/// });
/// ```
///
/// ## Return State
/// - Success: [SyncCompleted] with itemsCount and syncedAt
/// - Failure: [SyncFailed] with error message
/// - Network issue: May emit [SyncOffline]
///
/// See also:
/// - [SyncCompleteEvent]: Explicit sync completion
/// - [RetrySyncEvent]: Retry after failure
/// - [SyncRepository.syncData]: Actual sync implementation
class StartSyncEvent extends SyncEvent {
  /// Whether this sync was manually triggered by user
  ///
  /// - true: User initiated (pull-to-refresh, sync button)
  /// - false: System initiated (auto-sync, connection restored)
  ///
  /// Used to determine retry policy and UI feedback.
  final bool isManual;

  /// Creates an event to start synchronization
  ///
  /// ## Parameters
  /// - [isManual]: true for user-triggered, false for system (default: true)
  ///
  /// ## Example
  /// ```dart
  /// // User explicitly syncing
  /// const manualSync = StartSyncEvent(isManual: true);
  ///
  /// // Automatic sync
  /// const autoSync = StartSyncEvent(isManual: false);
  /// ```
  const StartSyncEvent({this.isManual = true});

  @override
  List<Object?> get props => [isManual];
}

/// Triggered when synchronization completes successfully
///
/// Indicates sync completed and updated [itemsCount] items.
/// Used to emit SyncCompleted state with result metadata.
///
/// ## Parameters
/// - [itemsCount]: Number of items synchronized
/// - [syncedAt]: Timestamp when sync completed
///
/// ## Usage
///
/// Usually called by event handler after sync completes:
/// ```dart
/// Future<void> _onStartSync(...) async {
///   try {
///     final result = await syncRepository.syncData();
///     add(SyncCompleteEvent(
///       itemsCount: result.itemsCount,
///       syncedAt: DateTime.now(),
///     ));
///   } catch (e) {
///     add(SyncErrorEvent(e.toString()));
///   }
/// }
/// ```
///
/// ## Flow
/// ```
/// SyncCompleteEvent created
///       ↓
/// add() to SyncBloc
///       ↓
/// _onSyncComplete handler called
///       ↓
/// SyncCompleted state emitted
///       ↓
/// After 500ms: SyncIdle emitted
/// ```
///
/// ## See Also
/// - [SyncCompleted]: Corresponding state
/// - [StartSyncEvent]: Initiates sync
class SyncCompleteEvent extends SyncEvent {
  /// Number of items successfully synchronized
  ///
  /// Total count of screens, widgets, or data items that were
  /// synced in this operation.
  final int itemsCount;

  /// Timestamp when sync completed
  ///
  /// Used to track "last sync" and display in UI.
  /// Should be set to DateTime.now() when sync finishes.
  final DateTime syncedAt;

  /// Creates event to indicate sync completion
  ///
  /// ## Parameters
  /// - [itemsCount]: Total items synced
  /// - [syncedAt]: Completion timestamp
  ///
  /// ## Example
  /// ```dart
  /// add(SyncCompleteEvent(
  ///   itemsCount: 42,
  ///   syncedAt: DateTime.now(),
  /// ));
  /// ```
  const SyncCompleteEvent({
    required this.itemsCount,
    required this.syncedAt,
  });

  @override
  List<Object?> get props => [itemsCount, syncedAt];
}

/// Triggered when synchronization encounters an error
///
/// Indicates sync operation failed. Causes SyncFailed state emission
/// and potentially automatic retry with exponential backoff.
///
/// ## Parameters
/// - [errorMessage]: Description of error that occurred
///
/// ## Error Types
/// - Network error: "Network timeout", "Connection refused"
/// - Server error: "Server responded with 500", "Invalid response"
/// - Conflict error: "Data conflict detected", "Merge failed"
/// - Storage error: "Database write failed", "Disk full"
///
/// ## Retry Behavior
///
/// SyncBloc automatically retries on error (up to 3 times):
/// ```
/// Attempt 1: Immediate
/// Attempt 2: Wait 2 seconds
/// Attempt 3: Wait 4 seconds
/// Attempt 4: Wait 8 seconds
/// Final: Give up, emit SyncIdle
/// ```
///
/// ## Usage
///
/// Usually thrown from sync handler on error:
/// ```dart
/// try {
///   await syncRepository.syncData();
/// } catch (e) {
///   add(SyncErrorEvent('Sync failed: ${e.message}'));
/// }
/// ```
///
/// ## See Also
/// - [SyncFailed]: Corresponding state
/// - [RetrySyncEvent]: Manual retry
class SyncErrorEvent extends SyncEvent {
  /// Human-readable error message
  ///
  /// Should explain what went wrong so UI can display to user.
  /// Examples:
  /// - "Network connection failed"
  /// - "Server error: 503"
  /// - "No storage space available"
  final String errorMessage;

  /// Creates event to report sync error
  ///
  /// ## Parameters
  /// - [errorMessage]: Description of error
  ///
  /// ## Example
  /// ```dart
  /// add(SyncErrorEvent('Connection timeout after 30s'));
  /// ```
  const SyncErrorEvent(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

/// Manually retry failed synchronization
///
/// Triggers another sync attempt after previous failure.
/// Used by UI to allow manual retry or by SyncBloc for auto-retry.
///
/// ## Auto-Retry
///
/// SyncBloc automatically retries after errors:
/// - Max 3 automatic retries
/// - Exponential backoff between attempts
/// - Manual retry button can trigger additional attempts
///
/// ## Manual Retry
///
/// User can trigger retry manually:
/// ```dart
/// FloatingActionButton(
///   onPressed: () {
///     context.read<SyncBloc>().add(RetrySyncEvent());
///   },
///   child: Icon(Icons.refresh),
/// )
/// ```
///
/// ## Implementation
///
/// RetrySyncEvent triggers another StartSyncEvent:
/// ```dart
/// Future<void> _onRetrySync(...) async {
///   add(const StartSyncEvent());
/// }
/// ```
///
/// ## See Also
/// - [SyncErrorEvent]: Reports error
/// - [StartSyncEvent]: Initial sync attempt
class RetrySyncEvent extends SyncEvent {
  /// Creates event to retry failed sync
  ///
  /// ## Example
  /// ```dart
  /// const retryEvent = RetrySyncEvent();
  /// ```
  const RetrySyncEvent();
}

/// Pause ongoing synchronization
///
/// Temporarily stops sync operation. Useful when user wants to
/// conserve bandwidth or battery.
///
/// ## State Change
/// ```
/// SyncInProgress
///       ↓
/// PauseSyncEvent added
///       ↓
/// SyncPaused emitted
/// ```
///
/// ## After Pause
///
/// To resume, add ResumeSyncEvent:
/// ```dart
/// syncBloc.add(PauseSyncEvent());   // Pause
/// // ... later ...
/// syncBloc.add(ResumeSyncEvent()); // Resume
/// ```
///
/// ## Usage
///
/// ```dart
/// // Pause sync when user switches to metered network
/// if (isMeteredNetwork) {
///   syncBloc.add(PauseSyncEvent());
/// }
/// ```
///
/// ## See Also
/// - [ResumeSyncEvent]: Resume paused sync
/// - [SyncPaused]: Corresponding state
class PauseSyncEvent extends SyncEvent {
  /// Creates event to pause sync
  ///
  /// ## Example
  /// ```dart
  /// const pauseEvent = PauseSyncEvent();
  /// ```
  const PauseSyncEvent();
}

/// Resume paused synchronization
///
/// Restarts sync operation after being paused.
/// Continues from where it was paused.
///
/// ## State Change
/// ```
/// SyncPaused
///       ↓
/// ResumeSyncEvent added
///       ↓
/// StartSyncEvent added internally
///       ↓
/// SyncInProgress emitted
/// ```
///
/// ## Usage
///
/// ```dart
/// syncBloc.add(PauseSyncEvent());      // Pause
/// syncBloc.add(ResumeSyncEvent());     // Resume
/// ```
///
/// ## See Also
/// - [PauseSyncEvent]: Pause sync
/// - [SyncInProgress]: State after resume
class ResumeSyncEvent extends SyncEvent {
  /// Creates event to resume paused sync
  ///
  /// ## Example
  /// ```dart
  /// const resumeEvent = ResumeSyncEvent();
  /// ```
  const ResumeSyncEvent();
}

/// Resolve data conflict during synchronization
///
/// When local and remote versions of data diverge, conflict resolution
/// is needed. This event provides the resolution choice.
///
/// ## Conflict Scenarios
///
/// - Same item modified locally and remotely
/// - Item deleted locally but updated remotely
/// - Item updated locally but deleted remotely
///
/// ## Resolution Options
///
/// ```dart
/// {
///   'strategy': 'preferLocal',   // Use local version
///   'strategy': 'preferRemote',  // Use remote version
///   'strategy': 'merge',         // Merge both versions
///   'strategy': 'custom',        // Custom merge logic
/// }
/// ```
///
/// ## Usage
///
/// ```dart
/// context.read<SyncBloc>().add(
///   ResolveConflictEvent(
///     conflictId: 'screen_123',
///     resolution: {'strategy': 'preferLocal'}
///   )
/// );
/// ```
///
/// ## See Also
/// - [SyncConflict]: Conflict state
/// - [SyncRepository.resolveConflict]: Resolution logic
class ResolveConflictEvent extends SyncEvent {
  /// Unique identifier for the conflict
  ///
  /// Usually the screen/item ID that has conflicting versions.
  final String conflictId;

  /// Resolution strategy and parameters
  ///
  /// Map containing how to resolve conflict:
  /// - strategy: 'preferLocal', 'preferRemote', 'merge', 'custom'
  /// - mergeLogic: Custom merge function if needed
  /// - timestamp: For version selection
  final Map<String, dynamic> resolution;

  /// Creates event to resolve conflict
  ///
  /// ## Parameters
  /// - [conflictId]: ID of conflicting item
  /// - [resolution]: Resolution strategy
  ///
  /// ## Example
  /// ```dart
  /// add(ResolveConflictEvent(
  ///   conflictId: 'item_42',
  ///   resolution: {'strategy': 'preferRemote'}
  /// ));
  /// ```
  const ResolveConflictEvent({
    required this.conflictId,
    required this.resolution,
  });

  @override
  List<Object?> get props => [conflictId, resolution];
}

/// Clear all synchronization state and history
///
/// Resets sync tracking including last sync time, retry count, etc.
/// Useful for debugging or starting fresh after major issues.
///
/// ## State Change
/// ```
/// Any state
///       ↓
/// ClearSyncStateEvent added
///       ↓
/// SyncIdle emitted
/// ```
///
/// ## What Gets Cleared
/// - Last sync timestamp
/// - Retry counter
/// - Pending sync items (not deleted, just cleared flag)
/// - Conflict state
///
/// ## Usage
///
/// ```dart
/// // Debug: Start fresh
/// syncBloc.add(ClearSyncStateEvent());
///
/// // Or in error recovery
/// if (error.isCritical) {
///   syncBloc.add(ClearSyncStateEvent());
/// }
/// ```
///
/// ## ⚠️ Warning
/// This doesn't delete actual data, just resets sync metadata.
/// Data loss only occurs if actual sync was incomplete.
///
/// ## See Also
/// - [SyncIdle]: State after clearing
class ClearSyncStateEvent extends SyncEvent {
  /// Creates event to clear sync state
  ///
  /// ## Example
  /// ```dart
  /// const clearEvent = ClearSyncStateEvent();
  /// ```
  const ClearSyncStateEvent();
}
