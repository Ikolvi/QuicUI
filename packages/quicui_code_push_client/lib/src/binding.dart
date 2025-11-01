// Copyright 2024 QuicUI Contributors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/services.dart';

/// Configuration for the QuicUI Code Push service
class CodePushConfig {
  const CodePushConfig({
    required this.serviceUrl,
    required this.appId,
    required this.appVersion,
    this.enabled = true,
    this.autoCheckInterval = const Duration(hours: 1),
    this.autoLoadCritical = true,
  });

  /// URL of the QuicUI Code Push service
  final String serviceUrl;

  /// Application ID for identifying the app
  final String appId;

  /// Current application version
  final String appVersion;

  /// Enable/disable code push functionality
  final bool enabled;

  /// How often to check for patches (default: 1 hour)
  final Duration autoCheckInterval;

  /// Whether to auto-load critical patches
  final bool autoLoadCritical;
}

/// Patch metadata received from service
class CodePushPatchInfo {
  const CodePushPatchInfo({
    required this.version,
    required this.platform,
    required this.patchHash,
    required this.patchSize,
    required this.signature,
    required this.critical,
    required this.releaseDate,
  });

  /// Semantic version of the patch
  final String version;

  /// Platform this patch is for (android, ios, web)
  final String platform;

  /// SHA256 hash of the patch for verification
  final String patchHash;

  /// Size of the patch in bytes
  final int patchSize;

  /// Ed25519 signature of the patch
  final String signature;

  /// Whether this patch should be auto-loaded immediately
  final bool critical;

  /// When the patch was released
  final DateTime releaseDate;

  factory CodePushPatchInfo.fromMap(Map<dynamic, dynamic> map) {
    return CodePushPatchInfo(
      version: map['version'] as String,
      platform: map['platform'] as String,
      patchHash: map['patchHash'] as String,
      patchSize: map['patchSize'] as int,
      signature: map['signature'] as String,
      critical: map['critical'] as bool? ?? false,
      releaseDate: DateTime.parse(map['releaseDate'] as String),
    );
  }
}

/// Result of a patch operation
class PatchResult {
  const PatchResult({
    required this.success,
    required this.message,
    this.patchVersion,
  });

  /// Whether the operation succeeded
  final bool success;

  /// Human-readable result message
  final String message;

  /// Version of the loaded patch (if successful)
  final String? patchVersion;

  factory PatchResult.fromMap(Map<dynamic, dynamic> map) {
    return PatchResult(
      success: map['success'] as bool,
      message: map['message'] as String,
      patchVersion: map['patchVersion'] as String?,
    );
  }
}

/// QuicUI Code Push binding for integrating into Flutter framework
class CodePushBinding {
  static const platform = MethodChannel('com.quicui/codepush');
  static CodePushConfig? _config;
  static Timer? _autoCheckTimer;

  /// Initialize code push with configuration
  static Future<bool> initialize(CodePushConfig config) async {
    _config = config;

    if (!config.enabled) {
      return false;
    }

    try {
      final result = await platform.invokeMethod<bool>('initCodePush', {
        'serviceUrl': config.serviceUrl,
        'appId': config.appId,
        'appVersion': config.appVersion,
      });

      if (result ?? false) {
        // Start auto-checking if configured
        if (config.autoCheckInterval.inMilliseconds > 0) {
          _startAutoChecking(config.autoCheckInterval);
        }
      }

      return result ?? false;
    } on PlatformException catch (e) {
      print('Failed to initialize code push: ${e.message}');
      return false;
    }
  }

  /// Check for available patches from the service
  static Future<CodePushPatchInfo?> checkForPatches() async {
    if (_config == null) {
      print('Code push not initialized');
      return null;
    }

    try {
      final result = await platform.invokeMethod<Map<dynamic, dynamic>?>(
        'checkPatch',
        {},
      );

      if (result != null) {
        return CodePushPatchInfo.fromMap(result);
      }
      return null;
    } on PlatformException catch (e) {
      print('Failed to check for patches: ${e.message}');
      return null;
    }
  }

  /// Load a specific patch by version
  static Future<PatchResult> loadPatch(String version) async {
    if (_config == null) {
      return PatchResult(
        success: false,
        message: 'Code push not initialized',
      );
    }

    try {
      final result = await platform.invokeMethod<Map<dynamic, dynamic>>(
        'loadPatch',
        {'version': version},
      );

      if (result != null) {
        return PatchResult.fromMap(result);
      }

      return PatchResult(
        success: false,
        message: 'Unknown error loading patch',
      );
    } on PlatformException catch (e) {
      return PatchResult(
        success: false,
        message: e.message ?? 'Platform exception',
      );
    }
  }

  /// Disable code push and stop checking
  static Future<void> disable() async {
    _stopAutoChecking();
    _config = null;

    try {
      await platform.invokeMethod('disableCodePush');
    } on PlatformException catch (e) {
      print('Failed to disable code push: ${e.message}');
    }
  }

  /// Get the currently loaded patch version
  static Future<String?> getLoadedPatchVersion() async {
    try {
      final result = await platform.invokeMethod<String?>(
        'getLoadedPatchVersion',
      );
      return result;
    } on PlatformException catch (e) {
      print('Failed to get loaded patch version: ${e.message}');
      return null;
    }
  }

  /// Start automatic patch checking at specified interval
  static void _startAutoChecking(Duration interval) {
    _stopAutoChecking();

    _autoCheckTimer = Timer.periodic(interval, (_) async {
      final patch = await checkForPatches();
      if (patch != null) {
        print('Found patch: ${patch.version}');

        // Auto-load critical patches
        if (patch.critical && _config!.autoLoadCritical) {
          await loadPatch(patch.version);
        }
      }
    });
  }

  /// Stop automatic patch checking
  static void _stopAutoChecking() {
    _autoCheckTimer?.cancel();
    _autoCheckTimer = null;
  }
}

/// Services binding extension for code push integration
/// Add this to the main flutter framework's services binding
class CodePushServicesBinding {
  /// Initialize code push in the Flutter framework
  /// Call this from ServicesBinding.ensureInitialized() or equivalent
  static Future<void> initializeCodePush({
    String? serviceUrl,
    String? appId,
    String? appVersion,
    bool enabled = true,
  }) async {
    // Use provided config or try to load from environment/assets
    final config = CodePushConfig(
      serviceUrl: serviceUrl ?? 'https://api.quicui.com',
      appId: appId ?? 'com.example.app',
      appVersion: appVersion ?? '1.0.0',
      enabled: enabled,
    );

    await CodePushBinding.initialize(config);
  }
}
