import 'dart:io';

import 'package:quicui_compiler/src/cli_commands.dart';
import 'package:quicui_compiler/src/kernel_analysis.dart';

/// QuicUI Code Push Compiler - Main CLI Entry Point
/// 
/// Usage:
///   quicui-compiler build <old-kernel> <new-kernel> --version=1.0.1
///   quicui-compiler upload <patch-version> --service-url=https://api.quicui.dev
///   quicui-compiler rollout <patch-version> --percentage=10
///   quicui-compiler version list --service-url=https://api.quicui.dev
///   quicui-compiler keygen
///   quicui-compiler verify <patch-file> <key-file> <manifest-file>

void main(List<String> arguments) async {
  // Parse command line arguments
  if (arguments.isEmpty) {
    _printUsage();
    exit(1);
  }

  final command = arguments[0];
  final args = arguments.sublist(1);

  try {
    switch (command) {
      case 'build':
        await _handleBuild(args);
        break;

      case 'upload':
        await _handleUpload(args);
        break;

      case 'rollout':
        await _handleRollout(args);
        break;

      case 'version':
        await _handleVersion(args);
        break;

      case 'keygen':
        await _handleKeyGen(args);
        break;

      case 'verify':
        await _handleVerify(args);
        break;

      case '--help':
      case '-h':
        _printUsage();
        break;

      case '--version':
      case '-v':
        print('QuicUI Code Push Compiler v1.0.0');
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
QuicUI Code Push Compiler v1.0.0
Patch compilation, signing, and deployment tool

USAGE:
  quicui-compiler <command> [options]

COMMANDS:
  build       Build a new patch from kernel files
  upload      Upload patch to code push service
  rollout     Deploy patch to users
  version     Manage patch versions
  keygen      Generate signing key pair
  verify      Verify patch signature

EXAMPLES:
  # Build a patch
  quicui-compiler build old.kernel new.kernel \\
    --version=1.0.1 \\
    --description="Bug fix release"

  # Upload to service
  quicui-compiler upload 1.0.1 \\
    --service-url=https://api.quicui.dev \\
    --app-id=com.example.app

  # Rollout patch gradually
  quicui-compiler rollout 1.0.1 \\
    --service-url=https://api.quicui.dev \\
    --app-id=com.example.app \\
    --percentage=10

  # Generate signing keys
  quicui-compiler keygen

  # List available versions
  quicui-compiler version list \\
    --service-url=https://api.quicui.dev \\
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
  For more information, visit: https://quicui.dev/docs/compiler

For help with a specific command:
  quicui-compiler <command> --help
''');
}
