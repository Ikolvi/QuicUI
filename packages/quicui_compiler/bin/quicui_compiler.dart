import 'dart:io';
import 'dart:convert';

import 'package:quicui_compiler/src/cli_commands.dart';
import 'package:quicui_compiler/src/bsdiff.dart';
import 'package:crypto/crypto.dart';

/// QuicUI Code Push Compiler - Main CLI Entry Point
/// 
/// Usage:
///   quicui-compiler diff <old-file> <new-file> --output=patch.quicui
///   quicui-compiler patch <old-file> <patch-file> <new-file>
///   quicui-compiler build <old-kernel> <new-kernel> --version=1.0.1
///   quicui-compiler upload <patch-version> --service-url=https://api.quicui.com
///   quicui-compiler rollout <patch-version> --percentage=10
///   quicui-compiler version list --service-url=https://api.quicui.com
///   quicui-compiler keygen
///   quicui-compiler verify <patch-file> <key-file> <manifest-file>

void main(List<String> args) async {
  // Parse command line arguments
  if (args.isEmpty) {
    _printUsage();
    exit(1);
  }

  final command = args[0];
  final cmdArgs = args.sublist(1);

  try {
    switch (command) {
      case 'build':
        await _handleBuild(cmdArgs);
        break;

      case 'diff':
        await _handleDiff(cmdArgs);
        break;

      case 'patch':
        await _handlePatch(cmdArgs);
        break;

      case 'upload':
        await _handleUpload(cmdArgs);
        break;

      case 'rollout':
        await _handleRollout(cmdArgs);
        break;

      case 'version':
        await _handleVersion(cmdArgs);
        break;

      case 'keygen':
        await _handleKeyGen(cmdArgs);
        break;

      case 'verify':
        await _handleVerify(cmdArgs);
        break;

      case 'register':
        await _handleRegister(cmdArgs);
        break;

      case '--help':
      case '-h':
        _printUsage();
        break;

      case '--version':
      case '-v':
        print('QuicUI Code Push Compiler v0.9.0-dev');
        break;

      default:
        print('❌ Unknown command: $command');
        _printUsage();
        exit(1);
    }
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

/// Handle 'build' command
Future<void> _handleBuild(List<String> args) async {
  if (args.length < 2) {
    print('Usage: quicui-compiler build <old-kernel> <new-kernel> [options]');
    print('Options:');
    print('  --version=VERSION          Patch version (required)');
    print('  --description=TEXT         Patch description');
    print('  --critical                 Mark as critical patch');
    print('  --output-dir=DIR           Output directory');
    return;
  }

  final oldKernel = args[0];
  final newKernel = args[1];
  final options = _parseOptions(args.sublist(2));

  if (!options.containsKey('version')) {
    print('❌ Error: --version is required');
    return;
  }

  final outputDir = options['output-dir'] as String? ?? './.quicui';
  final cli = CodePushCliCommands(projectDir: '.', outputDir: outputDir);

  await cli.initialize();

  final result = await cli.build(
    oldKernelPath: oldKernel,
    newKernelPath: newKernel,
    patchVersion: options['version'] as String,
    description: options['description'] as String?,
    critical: options.containsKey('critical'),
  );

  if (result.success) {
    exit(0);
  } else {
    exit(1);
  }
}

/// Handle 'diff' command - Generate binary patch using BsDiff
Future<void> _handleDiff(List<String> args) async {
  if (args.length < 2) {
    print('Usage: quicui-compiler diff <old-file> <new-file> [options]');
    print('');
    print('Generate a binary patch from old file to new file using BsDiff algorithm.');
    print('Automatically registers patch with backend server after creation.');
    print('');
    print('Arguments:');
    print('  <old-file>                 Path to old snapshot file');
    print('  <new-file>                 Path to new snapshot file');
    print('');
    print('Options:');
    print('  --output=FILE              Output patch file path');
    print('                             (default: patch.quicui)');
    print('  --compress=ALGORITHM       Compress patch: gzip, bz2, xz, or none');
    print('                             (default: none)');
    print('  --app-id=ID                Application ID (required for auto-register)');
    print('  --version=VERSION          Patch version (required for auto-register)');
    print('  --server-url=URL           Backend server URL (default: http://192.168.20.100:8080)');
    print('  --no-register              Skip automatic registration');
    print('');
    print('Example:');
    print('  quicui-compiler diff app_v1.0.0.so app_v1.0.1.so \\');
    print('    --output=v1.0.0_to_v1.0.1.quicui \\');
    print('    --app-id=com.quicui.test_app_fresh \\');
    print('    --version=1.0.1 \\');
    print('    --compress=none');
    return;
  }

  final oldFile = args[0];
  final newFile = args[1];
  final options = _parseOptions(args.sublist(2));

  final outputFile = options['output'] as String? ?? 'patch.quicui';
  final compression = options['compress'] as String? ?? 'none';
  final appId = options['app-id'] as String?;
  final version = options['version'] as String?;
  final serverUrl = options['server-url'] as String? ?? 'http://192.168.20.100:8080';
  final noRegister = options.containsKey('no-register');

  print('');
  print('🔧 QuicUI Binary Diff');
  print('═' * 60);
  print('Old file:     $oldFile');
  print('New file:     $newFile');
  print('Output:       $outputFile');
  print('Compression:  $compression');
  if (!noRegister && appId != null && version != null) {
    print('Server URL:   $serverUrl');
    print('App ID:       $appId');
    print('Version:      $version');
  }
  print('═' * 60);
  print('');

  try {
    final patch = await BsDiff.generatePatch(
      oldFile,
      newFile,
      outputPath: outputFile,
    );

    // Apply compression if requested
    int compressedSize = patch.patchSize;
    bool compressionSuccess = false;
    if (compression != 'none') {
      compressionSuccess = await _compressPatch(outputFile, compression);
      if (compressionSuccess) {
        final compressedFile = File('$outputFile.$compression');
        compressedSize = await compressedFile.length();
      }
    }

    print('');
    print('✅ Patch generated successfully!');
    print('');
    print('Patch Statistics:');
    print('  Old size:        ${_formatBytes(patch.oldSize)}');
    print('  New size:        ${_formatBytes(patch.newSize)}');
    print('  Patch size:      ${_formatBytes(patch.patchSize)}');
    if (compression != 'none' && compressionSuccess) {
      print('  Compressed:      ${_formatBytes(compressedSize)} (${compression})');
      final totalCompression = (1 - compressedSize / patch.newSize) * 100;
      print('  Total reduction: ${totalCompression.toStringAsFixed(2)}%');
    }
    print('  Operations:      ${patch.operations.length}');
    print('');
    print('Old hash: ${patch.oldHash}');
    print('New hash: ${patch.newHash}');
    print('');

    // Auto-register with backend if credentials provided
    if (!noRegister && appId != null && version != null) {
      print('');
      print('📤 Auto-registering patch with backend...');
      print('');
      
      // Call register command
      await _handleRegister([
        outputFile,
        '--server-url=$serverUrl',
        '--app-id=$appId',
        '--version=$version',
      ]);
    } else if (!noRegister) {
      print('⚠️  Skipping auto-registration (--app-id and --version required)');
      print('');
      print('To register manually:');
      print('  quicui-compiler register $outputFile \\');
      print('    --app-id=<your-app-id> \\');
      print('    --version=<patch-version> \\');
      print('    --server-url=$serverUrl');
      print('');
    }
  } catch (e) {
    print('');
    print('❌ Error generating patch: $e');
    exit(1);
  }
}

/// Handle 'patch' command - Apply binary patch using BsPatch
Future<void> _handlePatch(List<String> args) async {
  if (args.length < 3) {
    print('Usage: quicui-compiler patch <old-file> <patch-file> <new-file>');
    print('');
    print('Apply a binary patch to an old file to produce a new file.');
    print('Automatically detects and decompresses compressed patches (.gz, .bz2, .xz).');
    print('');
    print('Arguments:');
    print('  <old-file>                 Path to old snapshot file');
    print('  <patch-file>               Path to patch file (.quicui, .quicui.xz, etc)');
    print('  <new-file>                 Path to output new snapshot file');
    print('');
    print('Example:');
    print('  quicui-compiler patch app_v1.0.0.so patch_1.0.1.quicui.xz app_v1.0.1.so');
    return;
  }

  final oldFile = args[0];
  final patchFile = args[1];
  final newFile = args[2];

  print('');
  print('🔧 QuicUI Binary Patch');
  print('═' * 60);
  print('Old file:   $oldFile');
  print('Patch file: $patchFile');
  print('New file:   $newFile');
  print('═' * 60);
  print('');

  try {
    // Decompress patch if needed
    final actualPatchFile = await _decompressPatch(patchFile);

    await BsDiff.applyPatch(oldFile, actualPatchFile, newFile);

    print('');
    print('✅ Patch applied successfully!');
    print('');

    // Clean up temporary decompressed file if it was created
    if (actualPatchFile != patchFile) {
      await File(actualPatchFile).delete();
    }
  } catch (e) {
    print('');
    print('❌ Error applying patch: $e');
    exit(1);
  }
}

/// Handle 'upload' command
Future<void> _handleUpload(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: quicui-compiler upload <patch-version> [options]');
    print('Options:');
    print('  --service-url=URL          Service URL (required)');
    print('  --app-id=ID                App ID (required)');
    print('  --auth-token=TOKEN         Authentication token');
    print('  --output-dir=DIR           Output directory');
    return;
  }

  final patchVersion = args[0];
  final options = _parseOptions(args.sublist(1));

  if (!options.containsKey('service-url') || !options.containsKey('app-id')) {
    print('❌ Error: --service-url and --app-id are required');
    return;
  }

  final outputDir = options['output-dir'] as String? ?? './.quicui';
  final cli = CodePushCliCommands(projectDir: '.', outputDir: outputDir);

  await cli.initialize();

  final result = await cli.upload(
    patchVersion: patchVersion,
    serviceUrl: options['service-url'] as String,
    appId: options['app-id'] as String,
    authToken: options['auth-token'] as String?,
  );

  if (result.success) {
    exit(0);
  } else {
    exit(1);
  }
}

/// Handle 'rollout' command
Future<void> _handleRollout(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: quicui-compiler rollout <patch-version> [options]');
    print('Options:');
    print('  --service-url=URL          Service URL (required)');
    print('  --app-id=ID                App ID (required)');
    print('  --percentage=NUM           Rollout percentage (0-100, default: 100)');
    print('  --environment=ENV          Environment (default: production)');
    print('  --critical                 Mark as critical rollout');
    return;
  }

  final patchVersion = args[0];
  final options = _parseOptions(args.sublist(1));

  if (!options.containsKey('service-url') || !options.containsKey('app-id')) {
    print('❌ Error: --service-url and --app-id are required');
    return;
  }

  final outputDir = options['output-dir'] as String? ?? './.quicui';
  final cli = CodePushCliCommands(projectDir: '.', outputDir: outputDir);

  await cli.initialize();

  final percentage = double.tryParse(options['percentage'] as String? ?? '100') ?? 100.0;

  final result = await cli.rollout(
    patchVersion: patchVersion,
    serviceUrl: options['service-url'] as String,
    appId: options['app-id'] as String,
    rolloutPercentage: percentage,
    environment: options['environment'] as String?,
    critical: options.containsKey('critical'),
  );

  if (result.success) {
    exit(0);
  } else {
    exit(1);
  }
}

/// Handle 'version' command
Future<void> _handleVersion(List<String> args) async {
  if (args.isEmpty || args[0] != 'list') {
    print('Usage: quicui-compiler version list [options]');
    print('Options:');
    print('  --service-url=URL          Service URL (required)');
    print('  --app-id=ID                App ID (required)');
    return;
  }

  final options = _parseOptions(args.sublist(1));

  if (!options.containsKey('service-url') || !options.containsKey('app-id')) {
    print('❌ Error: --service-url and --app-id are required');
    return;
  }

  final outputDir = options['output-dir'] as String? ?? './.quicui';
  final cli = CodePushCliCommands(projectDir: '.', outputDir: outputDir);

  await cli.initialize();

  final result = await cli.listVersions(
    serviceUrl: options['service-url'] as String,
    appId: options['app-id'] as String,
  );

  if (result.success) {
    exit(0);
  } else {
    exit(1);
  }
}

/// Handle 'keygen' command
Future<void> _handleKeyGen(List<String> args) async {
  final options = _parseOptions(args);

  final outputDir = options['output-dir'] as String? ?? './.quicui';
  final cli = CodePushCliCommands(projectDir: '.', outputDir: outputDir);

  await cli.initialize();

  final result = await cli.generateKey();

  if (result.success) {
    exit(0);
  } else {
    exit(1);
  }
}

/// Handle 'verify' command
Future<void> _handleVerify(List<String> args) async {
  if (args.length < 3) {
    print('Usage: quicui-compiler verify <patch-file> <key-file> <manifest-file>');
    return;
  }

  final patchFile = args[0];
  final keyFile = args[1];
  final manifestFile = args[2];

  final cli = CodePushCliCommands(projectDir: '.', outputDir: './.quicui');

  await cli.initialize();

  final result = await cli.verify(
    patchFile: patchFile,
    publicKeyFile: keyFile,
    manifestFile: manifestFile,
  );

  if (result.success) {
    exit(0);
  } else {
    exit(1);
  }
}

/// Handle 'register' command - Register patch with backend server
Future<void> _handleRegister(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: quicui-compiler register <patch-file> [options]');
    print('');
    print('Register a patch with the backend server after generating it.');
    print('Automatically detects compressed versions and registers them.');
    print('');
    print('Arguments:');
    print('  <patch-file>               Path to patch file (.quicui)');
    print('');
    print('Options:');
    print('  --server-url=URL           Backend server URL (default: http://localhost:8080)');
    print('  --app-id=ID                Application ID (required)');
    print('  --version=VERSION          Patch version (required)');
    print('  --patch-id=ID              Custom patch ID (default: auto-generated)');
    print('');
    print('Example:');
    print('  quicui-compiler register v1.0.0_to_v1.0.1.quicui \\');
    print('    --app-id=com.example.app \\');
    print('    --version=1.0.1 \\');
    print('    --server-url=http://localhost:8080');
    return;
  }

  final patchFile = args[0];
  final options = _parseOptions(args.sublist(1));

  final serverUrl = options['server-url'] as String? ?? 'http://localhost:8080';
  final appId = options['app-id'] as String?;
  final version = options['version'] as String?;
  final patchId = options['patch-id'] as String?;

  if (appId == null || version == null) {
    print('❌ Error: --app-id and --version are required');
    print('');
    print('Example:');
    print('  quicui-compiler register $patchFile --app-id=com.example.app --version=1.0.1');
    exit(1);
  }

  print('');
  print('📤 Registering Patch with Backend');
  print('═' * 60);
  print('Patch file:  $patchFile');
  print('Server URL:  $serverUrl');
  print('App ID:      $appId');
  print('Version:     $version');
  print('═' * 60);
  print('');

  try {
    // Check if patch file exists
    final patchFileObj = File(patchFile);
    if (!await patchFileObj.exists()) {
      print('❌ Patch file not found: $patchFile');
      exit(1);
    }

    // Get absolute path
    final absolutePath = patchFileObj.absolute.path;

    // Detect compressed versions
    final compressedPaths = <String, String>{};
    final compressedSizes = <String, int>{};

    for (final ext in ['xz', 'gz', 'bz2']) {
      final compressedFile = File('$absolutePath.$ext');
      if (await compressedFile.exists()) {
        compressedPaths[ext] = compressedFile.absolute.path;
        compressedSizes[ext] = await compressedFile.length();
        print('✓ Found compressed version: $ext (${_formatBytes(compressedSizes[ext]!)})');
      }
    }

    if (compressedPaths.isEmpty) {
      print('⚠️  No compressed versions found. Consider using --compress=xz when generating patches.');
    }

    // Get file sizes
    final uncompressedSize = await patchFileObj.length();

    // Calculate hash
    final bytes = await patchFileObj.readAsBytes();
    final digest = sha256.convert(bytes);
    final hash = digest.toString();

    print('');
    print('📊 Patch Information:');
    print('   Uncompressed: ${_formatBytes(uncompressedSize)}');
    if (compressedPaths.containsKey('xz')) {
      final reduction = (1 - compressedSizes['xz']! / uncompressedSize) * 100;
      print('   Compressed:   ${_formatBytes(compressedSizes['xz']!)} (xz, ${reduction.toStringAsFixed(1)}% reduction)');
    }
    print('   SHA256:       $hash');
    print('');

    // Generate patch ID if not provided
    final finalPatchId = patchId ?? '${appId}_v$version';

    // Create registration payload
    final payload = {
      'patchId': finalPatchId,
      'version': version,
      'appId': appId,
      'uncompressedPath': absolutePath,
      'compressedPaths': compressedPaths,
      'uncompressedSize': uncompressedSize,
      'compressedSizes': compressedSizes,
      'hash': hash,
    };

    // Send registration request
    print('📤 Sending registration request to $serverUrl/api/v1/patches/register...');

    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse('$serverUrl/api/v1/patches/register'));
      request.headers.set('Content-Type', 'application/json');
      request.write(json.encode(payload));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final result = json.decode(responseBody);
        print('');
        print('✅ Patch registered successfully!');
        print('');
        print('Patch Details:');
        print('   Patch ID: ${result['patchId']}');
        print('   Message:  ${result['message']}');
        print('');
        print('Next Steps:');
        print('1. Test patch check:');
        print('   curl -X POST $serverUrl/api/v1/patches/check \\');
        print('     -H "Content-Type: application/json" \\');
        print('     -d \'{"appId": "$appId", "currentVersion": "1.0.0", "acceptCompression": ["xz"]}\'');
        print('');
        print('2. Download patch:');
        print('   curl -H "Accept-Encoding: xz" \\');
        print('     $serverUrl/api/v1/patches/download/$finalPatchId \\');
        print('     -o downloaded_patch.quicui.xz');
        print('');
      } else {
        print('');
        print('❌ Registration failed!');
        print('   Status: ${response.statusCode}');
        print('   Response: $responseBody');
        exit(1);
      }
    } finally {
      client.close();
    }
  } catch (e) {
    print('');
    print('❌ Error registering patch: $e');
    exit(1);
  }
}

/// Parse command-line options
Map<String, dynamic> _parseOptions(List<String> args) {
  final options = <String, dynamic>{};

  for (final arg in args) {
    if (arg.startsWith('--')) {
      final parts = arg.substring(2).split('=');
      final key = parts[0];
      final value = parts.length > 1 ? parts.sublist(1).join('=') : true;
      options[key] = value;
    }
  }

  return options;
}

/// Print usage information
void _printUsage() {
  print('''
QuicUI Code Push Compiler v0.9.0-dev
Patch compilation, signing, and deployment tool

USAGE:
  quicui-compiler <command> [options]

COMMANDS:
  diff        Generate binary patch between two files
  patch       Apply binary patch to a file
  build       Build a new patch from kernel files
  upload      Upload patch to code push service
  rollout     Deploy patch to users
  version     Manage patch versions
  keygen      Generate signing key pair
  verify      Verify patch signature
  register    Register patch with backend server

EXAMPLES:
  # Generate compressed binary patch
  quicui-compiler diff old.so new.so --output=patch.quicui --compress=xz

  # Apply compressed patch
  quicui-compiler patch old.so patch.quicui.xz new.so

  # Register patch with backend
  quicui-compiler register patch.quicui \\
    --app-id=com.example.app \\
    --version=1.0.1 \\
    --server-url=http://localhost:8080

  # Build a patch
  quicui-compiler build old.kernel new.kernel \\
    --version=1.0.1 \\
    --description="Bug fix release"

  # Upload to service
  quicui-compiler upload 1.0.1 \\
    --service-url=https://api.quicui.com \\
    --app-id=com.example.app

  # Rollout patch gradually
  quicui-compiler rollout 1.0.1 \\
    --service-url=https://api.quicui.com \\
    --app-id=com.example.app \\
    --percentage=10

  # Generate signing keys
  quicui-compiler keygen

  # List available versions
  quicui-compiler version list \\
    --service-url=https://api.quicui.com \\
    --app-id=com.example.app

  # Verify patch signature
  quicui-compiler verify patch.bin key.pub manifest.json

OPTIONS:
  --help, -h              Show this help message
  --version, -v           Show version information
  --output-dir=DIR        Output directory (./.quicui)
  --service-url=URL       Code push service URL
  --app-id=ID             Application ID
  --version=VERSION       Patch version
  --description=TEXT      Patch description
  --percentage=NUM        Rollout percentage (0-100)
  --critical              Mark as critical patch/rollout
  --environment=ENV       Target environment
  --auth-token=TOKEN      Authentication token

DOCUMENTATION:
  For more information, visit: https://quicui.com/docs/compiler

For help with a specific command:
  quicui-compiler <command> --help
''');
}

/// Format bytes into human-readable string
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(2)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

/// Compress patch file using specified algorithm
/// Returns true if compression successful
Future<bool> _compressPatch(String patchPath, String algorithm) async {
  try {
    final patchFile = File(patchPath);
    if (!await patchFile.exists()) {
      print('❌ Patch file not found: $patchPath');
      return false;
    }

    print('🗜️  Compressing patch with $algorithm...');

    // Use system compression tools for better performance and compression
    String command;
    String extension;

    switch (algorithm.toLowerCase()) {
      case 'gzip':
      case 'gz':
        command = 'gzip';
        extension = 'gz';
        break;

      case 'bzip2':
      case 'bz2':
        command = 'bzip2';
        extension = 'bz2';
        break;

      case 'xz':
        command = 'xz';
        extension = 'xz';
        break;

      default:
        print('❌ Unknown compression algorithm: $algorithm');
        return false;
    }

    final originalSize = await patchFile.length();

    // Run compression command
    final result = await Process.run(
      command,
      ['-9', '-k', '-f', patchPath],  // -9: max compression, -k: keep original, -f: force
      workingDirectory: patchFile.parent.path,
    );

    if (result.exitCode != 0) {
      print('❌ Compression failed: ${result.stderr}');
      return false;
    }

    // Check compressed file
    final compressedFile = File('$patchPath.$extension');
    if (!await compressedFile.exists()) {
      print('❌ Compressed file not found');
      return false;
    }

    final compressedSize = await compressedFile.length();
    final reduction = (1 - compressedSize / originalSize) * 100;

    print('✅ Compressed: ${_formatBytes(originalSize)} → ${_formatBytes(compressedSize)} (${reduction.toStringAsFixed(2)}% reduction)');
    print('   Output: ${compressedFile.path}');

    return true;
  } catch (e) {
    print('❌ Compression error: $e');
    return false;
  }
}

/// Decompress patch file if compressed
/// Returns the path to the decompressed file (or original if not compressed)
Future<String> _decompressPatch(String patchPath) async {
  final patchFile = File(patchPath);
  if (!await patchFile.exists()) {
    throw Exception('Patch file not found: $patchPath');
  }

  final extension = patchPath.split('.').last.toLowerCase();
  
  // Check if file is compressed
  if (!['gz', 'bz2', 'xz'].contains(extension)) {
    // Not compressed, return original path
    return patchPath;
  }

  print('🗜️  Decompressing patch...');

  // Determine decompression command
  String command;
  switch (extension) {
    case 'gz':
      command = 'gunzip';
      break;
    case 'bz2':
      command = 'bunzip2';
      break;
    case 'xz':
      command = 'unxz';
      break;
    default:
      throw Exception('Unknown compression format: $extension');
  }

  final compressedSize = await patchFile.length();
  
  // Decompress (keep original with -k flag)
  final result = await Process.run(
    command,
    ['-k', '-f', patchPath],  // -k: keep original, -f: force
    workingDirectory: patchFile.parent.path,
  );

  if (result.exitCode != 0) {
    throw Exception('Decompression failed: ${result.stderr}');
  }

  // Get decompressed file path (remove compression extension)
  final decompressedPath = patchPath.substring(0, patchPath.lastIndexOf('.'));
  final decompressedFile = File(decompressedPath);
  
  if (!await decompressedFile.exists()) {
    throw Exception('Decompressed file not found: $decompressedPath');
  }

  final decompressedSize = await decompressedFile.length();

  print('✅ Decompressed: ${_formatBytes(compressedSize)} → ${_formatBytes(decompressedSize)}');
  print('   Output: $decompressedPath');

  return decompressedPath;
}
