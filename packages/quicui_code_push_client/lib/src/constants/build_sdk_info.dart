/// Build-time SDK detection constants
/// This file is generated at build time to capture SDK information
class BuildSDKInfo {
  /// SDK type detected at build time
  static String get sdkType => const String.fromEnvironment(
    'QUICUI_SDK_TYPE',
    defaultValue: 'unknown',
  );

  /// Flutter version detected at build time
  static String get flutterVersion => const String.fromEnvironment(
    'QUICUI_FLUTTER_VERSION',
    defaultValue: 'unknown',
  );

  /// Dart version detected at build time
  static String get dartVersion => const String.fromEnvironment(
    'QUICUI_DART_VERSION',
    defaultValue: 'unknown',
  );

  /// SDK channel detected at build time
  static String get channel => const String.fromEnvironment(
    'QUICUI_SDK_CHANNEL',
    defaultValue: 'unknown',
  );

  /// Whether this is a QuicUI fork
  static bool get isQuicUI => const bool.fromEnvironment(
    'QUICUI_IS_FORK',
    defaultValue: false,
  );

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
      return 'QuicUI $flutterVersion ($channel)';
    } else {
      return 'Flutter $flutterVersion ($channel)';
    }
  }
}
