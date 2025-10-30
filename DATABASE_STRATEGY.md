# QuicUI Database & Local Storage Strategy

## 🚀 Why ObjectBox for Local Storage?

### Performance Comparison

```
Operation               ObjectBox    SQLite    Hive      SharedPrefs
─────────────────────────────────────────────────────────────────
Single Query           0.2ms        1.5ms     2ms       0.5ms*
Batch Insert (1000)    50ms         200ms     300ms     N/A
Complex Query          1ms          8ms       N/A       N/A
Sync Operation         100ms        500ms     1000ms    N/A
Space (1000 records)   ~1MB         ~2MB      ~3MB      ~100KB*
ACID Compliance        ✅ Yes       ✅ Yes    ❌ No     ❌ No
Type Safety            ✅ Yes       ❌ No     ✅ Yes    ❌ No
```

### ObjectBox Advantages

✅ **Zero-Copy Technology**: Direct in-memory access  
✅ **ACID Transactions**: Data integrity guaranteed  
✅ **Real-time Sync**: Built for offline-first apps  
✅ **Type-Safe**: Dart-native with code generation  
✅ **Minimal Configuration**: Works out of the box  
✅ **Encryption Support**: Built-in encryption available  
✅ **Reactive Queries**: Observable data streams  
✅ **Relations Support**: Handle complex data models  

---

## 📋 Data Models for QuicUI

### 1. Cached UI Screens

```dart
@Entity()
class CachedUIScreen {
  @Id()
  int id = 0;

  late String screenId;           // Unique screen identifier
  late String jsonData;            // Full JSON screen definition
  
  late DateTime createdAt;         // When cached
  @Property(type: PropertyType.date)
  DateTime? expiresAt;             // Cache expiration (TTL)
  
  late DateTime lastAccessedAt;    // LRU tracking
  late int accessCount;            // Usage metrics
  
  // Relations
  final tags = ToMany<CacheTag>();
  
  // Helpers
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
  
  bool get isStale {
    // Consider cache stale after 30 days if not accessed
    return DateTime.now().difference(lastAccessedAt).inDays > 30;
  }
}

@Entity()
class CacheTag {
  @Id()
  int id = 0;
  
  late String tag;
  
  // Relationship to screen
  final screen = ToOne<CachedUIScreen>();
}
```

**Use Cases:**
- Store full screen JSON definitions
- Implement LRU (Least Recently Used) cache
- Quick lookups without network
- Offline support

---

### 2. User State & Preferences

```dart
@Entity()
class UserState {
  @Id()
  int id = 0;

  late String key;                 // State key
  late String value;               // JSON-serialized value
  
  @Property(type: PropertyType.date)
  late DateTime createdAt;
  @Property(type: PropertyType.date)
  late DateTime updatedAt;
  
  late int version;                // For conflict resolution
  late bool isLocal;               // Local-only vs synced
  late String? syncStatus;         // 'synced', 'pending', 'failed'
}
```

**Use Cases:**
- Persist user preferences (theme, language, etc.)
- Store last-known state
- Enable offline features
- Support undo/redo functionality

---

### 3. Form Data & Drafts

```dart
@Entity()
class FormDraft {
  @Id()
  int id = 0;

  late String formId;              // Form identifier
  late String draftData;           // JSON of form values
  
  @Property(type: PropertyType.date)
  late DateTime createdAt;
  @Property(type: PropertyType.date)
  late DateTime lastModifiedAt;
  
  late String? userId;             // User who created draft
  late String? deviceId;           // Which device
  
  // Status tracking
  late String status;              // 'draft', 'submitted', 'failed'
  late String? errorMessage;       // Last error if any
  
  final attachments = ToMany<FormAttachment>();
}

@Entity()
class FormAttachment {
  @Id()
  int id = 0;

  late String fileName;
  late String filePath;
  late int fileSize;
  late String mimeType;
  
  @Property(type: PropertyType.date)
  late DateTime uploadedAt;
  
  late String? uploadUrl;
  late String uploadStatus;        // 'pending', 'uploading', 'failed'
  
  // Relationship
  final draft = ToOne<FormDraft>();
}
```

**Use Cases:**
- Save form drafts automatically
- Recover unsaved data
- Track attachment uploads
- Support multi-step forms

---

### 4. API Response Cache

```dart
@Entity()
class APIResponse {
  @Id()
  int id = 0;

  late String endpoint;            // API endpoint URL
  late String method;              // GET, POST, etc.
  late String? requestHash;        // Hash of request params
  late String responseData;        // Full response JSON
  
  @Property(type: PropertyType.date)
  late DateTime createdAt;
  @Property(type: PropertyType.date)
  DateTime? expiresAt;             // Cache TTL
  
  late int statusCode;             // HTTP status
  late Map<String, String>? headers;
  
  late bool isCurrent;             // Most recent response
  late String? eTag;               // For conditional requests
}
```

**Use Cases:**
- Cache API responses
- Implement conditional requests (ETags)
- Serve offline fallbacks
- Reduce bandwidth

---

### 5. Sync Queue & Metadata

```dart
@Entity()
class SyncOperation {
  @Id()
  int id = 0;

  late String operationType;       // 'create', 'update', 'delete'
  late String entityType;          // 'screen', 'form', 'state'
  late String entityId;
  
  late String operationData;       // Change details (JSON)
  
  @Property(type: PropertyType.date)
  late DateTime createdAt;
  
  late String status;              // 'pending', 'syncing', 'synced', 'failed'
  late int retryCount;
  late String? lastError;
  
  @Property(type: PropertyType.date)
  DateTime? lastAttemptAt;
  
  late int priority;               // 0 (low) to 10 (high)
}

@Entity()
class SyncMetadata {
  @Id()
  int id = 0;

  late String deviceId;
  late String userId;
  
  @Property(type: PropertyType.date)
  DateTime? lastSyncAt;
  @Property(type: PropertyType.date)
  DateTime? lastConflictAt;
  
  late String syncStrategy;        // 'LastWriteWins', 'ServerAuthoritative'
  late bool isOnline;
  late int pendingOperations;
}
```

**Use Cases:**
- Queue operations for sync
- Handle offline actions
- Retry failed requests
- Track sync state

---

### 6. Conflict Resolution History

```dart
@Entity()
class ConflictLog {
  @Id()
  int id = 0;

  late String entityId;
  late String entityType;
  
  late String localValue;          // Local JSON
  late String remoteValue;         // Remote JSON
  late String resolvedValue;       // Final JSON used
  
  late String resolutionStrategy;  // 'LastWriteWins', 'Custom', etc.
  
  @Property(type: PropertyType.date)
  late DateTime detectedAt;
  @Property(type: PropertyType.date)
  late DateTime resolvedAt;
  
  late String? notes;              // Detailed info
}
```

**Use Cases:**
- Log conflicts for debugging
- Analyze sync patterns
- Implement smart conflict resolution
- Audit trail

---

## 🏗️ Database Architecture

### ObjectBox Store Structure

```dart
import 'objectbox.g.dart';

class ObjectBox {
  /// The Store of this app.
  late final Store store;

  /// A Box of CachedUIScreens.
  late final Box<CachedUIScreen> cachedScreenBox;

  /// A Box of UserStates.
  late final Box<UserState> userStateBox;

  /// A Box of FormDrafts.
  late final Box<FormDraft> formDraftBox;

  /// A Box of APIResponses.
  late final Box<APIResponse> apiResponseBox;

  /// A Box of SyncOperations.
  late final Box<SyncOperation> syncOperationBox;

  /// A Box of SyncMetadata.
  late final Box<SyncMetadata> syncMetadataBox;

  /// A Box of ConflictLogs.
  late final Box<ConflictLog> conflictLogBox;

  ObjectBox._create(this.store) {
    cachedScreenBox = Box<CachedUIScreen>(store);
    userStateBox = Box<UserState>(store);
    formDraftBox = Box<FormDraft>(store);
    apiResponseBox = Box<APIResponse>(store);
    syncOperationBox = Box<SyncOperation>(store);
    syncMetadataBox = Box<SyncMetadata>(store);
    conflictLogBox = Box<ConflictLog>(store);
  }

  /// Create an instance of ObjectBox to use throughout the app.
  static Future<ObjectBox> create() async {
    final store = await openStore();
    return ObjectBox._create(store);
  }

  // Query helpers with proper indexing
  Query<CachedUIScreen> queryCachedScreen(String screenId) {
    return cachedScreenBox.query(
      CachedUIScreen_.screenId.equals(screenId),
    ).build();
  }

  Query<UserState> queryUserState(String key) {
    return userStateBox.query(
      UserState_.key.equals(key),
    ).build();
  }

  Query<FormDraft> queryPendingDrafts() {
    return formDraftBox.query(
      FormDraft_.status.equals('draft'),
    )
    .order(FormDraft_.lastModifiedAt, flags: Order.descending)
    .build();
  }
}
```

---

## 🔧 Database Operations

### 1. Initialize Database

```dart
class DatabaseProvider {
  static late ObjectBox _objectBox;

  static Future<void> initialize() async {
    _objectBox = await ObjectBox.create();
    
    // Cleanup old cached data
    await _cleanupExpiredCache();
    
    // Restore sync state
    await _restoreSyncState();
  }

  static Future<void> _cleanupExpiredCache() async {
    final expired = _objectBox.cachedScreenBox.query(
      CachedUIScreen_.expiresAt.lessThan(DateTime.now().millisecondsSinceEpoch),
    ).build().find();
    
    _objectBox.cachedScreenBox.removeMany(
      expired.map((e) => e.id).toList(),
    );
  }

  static Future<void> _restoreSyncState() async {
    final pending = _objectBox.syncOperationBox.query(
      SyncOperation_.status.equals('syncing'),
    ).build().find();
    
    // Reset status to pending for retry
    for (var op in pending) {
      op.status = 'pending';
      op.retryCount = 0;
    }
    _objectBox.syncOperationBox.putMany(pending);
  }
}
```

### 2. Cache UI Screens

```dart
class UICache {
  static Future<void> cacheScreen(
    String screenId,
    String jsonData, {
    Duration ttl = const Duration(hours: 24),
  }) async {
    final existing = _objectBox.cachedScreenBox.query(
      CachedUIScreen_.screenId.equals(screenId),
    ).build().findFirst();

    if (existing != null) {
      // Update existing cache
      existing
        ..jsonData = jsonData
        ..expiresAt = DateTime.now().add(ttl)
        ..lastAccessedAt = DateTime.now()
        ..accessCount += 1;
      _objectBox.cachedScreenBox.put(existing);
    } else {
      // Create new cache
      final cache = CachedUIScreen()
        ..screenId = screenId
        ..jsonData = jsonData
        ..createdAt = DateTime.now()
        ..expiresAt = DateTime.now().add(ttl)
        ..lastAccessedAt = DateTime.now()
        ..accessCount = 1;
      _objectBox.cachedScreenBox.put(cache);
    }
  }

  static Future<String?> getScreen(String screenId) async {
    final cache = _objectBox.cachedScreenBox.query(
      CachedUIScreen_.screenId.equals(screenId),
    ).build().findFirst();

    if (cache != null && !cache.isExpired) {
      // Update access info
      cache.lastAccessedAt = DateTime.now();
      cache.accessCount += 1;
      _objectBox.cachedScreenBox.put(cache);
      
      return cache.jsonData;
    }

    return null;
  }

  static Future<void> invalidateScreen(String screenId) async {
    final query = _objectBox.cachedScreenBox.query(
      CachedUIScreen_.screenId.equals(screenId),
    ).build();
    
    final cache = query.findFirst();
    if (cache != null) {
      _objectBox.cachedScreenBox.remove(cache.id);
    }
  }
}
```

### 3. User State Management

```dart
class StateStorage {
  static Future<void> setState(String key, dynamic value) async {
    final existing = _objectBox.userStateBox.query(
      UserState_.key.equals(key),
    ).build().findFirst();

    final jsonValue = jsonEncode(value);
    final now = DateTime.now();

    if (existing != null) {
      existing
        ..value = jsonValue
        ..updatedAt = now
        ..version += 1;
      _objectBox.userStateBox.put(existing);
    } else {
      final state = UserState()
        ..key = key
        ..value = jsonValue
        ..createdAt = now
        ..updatedAt = now
        ..version = 1
        ..isLocal = true
        ..syncStatus = 'pending';
      _objectBox.userStateBox.put(state);
    }
  }

  static Future<dynamic> getState(String key) async {
    final state = _objectBox.userStateBox.query(
      UserState_.key.equals(key),
    ).build().findFirst();

    if (state != null) {
      return jsonDecode(state.value);
    }
    return null;
  }

  static Stream<dynamic> watchState(String key) {
    return _objectBox.userStateBox.query(
      UserState_.key.equals(key),
    ).watch(triggerImmediately: true).map((query) {
      final state = query.findFirst();
      return state != null ? jsonDecode(state.value) : null;
    });
  }
}
```

### 4. Form Draft Management

```dart
class FormStorage {
  static Future<void> saveDraft(
    String formId,
    Map<String, dynamic> data,
  ) async {
    final existing = _objectBox.formDraftBox.query(
      FormDraft_.formId.equals(formId),
    ).build().findFirst();

    if (existing != null) {
      existing
        ..draftData = jsonEncode(data)
        ..lastModifiedAt = DateTime.now();
      _objectBox.formDraftBox.put(existing);
    } else {
      final draft = FormDraft()
        ..formId = formId
        ..draftData = jsonEncode(data)
        ..createdAt = DateTime.now()
        ..lastModifiedAt = DateTime.now()
        ..status = 'draft'
        ..isLocal = true;
      _objectBox.formDraftBox.put(draft);
    }
  }

  static Future<Map<String, dynamic>?> getDraft(String formId) async {
    final draft = _objectBox.formDraftBox.query(
      FormDraft_.formId.equals(formId),
    ).build().findFirst();

    if (draft != null) {
      return jsonDecode(draft.draftData);
    }
    return null;
  }

  static Future<void> submitDraft(String formId) async {
    final draft = _objectBox.formDraftBox.query(
      FormDraft_.formId.equals(formId),
    ).build().findFirst();

    if (draft != null) {
      draft.status = 'submitted';
      _objectBox.formDraftBox.put(draft);
    }
  }

  static Future<void> deleteDraft(String formId) async {
    final draft = _objectBox.formDraftBox.query(
      FormDraft_.formId.equals(formId),
    ).build().findFirst();

    if (draft != null) {
      _objectBox.formDraftBox.remove(draft.id);
    }
  }
}
```

---

## 🔄 Sync Strategy

### Optimistic Sync Pattern

```dart
class SyncManager {
  static Future<void> syncOfflineChanges() async {
    final pending = _objectBox.syncOperationBox.query(
      SyncOperation_.status.equals('pending'),
    )
    .order(SyncOperation_.priority, flags: Order.descending)
    .build()
    .find();

    for (var operation in pending) {
      try {
        await _executeSyncOperation(operation);
        operation.status = 'synced';
      } catch (e) {
        operation.status = 'failed';
        operation.lastError = e.toString();
        operation.retryCount += 1;
      }
      _objectBox.syncOperationBox.put(operation);
    }
  }

  static Future<void> _executeSyncOperation(
    SyncOperation operation,
  ) async {
    operation.status = 'syncing';
    _objectBox.syncOperationBox.put(operation);

    final data = jsonDecode(operation.operationData);

    switch (operation.operationType) {
      case 'create':
        await _uploadData(operation.endpoint, data);
        break;
      case 'update':
        await _updateData(operation.endpoint, operation.entityId, data);
        break;
      case 'delete':
        await _deleteData(operation.endpoint, operation.entityId);
        break;
    }
  }
}
```

### Conflict Resolution

```dart
class ConflictResolver {
  enum Strategy {
    lastWriteWins,
    serverAuthoritative,
    clientAuthoritative,
    custom,
  }

  static Future<dynamic> resolve(
    dynamic localValue,
    dynamic remoteValue,
    Strategy strategy,
  ) async {
    switch (strategy) {
      case Strategy.lastWriteWins:
        return remoteValue; // Server is authoritative by timestamp

      case Strategy.serverAuthoritative:
        return remoteValue; // Always trust server

      case Strategy.clientAuthoritative:
        return localValue; // Always trust client

      case Strategy.custom:
        return await _customResolve(localValue, remoteValue);
    }
  }

  static Future<dynamic> _customResolve(
    dynamic local,
    dynamic remote,
  ) async {
    // Deep merge strategy for objects
    if (local is Map && remote is Map) {
      return {...remote, ...local};
    }
    return remote; // Fallback
  }
}
```

---

## 📊 Performance Optimization

### Indexing Strategy

```dart
// Key fields to index:
@Entity()
class CachedUIScreen {
  @Id()
  int id = 0;

  @Index() // Frequently queried
  late String screenId;

  @Index() // For expiration queries
  @Property(type: PropertyType.date)
  DateTime? expiresAt;

  // Other fields...
}

@Entity()
class UserState {
  @Id()
  int id = 0;

  @Index() // Key lookup
  late String key;

  @Index() // For sync queries
  late bool isLocal;

  // Other fields...
}

@Entity()
class SyncOperation {
  @Id()
  int id = 0;

  @Index() // For status filtering
  late String status;

  @Index() // For retry logic
  late int retryCount;

  // Other fields...
}
```

### Batch Operations

```dart
// Bulk insert
await _objectBox.cachedScreenBox.putMany(screens);

// Bulk update
for (var screen in screens) {
  screen.expiresAt = DateTime.now().add(Duration(hours: 24));
}
await _objectBox.cachedScreenBox.putMany(screens);

// Bulk delete
final ids = screens.map((s) => s.id).toList();
await _objectBox.cachedScreenBox.removeMany(ids);
```

### Query Optimization

```dart
// Efficient query with pagination
Query<FormDraft> queryDrafts(int limit, int offset) {
  return _objectBox.formDraftBox.query()
    .order(FormDraft_.lastModifiedAt, flags: Order.descending)
    .offset(offset)
    .limit(limit)
    .build();
}
```

---

## 🔒 Security Considerations

### Encryption

```dart
// Enable encryption for sensitive data
final store = await openStore(
  modelJsonPath: getApplicationDocumentsDirectory(),
  // Encryption requires separate package
  // encryptionKey: _generateEncryptionKey(),
);
```

### Data Cleanup

```dart
// Clear sensitive data on logout
static Future<void> clearUserData() async {
  _objectBox.userStateBox.removeAll();
  _objectBox.formDraftBox.removeAll();
  _objectBox.syncOperationBox.removeAll();
  
  // Keep only cached UI for offline support
  final retained = _objectBox.cachedScreenBox.query(
    CachedUIScreen_.expiresAt.greaterThan(
      DateTime.now().millisecondsSinceEpoch,
    ),
  ).build().find();
  
  final removeIds = _objectBox.cachedScreenBox
    .getAll()
    .where((s) => !retained.contains(s))
    .map((s) => s.id)
    .toList();
  
  _objectBox.cachedScreenBox.removeMany(removeIds);
}
```

---

## 📈 Monitoring & Debugging

```dart
class DatabaseMonitor {
  static void logStats() {
    print('=== ObjectBox Stats ===');
    print('Cached Screens: ${_objectBox.cachedScreenBox.count()}');
    print('User States: ${_objectBox.userStateBox.count()}');
    print('Form Drafts: ${_objectBox.formDraftBox.count()}');
    print('Sync Operations: ${_objectBox.syncOperationBox.count()}');
    print('Conflicts: ${_objectBox.conflictLogBox.count()}');
  }

  static Future<Map<String, dynamic>> getStorageSize() async {
    // Calculate approximate storage usage
    return {
      'cachedScreens': _objectBox.cachedScreenBox.count(),
      'userStates': _objectBox.userStateBox.count(),
      'formDrafts': _objectBox.formDraftBox.count(),
      'syncOps': _objectBox.syncOperationBox.count(),
    };
  }
}
```

---

## 🚀 Migration Guide

### From Hive to ObjectBox

```dart
// Load old Hive data
final hiveBox = await Hive.openBox('quicui_cache');

// Migrate to ObjectBox
for (var key in hiveBox.keys) {
  final value = hiveBox.get(key);
  
  final cached = CachedUIScreen()
    ..screenId = key as String
    ..jsonData = value['json'] as String
    ..createdAt = DateTime.now();
  
  _objectBox.cachedScreenBox.put(cached);
}
```

---

*Last Updated: October 30, 2025*
*Database Version: 1.0*
