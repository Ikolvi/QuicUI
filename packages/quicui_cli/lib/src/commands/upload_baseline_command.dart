import 'dart:io';
import 'dart:convert';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../config/cli_config.dart';

/// Command to upload baseline APK to Supabase Storage
class UploadBaselineCommand extends Command {
  @override
  final name = 'upload-baseline';
  
  @override
  final description = 'Upload baseline APK to server storage';

  UploadBaselineCommand() {
    argParser
      ..addOption(
        'baseline-dir',
        abbr: 'b',
        help: 'Path to baseline directory',
        defaultsTo: './baseline',
      )
      ..addOption(
        'project',
        abbr: 'p',
        help: 'Path to Flutter project',
        defaultsTo: '.',
      )
      ..addFlag(
        'replace',
        abbr: 'r',
        help: 'Replace existing baseline',
        negatable: false,
      );
  }

  @override
  Future<void> run() async {
    final baselineDir = argResults!['baseline-dir'] as String;
    final projectPath = argResults!['project'] as String;
    final replace = argResults!['replace'] as bool;

    print('');
    print('⬆️  QuicUI Baseline Uploader');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');

    final config = await CliConfig.load(projectPath);

    try {
      // Step 1: Load metadata
      final metadataFile = File(p.join(baselineDir, 'metadata.json'));
      if (!await metadataFile.exists()) {
        throw Exception('Metadata file not found in $baselineDir');
      }

      final metadata = jsonDecode(await metadataFile.readAsString());
      final version = metadata['version'];
      final apkPath = metadata['apkPath'];
      final libappPath = metadata['libappPath'];

      print('📋 Baseline Info:');
      print('   Version:      $version');
      print('   App ID:       ${config.appId}');
      print('   Architecture: ${metadata['architecture']}');
      print('');

      // Step 2: Read APK file
      final apkFile = File(apkPath);
      if (!await apkFile.exists()) {
        throw Exception('APK file not found: $apkPath');
      }

      final apkBytes = await apkFile.readAsBytes();
      final apkHash = sha256.convert(apkBytes).toString();
      final apkSize = apkBytes.length;

      print('📦 APK Details:');
      print('   Size: ${(apkSize / 1024 / 1024).toStringAsFixed(2)} MB');
      print('   Hash: $apkHash');
      print('');

      // Step 3: Upload to Supabase Storage
      print('⬆️  Uploading to storage...');
      
      final storagePath = 'patches/${config.appId}/baseline-v$version.apk';
      final uploadResult = await _uploadToStorage(
        config: config,
        bytes: apkBytes,
        path: storagePath,
        contentType: 'application/octet-stream',
        replace: replace,
      );

      print('   ✅ Uploaded: $storagePath');
      print('');

      // Step 4: Register baseline in database
      print('📝 Registering baseline...');
      
      final registrationData = {
        'app_id': config.appId,
        'version': version,
        'architecture': metadata['architecture'],
        'apk_path': storagePath,
        'apk_hash': apkHash,
        'apk_size': apkSize,
        'is_baseline': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _registerBaseline(config, registrationData);
      print('   ✅ Registered in database');
      print('');

      print('✅ Baseline Upload Complete!');
      print('');
      print('💡 Next steps:');
      print('   1. Build new version: quicui build-apk --version 2.0.0');
      print('   2. Generate patch: quicui generate-patch');
      print('   3. Upload patch: quicui upload-patch');
      print('');
    } catch (e) {
      print('');
      print('❌ Error: $e');
      exit(1);
    }
  }

  Future<Map<String, dynamic>> _uploadToStorage({
    required CliConfig config,
    required List<int> bytes,
    required String path,
    required String contentType,
    required bool replace,
  }) async {
    final url = '${config.serverUrl.replaceAll('/functions/v1', '')}/storage/v1/object/patches/$path';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${config.apiKey}',
        'apikey': config.apiKey,
        'Content-Type': contentType,
        if (replace) 'x-upsert': 'true',
      },
      body: bytes,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
    }

    return jsonDecode(response.body);
  }

  Future<void> _registerBaseline(CliConfig config, Map<String, dynamic> data) async {
    final url = '${config.serverUrl}/baseline-register';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'apikey': config.apiKey,
        'Authorization': 'Bearer ${config.apiKey}',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Registration failed: ${response.statusCode} - ${response.body}');
    }
  }
}
