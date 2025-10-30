import 'package:quicui/quicui.dart';

/// Abstract interface for backend data sources
///
/// All backend implementations (Supabase, Firebase, custom, etc.) must
/// implement this interface to work with QuicUI.
///
/// This ensures QuicUI core remains database-agnostic and supports
/// multiple backends through a consistent contract.
abstract class DataSource {
  // ==================== Screen Operations ====================

  /// Fetch a single screen by ID
  ///
  /// Returns the screen if found, throws [ScreenNotFoundException] if not.
  /// Throws [DataSourceException] on network or other errors.
  Future<Screen> fetchScreen(String screenId);

  /// Fetch multiple screens with pagination
  ///
  /// Parameters:
  ///   - [limit]: Number of screens to fetch (default: 20)
  ///   - [offset]: Pagination offset (default: 0)
  ///
  /// Returns paginated list of screens. Empty list if no results.
  /// Throws [DataSourceException] on errors.
  Future<List<Screen>> fetchScreens({
    int limit = 20,
    int offset = 0,
  });

  /// Save or update a screen
  ///
  /// If [screenId] exists, updates the existing screen.
  /// Otherwise, creates a new screen with the given ID.
  ///
  /// Throws [DataSourceException] on errors.
  Future<void> saveScreen(String screenId, Screen screen);

  /// Delete a screen
  ///
  /// Throws [ScreenNotFoundException] if screen doesn't exist.
  /// Throws [DataSourceException] on other errors.
  Future<void> deleteScreen(String screenId);

  // ==================== Search & Query ====================

  /// Search screens by query string
  ///
  /// Searches across screen name and other text fields.
  /// Returns list of matching screens, empty list if no matches.
  ///
  /// Throws [DataSourceException] on errors.
  Future<List<Screen>> searchScreens(String query);

  /// Get total number of screens
  ///
  /// Useful for pagination and listing total count.
  /// Throws [DataSourceException] on errors.
  Future<int> getScreenCount();

  // ==================== Sync Operations ====================

  /// Synchronize pending items with backend
  ///
  /// Called when app goes back online or user explicitly syncs.
  /// Attempts to sync all pending items (creates, updates, deletes).
  ///
  /// Returns [SyncResult] with counts and any errors.
  /// Conflicting items should be handled and returned in errors.
  ///
  /// Throws [DataSourceException] on critical errors.
  Future<SyncResult> syncData(List<SyncItem> pendingItems);

  /// Get all pending items waiting to sync
  ///
  /// These are items that were created/modified offline or failed to sync.
  /// Returns empty list if no pending items.
  ///
  /// Throws [DataSourceException] on errors.
  Future<List<SyncItem>> getPendingItems();

  /// Resolve a sync conflict
  ///
  /// Called when local and remote versions differ.
  /// Implementation should determine which version wins and return resolution.
  ///
  /// Returns [ConflictResolution] indicating chosen strategy.
  /// Throws [DataSourceException] on errors.
  Future<ConflictResolution> resolveConflict(ConflictCase conflict);

  // ==================== Connection ====================

  /// Establish connection to backend
  ///
  /// Performs any necessary initialization and validates connectivity.
  /// Should be called before using other methods.
  ///
  /// Throws [DataSourceException] if connection fails.
  Future<void> connect();

  /// Close connection to backend
  ///
  /// Cleans up resources, closes subscriptions, etc.
  /// Safe to call multiple times.
  Future<void> disconnect();

  /// Check if currently connected to backend
  ///
  /// Can be used to determine if sync operations are possible.
  /// Returns true if connected, false otherwise.
  Future<bool> isConnected();

  // ==================== Realtime (Optional) ====================

  /// Subscribe to screen changes (create/update/delete)
  ///
  /// Returns a stream of real-time events for the given screen.
  /// Implementation can use WebSockets, polling, or other mechanisms.
  ///
  /// Stream should emit events on INSERT, UPDATE, DELETE operations.
  /// Closes when [unsubscribe] is called for this screenId.
  ///
  /// Throws [DataSourceException] if subscription fails.
  Stream<RealtimeEvent<Screen>> subscribeToScreen(String screenId);

  /// Unsubscribe from screen updates
  ///
  /// Stops receiving updates for the specified screen.
  /// Safe to call even if not subscribed.
  ///
  /// Throws [DataSourceException] on errors.
  Future<void> unsubscribe(String screenId);
}
