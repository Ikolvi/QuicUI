/// Screen data model for QuicUI
///
/// This model represents a complete screen definition that can be:
/// - Loaded from a JSON configuration
/// - Rendered by the UIRenderer
/// - Synchronized with a backend service
/// - Cached locally for offline access
///
/// See also:
/// - [WidgetData]: Individual widget configuration
/// - [UIRenderer]: For rendering screens to Flutter widgets
/// - [ScreenRepository]: For loading screens from different sources

import 'package:equatable/equatable.dart';
import 'widget_data.dart';

/// Represents a screen that can be rendered dynamically from JSON.
///
/// A Screen contains the complete definition needed to render a UI:
/// - [rootWidget]: The top-level widget (usually a layout widget like Column or Row)
/// - [metadata]: Additional screen information
/// - [config]: Screen-level configuration (theme, state, etc.)
///
/// ## Example
/// ```dart
/// const screen = Screen(
///   id: 'home_screen',
///   name: 'Home Screen',
///   version: 1,
///   rootWidget: WidgetData(...),
///   metadata: ScreenMetadata(...),
///   createdAt: DateTime.now(),
///   updatedAt: DateTime.now(),
///   isActive: true,
///   config: ScreenConfig(...),
/// );
///
/// // Render to Flutter widget
/// final renderer = UIRenderer();
/// final widget = renderer.renderScreen(screen);
/// ```
///
/// ## JSON Serialization
///
/// Screens can be created from JSON:
/// ```dart
/// final json = {
///   'id': 'home_screen',
///   'name': 'Home',
///   'version': 1,
///   'rootWidget': {...},
///   'metadata': {...},
///   'createdAt': '2024-10-30T10:00:00Z',
///   'updatedAt': '2024-10-30T10:00:00Z',
///   'isActive': true,
///   'config': {...},
/// };
/// final screen = Screen.fromJson(json);
/// ```
///
/// ## State Management
///
/// Screen state is managed through [ScreenBloc]:
/// ```dart
/// context.read<ScreenBloc>().add(
///   LoadScreenEvent(screenId: 'home_screen'),
/// );
/// ```
class Screen extends Equatable {
  /// Unique identifier for the screen
  ///
  /// Used to reference the screen in the backend and for caching.
  /// Should be unique across all screens in the application.
  final String id;

  /// Human-readable name of the screen
  ///
  /// Used for display purposes and logging.
  final String name;

  /// Version number of the screen definition
  ///
  /// Helps track changes and invalidate caches.
  /// Incremented when the screen definition changes.
  final int version;

  /// Root widget of the screen
  ///
  /// The top-level widget that will be rendered. Usually:
  /// - [Scaffold] for app screens
  /// - [Column] or [Row] for layout screens
  /// - [ListView] for scrollable screens
  ///
  /// See [WidgetData] for available widget types.
  final WidgetData rootWidget;

  /// Screen metadata
  ///
  /// Additional information about the screen:
  /// - Descriptive tags
  /// - Author information
  /// - Changelog entries
  /// - Custom metadata
  final ScreenMetadata? metadata;

  /// Creation timestamp
  ///
  /// When this screen definition was created.
  final DateTime createdAt;

  /// Last update timestamp
  ///
  /// When this screen definition was last modified.
  /// Used to detect if cached version is stale.
  final DateTime updatedAt;

  /// Whether screen is active
  ///
  /// Inactive screens can be filtered out during loading.
  /// Useful for gradually rolling out new screens.
  final bool isActive;

  /// Screen configuration
  ///
  /// Contains:
  /// - Initial state bindings
  /// - Theme configuration
  /// - Action handlers
  /// - API endpoints
  ///
  /// See [ScreenConfig] for details.
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
