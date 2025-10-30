import 'package:equatable/equatable.dart';
import 'package:quicui/quicui.dart';

// ==================== Sync Models ====================

/// Represents a single item pending synchronization
class SyncItem extends Equatable {
  /// Unique identifier for this sync item
  final String id;

  /// The screen ID being synced
  final String screenId;

  /// The operation type (create, update, delete)
  final SyncOperation operation;

  /// The screen data (null for delete operations)
  final Screen? screen;

  /// When this item was created locally
  final DateTime createdAt;

  /// Number of failed sync attempts
  final int retryCount;

  /// Last error message (if any)
  final String? lastError;

  /// Whether this item is currently being synced
  final bool isSyncing;

  const SyncItem({
    required this.id,
    required this.screenId,
    required this.operation,
    this.screen,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
    this.isSyncing = false,
  });

  /// Create a copy with optional field updates
  SyncItem copyWith({
    String? id,
    String? screenId,
    SyncOperation? operation,
    Screen? screen,
    DateTime? createdAt,
    int? retryCount,
    String? lastError,
    bool? isSyncing,
  }) {
    return SyncItem(
      id: id ?? this.id,
      screenId: screenId ?? this.screenId,
      operation: operation ?? this.operation,
      screen: screen ?? this.screen,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'screenId': screenId,
      'operation': operation.toString().split('.').last,
      'screen': screen?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'lastError': lastError,
      'isSyncing': isSyncing,
    };
  }

  /// Create from JSON
  factory SyncItem.fromJson(Map<String, dynamic> json) {
    return SyncItem(
      id: json['id'] as String,
      screenId: json['screenId'] as String,
      operation: SyncOperation.values.firstWhere(
        (e) => e.toString().split('.').last == json['operation'],
      ),
      screen: json['screen'] != null ? Screen.fromJson(json['screen']) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      lastError: json['lastError'] as String?,
      isSyncing: json['isSyncing'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    screenId,
    operation,
    screen,
    createdAt,
    retryCount,
    lastError,
    isSyncing,
  ];
}

/// Types of sync operations
enum SyncOperation {
  create,
  update,
  delete,
}

/// Result of sync operation
class SyncResult extends Equatable {
  /// Number of items successfully synced
  final int synced;

  /// Number of items that failed to sync
  final int failed;

  /// List of specific errors for failed items
  final List<SyncError> errors;

  /// When sync completed
  final DateTime completedAt;

  SyncResult({
    required this.synced,
    required this.failed,
    required this.errors,
    DateTime? completedAt,
  }) : completedAt = completedAt ?? DateTime.now();

  @override
  List<Object?> get props => [synced, failed, errors, completedAt];
}

/// Error from a failed sync item
class SyncError extends Equatable {
  /// ID of the item that failed
  final String itemId;

  /// The operation that failed
  final SyncOperation operation;

  /// Error message
  final String error;

  /// Root cause exception (if any)
  final Object? originalException;

  const SyncError({
    required this.itemId,
    required this.operation,
    required this.error,
    this.originalException,
  });

  @override
  List<Object?> get props => [itemId, operation, error, originalException];
}

// ==================== Conflict Models ====================

/// Represents a conflict between local and remote versions
class ConflictCase extends Equatable {
  /// Unique ID for this conflict
  final String id;

  /// The screen ID with conflict
  final String screenId;

  /// Local version of the screen
  final Screen localVersion;

  /// Remote version of the screen
  final Screen remoteVersion;

  /// When the conflict was detected
  final DateTime detectedAt;

  /// Operation that caused conflict (create, update, delete)
  final SyncOperation operation;

  const ConflictCase({
    required this.id,
    required this.screenId,
    required this.localVersion,
    required this.remoteVersion,
    required this.detectedAt,
    required this.operation,
  });

  @override
  List<Object?> get props => [
    id,
    screenId,
    localVersion,
    remoteVersion,
    detectedAt,
    operation,
  ];
}

/// Resolution strategy for conflicts
enum ConflictResolution {
  /// Keep local version, overwrite remote
  useLocal,

  /// Keep remote version, overwrite local
  useRemote,

  /// Merge both versions (implementation specific)
  merge,

  /// User needs to decide manually
  requiresUserInput,

  /// Abort sync, keep both versions
  abort,
}

/// Represents a real-time event from backend
class RealtimeEvent<T> extends Equatable {
  /// Type of event (INSERT, UPDATE, DELETE)
  final EventType type;

  /// The changed data
  final T data;

  /// When the event occurred
  final DateTime timestamp;

  /// User ID who made the change (if available)
  final String? userId;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  const RealtimeEvent({
    required this.type,
    required this.data,
    required this.timestamp,
    this.userId,
    this.metadata,
  });

  @override
  List<Object?> get props => [type, data, timestamp, userId, metadata];
}

/// Types of real-time events
enum EventType {
  insert,
  update,
  delete,
}
