import 'dart:async';
import 'dart:io' show Platform, Process;

/// Service for detecting and reporting Flutter SDK information
class SDKInfoService {
  /// Cached SDK info to avoid repeated executions
  static Map<String, dynamic>? _cachedSDKInfo;

  /// Get Flutter SDK version
  /// 
  /// Returns the Flutter version string (e.g., "3.38.0-1.0.pre-350")
  static Future<String> getFlutterSDKVersion() async {
    try {
      // Check build-time constant first (most reliable for packaged apps)
      final buildVersion = const String.fromEnvironment(
        'QUICUI_FLUTTER_VERSION',
        defaultValue: '',
      );
      if (buildVersion.isNotEmpty && buildVersion != 'unknown') {
        return buildVersion;
      }
      
      if (Platform.isAndroid || Platform.isIOS) {
        // On mobile platforms, return version from pubspec or constants
        return _getFlutterVersionFromPubspec();
      }
      
      final result = await Process.run('flutter', ['--version']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        // Parse version from output like "Flutter 3.38.0-1.0.pre-350 • channel..."
        final match = RegExp(r'Flutter\s+([\d\.\-\w]+)').firstMatch(output);
        return match?.group(1) ?? 'Unknown';
      }
      return 'Unknown';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Get Dart SDK version
  /// 
  /// Returns the Dart version string (e.g., "3.11.0")
  static Future<String> getDartSDKVersion() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return _getDartVersionFromPubspec();
      }
      
      final result = await Process.run('dart', ['--version']);
      if (result.exitCode == 0) {
        final output = result.stderr.toString();
        // Parse version from output like "Dart SDK version: 3.11.0"
        final match = RegExp(r'(\d+\.\d+\.\d+)').firstMatch(output);
        return match?.group(1) ?? 'Unknown';
      }
      return 'Unknown';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Get Flutter SDK channel
  /// 
  /// Returns the channel name (e.g., "stable", "[user-branch]", "dev")
  static Future<String> getFlutterSDKChannel() async {
    try {
      // Check build-time constant first (most reliable for packaged apps)
      final buildChannel = const String.fromEnvironment(
        'QUICUI_SDK_CHANNEL',
        defaultValue: '',
      );
      if (buildChannel.isNotEmpty && buildChannel != 'unknown') {
        return buildChannel;
      }
      
      if (Platform.isAndroid || Platform.isIOS) {
        return 'mobile';
      }
      
      final result = await Process.run('flutter', ['--version']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        // Parse channel from output like "Flutter 3.38.0 • channel [user-branch] •"
        final match = RegExp(r'channel\s+([^\s•]+)').firstMatch(output);
        return match?.group(1) ?? 'unknown';
      }
      return 'unknown';
    } catch (e) {
      return 'error';
    }
  }

  /// Detect if using QuicUI custom Flutter SDK
  /// 
  /// Returns true if the Flutter SDK is the custom QuicUI fork
  static Future<bool> isQuicUISDK() async {
    try {
      // First check build-time constant (most reliable)
      if (const bool.fromEnvironment('QUICUI_IS_FORK', defaultValue: false)) {
        return true;
      }
      
      final channel = await getFlutterSDKChannel();
      
      // Check for QuicUI indicators
      if (channel.contains('user-branch') || 
          channel.contains('quicui') ||
          channel == '[user-branch]') {
        return true;
      }
      
      // Check version for custom markers
      final version = await getFlutterSDKVersion();
      if (version.contains('pre') || version.contains('quicui')) {
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get Git branch of Flutter SDK (if available)
  /// 
  /// Returns the Git branch name or null if not available
  static Future<String?> getSDKBranch() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return null;
      }
      
      final result = await Process.run('flutter', ['--version', '--verbose']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        // Look for branch information
        final lines = output.split('\n');
        for (final line in lines) {
          if (line.contains('quicui') || line.contains('branch')) {
            return line.trim();
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get Git commit hash of Flutter SDK (if available)
  /// 
  /// Returns the commit hash or null if not available
  static Future<String?> getSDKCommitHash() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return null;
      }
      
      final result = await Process.run('flutter', ['--version']);
      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        // Parse commit from output like "Framework • revision c1fc29fea9"
        final match = RegExp(r'revision\s+([a-f0-9]+)').firstMatch(output);
        return match?.group(1);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get SDK version tag (if available)
  /// 
  /// Returns the version tag or null if not available
  static Future<String?> getSDKVersionTag() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return null;
      }
      
      // Look for QuicUI version tag
      final isQuicUI = await isQuicUISDK();
      if (isQuicUI) {
        // Return expected tag format for QuicUI SDK
        return 'v3.35.7-quicui-0.9.0';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get all SDK information as a map
  /// 
  /// Returns a complete map of all SDK information
  static Future<Map<String, dynamic>> getFullSDKInfo() async {
    // Return cached info if available
    if (_cachedSDKInfo != null) {
      return Map.from(_cachedSDKInfo!);
    }

    final info = <String, dynamic>{
      'flutterVersion': await getFlutterSDKVersion(),
      'dartVersion': await getDartSDKVersion(),
      'channel': await getFlutterSDKChannel(),
      'isQuicUI': await isQuicUISDK(),
      'branch': await getSDKBranch(),
      'commitHash': await getSDKCommitHash(),
      'versionTag': await getSDKVersionTag(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Cache the result for 5 minutes
    _cachedSDKInfo = info;
    Future.delayed(const Duration(minutes: 5), () {
      _cachedSDKInfo = null;
    });

    return info;
  }

  /// Format SDK info as a readable report string
  /// 
  /// Returns formatted text report of SDK information
  static Future<String> getSDKReport() async {
    final info = await getFullSDKInfo();
    
    final buffer = StringBuffer();
    buffer.writeln('Flutter SDK Information:');
    buffer.writeln('├─ Version: ${info['flutterVersion']}');
    buffer.writeln('├─ Channel: ${info['channel']}');
    buffer.writeln('├─ Dart: ${info['dartVersion']}');
    buffer.writeln('├─ QuicUI Custom: ${info['isQuicUI'] ? '✅ YES' : '❌ NO'}');
    
    if (info['branch'] != null) {
      buffer.writeln('├─ Branch: ${info['branch']}');
    }
    
    if (info['commitHash'] != null) {
      buffer.writeln('├─ Commit: ${info['commitHash']}');
    }
    
    if (info['versionTag'] != null) {
      buffer.writeln('└─ Tag: ${info['versionTag']}');
    } else {
      buffer.writeln('└─ Timestamp: ${info['timestamp']}');
    }

    return buffer.toString();
  }

  /// Clear cached SDK info
  static void clearCache() {
    _cachedSDKInfo = null;
  }

  // Private helper methods

  /// Get Flutter version from pubspec.yaml (fallback for mobile)
  static String _getFlutterVersionFromPubspec() {
    try {
      // On mobile, we can't easily run flutter --version
      // Return a default that indicates mobile platform
      return 'N/A (Mobile)';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get Dart version from SDK constants (fallback for mobile)
  static String _getDartVersionFromPubspec() {
    try {
      // On mobile, we can't easily run dart --version
      // Return platform information instead
      return 'Platform: ${Platform.operatingSystem}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
