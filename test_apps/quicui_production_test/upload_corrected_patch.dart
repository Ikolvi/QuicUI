import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('⬆️  Uploading CORRECTED Full Patched Binary');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('');
  
  // Read Supabase config
  final config = jsonDecode(await File('../../packages/quicui_cli/supabase_config.json').readAsString());
  final supabaseUrl = config['supabase_url'];
  final supabaseKey = config['supabase_key'];
  
  // Read corrected metadata
  final metadata = jsonDecode(await File('./patches/1764180399757_metadata_corrected.json').readAsString());
  
  print('📋 Patch Info:');
  print('   Patch ID: ${metadata['patchId']}');
  print('   From: v${metadata['fromVersion']}');
  print('   To: v${metadata['toVersion']}');
  print('   Platform: ${metadata['platform']}');
  print('   Architecture: ${metadata['architecture']}');
  print('   Compressed size: ${(metadata['compressedSize'] / 1024).toStringAsFixed(2)} KB');
  print('   Uncompressed size: ${(metadata['uncompressedSize'] / 1024 / 1024).toStringAsFixed(2)} MB');
  print('');
  
  // Read patch file
  final patchFile = File('./patches/App-v3.0.30-patched.xz');
  final patchBytes = await patchFile.readAsBytes();
  print('✅ Read patch file: ${patchBytes.length} bytes');
  print('');
  
  // Create multipart request
  print('⬆️  Uploading to Supabase...');
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$supabaseUrl/functions/v1/patches-upload'),
  );
  
  request.headers['Authorization'] = 'Bearer $supabaseKey';
  request.headers['Content-Type'] = 'multipart/form-data';
  
  // Add metadata
  request.fields['metadata'] = jsonEncode(metadata);
  
  // Add patch file
  request.files.add(http.MultipartFile.fromBytes(
    'patch',
    patchBytes,
    filename: 'App-v3.0.30-patched.xz',
  ));
  
  final response = await request.send();
  final responseBody = await response.stream.bytesToString();
  
  if (response.statusCode == 200) {
    print('✅ Upload successful!');
    print('');
    print('💡 Patch is now available for download');
    print('   Clients on v${metadata['fromVersion']} will receive this update');
    print('   Download size: ${(metadata['compressedSize'] / 1024).toStringAsFixed(2)} KB');
    print('   Installed size: ${(metadata['uncompressedSize'] / 1024 / 1024).toStringAsFixed(2)} MB');
  } else {
    print('❌ Upload failed: ${response.statusCode}');
    print('Response: $responseBody');
    exit(1);
  }
}
