/// Screen data model for QuicUI
import 'package:equatable/equatable.dart';
import 'widget_data.dart';

/// Represents a screen that can be rendered dynamically from JSON
class Screen extends Equatable {
  /// Unique identifier for the screen
  final String id;

  /// Human-readable name of the screen
  final String name;

  /// Version of the screen
  final int version;

  /// Root widget of the screen
  final WidgetData rootWidget;

  /// Screen metadata
  final ScreenMetadata? metadata;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime updatedAt;

  /// Whether screen is active
  final bool isActive;

  /// Screen configuration
  final ScreenConfig config;

  const Screen({
    required this.id,
    required this.name,
    required this.version,
    required this.rootWidget,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.config,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    version,
    rootWidget,
    metadata,
    createdAt,
    updatedAt,
    isActive,
    config,
  ];

  /// Manual JSON deserialization
  factory Screen.fromJson(Map<String, dynamic> json) {
    return Screen(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as int? ?? 1,
      rootWidget: WidgetData.fromJson(json['rootWidget'] as Map<String, dynamic>),
      metadata: json['metadata'] != null ? ScreenMetadata.fromJson(json['metadata'] as Map<String, dynamic>) : null,
      createdAt: json['createdAt'] is String ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] is String ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
      config: json['config'] != null ? ScreenConfig.fromJson(json['config'] as Map<String, dynamic>) : const ScreenConfig(),
    );
  }

  /// Manual JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'rootWidget': rootWidget.toJson(),
    'metadata': metadata?.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isActive': isActive,
    'config': config.toJson(),
  };

  /// Creates a copy of this screen with modified fields
  Screen copyWith({
    String? id,
    String? name,
    int? version,
    WidgetData? rootWidget,
    ScreenMetadata? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    ScreenConfig? config,
  }) {
    return Screen(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      rootWidget: rootWidget ?? this.rootWidget,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      config: config ?? this.config,
    );
  }
}

/// Metadata associated with a screen
class ScreenMetadata extends Equatable {
  /// Screen description
  final String? description;

  /// Screen category
  final String? category;

  /// Tags for organization
  final List<String> tags;

  /// Custom metadata
  final Map<String, dynamic>? customData;

  const ScreenMetadata({
    this.description,
    this.category,
    this.tags = const [],
    this.customData,
  });

  @override
  List<Object?> get props => [description, category, tags, customData];

  factory ScreenMetadata.fromJson(Map<String, dynamic> json) {
    return ScreenMetadata(
      description: json['description'] as String?,
      category: json['category'] as String?,
      tags: List<String>.from(json['tags'] as List<dynamic>? ?? []),
      customData: json['customData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'description': description,
    'category': category,
    'tags': tags,
    'customData': customData,
  };
}

/// Screen configuration
class ScreenConfig extends Equatable {
  /// Whether screen requires authentication
  final bool requiresAuth;

  /// Cache duration in seconds
  final int cacheDurationSeconds;

  /// Whether to enable offline support
  final bool enableOfflineSupport;

  /// Timeout for loading in seconds
  final int loadTimeoutSeconds;

  /// Theme to apply
  final String? themeId;

  /// Refresh interval in seconds (null = no auto-refresh)
  final int? autoRefreshSeconds;

  const ScreenConfig({
    this.requiresAuth = false,
    this.cacheDurationSeconds = 3600,
    this.enableOfflineSupport = true,
    this.loadTimeoutSeconds = 30,
    this.themeId,
    this.autoRefreshSeconds,
  });

  @override
  List<Object?> get props => [
    requiresAuth,
    cacheDurationSeconds,
    enableOfflineSupport,
    loadTimeoutSeconds,
    themeId,
    autoRefreshSeconds,
  ];

  factory ScreenConfig.fromJson(Map<String, dynamic> json) {
    return ScreenConfig(
      requiresAuth: json['requiresAuth'] as bool? ?? false,
      cacheDurationSeconds: json['cacheDurationSeconds'] as int? ?? 3600,
      enableOfflineSupport: json['enableOfflineSupport'] as bool? ?? true,
      loadTimeoutSeconds: json['loadTimeoutSeconds'] as int? ?? 30,
      themeId: json['themeId'] as String?,
      autoRefreshSeconds: json['autoRefreshSeconds'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'requiresAuth': requiresAuth,
    'cacheDurationSeconds': cacheDurationSeconds,
    'enableOfflineSupport': enableOfflineSupport,
    'loadTimeoutSeconds': loadTimeoutSeconds,
    'themeId': themeId,
    'autoRefreshSeconds': autoRefreshSeconds,
  };
}
