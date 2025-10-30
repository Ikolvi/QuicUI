/// ObjectBox database management
/// 
/// Provides a singleton instance for local storage using ObjectBox.
/// Handles database initialization, schema migration, and cleanup.

import 'package:objectbox/objectbox.dart';
import 'screen_entity.dart';

/// ObjectBox database manager singleton
class ObjectBoxDatabase {
  static late final Store _store;
  static final ObjectBoxDatabase _instance = ObjectBoxDatabase._internal();

  late final Box<ScreenEntity> _screenBox;

  factory ObjectBoxDatabase() {
    return _instance;
  }

  ObjectBoxDatabase._internal();

  /// Initialize the database with provided store
  /// 
  /// This method should be called by the main app initialization
  static void initialize(Store store) {
    _store = store;
  }

  /// Get the store instance
  static Store getStore() {
    return _store;
  }

  /// Get screen box
  Box<ScreenEntity> getScreenBox() {
    _screenBox = _store.box<ScreenEntity>();
    return _screenBox;
  }

  /// Put a screen in the database
  Future<int> putScreen(ScreenEntity screen) async {
    return _screenBox.put(screen);
  }

  /// Put multiple screens
  Future<List<int>> putScreens(List<ScreenEntity> screens) async {
    return _screenBox.putMany(screens);
  }

  /// Get screen by ID
  ScreenEntity? getScreen(int id) {
    return _screenBox.get(id);
  }

  /// Get screen by screenId
  ScreenEntity? getScreenByScreenId(String screenId) {
    final screens = getAllScreens();
    try {
      return screens.firstWhere((s) => s.screenId == screenId);
    } catch (e) {
      return null;
    }
  }

  /// Get all screens
  List<ScreenEntity> getAllScreens() {
    return _screenBox.getAll();
  }

  /// Get all screens that need syncing
  List<ScreenEntity> getScreensNeedingSync() {
    return getAllScreens()
        .where((s) => s.syncStatus != 'synced')
        .toList();
  }

  /// Get pending screens with specific status
  List<ScreenEntity> getScreensByStatus(String status) {
    return getAllScreens()
        .where((s) => s.syncStatus == status)
        .toList();
  }

  /// Get screens with conflicts
  List<ScreenEntity> getScreensWithConflicts() {
    return getAllScreens()
        .where((s) => s.hasConflict)
        .toList();
  }

  /// Get recently modified screens
  List<ScreenEntity> getRecentlyModified({Duration? sinceTime}) {
    final since = sinceTime ?? Duration(hours: 1);
    final timestamp = DateTime.now()
        .subtract(since)
        .millisecondsSinceEpoch;

    return getAllScreens()
        .where((s) => s.localModifiedAt > timestamp)
        .toList();
  }

  /// Delete screen by ID
  bool deleteScreen(int id) {
    return _screenBox.remove(id);
  }

  /// Delete screen by screenId
  bool deleteScreenByScreenId(String screenId) {
    final screen = getScreenByScreenId(screenId);
    if (screen != null) {
      return _screenBox.remove(screen.id);
    }
    return false;
  }

  /// Delete multiple screens
  void deleteScreens(List<int> ids) {
    _screenBox.removeMany(ids);
  }

  /// Clear all screens
  void clearAllScreens() {
    _screenBox.removeAll();
  }

  /// Close the database
  void close() {
    _store.close();
  }

  /// Check if database is open
  bool isOpen() {
    return _store.isClosed() == false;
  }

  /// Query count of all screens
  int countScreens() {
    return _screenBox.count();
  }

  /// Query count by status
  int countByStatus(String status) {
    return getScreensByStatus(status).length;
  }

  /// Get total size of JSON data
  int getTotalDataSize() {
    final screens = getAllScreens();
    return screens.fold<int>(
      0,
      (sum, screen) => sum + screen.jsonData.length,
    );
  }

  /// Create a backup of the database
  /// 
  /// This would typically backup to a file or cloud storage
  Future<void> backup() async {
    // TODO: Implement backup functionality
  }

  /// Restore from backup
  /// 
  /// This would typically restore from a file or cloud storage
  Future<void> restore() async {
    // TODO: Implement restore functionality
  }
}
