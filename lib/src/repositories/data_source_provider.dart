import 'package:quicui/src/repositories/abstract/data_source.dart';
import 'package:quicui/src/utils/logger_util.dart';

/// Service locator for managing DataSource instances
///
/// DataSourceProvider is a centralized registry for backend implementations.
/// It enables QuicUI to support multiple backends without tight coupling.
///
/// ## Architecture
///
/// ```
/// QuicUIService
///   ↓
/// DataSourceProvider (this file)
///   ↓ (manages)
/// DataSource Interface
///   ↓ (implemented by)
/// SupabaseDataSource, FirebaseDataSource, CustomDataSource, etc.
/// ```
///
/// ## Usage
///
/// ### Registration (during app initialization)
/// ```dart
/// final dataSource = SupabaseDataSource(...);
/// DataSourceProvider.instance.register(dataSource);
/// ```
///
/// ### Retrieval (throughout the app)
/// ```dart
/// final dataSource = DataSourceProvider.instance.get();
/// final screen = await dataSource.fetchScreen('home_screen');
/// ```
///
/// ### Validation
/// ```dart
/// if (!DataSourceProvider.instance.isRegistered) {
///   throw Exception('DataSource not registered');
/// }
/// ```
///
/// ## Best Practices
/// - Register DataSource early (in main.dart or app initialization)
/// - Validate registration before using repositories
/// - Handle unregistered state gracefully
/// - Test with mock DataSource implementations
///
/// See also:
/// - [DataSource]: Backend interface
/// - [ScreenRepository]: Consumer of DataSource
/// - [SyncRepository]: Sync coordinator

/// Exception thrown when DataSource operations fail
class DataSourceProviderException implements Exception {
  /// Error message
  final String message;

  /// Root cause (if any)
  final dynamic originalError;

  /// Stack trace (if any)
  final StackTrace? stackTrace;

  /// Creates a new DataSourceProviderException
  DataSourceProviderException({
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'DataSourceProviderException: $message';
}

/// Service locator for DataSource implementations
///
/// Provides singleton pattern for managing backend implementations.
/// Supports registration, retrieval, and validation of DataSource instances.
///
/// Thread-safe implementation ensures consistent access across app.
///
/// See also:
/// - [DataSource]: Backend interface contract
class DataSourceProvider {
  /// Singleton instance
  static final DataSourceProvider _instance = DataSourceProvider._internal();

  /// Private backend instance storage
  DataSource? _dataSource;

  /// Private constructor for singleton pattern
  DataSourceProvider._internal();

  /// Get singleton instance
  ///
  /// Returns the same instance throughout app lifetime.
  /// Use this to access the DataSource provider.
  ///
  /// Example:
  /// ```dart
  /// final provider = DataSourceProvider.instance;
  /// ```
  static DataSourceProvider get instance => _instance;

  /// Register a DataSource implementation
  ///
  /// Should be called during app initialization to set up the backend.
  /// Only one DataSource can be registered at a time.
  /// Subsequent calls will replace the previous implementation.
  ///
  /// ## Parameters
  /// - [dataSource]: Backend implementation (required)
  ///
  /// ## Validation
  /// - Logs info message on successful registration
  /// - Validates DataSource is not null
  /// - Logs warning if replacing existing DataSource
  ///
  /// ## Example
  /// ```dart
  /// void main() async {
  ///   final dataSource = SupabaseDataSource(
  ///     url: 'https://...',
  ///     anonKey: '...',
  ///   );
  ///   DataSourceProvider.instance.register(dataSource);
  ///   runApp(MyApp());
  /// }
  /// ```
  ///
  /// See also:
  /// - [get]: Retrieve registered DataSource
  /// - [isRegistered]: Check registration status
  /// - [unregister]: Clear registration
  void register(DataSource dataSource) {
    if (_dataSource != null) {
      LoggerUtil.warning(
        'DataSource already registered. Replacing existing implementation.',
      );
    }

    _dataSource = dataSource;
    LoggerUtil.info(
      'DataSource registered: ${dataSource.runtimeType}',
    );
  }

  /// Get the registered DataSource implementation
  ///
  /// Returns the currently registered DataSource.
  /// Throws exception if no DataSource is registered.
  ///
  /// ## Returns
  /// The registered DataSource instance
  ///
  /// ## Throws
  /// - [DataSourceProviderException]: If no DataSource is registered
  ///
  /// ## Example
  /// ```dart
  /// try {
  ///   final dataSource = DataSourceProvider.instance.get();
  ///   final screen = await dataSource.fetchScreen('home_screen');
  /// } on DataSourceProviderException catch (e) {
  ///   print('Error: ${e.message}');
  /// }
  /// ```
  ///
  /// See also:
  /// - [register]: Register a DataSource
  /// - [isRegistered]: Check if registered
  DataSource get() {
    if (_dataSource == null) {
      const message = 'DataSource not registered. '
          'Call DataSourceProvider.instance.register() during app initialization.';
      LoggerUtil.error(message);
      throw DataSourceProviderException(message: message);
    }

    return _dataSource!;
  }

  /// Check if a DataSource is registered
  ///
  /// Use this to validate registration before using DataSource methods.
  /// Useful for conditional initialization or error handling.
  ///
  /// ## Returns
  /// true if DataSource is registered, false otherwise
  ///
  /// ## Example
  /// ```dart
  /// if (DataSourceProvider.instance.isRegistered) {
  ///   final dataSource = DataSourceProvider.instance.get();
  ///   // Use dataSource
  /// } else {
  ///   print('DataSource not yet registered');
  /// }
  /// ```
  ///
  /// See also:
  /// - [get]: Retrieve registered DataSource
  /// - [register]: Register a DataSource
  bool get isRegistered => _dataSource != null;

  /// Unregister the current DataSource
  ///
  /// Clears the registered DataSource implementation.
  /// Useful for testing, hot reload, or app teardown.
  /// Safe to call even if no DataSource is registered.
  ///
  /// ## Logging
  /// - Logs debug message on successful unregistration
  /// - Logs warning if called when nothing was registered
  ///
  /// ## Example
  /// ```dart
  /// // In test teardown
  /// void tearDown() {
  ///   DataSourceProvider.instance.unregister();
  /// }
  /// ```
  ///
  /// See also:
  /// - [register]: Register a DataSource
  /// - [get]: Retrieve registered DataSource
  void unregister() {
    if (_dataSource == null) {
      LoggerUtil.warning('Attempted to unregister, but no DataSource was registered.');
      return;
    }

    final type = _dataSource!.runtimeType;
    _dataSource = null;
    LoggerUtil.debug('DataSource unregistered: $type');
  }

  /// Get registered DataSource or null
  ///
  /// Safe retrieval that returns null instead of throwing.
  /// Useful for optional operations or checking state.
  ///
  /// ## Returns
  /// Registered DataSource, or null if not registered
  ///
  /// ## Example
  /// ```dart
  /// final dataSource = DataSourceProvider.instance.getOrNull();
  /// if (dataSource != null) {
  ///   // Use dataSource
  /// }
  /// ```
  ///
  /// See also:
  /// - [get]: Throws if not registered
  /// - [isRegistered]: Check registration status
  DataSource? getOrNull() => _dataSource;
}
