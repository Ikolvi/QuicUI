# Supabase Package Separation Plan

**Status:** 📋 Planning Phase  
**Date:** October 30, 2025  
**Target:** v2.0.0 - Database Agnostic Architecture  
**Duration:** 3-4 weeks  

---

## 🎯 Executive Summary

QuicUI is currently tightly coupled with Supabase backend. This plan separates Supabase integration into a **standalone plugin package** (`quicui_supabase`), enabling:

✅ **Core QuicUI** - Database agnostic, UI rendering engine  
✅ **quicui_supabase** - Supabase backend plugin  
✅ **Future plugins** - Firebase, AWS Amplify, custom backends  

**Benefit:** Users can now use QuicUI with ANY backend by implementing the `DataSource` interface.

---

## 📊 Current Architecture (v1.1.0)

```
┌─────────────────────────────────────────────────────────┐
│                         QuicUI                           │
├─────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │    Rendering │  │     BLoC     │  │ Repository   │  │
│  │   Engine     │  │   Pattern    │  │   Pattern    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         ↓                  ↓                  ↓          │
│  ┌──────────────────────────────────────────────────┐   │
│  │         SupabaseService (TIGHTLY COUPLED)        │   │
│  └──────────────────────────────────────────────────┘   │
│         ↓                                                │
│  ┌──────────────────────────────────────────────────┐   │
│  │     Supabase Backend (PostgreSQL + APIs)         │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘

Problem: QuicUI can ONLY work with Supabase
```

---

## 🎨 Target Architecture (v2.0.0)

```
┌──────────────────────────────────────────────────────────────────┐
│                    QuicUI Core (Database Agnostic)               │
├──────────────────────────────────────────────────────────────────┤
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐     │
│  │  Rendering     │  │  BLoC Pattern  │  │  Repository    │     │
│  │  Engine        │  │                │  │  Pattern       │     │
│  └────────────────┘  └────────────────┘  └────────────────┘     │
│         ↓                    ↓                    ↓               │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │   Abstract DataSource Interface (Plugin Contract)        │    │
│  │  ┌──────────────────────────────────────────────────┐    │    │
│  │  │ - fetchScreen()     - saveScreen()              │    │    │
│  │  │ - deleteScreen()    - searchScreens()           │    │    │
│  │  │ - syncData()        - resolveConflict()         │    │    │
│  │  │ - connect()         - disconnect()              │    │    │
│  │  └──────────────────────────────────────────────────┘    │    │
│  └──────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
                              ↓
        ┌─────────────────────┼─────────────────────┐
        ↓                     ↓                     ↓
   ┌─────────┐           ┌─────────┐           ┌─────────┐
   │ quicui_ │           │ quicui_ │           │ Custom  │
   │supabase │           │firebase │           │Backend  │
   └─────────┘           └─────────┘           └─────────┘
        ↓                     ↓                     ↓
   Supabase           Firebase/          Custom DB
   PostgreSQL         Firestore          Implementation

Benefit: QuicUI works with ANY backend
```

---

## 📦 New Package Structure

### Core Package: `quicui` (Database Agnostic)

```
quicui/
├── lib/
│   └── src/
│       ├── core/              (No Supabase references)
│       ├── rendering/         (UI engine)
│       ├── models/            (Data models)
│       ├── widgets/           (UI components)
│       ├── bloc/              (State management)
│       ├── repositories/       (Use abstract interfaces)
│       │   ├── data_source_interface.dart  (NEW)
│       │   ├── screen_repository.dart      (refactored)
│       │   └── sync_repository.dart        (refactored)
│       ├── services/
│       │   ├── storage_service.dart        (unchanged)
│       │   ├── quicui_service.dart         (refactored)
│       │   ├── realtime_service.dart       (to be generic)
│       │   └── data_source_provider.dart   (NEW)
│       └── utils/
├── pubspec.yaml
└── README.md
```

### Plugin Package: `quicui_supabase` (NEW)

```
quicui_supabase/
├── lib/
│   └── src/
│       ├── supabase_data_source.dart       (Implements interface)
│       ├── supabase_realtime_source.dart   (Real-time impl)
│       ├── models/
│       │   └── supabase_config.dart
│       ├── services/
│       │   └── supabase_service.dart       (from core, moved here)
│       └── extensions/
│           └── quicui_supabase_init.dart   (Setup helpers)
├── pubspec.yaml
├── example/
│   ├── lib/
│   │   └── main.dart
│   └── pubspec.yaml
└── README.md
```

---

## 🔧 Implementation Phases

### Phase 1: Define Abstract Interfaces (3-4 days)

**File:** `lib/src/repositories/data_source_interface.dart` (Core)

```dart
/// Abstract interface for backend data sources
abstract class DataSource {
  // Screen Operations
  Future<Screen> fetchScreen(String screenId);
  Future<List<Screen>> fetchScreens({int limit, int offset});
  Future<void> saveScreen(String screenId, Screen screen);
  Future<void> deleteScreen(String screenId);
  
  // Search & Query
  Future<List<Screen>> searchScreens(String query);
  Future<int> getScreenCount();
  
  // Sync Operations
  Future<SyncResult> syncData(List<SyncItem> pendingItems);
  Future<List<SyncItem>> getPendingItems();
  Future<ConflictResolution> resolveConflict(ConflictCase conflict);
  
  // Connection
  Future<void> connect();
  Future<void> disconnect();
  Future<bool> isConnected();
  
  // Realtime (if supported)
  Stream<RealtimeEvent<Screen>> subscribeToScreen(String screenId);
  Future<void> unsubscribe(String screenId);
}

/// Realtime event model
class RealtimeEvent<T> extends Equatable {
  final EventType type;      // INSERT, UPDATE, DELETE
  final T data;
  final DateTime timestamp;
  
  const RealtimeEvent({
    required this.type,
    required this.data,
    required this.timestamp,
  });
}

enum EventType { insert, update, delete }
```

**Tasks:**
- [ ] Create `DataSource` abstract class
- [ ] Create `RealtimeSource` abstract class
- [ ] Create model classes for sync, conflicts, results
- [ ] Document interface contracts
- [ ] Create error classes

**Deliverables:**
- `data_source_interface.dart` (200+ lines)
- `realtime_source_interface.dart` (150+ lines)
- Model classes (300+ lines)

---

### Phase 2: Refactor Core Repositories (4-5 days)

**Files:** `lib/src/repositories/*.dart`

**Changes to ScreenRepository:**

```dart
// Before (tightly coupled)
class ScreenRepository {
  final SupabaseService _supabaseService;
  // ... Supabase-specific logic
}

// After (abstracted)
class ScreenRepository {
  final DataSource _dataSource;  // Generic interface
  final StorageService _storage;
  
  ScreenRepository({
    required DataSource dataSource,
    required StorageService storage,
  });
  
  Future<Screen?> getScreen(String id) async {
    try {
      // Try remote first
      return await _dataSource.fetchScreen(id);
    } catch (e) {
      // Fallback to local
      return await _storage.get('screen_$id');
    }
  }
}
```

**Tasks:**
- [ ] Remove Supabase imports from core repositories
- [ ] Replace `SupabaseService` with `DataSource` interface
- [ ] Update `ScreenRepository` to use generic interface
- [ ] Update `SyncRepository` to use generic interface
- [ ] Update error handling to use generic exceptions
- [ ] Add fallback strategies for offline
- [ ] Write tests for repositories

**Deliverables:**
- Refactored `screen_repository.dart`
- Refactored `sync_repository.dart`
- Updated error handling
- 100+ tests

---

### Phase 3: Create DataSourceProvider (2-3 days)

**File:** `lib/src/services/data_source_provider.dart` (NEW)

```dart
/// Service locator for data source
///
/// Allows QuicUI to work with different backends
/// by implementing DataSource interface
class DataSourceProvider {
  static DataSource? _instance;
  
  /// Register a data source implementation
  static void register(DataSource dataSource) {
    _instance = dataSource;
  }
  
  /// Get the registered data source
  static DataSource get instance {
    if (_instance == null) {
      throw Exception('DataSource not registered. '
          'Call DataSourceProvider.register() first');
    }
    return _instance!;
  }
  
  /// Check if data source is registered
  static bool get isRegistered => _instance != null;
}
```

**Tasks:**
- [ ] Create `DataSourceProvider` service locator
- [ ] Add registration methods
- [ ] Add validation
- [ ] Add error messages
- [ ] Add documentation

**Deliverables:**
- `data_source_provider.dart`
- Usage examples
- Tests

---

### Phase 4: Create quicui_supabase Plugin (5-7 days)

**File:** `lib/src/supabase_data_source.dart` (NEW package)

```dart
/// Supabase implementation of DataSource
class SupabaseDataSource implements DataSource {
  final SupabaseClient _client;
  
  SupabaseDataSource(this._client);
  
  @override
  Future<Screen> fetchScreen(String screenId) async {
    final response = await _client
        .from('screens')
        .select()
        .eq('id', screenId)
        .single();
    
    return Screen.fromJson(response);
  }
  
  // ... implement all interface methods
}

/// Initialization helper
extension QuicUISupabaseInit on QuicUI {
  static Future<void> initSupabase({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
    
    final dataSource = SupabaseDataSource(
      Supabase.instance.client,
    );
    
    DataSourceProvider.register(dataSource);
  }
}
```

**Tasks:**
- [ ] Create `quicui_supabase` package
- [ ] Create `SupabaseDataSource` implementation
- [ ] Create `SupabaseRealtimeSource` for subscriptions
- [ ] Create initialization helpers
- [ ] Create examples
- [ ] Write comprehensive tests
- [ ] Create documentation

**Deliverables:**
- New `quicui_supabase` package
- `supabase_data_source.dart` (400+ lines)
- Example app
- README with setup guide
- 80+ tests

---

### Phase 5: Update QuicUIService (2-3 days)

**File:** `lib/src/services/quicui_service.dart`

```dart
// Before
class QuicUI {
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    // ... Supabase-specific setup
  }
}

// After (generic)
class QuicUI {
  /// Initialize QuicUI with a data source
  /// 
  /// This is the generic method - use this for custom backends
  static Future<void> initializeWithDataSource({
    required DataSource dataSource,
    required StorageService? storage,
  }) async {
    DataSourceProvider.register(dataSource);
    // ... rest of initialization
  }
  
  /// [DEPRECATED] Use Supabase? Use quicui_supabase package instead!
  /// 
  /// Initialize QuicUI with Supabase backend
  @Deprecated('Use QuicUISupabase.initialize() instead')
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    // Redirect to quicui_supabase
    await QuicUISupabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
```

**Tasks:**
- [ ] Add `initializeWithDataSource()` method
- [ ] Deprecate Supabase-specific initialize
- [ ] Update error messages
- [ ] Update documentation
- [ ] Add migration guide

**Deliverables:**
- Updated `quicui_service.dart`
- Migration guide for v1.x → v2.0
- Deprecation notices

---

### Phase 6: Update Documentation & Examples (3-4 days)

**Files:**
- `README.md` (core package)
- `examples/` (new structure)
- `docs/` (new guides)

**Updates:**

1. **Core README.md**
   - Remove Supabase-specific setup
   - Add generic data source setup
   - Link to plugin packages
   - Architecture diagram

2. **New Plugin Documentation:**
   - `quicui_supabase/README.md`
   - `quicui_supabase/example/`
   - Setup guide
   - Real-time features

3. **New Examples:**
   - `examples/with_supabase/` (move existing)
   - `examples/custom_backend/` (template for users)
   - `examples/firebase/` (future)

**Tasks:**
- [ ] Rewrite core README
- [ ] Create Supabase plugin README
- [ ] Create custom backend example
- [ ] Create migration guide
- [ ] Update API documentation
- [ ] Create architecture diagrams
- [ ] Create step-by-step tutorials

**Deliverables:**
- Updated README files
- 3+ examples
- Migration guide (10+ pages)
- Architecture documentation

---

## 🔄 Migration Path (v1.1.0 → v2.0.0)

### For Existing Users (Using Supabase):

**Before (v1.1.0):**
```dart
import 'package:quicui/quicui.dart';

void main() async {
  await QuicUI.initialize(
    supabaseUrl: 'https://xxx.supabase.co',
    supabaseAnonKey: 'xxx',
  );
}
```

**After (v2.0.0 - Option 1: Use Supabase plugin):**
```dart
import 'package:quicui/quicui.dart';
import 'package:quicui_supabase/quicui_supabase.dart';

void main() async {
  await QuicUISupabase.initialize(
    url: 'https://xxx.supabase.co',
    anonKey: 'xxx',
  );
}
```

**After (v2.0.0 - Option 2: Custom backend):**
```dart
import 'package:quicui/quicui.dart';

class FirebaseDataSource implements DataSource {
  // Implement interface
}

void main() async {
  await QuicUI.initializeWithDataSource(
    dataSource: FirebaseDataSource(),
  );
}
```

### Breaking Changes:
- ⚠️ `QuicUI.initialize()` moved to `QuicUISupabase.initialize()`
- ⚠️ Remove `supabase_flutter` from core `pubspec.yaml`
- ⚠️ Move Supabase types to plugin package

### Backward Compatibility:
- ✅ Deprecation warnings in v2.0.0
- ✅ Migration guide provided
- ✅ Both APIs work initially

---

## 📦 New Package Dependencies

### Core `quicui/pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^9.0.0
  bloc: ^9.0.0
  equatable: ^2.0.5
  # ... other non-database packages
  # ✅ REMOVED: supabase_flutter
  # ✅ REMOVED: any database-specific package
```

### Plugin `quicui_supabase/pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  quicui: ^2.0.0
  supabase_flutter: ^2.10.3
  # Supabase-specific dependencies
```

---

## 🧪 Testing Strategy

### Core Package Tests
- Data source interface contract tests (abstract)
- Repository tests with mock data source
- BLoC tests
- Widget rendering tests

### Plugin Package Tests
- Supabase data source implementation tests
- Real-time subscription tests
- End-to-end integration tests
- Error recovery tests

### Test Coverage Target: 85%+

---

## 📋 Files to Create/Modify

### Create (NEW)
- [ ] `lib/src/repositories/data_source_interface.dart`
- [ ] `lib/src/repositories/realtime_source_interface.dart`
- [ ] `lib/src/services/data_source_provider.dart`
- [ ] `quicui_supabase/` (entire package)
- [ ] `examples/custom_backend_template/`
- [ ] `docs/ARCHITECTURE_V2.md`
- [ ] `docs/MIGRATION_GUIDE_V1_TO_V2.md`
- [ ] `docs/CREATING_CUSTOM_BACKEND.md`

### Modify
- [ ] `lib/src/repositories/screen_repository.dart`
- [ ] `lib/src/repositories/sync_repository.dart`
- [ ] `lib/src/services/quicui_service.dart`
- [ ] `lib/src/bloc/**/*.dart` (remove Supabase references)
- [ ] `pubspec.yaml` (remove supabase_flutter)
- [ ] `README.md` (rewrite)
- [ ] Example app (move to plugin)

### Move to quicui_supabase
- [ ] `lib/src/services/supabase_service.dart`
- [ ] Example code (refactor)

---

## 📊 Project Timeline

| Phase | Duration | Tasks | Deliverables |
|-------|----------|-------|--------------|
| 1 | 3-4 days | Define interfaces | Interface contracts, models |
| 2 | 4-5 days | Refactor core | Generic repositories |
| 3 | 2-3 days | Create provider | Service locator |
| 4 | 5-7 days | Create plugin | quicui_supabase package |
| 5 | 2-3 days | Update service | Generic initialization |
| 6 | 3-4 days | Docs & examples | Documentation, guides |
| **Total** | **~4 weeks** | | **v2.0.0 Release** |

---

## 🎯 Success Criteria

### Functional
- [ ] QuicUI works with abstract DataSource interface
- [ ] quicui_supabase plugin provides full Supabase support
- [ ] Custom backends can be implemented by users
- [ ] Real-time subscriptions work across all backends
- [ ] Offline sync works with any backend
- [ ] All 228 existing tests pass

### Quality
- [ ] 85%+ test coverage
- [ ] Zero breaking changes to core API (except datasource)
- [ ] Comprehensive documentation
- [ ] Migration guide for users
- [ ] Example implementations

### Compatibility
- [ ] Works with Flutter 3.0+
- [ ] Works with Dart 3.0+
- [ ] Backward compatibility deprecation path

---

## 🚀 Benefits After Separation

### For QuicUI Users
✅ Use with Supabase, Firebase, AWS Amplify, etc.  
✅ Implement custom backend easily  
✅ No dependency bloat if not using Supabase  
✅ Faster core package updates  

### For QuicUI Developers
✅ Cleaner core codebase  
✅ Easier to maintain and test  
✅ Faster core development  
✅ Plugin ecosystem support  

### For Community
✅ Enable third-party backend plugins  
✅ Reduce decision paralysis (any backend works)  
✅ More flexible for enterprise use cases  

---

## 📚 Related Documentation

This plan enables:
- **REALTIME_PLAN.md** - Real-time features for any backend
- **REALTIME_ARCHITECTURE.md** - Generic event architecture
- Custom backend implementations (Firebase, AWS Amplify, etc.)

---

## 🔄 Versioning

- **v1.1.0** (Current) - Supabase-only, all TODOs completed
- **v2.0.0-beta.1** - Core/Supabase separation (alpha)
- **v2.0.0-rc.1** - Release candidate
- **v2.0.0** - Stable release with Supabase plugin

---

**Status:** 📋 Planning Phase Complete  
**Ready for:** Phase 1 Implementation  
**Next Step:** Define DataSource interfaces  

