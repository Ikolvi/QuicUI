import 'dart:io';
import 'dart:convert';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:archive/archive_io.dart';
import '../config/cli_config.dart';
import '../services/flutter_service.dart';
import '../services/compiler_service.dart';

/// Command to build and create a patch in one step
/// This is a single command that:
/// 1. Builds the new APK/IPA
/// 2. Extracts the new binary
/// 3. Downloads baseline from server (or uses local)
/// 4. Generates the patch
/// 5. Uploads the patch
class PatchCommand extends Command {
  @override
  final name = 'patch';
  
  @override
  final description = 'Build app, generate patch, and upload (one command does everything)';

  PatchCommand() {
    argParser
      ..addOption(
        'version',
        abbr: 'v',
        help: 'New version number (e.g., 1.0.1). If not specified, reads from pubspec.yaml',
      )
      ..addOption(
        'baseline',
        abbr: 'b',
        help: 'Baseline version to patch from. If not specified, uses latest baseline from server',
      )
      ..addOption(
        'platform',
        abbr: 'p',
        help: 'Target platform',
        defaultsTo: 'android',
        allowed: ['android', 'ios'],
      )
      ..addOption(
        'architecture',
        abbr: 'a',
        help: 'Target architecture',
        defaultsTo: 'arm64-v8a',
        allowed: ['arm64-v8a', 'armeabi-v7a', 'x86_64', 'arm64'],
      )
      ..addOption(
        'project',
        help: 'Path to Flutter project',
        defaultsTo: '.',
      )
      ..addOption(
        'compression',
        abbr: 'c',
        help: 'Compression format',
        defaultsTo: 'xz',
        allowed: ['none', 'xz', 'gzip'],
      )
      ..addOption(
        'release-notes',
        help: 'Release notes for this patch',
        defaultsTo: '',
      )
      ..addFlag(
        'critical',
        help: 'Mark this patch as critical (forces update)',
        defaultsTo: false,
      )
      ..addFlag(
        'verbose',
        help: 'Show detailed output',
        defaultsTo: false,
      );
  }

  @override
  Future<void> run() async {
    var projectPath = argResults!['project'] as String;
    final platform = argResults!['platform'] as String;
    final architecture = argResults!['architecture'] as String;
    final compression = argResults!['compression'] as String;
    final releaseNotes = argResults!['release-notes'] as String;
    final critical = argResults!['critical'] as bool;
    final verbose = argResults!['verbose'] as bool;

    projectPath = p.normalize(p.absolute(projectPath));

    print('');
    print('🔄 QuicUI Patch');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');

    try {
      // Step 1: Load config and get versions
      final config = await CliConfig.load(projectPath);
      String newVersion = argResults!['version'] as String? ?? await _getVersionFromPubspec(projectPath);
      String? baselineVersion = argResults!['baseline'] as String?;
      
      print('📋 Patch Info:');
      print('   App ID:       ${config.appId}');
      print('   New Version:  $newVersion');
      print('   Platform:     $platform');
      print('   Architecture: $architecture');
      print('');

      // Step 2: Get baseline version (from arg or fetch latest from server)
      if (baselineVersion == null) {
        print('🔍 Step 1: Finding latest baseline...');
        baselineVersion = await _getLatestBaselineVersion(config, platform, architecture);
        print('   ✅ Found baseline: v$baselineVersion');
      } else {
        print('📌 Using specified baseline: v$baselineVersion');
      }
      print('');

      // Step 3: Build new APK/IPA
      print('📦 Step 2: Building ${platform == 'android' ? 'APK' : 'IPA'}...');
      final buildResult = await _buildApp(projectPath, platform, architecture, verbose);
      print('   ✅ Build complete');
      print('');

      // Step 4: Extract new binary
      print('📂 Step 3: Extracting new binary...');
      final newBinaryResult = await _extractBinary(
        buildResult['apkPath']!,
        platform,
        architecture,
        projectPath,
        'new',
      );
      print('   ✅ New binary: ${(newBinaryResult['binarySize']! / 1024 / 1024).toStringAsFixed(2)} MB');
      print('');

      // Step 5: Download baseline from server
      print('⬇️  Step 4: Downloading baseline...');
      final baselineBinaryPath = await _downloadBaseline(
        config: config,
        version: baselineVersion,
        platform: platform,
        architecture: architecture,
        projectPath: projectPath,
      );
      print('   ✅ Baseline downloaded');
      print('');

      // Step 6: Generate patch
      print('🔨 Step 5: Generating patch...');
      final patchResult = await _generatePatch(
        oldBinaryPath: baselineBinaryPath,
        newBinaryPath: newBinaryResult['binaryPath']!,
        projectPath: projectPath,
        compression: compression,
        platform: platform,
      );
      print('   ✅ Patch generated');
      print('   Uncompressed: ${(patchResult['uncompressedSize']! / 1024).toStringAsFixed(2)} KB');
      print('   Compressed:   ${(patchResult['compressedSize']! / 1024).toStringAsFixed(2)} KB');
      print('   Ratio:        ${(patchResult['compressionRatio']! * 100).toStringAsFixed(1)}%');
      print('');

      // Step 7: Upload patch
      print('⬆️  Step 6: Uploading patch...');
      final uploadResult = await _uploadPatch(
        config: config,
        patchPath: patchResult['patchPath']!,
        newVersion: newVersion,
        baselineVersion: baselineVersion,
        platform: platform,
        architecture: architecture,
        patchHash: patchResult['patchHash']!,
        compressedSize: patchResult['compressedSize']!,
        uncompressedSize: patchResult['uncompressedSize']!,
        compression: compression,
        releaseNotes: releaseNotes,
        critical: critical,
      );
      print('   ✅ Patch uploaded');
      print('');

      print('═══════════════════════════════════════════');
      print('✅ Patch Complete!');
      print('');
      print('📋 Summary:');
      print('   From:    v$baselineVersion');
      print('   To:      v$newVersion');
      print('   Size:    ${(patchResult['compressedSize']! / 1024).toStringAsFixed(2)} KB');
      print('   Patch ID: ${uploadResult['patchId']}');
      print('');
      print('💡 Users on v$baselineVersion will receive this update automatically!');
      print('');

    } catch (e) {
      print('');
      print('❌ Error: $e');
      exit(1);
    }
  }

  Future<String> _getVersionFromPubspec(String projectPath) async {
    final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      throw Exception('pubspec.yaml not found in $projectPath');
    }
    
    final content = await pubspecFile.readAsString();
    final versionMatch = RegExp(r'^version:\s*(\d+\.\d+\.\d+)', multiLine: true).firstMatch(content);
    if (versionMatch == null) {
      throw Exception('Could not find version in pubspec.yaml');
    }
    
    return versionMatch.group(1)!;
  }

  Future<String> _getLatestBaselineVersion(
    CliConfig config,
    String platform,
    String architecture,
  ) async {
    final response = await http.get(
      Uri.parse('https://pcaxvanjhtfaeimflgfk.supabase.co/rest/v1/baselines?app_id=eq.${config.appId}&platform=eq.$platform&architecture=eq.$architecture&order=created_at.desc&limit=1'),
      headers: {
        'Authorization': 'Bearer ${config.apiKey}',
        'apikey': config.apiKey,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch baseline: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as List;
    if (data.isEmpty) {
      throw Exception('No baseline found for ${config.appId}. Run "quicui release" first.');
    }

    return data[0]['version'] as String;
  }

  Future<Map<String, String>> _buildApp(
    String projectPath,
    String platform,
    String architecture,
    bool verbose,
  ) async {
    final config = await CliConfig.load(projectPath);
    final flutterService = FlutterService(config);
    final version = await _getVersionFromPubspec(projectPath);
    
    if (platform == 'android') {
      final apkPath = await flutterService.buildApk(
        projectPath: projectPath,
        version: version,
        architecture: architecture,
      );
      return {'apkPath': apkPath};
    } else {
      final ipaPath = await flutterService.buildIos(
        projectPath: projectPath,
        version: version,
      );
      return {'apkPath': ipaPath};
    }
  }

  Future<Map<String, dynamic>> _extractBinary(
    String apkPath,
    String platform,
    String architecture,
    String projectPath,
    String prefix,
  ) async {
    final outputDir = p.join(projectPath, '.quicui', 'temp');
    await Directory(outputDir).create(recursive: true);
    
    if (platform == 'android') {
      final archive = ZipDecoder().decodeBytes(await File(apkPath).readAsBytes());
      
      for (final file in archive) {
        if (file.name.contains('lib/$architecture/libapp.so')) {
          final binaryPath = p.join(outputDir, '${prefix}_libapp.so');
          final outFile = File(binaryPath);
          await outFile.writeAsBytes(file.content as List<int>);
          return {
            'binaryPath': binaryPath,
            'binarySize': file.size,
          };
        }
      }
      
      throw Exception('libapp.so not found in APK for architecture $architecture');
    } else {
      throw Exception('iOS patch not yet implemented');
    }
  }

  Future<String> _downloadBaseline({
    required CliConfig config,
    required String version,
    required String platform,
    required String architecture,
    required String projectPath,
  }) async {
    // Get baseline info from database
    final response = await http.get(
      Uri.parse('https://pcaxvanjhtfaeimflgfk.supabase.co/rest/v1/baselines?app_id=eq.${config.appId}&version=eq.$version&platform=eq.$platform&architecture=eq.$architecture&limit=1'),
      headers: {
        'Authorization': 'Bearer ${config.apiKey}',
        'apikey': config.apiKey,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch baseline info: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as List;
    if (data.isEmpty) {
      throw Exception('Baseline v$version not found');
    }

    final storagePath = data[0]['binary_path'] as String;

    // Download from storage
    final downloadResponse = await http.get(
      Uri.parse('https://pcaxvanjhtfaeimflgfk.supabase.co/storage/v1/object/public/baselines/$storagePath'),
      headers: {
        'Authorization': 'Bearer ${config.apiKey}',
      },
    );

    if (downloadResponse.statusCode != 200) {
      throw Exception('Failed to download baseline: ${downloadResponse.statusCode}');
    }

    // Save to temp directory
    final outputDir = p.join(projectPath, '.quicui', 'temp');
    await Directory(outputDir).create(recursive: true);
    
    final baselinePath = p.join(outputDir, 'baseline_libapp.so');
    await File(baselinePath).writeAsBytes(downloadResponse.bodyBytes);

    return baselinePath;
  }

  Future<Map<String, dynamic>> _generatePatch({
    required String oldBinaryPath,
    required String newBinaryPath,
    required String projectPath,
    required String compression,
    required String platform,
  }) async {
    final outputDir = p.join(projectPath, '.quicui', 'patches');
    await Directory(outputDir).create(recursive: true);

    final result = await CompilerService.generatePatch(
      oldLibappPath: oldBinaryPath,
      newLibappPath: newBinaryPath,
      outputDir: outputDir,
      compression: compression,
    );

    return {
      'patchPath': result.patchPath,
      'patchHash': result.patchHash,
      'compressedSize': result.patchSize,
      'uncompressedSize': result.uncompressedSize,
      'compressionRatio': result.compressionRatio,
    };
  }

  Future<Map<String, String>> _uploadPatch({
    required CliConfig config,
    required String patchPath,
    required String newVersion,
    required String baselineVersion,
    required String platform,
    required String architecture,
    required String patchHash,
    required int compressedSize,
    required int uncompressedSize,
    required String compression,
    required String releaseNotes,
    required bool critical,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final patchId = '${config.appId}_${newVersion}_${platform}_$timestamp';
    
    // Upload patch file to storage
    final storagePath = '${config.appId}/${newVersion}_${platform}_$architecture.${compression == 'none' ? 'quicui' : 'quicui.$compression'}';
    
    final patchBytes = await File(patchPath).readAsBytes();
    
    final uploadResponse = await http.post(
      Uri.parse('https://pcaxvanjhtfaeimflgfk.supabase.co/storage/v1/object/patches/$storagePath'),
      headers: {
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/octet-stream',
        'x-upsert': 'true',
      },
      body: patchBytes,
    );

    if (uploadResponse.statusCode != 200 && uploadResponse.statusCode != 201) {
      throw Exception('Failed to upload patch: ${uploadResponse.statusCode} ${uploadResponse.body}');
    }

    // Register patch in database
    final registerResponse = await http.post(
      Uri.parse('https://pcaxvanjhtfaeimflgfk.supabase.co/rest/v1/patches'),
      headers: {
        'Authorization': 'Bearer ${config.apiKey}',
        'apikey': config.apiKey,
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates',
      },
      body: jsonEncode({
        'patch_id': patchId,
        'app_id': config.appId,
        'version': newVersion,
        'platform': platform,
        'architecture': architecture,
        'hash': patchHash,
        'compression': compression,
        'uncompressed_path': storagePath,
        'uncompressed_size': uncompressedSize,
        'compressed_paths': {compression: storagePath},
        'compressed_sizes': {compression: compressedSize},
        'release_notes': releaseNotes,
        'critical': critical,
        'status': 'active',
      }),
    );

    if (registerResponse.statusCode != 200 && registerResponse.statusCode != 201) {
      throw Exception('Failed to register patch: ${registerResponse.statusCode} ${registerResponse.body}');
    }

    return {'patchId': patchId};
  }
}
