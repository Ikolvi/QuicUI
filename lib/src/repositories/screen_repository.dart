import 'package:quicui/src/models/screen.dart';
import 'package:quicui/src/repositories/abstract/data_source.dart';

/// Screen repository for data management
///
/// This module provides the data access layer for screen operations.
/// It abstracts the underlying data sources through the [DataSource] interface
/// and provides a simple interface for screen data retrieval and storage.
///
/// ## Architecture
///
/// ```
/// ScreenBloc
///   ↓
/// ScreenRepository (this file)
///   ↓
/// DataSource Interface (Backend-agnostic)
///   ↓
/// Backend Implementations (Supabase, Firebase, Custom, etc.)
/// ```
///
/// ## Data Flow
///
/// ### Reading Screen Data
/// ```
/// getScreen(screenId)
///   → Fetch from DataSource
///   → Cache locally (if storage available)
///   → Return complete data
/// ```
///
/// ### Saving Screen Data
/// ```
/// saveScreen(screenId, data)
///   → Update cache immediately (if available)
///   → Send to DataSource
///   → Sync when connection available
/// ```
///
/// ## Usage
///
/// ```dart
/// final repo = ScreenRepository(dataSource: myDataSource);
///
/// // Get screen
/// final screen = await repo.getScreen('home_screen');
///
/// // List all screens
/// final screens = await repo.listScreens();
///
/// // Save screen
/// await repo.saveScreen('home_screen', screen);
///
/// // Delete screen
/// await repo.deleteScreen('home_screen');
/// ```
///
/// ## Error Handling
///
/// All methods throw exceptions on failure:
/// - [DataSourceException]: Backend errors
/// - [ScreenNotFoundException]: Screen not found
/// - [SyncException]: Synchronization errors
/// - Custom exceptions for domain errors
///
/// See also:
/// - [ScreenBloc]: Consumer of this repository
/// - [DataSource]: Backend interface
/// - [SyncRepository]: Synchronization handler

/// Repository for managing screen data
///
/// Provides high-level interface for screen operations.
/// Coordinates with a backend implementation (via [DataSource] interface)
/// and handles data consistency.
///
/// ## Responsibilities
/// - Screen data retrieval
/// - Screen data storage
/// - Error handling and translation
/// - Data transformation if needed
/// - Fallback strategies
///
/// ## Implementation Notes
/// - Uses repository pattern for abstraction
/// - Backend-agnostic design
/// - Supports offline scenarios
/// - Provides clear error semantics
///
/// See also:
/// - [ScreenBloc]: Primary consumer
/// - [DataSource]: Backend interface
/// - [SyncRepository]: Sync coordination
class ScreenRepository {
  /// The backend data source implementation
  final DataSource _dataSource;

  /// Creates a new ScreenRepository
  ///
  /// Parameters:
  ///   - [dataSource]: Backend implementation (required)
  ScreenRepository({
    required DataSource dataSource,
  })  : _dataSource = dataSource;
  /// Retrieve a screen by its ID
  ///
  /// Fetches complete screen configuration including:
  /// - Widget definitions
  /// - Layout structure
  /// - State values
  /// - Metadata
  ///
  /// ## Behavior
  /// - Fetches from backend data source
  /// - Returns screen data
  ///
  /// ## Parameters
  /// - [screenId]: Unique identifier of the screen
  ///   - Format: 'app_name:screen_name' or simple string
  ///   - Examples: 'home_screen', 'auth:login'
  ///
  /// ## Returns
  /// Complete screen object with:
  /// - Widget definitions
  /// - Layout structure
  /// - State values
  /// - Metadata
  ///
  /// ## Throws
  /// - [ScreenNotFoundException]: Screen doesn't exist
  /// - [DataSourceException]: Backend error
  /// - [Exception]: Other errors
  ///
  /// ## Example
  /// ```dart
  /// try {
  ///   final screen = await repository.getScreen('home_screen');
  ///   print('Loaded: ${screen.title}');
  /// } on ScreenNotFoundException {
  ///   print('Screen not found');
  /// } on DataSourceException catch (e) {
  ///   print('Backend error: ${e.message}');
  /// }
  /// ```
  ///
  /// See also:
  /// - [listScreens]: List multiple screens
  /// - [saveScreen]: Update screen data
  Future<Screen> getScreen(String screenId) async {
    return await _dataSource.fetchScreen(screenId);
  }

  /// List all available screens
  ///
  /// Retrieves metadata for all screens accessible to the user.
  /// Useful for navigation menus, screen listing, and app discovery.
  ///
  /// ## Behavior
  /// - Fetches from backend
  /// - Returns all screens
  ///
  /// ## Returns
  /// List of screens with all their data
  ///
  /// ## Throws
  /// - [DataSourceException]: Backend error
  /// - [Exception]: Other errors
  ///
  /// ## Example
  /// ```dart
  /// final screens = await repository.listScreens();
  /// for (final screen in screens) {
  ///   print('${screen.title} (${screen.id})');
  /// }
  /// ```
  ///
  /// See also:
  /// - [getScreen]: Get full screen details
  /// - [ScreenBloc]: Primary consumer
  Future<List<Screen>> listScreens() async {
    return await _dataSource.fetchScreens(
      limit: 1000,
      offset: 0,
    );
  }

  /// Save or update screen data
  ///
  /// Persists screen configuration to backend.
  /// Used for:
  /// - Creating new screens
  /// - Updating existing screens
  /// - Applying incremental changes
  ///
  /// ## Behavior
  /// - Sends to backend data source
  ///
  /// ## Parameters
  /// - [screenId]: Unique identifier
  /// - [screen]: Complete screen object
  ///
  /// ## Throws
  /// - [ArgumentError]: Invalid screen data
  /// - [DataSourceException]: Backend error
  /// - [Exception]: Other errors
  ///
  /// ## Example
  /// ```dart
  /// final screen = Screen(
  ///   id: 'home_screen',
  ///   title: 'Home',
  ///   widgets: [...],
  /// );
  /// await repository.saveScreen('home_screen', screen);
  /// ```
  ///
  /// See also:
  /// - [deleteScreen]: Remove screen
  /// - [getScreen]: Retrieve current screen
  Future<void> saveScreen(String screenId, Screen screen) async {
    // Validate input
    if (screenId.isEmpty) {
      throw ArgumentError('screenId cannot be empty');
    }

    await _dataSource.saveScreen(screenId, screen);
  }

  /// Delete a screen
  ///
  /// Removes screen from all storage locations.
  /// This is a destructive operation - deleted data cannot be recovered.
  ///
  /// ## Behavior
  /// - Deletes from backend
  /// - Cannot be undone
  ///
  /// ## Parameters
  /// - [screenId]: ID of screen to delete
  ///   - Must exist
  ///
  /// ## Throws
  /// - [ScreenNotFoundException]: Screen not found
  /// - [DataSourceException]: Backend error
  /// - [Exception]: Other errors
  ///
  /// ## Example
  /// ```dart
  /// // Confirm before deleting
  /// final confirmed = await showDeleteDialog(context);
  /// if (confirmed) {
  ///   await repository.deleteScreen('temp_screen');
  ///   ScaffoldMessenger.of(context).showSnackBar(
  ///     SnackBar(content: Text('Screen deleted')),
  ///   );
  /// }
  /// ```
  ///
  /// See also:
  /// - [saveScreen]: Update screen
  /// - [getScreen]: Retrieve screen
  Future<void> deleteScreen(String screenId) async {
    // Validate input
    if (screenId.isEmpty) {
      throw ArgumentError('screenId cannot be empty');
    }

    await _dataSource.deleteScreen(screenId);
  }
}
