/// Data models for QuicUI Code Push Backend
/// 
/// Represents core entities in the patch management system

// ==================== User Models ====================

/// Represents a user account
class User {
  final String id;
  final String email;
  final String name;
  final String passwordHash;
  final List<String> roles;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.passwordHash,
    this.roles = const ['user'],
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  /// Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      passwordHash: json['passwordHash'] as String,
      roles: List<String>.from(json['roles'] as List? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt'] as String) 
        : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'passwordHash': passwordHash,
    'roles': roles,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'isActive': isActive,
  };

  /// Check if user has role
  bool hasRole(String role) => roles.contains(role);
}

// ==================== App Models ====================

/// Represents a Flutter application
class App {
  final String id;
  final String userId;  // Owner
  final String name;
  final String platform;  // 'flutter', 'flutter-web', etc.
  final String? description;
  final String? bundleId;
  final String? packageName;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  App({
    required this.id,
    required this.userId,
    required this.name,
    required this.platform,
    this.description,
    this.bundleId,
    this.packageName,
    this.metadata = const {},
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from JSON
  factory App.fromJson(Map<String, dynamic> json) {
    return App(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      platform: json['platform'] as String,
      description: json['description'] as String?,
      bundleId: json['bundleId'] as String?,
      packageName: json['packageName'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'platform': platform,
    'description': description,
    'bundleId': bundleId,
    'packageName': packageName,
    'metadata': metadata,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}

// ==================== Patch Models ====================

/// Represents a code patch
class Patch {
  final String id;
  final String appId;
  final String version;
  final String? description;
  final String baseVersion;  // Kernel hash this patch is based on
  final String targetVersion; // Kernel hash after applying patch
  final int fileSize;
  final String fileHash;
  final String? signature;
  final bool critical;
  final double compressionRatio;
  final int operationCount;
  final String? cdnUrl;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;

  Patch({
    required this.id,
    required this.appId,
    required this.version,
    this.description,
    required this.baseVersion,
    required this.targetVersion,
    required this.fileSize,
    required this.fileHash,
    this.signature,
    this.critical = false,
    required this.compressionRatio,
    required this.operationCount,
    this.cdnUrl,
    required this.createdAt,
    this.expiresAt,
    this.metadata = const {},
  });

  /// Create from JSON
  factory Patch.fromJson(Map<String, dynamic> json) {
    return Patch(
      id: json['id'] as String,
      appId: json['appId'] as String,
      version: json['version'] as String,
      description: json['description'] as String?,
      baseVersion: json['baseVersion'] as String,
      targetVersion: json['targetVersion'] as String,
      fileSize: json['fileSize'] as int,
      fileHash: json['fileHash'] as String,
      signature: json['signature'] as String?,
      critical: json['critical'] as bool? ?? false,
      compressionRatio: (json['compressionRatio'] as num).toDouble(),
      operationCount: json['operationCount'] as int,
      cdnUrl: json['cdnUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
        ? DateTime.parse(json['expiresAt'] as String)
        : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'appId': appId,
    'version': version,
    'description': description,
    'baseVersion': baseVersion,
    'targetVersion': targetVersion,
    'fileSize': fileSize,
    'fileHash': fileHash,
    'signature': signature,
    'critical': critical,
    'compressionRatio': compressionRatio,
    'operationCount': operationCount,
    'cdnUrl': cdnUrl,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'metadata': metadata,
  };

  /// Check if patch is still valid
  bool isValid() {
    if (expiresAt != null && expiresAt!.isBefore(DateTime.now())) {
      return false;
    }
    return true;
  }
}

// ==================== Rollout Models ====================

/// Represents a patch rollout (deployment)
class Rollout {
  final String id;
  final String appId;
  final String patchVersion;
  final String environment;
  final double percentage;
  final RolloutStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? cancelledReason;
  final Map<String, int> metrics;  // Downloads, errors, etc.

  Rollout({
    required this.id,
    required this.appId,
    required this.patchVersion,
    required this.environment,
    required this.percentage,
    required this.status,
    required this.startedAt,
    this.completedAt,
    this.cancelledReason,
    this.metrics = const {},
  });

  /// Create from JSON
  factory Rollout.fromJson(Map<String, dynamic> json) {
    return Rollout(
      id: json['id'] as String,
      appId: json['appId'] as String,
      patchVersion: json['patchVersion'] as String,
      environment: json['environment'] as String,
      percentage: (json['percentage'] as num).toDouble(),
      status: RolloutStatus.values.firstWhere(
        (s) => s.toString() == 'RolloutStatus.${json['status']}',
      ),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'] as String)
        : null,
      cancelledReason: json['cancelledReason'] as String?,
      metrics: Map<String, int>.from(json['metrics'] as Map? ?? {}),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'appId': appId,
    'patchVersion': patchVersion,
    'environment': environment,
    'percentage': percentage,
    'status': status.name,
    'startedAt': startedAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'cancelledReason': cancelledReason,
    'metrics': metrics,
  };
}

/// Rollout status enum
enum RolloutStatus {
  pending,    // Not yet started
  active,     // Currently rolling out
  paused,     // Paused
  completed,  // Successfully completed
  cancelled,  // Cancelled by user
  failed,     // Failed
}

// ==================== Metrics Models ====================

/// Represents patch download metrics
class PatchMetrics {
  final String appId;
  final String? patchVersion;
  final int totalDownloads;
  final int successfulDownloads;
  final int failedDownloads;
  final double averageDownloadTimeMs;
  final int activeUsers;
  final double successRate;
  final Map<String, int> platformBreakdown;  // iOS, Android, Web
  final DateTime collectedAt;

  PatchMetrics({
    required this.appId,
    this.patchVersion,
    required this.totalDownloads,
    required this.successfulDownloads,
    required this.failedDownloads,
    required this.averageDownloadTimeMs,
    required this.activeUsers,
    required this.successRate,
    this.platformBreakdown = const {},
    required this.collectedAt,
  });

  /// Create from JSON
  factory PatchMetrics.fromJson(Map<String, dynamic> json) {
    return PatchMetrics(
      appId: json['appId'] as String,
      patchVersion: json['patchVersion'] as String?,
      totalDownloads: json['totalDownloads'] as int,
      successfulDownloads: json['successfulDownloads'] as int,
      failedDownloads: json['failedDownloads'] as int,
      averageDownloadTimeMs: (json['averageDownloadTimeMs'] as num).toDouble(),
      activeUsers: json['activeUsers'] as int,
      successRate: (json['successRate'] as num).toDouble(),
      platformBreakdown: Map<String, int>.from(
        json['platformBreakdown'] as Map? ?? {}
      ),
      collectedAt: DateTime.parse(json['collectedAt'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'appId': appId,
    'patchVersion': patchVersion,
    'totalDownloads': totalDownloads,
    'successfulDownloads': successfulDownloads,
    'failedDownloads': failedDownloads,
    'averageDownloadTimeMs': averageDownloadTimeMs,
    'activeUsers': activeUsers,
    'successRate': successRate,
    'platformBreakdown': platformBreakdown,
    'collectedAt': collectedAt.toIso8601String(),
  };
}

// ==================== API Response Models ====================

/// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
  });

  /// Create success response
  factory ApiResponse.success(T data, {int statusCode = 200}) {
    return ApiResponse(
      success: true,
      data: data,
      statusCode: statusCode,
    );
  }

  /// Create error response
  factory ApiResponse.error(String error, {int statusCode = 400}) {
    return ApiResponse(
      success: false,
      error: error,
      statusCode: statusCode,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'success': success,
    'data': data,
    'error': error,
    'statusCode': statusCode,
  };
}

// ==================== Pagination Models ====================

/// Pagination request parameters
class PaginationRequest {
  final int page;
  final int pageSize;
  final String? sortBy;
  final bool ascending;

  PaginationRequest({
    this.page = 1,
    this.pageSize = 20,
    this.sortBy,
    this.ascending = true,
  });

  /// Get offset for database query
  int get offset => (page - 1) * pageSize;

  /// Create from query parameters
  factory PaginationRequest.fromQuery(Map<String, String> query) {
    return PaginationRequest(
      page: int.tryParse(query['page'] ?? '') ?? 1,
      pageSize: int.tryParse(query['pageSize'] ?? '') ?? 20,
      sortBy: query['sortBy'],
      ascending: query['order'] != 'desc',
    );
  }
}

/// Pagination response wrapper
class PaginatedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasMore;

  PaginatedResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  }) : hasMore = (page * pageSize) < totalCount;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'items': items,
    'pagination': {
      'total': totalCount,
      'page': page,
      'pageSize': pageSize,
      'hasMore': hasMore,
    },
  };
}
