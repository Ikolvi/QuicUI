/// Local data source


/// Local data source for database operations
class LocalDataSource {
  /// Save screen locally
  Future<void> saveScreen(String screenId, Map<String, dynamic> data) async {
    // TODO: Implement ObjectBox storage
    throw UnimplementedError('saveScreen not implemented');
  }

  /// Get screen from local storage
  Future<Map<String, dynamic>> getScreen(String screenId) async {
    // TODO: Implement ObjectBox retrieval
    throw UnimplementedError('getScreen not implemented');
  }

  /// Delete screen locally
  Future<void> deleteScreen(String screenId) async {
    // TODO: Implement ObjectBox deletion
    throw UnimplementedError('deleteScreen not implemented');
  }
}
