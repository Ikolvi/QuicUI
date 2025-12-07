import 'dart:io';
import 'dart:convert';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../config/cli_config.dart';

/// Command to upload patch to Supabase
class UploadPatchCommand extends Command {
  @override
  final name = 'upload-patch';
  
  @override
  final description = 'Upload patch to server';

  UploadPatchCommand() {
    argParser
      ..addOption(
        'patch',
        help: 'Patch file path (.vmcode or .quicui)',
        mandatory: true,
      )
      ..addOption(
        'version',
        help: 'Patch version (e.g., 3.0.61)',
        mandatory: true,
      )
      ..addOption(
        'app-id',
        help: 'App ID (e.g., com.example.app)',
        mandatory: true,
      )
      ..addOption(
        'platform',
        help: 'Platform: ios or android',
        allowed: ['ios', 'android'],
        defaultsTo: 'ios',
      )
      ..addOption(
        'from-version',
        help: 'Base version (e.g., 3.0.60)',
      )
      ..addOption(
        'architecture',
        help: 'Architecture (e.g., arm64, arm64-v8a)',
        defaultsTo: 'arm64',
      );
  }

  @override
  Future<void> run() async {
    final patchPath = argResults!['patch'] as String;
    final version = argResults!['version'] as String;
    final appId = argResults!['app-id'] as String;
    final platform = argResults!['platform'] as String;
    final fromVersion = argResults!['from-version'] as String?;
    final architecture = argResults!['architecture'] as String;

    print('');
    print('⬆️  QuicUI Patch Uploader');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');

    // Load default config (for server URL)
    final config = await CliConfig.load('.');

    try {
      // Step 1: Validate patch file
      final patchFile = File(patchPath);
      if (!await patchFile.exists()) {
        throw Exception('Patch file not found: $patchPath');
      }

      final patchBytes = await patchFile.readAsBytes();
      final patchSizeKB = (patchBytes.length / 1024).toStringAsFixed(2);
      
      // Generate patch ID from filename or timestamp
      final filename = p.basenameWithoutExtension(patchPath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final patchId = '${appId}_${version}_${platform}_$timestamp';

      print('📋 Patch Info:');
      print('   File:         $filename');
      print('   Patch ID:     $patchId');
      print('   Platform:     $platform');
      print('   Architecture: $architecture');
      if (fromVersion != null) {
        print('   From:         v$fromVersion');
      }
      print('   To:           v$version');
      print('   App ID:       $appId');
      print('');

      print('📦 Patch Details:');
      print('   Size: $patchSizeKB KB');
      print('   Path: $patchPath');
      print('');

      // Calculate hash
      print('🔐 Calculating hash...');
      final hash = _calculateHash(patchBytes);
      print('   Hash: $hash');
      print('');

      // Detect compression
      final compression = patchPath.endsWith('.xz') ? 'xz' : 'none';

      // Build metadata
      final metadata = {
        'patchId': patchId,
        'version': version,
        'toVersion': version,
        'fromVersion': fromVersion ?? 'unknown',
        'appId': appId,
        'platform': platform,
        'architecture': architecture,
        'hash': hash,
        'uncompressedSize': patchBytes.length,
        'compressedSize': patchBytes.length,
        'compression': compression,
      };

      // Step 2: Upload as multipart (much faster than base64)
      print('⬆️  Uploading patch...');
      
      await _uploadPatchMultipart(config, patchBytes, metadata);

      print('');
      print('✅ Patch Upload Complete!');
      print('');
      print('💡 Patch is now available for download');
      if (fromVersion != null) {
        print('   Clients on v$fromVersion will receive this update');
      }
      print('');
    } catch (e) {
      print('');
      print('❌ Error: $e');
      exit(1);
    }
  }

  String _calculateHash(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Upload patch using multipart/form-data (much faster than base64)
  Future<void> _uploadPatchMultipart(
    CliConfig config,
    List<int> patchBytes,
    Map<String, dynamic> metadata,
  ) async {
    final url = '${config.serverUrl}/patches-register';
    
    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..headers.addAll({
        'Authorization': 'Bearer ${config.apiKey}',
        'apikey': config.apiKey,
      })
      ..fields.addAll({
        'patchId': metadata['patchId'].toString(),
        'version': metadata['toVersion'].toString(),
        'appId': metadata['appId'].toString(),
        'platform': (metadata['platform'] ?? 'android').toString(),
        'architecture': metadata['architecture'].toString(),
        'hash': metadata['hash'].toString(),
        'uncompressedSize': metadata['uncompressedSize'].toString(),
        'compressedSize': metadata['compressedSize'].toString(),
        'compression': metadata['compression'].toString(),
      });

    // Determine file extension based on platform
    final platform = metadata['platform'] ?? 'android';
    final baseExtension = platform == 'ios' ? 'vmcode' : 'quicui';
    final compression = metadata['compression'] as String;
    final filename = compression == 'xz' 
        ? '${metadata['patchId']}.$baseExtension.xz'
        : '${metadata['patchId']}.$baseExtension';

    request.files.add(http.MultipartFile.fromBytes(
      'patchFile',
      patchBytes,
      filename: filename,
    ));

    final streamedResponse = await request.send().timeout(
      Duration(seconds: 60),
      onTimeout: () {
        throw Exception('Upload timed out after 60 seconds');
      },
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 && response.statusCode != 201) {
      // Try to parse error response
      String errorMessage = 'Upload failed: ${response.statusCode}';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['error'] != null) {
          errorMessage = '${errorData['error']['code']}: ${errorData['error']['message']}';
        } else {
          errorMessage = response.body;
        }
      } catch (_) {
        errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
      }
      throw Exception(errorMessage);
    }
    
    print('   ✅ Uploaded successfully');
  }
}
