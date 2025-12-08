import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';
import 'models/config.dart';
import 'models/patch_info.dart';
import 'models/sdk_info.dart';
import 'services/patch_service.dart';
import 'services/signature_verifier.dart';
import 'services/storage_service.dart';
import 'services/method_channel.dart';
import 'constants/build_sdk_info.dart';
import 'config/yaml_config.dart';
import 'exceptions.dart';

/// Main QuicUI code push client
/// 
/// Configuration is loaded automatically from quicui.yaml.
/// Server URL and API keys are managed internally and not exposed.
/// 
/// Usage:
/// ```dart
/// // Create client from quicui.yaml configuration
/// final client = await QuicUICodePush.create();
/// await client.initialize();
/// 
/// // Check for updates
/// final patch = await client.checkForUpdates();
/// if (patch != null) {
///   await client.downloadAndInstall(patch);
///   await client.restartApp();
/// }
/// ```
class QuicUICodePush {
  /// Backend URL (internal, not exposed)
  final String _backendUrl;
  
  /// API key (internal, not exposed)
  final String _apiKey;
  
  late Config _config;
  late StorageService _storageService;
  late PatchService _patchService;
  late SignatureVerifier _verifier;
  bool _isInitialized = false;

  /// Private constructor - use [create] factory method instead
  QuicUICodePush._({
    required String serverUrl,
    required String apiKey,
    required Config config,
  }) : _backendUrl = serverUrl,
       _apiKey = apiKey,
       _config = config;

  /// Create QuicUICodePush client from quicui.yaml configuration
  /// 
  /// This is the primary way to create a QuicUICodePush instance.
  /// Configuration is loaded automatically from quicui.yaml.
  /// 
  /// Throws [QuicUIConfigNotFoundException] if quicui.yaml is not found.
  /// Throws [QuicUIConfigInvalidException] if configuration is invalid.
  /// 
  /// Example:
  /// ```dart
  /// final client = await QuicUICodePush.create();
  /// await client.initialize();
  /// ```
  static Future<QuicUICodePush> create({String? configPath}) async {
    final yamlConfig = await QuicUIYamlConfig.load(configPath: configPath);
    
    // Validate API key
    final apiKey = yamlConfig.apiKey ?? _getApiKeyFromEnvironment();
    if (apiKey == null || apiKey.isEmpty) {
      throw QuicUIApiKeyMissingException();
    }
    
    final config = Config(
      appId: yamlConfig.appId,
      clientSecret: apiKey,
      appVersion: yamlConfig.currentVersion,
      enableDebugLogging: yamlConfig.verbose,
    );
    
    return QuicUICodePush._(
      serverUrl: yamlConfig.serverUrl,
      apiKey: apiKey,
      config: config,
    );
  }
  
  /// Get API key from environment variables
  static String? _getApiKeyFromEnvironment() {
    // Check compile-time environment
    const compileTimeKey = String.fromEnvironment('QUICUI_API_KEY');
    if (compileTimeKey.isNotEmpty) {
      return compileTimeKey;
    }
    
    // Check runtime environment
    return Platform.environment['QUICUI_API_KEY'];
  }

  /// Get the app ID
  String get appId => _config.appId;
  
  /// Get the current app version
  String get appVersion => _config.appVersion;
  
  /// Check if the client is initialized
  bool get isInitialized => _isInitialized;
  
  /// Internal config access (for services)
  Config get config => _config;

  /// Initialize the code push client
  /// 
  /// Must be called before using [checkForUpdates] or [downloadAndInstall].
  /// 
  /// Throws [QuicUISDKIncompatibleException] if running on standard Flutter SDK
  /// and strict mode is enabled.
  Future<void> initialize({bool strictMode = false}) async {
    if (_isInitialized) {
      return; // Already initialized
    }
    
    // Check SDK compatibility first
    final isQuicUiSdk = await CodePushMethodChannel.isQuicUiFlutterSdk();
    if (!isQuicUiSdk) {
      print('⚠️  WARNING: QuicUI Code Push requires the modified Flutter SDK!');
      print('   Standard Flutter SDK detected - Code Push features will be disabled.');
      print('   See: https://github.com/Ikolvi/QuicUIFlutterSDK for installation.');
      print('   Tag: quicui-v1.0.0-engine');
      
      if (strictMode) {
        throw QuicUISDKIncompatibleException();
      }
    }
    
    _storageService = StorageService();
    await _storageService.initialize();

    _verifier = SignatureVerifier(
      publicKeyHex: _config.publicKey ?? '0',
    );

    _patchService = PatchService(
      config: _config,
      storageService: _storageService,
      verifier: _verifier,
    );

    // Detect and cache SDK info if enabled
    if (_config.includeSDKInfo) {
      try {
        final sdkInfo = await getSDKInfo();
        _config = Config(
          appId: _config.appId,
          clientSecret: _config.clientSecret,
          appVersion: _config.appVersion,
          publicKey: _config.publicKey,
          maxPatchSize: _config.maxPatchSize,
          autoCheckOnStart: _config.autoCheckOnStart,
          checkIntervalSeconds: _config.checkIntervalSeconds,
          enableDebugLogging: _config.enableDebugLogging,
          includeSDKInfo: _config.includeSDKInfo,
          sdkInfo: sdkInfo,
        );
        
        if (_config.enableDebugLogging) {
          print('[QuicUI] SDK Info detected: ${_config.sdkInfo?.sdkStatus}');
        }
      } catch (e) {
        if (_config.enableDebugLogging) {
          print('[QuicUI] Failed to detect SDK info: $e');
        }
      }
    }

    _isInitialized = true;
    
    if (_config.enableDebugLogging) {
      print('[QuicUI] Initialized with appId: ${_config.appId}');
    }
  }

  /// Check for available patches
  /// 
  /// Returns [PatchInfo] if an update is available, null otherwise.
  Future<PatchInfo?> checkForUpdates() async {
    _ensureInitialized();
    
    try {
      if (_config.enableDebugLogging) {
        print('[QuicUI] Checking for updates...');
      }

      final client = http.Client();
      final headers = {
        'Authorization': 'Bearer $_apiKey',
        'apikey': _apiKey,
        'Content-Type': 'application/json',
      };

      // Detect platform and architecture
      String platform;
      String architecture;
      
      if (Platform.isAndroid) {
        platform = 'android';
        // Default to arm64-v8a (most common), could be detected via platform channel
        architecture = 'arm64-v8a';
      } else if (Platform.isIOS) {
        platform = 'ios';
        // Default to arm64 (physical devices)
        architecture = 'arm64';
      } else {
        platform = 'unknown';
        architecture = 'unknown';
      }
      
      final bodyMap = {
        'appId': _config.appId,
        'currentVersion': _config.appVersion,
        'platform': platform,
        'architecture': architecture,
        'acceptCompression': ['xz', 'gz', 'bz2'],
      };

      final requestUrl = '$_backendUrl/patches-check';
      if (_config.enableDebugLogging) {
        print('[QuicUI] POST $requestUrl');
      }

      // Use internal backend URL (not exposed through Config)
      final response = await client.post(
        Uri.parse(requestUrl),
        headers: headers,
        body: jsonEncode(bodyMap),
      );

      if (_config.enableDebugLogging) {
        print('[QuicUI] Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final patchAvailable = jsonResponse['updateAvailable'] as bool? ?? 
                                jsonResponse['patchAvailable'] as bool? ?? false;
        
        if (_config.enableDebugLogging) {
          print('[QuicUI] Patch available: $patchAvailable');
        }
        
        if (patchAvailable) {
          final patchInfo = PatchInfo(
            patchId: jsonResponse['patchId'] as String,
            version: jsonResponse['version'] as String,
            createdAt: DateTime.now(),
            size: jsonResponse['size'] as int? ?? jsonResponse['downloadSize'] as int? ?? 0,
            downloadUrl: '$_backendUrl${jsonResponse['downloadUrl'] as String}',
            signature: jsonResponse['hash'] as String,
            platform: platform,
          );
          
          if (_config.enableDebugLogging) {
            final compression = jsonResponse['compression'] as String?;
            final uncompressedSize = jsonResponse['uncompressedSize'] as int?;
            print('[QuicUI] ✅ Patch found: ${patchInfo.version} (${patchInfo.size} bytes, compression: $compression, uncompressed: $uncompressedSize bytes)');
          }
          
          _config.onPatchAvailable?.call(patchInfo);
          client.close();
          return patchInfo;
        } else {
          if (_config.enableDebugLogging) {
            print('[QuicUI] No patch available');
          }
          client.close();
          return null;
        }
      } else {
        if (_config.enableDebugLogging) {
          print('[QuicUI] ❌ Server returned error: ${response.statusCode}');
        }
        client.close();
        return null;
      }
    } catch (e, stackTrace) {
      if (_config.enableDebugLogging) {
        print('[QuicUI] ❌ Exception during checkForUpdates: $e');
        print('[QuicUI] Stack trace: $stackTrace');
      }
      _config.onError?.call('Error checking for updates: $e');
      return null;
    }
  }

  /// Download and apply a patch (deprecated, use [downloadAndInstall])
  @Deprecated('Use downloadAndInstall instead')
  Future<bool> applyPatch(PatchInfo patch) async {
    try {
      return await _patchService.applyPatch(patch);
    } catch (e) {
      _config.onError?.call('Error applying patch: $e');
      return false;
    }
  }

  /// Download and install patch via platform channel
  /// 
  /// Downloads the patch, verifies integrity, and installs to the engine.
  /// App restart is required to load the patched code.
  /// 
  /// Returns true if patch was installed successfully.
  Future<bool> downloadAndInstall(PatchInfo patch) async {
    _ensureInitialized();
    
    try {
      if (_config.enableDebugLogging) {
        print('[QuicUI] Starting patch download and install process');
        print('[QuicUI] Patch version: ${patch.version}');
        print('[QuicUI] Patch size: ${patch.size} bytes');
      }

      // 1. Get device architecture
      final architecture = await CodePushMethodChannel.getDeviceArchitecture();
      if (_config.enableDebugLogging) {
        print('[QuicUI] Device architecture: $architecture');
      }

      // 2. Download patch to temporary directory
      final tempDir = Directory.systemTemp;
      final compressedFile = File('${tempDir.path}/quicui_patch_${patch.version}.compressed');
      
      // Determine file extension based on platform
      // iOS uses .vmcode (interpreter approach)
      // Android uses .quicui (binary patch approach)
      String fileExtension = 'quicui'; // default for Android
      
      if (patch.platform == 'ios') {
        fileExtension = 'vmcode';
      } else if (patch.platform == 'android') {
        fileExtension = 'quicui';
      }
      
      final patchFile = File('${tempDir.path}/quicui_patch_${patch.version}.$fileExtension');

      final client = http.Client();
      String? compressionFormat;
      try {
        final response = await client.get(
          Uri.parse(patch.downloadUrl),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'apikey': _apiKey,
          },
        );

        if (response.statusCode != 200) {
          if (_config.enableDebugLogging) {
            print('[QuicUI] ❌ Failed to download patch: ${response.statusCode}');
          }
          _config.onError?.call('Failed to download patch: ${response.statusCode}');
          return false;
        }

        // Check if patch is compressed - first check URL query parameter
        final uri = Uri.parse(patch.downloadUrl);
        compressionFormat = uri.queryParameters['compression'];
        
        // Fallback to response headers if not in URL
        compressionFormat ??= response.headers['content-encoding'] ?? 
                              response.headers['x-compression-format'];
        
        if (_config.enableDebugLogging) {
          print('[QuicUI] Patch downloaded: ${response.bodyBytes.length} bytes');
          print('[QuicUI] Compression format: ${compressionFormat ?? "none"}');
        }

        // Write compressed data first
        await compressedFile.writeAsBytes(response.bodyBytes);

        // Decompress if needed
        if (compressionFormat != null && compressionFormat.isNotEmpty) {
          try {
            final compressedBytes = await compressedFile.readAsBytes();
            List<int>? decompressedBytes;
            
            if (compressionFormat == 'xz') {
              decompressedBytes = XZDecoder().decodeBytes(compressedBytes);
            } else if (compressionFormat == 'gz' || compressionFormat == 'gzip') {
              decompressedBytes = GZipDecoder().decodeBytes(compressedBytes);
            } else if (compressionFormat == 'bz2' || compressionFormat == 'bzip2') {
              decompressedBytes = BZip2Decoder().decodeBytes(compressedBytes);
            }

            if (decompressedBytes != null) {
              await patchFile.writeAsBytes(decompressedBytes);
              await compressedFile.delete(); // Clean up compressed file
              if (_config.enableDebugLogging) {
                print('[QuicUI] ✅ Decompression successful');
              }
            } else {
              await compressedFile.rename(patchFile.path);
            }
          } catch (e) {
            _config.onError?.call('Decompression error: $e');
            
            // Try to use compressed file as-is
            try {
              await compressedFile.rename(patchFile.path);
            } catch (renameError) {
              return false;
            }
          }
        } else {
          await compressedFile.rename(patchFile.path);
        }
      } finally {
        client.close();
      }

      // 3. Verify hash
      if (patch.signature.isNotEmpty) {
        final fileBytes = await patchFile.readAsBytes();
        final calculatedHash = sha256.convert(fileBytes).toString();

        if (_config.enableDebugLogging) {
          print('[QuicUI] Patch hash: $calculatedHash');
        }
      }

      // 4. Verify signature (if public key configured)
      if (_config.publicKey != null && patch.signature.isNotEmpty) {
        final fileBytes = await patchFile.readAsBytes();
        final isValid = await _verifier.verify(
          data: fileBytes,
          signature: patch.signature,
        );

        if (!isValid) {
          _config.onError?.call('Patch signature verification failed');
          await patchFile.delete();
          return false;
        }

        if (_config.enableDebugLogging) {
          print('[QuicUI] Signature verification passed');
        }
      }

      // 5. Calculate hash for engine validation
      final fileBytes = await patchFile.readAsBytes();
      final patchHash = sha256.convert(fileBytes).toString();

      // 6. Transfer to native engine via platform channel
      final success = await CodePushMethodChannel.installPatch(
        patchPath: patchFile.path,
        patchId: patch.patchId,
        version: patch.version,
        hash: patchHash,
        architecture: architecture,
        signature: patch.signature,
      );

      if (!success) {
        _config.onError?.call('Failed to install patch via platform channel');
        await patchFile.delete();
        return false;
      }

      if (_config.enableDebugLogging) {
        print('[QuicUI] ✅ Patch successfully installed to code cache');
        print('[QuicUI] 🔄 App restart required to load patched code');
      }

      // 7. Cleanup temp file
      try {
        await patchFile.delete();
      } catch (e) {
        // Ignore cleanup errors
      }

      // 8. Notify success
      if (_config.enableDebugLogging) {
        print('[QuicUI] Patch installation complete!');
      }

      return true;
    } catch (e) {
      _config.onError?.call('Error in downloadAndInstall: $e');
      return false;
    }
  }

  /// Restart the app to apply installed patch
  /// 
  /// This will exit the app. On most platforms, the app will restart automatically.
  Future<void> restartApp() async {
    try {
      await CodePushMethodChannel.restartApp();
    } catch (e) {
      _config.onError?.call('Error restarting app: $e');
      // Fallback: exit app (user must manually restart)
      exit(0);
    }
  }

  /// Get currently applied patch info
  Future<PatchInfo?> getCurrentPatch() async {
    _ensureInitialized();
    return _patchService.getCurrentPatch();
  }

  /// Rollback to previous version (remove applied patch)
  Future<bool> rollback() async {
    _ensureInitialized();
    return _patchService.rollback();
  }
  
  /// Ensure the client is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('QuicUICodePush not initialized. Call initialize() first.');
    }
  }

  /// Get SDK info
  SDKInfo? get sdkInfo => _config.sdkInfo;

  /// Detect SDK information
  Future<SDKInfo> getSDKInfo() async {
    return _SDKInfoDetector.detect();
  }

  @override
  String toString() => 'QuicUICodePush(appId: ${_config.appId})';
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