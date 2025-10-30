# QuicUI Real-Time Updates Implementation Plan

**Document Version:** 1.0  
**Date:** October 30, 2025  
**Status:** Planning Phase  
**Scope:** PostgreSQL Real-Time Subscriptions via Supabase Realtime

---

## 1. Executive Summary

This document outlines the implementation plan for adding **real-time updates** to QuicUI using Supabase's PostgreSQL real-time capabilities. This enables:

- **Instant screen updates** when changed on backend
- **Live collaboration** - see changes as they happen
- **Offline support** - queue updates, sync when online
- **Conflict resolution** - merge local and remote changes
- **Connection management** - auto-reconnect with backoff

### Key Metrics
- **Latency:** <500ms for updates
- **Reliability:** 99.5% uptime with auto-reconnect
- **Scalability:** Support 1000+ concurrent subscriptions
- **Battery:** Optimized for mobile with adaptive refresh rates

---

## 2. Architecture Overview

### 2.1 Current Data Flow (REST-based)

```
ScreenBloc
    ↓
ScreenRepository
    ↓
SupabaseService (REST API)
    ↓
Supabase Backend (PostgreSQL)
```

**Issues:**
- Polling-based (inefficient)
- High latency (up to 30s)
- Battery drain (constant requests)
- Scalability limits

### 2.2 Proposed Real-Time Architecture

```
RealtimeBloc ←→ RealtimeService (WebSocket)
    ↓                           ↓
ScreenBloc                  Supabase Realtime
    ↓                           ↓
ScreenRepository       PostgreSQL Events
    ↓
SyncRepository
    ↓
Local Cache + Remote Sync
```

**Advantages:**
- Event-driven (low latency ~100ms)
- Push-based (instant updates)
- Battery efficient (no polling)
- Scalable (WebSocket-based)

### 2.3 Component Layers

```
┌─────────────────────────────────────────┐
│         UI Layer                        │
│  ├── ScreenView (with real-time)       │
│  ├── RealtimeIndicator                  │
│  └── SyncStatusBanner                   │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         BLoC Layer                      │
│  ├── ScreenBloc (subscribes to updates) │
│  ├── SyncBloc (handles sync)            │
│  └── RealtimeBloc (manages subscriptions│
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      Repository Layer                   │
│  ├── ScreenRepository (real-time stream)│
│  ├── SyncRepository (conflict handling) │
│  └── RealtimeRepository (subscriptions) │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      Service Layer                      │
│  ├── RealtimeService (WebSocket mgmt)   │
│  ├── SupabaseService (REST + Realtime)  │
│  └── StorageService (local cache)       │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      Data Layer                         │
│  ├── Supabase Realtime (PostgreSQL)     │
│  ├── Local Cache (ObjectBox/Hive)       │
│  └── Sync Queue                         │
└─────────────────────────────────────────┘
```

---

## 3. Detailed Implementation Plan

### 3.1 Phase 1: Core Real-Time Service (Week 1)

#### 3.1.1 Create RealtimeService

**File:** `lib/src/services/realtime_service.dart`

**Responsibilities:**
- Manage Supabase real-time subscriptions
- Handle WebSocket connections
- Emit real-time events

**Core Methods:**

```dart
class RealtimeService {
  // Subscription Management
  Future<void> subscribeToScreens(Function(Map) onUpdate);
  Future<void> subscribeToScreen(String screenId, Function(Map) onUpdate);
  Future<void> subscribeToTable(String table, Function(PostgresChangePayload) onUpdate);
  
  // Lifecycle
  Future<void> initialize();
  Future<void> connect();
  Future<void> disconnect();
  
  // Status
  Stream<ConnectionStatus> get connectionStatus;
  bool get isConnected;
  
  // Utilities
  List<String> get activeSubscriptions;
  void clearAllSubscriptions();
}
```

**Features:**
- ✅ PostgreSQL Change Events (INSERT, UPDATE, DELETE)
- ✅ Connection status tracking
- ✅ Automatic reconnection with exponential backoff
- ✅ Error handling and recovery
- ✅ Memory management (cleanup subscriptions)

**Example Usage:**

```dart
final realtimeService = RealtimeService();
await realtimeService.initialize();

realtimeService.subscribeToScreen(
  'home_screen',
  (update) {
    print('Screen updated: ${update.newRecord}');
    // Update local cache
    // Emit to BLoC
  },
);
```

#### 3.1.2 Connection Status Model

**File:** `lib/src/models/connection_status.dart`

```dart
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class ConnectionStatus extends Equatable {
  final ConnectionState state;
  final String? message;
  final DateTime lastConnected;
  final int reconnectAttempts;
  final Duration? nextRetryIn;
  
  // Getters
  bool get isOnline => state == ConnectionState.connected;
  bool get isOffline => state == ConnectionState.disconnected;
  bool get isRetrying => state == ConnectionState.reconnecting;
}
```

### 3.2 Phase 2: Event Models & Repositories (Week 1-2)

#### 3.2.1 Real-Time Event Models

**File:** `lib/src/models/realtime_event.dart`

```dart
enum EventType {
  insert,
  update,
  delete,
}

class RealtimeEvent<T> extends Equatable {
  final EventType type;
  final String table;
  final T oldRecord;
  final T newRecord;
  final DateTime timestamp;
  final String userId;
  final String deviceId;
  
  // Getters
  bool get isLocal => userId == getCurrentUserId();
  bool get isRemote => !isLocal;
}

class ScreenRealtimeEvent extends RealtimeEvent<Screen> {
  // Specific for Screen events
}
```

#### 3.2.2 Update RealtimeRepository

**File:** `lib/src/repositories/realtime_repository.dart`

```dart
class RealtimeRepository {
  // Streams for subscriptions
  Stream<RealtimeEvent<Screen>> get screenUpdates;
  Stream<ConnectionStatus> get connectionStatus;
  
  // Subscription management
  Future<void> subscribeToScreen(String screenId);
  Future<void> subscribeToAllScreens();
  Future<void> unsubscribeFromScreen(String screenId);
  
  // Query
  List<String> get activeSubscriptions;
  bool isSubscribedTo(String screenId);
}
```

#### 3.2.3 Update ScreenRepository with Real-Time

**File:** `lib/src/repositories/screen_repository.dart`

**Add:**
```dart
class ScreenRepository {
  // Existing methods...
  
  // NEW: Real-time streams
  Stream<RealtimeEvent<Screen>> subscribeToScreenUpdates(String screenId);
  Stream<RealtimeEvent<Screen>> subscribeToAllScreenUpdates();
  
  // Handle incoming real-time updates
  Future<void> _handleRealtimeUpdate(RealtimeEvent<Screen> event);
}
```

**Logic:**
1. Receive real-time event from RealtimeService
2. Check if local changes conflict
3. If conflict → run conflict resolution
4. Update local cache
5. Emit to listeners

### 3.3 Phase 3: Real-Time BLoC (Week 2)

#### 3.3.1 Create RealtimeBloc

**File:** `lib/src/bloc/realtime/realtime_bloc.dart`

**State Machine:**

```
RealtimeInitial
    ↓
RealtimeConnecting
    ↓ (success)
RealtimeConnected
    ├→ RealtimeUpdate (on event)
    ├→ RealtimeDisconnected (on error)
    └→ RealtimeError (on fatal error)
```

**Events:**

```dart
abstract class RealtimeEvent extends Equatable {}

class InitializeRealtimeEvent extends RealtimeEvent {}
class ConnectRealtimeEvent extends RealtimeEvent {}
class DisconnectRealtimeEvent extends RealtimeEvent {}
class SubscribeToScreenEvent extends RealtimeEvent {
  final String screenId;
}
class UnsubscribeFromScreenEvent extends RealtimeEvent {
  final String screenId;
}
class HandleRealtimeUpdateEvent extends RealtimeEvent {
  final RealtimeEvent<Screen> update;
}
class RealtimeErrorEvent extends RealtimeEvent {
  final String message;
  final StackTrace stackTrace;
}
```

**States:**

```dart
abstract class RealtimeState extends Equatable {}

class RealtimeInitial extends RealtimeState {}
class RealtimeConnecting extends RealtimeState {}
class RealtimeConnected extends RealtimeState {
  final int activeSubscriptions;
}
class RealtimeUpdate extends RealtimeState {
  final RealtimeEvent<Screen> update;
  final Screen updatedScreen;
}
class RealtimeDisconnected extends RealtimeState {
  final String reason;
}
class RealtimeError extends RealtimeState {
  final String message;
}
```

**Implementation:**

```dart
class RealtimeBloc extends Bloc<RealtimeEvent, RealtimeState> {
  final RealtimeService _realtimeService;
  final ScreenRepository _screenRepository;
  
  RealtimeBloc({
    required RealtimeService realtimeService,
    required ScreenRepository screenRepository,
  }) : super(RealtimeInitial()) {
    on<InitializeRealtimeEvent>(_onInitialize);
    on<SubscribeToScreenEvent>(_onSubscribe);
    on<HandleRealtimeUpdateEvent>(_onUpdate);
    // ... other event handlers
  }
  
  Future<void> _onInitialize(
    InitializeRealtimeEvent event,
    Emitter<RealtimeState> emit,
  ) async {
    try {
      emit(RealtimeConnecting());
      await _realtimeService.initialize();
      emit(RealtimeConnected(activeSubscriptions: 0));
      
      // Listen to connection status
      _realtimeService.connectionStatus.listen((status) {
        if (!status.isOnline) {
          add(RealtimeErrorEvent('Disconnected: ${status.message}'));
        }
      });
    } catch (e) {
      emit(RealtimeError(message: e.toString()));
    }
  }
}
```

### 3.4 Phase 4: Integration with Sync (Week 2-3)

#### 3.4.1 Coordinate Real-Time & Sync BLoCs

**Update SyncBloc:**

```dart
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final RealtimeBloc _realtimeBloc;
  
  SyncBloc({required RealtimeBloc realtimeBloc})
    : _realtimeBloc = realtimeBloc {
    // When real-time update received, pause auto-sync
    _realtimeBloc.stream.listen((state) {
      if (state is RealtimeUpdate) {
        _handleRealtimeUpdate(state.update);
      }
    });
  }
  
  Future<void> _handleRealtimeUpdate(RealtimeEvent<Screen> event) async {
    // 1. Check if conflicting with pending sync
    final pending = await _syncRepository.getPendingItemsCount();
    if (pending > 0) {
      // Check if same item is pending
      if (_hasPendingChange(event.newRecord.id)) {
        // Run conflict resolution
        add(ResolveConflictEvent(...));
      }
    }
    
    // 2. Update local cache
    await _screenRepository.saveScreen(
      event.newRecord.id,
      event.newRecord.toJson(),
    );
    
    // 3. Emit update state
    emit(SyncUpdated(itemsCount: 1));
  }
}
```

#### 3.4.2 Conflict Resolution Strategy

**Rules:**
1. **Local changes pending + Remote update:**
   - Check timestamps
   - If remote is newer → merge (keeping local edits)
   - If local is newer → ignore remote

2. **Concurrent edits:**
   - Use field-level merging
   - Keep non-conflicting changes from both
   - Ask user for conflicting fields

3. **Delete conflicts:**
   - If local delete + remote update → delete wins
   - If local update + remote delete → delete wins

### 3.5 Phase 5: UI Integration (Week 3)

#### 3.5.1 Update ScreenView

**Add Real-Time Indicators:**

```dart
class ScreenView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RealtimeBloc, RealtimeState>(
      builder: (context, realtimeState) {
        return BlocBuilder<ScreenBloc, ScreenState>(
          builder: (context, screenState) {
            return Stack(
              children: [
                // Main screen content
                if (screenState is ScreenLoaded)
                  _buildScreen(screenState.screenData),
                
                // Real-time indicator
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildConnectionIndicator(realtimeState),
                ),
                
                // Sync status banner
                if (screenState is ScreenUpdating)
                  _buildSyncBanner(),
              ],
            );
          },
        );
      },
    );
  }
  
  Widget _buildConnectionIndicator(RealtimeState state) {
    if (state is RealtimeConnected) {
      return Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.cloud_done, color: Colors.white, size: 16),
      );
    }
    // ... other states
  }
}
```

#### 3.5.2 Real-Time Update Widget

**New Widget:** `lib/src/widgets/realtime_listener.dart`

```dart
class RealtimeListener extends StatefulWidget {
  final String screenId;
  final Function(RealtimeEvent<Screen>) onUpdate;
  final Widget child;
  
  @override
  State<RealtimeListener> createState() => _RealtimeListenerState();
}

class _RealtimeListenerState extends State<RealtimeListener> {
  late StreamSubscription<RealtimeEvent<Screen>> _subscription;
  
  @override
  void initState() {
    super.initState();
    _subscription = context.read<RealtimeRepository>()
        .subscribeToScreenUpdates(widget.screenId)
        .listen(widget.onUpdate);
  }
  
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) => widget.child;
}
```

### 3.6 Phase 6: Testing (Week 3-4)

#### 3.6.1 Unit Tests

**File:** `test/unit/services/realtime_service_test.dart`

```dart
void main() {
  group('RealtimeService', () {
    test('connects to Supabase realtime', () async {
      final service = RealtimeService();
      await service.initialize();
      expect(service.isConnected, isTrue);
    });
    
    test('subscribes to screen updates', () async {
      final updates = <RealtimeEvent>[];
      await service.subscribeToScreen(
        'test_screen',
        (event) => updates.add(event),
      );
      expect(updates, isNotEmpty);
    });
    
    test('auto-reconnects on disconnect', () async {
      // Simulate disconnect
      await service.disconnect();
      
      // Should auto-reconnect
      await Future.delayed(Duration(seconds: 2));
      expect(service.isConnected, isTrue);
    });
  });
}
```

#### 3.6.2 Integration Tests

**File:** `test/integration/realtime_integration_test.dart`

```dart
void main() {
  group('Real-Time Integration', () {
    test('updates propagate from backend to UI', () async {
      // 1. Setup test app
      // 2. Subscribe to screen
      // 3. Trigger backend update
      // 4. Verify UI updates
    });
    
    test('conflict resolution on concurrent edits', () async {
      // 1. Make local change
      // 2. Trigger concurrent remote update
      // 3. Verify conflict resolution
    });
  });
}
```

### 3.7 Phase 7: Documentation (Week 4)

#### 3.7.1 API Documentation

Add to `lib/src/services/realtime_service.dart`:

```dart
/// # Real-Time Updates Guide
///
/// QuicUI supports real-time updates via Supabase PostgreSQL real-time events.
///
/// ## Quick Start
///
/// ```dart
/// // 1. Initialize real-time service
/// final realtimeService = RealtimeService();
/// await realtimeService.initialize();
///
/// // 2. Subscribe to updates
/// realtimeService.subscribeToScreen(
///   'home_screen',
///   (update) => print('Screen updated: ${update.newRecord}'),
/// );
///
/// // 3. Use in BLoC
/// context.read<RealtimeBloc>().add(SubscribeToScreenEvent('home_screen'));
/// ```
///
/// ## Update Types
///
/// - **INSERT**: New screen created
/// - **UPDATE**: Screen fields modified
/// - **DELETE**: Screen removed
///
/// ## Conflict Resolution
///
/// When local pending changes conflict with remote updates:
/// 1. Automatic: Local recent changes → Local wins
/// 2. Automatic: Remote recent changes → Remote wins
/// 3. Manual: Different users → Show UI dialog
///
/// ## Performance Tips
///
/// - Subscribe only to screens you need
/// - Use targeted subscriptions (single screen vs all)
/// - Clean up subscriptions when done
/// - Monitor connection status
```

#### 3.7.2 README Section

Add to `README.md`:

```markdown
## Real-Time Updates

QuicUI supports real-time screen updates via Supabase's PostgreSQL real-time subscriptions.

### Enable Real-Time Updates

```dart
await QuicUIService.instance.initializeRealtime();

// Listen for updates
context.read<RealtimeBloc>().add(
  SubscribeToScreenEvent('home_screen'),
);
```

### Connection Status

```dart
BlocBuilder<RealtimeBloc, RealtimeState>(
  builder: (context, state) {
    if (state is RealtimeConnected) {
      return Text('Connected - ${state.activeSubscriptions} subscriptions');
    }
    return Text('Disconnected');
  },
)
```
```

---

## 4. Database Schema Requirements

### 4.1 Screens Table

```sql
CREATE TABLE IF NOT EXISTS screens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  app_id UUID NOT NULL,
  name TEXT NOT NULL,
  title TEXT,
  description TEXT,
  
  -- UI Definition
  widgets JSONB NOT NULL DEFAULT '{}',
  layout JSONB NOT NULL DEFAULT '{}',
  state JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  
  -- Versioning
  version INTEGER DEFAULT 1,
  
  -- Timestamps
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP,
  
  -- Sync tracking
  is_synced BOOLEAN DEFAULT true,
  last_synced_at TIMESTAMP,
  
  -- User tracking
  created_by UUID REFERENCES auth.users,
  updated_by UUID REFERENCES auth.users,
  
  CONSTRAINT screens_app_id_name UNIQUE(app_id, name)
);

-- Enable real-time
ALTER TABLE screens REPLICA IDENTITY FULL;
```

### 4.2 Realtime Policy

```sql
-- Allow authenticated users to see updates
CREATE POLICY "Allow realtime for authenticated users"
  ON screens
  FOR SELECT
  USING (auth.role() = 'authenticated');
```

---

## 5. Configuration

### 5.1 Supabase RealTime Settings

**Supabase Console → Project Settings → Realtime:**
- ✅ Enable realtime
- ✅ Add `screens` table
- ✅ Set Replica Identity to FULL
- ✅ Enable row-level security (RLS)

### 5.2 pubspec.yaml Updates

No new dependencies needed! `supabase_flutter: ^2.10.3` includes:
- ✅ `realtime_client` (WebSocket)
- ✅ `postgrest` (REST)
- ✅ Connection management

---

## 6. Implementation Timeline

| Phase | Task | Duration | Week |
|-------|------|----------|------|
| 1 | RealtimeService + ConnectionStatus | 3 days | 1 |
| 2 | Event models + Repositories | 3 days | 1-2 |
| 3 | RealtimeBloc state machine | 3 days | 2 |
| 4 | Sync + Real-Time integration | 3 days | 2-3 |
| 5 | UI updates + widgets | 3 days | 3 |
| 6 | Unit + Integration tests | 3 days | 3-4 |
| 7 | Documentation + examples | 2 days | 4 |
| **Total** | **~4 weeks** | | |

---

## 7. Risk Analysis

### 7.1 Potential Issues

| Risk | Impact | Mitigation |
|------|--------|-----------|
| WebSocket timeout | High latency | Auto-reconnect with backoff |
| Conflict storms | Data corruption | Timeout between conflicts |
| Memory leaks | App crash | Cleanup on subscription end |
| Offline accumulation | Sync delay | Batch sync with chunking |
| Server overload | Service degradation | Connection pooling + limits |

### 7.2 Mitigation Strategies

1. **Testing:** Comprehensive test coverage (80%+)
2. **Monitoring:** Connection metrics, error tracking
3. **Fallback:** REST API polling as fallback
4. **Limits:** Max subscriptions per session (10)
5. **Cleanup:** Auto-unsubscribe after 5 min inactivity

---

## 8. Success Criteria

✅ **Functional**
- [ ] Real-time updates arrive <500ms
- [ ] Conflict resolution works automatically
- [ ] Offline → online sync seamless
- [ ] Connection auto-restores

✅ **Performance**
- [ ] No memory leaks (28-day test)
- [ ] CPU <2% during idle subscriptions
- [ ] Battery drain <10% per hour
- [ ] Handle 1000+ events/minute

✅ **Reliability**
- [ ] 99.5% uptime
- [ ] All tests pass (100% coverage)
- [ ] No data loss on crash
- [ ] Graceful degradation offline

✅ **UX**
- [ ] User sees "syncing" indicators
- [ ] Instant UI updates on remote changes
- [ ] Clear error messages
- [ ] No app freezing

---

## 9. Future Enhancements

🚀 **Phase 2 (Post-MVP):**
- [ ] Selective real-time (subscribe by filter)
- [ ] Broadcast channels (team collaboration)
- [ ] Presence tracking (see who's online)
- [ ] Optimistic updates (instant local feedback)
- [ ] Replication backoff (smart retry intervals)

🚀 **Phase 3 (Long-term):**
- [ ] Audit log with real-time events
- [ ] Time-travel debugging (replay changes)
- [ ] Analytics on real-time events
- [ ] CDN caching with invalidation
- [ ] GraphQL subscriptions alternative

---

## 10. Code References

### Key Files to Create/Update

**Create:**
- ✨ `lib/src/services/realtime_service.dart`
- ✨ `lib/src/repositories/realtime_repository.dart`
- ✨ `lib/src/bloc/realtime/realtime_bloc.dart`
- ✨ `lib/src/models/realtime_event.dart`
- ✨ `lib/src/models/connection_status.dart`
- ✨ `lib/src/widgets/realtime_listener.dart`

**Update:**
- 📝 `lib/src/services/supabase_service.dart`
- 📝 `lib/src/repositories/screen_repository.dart`
- 📝 `lib/src/repositories/sync_repository.dart`
- 📝 `lib/src/bloc/sync/sync_bloc.dart`
- 📝 `lib/src/widgets/screen_view.dart`
- 📝 `README.md`

**Test:**
- 🧪 `test/unit/services/realtime_service_test.dart`
- 🧪 `test/unit/bloc/realtime_bloc_test.dart`
- 🧪 `test/integration/realtime_integration_test.dart`

---

## 11. Next Steps

1. **Review & Approval:** Get feedback on this plan
2. **Setup Database:** Create Supabase RealTime schema
3. **Implement Phase 1:** Start with RealtimeService
4. **Iterate:** Move through phases with testing
5. **Document:** Add comprehensive docs & examples
6. **Release:** v1.1.0 with real-time support

---

## References

- [Supabase Realtime Docs](https://supabase.com/docs/guides/realtime)
- [PostgreSQL Logical Replication](https://www.postgresql.org/docs/current/logical-replication.html)
- [Flutter BLoC Pattern](https://bloclibrary.dev)
- [Flutter Streams Best Practices](https://dart.dev/articles/libraries/creating-streams-in-dart)

