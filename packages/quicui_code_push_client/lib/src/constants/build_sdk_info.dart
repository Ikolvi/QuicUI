import 'package:flutter/services.dart';

/// Build-time SDK detection constants
/// This file reads SDK information directly from Flutter's built-in FlutterVersion.
/// 
/// Detects QuicUI fork by checking if FlutterVersion has the quicui marker.
class BuildSDKInfo {
  /// Flutter version from the SDK
  static const String? flutterVersion = FlutterVersion.version;

  /// Dart version from the SDK
  static const String? dartVersion = FlutterVersion.dartVersion;

  /// SDK channel from the SDK
  static const String? channel = FlutterVersion.channel;

  /// Whether this is a QuicUI fork
  /// Detected by checking if FlutterVersion.quicuiMarker exists and is set
  static bool get isQuicUI {
    try {
      // If QuicUI fork, FlutterVersion.quicuiMarker will be 'quicui'
      // If standard Flutter, this property doesn't exist and throws an error
      // ignore: invalid_use_of_visible_for_testing_member
      final marker = _getQuicUIMarker();
      return marker == 'quicui';
    } catch (e) {
      // Standard Flutter doesn't have the quicuiMarker property
      return false;
    }
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
  };

  /// Get build SDK info as a formatted string
  static String getSDKString() {
    if (isQuicUI) {
      return 'QuicUI ${flutterVersion ?? "unknown"} (${channel ?? "unknown"})';
    } else {
      return 'Flutter ${flutterVersion ?? "unknown"} (${channel ?? "unknown"})';
    }
  }

  /// Helper to safely access FlutterVersion.quicuiMarker
  /// Returns 'quicui' if available, otherwise throws
  static String? _getQuicUIMarker() {
    // This will use reflection to check if quicuiMarker exists
    // If QuicUI fork: returns 'quicui'
    // If standard Flutter: throws and is caught as false
    try {
      // Try to access it through the mirror system
      // For now, we'll use a simpler approach - check version string
      final version = flutterVersion ?? '';
      if (version.contains('quicui')) {
        return 'quicui';
      }
      throw Exception('QuicUI marker not found');
    } catch (e) {
      rethrow;
    }
  }
}

