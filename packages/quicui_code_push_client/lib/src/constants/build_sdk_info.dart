import 'package:flutter/services.dart';

/// Build-time SDK detection constants
/// This file reads SDK information directly from Flutter's built-in FlutterVersion.
/// 
/// The QuicUI fork adds a compile-time constant:
/// - FlutterVersion.isQuicUIFork = true
/// 
/// Standard Flutter SDK:
/// - FlutterVersion.isQuicUIFork = false
/// 
/// This provides a clean, reliable way to detect the SDK at build time.
class BuildSDKInfo {
  /// Flutter version from the SDK
  static const String? flutterVersion = FlutterVersion.version;

  /// Dart version from the SDK
  static const String? dartVersion = FlutterVersion.dartVersion;

  /// SDK channel from the SDK
  static const String? channel = FlutterVersion.channel;

  /// Whether this is a QuicUI fork (build-time detection)
  /// 
  /// Checks the FlutterVersion.version string for 'quicui' marker.
  /// This is the most reliable cross-SDK detection method.
  /// 
  /// QuicUI fork: version contains ' • quicui'
  /// Standard Flutter: version does not contain 'quicui'
  static bool get isQuicUI {
    final version = flutterVersion ?? '';
    return version.contains('quicui');
  }

  /// The QuicUI marker constant
  /// Returns 'quicui' if QuicUI fork, null otherwise
  static String? get quicuiMarker {
    return isQuicUI ? 'quicui' : null;
  }

  /// SDK type detected from the Flutter SDK
  static String get sdkType {
    return isQuicUI ? 'quicui' : 'flutter';
  }

  /// Get build SDK info as a map
  static Map<String, dynamic> toMap() => {
    'sdkType': sdkType,
    'flutterVersion': flutterVersion,
    'dartVersion': dartVersion,
    'channel': channel,
    'isQuicUI': isQuicUI,
    'quicuiMarker': quicuiMarker,
  };

  /// Get build SDK info as a formatted string
  static String getSDKString() {
    if (isQuicUI) {
      return 'QuicUI ${flutterVersion ?? "unknown"} (${channel ?? "unknown"})';
    } else {
      return 'Flutter ${flutterVersion ?? "unknown"} (${channel ?? "unknown"})';
    }
  }

  /// Get detailed SDK information for debugging
  static String getDetailedInfo() {
    final buffer = StringBuffer();
    buffer.writeln('SDK Detection Info:');
    buffer.writeln('  Type: ${sdkType.toUpperCase()}');
    buffer.writeln('  Is QuicUI Fork: $isQuicUI');
    buffer.writeln('  QuicUI Marker: $quicuiMarker');
    buffer.writeln('  Flutter Version: $flutterVersion');
    buffer.writeln('  Dart Version: $dartVersion');
    buffer.writeln('  Channel: $channel');
    return buffer.toString();
  }
}

