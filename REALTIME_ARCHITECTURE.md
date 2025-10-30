# Real-Time Architecture: Detailed Diagrams & Flows

## 1. System Architecture Diagram

```
┌───────────────────────────────────────────────────────────────────────────┐
│                           QUICUI Application Layer                         │
├───────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │                        UI Layer (Widgets)                            │ │
│  │  ┌────────────────────┐  ┌────────────────────┐  ┌──────────────┐   │ │
│  │  │   ScreenView       │  │  RealtimeListener  │  │ Sync Banner  │   │ │
│  │  │                    │  │                    │  │              │   │ │
│  │  │ • Renders screen   │  │ • Subscribes to    │  │ • Shows      │   │ │
│  │  │ • Shows content    │  │   updates          │  │   sync state │   │ │
│  │  │ • Updates on sync  │  │ • Emits to BLoC    │  │ • Progress   │   │ │
│  │  └────────────────────┘  └────────────────────┘  └──────────────┘   │ │
│  │           ↓                        ↓                      ↓             │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                     ↓                                       │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │                    BLoC Layer (State Management)                     │ │
│  │  ┌────────────────────────────┐  ┌──────────────────────────────┐   │ │
│  │  │    ScreenBloc              │  │    RealtimeBloc              │   │ │
│  │  │                            │  │                              │   │ │
│  │  │ Events:                    │  │ Events:                      │   │ │
│  │  │ • FetchScreenEvent         │  │ • InitializeRealtimeEvent    │   │ │
│  │  │ • UpdateScreenEvent        │  │ • SubscribeToScreenEvent     │   │ │
│  │  │ • HandleRealtimeUpdate     │  │ • HandleRealtimeUpdateEvent  │   │ │
│  │  │                            │  │                              │   │ │
│  │  │ States:                    │  │ States:                      │   │ │
│  │  │ • ScreenLoading            │  │ • RealtimeConnected          │   │ │
│  │  │ • ScreenLoaded             │  │ • RealtimeDisconnected       │   │ │
│  │  │ • ScreenUpdating           │  │ • RealtimeUpdate             │   │ │
│  │  │ • ScreenError              │  │ • RealtimeError              │   │ │
│  │  └────────────────────────────┘  └──────────────────────────────┘   │ │
│  │                 ↓                             ↓                       │ │
│  │         ┌───────────────────────────────────────────┐                │ │
│  │         │      SyncBloc                             │                │ │
│  │         │                                           │                │ │
│  │         │ • Coordinates sync & real-time            │                │ │
│  │         │ • Conflict resolution                     │                │ │
│  │         │ • Pending change queue                    │                │ │
│  │         └───────────────────────────────────────────┘                │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                    ↓                                      ↓                  │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │              Repository Layer (Data Access)                          │ │
│  │  ┌──────────────────────────┐  ┌────────────────────────────────┐   │ │
│  │  │  ScreenRepository        │  │  RealtimeRepository            │   │ │
│  │  │                          │  │                                │   │ │
│  │  │ • getScreen()            │  │ • subscribeToScreen()          │   │ │
│  │  │ • listScreens()          │  │ • subscribeToAllScreens()      │   │ │
│  │  │ • saveScreen()           │  │ • unsubscribeFromScreen()      │   │ │
│  │  │ • deleteScreen()         │  │ • activeSubscriptions          │   │ │
│  │  │ • Real-time stream       │  │ • connectionStatus stream      │   │ │
│  │  └──────────────────────────┘  └────────────────────────────────┘   │ │
│  │           ↓                              ↓                            │ │
│  │  ┌──────────────────────────────────────────────────────────────┐   │ │
│  │  │          SyncRepository                                      │   │ │
│  │  │                                                              │   │ │
│  │  │ • syncData()        • getPendingItemsCount()               │   │ │
│  │  │ • resolveConflict() • mergeChanges()                       │   │ │
│  │  └──────────────────────────────────────────────────────────────┘   │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                    ↓                                      ↓                  │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │              Service Layer (Business Logic)                          │ │
│  │  ┌────────────────────────────┐  ┌──────────────────────────────┐   │ │
│  │  │  SupabaseService           │  │  RealtimeService             │   │ │
│  │  │  (REST API Client)         │  │  (WebSocket Manager)         │   │ │
│  │  │                            │  │                              │   │ │
│  │  │ • fetchScreen()            │  │ • initialize()               │   │ │
│  │  │ • updateScreen()           │  │ • subscribeToTable()         │   │ │
│  │  │ • createScreen()           │  │ • connect/disconnect()       │   │ │
│  │  │ • batchSync()              │  │ • connectionStatus stream    │   │ │
│  │  │ • searchScreens()          │  │ • Auto-reconnect logic       │   │ │
│  │  └────────────────────────────┘  └──────────────────────────────┘   │ │
│  │           ↓                              ↓                            │ │
│  │  ┌──────────────────────────────────────────────────────────────┐   │ │
│  │  │              StorageService (Local Cache)                    │   │ │
│  │  │                                                              │   │ │
│  │  │ • save(key, data)  • get(key)  • delete(key)  • clear()    │   │ │
│  │  │ • Uses: ObjectBox + Hive + SharedPreferences               │   │ │
│  │  └──────────────────────────────────────────────────────────────┘   │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                      ↓                                      │
│  ┌──────────────────────────────────────────────────────────────────────┐ │
│  │                       Data Layer                                     │ │
│  │  ┌────────────────────────┐  ┌────────────────────────────────┐   │ │
│  │  │  Local Cache           │  │  Sync Queue                    │   │ │
│  │  │  (ObjectBox)           │  │                                │   │ │
│  │  │                        │  │ • Pending creates              │   │ │
│  │  │ • Screens cache        │  │ • Pending updates              │   │ │
│  │  │ • Metadata cache       │  │ • Pending deletes              │   │ │
│  │  │ • Quick access         │  │ • Sync status flags            │   │ │
│  │  └────────────────────────┘  └────────────────────────────────┘   │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────────┘
                                     ↕ (HTTP & WebSocket)
┌───────────────────────────────────────────────────────────────────────────┐
│                    Supabase Backend (Remote)                              │
├───────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌────────────────────────────┐  ┌──────────────────────────────────┐    │
│  │  Supabase REST API         │  │  Supabase Realtime (WebSocket)   │    │
│  │                            │  │                                  │    │
│  │ Endpoints:                 │  │ • PostgreSQL Change Events       │    │
│  │ • GET /screens/:id         │  │ • INSERT notifications           │    │
│  │ • POST /screens            │  │ • UPDATE notifications           │    │
│  │ • PATCH /screens/:id       │  │ • DELETE notifications           │    │
│  │ • DELETE /screens/:id      │  │ • Real-time subscriptions        │    │
│  │ • GET /screens?search=...  │  │ • Payload delivery via WS        │    │
│  │                            │  │                                  │    │
│  │ Returns: JSON responses    │  │ Emits: PostgresChangePayload     │    │
│  │ Latency: ~100-200ms        │  │ Latency: <100ms                  │    │
│  └────────────────────────────┘  └──────────────────────────────────┘    │
│           ↓                                ↓                               │
│  ┌──────────────────────────────────────────────────────────────────┐    │
│  │             PostgreSQL Database                                  │    │
│  │                                                                  │    │
│  │  ┌────────────────────────────────────┐  REPLICA IDENTITY: FULL │    │
│  │  │  screens table                     │  ✅ Enable Realtime      │    │
│  │  │                                    │  ✅ Enable RLS           │    │
│  │  │ • id (PK)      • updated_at        │  ✅ CREATE TRIGGER       │    │
│  │  │ • name         • widgets (JSONB)   │                          │    │
│  │  │ • title        • layout (JSONB)    │  Logical Replication     │    │
│  │  │ • created_by   • created_at        │  Publications:           │    │
│  │  │ • updated_by   • is_synced         │  • "screens_pub"         │    │
│  │  └────────────────────────────────────┘                          │    │
│  └──────────────────────────────────────────────────────────────────┘    │
│                                                                             │
└───────────────────────────────────────────────────────────────────────────┘
```

## 2. Real-Time Event Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                 Backend Update (Someone edits screen)                    │
└─────────────────────────────────────────────────────────────────────────┘
                                  │
                                  ↓
                    ┌─────────────────────────────┐
                    │  Update SQL TRIGGER fires   │
                    │  (PostgreSQL)               │
                    └─────────────────────────────┘
                                  │
                                  ↓
        ┌─────────────────────────────────────────────────┐
        │   PostgreSQL Logical Replication               │
        │   • Detects changes on 'screens' table          │
        │   • Formats as WAL record                       │
        │   • Sends to Replication Slot                   │
        └─────────────────────────────────────────────────┘
                                  │
                                  ↓
        ┌─────────────────────────────────────────────────┐
        │  Supabase Realtime Server                       │
        │  • Monitors replication slot                    │
        │  • Creates PostgresChangePayload                │
        │  • Broadcasts to subscribed clients             │
        └─────────────────────────────────────────────────┘
                                  │
                ┌─────────────────┴──────────────────┐
                │                                    │
                ↓ (WebSocket Message)                ↓
        ┌───────────────────────┐        ┌──────────────────────┐
        │  App Instance 1       │        │  App Instance 2      │
        │  (User A)             │        │  (User B)            │
        └───────────────────────┘        └──────────────────────┘
                │                                    │
                ↓                                    ↓
        ┌──────────────────────┐        ┌──────────────────────┐
        │ RealtimeService      │        │ RealtimeService      │
        │ • Receives WS msg    │        │ • Receives WS msg    │
        │ • Parses payload     │        │ • Parses payload     │
        │ • Emits event stream │        │ • Emits event stream │
        └──────────────────────┘        └──────────────────────┘
                │                                    │
                ↓                                    ↓
        ┌──────────────────────┐        ┌──────────────────────┐
        │ RealtimeRepository   │        │ RealtimeRepository   │
        │ • Filters by user    │        │ • Filters by user    │
        │ • Checks access      │        │ • Checks access      │
        │ • Emits to repos     │        │ • Emits to repos     │
        └──────────────────────┘        └──────────────────────┘
                │                                    │
                ↓                                    ↓
        ┌──────────────────────┐        ┌──────────────────────┐
        │ ScreenRepository     │        │ ScreenRepository     │
        │ • Check conflicts    │        │ • Check conflicts    │
        │ • Update cache       │        │ • Update cache       │
        │ • Emit to BLoC       │        │ • Emit to BLoC       │
        └──────────────────────┘        └──────────────────────┘
                │                                    │
                ↓                                    ↓
        ┌──────────────────────┐        ┌──────────────────────┐
        │ ScreenBloc           │        │ ScreenBloc           │
        │ • Handle update      │        │ • Handle update      │
        │ • Emit ScreenUpdate  │        │ • Emit ScreenUpdate  │
        │ • Notify listeners   │        │ • Notify listeners   │
        └──────────────────────┘        └──────────────────────┘
                │                                    │
                ↓                                    ↓
        ┌──────────────────────┐        ┌──────────────────────┐
        │ UI Layer             │        │ UI Layer             │
        │ • BlocBuilder        │        │ • BlocBuilder        │
        │ • Rebuild screen     │        │ • Rebuild screen     │
        │ • Show new content   │        │ • Show new content   │
        │ • Latency: ~50-100ms │        │ • Latency: ~50-100ms │
        └──────────────────────┘        └──────────────────────┘
                │                                    │
                ✅ User sees update                 ✅ User sees update
```

## 3. Conflict Resolution Flow

```
                    ┌──────────────────────────────┐
                    │  Incoming Real-Time Update   │
                    │  (Remote change)             │
                    └──────────────────────────────┘
                                 │
                                 ↓
                    ┌──────────────────────────────┐
                    │  Check Sync Queue            │
                    │  - Pending items?            │
                    │  - Same screen ID?           │
                    └──────────────────────────────┘
                          │              │
                  ┌───────┴──────┬───────┴────────┐
                  │              │                 │
                ✅ No           ❌ Yes            
              Conflict        Conflict         
                  │              │                 
                  ↓              ↓
            ┌──────────────┐  ┌─────────────────┐
            │ Simple Merge │  │ Conflict Logic  │
            │              │  │                 │
            │ • Update     │  │ Compare:        │
            │   local      │  │ • Timestamps    │
            │ • Cache      │  │ • User ID       │
            │ • Emit       │  │ • Content hash  │
            │   update     │  │                 │
            └──────────────┘  └─────────────────┘
                  │                   │
                  │         ┌─────────┴──────────┐
                  │         │                     │
                  │    ┌────┴────┐          ┌────┴────┐
                  │    │ Remote  │          │ Local   │
                  │    │ Newer   │          │ Newer   │
                  │    └────┬────┘          └────┬────┘
                  │         │                    │
                  │         ↓                    ↓
                  │    ┌─────────────┐    ┌──────────────┐
                  │    │ Use Remote  │    │ Use Local    │
                  │    │ • Priority  │    │ • Priority   │
                  │    │ • Merge w/  │    │ • Merge w/   │
                  │    │   local UI  │    │   remote UI  │
                  │    └─────────────┘    └──────────────┘
                  │         │                    │
                  └─────────┬────────────────────┘
                            │
                            ↓
                    ┌──────────────────────┐
                    │ Update Local Cache   │
                    │ • Merged result      │
                    │ • Mark as synced     │
                    │ • Clear queue entry  │
                    └──────────────────────┘
                            │
                            ↓
                    ┌──────────────────────┐
                    │ Emit to BLoC         │
                    │ • ScreenUpdated      │
                    │ • Merged data        │
                    │ • Sync status       │
                    └──────────────────────┘
                            │
                            ↓
                    ┌──────────────────────┐
                    │ UI Reflects Merge    │
                    │ • Show merged state  │
                    │ • Highlight changes  │
                    │ • Notify user (opt)  │
                    └──────────────────────┘
```

## 4. Connection State Machine

```
                    ┌────────────────────────┐
                    │  Disconnected          │
                    │  (Initial State)       │
                    └────────────────────────┘
                             │
                   (Init → Connect)
                             │
                             ↓
                    ┌────────────────────────┐
                    │  Connecting            │
                    │  • Creating WS         │
                    │  • Auth handshake      │
                    │  • Subscribe to table  │
                    └────────────────────────┘
                             │
                   ┌─────────┴──────────┐
                   │                    │
               ✅ Success          ❌ Failure
                   │                    │
                   ↓                    ↓
        ┌────────────────────┐  ┌──────────────────┐
        │  Connected         │  │  Error           │
        │                    │  │  • Log error     │
        │ • Can receive      │  │  • Wait backoff  │
        │   updates          │  │  • Reconnecting  │
        │ • Can subscribe    │  │                  │
        │ • Status: online   │  └──────────────────┘
        └────────────────────┘           │
             │          │                │
        (Event)  (App   ↓ (Backoff expired)
        received) paused)│
             │          │    ┌─────────────┐
             │          │    │ Reconnecting│
             │          │    │ • Retry WS  │
             │          │    │ • Exponential
             │          │    │   backoff   │
             │          │    │ • Max 3x    │
             │          │    └─────────────┘
             │          ↓           │
             │    ┌────────────┐    │
             │    │ Suspended  │    │
             │    │ (Paused)   │←───┘ (Retry failed)
             │    │            │
             │    │ • Cannot   │
             │    │   receive  │
             │    │ • App in   │
             │    │   BG       │
             │    └────────────┘
             │         │
             │    (App resumed)
             │         │
             └─────────┴──→ (Attempt reconnect)
                            │
                            ↓
                  ┌──────────────────┐
                  │ Reconnecting     │
                  │ (exponential BO)  │
                  └──────────────────┘
                            │
                     ┌──────┴──────┐
                     │             │
                 ✅ Success    ❌ Fail
                     │             │
                     ↓             ↓
                (Connected)    (Error)
```

## 5. Data Synchronization Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                 Offline → Online Transition                      │
└─────────────────────────────────────────────────────────────────┘
                             │
                  (Connection restored)
                             │
                             ↓
                    ┌──────────────────────┐
                    │ Sync Phase 1:        │
                    │ Upload Local Changes │
                    └──────────────────────┘
                             │
        ┌────────────────────┴─────────────────┐
        │                                      │
    ┌───┴──────┐                          ┌───┴──────┐
    │ Gather   │                          │ For each │
    │ pending  │                          │ pending  │
    │ changes  │                          │ item:    │
    └───┬──────┘                          └───┬──────┘
        │                                      │
        ↓                                      ↓
    ┌──────────────────┐              ┌──────────────┐
    │ Query sync queue │              │ POST to      │
    │ • CREATEs        │              │ Supabase     │
    │ • UPDATEs        │              │              │
    │ • DELETEs        │              └──────────────┘
    └──────────────────┘                     │
                                             ↓
                                      ┌──────────────┐
                                      │ Check status │
                                      │ ✅ Success   │
                                      │ ❌ Conflict  │
                                      │ ❌ Error     │
                                      └──────────────┘
                                             │
                    ┌────────────────────────┼────────────────────┐
                    │                        │                    │
                ✅ Success              ⚠️ Conflict          ❌ Error
                    │                        │                    │
                    ↓                        ↓                    ↓
            ┌──────────────┐    ┌────────────────────┐  ┌──────────────┐
            │ Mark synced  │    │ Run conflict       │  │ Retry later  │
            │ • Flag=true  │    │ resolution         │  │ • Add backoff│
            │ • Remove     │    │ • Merge data       │  │ • Reschedule │
            │   from Q     │    │ • Update cache     │  │ • Retry count
            └──────────────┘    │ • Send merged      │  └──────────────┘
                    │           │   to server        │          │
                    ↓           └────────────────────┘          │
                  Phase 2:                    │                 │
              Download Changes                ↓                 │
                    │                     (Retried later)       │
                    │                        │                  │
                    ↓                        └──────────────────┘
            ┌──────────────────┐
            │ Check remote     │
            │ for new updates  │
            │ • Query since    │
            │   lastSync       │
            │ • Get deltas     │
            └──────────────────┘
                    │
                    ↓
            ┌──────────────────┐
            │ Merge remote     │
            │ with local       │
            │ • 3-way merge    │
            │ • Field-level    │
            │ • Keep local UI  │
            │   edits          │
            └──────────────────┘
                    │
                    ↓
            ┌──────────────────┐
            │ Update cache     │
            │ • Save screens   │
            │ • Mark synced    │
            │ • Emit update    │
            └──────────────────┘
                    │
                    ↓
            ┌──────────────────┐
            │ Sync Complete    │
            │ • Notify user    │
            │ • Emit event     │
            │ • All data fresh │
            └──────────────────┘
```

## 6. Subscription Lifecycle

```
                    ┌──────────────────────────┐
                    │ App Loads Screen         │
                    │ ID: 'home_screen'        │
                    └──────────────────────────┘
                                 │
                                 ↓
                    ┌──────────────────────────┐
                    │ ScreenBloc               │
                    │ add(FetchScreenEvent)    │
                    └──────────────────────────┘
                                 │
                                 ↓
                    ┌──────────────────────────┐
                    │ ScreenRepository         │
                    │ getScreen('home_screen') │
                    └──────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
                ┌───┴──────┐          ┌──────┴────┐
                │ REST API │          │ Subscribe │
                │ Fetch    │          │ to RT     │
                └───┬──────┘          └──────┬────┘
                    │                        │
                    ↓                        ↓
            ┌──────────────┐     ┌──────────────────────┐
            │ Initial data │     │ RealtimeService      │
            │ returned     │     │ subscribeToScreen()  │
            └──────────────┘     └──────────────────────┘
                    │                        │
                    │                        ↓
                    │             ┌──────────────────────┐
                    │             │ Supabase Realtime    │
                    │             │ subscribe('screens', │
                    │             │ {  filter... })      │
                    │             └──────────────────────┘
                    │                        │
                    │                        ↓
                    │             ┌──────────────────────┐
                    │             │ PostgreSQL          │
                    │             │ Monitor table 'screens'
                    │             └──────────────────────┘
                    │                        │
                    └────────────┬───────────┘
                                 │
                                 ↓
                    ┌──────────────────────────┐
                    │ Emit ScreenLoaded        │
                    │ • Initial data           │
                    │ • Cache updated          │
                    │ • RT subscription active │
                    └──────────────────────────┘
                                 │
                ┌────────────────┴────────────────┐
                │                                 │
          (Background)                     (On remote update)
                │                                 │
                ↓                                 ↓
    ┌──────────────────────┐      ┌──────────────────────┐
    │ Waiting for updates  │      │ Realtime event       │
    │ • Listen to RT stream│      │ PostgresChange:      │
    │ • Monitor connection │      │ • eventType: 'UPDATE'│
    │ • Ready to merge     │      │ • new: {...}        │
    │                      │      │ • old: {...}        │
    └──────────────────────┘      └──────────────────────┘
                │                        │
                │                        ↓
                │        ┌──────────────────────────┐
                │        │ RealtimeRepository       │
                │        │ emits StreamEvent        │
                │        └──────────────────────────┘
                │                        │
                │                        ↓
                │        ┌──────────────────────────┐
                │        │ ScreenRepository         │
                │        │ _handleRealtimeUpdate()  │
                │        │ • Check conflicts        │
                │        │ • Merge data             │
                │        │ • Update cache           │
                │        └──────────────────────────┘
                │                        │
                │                        ↓
                │        ┌──────────────────────────┐
                │        │ Emit ScreenUpdated       │
                │        │ state with new data      │
                │        └──────────────────────────┘
                │                        │
                │                        ↓
                │        ┌──────────────────────────┐
                │        │ UI rebuilds with         │
                │        │ new screen content       │
                │        │ ~50-100ms latency        │
                │        └──────────────────────────┘
                │
    (App sent to background or screen closed)
                │
                ↓
    ┌──────────────────────┐
    │ Unsubscribe          │
    │ • realtimeService    │
    │   .unsubscribe()     │
    │ • Cleanup listeners  │
    │ • Close stream       │
    │ • Remove from cache  │
    └──────────────────────┘
                │
                ↓
    ┌──────────────────────┐
    │ Supabase Realtime    │
    │ remove subscription  │
    │ • Stop sending       │
    │   updates for this   │
    │   screen             │
    │ • Free server conn   │
    └──────────────────────┘
```

## 7. Error Recovery Flow

```
                    ┌──────────────────────────┐
                    │ Error Detected           │
                    │ • Network timeout        │
                    │ • WS connection lost     │
                    │ • Server error           │
                    │ • Invalid subscription   │
                    └──────────────────────────┘
                                 │
                                 ↓
                    ┌──────────────────────────┐
                    │ Categorize Error         │
                    └──────────────────────────┘
                         │        │        │
        ┌────────────────┴┘       │        └──────────────────┐
        │                         │                           │
    ┌───┴──────────┐      ┌──────┴────────┐      ┌───────────┴──┐
    │ Temporary    │      │ User Error    │      │ Server Error │
    │ • Network    │      │ • Bad auth    │      │ • 5xx error  │
    │ • Timeout    │      │ • No access   │      │ • Bug        │
    │ • WS drop    │      │ • Invalid ID  │      │ • Overload   │
    └───┬──────────┘      └──────┬────────┘      └───────────┬──┘
        │                        │                           │
        ↓                        ↓                           ↓
    ┌────────────┐      ┌──────────────┐        ┌──────────────────┐
    │ Retry with │      │ Log + Alert  │        │ Backoff + Retry  │
    │ Exponential│      │ User         │        │ • Wait 1s, 2s,   │
    │ Backoff    │      │ • Permission │        │   4s, 8s         │
    │            │      │   error      │        │ • Max retries: 5 │
    │ Attempt 1: │      │ • Info toast │        │                  │
    │ 1 second   │      │ • Log error  │        └──────────────────┘
    │ Attempt 2: │      │              │                   │
    │ 2 seconds  │      │              │        ┌──────────┴────────┐
    │ Attempt 3: │      │              │        │                   │
    │ 4 seconds  │      │              │    ✅ Success         ❌ Max retries
    │ Attempt 4: │      │              │        │                   │
    │ 8 seconds  │      │              │        ↓                   ↓
    │ Attempt 5: │      │              │  ┌──────────┐      ┌─────────────┐
    │ 16 seconds │      │              │  │ Resume   │      │ Emit Error  │
    │            │      │              │  │ normal   │      │ • Show user │
    └──────────┬─┘      │              │  │ operation│      │ • Fallback  │
        │               │              │  └──────────┘      │   to REST   │
        └──────┬────────┴──────────────┘                    │ • Suggest   │
               │                                             │   refresh   │
        ┌──────┴────────────────────────────────────────────┴─────────────┐
        │                                                                  │
        ↓                                                                  │
    ┌──────────────────────┐                                              │
    │ Update Connection    │                                              │
    │ Status               │                                              │
    │ • Connected or       │                                              │
    │   Disconnected       │                                              │
    │ • Emit to BLoC       │                                              │
    │ • UI shows status    │                                              │
    └──────────────────────┘                                              │
                │                                                          │
                └──────────────────────────────────────────────────────────┘
```

---

These diagrams provide a complete visual reference for understanding the real-time architecture, data flows, and error handling patterns.

