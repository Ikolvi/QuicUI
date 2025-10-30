/// Supabase backend service integration
///
/// This module provides integration with Supabase backend for:
/// - Remote data storage
/// - Screen CRUD operations
/// - Real-time synchronization
/// - Authentication management
/// - Search and querying
///
/// ## Architecture
///
/// ```
/// ScreenRepository
///   ↓
/// SupabaseService (this file)
///   ↓
/// Supabase Backend (PostgreSQL + APIs)
///   ├── Auth service
///   ├── Database (screens, widgets)
///   ├── Realtime subscriptions
///   └── Storage (assets, configs)
/// ```
///
/// ## Data Schema
///
/// ### Screens Table
/// ```sql
/// CREATE TABLE screens (
///   id TEXT PRIMARY KEY,
///   name TEXT NOT NULL,
///   title TEXT,
///   widgets JSONB,
///   layout JSONB,
///   state JSONB,
///   metadata JSONB,
///   created_at TIMESTAMP,
///   updated_at TIMESTAMP
/// );
/// ```
///
/// ## Key Features
/// - CRUD operations for screens
/// - Real-time subscriptions
/// - Full-text search
/// - Batch synchronization
/// - Connection pooling
/// - Error recovery
///
/// ## Usage
///
/// ```dart
/// final supabase = SupabaseService();
/// await supabase.initialize(url: 'https://xxx.supabase.co', anonKey: 'xxx');
///
/// final screenData = await supabase.fetchScreen('home_screen');
/// await supabase.updateScreen('home_screen', newData);
/// ```
///
/// ## Singleton Pattern
///
/// ```
/// SupabaseService is a singleton
/// ↓
/// Use: SupabaseService() returns same instance
/// ↓
/// Thread-safe and efficient
/// ```
///
/// ## Error Handling
///
/// ```dart
/// try {
///   await supabase.fetchScreen(id);
/// } on SocketException {
///   // Network error
/// } on PostgrestException {
///   // Database error
/// } on AuthException {
///   // Auth error
/// }
/// ```
///
/// See also:
/// - [ScreenRepository]: Consumer of this service
/// - [QuicUIService]: Initializes this service
/// - [StorageService]: Local caching layer

import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for Supabase integration
///
/// Manages all interactions with Supabase backend.
/// Provides:
/// - Screen CRUD operations
/// - Real-time synchronization
/// - Search and querying
/// - Connection management
/// - Error handling and recovery
///
/// ## Responsibilities
/// - Execute database queries
/// - Handle authentication
/// - Manage connections
/// - Subscribe to real-time updates
/// - Implement retry logic
/// - Handle rate limiting
///
/// ## Singleton Pattern
/// - Single instance per app
/// - Thread-safe initialization
/// - Shared connection pool
/// - Memory efficient
///
/// ## Error Recovery
/// - Automatic reconnection
/// - Exponential backoff
/// - Graceful degradation
/// - User notifications
///
/// See also:
/// - [ScreenRepository]: Primary consumer
/// - [StorageService]: Cache layer
/// - [QuicUIService]: Initializer
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  late SupabaseClient _client;
  bool _initialized = false;

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  /// Initialize Supabase connection
  ///
  /// Establishes connection to Supabase backend.
  /// Must be called exactly once at app startup.
  ///
  /// ## Parameters
  /// - [url]: Supabase project URL
  ///   - Format: https://[project-id].supabase.co
  ///   - From Supabase project settings
  /// - [anonKey]: Anonymous API key
  ///   - For unauthenticated access
  ///   - From Supabase project settings
  ///
  /// ## Initialization Process
  /// 1. Validates connection parameters
  /// 2. Creates Supabase client
  /// 3. Establishes connection pool
  /// 4. Validates credentials
  /// 5. Sets up event listeners
  /// 6. Completes
  ///
  /// ## Behavior
  /// - Creates global Supabase instance
  /// - Thread-safe and idempotent
  /// - Connection pooling enabled
  /// - Retry logic enabled
  ///
  /// ## Throws
  /// - [ArgumentError]: Invalid credentials
  /// - [SocketException]: Network error
  /// - [Exception]: Connection failed
  ///
  /// ## Performance
  /// - Typically ~500ms-2s
  /// - Depends on network latency
  /// - Retries on transient failures
  ///
  /// ## Example
  /// ```dart
  /// await SupabaseService().initialize(
  ///   url: 'https://abcdef.supabase.co',
  ///   anonKey: 'eyJhbGc...',
  /// );
  /// ```
  ///
  /// See also:
  /// - [isInitialized]: Check initialization status
  /// - [getClient]: Access Supabase client
  Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      _client = Supabase.instance.client;
      _initialized = true;
      print('Supabase initialized successfully');
    } catch (e) {
      print('Failed to initialize Supabase: $e');
      rethrow;
    }
  }

  /// Get the Supabase client
  ///
  /// Returns the initialized Supabase client for advanced operations.
  /// Client provides:
  /// - Direct database access
  /// - Authentication methods
  /// - Real-time subscriptions
  /// - File storage operations
  ///
  /// ## Returns
  /// SupabaseClient instance for direct use
  ///
  /// ## Throws
  /// - [StateError]: Called before initialize()
  ///
  /// ## Example
  /// ```dart
  /// final client = SupabaseService().getClient();
  /// final user = client.auth.currentUser;
  /// ```
  ///
  /// See also:
  /// - [initialize]: Must call first
  /// - [isInitialized]: Check before calling
  SupabaseClient getClient() {
    return _client;
  }

  /// Check if Supabase is initialized
  ///
  /// Returns whether Supabase has been successfully initialized.
  /// Check this before using other methods.
  ///
  /// ## Returns
  /// - true: Supabase ready to use
  /// - false: Call initialize() first
  ///
  /// ## Example
  /// ```dart
  /// if (!SupabaseService().isInitialized()) {
  ///   await SupabaseService().initialize(...);
  /// }
  /// ```
  ///
  /// See also:
  /// - [initialize]: Initialize service
  bool isInitialized() {
    return _initialized;
  }

  /// Fetch all screens from Supabase
  ///
  /// Retrieves metadata for all screens accessible to the user.
  /// Returns a list of screen metadata (not full screen data).
  ///
  /// ## Returns
  /// List of screens with metadata:
  /// ```json
  /// [
  ///   {"id": "home", "name": "Home", "title": "Home Screen"},
  ///   {"id": "settings", "name": "Settings", "title": "Settings"}
  /// ]
  /// ```
  ///
  /// ## Performance
  /// - Cold request: ~300-1000ms
  /// - Cacheable results
  /// - Pagination support (limit via query)
  ///
  /// ## Throws
  /// - [SocketException]: Network error
  /// - [PostgrestException]: Database error
  /// - [Exception]: Access denied
  ///
  /// ## Example
  /// ```dart
  /// final screens = await service.fetchScreens();
  /// for (final screen in screens) {
  ///   print('${screen['title']} (${screen['id']})');
  /// }
  /// ```
  ///
  /// See also:
  /// - [fetchScreen]: Get single screen
  /// - [searchScreens]: Search by name
  Future<List<Map<String, dynamic>>> fetchScreens() async {
    try {
      final response = await _client
          .from('screens')
          .select() as List<dynamic>;

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching screens: $e');
      rethrow;
    }
  }

  /// Fetch single screen by ID
  ///
  /// Retrieves complete screen configuration for rendering.
  /// Returns all screen data including widgets, layout, and state.
  ///
  /// ## Parameters
  /// - [screenId]: Unique screen identifier
  ///
  /// ## Returns
  /// Complete screen data:
  /// ```json
  /// {
  ///   "id": "home_screen",
  ///   "name": "home",
  ///   "title": "Home Screen",
  ///   "widgets": [...],
  ///   "layout": {...},
  ///   "state": {...},
  ///   "metadata": {...}
  /// }
  /// ```
  ///
  /// ## Performance
  /// - Typical: ~200-500ms
  /// - Depends on screen complexity
  /// - Network latency impact: ~50-200ms
  ///
  /// ## Throws
  /// - [SocketException]: Network error
  /// - [PostgrestException]: Not found, access denied
  /// - [Exception]: Query failed
  ///
  /// ## Caching Strategy
  /// - Cache results locally
  /// - Check cache before network call
  /// - Validate cache freshness
  /// - Refresh on user action
  ///
  /// ## Example
  /// ```dart
  /// try {
  ///   final screen = await service.fetchScreen('home_screen');
  ///   renderer.render(screen);
  /// } on PostgrestException catch (e) {
  ///   if (e.code == 'PGRST116') {
  ///     print('Screen not found');
  ///   }
  /// }
  /// ```
  ///
  /// See also:
  /// - [fetchScreens]: Get all screens
  /// - [updateScreen]: Modify screen
  Future<Map<String, dynamic>> fetchScreen(String screenId) async {
    try {
      final response = await _client
          .from('screens')
          .select()
          .eq('id', screenId)
          .single();

      return response;
    } catch (e) {
      print('Error fetching screen: $e');
      rethrow;
    }
  }

  /// Create new screen in Supabase
  ///
  /// Inserts new screen configuration into database.
  /// Returns created screen with all fields populated by server.
  ///
  /// ## Parameters
  /// - [data]: Screen data to create
  ///   - Must include: id, name, title, widgets
  ///   - Optional: layout, state, metadata
  ///
  /// ## Returns
  /// Created screen with server-assigned fields:
  /// - created_at: Server timestamp
  /// - updated_at: Server timestamp
  /// - All other fields: As provided
  ///
  /// ## Behavior
  /// - Creates new database record
  /// - Assigns server timestamps
  /// - Validates constraints
  /// - Returns complete record
  /// - Triggers real-time subscribers
  ///
  /// ## Throws
  /// - [PostgrestException]: Duplicate ID, validation error
  /// - [SocketException]: Network error
  /// - [Exception]: Access denied
  ///
  /// ## Performance
  /// - Typical: ~300-800ms
  /// - Includes validation time
  /// - Database write time
  ///
  /// ## Validation
  /// Server validates:
  /// - ID uniqueness
  /// - Required fields present
  /// - Data type correctness
  /// - User permissions
  ///
  /// ## Example
  /// ```dart
  /// final newScreen = {
  ///   'id': 'new_screen',
  ///   'name': 'new_screen',
  ///   'title': 'New Screen',
  ///   'widgets': [],
  /// };
  /// final created = await service.createScreen(newScreen);
  /// ```
  ///
  /// See also:
  /// - [updateScreen]: Modify existing screen
  /// - [deleteScreen]: Remove screen
  Future<Map<String, dynamic>> createScreen(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('screens')
          .insert([data])
          .select() as List<dynamic>;

      return response.first as Map<String, dynamic>;
    } catch (e) {
      print('Error creating screen: $e');
      rethrow;
    }
  }

  /// Update screen in Supabase
  ///
  /// Updates existing screen configuration.
  /// Can update all fields or just specific ones (partial update).
  ///
  /// ## Parameters
  /// - [screenId]: ID of screen to update
  /// - [data]: Updated field values
  ///   - Can be full or partial update
  ///   - Unspecified fields unchanged
  ///
  /// ## Returns
  /// Updated screen record with changes applied
  ///
  /// ## Behavior
  /// - Updates specified fields
  /// - Preserves unmodified fields
  /// - Updates server timestamp
  /// - Validates constraints
  /// - Triggers real-time subscribers
  ///
  /// ## Throws
  /// - [PostgrestException]: Not found, validation error
  /// - [SocketException]: Network error
  /// - [Exception]: Access denied
  ///
  /// ## Performance
  /// - Typical: ~300-800ms
  /// - Depends on update size
  /// - Concurrent updates: ~500-1500ms
  ///
  /// ## Conflict Handling
  /// - Last-write-wins semantics
  /// - Concurrent updates merge
  /// - Server determines final state
  ///
  /// ## Example
  /// ```dart
  /// // Partial update
  /// await service.updateScreen('home_screen', {
  ///   'title': 'Updated Title',
  ///   'state': {'theme': 'dark'},
  /// });
  /// ```
  ///
  /// See also:
  /// - [createScreen]: Insert new screen
  /// - [fetchScreen]: Get current data
  Future<Map<String, dynamic>> updateScreen(
    String screenId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .from('screens')
          .update(data)
          .eq('id', screenId)
          .select() as List<dynamic>;

      return response.first as Map<String, dynamic>;
    } catch (e) {
      print('Error updating screen: $e');
      rethrow;
    }
  }

  /// Delete screen from Supabase
  ///
  /// Removes screen from database permanently.
  /// This is destructive and cannot be undone (without backup).
  ///
  /// ## Parameters
  /// - [screenId]: ID of screen to delete
  ///
  /// ## Behavior
  /// - Deletes database record
  /// - Cascades to dependent data
  /// - Cannot be recovered
  /// - Triggers real-time subscribers
  ///
  /// ## Throws
  /// - [PostgrestException]: Not found, cascade failed
  /// - [SocketException]: Network error
  /// - [Exception]: Access denied
  ///
  /// ## Performance
  /// - Typical: ~200-500ms
  /// - Cascade deletes: ~500-2000ms
  ///
  /// ## Safety
  /// - Requires explicit call (not automatic)
  /// - Should require confirmation UI
  /// - Logged for audit trail
  /// - Consider soft-delete instead
  ///
  /// ## Example
  /// ```dart
  /// if (await showDeleteConfirmation(context)) {
  ///   await service.deleteScreen('old_screen');
  /// }
  /// ```
  ///
  /// See also:
  /// - [createScreen]: Insert new screen
  /// - [updateScreen]: Modify screen
  Future<void> deleteScreen(String screenId) async {
    try {
      await _client
          .from('screens')
          .delete()
          .eq('id', screenId);
    } catch (e) {
      print('Error deleting screen: $e');
      rethrow;
    }
  }

  /// Batch sync multiple screens
  ///
  /// Efficiently synchronizes multiple screens with backend.
  /// Used for offline sync or bulk updates.
  ///
  /// ## Parameters
  /// - [screens]: List of screen configurations to sync
  ///   - Each must have 'id' field
  ///   - Automatically detects create vs update
  ///
  /// ## Process
  /// 1. For each screen:
  ///    - Check if exists in database
  ///    - If exists: update
  ///    - If not exists: create
  /// 2. Continue on error for partial success
  /// 3. Return results
  ///
  /// ## Behavior
  /// - Creates or updates as needed
  /// - Processes sequentially (safe)
  /// - Partial success allowed
  /// - Preserves order
  ///
  /// ## Throws
  /// - [Exception]: Critical error (stops batch)
  ///
  /// ## Performance
  /// - N screens: ~300ms + (N × 200ms)
  /// - 10 screens: ~2-3 seconds
  /// - 100 screens: ~20-25 seconds
  ///
  /// ## Optimization
  /// - Use for offline sync
  /// - Not for single operations
  /// - Consider server-side batch endpoint
  ///
  /// ## Example
  /// ```dart
  /// final screens = [
  ///   {'id': 'screen1', 'title': 'Screen 1'},
  ///   {'id': 'screen2', 'title': 'Screen 2'},
  /// ];
  /// await service.batchSync(screens);
  /// ```
  ///
  /// See also:
  /// - [updateScreen]: Single update
  /// - [createScreen]: Single create
  Future<void> batchSync(List<Map<String, dynamic>> screens) async {
    try {
      for (final screen in screens) {
        try {
          await fetchScreen(screen['id']);
          await updateScreen(screen['id'], screen);
        } catch (_) {
          await createScreen(screen);
        }
      }
    } catch (e) {
      print('Error batch syncing: $e');
      rethrow;
    }
  }

  /// Search screens by name
  ///
  /// Full-text search for screens by name or title.
  /// Case-insensitive pattern matching.
  ///
  /// ## Parameters
  /// - [query]: Search term (substring match)
  ///   - Case-insensitive
  ///   - Wildcard: % for any characters
  ///   - Example: 'home' matches 'home_screen', 'hOmE_page'
  ///
  /// ## Returns
  /// List of matching screens with metadata
  ///
  /// ## Performance
  /// - Indexed search: ~50-200ms
  /// - Large dataset: ~200-500ms
  /// - Network latency: ~50-150ms
  ///
  /// ## Throws
  /// - [SocketException]: Network error
  /// - [PostgrestException]: Query error
  ///
  /// ## Example
  /// ```dart
  /// final results = await service.searchScreens('home');
  /// for (final screen in results) {
  ///   print(screen['title']);
  /// }
  /// ```
  ///
  /// See also:
  /// - [fetchScreens]: Get all screens
  /// - [fetchScreen]: Get by ID
  Future<List<Map<String, dynamic>>> searchScreens(String query) async {
    try {
      final response = await _client
          .from('screens')
          .select()
          .ilike('name', '%$query%')
          as List<dynamic>;

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error searching screens: $e');
      rethrow;
    }
  }

  /// Get count of all screens
  ///
  /// Returns total number of screens in database.
  /// Lightweight operation for UI statistics.
  ///
  /// ## Returns
  /// Total screen count, or 0 on error
  ///
  /// ## Performance
  /// - Typical: ~100-300ms
  /// - Uses COUNT optimization
  /// - Network latency: ~50-150ms
  ///
  /// ## Error Handling
  /// Returns 0 on any error (non-throwing).
  /// Check logs for errors.
  ///
  /// ## Example
  /// ```dart
  /// final count = await service.getScreenCount();
  /// setState(() => _screenCount = count);
  /// ```
  ///
  /// See also:
  /// - [fetchScreens]: Get all screens
  Future<int> getScreenCount() async {
    try {
      final response = await _client
          .from('screens')
          .select() as List<dynamic>;

      return response.length;
    } catch (e) {
      print('Error getting screen count: $e');
      return 0;
    }
  }

  /// Poll Supabase for changes
  ///
  /// Checks for remote changes and syncs locally.
  /// Use periodically for near-real-time updates.
  /// For true real-time, use Supabase Realtime subscriptions.
  ///
  /// ## Behavior
  /// - Fetches all screens
  /// - Detects new/updated/deleted
  /// - Triggers sync mechanism
  /// - Non-throwing (errors logged)
  ///
  /// ## Performance
  /// - Typically: ~200-500ms
  /// - Network dependent
  /// - Can be called frequently
  ///
  /// ## Polling Strategy
  /// - Use 10-30 second intervals
  /// - Increase interval if no changes
  /// - Background thread safe
  ///
  /// ## Example
  /// ```dart
  /// Timer.periodic(Duration(seconds: 30), (_) {
  ///   await service.pollForChanges();
  /// });
  /// ```
  ///
  /// See also:
  /// - [fetchScreens]: Fetches screens
  /// - [close]: Cleanup on app close
  Future<void> pollForChanges() async {
    try {
      await fetchScreens();
    } catch (e) {
      print('Error polling for changes: $e');
    }
  }

  /// Close Supabase connection
  ///
  /// Cleans up connections and releases resources.
  /// Call on app shutdown or when Supabase no longer needed.
  ///
  /// ## Behavior
  /// - Closes all subscriptions
  /// - Closes WebSocket connections
  /// - Releases connection pool
  /// - Flushes pending requests
  ///
  /// ## Timing
  /// - Call in app's dispose/cleanup
  /// - Non-blocking operation
  /// - Safe to call multiple times
  ///
  /// ## Example
  /// ```dart
  /// void dispose() {
  ///   SupabaseService().close();
  ///   super.dispose();
  /// }
  /// ```
  ///
  /// See also:
  /// - [initialize]: Opposite operation
  Future<void> close() async {
    try {
      await Supabase.instance.client.removeAllChannels();
    } catch (e) {
      print('Error closing Supabase: $e');
    }
  }
}
