/// ObjectBox entity representing cached screen data for local storage
///
/// This module defines the ScreenEntity class - the data model used by ObjectBox
/// for persisting screen configurations locally. Enables offline-first functionality
/// with efficient synchronization tracking.
///
/// ## Purpose
///
/// ScreenEntity bridges between:
/// - **Backend**: Remote Screen API models
/// - **Local Database**: ObjectBox persistent storage
/// - **Sync Layer**: Tracks sync state and conflicts
/// - **UI Layer**: Provides cached data for rendering
///
/// ## Storage Strategy
///
/// ```
/// Backend Screen (API)
///    ↓
/// ScreenEntity (local cache)
///    ├→ jsonData: Complete configuration
///    ├→ syncStatus: 'pending' | 'synced' | 'failed'
///    ├→ hasConflict: Conflict marker
///    └→ localModifiedAt: Change tracking
///    ↓
/// UI renders from ScreenEntity
/// Sync updates via SyncRepository
/// ```
///
/// ## Sync States
///
/// ```
/// Initial: Created locally (syncStatus = 'pending')
///    ↓
/// Uploading (syncStatus = 'synced' if success, 'failed' if error)
///    ↓
/// Synced (syncStatus = 'synced', no conflict)
///    ↓
/// Modified locally (syncStatus = 'pending')
///    ↓
/// Conflict (hasConflict = true, remoteVersion set)
/// ```
///
/// ## Data Flow
///
/// ```
/// User creates/modifies screen
///    ↓
/// ScreenEntity created/updated
///    ↓
/// Stored in ObjectBox Box<ScreenEntity>
///    ↓
/// SyncRepository detects needsSync()
///    ↓
/// Uploaded to backend
///    ↓
/// markAsSynced() called
///    ↓
/// syncStatus = 'synced'
/// ```
///
/// ## Usage Examples
///
/// ### Creating Entity
/// ```dart
/// final entity = ScreenEntity(
///   screenId: 'screen_123',
///   name: 'Home Screen',
///   jsonData: jsonEncode(screenData),
/// );
/// await objectbox.putScreen(entity);
/// ```
///
/// ### Tracking Changes
/// ```dart
/// // Mark as pending sync
/// entity.markAsPending();
/// await objectbox.putScreen(entity);
///
/// // After successful sync
/// entity.markAsSynced();
/// await objectbox.putScreen(entity);
/// ```
///
/// ### Conflict Resolution
/// ```dart
/// if (entity.hasConflict) {
///   // Show conflict to user
///   showConflictDialog(
///     local: jsonDecode(entity.jsonData),
///     remote: jsonDecode(entity.remoteVersion!),
///   );
/// }
/// ```
///
/// ## Database Schema
///
/// | Field | Type | Purpose |
/// |-------|------|---------|
/// | id | int | ObjectBox primary key (auto) |
/// | screenId | String | Unique backend identifier |
/// | name | String | Display name |
/// | version | int | Change version counter |
/// | jsonData | String | Complete configuration |
/// | lastUpdated | int | Sync timestamp |
/// | syncStatus | String | Sync state |
/// | failedAttempts | int | Retry counter |
/// | localModifiedAt | int | Local change timestamp |
/// | isDeleted | bool | Soft delete marker |
/// | hasConflict | bool | Conflict flag |
/// | remoteVersion | String | Remote version for conflict |
/// | widgetIds | List | Related widget IDs |
///
/// ## Best Practices
///
/// - **Check needsSync()**: Before SyncRepository operations
/// - **Update timestamps**: Always update lastUpdated on changes
/// - **Handle conflicts**: Check hasConflict before syncing
/// - **Track failures**: Monitor failedAttempts for retry logic
/// - **Soft deletes**: Use isDeleted for recovery
///
/// See also:
/// - [ObjectBoxDatabase]: Database manager
/// - [LocalDataSource]: Data source using this entity
/// - [SyncRepository]: Sync operations


import 'package:objectbox/objectbox.dart';

/// ObjectBox entity for locally cached screen data
///
/// Represents a screen configuration stored in ObjectBox database.
/// Handles offline persistence, sync state tracking, and conflict management.
///
/// ## ObjectBox Annotations
///
/// - `@Entity()`: Marks as ObjectBox entity (database table)
/// - `@Id()`: Primary key (auto-generated)
/// - `@Unique()`: screenId is unique constraint
///
/// ## Entity Lifecycle
///
/// ```
/// Created in memory
///    ↓
/// await objectbox.putScreen(entity)
///    ↓
/// Stored in ObjectBox
///    ↓
/// await objectbox.getScreen(id)
///    ↓
/// Retrieved and modified
///    ↓
/// await objectbox.putScreen(entity)
///    ↓
/// Updated in database
/// ```
///
/// ## Key Properties
///
/// **Identity**:
/// - `id`: ObjectBox-managed auto-increment primary key
/// - `screenId`: Backend-provided unique identifier
///
/// **Content**:
/// - `name`: Human-readable name for UI
/// - `jsonData`: Complete serialized screen configuration
/// - `version`: Change counter for optimistic locking
///
/// **Sync Tracking**:
/// - `syncStatus`: 'pending' | 'synced' | 'failed'
/// - `failedAttempts`: Number of sync failures
/// - `lastUpdated`: When last synced
/// - `localModifiedAt`: When locally changed
///
/// **Conflict Management**:
/// - `hasConflict`: True if local ≠ remote
/// - `remoteVersion`: Remote version string for comparison
/// - `isDeleted`: Soft delete marker for recovery
///
/// **Relations**:
/// - `widgetIds`: List of related widget identifiers
///
/// ## Example
///
/// ```dart
/// // Create new entity
/// final entity = ScreenEntity(
///   screenId: 'home_screen',
///   name: 'Home',
///   jsonData: jsonEncode({
///     'widgets': [...],
///     'layout': 'column',
///   }),
/// );
/// entity.version = 1;
///
/// // Save to database
/// await database.putScreen(entity);
///
/// // Retrieve and modify
/// final retrieved = database.getScreenByScreenId('home_screen');
/// retrieved?.version = 2;
/// retrieved?.markAsPending(); // Mark for next sync
/// await database.putScreen(retrieved!);
/// ```
@Entity()
class ScreenEntity {
  /// ObjectBox primary key (auto-generated)
  ///
  /// Automatically assigned by ObjectBox on first put.
  /// Default: 0 (indicates new entity, ObjectBox generates ID).
  /// When > 0: Entity exists in database.
  ///
  /// Used for fast lookups within ObjectBox.
  /// For external references, use [screenId] instead.
  @Id()
  int id = 0;

  /// Unique backend identifier for this screen
  ///
  /// Set by backend API (e.g., "screen_abc123").
  /// Used as natural primary key across systems.
  /// Cannot be changed after creation.
  ///
  /// Constraint: Unique in database (enforced by ObjectBox).
  /// Use for querying by business identifier.
  ///
  /// ## Example
  /// ```dart
  /// final entity = database.getScreenByScreenId('home_screen');
  /// ```
  @Unique()
  String screenId = '';

  /// Display name or title of the screen
  ///
  /// Human-readable name shown in UI.
  /// Can be updated without affecting syncing.
  ///
  /// ## Example
  /// - "Home Screen"
  /// - "User Profile"
  /// - "Settings Page"
  String name = '';

  /// Version number for change tracking
  ///
  /// Incremented on each modification.
  /// Used for:
  /// - Optimistic locking
  /// - Change detection
  /// - Conflict resolution
  ///
  /// Initial value: 0
  /// Incremented by: SyncRepository on successful sync
  int version = 0;

  /// Complete serialized screen configuration as JSON
  ///
  /// Stores full screen definition including:
  /// - Widget tree structure
  /// - Layout configuration
  /// - Widget properties
  /// - Event handlers
  /// - Custom data
  ///
  /// Format: JSON string (use `jsonDecode()` to parse)
  ///
  /// ## Example
  /// ```json
  /// {
  ///   "id": "screen_123",
  ///   "widgets": [...],
  ///   "layout": "column"
  /// }
  /// ```
  ///
  /// ## Storage Note
  /// Stored as string to avoid complex nested objects.
  /// ObjectBox works best with simple types.
  String jsonData = '';

  /// Last update timestamp (milliseconds since epoch)
  ///
  /// Set to `DateTime.now().millisecondsSinceEpoch` when synced.
  /// Used to determine cache staleness and sync order.
  ///
  /// ## Example
  /// ```dart
  /// final time = DateTime.fromMillisecondsSinceEpoch(lastUpdated);
  /// final age = DateTime.now().difference(time);
  /// ```
  int lastUpdated = 0;

  /// Synchronization status with backend
  ///
  /// Values:
  /// - `'pending'`: Awaiting sync, created/modified locally
  /// - `'synced'`: Successfully synced with backend
  /// - `'failed'`: Sync failed, will retry
  ///
  /// Transitions:
  /// ```
  /// pending → synced (on successful upload)
  /// pending → failed (on error)
  /// synced → pending (on local modification)
  /// failed → pending (on retry)
  /// ```
  ///
  /// Query sync-pending screens:
  /// ```dart
  /// final pending = database.getScreensNeedingSync();
  /// ```
  String syncStatus = 'synced';

  /// Count of failed synchronization attempts
  ///
  /// Incremented each time sync fails.
  /// Reset to 0 on successful sync.
  /// Used to determine if we should give up retrying.
  ///
  /// Typical retry strategy:
  /// - failedAttempts < 3: Retry
  /// - failedAttempts >= 3: Mark as failed, alert user
  ///
  /// ## Exponential Backoff Example
  /// ```dart
  /// final backoffSeconds = 2 << entity.failedAttempts;  // 2, 4, 8 seconds
  /// await Future.delayed(Duration(seconds: backoffSeconds));
  /// ```
  int failedAttempts = 0;

  /// Local modification timestamp (milliseconds since epoch)
  ///
  /// Updated whenever screen is modified locally (before syncing).
  /// Allows sorting by "recently modified".
  ///
  /// Different from [lastUpdated]:
  /// - [lastUpdated]: When sync completed
  /// - [localModifiedAt]: When locally changed
  ///
  /// ## Query Recently Modified
  /// ```dart
  /// final recent = database.getRecentlyModified(sinceTime: Duration(minutes: 5));
  /// ```
  int localModifiedAt = 0;

  /// Soft delete marker
  ///
  /// When true: Record marked as deleted locally but not yet synced deletion.
  /// Allows recovery if sync fails or user changes mind.
  ///
  /// Sync process: Send deletion to backend, then purge from database.
  /// Until sync: Query filters out isDeleted=true items.
  ///
  /// Advantages:
  /// - Recovery from accidental delete
  /// - Preserve undo history
  /// - Transaction safety
  bool isDeleted = false;

  /// Data conflict indicator
  ///
  /// Set to true when:
  /// - Local and remote versions diverge
  /// - Merge conflict detected during sync
  /// - User modification during sync
  ///
  /// When true: [remoteVersion] contains conflicting remote data.
  /// Resolution: User chooses local or remote, or manual merge.
  ///
  /// Query conflicts:
  /// ```dart
  /// final conflicts = database.getScreensWithConflicts();
  /// ```
  bool hasConflict = false;

  /// Remote version for conflict detection
  ///
  /// Populated when [hasConflict] is true.
  /// Contains the remote version that conflicts with local.
  /// null if no conflict.
  ///
  /// Similar to jsonData, stores as JSON string.
  /// Use `jsonDecode()` to parse.
  ///
  /// ## Conflict Resolution Example
  /// ```dart
  /// if (entity.hasConflict) {
  ///   final local = jsonDecode(entity.jsonData);
  ///   final remote = jsonDecode(entity.remoteVersion!);
  ///   // Show UI for user to choose or merge
  /// }
  /// ```
  String? remoteVersion;

  /// List of related widget IDs
  ///
  /// References to widgets used in this screen.
  /// Enables quick lookup of widget dependencies.
  ///
  /// Stored as list in ObjectBox.
  /// Updated when widgets are added/removed from screen.
  final widgetIds = <String>[];

  /// Creates a new screen entity
  ///
  /// Initializes timestamps and default status.
  ///
  /// ## Parameters
  /// - [screenId]: Backend identifier (required)
  /// - [name]: Display name (required)
  /// - [jsonData]: Serialized configuration (required)
  ///
  /// ## Example
  /// ```dart
  /// final entity = ScreenEntity(
  ///   screenId: 'home_screen',
  ///   name: 'Home',
  ///   jsonData: jsonEncode(screenConfig),
  /// );
  /// ```
  ///
  /// ## Auto-Set
  /// - [id]: 0 (ObjectBox will assign)
  /// - [lastUpdated]: Current time
  /// - [localModifiedAt]: Current time
  /// - [syncStatus]: 'synced' (override with markAsPending())
  /// - [version]: 0
  ScreenEntity({
    required this.screenId,
    required this.name,
    required this.jsonData,
  }) {
    lastUpdated = DateTime.now().millisecondsSinceEpoch;
    localModifiedAt = lastUpdated;
  }

  /// Check if screen needs synchronization
  ///
  /// Returns true if screen has pending changes to sync.
  ///
  /// Returns true when:
  /// - syncStatus == 'pending': Never synced or local changes
  /// - syncStatus == 'failed': Previous sync failed
  ///
  /// Returns false when:
  /// - syncStatus == 'synced': Up to date with backend
  ///
  /// ## Usage
  /// ```dart
  /// final pending = database.getAllScreens()
  ///   .where((s) => s.needsSync())
  ///   .toList();
  /// ```
  ///
  /// See also:
  /// - [markAsPending]: Mark as needing sync
  /// - [markAsSynced]: Mark as synced
  /// - [markAsFailed]: Mark as failed
  bool needsSync() {
    return syncStatus == 'pending' || syncStatus == 'failed';
  }

  /// Mark screen as successfully synced
  ///
  /// Sets:
  /// - syncStatus: 'synced'
  /// - failedAttempts: 0 (reset failures)
  /// - lastUpdated: current time
  ///
  /// Call after successful backend sync.
  ///
  /// ## Example
  /// ```dart
  /// try {
  ///   await repository.uploadScreen(entity);
  ///   entity.markAsSynced();
  ///   await database.putScreen(entity);
  /// } catch (e) {
  ///   entity.markAsFailed();
  /// }
  /// ```
  ///
  /// See also:
  /// - [markAsFailed]: Mark as failed
  /// - [markAsPending]: Mark as pending
  void markAsSynced() {
    syncStatus = 'synced';
    failedAttempts = 0;
    lastUpdated = DateTime.now().millisecondsSinceEpoch;
  }

  /// Mark screen as failed to sync
  ///
  /// Sets:
  /// - syncStatus: 'failed'
  /// - failedAttempts: incremented
  /// - lastUpdated: current time
  ///
  /// Call when sync attempt fails.
  /// Use failedAttempts to implement retry logic.
  ///
  /// ## Example
  /// ```dart
  /// try {
  ///   await repository.uploadScreen(entity);
  ///   entity.markAsSynced();
  /// } catch (e) {
  ///   entity.markAsFailed();
  ///   if (entity.failedAttempts >= 3) {
  ///     alertUser('Sync failed for ${entity.name}');
  ///   }
  /// }
  /// ```
  ///
  /// See also:
  /// - [markAsSynced]: Mark as synced
  /// - [markAsPending]: Mark as pending
  void markAsFailed() {
    syncStatus = 'failed';
    failedAttempts++;
    lastUpdated = DateTime.now().millisecondsSinceEpoch;
  }

  /// Mark screen as pending synchronization
  ///
  /// Sets:
  /// - syncStatus: 'pending'
  /// - localModifiedAt: current time
  ///
  /// Call when screen is modified locally (before sync).
  /// Tells sync layer that changes need uploading.
  ///
  /// ## Example
  /// ```dart
  /// // User modified screen
  /// entity.name = 'Updated Name';
  /// entity.jsonData = jsonEncode(newConfig);
  /// entity.markAsPending();
  /// await database.putScreen(entity);
  /// // Next sync will upload this
  /// ```
  ///
  /// See also:
  /// - [markAsSynced]: Mark as synced
  /// - [markAsFailed]: Mark as failed
  void markAsPending() {
    syncStatus = 'pending';
    localModifiedAt = DateTime.now().millisecondsSinceEpoch;
  }

  /// Get age of cached data in seconds
  ///
  /// Calculates time elapsed since [lastUpdated].
  /// Useful for cache invalidation and staleness detection.
  ///
  /// ## Returns
  /// Seconds since last update
  ///
  /// ## Example
  /// ```dart
  /// final age = entity.getAgeSeconds();
  /// if (age > 3600) {  // Older than 1 hour
  ///   // Mark for refresh
  ///   entity.markAsPending();
  /// }
  /// ```
  ///
  /// ## Performance
  /// O(1) calculation, safe to call frequently
  int getAgeSeconds() {
    return DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(lastUpdated),
    ).inSeconds;
  }
}
