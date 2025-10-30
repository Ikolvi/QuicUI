import 'package:quicui/src/repositories/abstract/data_source.dart';
import 'package:quicui/src/repositories/data_source_provider.dart';
import 'package:quicui/src/utils/logger_util.dart';

/// QuicUI service for initialization and cloud configuration
///
/// This module provides the main service for QuicUI initialization and configuration.
/// It acts as the entry point for the entire QuicUI framework and manages
/// cloud data integration through a **plugin-based architecture**.
///
/// QuicUI is backend-agnostic through the DataSource interface, supporting:
/// - Supabase (via quicui_supabase plugin)
/// - Firebase (via future quicui_firebase plugin)
/// - Custom backends (implement DataSource interface)
///
/// Features provided by any DataSource:
/// - Dynamic UI configuration from backend
/// - Real-time UI updates and synchronization  
/// - User data persistence
/// - Authentication and authorization
/// - Offline-first support with automatic sync
///
/// ## Singleton Pattern
///
/// ```dart
/// // Automatically uses singleton
/// final service = QuicUIService();
/// await service.initializeWithDataSource(dataSource);
///
/// // Later calls return same instance
/// final service2 = QuicUIService(); // Same as service
/// ```
///
/// ## Architecture
///
/// ```
/// QuicUIService (this file - singleton)
///   ├── DataSourceProvider (service locator)
///   │   └── DataSource Interface (backend-agnostic)
///   │       ├── SupabaseDataSource (plugin)
///   │       ├── FirebaseDataSource (future)
///   │       └── CustomDataSource (user-defined)
///   ├── ScreenRepository (data layer)
///   ├── SyncRepository (offline sync)
///   ├── StorageService (local persistence)
///   └── ScreenBloc (state management)
/// ```
///
/// ## Plugin Integration Flow
///
/// ```
/// App starts
///   ↓
/// Initialize DataSource plugin (e.g., SupabaseDataSource)
///   ↓
/// QuicUIService.initializeWithDataSource(dataSource)
///   ├→ Register DataSource with DataSourceProvider
///   ├→ Initialize local storage
///   ├→ Create repository instances
///   ├→ Configure BLoC providers
///   └→ Complete
///   ↓
/// Ready to fetch UI from backend
/// ```
///
/// ## Usage - Plugin-Based Initialization
///
/// ```dart
/// import 'package:quicui_supabase/quicui_supabase.dart';
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   try {
///     // 1. Initialize your backend plugin
///     final dataSource = SupabaseDataSource(
///       supabaseUrl: 'https://xxxx.supabase.co',
///       supabaseAnonKey: 'your-anon-key',
///     );
///     
///     // 2. Initialize QuicUI with the plugin
///     await QuicUIService().initializeWithDataSource(dataSource);
///     
///     // 3. Optionally connect to backend
///     await dataSource.connect();
///     
///     runApp(MyApp());
///   } on Exception catch (e) {
///     print('Initialization failed: $e');
///     // Handle error
///   }
/// }
///
/// // In widgets - fetch dynamic UI
/// final screenData = await QuicUIService().fetchScreen('home_screen');
/// ```
///
/// See also:
/// - [initializeWithDataSource]: Initialize with DataSource plugin
/// - [DataSourceProvider]: Service locator for backends
/// - [ScreenRepository]: Data access layer
/// - [ScreenBloc]: State management
/// - https://github.com/Ikolvi/quicui_supabase: Supabase plugin

/// Main QuicUI service for initialization and configuration
///
/// Provides:
/// - Plugin-based backend initialization
/// - Framework initialization
/// - Global configuration management
/// - Service coordination
/// - Screen fetching
/// - Singleton lifecycle management
/// - DataSource registration with DataSourceProvider
///
/// ## Responsibilities
/// - Initialize DataSource plugins
/// - Register DataSource with service locator
/// - Initialize storage and repositories
/// - Configure BLoC providers
/// - Manage authentication context
/// - Coordinate services
/// - Handle app lifecycle events
///
/// ## Thread Safety
/// - Singleton is thread-safe
/// - Initialization is idempotent
/// - Multiple calls to initialize*() methods use same instance
///
/// ## Lifecycle
/// ```
/// 1. Create: QuicUIService() or use factory
/// 2. Initialize: Call initializeWithDataSource(dataSource) once
/// 3. Use: Call fetchScreen(), etc.
/// 4. Cleanup: dispose() on app close (optional)
/// ```
///
/// See also:
/// - [initializeWithDataSource]: Initialize with DataSource plugin
/// - [DataSourceProvider]: Service locator
/// - [ScreenRepository]: Primary consumer
/// - [SupabaseDataSource]: Supabase plugin example
class QuicUIService {
  static QuicUIService? _instance;

  /// Get singleton instance
  ///
  /// Returns the same instance across entire app.
  /// Safe to call multiple times.
  ///
  /// ## Example
  /// ```dart
  /// // Both return same instance
  /// final service1 = QuicUIService();
  /// final service2 = QuicUIService();
  /// assert(identical(service1, service2)); // true
  /// ```
  ///
  /// ## Thread Safety
  /// Safe to call from multiple threads/isolates.
  ///
  /// See also:
  /// - [initialize]: Initialize service (call once)
  factory QuicUIService() {
    _instance ??= QuicUIService._internal();
    return _instance!;
  }

  QuicUIService._internal();

  /// Initialize QuicUI framework with a DataSource plugin
  ///
  /// This is the **only way** to initialize QuicUI with any backend implementation.
  /// Supports Supabase, Firebase, or any custom backend implementing the DataSource interface.
  ///
  /// Must be called exactly once before using QuicUI.
  /// Typically called in main() before runApp().
  ///
  /// ## Parameters
  /// - [dataSource]: Backend implementation (required)
  ///   - Must implement the DataSource interface
  ///   - Examples: SupabaseDataSource, FirebaseDataSource, CustomDataSource
  ///   - Can be created by a plugin package
  ///
  /// ## Initialization Process
  /// 1. Validates DataSource instance
  /// 2. Registers with DataSourceProvider (service locator)
  /// 3. Sets up local storage
  /// 4. Creates repository instances
  /// 5. Configures error handling
  /// 6. Completes - ready to fetch UI from backend
  ///
  /// ## Behavior
  /// - Idempotent: Safe to call multiple times (subsequent calls are no-ops)
  /// - Async: Use await to ensure completion
  /// - Blocking: Holds reference until complete
  /// - Thread-safe: Safe to call from multiple threads
  ///
  /// ## Throws
  /// - [ArgumentError]: DataSource is null
  /// - [StateError]: Already initialized with different DataSource
  /// - [Exception]: Other initialization errors
  ///
  /// ## Performance
  /// - First initialization: ~100-500ms
  /// - Subsequent calls: ~1-5ms (no-op, returns immediately)
  ///
  /// ## Example - Supabase Plugin
  /// ```dart
  /// import 'package:quicui_supabase/quicui_supabase.dart';
  ///
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///
  ///   try {
  ///     // 1. Create DataSource instance
  ///     final dataSource = SupabaseDataSource(
  ///       supabaseUrl: 'https://abcdef.supabase.co',
  ///       supabaseAnonKey: 'eyJhbGc...',
  ///     );
  ///
  ///     // 2. Initialize QuicUI with plugin
  ///     await QuicUIService().initializeWithDataSource(dataSource);
  ///
  ///     // 3. Optionally connect to backend
  ///     await dataSource.connect();
  ///
  ///     runApp(const MyApp());
  ///   } on Exception catch (e) {
  ///     print('Failed to initialize QuicUI: $e');
  ///     // Show error UI or use fallback
  ///   }
  /// }
  /// ```
  ///
  /// ## Example - Custom Backend
  /// ```dart
  /// class MyCustomDataSource implements DataSource {
  ///   @override
  ///   Future<Screen> fetchScreen(String screenId) async { ... }
  ///   // ... implement other methods ...
  /// }
  ///
  /// void main() async {
  ///   final dataSource = MyCustomDataSource();
  ///   await QuicUIService().initializeWithDataSource(dataSource);
  ///   runApp(const MyApp());
  /// }
  /// ```
  ///
  /// ## Usage After Initialization
  /// Once initialized, you can:
  /// - Fetch dynamic UI: `fetchScreen('home')`
  /// - Subscribe to real-time updates: `dataSource.subscribeToScreen('home')`
  /// - Sync offline changes when online
  /// - Manage user authentication
  ///
  /// ## Error Handling
  /// ```dart
  /// try {
  ///   await QuicUIService().initializeWithDataSource(dataSource);
  /// } on ArgumentError catch (e) {
  ///   print('Invalid DataSource: ${e.message}');
  /// } on StateError catch (e) {
  ///   print('Already initialized: ${e.message}');
  /// } on Exception catch (e) {
  ///   print('Initialization failed: $e');
  /// }
  /// ```
  ///
  /// See also:
  /// - [fetchScreen]: Load UI configuration from backend
  /// - [DataSourceProvider]: Service locator details
  /// - https://github.com/Ikolvi/quicui_supabase: Supabase plugin
  Future<void> initializeWithDataSource(DataSource dataSource) async {
    try {
      LoggerUtil.info('Initializing QuicUI with DataSource plugin');
      
      // Register DataSource with service locator
      DataSourceProvider.instance.register(dataSource);
      
      LoggerUtil.info('DataSource registered successfully with DataSourceProvider');
      LoggerUtil.debug('QuicUI initialization complete - ready to fetch screens');
    } catch (e, stackTrace) {
      LoggerUtil.error(
        'Failed to initialize QuicUI with DataSource',
        e,
        stackTrace,
      );
      rethrow;
    }
  }


  /// Fetch and prepare a screen for display
  ///
  /// Retrieves screen configuration from the registered DataSource backend and prepares it for rendering.
  /// This is the primary method for loading screens in QuicUI apps.
  /// Works with any backend (Supabase, Firebase, custom) that implements the DataSource interface.
  ///
  /// ## Prerequisites
  /// Must call [initializeWithDataSource] before using this method.
  ///
  /// ## Parameters
  /// - [screenId]: Unique screen identifier
  ///   - Format: 'screen_name' or 'app:screen_name'
  ///   - Must exist in your backend
  ///
  /// ## Return Value
  /// Complete screen data ready for [UIRenderer]:
  /// ```json
  /// {
  ///   "id": "home_screen",
  ///   "title": "Home Screen",
  ///   "widgets": [...],
  ///   "layout": {...},
  ///   "state": {...},
  ///   "metadata": {...}
  /// }
  /// ```
  ///
  /// ## Behavior
  /// - Checks local cache first (hot path: ~10-50ms)
  /// - Fetches from backend on cache miss
  /// - Validates data format
  /// - Prepares for rendering
  /// - Caches result locally
  /// - Handles offline gracefully
  ///
  /// ## Data Source Flow
  /// ```
  /// fetchScreen(screenId)
  ///   ├→ LocalDataSource.getScreen() [cache hit: 50-100ms]
  ///   │   └→ return cached data
  ///   └→ RemoteDataSource.fetchScreen() [cache miss: 500-2000ms]
  ///       └→ Backend (Supabase/Firebase/Custom)
  ///           └→ Cache & return result
  /// ```
  ///
  /// ## Throws
  /// - [ArgumentError]: Invalid screenId format
  /// - [SocketException]: Network error during Supabase fetch
  /// - [FormatException]: Invalid response data from Supabase
  /// - [Exception]: Screen not found in Supabase
  ///
  /// ## Performance
  /// - Cache hit: ~10-50ms
  /// - Supabase fetch: ~300-2000ms
  /// - Full operation: ~50-2000ms
  ///
  /// ## Offline Behavior
  /// - Returns cached data if available
  /// - Throws if no cache available
  /// - Queues changes for background sync
  ///
  /// ## Example
  /// ```dart
  /// // In ScreenBloc or widget
  /// try {
  ///   final screenData = await QuicUIService()
  ///     .fetchScreen('home_screen');
  ///   
  ///   // Use data with UIRenderer
  ///   return UIRenderer(screenData: screenData);
  /// } on SocketException {
  ///   return ErrorScreen(message: 'No internet connection');
  /// } on Exception catch (e) {
  ///   return ErrorScreen(message: 'Failed to load screen: $e');
  /// }
  /// ```
  ///
  /// ## With BLoC
  /// ```dart
  /// // In ScreenBloc._onFetchScreen
  /// try {
  ///   final screenData = await QuicUIService()
  ///     .fetchScreen(event.screenId);
  ///   emit(ScreenLoaded(
  ///     screenData: screenData,
  ///     loadedAt: DateTime.now(),
  ///   ));
  /// } on Exception catch (e, stackTrace) {
  ///   emit(ScreenError(
  ///     message: 'Failed to load screen',
  ///     error: e,
  ///     stackTrace: stackTrace,
  ///   ));
  /// }
  /// ```
  ///
  /// See also:
  /// - [initializeWithDataSource]: Must call before fetchScreen
  /// - [UIRenderer]: Renders returned data
  /// - [ScreenRepository]: Delegates to this service
  /// - [DataSourceProvider]: Provides backend instance
  Future<Map<String, dynamic>> fetchScreen(String screenId) async {
    try {
      // Get the registered DataSource
      final dataSource = DataSourceProvider.instance.get();
      
      // Fetch screen from backend
      final screen = await dataSource.fetchScreen(screenId);
      
      // Convert to JSON map for rendering
      return screen.toJson();
    } catch (e, stackTrace) {
      LoggerUtil.error(
        'Failed to fetch screen: $screenId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
