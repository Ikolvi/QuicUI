import 'dart:io';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

import '../config.dart';
import '../services/flutter_build_service.dart';
import '../services/apk_extractor_service.dart';
import '../bsdiff.dart';

/// Automated build and deploy command
/// Handles: build APK -> extract libapp.so -> generate patches -> compress -> upload
class AutoBuildCommand {
  final _log = Logger('AutoBuildCommand');
  final QuicUIConfig config;

  late final FlutterBuildService _buildService;
  late final ApkExtractorService _extractorService;

  AutoBuildCommand({required this.config}) {
    _buildService = FlutterBuildService(
      projectPath: config.build.getAbsoluteProjectPath(),
    );
    _extractorService = ApkExtractorService();

    // Setup logging
    if (config.advanced.verbose) {
      Logger.root.level = Level.ALL;
    } else {
      Logger.root.level = Level.INFO;
    }
    
    Logger.root.onRecord.listen((record) {
      print('[${record.level.name}] ${record.loggerName}: ${record.message}');
    });
  }

  /// Execute full automated build and deploy
  Future<void> execute({
    String? targetVersion,
    bool skipBuild = false,
    bool skipUpload = false,
  }) async {
    print('');
    print('🚀 QuicUI Auto-Deploy');
    print('═' * 70);
    print('');

    try {
      // 1. Determine versions
      final baseVersion = config.version.current;
      final newVersion = targetVersion ?? config.version.getNextVersion();

      _log.info('Base version: $baseVersion');
      _log.info('New version:  $newVersion');

      // 2. Build APK (unless skipped)
      String apkPath;
      if (skipBuild) {
        apkPath = config.build.getAbsoluteApkPath();
        _log.info('Skipping build, using existing APK: $apkPath');
        
        if (!await File(apkPath).exists()) {
          throw Exception('APK not found: $apkPath. Remove --skip-build to build it.');
        }
      } else {
        print('');
        print('📦 Step 1/5: Building Flutter APK...');
        print('─' * 70);
        apkPath = await _buildService.buildApk(
          verbose: config.advanced.verbose,
        );
      }

      // 3. Extract libapp.so files
      print('');
      print('📂 Step 2/5: Extracting AOT snapshots...');
      print('─' * 70);
      
      final outputDir = config.build.getAbsoluteOutputPath();
      await Directory(outputDir).create(recursive: true);

      final extractedLibs = await _extractorService.extractLibApp(
        apkPath,
        config.build.architectures,
        outputDir: p.join(outputDir, 'extracted'),
      );

      if (extractedLibs.isEmpty) {
        throw Exception('No libapp.so files extracted. Check APK contains native code.');
      }

      // 4. Generate patches for each architecture
      print('');
      print('🔨 Step 3/5: Generating patches...');
      print('─' * 70);

      final patchFiles = <String, String>{};  // arch -> patch file path
      
      for (final entry in extractedLibs.entries) {
        final arch = entry.key;
        final newLibPath = entry.value;

        _log.info('Processing architecture: $arch');

        // Check if base snapshot exists
        final baseLibPath = p.join(
          outputDir,
          'base_snapshots',
          'libapp_${arch}_v$baseVersion.so',
        );

        if (!await File(baseLibPath).exists()) {
          // First build - save as base snapshot
          _log.info('No base snapshot found. Saving as base version...');
          await Directory(p.dirname(baseLibPath)).create(recursive: true);
          await File(newLibPath).copy(baseLibPath);
          _log.info('✅ Saved base snapshot: $baseLibPath');
          continue;
        }

        // Generate patch
        final patchFileName = 'patch_${baseVersion}_to_${newVersion}_$arch.quicui';
        final patchPath = p.join(outputDir, 'patches', patchFileName);

        await Directory(p.dirname(patchPath)).create(recursive: true);

        _log.info('Generating patch: $patchFileName');
        
        final patch = await BsDiff.generatePatch(
          baseLibPath,
          newLibPath,
          outputPath: patchPath,
        );

        _log.info('✅ Patch generated: ${_formatBytes(patch.patchSize)}');

        // Skip if identical
        if (config.patch.skipIfIdentical && patch.patchSize < 100) {
          _log.warning('⚠️  Files are identical or minimal changes. Skipping...');
          await File(patchPath).delete();
          continue;
        }

        patchFiles[arch] = patchPath;

        // Save new snapshot as next base
        if (config.advanced.cacheBaseSnapshots) {
          final newBaseLibPath = p.join(
            outputDir,
            'base_snapshots',
            'libapp_${arch}_v$newVersion.so',
          );
          await File(newLibPath).copy(newBaseLibPath);
          _log.info('Cached new base snapshot: $newBaseLibPath');
        }
      }

      if (patchFiles.isEmpty) {
        _log.warning('No patches generated. All architectures are up-to-date.');
        return;
      }

      // 5. Compress patches
      if (config.patch.compression != 'none') {
        print('');
        print('🗜️  Step 4/5: Compressing patches...');
        print('─' * 70);

        for (final entry in patchFiles.entries) {
          final patchPath = entry.value;

          await _compressPatch(patchPath, config.patch.compression);
        }
      }

      // 6. Upload patches to backend
      if (!skipUpload && config.upload.autoUpload && !config.advanced.dryRun) {
        print('');
        print('📤 Step 5/5: Uploading patches to backend...');
        print('─' * 70);

        for (final entry in patchFiles.entries) {
          final arch = entry.key;
          final patchPath = entry.value;

          await _uploadPatch(
            patchPath: patchPath,
            architecture: arch,
            version: newVersion,
          );
        }

        // Update config with new version
        await config.saveVersion(newVersion);
        _log.info('✅ Updated quicui.yaml with version: $newVersion');
      } else {
        _log.info('Upload skipped (dry-run mode or auto-upload disabled)');
      }

      print('');
      print('═' * 70);
      print('✅ Auto-deploy completed successfully!');
      print('');
      print('Summary:');
      print('  Base version:    $baseVersion');
      print('  New version:     $newVersion');
      print('  Patches:         ${patchFiles.length}');
      print('  Architectures:   ${patchFiles.keys.join(', ')}');
      print('');
      
      if (config.advanced.dryRun) {
        print('⚠️  DRY RUN MODE - Patches generated but not uploaded');
        print('');
      }

    } catch (e, stackTrace) {
      _log.severe('❌ Auto-deploy failed: $e');
      if (config.advanced.verbose) {
        _log.severe('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  /// Compress patch file using configured algorithm
  Future<void> _compressPatch(String patchPath, String algorithm) async {
    _log.info('Compressing: $patchPath with $algorithm');

    String command;
    switch (algorithm.toLowerCase()) {
      case 'xz':
        command = 'xz';
        break;
      case 'gzip':
      case 'gz':
        command = 'gzip';
        break;
      case 'bzip2':
      case 'bz2':
        command = 'bzip2';
        break;
      default:
        _log.warning('Unknown compression: $algorithm. Skipping.');
        return;
    }

    final originalSize = await File(patchPath).length();

    final result = await Process.run(
      command,
      ['-9', '-k', '-f', patchPath],  // -9: max compression, -k: keep original, -f: force
      workingDirectory: p.dirname(patchPath),
    );

    if (result.exitCode != 0) {
      throw Exception('Compression failed: ${result.stderr}');
    }

    final compressedPath = '$patchPath.$algorithm';
    if (await File(compressedPath).exists()) {
      final compressedSize = await File(compressedPath).length();
      final reduction = (1 - compressedSize / originalSize) * 100;
      
      _log.info('✅ Compressed: ${_formatBytes(originalSize)} → ${_formatBytes(compressedSize)} '
          '(${reduction.toStringAsFixed(1)}% reduction)');
    }
  }

  /// Upload patch to backend server
  Future<void> _uploadPatch({
    required String patchPath,
    required String architecture,
    required String version,
  }) async {
    _log.info('Uploading patch for $architecture...');

    // Check if compressed version exists
    String uploadPath = patchPath;
    String compression = 'none';
    
    final compressedPath = '$patchPath.${config.patch.compression}';
    if (await File(compressedPath).exists()) {
      uploadPath = compressedPath;
      compression = config.patch.compression;
      _log.info('Using compressed version: $uploadPath');
    }

    // Read patch file
    final patchFile = File(uploadPath);
    if (!await patchFile.exists()) {
      throw Exception('Patch file not found: $uploadPath');
    }

    final patchBytes = await patchFile.readAsBytes();
    final patchSize = patchBytes.length;

    // Calculate hash
    final digest = sha256.convert(patchBytes);
    final hash = digest.toString();

    // Generate patch ID
    final patchId = '${config.app.id}_v${version}_$architecture';

    _log.info('Patch ID: $patchId');
    _log.info('Size: ${_formatBytes(patchSize)}');
    _log.info('Hash: $hash');

    // Prepare registration payload with file upload
    final patchBase64 = base64Encode(patchBytes);
    
    final payload = {
      'patchId': patchId,
      'version': version,
      'appId': config.app.id,
      'architecture': architecture,
      'uncompressedSize': patchSize,
      'compressedSizes': compression != 'none' ? {compression: patchSize} : {},
      'hash': hash,
      'compression': compression,
      'patchFileBase64': patchBase64, // Upload file as base64
    };

    // Upload with retry
    // Supabase Edge Functions: url/patches-register
    // Old backend: url/api/v1/patches/register
    final url = config.server.url.contains('supabase.co')
        ? '${config.server.url}/patches-register'
        : '${config.server.url}/api/v1/patches/register';
    
    for (int attempt = 1; attempt <= config.upload.retryCount; attempt++) {
      try {
        _log.info('Upload attempt $attempt/${config.upload.retryCount}...');

        final response = await http
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                if (config.server.apiKey != null)
                  'apikey': config.server.apiKey!, // Supabase anon key
                if (config.server.apiKey != null)
                  'Authorization': 'Bearer ${config.server.apiKey}',
              },
              body: json.encode(payload),
            )
            .timeout(Duration(seconds: config.upload.timeout));

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          _log.info('✅ Upload successful: ${result['message']}');
          return;
        } else {
          _log.warning('Upload failed: ${response.statusCode} - ${response.body}');
          
          if (attempt < config.upload.retryCount) {
            _log.info('Retrying in ${attempt * 2} seconds...');
            await Future.delayed(Duration(seconds: attempt * 2));
          }
        }
      } catch (e) {
        _log.warning('Upload error: $e');
        
        if (attempt < config.upload.retryCount) {
          _log.info('Retrying in ${attempt * 2} seconds...');
          await Future.delayed(Duration(seconds: attempt * 2));
        } else {
          rethrow;
        }
      }
    }

    throw Exception('Upload failed after ${config.upload.retryCount} attempts');
  }

  /// Format bytes for display
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
