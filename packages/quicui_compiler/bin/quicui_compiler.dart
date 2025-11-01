import 'dart:io';

import 'package:quicui_compiler/src/cli_commands.dart';
import 'package:quicui_compiler/src/bsdiff.dart';

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
    print('');
    print('Arguments:');
    print('  <old-file>                 Path to old snapshot file');
    print('  <new-file>                 Path to new snapshot file');
    print('');
    print('Options:');
    print('  --output=FILE              Output patch file path');
    print('                             (default: patch.quicui)');
    print('');
    print('Example:');
    print('  quicui-compiler diff app_v1.0.0.so app_v1.0.1.so --output=patch_1.0.1.quicui');
    return;
  }

  final oldFile = args[0];
  final newFile = args[1];
  final options = _parseOptions(args.sublist(2));

  final outputFile = options['output'] as String? ?? 'patch.quicui';

  print('');
  print('🔧 QuicUI Binary Diff');
  print('═' * 60);
  print('Old file: $oldFile');
  print('New file: $newFile');
  print('Output:   $outputFile');
  print('═' * 60);
  print('');

  try {
    final patch = await BsDiff.generatePatch(
      oldFile,
      newFile,
      outputPath: outputFile,
    );

    print('');
    print('✅ Patch generated successfully!');
    print('');
    print('Patch Statistics:');
    print('  Old size:        ${_formatBytes(patch.oldSize)}');
    print('  New size:        ${_formatBytes(patch.newSize)}');
    print('  Patch size:      ${_formatBytes(patch.patchSize)}');
    print('  Compression:     ${patch.compressionRatio.toStringAsFixed(2)}%');
    print('  Operations:      ${patch.operations.length}');
    print('');
    print('Old hash: ${patch.oldHash}');
    print('New hash: ${patch.newHash}');
    print('');
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
    print('');
    print('Arguments:');
    print('  <old-file>                 Path to old snapshot file');
    print('  <patch-file>               Path to patch file (.quicui)');
    print('  <new-file>                 Path to output new snapshot file');
    print('');
    print('Example:');
    print('  quicui-compiler patch app_v1.0.0.so patch_1.0.1.quicui app_v1.0.1.so');
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
    await BsDiff.applyPatch(oldFile, patchFile, newFile);

    print('');
    print('✅ Patch applied successfully!');
    print('');
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

EXAMPLES:
  # Generate binary diff patch
  quicui-compiler diff old.so new.so --output=patch.quicui

  # Apply binary patch
  quicui-compiler patch old.so patch.quicui new.so

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
