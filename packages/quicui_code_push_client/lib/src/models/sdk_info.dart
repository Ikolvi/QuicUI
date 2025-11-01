/// Model class for SDK information
class SDKInfo {
  /// Flutter SDK version
  final String flutterVersion;

  /// Dart SDK version
  final String dartVersion;

  /// SDK channel (e.g., "stable", "[user-branch]", "dev")
  final String channel;

  /// Whether this is the QuicUI custom SDK
  final bool isQuicUI;

  /// Git branch (if available)
  final String? branch;

  /// Git commit hash (if available)
  final String? commitHash;

  /// Version tag (e.g., "v3.35.7-quicui-0.9.0")
  final String? versionTag;

  /// Custom properties map
  final Map<String, String> customProperties;

  /// Timestamp when SDK info was collected
  final DateTime timestamp;

  /// Constructor
  SDKInfo({
    required this.flutterVersion,
    required this.dartVersion,
    required this.channel,
    required this.isQuicUI,
    this.branch,
    this.commitHash,
    this.versionTag,
    Map<String, String>? customProperties,
    DateTime? timestamp,
  })  : customProperties = customProperties ?? {},
        timestamp = timestamp ?? DateTime.now();

  /// Create SDKInfo from a JSON map
  factory SDKInfo.fromJson(Map<String, dynamic> json) {
    return SDKInfo(
      flutterVersion: json['flutterVersion'] as String? ?? 'Unknown',
      dartVersion: json['dartVersion'] as String? ?? 'Unknown',
      channel: json['channel'] as String? ?? 'unknown',
      isQuicUI: json['isQuicUI'] as bool? ?? false,
      branch: json['branch'] as String?,
      commitHash: json['commitHash'] as String?,
      versionTag: json['versionTag'] as String?,
      customProperties:
          (json['customProperties'] as Map<String, dynamic>?)
              ?.cast<String, String>() ??
          {},
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Convert SDKInfo to JSON map
  Map<String, dynamic> toJson() => {
        'flutterVersion': flutterVersion,
        'dartVersion': dartVersion,
        'channel': channel,
        'isQuicUI': isQuicUI,
        'branch': branch,
        'commitHash': commitHash,
        'versionTag': versionTag,
        'customProperties': customProperties,
        'timestamp': timestamp.toIso8601String(),
      };

  /// Get a formatted report string
  String toReport() {
    final buffer = StringBuffer();
    buffer.writeln('Flutter SDK Information:');
    buffer.writeln('├─ Version: $flutterVersion');
    buffer.writeln('├─ Channel: $channel');
    buffer.writeln('├─ Dart: $dartVersion');
    buffer.writeln('├─ QuicUI Custom: ${isQuicUI ? '✅ YES' : '❌ NO'}');

    if (branch != null) {
      buffer.writeln('├─ Branch: $branch');
    }

    if (commitHash != null) {
      buffer.writeln('├─ Commit: $commitHash');
    }

    if (versionTag != null) {
      buffer.writeln('└─ Tag: $versionTag');
    } else {
      buffer.writeln('└─ Timestamp: ${timestamp.toIso8601String()}');
    }

    return buffer.toString();
  }

  /// Get short SDK description
  String toShortString() {
    if (isQuicUI) {
      return 'QuicUI $flutterVersion ($channel)';
    }
    return 'Flutter $flutterVersion ($channel)';
  }

  /// Check if SDK info is valid
  bool isValid() {
    return flutterVersion != 'Unknown' &&
        flutterVersion != 'Error' &&
        dartVersion != 'Unknown' &&
        dartVersion != 'Error';
  }

  /// Check if SDK is a pre-release version
  bool isPreRelease() {
    return flutterVersion.contains('pre') ||
        flutterVersion.contains('beta') ||
        flutterVersion.contains('alpha') ||
        flutterVersion.contains('dev');
  }

  /// Get display string for SDK status
  String get sdkStatus {
    if (!isValid()) {
      return 'Unknown SDK';
    }

    if (isQuicUI) {
      return isPreRelease()
          ? 'QuicUI (Pre-release)'
          : 'QuicUI (Custom Fork)';
    }

    return isPreRelease() ? 'Flutter (Pre-release)' : 'Flutter (Standard)';
  }

  @override
  String toString() =>
      'SDKInfo(flutter: $flutterVersion, dart: $dartVersion, '
      'channel: $channel, quicui: $isQuicUI)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SDKInfo &&
          runtimeType == other.runtimeType &&
          flutterVersion == other.flutterVersion &&
          dartVersion == other.dartVersion &&
          channel == other.channel &&
          isQuicUI == other.isQuicUI &&
          branch == other.branch &&
          commitHash == other.commitHash &&
          versionTag == other.versionTag;

  @override
  int get hashCode =>
      flutterVersion.hashCode ^
      dartVersion.hashCode ^
      channel.hashCode ^
      isQuicUI.hashCode ^
      branch.hashCode ^
      commitHash.hashCode ^
      versionTag.hashCode;
}
