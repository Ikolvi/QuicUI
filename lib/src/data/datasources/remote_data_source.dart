/// Remote data source for API interactions
///
/// This module handles all remote API calls to the backend.
/// Abstracts HTTP communication and provides a clean data layer.
///
/// ## Performance
/// - Network latency: 50-500ms
/// - Processing: 10-100ms
/// - Total: 100-1000ms typical
///
/// See also:
/// - [LocalDataSource]: Local caching layer
/// - [ScreenRepository]: Primary consumer
/// - [SupabaseService]: Actual HTTP client

/// Remote data source for API calls
class RemoteDataSource {
  /// Fetch screen from remote API
  ///
  /// Retrieves complete screen configuration from backend.
  /// This always fetches fresh data (never cached at this layer).
  ///
  /// ## Performance
  /// - Network request: 100-2000ms
  /// - JSON parsing: 10-100ms
  /// - Total: 150-2100ms
  Future<Map<String, dynamic>> fetchScreen(String screenId) async {
    // TODO: Implement API call
    throw UnimplementedError('fetchScreen not implemented');
  }

  /// Upload screen data to remote API
  ///
  /// Sends updated screen configuration to backend.
  /// Used for saving changes made locally.
  Future<void> uploadScreen(String screenId, Map<String, dynamic> data) async {
    // TODO: Implement API call
    throw UnimplementedError('uploadScreen not implemented');
  }
}
