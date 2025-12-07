import 'dart:io';
import 'dart:convert';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive_io.dart';
import '../config/cli_config.dart';
import '../services/flutter_service.dart';

/// Command to build and release a baseline version
/// This is a single command that:
/// 1. Builds the APK/IPA
/// 2. Extracts the binary (libapp.so / App)
/// 3. Uploads baseline to server storage
/// 4. Registers baseline in database
class ReleaseCommand extends Command {
  @override
  final name = 'release';
  
  @override
  final description = 'Build and release a new baseline version (one command does everything)';

  ReleaseCommand() {
    argParser
      ..addOption(
        'version',
        abbr: 'v',
        help: 'Version number (e.g., 1.0.0). If not specified, reads from pubspec.yaml',
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
    final verbose = argResults!['verbose'] as bool;

    projectPath = p.normalize(p.absolute(projectPath));

    print('');
    print('🚀 QuicUI Release');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');

    try {
      // Step 1: Load config and get version
      final config = await CliConfig.load(projectPath);
      String version = argResults!['version'] as String? ?? await _getVersionFromPubspec(projectPath);
      
      print('📋 Release Info:');
      print('   App ID:       ${config.appId}');
      print('   Version:      $version');
      print('   Platform:     $platform');
      print('   Architecture: $architecture');
      print('');

      // Step 2: Build APK/IPA
      print('📦 Step 1: Building ${platform == 'android' ? 'APK' : 'IPA'}...');
      final buildResult = await _buildApp(projectPath, platform, architecture, verbose);
      print('   ✅ Build complete: ${buildResult['apkPath']}');
      print('');

      // Step 3: Extract binary
      print('📂 Step 2: Extracting binary...');
      final extractResult = await _extractBinary(
        buildResult['apkPath']!,
        platform,
        architecture,
        projectPath,
      );
      print('   ✅ Extracted: ${extractResult['binaryPath']}');
      print('   Size: ${(extractResult['binarySize']! / 1024 / 1024).toStringAsFixed(2)} MB');
      print('');

      // Step 4: Calculate hash
      print('🔐 Step 3: Calculating hash...');
      final binaryHash = await _calculateHash(extractResult['binaryPath']!);
      print('   Hash: $binaryHash');
      print('');

      // Step 5: Upload to storage
      print('⬆️  Step 4: Uploading baseline...');
      final uploadResult = await _uploadBaseline(
        config: config,
        version: version,
        platform: platform,
        architecture: architecture,
        binaryPath: extractResult['binaryPath']!,
        binarySize: extractResult['binarySize']!,
        binaryHash: binaryHash,
        apkPath: buildResult['apkPath']!,
      );
      print('   ✅ Uploaded to: ${uploadResult['storagePath']}');
      print('');

      // Step 6: Register in database
      print('📝 Step 5: Registering baseline...');
      await _registerBaseline(
        config: config,
        version: version,
        platform: platform,
        architecture: architecture,
        binaryPath: uploadResult['storagePath']!,
        binarySize: extractResult['binarySize']!,
        binaryHash: binaryHash,
      );
      print('   ✅ Baseline registered');
      print('');

      print('═══════════════════════════════════════════');
      print('✅ Release Complete!');
      print('');
      print('📋 Summary:');
      print('   Version:  $version');
      print('   Platform: $platform ($architecture)');
      print('   Hash:     ${binaryHash.substring(0, 16)}...');
      print('');
      print('💡 Next step: Make changes and run:');
      print('   quicui patch --version <new-version>');
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
  ) async {
    final outputDir = p.join(projectPath, '.quicui', 'baselines');
    await Directory(outputDir).create(recursive: true);
    
    if (platform == 'android') {
      // Extract libapp.so from APK
      final archive = ZipDecoder().decodeBytes(await File(apkPath).readAsBytes());
      
      for (final file in archive) {
        if (file.name.contains('lib/$architecture/libapp.so')) {
          final binaryPath = p.join(outputDir, 'libapp.so');
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
      // For iOS, extract App binary from .app bundle
      // This is simplified - in reality would need to handle .xcarchive
      throw Exception('iOS release not yet implemented');
    }
  }

  Future<String> _calculateHash(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return sha256.convert(bytes).toString();
  }

  Future<Map<String, String>> _uploadBaseline({
    required CliConfig config,
    required String version,
    required String platform,
    required String architecture,
    required String binaryPath,
    required int binarySize,
    required String binaryHash,
    required String apkPath,
  }) async {
    // Upload to Supabase storage
    final storagePath = '${config.appId}/${version}_${platform}_$architecture/libapp.so';
    
    final binaryBytes = await File(binaryPath).readAsBytes();
    
    final response = await http.post(
      Uri.parse('https://pcaxvanjhtfaeimflgfk.supabase.co/storage/v1/object/baselines/$storagePath'),
      headers: {
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/octet-stream',
        'x-upsert': 'true',
      },
      body: binaryBytes,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to upload baseline: ${response.statusCode} ${response.body}');
    }

    return {'storagePath': storagePath};
  }

  Future<void> _registerBaseline({
    required CliConfig config,
    required String version,
    required String platform,
    required String architecture,
    required String binaryPath,
    required int binarySize,
    required String binaryHash,
  }) async {
    final baselineId = '${config.appId}_${version}_${platform}_$architecture';
    
    final response = await http.post(
      Uri.parse('https://pcaxvanjhtfaeimflgfk.supabase.co/rest/v1/baselines'),
      headers: {
        'Authorization': 'Bearer ${config.apiKey}',
        'apikey': config.apiKey,
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates',
      },
      body: jsonEncode({
        'baseline_id': baselineId,
        'app_id': config.appId,
        'version': version,
        'platform': platform,
        'architecture': architecture,
        'binary_path': binaryPath,
        'binary_size': binarySize,
        'binary_hash': binaryHash,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to register baseline: ${response.statusCode} ${response.body}');
    }
  }
}
