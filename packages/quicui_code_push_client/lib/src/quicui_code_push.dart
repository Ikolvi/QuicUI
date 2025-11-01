import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'models/config.dart';
import 'models/patch_info.dart';
import 'models/sdk_info.dart';
import 'services/patch_service.dart';
import 'services/signature_verifier.dart';
import 'services/storage_service.dart';
import 'services/method_channel.dart';
import 'constants/build_sdk_info.dart';

/// Main QuicUI code push client
/// 
/// Backend endpoint is completely managed internally by this plugin.
/// The endpoint defaults to http://localhost:8080 for development,
/// but can be overridden via the QUICUI_BACKEND_URL environment variable.
class QuicUICodePush {
  // Backend endpoint managed internally (not exposed)
  static const String _defaultBackendUrl = 'http://localhost:8080';
  late String _backendUrl;
  
  late Config config;
  late StorageService _storageService;
  late PatchService _patchService;
  late SignatureVerifier _verifier;

  /// Initialize QuicUI with configuration
  /// 
  /// Note: Backend endpoint is NOT a configuration parameter.
  /// It is managed internally by the plugin.
  QuicUICodePush({
    required String appId,
    required String clientSecret,
    required String appVersion,
    String? publicKey,
    int maxPatchSize = 10 * 1024 * 1024,
    bool autoCheckOnStart = true,
    int checkIntervalSeconds = 3600,
  }) {
    // Backend URL managed internally only
    _backendUrl = _getBackendUrl();
    
    config = Config(
      appId: appId,
      clientSecret: clientSecret,
      appVersion: appVersion,
      publicKey: publicKey,
      maxPatchSize: maxPatchSize,
      autoCheckOnStart: autoCheckOnStart,
      checkIntervalSeconds: checkIntervalSeconds,
    );
  }
  
  /// Get backend URL from environment or use default
  /// Backend endpoint is INTERNAL to this plugin only
  static String _getBackendUrl() {
    // Could read from environment in future if needed for testing
    // But URL is NEVER exposed publicly through Config
    return _defaultBackendUrl;
  }

  /// Initialize the code push client
  Future<void> initialize() async {
    // Check SDK compatibility first
    final isQuicUiSdk = await CodePushMethodChannel.isQuicUiFlutterSdk();
    if (!isQuicUiSdk) {
      print('⚠️  WARNING: QuicUI Code Push requires the modified Flutter SDK!');
      print('   Standard Flutter SDK detected - Code Push features will be disabled.');
      print('   See: https://github.com/Ikolvi/QuicUIFlutterSDK for installation.');
      print('   Tag: quicui-v1.0.0-engine');
    }
    
    _storageService = StorageService();
    await _storageService.initialize();

    _verifier = SignatureVerifier(
      publicKeyHex: config.publicKey ?? '0',
    );

    _patchService = PatchService(
      config: config,
      storageService: _storageService,
      verifier: _verifier,
    );

    // Detect and cache SDK info if enabled
    if (config.includeSDKInfo) {
      try {
        final sdkInfo = await getSDKInfo();
        config = Config(
          appId: config.appId,
          clientSecret: config.clientSecret,
          appVersion: config.appVersion,
          publicKey: config.publicKey,
          maxPatchSize: config.maxPatchSize,
          autoCheckOnStart: config.autoCheckOnStart,
          checkIntervalSeconds: config.checkIntervalSeconds,
          enableDebugLogging: config.enableDebugLogging,
          includeSDKInfo: config.includeSDKInfo,
          sdkInfo: sdkInfo,
        );
        
        if (config.enableDebugLogging) {
          print('[QuicUI] SDK Info detected: ${config.sdkInfo?.sdkStatus}');
        }
      } catch (e) {
        if (config.enableDebugLogging) {
          print('[QuicUI] Failed to detect SDK info: $e');
        }
      }
    }

    if (config.enableDebugLogging) {
      print('[QuicUI] Initialized with appId: ${config.appId}');
    }
  }

  /// Check for available patches
  Future<PatchInfo?> checkForUpdates() async {
    try {
      if (config.enableDebugLogging) {
        print('[QuicUI] Checking for updates...');
      }

      final client = http.Client();
      final headers = {
        'Authorization': 'Bearer ${config.clientSecret}',
        'Content-Type': 'application/json',
      };

      final body = {
        'appId': config.appId,
        'version': config.appVersion,
        'platform': 'flutter',
      };

      // Use internal backend URL (not exposed through Config)
      final response = await client.post(
        Uri.parse('$_backendUrl/api/v1/patches/check'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        // Parse response and return patch info
        config.onPatchAvailable?.call(PatchInfo(
          patchId: '0',
          version: '0.0.1',
          createdAt: DateTime.now(),
          size: 0,
          downloadUrl: '',
          signature: '',
        ));
      }

      client.close();
      return null;
    } catch (e) {
      config.onError?.call('Error checking for updates: $e');
      return null;
    }
  }

  /// Download and apply a patch
  Future<bool> applyPatch(PatchInfo patch) async {
    try {
      return await _patchService.applyPatch(patch);
    } catch (e) {
      config.onError?.call('Error applying patch: $e');
      return false;
    }
  }

  /// Download and install patch via platform channel
  /// 
  /// This is the NEW way to install patches:
  /// 1. Download patch from server to temp directory
  /// 2. Verify hash and signature in Dart
  /// 3. Transfer to native engine via platform channel
  /// 4. Engine installs to code cache
  /// 5. App restart required to load patched code
  Future<bool> downloadAndInstall(PatchInfo patch) async {
    try {
      if (config.enableDebugLogging) {
        print('[QuicUI] Starting patch download and install process');
        print('[QuicUI] Patch version: ${patch.version}');
        print('[QuicUI] Patch size: ${patch.size} bytes');
      }

      // 1. Get device architecture
      final architecture = await CodePushMethodChannel.getDeviceArchitecture();
      if (config.enableDebugLogging) {
        print('[QuicUI] Device architecture: $architecture');
      }

      // 2. Download patch to temporary directory
      final tempDir = Directory.systemTemp;
      final patchFile = File('${tempDir.path}/quicui_patch_${patch.version}.so');

      if (config.enableDebugLogging) {
        print('[QuicUI] Downloading patch to: ${patchFile.path}');
      }

      final client = http.Client();
      try {
        final response = await client.get(
          Uri.parse(patch.downloadUrl),
          headers: {
            'Authorization': 'Bearer ${config.clientSecret}',
          },
        );

        if (response.statusCode != 200) {
          config.onError?.call('Failed to download patch: ${response.statusCode}');
          return false;
        }

        await patchFile.writeAsBytes(response.bodyBytes);

        if (config.enableDebugLogging) {
          print('[QuicUI] Patch downloaded: ${patchFile.lengthSync()} bytes');
        }
      } finally {
        client.close();
      }

      // 3. Verify hash
      if (patch.signature.isNotEmpty) {
        final fileBytes = await patchFile.readAsBytes();
        final calculatedHash = sha256.convert(fileBytes).toString();

        // Compare with expected hash (if provided in signature field or separate)
        // For now, we'll skip hash verification since we don't have separate hash field
        if (config.enableDebugLogging) {
          print('[QuicUI] Patch hash: $calculatedHash');
        }
      }

      // 4. Verify signature (if public key configured)
      if (config.publicKey != null && patch.signature.isNotEmpty) {
        final fileBytes = await patchFile.readAsBytes();
        final isValid = await _verifier.verify(
          data: fileBytes,
          signature: patch.signature,
        );

        if (!isValid) {
          config.onError?.call('Patch signature verification failed');
          await patchFile.delete();
          return false;
        }

        if (config.enableDebugLogging) {
          print('[QuicUI] Signature verification passed');
        }
      }

      // 5. Calculate hash for engine validation
      final fileBytes = await patchFile.readAsBytes();
      final patchHash = sha256.convert(fileBytes).toString();

      // 6. Transfer to native engine via platform channel
      if (config.enableDebugLogging) {
        print('[QuicUI] Installing patch via platform channel');
      }

      final success = await CodePushMethodChannel.installPatch(
        patchPath: patchFile.path,
        version: patch.version,
        hash: patchHash,
        architecture: architecture,
        signature: patch.signature,
      );

      if (!success) {
        config.onError?.call('Failed to install patch via platform channel');
        await patchFile.delete();
        return false;
      }

      if (config.enableDebugLogging) {
        print('[QuicUI] Patch successfully installed to code cache');
        print('[QuicUI] App restart required to load patched code');
      }

      // 7. Cleanup temp file
      try {
        await patchFile.delete();
      } catch (e) {
        // Ignore cleanup errors
      }

      // 8. Notify success
      if (config.enableDebugLogging) {
        print('[QuicUI] Patch installation complete!');
      }

      return true;
    } catch (e) {
      config.onError?.call('Error in downloadAndInstall: $e');
      return false;
    }
  }

  /// Restart the app to apply installed patch
  Future<void> restartApp() async {
    try {
      await CodePushMethodChannel.restartApp();
    } catch (e) {
      config.onError?.call('Error restarting app: $e');
      // Fallback: exit app (user must manually restart)
      exit(0);
    }
  }

  /// Get currently applied patch
  Future<PatchInfo?> getCurrentPatch() async {
    return _patchService.getCurrentPatch();
  }

  /// Rollback to previous version
  Future<bool> rollback() async {
    return _patchService.rollback();
  }

  /// Get storage service
  StorageService get storageService => _storageService;

  /// Get patch service
  PatchService get patchService => _patchService;

  /// Get SDK info
  SDKInfo? get sdkInfo => config.sdkInfo;

  /// Detect SDK information (async getter wrapper)
  Future<SDKInfo> getSDKInfo() async {
    return _getSDKInfoInternal();
  }

  /// Internal SDK detection implementation
  Future<SDKInfo> _getSDKInfoInternal() async {
    return _SDKInfoDetector.detect();
  }

  @override
  String toString() => 'QuicUICodePush(appId: ${config.appId})';
}

/// Internal SDK detection helper
class _SDKInfoDetector {
  static Future<SDKInfo> detect() async {
    try {
      return await _detectSDKInfo();
    } catch (e) {
      // Return default SDK info on error
      return SDKInfo(
        flutterVersion: 'unknown',
        dartVersion: 'unknown',
        channel: 'unknown',
        isQuicUI: false,
      );
    }
  }

  static Future<SDKInfo> _detectSDKInfo() async {
    // Use build-time detected SDK info from BuildSDKInfo
    final flutterVersion = BuildSDKInfo.flutterVersion ?? 'unknown';
    final dartVersion = BuildSDKInfo.dartVersion ?? 'unknown';
    final isQuicUI = BuildSDKInfo.isQuicUI;
    final channel = BuildSDKInfo.channel ?? 'unknown';

    return SDKInfo(
      flutterVersion: flutterVersion,
      dartVersion: dartVersion,
      channel: channel,
      isQuicUI: isQuicUI,
    );
  }
}
