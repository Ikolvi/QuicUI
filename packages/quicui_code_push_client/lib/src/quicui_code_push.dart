import 'package:http/http.dart' as http;
import 'src/models/config.dart';
import 'src/models/patch_info.dart';
import 'src/services/patch_service.dart';
import 'src/services/signature_verifier.dart';
import 'src/services/storage_service.dart';

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

  @override
  String toString() => 'QuicUICodePush(appId: ${config.appId})';
}
