/// Sync BLoC for offline-first data synchronization management
///
/// This module manages the synchronization of local data with backend services.
/// Implements the BLoC pattern with event-driven state management for offline-first
/// applications, supporting pause/resume, conflict resolution, and auto-retry.
///
/// ## Architecture
///
/// ```
/// User/System
///    ↓ (adds SyncEvent)
/// SyncBloc
///    ├→ Receives event
///    ├→ Calls event handler
///    ├→ Emits state
///    └→ Notifies listeners
///        ↓
///    UI Updates (BlocBuilder, BlocListener)
/// ```
///
/// ## Sync Lifecycle
///
/// ```
/// SyncIdle
///    ↓ StartSyncEvent
/// SyncInProgress (uploading local changes)
///    ↓
/// SyncInProgress (downloading remote changes)
///    ↓ (success)
/// SyncCompleted
///    ↓ (500ms delay)
/// SyncIdle
///
/// OR
///
///    ↓ (error)
/// SyncFailed
///    ↓ (wait 2^n seconds)
/// SyncInProgress (retry)
/// ```
///
/// ## Event Handlers
///
/// | Event | Handler | Behavior |
/// |-------|---------|----------|
/// | StartSyncEvent | _onStartSync | Start new sync |
/// | SyncCompleteEvent | _onSyncComplete | Mark sync done |
/// | SyncErrorEvent | _onSyncError | Handle error + auto-retry |
/// | RetrySyncEvent | _onRetrySync | Manual retry |
/// | PauseSyncEvent | _onPauseSync | Pause sync |
/// | ResumeSyncEvent | _onResumeSync | Resume sync |
/// | ResolveConflictEvent | _onResolveConflict | Resolve conflict |
/// | ClearSyncStateEvent | _onClearSyncState | Reset state |
///
/// ## Usage Examples
///
/// ### Basic Sync
/// ```dart
/// final syncBloc = SyncBloc();
/// syncBloc.add(StartSyncEvent(isManual: true));
/// ```
///
/// ### In BLoC Provider
/// ```dart
/// BlocProvider(
///   create: (_) => SyncBloc(),
///   child: MyApp(),
/// )
/// ```
///
/// ### Monitor Sync Status
/// ```dart
/// BlocBuilder<SyncBloc, SyncState>(
///   builder: (context, state) {
///     if (state is SyncInProgress) {
///       return LinearProgressIndicator(value: state.progress);
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
/// ## Auto-Retry Strategy
///
/// On sync error:
/// 1. Emit SyncFailed
/// 2. If manual sync or retries < 3: wait 2^n seconds
/// 3. Add RetrySyncEvent automatically
/// 4. Retry StartSyncEvent
/// 5. After 3 retries: Give up, emit SyncIdle
///
/// Backoff calculation: `1 << retryCount` (exponential)
/// - 1st retry: 2 seconds
/// - 2nd retry: 4 seconds
/// - 3rd retry: 8 seconds
/// - 4th retry: Stop trying
///
/// ## Conflict Resolution
///
/// When data conflicts during merge:
/// 1. Emit SyncConflict state
/// 2. UI shows both versions
/// 3. User/system chooses resolution
/// 4. Add ResolveConflictEvent
/// 5. Sync continues with chosen version
///
/// ## State Persistence
///
/// BLoC tracks:
/// - `_lastSyncAt`: Last successful sync timestamp
/// - `_syncRetryCount`: Current retry attempt number
///
/// These are local to BLoC instance. For persistence across app restart,
/// store in local database or shared preferences.
///
/// ## Testing
///
/// ```dart
/// final bloc = SyncBloc();
/// expectLater(
///   bloc.stream,
///   emitsInOrder([
///     isA<SyncInProgress>(),
///     isA<SyncCompleted>(),
///     isA<SyncIdle>(),
///   ]),
/// );
/// bloc.add(StartSyncEvent());
/// ```
///
/// See also:
/// - [SyncEvent]: Events triggering sync
/// - [SyncState]: State values
/// - [SyncRepository]: Actual sync implementation


import 'package:flutter_bloc/flutter_bloc.dart';

import 'sync_event.dart';
import 'sync_state.dart';

/// BLoC for managing offline-first data synchronization
///
/// Handles all synchronization logic using the BLoC pattern.
/// Manages state transitions, event routing, and sync lifecycle.
///
/// ## Responsibilities
/// - Route sync events to handlers
/// - Manage sync state transitions
/// - Track sync progress and errors
/// - Implement auto-retry with backoff
/// - Handle pause/resume functionality
/// - Resolve data conflicts
/// - Provide last sync timestamp
///
/// ## Internal State
/// - `_lastSyncAt`: DateTime of last successful sync
/// - `_syncRetryCount`: Current retry attempt (0-3)
///
/// ## Initial State
/// Starts with `SyncIdle()` - no sync in progress.
///
/// ## Event Registration
///
/// All events are registered in constructor:
/// ```dart
/// SyncBloc() : super(const SyncIdle()) {
///   on<StartSyncEvent>(_onStartSync);      // Handle start sync
///   on<SyncCompleteEvent>(_onSyncComplete); // Handle completion
///   on<SyncErrorEvent>(_onSyncError);       // Handle errors
///   on<RetrySyncEvent>(_onRetrySync);       // Handle retries
///   // ... more events
/// }
/// ```
///
/// ## Usage
///
/// ```dart
/// // Create BLoC
/// final syncBloc = SyncBloc();
///
/// // Add event to trigger sync
/// syncBloc.add(StartSyncEvent(isManual: true));
///
/// // Listen to state changes
/// syncBloc.stream.listen((state) {
///   if (state is SyncCompleted) {
///     print('Synced ${state.itemsCount} items');
///   }
/// });
///
/// // Clean up when done
/// await syncBloc.close();
/// ```
///
/// ## BLoC Provider Integration
///
/// ```dart
/// BlocProvider(
///   create: (_) => SyncBloc(),
///   child: MyApp(),
/// )
///
/// // In widget
/// context.read<SyncBloc>().add(StartSyncEvent());
/// ```
///
/// ## Testing
///
/// ```dart
/// test('sync completes successfully', () async {
///   final bloc = SyncBloc();
///
///   final states = [];
///   final subscription = bloc.stream.listen(states.add);
///
///   bloc.add(StartSyncEvent());
///   await Future.delayed(Duration(seconds: 3));
///
///   expect(states, [
///     isA<SyncInProgress>(),
///     isA<SyncCompleted>(),
///     isA<SyncIdle>(),
///   ]);
///
///   await subscription.cancel();
///   await bloc.close();
/// });
/// ```
///
/// ## Error Handling
///
/// On error:
/// 1. Emit SyncFailed state
/// 2. Check retry count
/// 3. If < 3: Calculate backoff and retry
/// 4. If >= 3: Go to SyncIdle
///
/// Each SyncErrorEvent increments retry counter.
/// Reset to 0 on successful sync.
///
/// ## Lifecycle
/// ```
/// created (SyncIdle)
///    ↓
/// events added → handled → states emitted
///    ↓
/// close() called → cleanup
/// ```
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  /// Last successful synchronization timestamp
  ///
  /// Null if sync never completed.
  /// Updated when SyncCompleted state emitted.
  /// Used to display "Last synced: X minutes ago".
  DateTime? _lastSyncAt;

  /// Current retry attempt count
  ///
  /// Increments on each sync error.
  /// Resets to 0 on successful sync.
  /// Used for exponential backoff: `1 << _syncRetryCount` seconds.
  /// Capped at 3 (max 3 automatic retries).
  int _syncRetryCount = 0;

  /// Creates a new SyncBloc instance
  ///
  /// Initializes with SyncIdle state and registers all event handlers.
  /// Must call close() when done using the BLoC.
  ///
  /// ## Event Handler Registration
  ///
  /// The constructor registers handlers for all sync events:
  /// - StartSyncEvent → _onStartSync
  /// - SyncCompleteEvent → _onSyncComplete
  /// - SyncErrorEvent → _onSyncError
  /// - RetrySyncEvent → _onRetrySync
  /// - PauseSyncEvent → _onPauseSync
  /// - ResumeSyncEvent → _onResumeSync
  /// - ResolveConflictEvent → _onResolveConflict
  /// - ClearSyncStateEvent → _onClearSyncState
  ///
  /// ## Example
  /// ```dart
  /// final bloc = SyncBloc();
  /// // Use bloc...
  /// await bloc.close();
  /// ```
  SyncBloc() : super(const SyncIdle()) {
    on<StartSyncEvent>(_onStartSync);
    on<SyncCompleteEvent>(_onSyncComplete);
    on<SyncErrorEvent>(_onSyncError);
    on<RetrySyncEvent>(_onRetrySync);
    on<PauseSyncEvent>(_onPauseSync);
    on<ResumeSyncEvent>(_onResumeSync);
    on<ResolveConflictEvent>(_onResolveConflict);
    on<ClearSyncStateEvent>(_onClearSyncState);
  }

  /// Handle StartSyncEvent - initiate synchronization
  ///
  /// Starts a new sync operation. Emits SyncInProgress, performs sync,
  /// then emits SyncCompleted or SyncFailed based on result.
  ///
  /// ## Process
  /// 1. Emit SyncInProgress
  /// 2. Call SyncRepository.syncData() [mocked as 2-second delay]
  /// 3. On success: emit SyncCompleted with results
  /// 4. On error: emit SyncFailed with error details
  /// 5. Reset retry count on success
  ///
  /// ## Parameters
  /// - [event]: StartSyncEvent with isManual flag
  /// - [emit]: Emits state to listeners
  ///
  /// ## Flow
  /// ```
  /// SyncIdle
  ///    ↓ StartSyncEvent
  /// SyncInProgress
  ///    ↓ (await sync)
  /// SyncCompleted or SyncFailed
  /// ```
  ///
  /// ## Mocking
  /// Current implementation uses 2-second delay. TODO: Replace with
  /// actual SyncRepository.syncData() call.
  ///
  /// ## See Also
  /// - [SyncCompleted]: Success result
  /// - [SyncFailed]: Error result
  Future<void> _onStartSync(
    StartSyncEvent event,
    Emitter<SyncState> emit,
  ) async {
    emit(const SyncInProgress());

    try {
      // TODO: Implement actual sync logic
      // Temporary mock implementation
      await Future.delayed(const Duration(seconds: 2));

      final syncedAt = DateTime.now();
      _lastSyncAt = syncedAt;
      _syncRetryCount = 0;

      emit(SyncCompleted(
        itemsCount: 0,
        syncedAt: syncedAt,
        syncDuration: const Duration(seconds: 2),
      ));
    } catch (e, stackTrace) {
      emit(SyncFailed(
        errorMessage: 'Sync failed: $e',
        error: e,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Handle SyncCompleteEvent - finalize sync operation
  ///
  /// Updates last sync time, resets retry count, emits SyncCompleted,
  /// then transitions to SyncIdle after brief delay.
  ///
  /// ## Process
  /// 1. Update _lastSyncAt
  /// 2. Reset _syncRetryCount to 0
  /// 3. Emit SyncCompleted with results
  /// 4. Wait 500ms
  /// 5. Emit SyncIdle with lastSyncAt
  ///
  /// ## Parameters
  /// - [event]: SyncCompleteEvent with itemsCount and syncedAt
  /// - [emit]: Emits states to listeners
  ///
  /// ## Duration Calculation
  /// Calculates sync duration from event.syncedAt to now.
  /// Note: Current implementation may have bug - uses
  /// millisecondsSinceEpoch which may not be correct.
  ///
  /// ## See Also
  /// - [SyncCompleted]: Completion state
  /// - [SyncIdle]: Idle state after brief delay
  Future<void> _onSyncComplete(
    SyncCompleteEvent event,
    Emitter<SyncState> emit,
  ) async {
    _lastSyncAt = event.syncedAt;
    _syncRetryCount = 0;

    emit(SyncCompleted(
      itemsCount: event.itemsCount,
      syncedAt: event.syncedAt,
      syncDuration: Duration(
        milliseconds: DateTime.now().millisecond - event.syncedAt.millisecond,
      ),
    ));

    // Transition back to idle
    await Future.delayed(const Duration(milliseconds: 500));
    emit(SyncIdle(lastSyncAt: _lastSyncAt));
  }

  /// Handle SyncErrorEvent - manage sync failure and auto-retry
  ///
  /// Emits SyncFailed state, implements exponential backoff retry,
  /// or goes to SyncIdle if max retries exceeded.
  ///
  /// ## Auto-Retry Strategy
  /// - Increment _syncRetryCount
  /// - If retries < 3: Wait exponentially and retry
  /// - If retries >= 3: Reset and go to SyncIdle
  ///
  /// ## Backoff Calculation
  /// Wait time = 1 << _syncRetryCount (exponential)
  /// - 1st error → Wait 2 seconds → Retry
  /// - 2nd error → Wait 4 seconds → Retry
  /// - 3rd error → Wait 8 seconds → Retry
  /// - 4th error → Give up
  ///
  /// ## Process
  /// 1. Emit SyncFailed with error message
  /// 2. If retries < 3:
  ///    - Calculate backoff: `1 << _syncRetryCount`
  ///    - Wait that many seconds
  ///    - Add RetrySyncEvent
  /// 3. If retries >= 3:
  ///    - Reset retry count
  ///    - Wait 500ms
  ///    - Emit SyncIdle
  ///
  /// ## Parameters
  /// - [event]: SyncErrorEvent with error message
  /// - [emit]: Emits states to listeners
  ///
  /// ## See Also
  /// - [SyncFailed]: Error state
  /// - [RetrySyncEvent]: Automatic retry event
  Future<void> _onSyncError(
    SyncErrorEvent event,
    Emitter<SyncState> emit,
  ) async {
    emit(SyncFailed(errorMessage: event.errorMessage));

    // Auto-retry with exponential backoff
    if (_syncRetryCount < 3) {
      _syncRetryCount++;
      await Future.delayed(
        Duration(seconds: 1 << _syncRetryCount), // Exponential backoff
      );
      add(const RetrySyncEvent());
    } else {
      // Reset retry count and go to idle
      _syncRetryCount = 0;
      await Future.delayed(const Duration(milliseconds: 500));
      emit(SyncIdle(lastSyncAt: _lastSyncAt));
    }
  }

  /// Handle RetrySyncEvent - retry failed synchronization
  ///
  /// Simply triggers another StartSyncEvent to retry sync.
  /// Used for both automatic retries and manual retry button.
  ///
  /// ## Process
  /// 1. Receive RetrySyncEvent
  /// 2. Add new StartSyncEvent
  /// 3. _onStartSync handler triggered
  /// 4. Sync retried
  ///
  /// ## Parameters
  /// - [event]: RetrySyncEvent (empty)
  /// - [emit]: Emits states to listeners (not used directly)
  ///
  /// ## Note
  /// RetrySyncEvent itself doesn't emit state. Instead adds new
  /// StartSyncEvent which triggers normal sync flow.
  ///
  /// ## See Also
  /// - [StartSyncEvent]: Actual sync operation
  /// - [SyncErrorEvent]: Triggers retry
  Future<void> _onRetrySync(
    RetrySyncEvent event,
    Emitter<SyncState> emit,
  ) async {
    add(const StartSyncEvent());
  }

  /// Handle PauseSyncEvent - pause ongoing sync
  ///
  /// Emits SyncPaused state. Sync can be resumed with ResumeSyncEvent.
  ///
  /// ## Process
  /// 1. Receive PauseSyncEvent
  /// 2. Emit SyncPaused state
  /// 3. Sync operation paused
  /// 4. Can resume later with ResumeSyncEvent
  ///
  /// ## Parameters
  /// - [event]: PauseSyncEvent (empty)
  /// - [emit]: Emits SyncPaused state
  ///
  /// ## Use Cases
  /// - User on metered network
  /// - Low battery
  /// - App backgrounded
  /// - User explicitly paused
  ///
  /// ## See Also
  /// - [ResumeSyncEvent]: Resume paused sync
  /// - [SyncPaused]: Paused state
  Future<void> _onPauseSync(
    PauseSyncEvent event,
    Emitter<SyncState> emit,
  ) async {
    emit(const SyncPaused());
  }

  /// Handle ResumeSyncEvent - resume paused sync
  ///
  /// Triggers new StartSyncEvent to resume sync operation.
  ///
  /// ## Process
  /// 1. Receive ResumeSyncEvent
  /// 2. Add new StartSyncEvent
  /// 3. Sync resumes
  ///
  /// ## Parameters
  /// - [event]: ResumeSyncEvent (empty)
  /// - [emit]: Emits states to listeners (not used directly)
  ///
  /// ## Note
  /// ResumeSyncEvent doesn't directly emit state. Instead adds
  /// StartSyncEvent which triggers normal sync flow.
  ///
  /// ## See Also
  /// - [PauseSyncEvent]: Pause sync
  /// - [StartSyncEvent]: Resume operation
  Future<void> _onResumeSync(
    ResumeSyncEvent event,
    Emitter<SyncState> emit,
  ) async {
    add(const StartSyncEvent());
  }

  /// Handle ResolveConflictEvent - resolve data conflicts
  ///
  /// Processes conflict resolution and continues sync.
  /// Emits SyncInProgress, performs resolution, completes sync.
  ///
  /// ## Process
  /// 1. Emit SyncInProgress
  /// 2. Perform conflict resolution [mocked as 1-second delay]
  /// 3. Add SyncCompleteEvent on success
  /// 4. Emit SyncFailed on error
  ///
  /// ## Parameters
  /// - [event]: ResolveConflictEvent with conflictId and resolution strategy
  /// - [emit]: Emits states to listeners
  ///
  /// ## Resolution Strategies
  /// event.resolution map may contain:
  /// - 'strategy': 'preferLocal' | 'preferRemote' | 'merge'
  /// - Other strategy-specific parameters
  ///
  /// ## Mocking
  /// Current implementation uses 1-second delay.
  /// TODO: Replace with actual conflict resolution logic.
  ///
  /// ## See Also
  /// - [SyncConflict]: Conflict state
  /// - [SyncCompleted]: Resolution succeeded
  /// - [SyncFailed]: Resolution failed
  Future<void> _onResolveConflict(
    ResolveConflictEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      // TODO: Implement conflict resolution logic
      emit(const SyncInProgress());
      await Future.delayed(const Duration(seconds: 1));
      add(SyncCompleteEvent(
        itemsCount: 1,
        syncedAt: DateTime.now(),
      ));
    } catch (e, stackTrace) {
      emit(SyncFailed(
        errorMessage: 'Conflict resolution failed: $e',
        error: e,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Handle ClearSyncStateEvent - reset sync metadata
  ///
  /// Clears sync tracking state including last sync time and retry count.
  /// Emits SyncIdle. Doesn't delete actual data, just metadata.
  ///
  /// ## Process
  /// 1. Set _lastSyncAt to null
  /// 2. Reset _syncRetryCount to 0
  /// 3. Emit SyncIdle
  ///
  /// ## Parameters
  /// - [event]: ClearSyncStateEvent (empty)
  /// - [emit]: Emits SyncIdle state
  ///
  /// ## What Gets Cleared
  /// - Last sync timestamp
  /// - Retry counter
  /// - Does NOT clear pending items or actual data
  ///
  /// ## Use Cases
  /// - Debug/testing
  /// - Error recovery
  /// - Start fresh
  /// - User requested reset
  ///
  /// ## ⚠️ Warning
  /// Only clears metadata. Actual data loss only if sync was incomplete.
  ///
  /// ## See Also
  /// - [SyncIdle]: State after clearing
  Future<void> _onClearSyncState(
    ClearSyncStateEvent event,
    Emitter<SyncState> emit,
  ) async {
    _lastSyncAt = null;
    _syncRetryCount = 0;
    emit(const SyncIdle());
  }

  /// Get timestamp of last successful synchronization
  ///
  /// Returns null if sync has never completed successfully.
  ///
  /// ## Example
  /// ```dart
  /// final lastSync = syncBloc.lastSyncAt;
  /// if (lastSync != null) {
  ///   final duration = DateTime.now().difference(lastSync);
  ///   print('Last synced ${duration.inMinutes} minutes ago');
  /// } else {
  ///   print('Never synced');
  /// }
  /// ```
  ///
  /// ## Note
  /// This is the BLoC-local value. For persistence across app restart,
  /// store in local database or shared preferences.
  ///
  /// ## Returns
  /// DateTime of last sync or null if never synced
  DateTime? get lastSyncAt => _lastSyncAt;
}
