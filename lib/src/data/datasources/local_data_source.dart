/// Local data source implementation with ObjectBox
/// 
/// Provides local storage and retrieval operations for screens
/// Using ObjectBox for efficient offline data management

import 'dart:convert';
import '../local/objectbox_database.dart';
import '../local/screen_entity.dart';

/// Local data source for database operations
class LocalDataSource {
  final ObjectBoxDatabase _db = ObjectBoxDatabase();

  /// Save screen locally
  Future<void> saveScreen(String screenId, Map<String, dynamic> data) async {
    try {
      final screen = ScreenEntity(
        screenId: screenId,
        name: data['name'] as String? ?? 'Untitled',
        jsonData: jsonEncode(data),
      );

      final existing = _db.getScreenByScreenId(screenId);
      if (existing != null) {
        screen.id = existing.id;
      }

      await _db.putScreen(screen);
    } catch (e) {
      print('Error saving screen: $e');
      rethrow;
    }
  }

  /// Get screen from local storage
  Future<Map<String, dynamic>> getScreen(String screenId) async {
    try {
      final screen = _db.getScreenByScreenId(screenId);
      if (screen != null) {
        return jsonDecode(screen.jsonData) as Map<String, dynamic>;
      }
      throw Exception('Screen not found: $screenId');
    } catch (e) {
      print('Error retrieving screen: $e');
      rethrow;
    }
  }

  /// Get all screens from local storage
  Future<List<Map<String, dynamic>>> getAllScreens() async {
    try {
      final screens = _db.getAllScreens();
      return screens
          .map((s) => jsonDecode(s.jsonData) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error retrieving all screens: $e');
      rethrow;
    }
  }

  /// Delete screen locally
  Future<void> deleteScreen(String screenId) async {
    try {
      _db.deleteScreenByScreenId(screenId);
    } catch (e) {
      print('Error deleting screen: $e');
      rethrow;
    }
  }

  /// Delete all screens
  Future<void> deleteAllScreens() async {
    try {
      _db.clearAllScreens();
    } catch (e) {
      print('Error deleting all screens: $e');
      rethrow;
    }
  }

  /// Get screens needing synchronization
  Future<List<ScreenEntity>> getScreensNeedingSync() async {
    try {
      return _db.getScreensNeedingSync();
    } catch (e) {
      print('Error getting screens needing sync: $e');
      rethrow;
    }
  }

  /// Update sync status
  Future<void> updateSyncStatus(String screenId, String status) async {
    try {
      final screen = _db.getScreenByScreenId(screenId);
      if (screen != null) {
        if (status == 'synced') {
          screen.markAsSynced();
        } else if (status == 'failed') {
          screen.markAsFailed();
        } else if (status == 'pending') {
          screen.markAsPending();
        }
        await _db.putScreen(screen);
      }
    } catch (e) {
      print('Error updating sync status: $e');
      rethrow;
    }
  }

  /// Get recently modified screens
  Future<List<ScreenEntity>> getRecentlyModified({Duration? since}) async {
    try {
      return _db.getRecentlyModified(sinceTime: since);
    } catch (e) {
      print('Error getting recently modified screens: $e');
      rethrow;
    }
  }

  /// Get screens with conflicts
  Future<List<ScreenEntity>> getScreensWithConflicts() async {
    try {
      return _db.getScreensWithConflicts();
    } catch (e) {
      print('Error getting screens with conflicts: $e');
      rethrow;
    }
  }

  /// Mark screen as deleted
  Future<void> markAsDeleted(String screenId) async {
    try {
      final screen = _db.getScreenByScreenId(screenId);
      if (screen != null) {
        screen.isDeleted = true;
        await _db.putScreen(screen);
      }
    } catch (e) {
      print('Error marking screen as deleted: $e');
      rethrow;
    }
  }

  /// Clear old screens (offline cache cleanup)
  /// 
  /// Removes screens older than the specified duration
  Future<void> clearOldScreens({Duration? olderThan}) async {
    try {
      final cutoff = olderThan ?? Duration(days: 30);
      final timestamp = DateTime.now()
          .subtract(cutoff)
          .millisecondsSinceEpoch;

      final screens = _db.getAllScreens();
      final toDelete = screens
          .where((s) => s.lastUpdated < timestamp && s.syncStatus == 'synced')
          .map((s) => s.id)
          .toList();

      if (toDelete.isNotEmpty) {
        _db.deleteScreens(toDelete);
      }
    } catch (e) {
      print('Error clearing old screens: $e');
      rethrow;
    }
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getStats() async {
    try {
      return {
        'totalScreens': _db.countScreens(),
        'syncedScreens': _db.countByStatus('synced'),
        'pendingScreens': _db.countByStatus('pending'),
        'failedScreens': _db.countByStatus('failed'),
        'totalDataSize': _db.getTotalDataSize(),
      };
    } catch (e) {
      print('Error getting stats: $e');
      rethrow;
    }
  }
}
