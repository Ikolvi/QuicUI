import 'dart:io';
import 'package:flutter/services.dart';

/// Platform channel for communicating with native code push engine
class CodePushMethodChannel {
  static const MethodChannel _channel =
      MethodChannel('dev.quicui.code_push');

  /// Install a downloaded patch file to the engine code cache
  /// 
  /// This transfers the patch from Dart to the native Flutter engine,
  /// which will install it to the code cache for next app restart.
  /// 
  /// Returns true if installation succeeded, false otherwise.
  static Future<bool> installPatch({
    required String patchPath,
    required String version,
    required String hash,
    required String architecture,
    String? signature,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('installPatch', {
        'patchPath': patchPath,
        'version': version,
        'hash': hash,
        'architecture': architecture,
        'signature': signature ?? '',
      });

      return result ?? false;
    } on PlatformException catch (e) {
      print('[QuicUI] Platform channel error: ${e.message}');
      return false;
    } catch (e) {
      print('[QuicUI] Unexpected error calling installPatch: $e');
      return false;
    }
  }

  /// Check if a patch is currently installed
  static Future<bool> hasPatch() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasPatch');
      return result ?? false;
    } catch (e) {
      print('[QuicUI] Error checking for patch: $e');
      return false;
    }
  }

  /// Get the version of the currently installed patch
  static Future<String?> getInstalledPatchVersion() async {
    try {
      return await _channel.invokeMethod<String>('getInstalledPatchVersion');
    } catch (e) {
      print('[QuicUI] Error getting patch version: $e');
      return null;
    }
  }

  /// Clear the installed patch (rollback to original APK code)
  static Future<bool> clearPatch() async {
    try {
      final result = await _channel.invokeMethod<bool>('clearPatch');
      return result ?? false;
    } catch (e) {
      print('[QuicUI] Error clearing patch: $e');
      return false;
    }
  }

  /// Get the device architecture (e.g., "arm64-v8a", "armeabi-v7a")
  static Future<String> getDeviceArchitecture() async {
    try {
      final result = await _channel.invokeMethod<String>('getArchitecture');
      return result ?? _guessArchitecture();
    } catch (e) {
      print('[QuicUI] Error getting architecture: $e');
      return _guessArchitecture();
    }
  }

  /// Fallback: Guess architecture from Platform
  static String _guessArchitecture() {
    if (Platform.isAndroid) {
      // Most modern Android devices are arm64
      return 'arm64-v8a';
    } else if (Platform.isIOS) {
      return 'arm64';
    } else if (Platform.isMacOS) {
      return 'x86_64';  // or arm64 for Apple Silicon
    } else if (Platform.isLinux) {
      return 'x86_64';
    } else if (Platform.isWindows) {
      return 'x86_64';
    }
    return 'unknown';
  }

  /// Restart the app (platform-specific)
  static Future<void> restartApp() async {
    try {
      await _channel.invokeMethod('restartApp');
    } catch (e) {
      print('[QuicUI] Error restarting app: $e');
      // Fallback: Exit app (user must manually restart)
      exit(0);
    }
  }

  /// Check if the app is using QuicUI-modified Flutter SDK
  /// 
  /// Returns true if QuicUI SDK is detected, false if using standard Flutter SDK.
  /// 
  /// When false, code push features will be disabled and methods will fail with
  /// SDK_NOT_SUPPORTED errors.
  static Future<bool> isQuicUiFlutterSdk() async {
    try {
      // Try to call a QuicUI-specific method
      await _channel.invokeMethod<bool>('hasPatch');
      return true;
    } on PlatformException catch (e) {
      if (e.code == 'SDK_NOT_SUPPORTED') {
        return false;
      }
      // Other errors don't indicate SDK incompatibility
      return true;
    } catch (e) {
      // Unknown error, assume SDK is present
      return true;
    }
  }

  /// Get SDK information for debugging
  /// 
  /// Returns a map with SDK details including whether QuicUI SDK is detected,
  /// required class names, and repository information.
  static Future<Map<String, dynamic>> getSdkInfo() async {
    final isQuicUi = await isQuicUiFlutterSdk();
    return {
      'isQuicUiSdk': isQuicUi,
      'repository': 'https://github.com/Ikolvi/QuicUIFlutterSDK',
      'tag': 'quicui-v1.0.0-engine',
      'platform': Platform.operatingSystem,
    };
  }
}
