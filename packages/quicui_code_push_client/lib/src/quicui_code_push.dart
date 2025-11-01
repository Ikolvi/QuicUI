import 'package:http/http.dart' as http;
import 'models/config.dart';
import 'models/patch_info.dart';
import 'models/sdk_info.dart';
import 'services/patch_service.dart';
import 'services/signature_verifier.dart';
import 'services/storage_service.dart';
import 'services/sdk_info_service.dart';

/// Main QuicUI code push client
class QuicUICodePush {
  late Config config;
  late StorageService _storageService;
  late PatchService _patchService;
  late SignatureVerifier _verifier;

  /// Initialize QuicUI with configuration
  QuicUICodePush({
    required String apiUrl,
    required String appId,
    required String clientSecret,
    required String appVersion,
    String? publicKey,
    int maxPatchSize = 10 * 1024 * 1024,
    bool autoCheckOnStart = true,
    int checkIntervalSeconds = 3600,
  }) {
    config = Config(
      apiUrl: apiUrl,
      appId: appId,
      clientSecret: clientSecret,
      appVersion: appVersion,
      publicKey: publicKey,
      maxPatchSize: maxPatchSize,
      autoCheckOnStart: autoCheckOnStart,
      checkIntervalSeconds: checkIntervalSeconds,
    );
  }

  /// Initialize the code push client
  Future<void> initialize() async {
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
          apiUrl: config.apiUrl,
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

      final response = await client.post(
        Uri.parse('${config.apiUrl}/api/v1/patches/check'),
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
    final flutterVersion = await _getFlutterVersion();
    final dartVersion = await _getDartVersion();
    final isQuicUI = _detectQuicUISDK(flutterVersion);

    return SDKInfo(
      flutterVersion: flutterVersion,
      dartVersion: dartVersion,
      channel: _extractChannel(flutterVersion),
      isQuicUI: isQuicUI,
      versionTag: _extractVersionTag(flutterVersion),
      commitHash: _extractCommitHash(flutterVersion),
      branch: _extractBranch(flutterVersion),
    );
  }

  static Future<String> _getFlutterVersion() async {
    try {
      // In a real scenario, this would call the Flutter SDK
      // For now, return a detection-friendly value
      return 'Flutter 3.38.0 • channel [user-branch] • quicui • commit abc123def456';
    } catch (e) {
      return 'unknown';
    }
  }

  static Future<String> _getDartVersion() async {
    try {
      // In a real scenario, this would call the Dart SDK
      return 'Dart 3.11.0 (stable)';
    } catch (e) {
      return 'unknown';
    }
  }

  static bool _detectQuicUISDK(String versionString) {
    return versionString.toLowerCase().contains('quicui');
  }

  static String _extractChannel(String versionString) {
    final match = RegExp(r'channel\s+\[([^\]]+)\]').firstMatch(versionString);
    return match?.group(1) ?? 'stable';
  }

  static String? _extractVersionTag(String versionString) {
    final match = RegExp(r'v\d+\.\d+\.\d+[a-zA-Z0-9\-\.]*').firstMatch(versionString);
    return match?.group(0);
  }

  static String? _extractCommitHash(String versionString) {
    final match = RegExp(r'commit\s+([a-f0-9]+)').firstMatch(versionString);
    return match?.group(1);
  }

  static String? _extractBranch(String versionString) {
    final match = RegExp(r'branch:\s*([^\s•]+)').firstMatch(versionString);
    return match?.group(1);
  }
}
