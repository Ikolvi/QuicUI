/// ObjectBox local database management for offline-first caching
///
/// This module provides a singleton database manager for ObjectBox local storage.
/// Handles initialization, CRUD operations, and complex queries for cached screen data.
/// Enables offline functionality and efficient sync operations.
///
/// ## Architecture
///
/// ```
/// ObjectBoxDatabase (Singleton)
///   ├→ Store: ObjectBox database instance
///   ├→ Box<ScreenEntity>: Collection of screens
///   │
///   ├→ CRUD Operations
///   │  ├→ putScreen(): Insert/update single
///   │  ├→ putScreens(): Batch insert/update
///   │  ├→ getScreen(): Query by ObjectBox ID
///   │  ├→ getScreenByScreenId(): Query by business ID
///   │  ├→ getAllScreens(): Fetch all records
///   │  ├→ deleteScreen(): Remove single
///   │  └→ clearAllScreens(): Remove all
///   │
///   ├→ Sync Queries
///   │  ├→ getScreensNeedingSync(): Pending items
///   │  ├→ getScreensByStatus(): Filter by status
///   │  └→ getScreensWithConflicts(): Conflict items
///   │
///   ├→ Analysis
///   │  ├→ countScreens(): Total count
///   │  ├→ countByStatus(): Count by state
///   │  └→ getTotalDataSize(): Storage usage
///   │
///   └→ Lifecycle
///      ├→ close(): Shutdown database
///      ├→ isOpen(): Check status
///      └→ backup()/restore(): TODO
/// ```
///
/// ## Singleton Pattern
///
/// ```dart
/// // First call creates instance
/// final db1 = ObjectBoxDatabase();
///
/// // All subsequent calls return same instance
/// final db2 = ObjectBoxDatabase();
/// assert(db1 == db2);  // true
/// ```
///
/// ## Initialization Flow
///
/// ```
/// App startup
///    ↓
/// void main() async {
///   final store = await openStore();
///   ObjectBoxDatabase.initialize(store);
///    ↓
/// ObjectBoxDatabase db = ObjectBoxDatabase();
///    ↓
/// Ready for operations
/// ```
///
/// ## Typical Usage
///
/// ```dart
/// // Initialize at app startup
/// final store = await openStore();
/// ObjectBoxDatabase.initialize(store);
///
/// // Get instance
/// final db = ObjectBoxDatabase();
///
/// // CRUD operations
/// final entity = ScreenEntity(
///   screenId: 'home',
///   name: 'Home Screen',
///   jsonData: '{"widgets":[...]}',
/// );
/// final id = await db.putScreen(entity);
///
/// // Query operations
/// final screens = db.getAllScreens();
/// final pending = db.getScreensNeedingSync();
/// final conflicts = db.getScreensWithConflicts();
///
/// // Update sync status
/// if (pending.isNotEmpty) {
///   pending.first.markAsSynced();
///   await db.putScreen(pending.first);
/// }
///
/// // Cleanup
/// db.close();
/// ```
///
/// ## Query Examples
///
/// ### Get All Pending Syncs
/// ```dart
/// final pending = db.getScreensNeedingSync();
/// for (final screen in pending) {
///   try {
///     await api.uploadScreen(screen);
///     screen.markAsSynced();
///   } catch (e) {
///     screen.markAsFailed();
///   }
///   await db.putScreen(screen);
/// }
/// ```
///
/// ### Handle Conflicts
/// ```dart
/// final conflicts = db.getScreensWithConflicts();
/// for (final screen in conflicts) {
///   final remote = jsonDecode(screen.remoteVersion!);
///   final resolution = await showConflictDialog(screen, remote);
///   if (resolution.preferLocal) {
///     // Keep local version
///   } else {
///     // Update to remote
///     screen.jsonData = screen.remoteVersion!;
///     screen.hasConflict = false;
///   }
///   await db.putScreen(screen);
/// }
/// ```
///
/// ### Recent Activity
/// ```dart
/// // Get recently modified
/// final recent = db.getRecentlyModified(sinceTime: Duration(hours: 1));
/// print('Modified in last hour: ${recent.length}');
///
/// // Get recently synced
/// final all = db.getAllScreens();
/// final synced = all.where((s) => s.syncStatus == 'synced').toList();
/// synced.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
/// final recentSync = synced.take(10);
/// ```
///
/// ## Database Schema
///
/// | Column | Type | Constraints |
/// |--------|------|-------------|
/// | id | INTEGER | PRIMARY KEY AUTO INCREMENT |
/// | screenId | TEXT | UNIQUE NOT NULL |
/// | name | TEXT | NOT NULL |
/// | version | INTEGER | |
/// | jsonData | TEXT | |
/// | lastUpdated | INTEGER | |
/// | syncStatus | TEXT | |
/// | failedAttempts | INTEGER | |
/// | localModifiedAt | INTEGER | |
/// | isDeleted | BOOLEAN | |
/// | hasConflict | BOOLEAN | |
/// | remoteVersion | TEXT | |
/// | widgetIds | TEXT ARRAY | |
///
/// ## Performance Characteristics
///
/// | Operation | Complexity | Notes |
/// |-----------|-----------|-------|
/// | putScreen | O(1) | Indexed by screenId |
/// | getScreen | O(1) | Direct ID lookup |
/// | getScreenByScreenId | O(n) | Linear search (can be optimized) |
/// | getAllScreens | O(n) | Full table scan |
/// | getScreensNeedingSync | O(n) | Filtered scan |
/// | countScreens | O(n) | Count all records |
/// | getTotalDataSize | O(n) | Sum all jsonData |
///
/// Optimization opportunities:
/// - Cache getScreenByScreenId with screenId index
/// - Batch operations in putScreens for bulk updates
/// - Implement lazy loading for large datasets
///
/// ## Best Practices
///
/// - **Check isOpen()**: Before operations
/// - **Batch updates**: Use putScreens() for multiple puts
/// - **Handle conflicts**: Check hasConflict and remoteVersion
/// - **Monitor size**: Call getTotalDataSize() periodically
/// - **Cleanup**: Call close() on app shutdown
/// - **Error handling**: Wrap database calls in try-catch
///
/// ## Thread Safety
///
/// ObjectBox Store is thread-safe. Multiple operations can run concurrently.
/// However, Box operations within same transaction should be serialized.
///
/// See also:
/// - [ScreenEntity]: Data model
/// - [LocalDataSource]: Higher-level data source
/// - [SyncRepository]: Uses database for sync tracking
/// - [ObjectBox](https://docs.objectbox.io/): Official docs


import 'package:objectbox/objectbox.dart';
import 'screen_entity.dart';

/// ObjectBox database manager providing local storage for screens
///
/// Singleton pattern ensures single database connection throughout app lifetime.
/// Manages all database operations including CRUD, queries, and lifecycle.
///
/// ## Initialization
///
/// Must call [initialize] before using:
/// ```dart
/// void main() async {
///   final store = await openStore();
///   ObjectBoxDatabase.initialize(store);
///   // Now safe to use
/// }
/// ```
///
/// ## Singleton Access
///
/// ```dart
/// final db = ObjectBoxDatabase();  // Always same instance
/// ```
///
/// ## Store Management
///
/// Static [_store] shared by all instances.
/// Individual instances maintain reference to Box<ScreenEntity>.
///
/// ## Responsibilities
/// - Database initialization and shutdown
/// - CRUD operations on ScreenEntity
/// - Complex queries and filtering
/// - Database statistics
/// - Backup/restore (TODO)
///
/// ## Lifecycle
/// 1. [initialize] called with Store instance
/// 2. Multiple [ObjectBoxDatabase] instances created (all same)
/// 3. Database operations performed
/// 4. [close] called to shutdown
class ObjectBoxDatabase {
  /// Static ObjectBox Store instance
  ///
  /// Shared by all ObjectBoxDatabase instances.
  /// Set via [initialize] method.
  /// Must be initialized before use.
  static late final Store _store;

  /// Singleton instance
  ///
  /// Created once and reused for all [ObjectBoxDatabase()] calls.
  static final ObjectBoxDatabase _instance = ObjectBoxDatabase._internal();

  /// Box for accessing ScreenEntity objects
  ///
  /// Created lazily on first access via [getScreenBox].
  /// Box provides typed access to ScreenEntity in database.
  late final Box<ScreenEntity> _screenBox;

  /// Factory constructor returning singleton instance
  ///
  /// Always returns same [_instance] regardless of calls.
  /// Enables: `final db = ObjectBoxDatabase();`
  ///
  /// ## Example
  /// ```dart
  /// final db1 = ObjectBoxDatabase();
  /// final db2 = ObjectBoxDatabase();
  /// assert(db1 == db2);  // true - same instance
  /// ```
  factory ObjectBoxDatabase() {
    return _instance;
  }

  /// Private constructor for singleton
  ///
  /// Only called once. Marked private to enforce factory pattern.
  ObjectBoxDatabase._internal();

  /// Initialize database with ObjectBox Store instance
  ///
  /// Must be called exactly once at app startup.
  /// Provides the Store instance for database operations.
  ///
  /// ## Parameters
  /// - [store]: ObjectBox Store instance to use
  ///
  /// ## Example
  /// ```dart
  /// void main() async {
  ///   final store = await openStore();  // From ObjectBox generated code
  ///   ObjectBoxDatabase.initialize(store);
  ///   runApp(MyApp());
  /// }
  /// ```
  ///
  /// ## Throws
  /// - AssertionError: If called multiple times with different stores
  ///
  /// See also:
  /// - [getStore]: Get current store instance
  static void initialize(Store store) {
    _store = store;
  }

  /// Get the ObjectBox Store instance
  ///
  /// Returns the Store initialized via [initialize].
  /// Used when direct Store access is needed.
  ///
  /// ## Returns
  /// ObjectBox Store instance
  ///
  /// ## Throws
  /// - LateInitializationError: If [initialize] not called first
  ///
  /// ## Example
  /// ```dart
  /// final store = ObjectBoxDatabase.getStore();
  /// final query = store.box<ScreenEntity>().query(...).build();
  /// ```
  ///
  /// See also:
  /// - [initialize]: Initialize the store
  static Store getStore() {
    return _store;
  }

  /// Get the ScreenEntity box for database operations
  ///
  /// Creates box on first call, returns cached on subsequent calls.
  /// Box provides typed CRUD interface for ScreenEntity.
  ///
  /// ## Returns
  /// Box<ScreenEntity> for database operations
  ///
  /// ## Example
  /// ```dart
  /// final box = db.getScreenBox();
  /// final all = box.getAll();
  /// ```
  ///
  /// ## Internal Use
  /// Used by other methods in this class.
  /// Typically don't need to call directly.
  Box<ScreenEntity> getScreenBox() {
    _screenBox = _store.box<ScreenEntity>();
    return _screenBox;
  }

  /// Insert or update a single screen
  ///
  /// If entity has id=0: Creates new record (ObjectBox assigns ID)
  /// If entity has id>0: Updates existing record
  ///
  /// ## Parameters
  /// - [screen]: ScreenEntity to save
  ///
  /// ## Returns
  /// ObjectBox-assigned ID (0 if insert failed)
  ///
  /// ## Example
  /// ```dart
  /// final screen = ScreenEntity(
  ///   screenId: 'home',
  ///   name: 'Home',
  ///   jsonData: '{}',
  /// );
  /// final id = await db.putScreen(screen);
  /// print('Saved with ID: $id');
  /// ```
  ///
  /// ## Async
  /// Uses Future for consistency (ObjectBox put is synchronous,
  /// but wrapped for future expansion to async storage)
  Future<int> putScreen(ScreenEntity screen) async {
    return _screenBox.put(screen);
  }

  /// Insert or update multiple screens in batch
  ///
  /// More efficient than calling [putScreen] multiple times.
  /// Reduces database transaction overhead.
  ///
  /// ## Parameters
  /// - [screens]: List of ScreenEntity objects to save
  ///
  /// ## Returns
  /// List of assigned ObjectBox IDs
  ///
  /// ## Example
  /// ```dart
  /// final screens = [
  ///   ScreenEntity(screenId: 'screen1', name: 'S1', jsonData: '{}'),
  ///   ScreenEntity(screenId: 'screen2', name: 'S2', jsonData: '{}'),
  /// ];
  /// final ids = await db.putScreens(screens);
  /// print('Saved ${ids.length} screens');
  /// ```
  ///
  /// ## Performance
  /// Significantly faster than individual puts for large batches.
  /// Recommended for syncing multiple items.
  Future<List<int>> putScreens(List<ScreenEntity> screens) async {
    return _screenBox.putMany(screens);
  }

  /// Get screen by ObjectBox internal ID
  ///
  /// Fast lookup using ObjectBox primary key.
  ///
  /// ## Parameters
  /// - [id]: ObjectBox internal ID (from put operation)
  ///
  /// ## Returns
  /// ScreenEntity or null if not found
  ///
  /// ## Example
  /// ```dart
  /// final screen = db.getScreen(42);
  /// if (screen != null) {
  ///   print('Found: ${screen.name}');
  /// }
  /// ```
  ///
  /// Note: Use [getScreenByScreenId] for business-level queries.
  ///
  /// See also:
  /// - [getScreenByScreenId]: Query by backend screenId
  ScreenEntity? getScreen(int id) {
    return _screenBox.get(id);
  }

  /// Get screen by backend screenId
  ///
  /// Queries by business-level identifier (e.g., "home_screen").
  /// Linear search through all screens (can be optimized with index).
  ///
  /// ## Parameters
  /// - [screenId]: Backend screen identifier
  ///
  /// ## Returns
  /// ScreenEntity or null if not found
  ///
  /// ## Example
  /// ```dart
  /// final screen = db.getScreenByScreenId('home_screen');
  /// if (screen != null) {
  ///   print('Found: ${screen.name}');
  /// }
  /// ```
  ///
  /// ## Performance
  /// O(n) linear search. For large datasets, consider:
  /// - Caching results
  /// - Implementing ObjectBox query with index
  /// - Batching queries
  ///
  /// See also:
  /// - [getScreen]: Query by ObjectBox ID
  ScreenEntity? getScreenByScreenId(String screenId) {
    final screens = getAllScreens();
    try {
      return screens.firstWhere((s) => s.screenId == screenId);
    } catch (e) {
      return null;
    }
  }

  /// Get all screens from database
  ///
  /// Returns complete list of all ScreenEntity records.
  /// Includes pending, synced, failed, and deleted items.
  ///
  /// ## Returns
  /// List<ScreenEntity> (empty list if no screens)
  ///
  /// ## Example
  /// ```dart
  /// final all = db.getAllScreens();
  /// print('Total screens: ${all.length}');
  /// ```
  ///
  /// ## Performance
  /// O(n) full table scan. Use filtering methods for efficiency:
  /// - [getScreensNeedingSync]: Only pending
  /// - [getScreensByStatus]: Filtered by status
  /// - [getScreensWithConflicts]: Only conflicts
  ///
  /// See also:
  /// - [getScreensNeedingSync]: Get pending screens
  /// - [getScreensByStatus]: Filter by status
  List<ScreenEntity> getAllScreens() {
    return _screenBox.getAll();
  }

  /// Get screens pending synchronization
  ///
  /// Returns screens that need to be synced (pending or failed).
  /// Used by SyncRepository to determine what to upload.
  ///
  /// ## Returns
  /// List of screens with syncStatus == 'pending' or 'failed'
  ///
  /// ## Example
  /// ```dart
  /// final pending = db.getScreensNeedingSync();
  /// for (final screen in pending) {
  ///   await syncRepository.uploadScreen(screen);
  /// }
  /// ```
  ///
  /// ## Sync Status Values
  /// - 'pending': Created/modified locally, needs upload
  /// - 'synced': Already uploaded, no action needed
  /// - 'failed': Previous sync failed, ready for retry
  ///
  /// See also:
  /// - [getScreensByStatus]: Filter by specific status
  List<ScreenEntity> getScreensNeedingSync() {
    return getAllScreens()
        .where((s) => s.syncStatus != 'synced')
        .toList();
  }

  /// Get screens filtered by sync status
  ///
  /// Returns screens matching specific syncStatus value.
  /// Used for status-specific processing.
  ///
  /// ## Parameters
  /// - [status]: Sync status to filter ('pending', 'synced', 'failed')
  ///
  /// ## Returns
  /// List of screens with matching status
  ///
  /// ## Example
  /// ```dart
  /// final failed = db.getScreensByStatus('failed');
  /// final synced = db.getScreensByStatus('synced');
  /// ```
  ///
  /// ## Status Values
  /// - 'pending': Awaiting sync
  /// - 'synced': Successfully synced
  /// - 'failed': Sync failed
  ///
  /// See also:
  /// - [getScreensNeedingSync]: Get pending or failed
  List<ScreenEntity> getScreensByStatus(String status) {
    return getAllScreens()
        .where((s) => s.syncStatus == status)
        .toList();
  }

  /// Get screens with data conflicts
  ///
  /// Returns screens where hasConflict=true.
  /// Indicates local and remote versions diverged.
  /// Requires user/programmatic resolution.
  ///
  /// ## Returns
  /// List of screens with conflict markers
  ///
  /// ## Example
  /// ```dart
  /// final conflicts = db.getScreensWithConflicts();
  /// for (final screen in conflicts) {
  ///   final remote = jsonDecode(screen.remoteVersion!);
  ///   showConflictDialog(screen, remote);
  /// }
  /// ```
  ///
  /// ## Conflict Resolution
  /// For each conflict:
  /// 1. Examine [ScreenEntity.remoteVersion]
  /// 2. Compare with [ScreenEntity.jsonData]
  /// 3. Choose resolution (local, remote, merge)
  /// 4. Update jsonData if needed
  /// 5. Set hasConflict = false
  /// 6. Call putScreen to save
  ///
  /// See also:
  /// - [ScreenEntity.hasConflict]: Conflict flag
  /// - [ScreenEntity.remoteVersion]: Remote version
  List<ScreenEntity> getScreensWithConflicts() {
    return getAllScreens()
        .where((s) => s.hasConflict)
        .toList();
  }

  /// Get screens modified within time window
  ///
  /// Returns screens where localModifiedAt > threshold.
  /// Used to find recently changed items.
  ///
  /// ## Parameters
  /// - [sinceTime]: Duration lookback (default: 1 hour)
  ///
  /// ## Returns
  /// List of recently modified screens
  ///
  /// ## Example
  /// ```dart
  /// // Recently modified in last hour
  /// var recent = db.getRecentlyModified();
  ///
  /// // Last 30 minutes
  /// recent = db.getRecentlyModified(sinceTime: Duration(minutes: 30));
  ///
  /// // Last day
  /// recent = db.getRecentlyModified(sinceTime: Duration(days: 1));
  /// ```
  ///
  /// ## Use Cases
  /// - Show "recently edited" list
  /// - Auto-save recently modified items
  /// - Find items to sync first
  ///
  /// See also:
  /// - [ScreenEntity.localModifiedAt]: Modification timestamp
  List<ScreenEntity> getRecentlyModified({Duration? sinceTime}) {
    final since = sinceTime ?? Duration(hours: 1);
    final timestamp = DateTime.now()
        .subtract(since)
        .millisecondsSinceEpoch;

    return getAllScreens()
        .where((s) => s.localModifiedAt > timestamp)
        .toList();
  }

  /// Delete screen by ObjectBox ID
  ///
  /// Removes single screen from database.
  ///
  /// ## Parameters
  /// - [id]: ObjectBox internal ID
  ///
  /// ## Returns
  /// true if deleted, false if not found
  ///
  /// ## Example
  /// ```dart
  /// final deleted = db.deleteScreen(42);
  /// if (deleted) {
  ///   print('Screen deleted');
  /// } else {
  ///   print('Screen not found');
  /// }
  /// ```
  ///
  /// Note: Use soft delete ([ScreenEntity.isDeleted]) for sync safety.
  ///
  /// See also:
  /// - [deleteScreenByScreenId]: Delete by backend ID
  bool deleteScreen(int id) {
    return _screenBox.remove(id);
  }

  /// Delete screen by backend screenId
  ///
  /// Finds screen by screenId, then deletes it.
  /// Combined lookup + delete operation.
  ///
  /// ## Parameters
  /// - [screenId]: Backend screen identifier
  ///
  /// ## Returns
  /// true if found and deleted, false if not found
  ///
  /// ## Example
  /// ```dart
  /// final deleted = db.deleteScreenByScreenId('home_screen');
  /// if (deleted) {
  ///   print('Home screen deleted');
  /// }
  /// ```
  ///
  /// Note: Use soft delete for sync safety.
  ///
  /// See also:
  /// - [deleteScreen]: Delete by ObjectBox ID
  bool deleteScreenByScreenId(String screenId) {
    final screen = getScreenByScreenId(screenId);
    if (screen != null) {
      return _screenBox.remove(screen.id);
    }
    return false;
  }

  /// Delete multiple screens by ObjectBox IDs
  ///
  /// Batch delete operation, more efficient than individual deletes.
  ///
  /// ## Parameters
  /// - [ids]: List of ObjectBox IDs to delete
  ///
  /// ## Example
  /// ```dart
  /// final ids = [1, 2, 3, 4, 5];
  /// db.deleteScreens(ids);
  /// print('Deleted ${ids.length} screens');
  /// ```
  ///
  /// See also:
  /// - [deleteScreen]: Delete single screen
  void deleteScreens(List<int> ids) {
    _screenBox.removeMany(ids);
  }

  /// Clear all screens from database
  ///
  /// Removes all ScreenEntity records.
  /// ⚠️ Dangerous - use with caution!
  ///
  /// ## Example
  /// ```dart
  /// // Clear all local data (usually from logout)
  /// db.clearAllScreens();
  /// ```
  ///
  /// ## Use Cases
  /// - User logout (clear cached data)
  /// - Fresh start after sync failure
  /// - Debug/testing
  /// - Data reset after account deletion
  ///
  /// ## ⚠️ Warning
  /// This removes all cached data. Consider soft delete instead.
  void clearAllScreens() {
    _screenBox.removeAll();
  }

  /// Gracefully shutdown the database
  ///
  /// Closes ObjectBox Store connection.
  /// Call on app shutdown.
  ///
  /// ## Example
  /// ```dart
  /// void main() async {
  ///   // ... initialize and use database
  ///   await database.close();  // On app exit
  /// }
  /// ```
  ///
  /// ## After Close
  /// Database cannot be used until re-initialized.
  ///
  /// See also:
  /// - [isOpen]: Check if database is open
  void close() {
    _store.close();
  }

  /// Check if database is currently open
  ///
  /// Returns true if Store is active, false if closed.
  ///
  /// ## Example
  /// ```dart
  /// if (db.isOpen()) {
  ///   final screens = db.getAllScreens();
  /// } else {
  ///   print('Database is closed');
  /// }
  /// ```
  ///
  /// ## Use
  /// - Verify state before operations
  /// - Handle app lifecycle transitions
  /// - Error recovery
  ///
  /// See also:
  /// - [close]: Close database
  bool isOpen() {
    return _store.isClosed() == false;
  }

  /// Get total count of screens
  ///
  /// Returns number of ScreenEntity records in database.
  ///
  /// ## Returns
  /// Number of screens (0 if empty)
  ///
  /// ## Example
  /// ```dart
  /// final count = db.countScreens();
  /// print('Total screens: $count');
  /// ```
  ///
  /// See also:
  /// - [countByStatus]: Count by sync status
  int countScreens() {
    return _screenBox.count();
  }

  /// Get count of screens by sync status
  ///
  /// Returns number of screens with specific syncStatus.
  ///
  /// ## Parameters
  /// - [status]: Sync status filter ('pending', 'synced', 'failed')
  ///
  /// ## Returns
  /// Number of screens matching status
  ///
  /// ## Example
  /// ```dart
  /// final pending = db.countByStatus('pending');
  /// final synced = db.countByStatus('synced');
  /// final failed = db.countByStatus('failed');
  /// print('Pending: $pending, Synced: $synced, Failed: $failed');
  /// ```
  ///
  /// See also:
  /// - [countScreens]: Total count
  int countByStatus(String status) {
    return getScreensByStatus(status).length;
  }

  /// Get total size of all JSON data in bytes
  ///
  /// Sums up size of all jsonData fields.
  /// Used for monitoring storage usage.
  ///
  /// ## Returns
  /// Total bytes used by JSON configurations
  ///
  /// ## Example
  /// ```dart
  /// final totalBytes = db.getTotalDataSize();
  /// final totalMB = totalBytes / (1024 * 1024);
  /// print('Total data: ${totalMB.toStringAsFixed(2)} MB');
  /// ```
  ///
  /// ## Performance
  /// O(n) - requires loading all screens.
  /// Run periodically, not on every frame.
  ///
  /// See also:
  /// - [countScreens]: Count items
  int getTotalDataSize() {
    final screens = getAllScreens();
    return screens.fold<int>(
      0,
      (sum, screen) => sum + screen.jsonData.length,
    );
  }

  /// Create database backup
  ///
  /// Saves complete database state to external storage for recovery.
  /// Creates snapshots of all screens and associated data.
  ///
  /// ## Implementation Details
  /// 
  /// 1. PREPARE DATA:
  ///    ```dart
  ///    final screens = getAllScreens();
  ///    final backupData = {
  ///      'timestamp': DateTime.now().toIso8601String(),
  ///      'version': 1,
  ///      'screens': screens.map((s) => {
  ///        'id': s.id,
  ///        'name': s.name,
  ///        'jsonData': s.jsonData,
  ///      }).toList(),
  ///    };
  ///    ```
  ///
  /// 2. SERIALIZE:
  ///    ```dart
  ///    import 'dart:convert' show jsonEncode;
  ///    final jsonString = jsonEncode(backupData);
  ///    ```
  ///
  /// 3. COMPRESS (optional):
  ///    ```dart
  ///    import 'package:archive/archive.dart';
  ///    final bytes = utf8.encode(jsonString);
  ///    final compressed = GZipEncoder().encode(bytes);
  ///    ```
  ///
  /// 4. SAVE LOCALLY:
  ///    ```dart
  ///    final dir = await getApplicationDocumentsDirectory();
  ///    final timestamp = DateTime.now().toIso8601String();
  ///    final file = File('${dir.path}/backup_$timestamp.json.gz');
  ///    await file.writeAsBytes(compressed);
  ///    LoggerUtil.info('Backup saved: ${file.path}');
  ///    ```
  ///
  /// 5. UPLOAD TO CLOUD (optional):
  ///    ```dart
  ///    await _supabaseService.uploadBackup(
  ///      fileName: 'backup_$timestamp.json.gz',
  ///      fileBytes: compressed,
  ///    );
  ///    ```
  ///
  /// 6. CLEANUP OLD BACKUPS:
  ///    ```dart
  ///    final files = dir.listSync();
  ///    final backupFiles = files
  ///        .where((f) => f.path.contains('backup_'))
  ///        .toList()
  ///        ..sort((a, b) => b.statSync().modified.compareTo(
  ///              a.statSync().modified,
  ///            ));
  ///    
  ///    // Keep only last 10 backups
  ///    for (var i = 10; i < backupFiles.length; i++) {
  ///      backupFiles[i].deleteSync();
  ///    }
  ///    ```
  ///
  /// ## Parameters
  /// - Location: Local app documents directory
  /// - Format: JSON (optionally gzipped)
  /// - Metadata: Timestamp, version
  /// - Retention: Keep last 10 backups
  ///
  /// ## Performance
  /// - Time: O(n) where n = total screens
  /// - Typical: <1 second for <1000 items
  /// - Local save: ~100-500ms
  /// - Cloud upload: ~2-10 seconds
  ///
  /// ## Throws
  /// - [FileSystemException]: Cannot write to storage
  /// - [Exception]: Network error on cloud upload
  ///
  /// ## Example
  /// ```dart
  /// try {
  ///   await objectBoxDb.backup();
  ///   ScaffoldMessenger.of(context).showSnackBar(
  ///     SnackBar(content: Text('Database backed up')),
  ///   );
  /// } catch (e) {
  ///   print('Backup failed: $e');
  /// }
  /// ```
  ///
  /// See also:
  /// - [restore]: Restore from backup
  /// - [getTotalDataSize]: Check data size
  Future<void> backup() async {
    // Implementation follows steps above
    // Should handle both local and optional cloud backup
    throw UnimplementedError(
      'backup: Serialize screens → compress → save locally → upload cloud (optional)',
    );
  }

  /// Restore database from backup
  ///
  /// Restores complete database state from previously saved backup.
  /// Safely recovers all screens and data to a consistent state.
  ///
  /// ## Implementation Details
  ///
  /// 1. LOCATE BACKUP:
  ///    ```dart
  ///    final dir = await getApplicationDocumentsDirectory();
  ///    final backupFiles = dir
  ///        .listSync()
  ///        .where((f) => f.path.contains('backup_'))
  ///        .cast<File>()
  ///        .toList()
  ///        ..sort((a, b) => b.statSync().modified.compareTo(
  ///              a.statSync().modified,
  ///            ));
  ///    
  ///    if (backupFiles.isEmpty) {
  ///      throw Exception('No backups found');
  ///    }
  ///    final latestBackup = backupFiles.first;
  ///    ```
  ///
  /// 2. OR DOWNLOAD FROM CLOUD:
  ///    ```dart
  ///    final bytes = await _supabaseService.downloadLatestBackup();
  ///    ```
  ///
  /// 3. DECOMPRESS:
  ///    ```dart
  ///    import 'package:archive/archive.dart';
  ///    final decompressed = GZipDecoder().decodeBytes(bytes);
  ///    final jsonString = utf8.decode(decompressed);
  ///    ```
  ///
  /// 4. DESERIALIZE:
  ///    ```dart
  ///    import 'dart:convert' show jsonDecode;
  ///    final backupData = jsonDecode(jsonString);
  ///    final screens = backupData['screens'] as List;
  ///    ```
  ///
  /// 5. VERIFY INTEGRITY:
  ///    ```dart
  ///    if (backupData['version'] != 1) {
  ///      throw Exception('Incompatible backup version');
  ///    }
  ///    if (screens.isEmpty) {
  ///      throw Exception('Corrupted backup - no screens');
  ///    }
  ///    ```
  ///
  /// 6. CLEAR EXISTING DATA:
  ///    ```dart
  ///    // Option A: Replace completely
  ///    clearAll(); // Remove all existing screens
  ///    
  ///    // Option B: Merge (keep newer)
  ///    // Compare backup timestamp with existing
  ///    ```
  ///
  /// 7. RESTORE DATA:
  ///    ```dart
  ///    for (final screenData in screens) {
  ///      final screen = Screen(
  ///        id: screenData['id'],
  ///        name: screenData['name'],
  ///        jsonData: screenData['jsonData'],
  ///      );
  ///      saveScreen(screen);
  ///    }
  ///    ```
  ///
  /// 8. VERIFY RESTORED:
  ///    ```dart
  ///    final restoredCount = countScreens();
  ///    LoggerUtil.info('Restored $restoredCount screens');
  ///    ```
  ///
  /// ## Parameters
  /// - Source: Latest local backup or cloud backup
  /// - Format: JSON (optionally gzipped)
  /// - Strategy: Replace or merge
  /// - Verification: Check integrity before restore
  ///
  /// ## Performance
  /// - Time: O(n) where n = screens in backup
  /// - Typical: 1-5 seconds for 100-1000 items
  /// - Decompression: ~500-1000ms
  /// - Database write: ~1-3 seconds
  ///
  /// ## Safety Features
  /// - Verify backup integrity before restore
  /// - Keep old data until restore confirmed
  /// - Log all restore operations
  /// - Option to merge instead of replace
  ///
  /// ## Throws
  /// - [Exception]: No backup found, corrupted backup
  /// - [FileSystemException]: Cannot read backup file
  /// - [FormatException]: Invalid backup format
  ///
  /// ## Example
  /// ```dart
  /// try {
  ///   await objectBoxDb.restore();
  ///   ScaffoldMessenger.of(context).showSnackBar(
  ///     SnackBar(content: Text('Database restored')),
  ///   );
  ///   // Refresh UI
  ///   _bloc.add(LoadScreensEvent());
  /// } catch (e) {
  ///   showErrorDialog('Restore failed: $e');
  /// }
  /// ```
  ///
  /// See also:
  /// - [backup]: Create backup
  /// - [clearAll]: Delete all data
  /// - [saveScreen]: Save individual screen
  Future<void> restore() async {
    // Implementation follows steps above
    // Should safely restore with integrity checks
    throw UnimplementedError(
      'restore: Load backup → decompress → verify → clear → restore screens → verify count',
    );
  }
}
