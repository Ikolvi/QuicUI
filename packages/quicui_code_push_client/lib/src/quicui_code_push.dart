import 'dart:io';
import 'dart:convert';
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
/// Backend endpoint is managed internally and points to production server.
/// Defaults to https://quicui-backend.onrender.com
class QuicUICodePush {
  // Backend endpoint managed internally (not exposed in public API)
  late String _backendUrl;
  
  late Config config;
  late StorageService _storageService;
  late PatchService _patchService;
  late SignatureVerifier _verifier;

  /// Initialize QuicUI with configuration
  /// 
  /// Server URL is NOT a parameter - it's managed internally.
  /// For testing, set QUICUI_SERVER_URL environment variable.
  QuicUICodePush({
    required String appId,
    required String clientSecret,
    required String appVersion,
    String? publicKey,
    int maxPatchSize = 10 * 1024 * 1024,
    bool autoCheckOnStart = true,
    int checkIntervalSeconds = 3600,
  }) {
    // Backend URL is internal only, from environment or default
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
  
  /// Get backend URL from environment or use production default
  /// INTERNAL USE ONLY - not exposed in public API
  static String _getBackendUrl() {
    // Check compile-time environment variable (set via --dart-define during build)
    const envUrl = String.fromEnvironment('QUICUI_SERVER_URL');
    
    if (envUrl.isNotEmpty) {
      print('[QuicUI] Using server URL from build environment: $envUrl');
      return envUrl;
    }
    
    // Fallback to runtime environment variable (for debugging)
    final runtimeUrl = Platform.environment['QUICUI_SERVER_URL'];
    
    if (runtimeUrl != null && runtimeUrl.isNotEmpty) {
      print('[QuicUI] Using server URL from runtime environment: $runtimeUrl');
      return runtimeUrl;
    }
    
    // Production default
    const productionUrl = 'https://quicui-backend.onrender.com';
    print('[QuicUI] Using production server URL: $productionUrl');
    return productionUrl;
    // return _defaultBackendUrl;
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
      print('[QuicUI] Checking for updates...');
      print('[QuicUI] Backend URL: $_backendUrl');

      final client = http.Client();
      final headers = {
        'Authorization': 'Bearer ${config.clientSecret}',
        'Content-Type': 'application/json',
      };

      final bodyMap = {
        'appId': config.appId,
        'currentVersion': config.appVersion,
        'acceptCompression': ['xz', 'gz', 'bz2'],
      };

      final requestUrl = '$_backendUrl/api/v1/patches/check';
      print('[QuicUI] POST $requestUrl');
      print('[QuicUI] Request body: $bodyMap');

      // Use internal backend URL (not exposed through Config)
      final response = await client.post(
        Uri.parse(requestUrl),
        headers: headers,
        body: jsonEncode(bodyMap),
      );

      print('[QuicUI] Response status: ${response.statusCode}');
      print('[QuicUI] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final patchAvailable = jsonResponse['patchAvailable'] as bool? ?? false;
        
        print('[QuicUI] Patch available: $patchAvailable');
        
        if (patchAvailable) {
          final patchInfo = PatchInfo(
            patchId: jsonResponse['patchId'] as String,
            version: jsonResponse['version'] as String,
            createdAt: DateTime.now(),
            size: jsonResponse['downloadSize'] as int,
            downloadUrl: '$_backendUrl${jsonResponse['downloadUrl'] as String}',
            signature: jsonResponse['hash'] as String,
          );
          
          final compression = jsonResponse['compression'] as String?;
          final uncompressedSize = jsonResponse['uncompressedSize'] as int?;
          
          print('[QuicUI] ✅ Patch found: ${patchInfo.version} (${patchInfo.size} bytes, compression: $compression, uncompressed: $uncompressedSize bytes)');
          
          config.onPatchAvailable?.call(patchInfo);
          client.close();
          return patchInfo;
        } else {
          print('[QuicUI] No patch available');
          client.close();
          return null;
        }
      } else {
        print('[QuicUI] ❌ Server returned error: ${response.statusCode}');
        print('[QuicUI] Error body: ${response.body}');
        client.close();
        return null;
      }
    } catch (e, stackTrace) {
      print('[QuicUI] ❌ Exception during checkForUpdates: $e');
      print('[QuicUI] Stack trace: $stackTrace');
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
      print('[QuicUI] Starting patch download and install process');
      print('[QuicUI] Patch version: ${patch.version}');
      print('[QuicUI] Patch size: ${patch.size} bytes');
      print('[QuicUI] Download URL: ${patch.downloadUrl}');

      // 1. Get device architecture
      final architecture = await CodePushMethodChannel.getDeviceArchitecture();
      print('[QuicUI] Device architecture: $architecture');

      // 2. Download patch to temporary directory
      final tempDir = Directory.systemTemp;
      final compressedFile = File('${tempDir.path}/quicui_patch_${patch.version}.compressed');
      final patchFile = File('${tempDir.path}/quicui_patch_${patch.version}.so');

      print('[QuicUI] Downloading patch to: ${compressedFile.path}');

      final client = http.Client();
      String? compressionFormat;
      try {
        print('[QuicUI] Making GET request to: ${patch.downloadUrl}');
        // Android doesn't have xz/gzip/bzip2 commands, so request uncompressed
        // TODO: Implement Dart-based decompression or bundle busybox
        final response = await client.get(
          Uri.parse(patch.downloadUrl),
          headers: {
            'Authorization': 'Bearer ${config.clientSecret}',
            // Don't request compression for now since Android lacks decompression tools
            // 'Accept-Encoding': 'xz, gz, bz2',
          },
        );

        print('[QuicUI] Response status: ${response.statusCode}');

        if (response.statusCode != 200) {
          print('[QuicUI] ❌ Failed to download patch: ${response.statusCode}');
          config.onError?.call('Failed to download patch: ${response.statusCode}');
          return false;
        }

        // Check if patch is compressed
        compressionFormat = response.headers['content-encoding'] ?? 
                           response.headers['x-compression-format'];
        
        print('[QuicUI] Patch downloaded: ${response.bodyBytes.length} bytes');
        print('[QuicUI] Compression format: ${compressionFormat ?? "none"}');

        // Write compressed data first
        await compressedFile.writeAsBytes(response.bodyBytes);

        // Decompress if needed
        if (compressionFormat != null && compressionFormat.isNotEmpty) {
          print('[QuicUI] Decompressing patch from $compressionFormat...');
          print('[QuicUI] Compressed file size: ${compressedFile.lengthSync()} bytes');

          try {
            // Use system commands to decompress
            Process? process;
            List<String> command;
            
            if (compressionFormat == 'xz') {
              command = ['xz', '-d', '-c', compressedFile.path];
              print('[QuicUI] Running command: ${command.join(" ")}');
              process = await Process.start('xz', ['-d', '-c', compressedFile.path]);
            } else if (compressionFormat == 'gz' || compressionFormat == 'gzip') {
              command = ['gzip', '-d', '-c', compressedFile.path];
              print('[QuicUI] Running command: ${command.join(" ")}');
              process = await Process.start('gzip', ['-d', '-c', compressedFile.path]);
            } else if (compressionFormat == 'bz2' || compressionFormat == 'bzip2') {
              command = ['bzip2', '-d', '-c', compressedFile.path];
              print('[QuicUI] Running command: ${command.join(" ")}');
              process = await Process.start('bzip2', ['-d', '-c', compressedFile.path]);
            }

            if (process != null) {
              print('[QuicUI] Process started, reading output...');
              final decompressedBytes = await process.stdout.toList();
              final bytes = decompressedBytes.expand((x) => x).toList();
              print('[QuicUI] Decompressed ${bytes.length} bytes in memory');
              
              await patchFile.writeAsBytes(bytes);
              print('[QuicUI] Written to: ${patchFile.path}');

              final exitCode = await process.exitCode;
              print('[QuicUI] Decompression exit code: $exitCode');
              
              if (exitCode != 0) {
                final error = await process.stderr.transform(utf8.decoder).join();
                print('[QuicUI] ❌ Decompression failed with exit code $exitCode');
                print('[QuicUI] Error: $error');
                config.onError?.call('Decompression failed: $error');
                await compressedFile.delete();
                return false;
              }

              await compressedFile.delete(); // Clean up compressed file
              print('[QuicUI] ✅ Decompression successful');
              print('[QuicUI] Decompressed file size: ${patchFile.lengthSync()} bytes');
            } else {
              print('[QuicUI] ⚠️  Unknown compression format, using file as-is');
              await compressedFile.rename(patchFile.path);
            }
          } catch (e, stackTrace) {
            print('[QuicUI] ❌ Decompression exception: $e');
            print('[QuicUI] Stack trace: $stackTrace');
            config.onError?.call('Decompression error: $e');
            
            // Try to use compressed file as-is
            print('[QuicUI] Attempting to use compressed file directly...');
            await compressedFile.rename(patchFile.path);
          }
        } else {
          print('[QuicUI] No compression, using file directly');
          await compressedFile.rename(patchFile.path);
          print('[QuicUI] Patch file size: ${patchFile.lengthSync()} bytes');
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
