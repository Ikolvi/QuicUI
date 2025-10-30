/// ObjectBox entity for Screen data storage
/// 
/// Represents a cached screen configuration stored locally for offline access
/// and efficient synchronization with the backend.

import 'package:objectbox/objectbox.dart';

@Entity()
class ScreenEntity {
  @Id()
  int id = 0;

  /// Unique identifier from backend
  @Unique()
  String screenId = '';

  /// Screen name/title
  String name = '';

  /// Screen version for change tracking
  int version = 0;

  /// Complete JSON configuration
  String jsonData = '';

  /// Last updated timestamp
  int lastUpdated = 0;

  /// Sync status: 'pending', 'synced', 'failed'
  String syncStatus = 'synced';

  /// Number of failed sync attempts
  int failedAttempts = 0;

  /// Local modification timestamp
  int localModifiedAt = 0;

  /// Whether this screen has been deleted on backend
  bool isDeleted = false;

  /// Conflict marker for sync resolution
  bool hasConflict = false;

  /// Remote version for conflict detection
  String? remoteVersion;

  /// List of related widget IDs
  final widgetIds = <String>[];

  /// Constructor
  ScreenEntity({
    required this.screenId,
    required this.name,
    required this.jsonData,
  }) {
    lastUpdated = DateTime.now().millisecondsSinceEpoch;
    localModifiedAt = lastUpdated;
  }

  /// Check if screen needs synchronization
  bool needsSync() {
    return syncStatus == 'pending' || syncStatus == 'failed';
  }

  /// Mark as synced
  void markAsSynced() {
    syncStatus = 'synced';
    failedAttempts = 0;
    lastUpdated = DateTime.now().millisecondsSinceEpoch;
  }

  /// Mark as failed
  void markAsFailed() {
    syncStatus = 'failed';
    failedAttempts++;
    lastUpdated = DateTime.now().millisecondsSinceEpoch;
  }

  /// Mark as pending
  void markAsPending() {
    syncStatus = 'pending';
    localModifiedAt = DateTime.now().millisecondsSinceEpoch;
  }

  /// Get age in seconds
  int getAgeSeconds() {
    return DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(lastUpdated),
    ).inSeconds;
  }
}
