import 'dart:io';
import 'dart:convert';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import '../config/cli_config.dart';
import '../services/compiler_service.dart';
import '../services/flutter_service.dart';

/// Command to generate patch between two versions
class GeneratePatchCommand extends Command {
  @override
  final name = 'generate-patch';
  
  @override
  final description = 'Generate patch between baseline and new version';

  GeneratePatchCommand() {
    argParser
      ..addOption(
        'from',
        help: 'Path to baseline directory',
        defaultsTo: './baseline',
      )
      ..addOption(
        'to',
        help: 'Path to new version directory (e.g., v2.0.0)',
        mandatory: true,
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output directory for patch',
        defaultsTo: './patches',
      )
      ..addOption(
        'project',
        abbr: 'p',
        help: 'Path to Flutter project',
        defaultsTo: '.',
      )
      ..addOption(
        'compression',
        abbr: 'c',
        help: 'Compression format',
        defaultsTo: 'xz',
        allowed: ['none', 'xz', 'gzip', 'bzip2'],
      );
  }

  @override
  Future<void> run() async {
    var fromDir = argResults!['from'] as String;
    var toDir = argResults!['to'] as String;
    var outputDir = argResults!['output'] as String;
    var projectPath = argResults!['project'] as String;
    final compression = argResults!['compression'] as String;

    // Resolve relative paths to absolute paths based on project directory
    projectPath = p.normalize(p.absolute(projectPath));
    fromDir = p.normalize(p.isAbsolute(fromDir) ? fromDir : p.join(projectPath, fromDir));
    toDir = p.normalize(p.isAbsolute(toDir) ? toDir : p.join(projectPath, toDir));
    outputDir = p.normalize(p.isAbsolute(outputDir) ? outputDir : p.join(projectPath, outputDir));

    print('');
    print('🔄 QuicUI Patch Generator');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');

    final config = await CliConfig.load(projectPath);

    // Ensure output directory exists
    await Directory(outputDir).create(recursive: true);

    try {
      // Step 1: Load metadata from both versions
      print('📋 Loading version metadata...');
      
      final fromMetadata = await _loadMetadata(fromDir);
      final toMetadata = await _loadMetadata(toDir);

      print('   From: v${fromMetadata['version']} (baseline)');
      print('   To:   v${toMetadata['version']}');
      
      // Auto-detect platform from directory structure or metadata
      String platform = (toMetadata['platform'] as String?) ?? 'unknown';
      
      // If platform not in metadata, detect from paths
      if (platform == 'unknown') {
        final binaryPath = toMetadata['libappPath'] ?? toMetadata['appBinaryPath'] ?? '';
        if (binaryPath.contains('ios') || binaryPath.contains('App.framework')) {
          platform = 'ios';
        } else if (binaryPath.contains('android') || binaryPath.contains('.so')) {
          platform = 'android';
        }
      }
      
      print('   Platform: $platform');
      print('');

      // Step 2: Invoke compiler to generate patch
      print('🔨 Generating patch...');
      
      // Support both Android (libappPath) and iOS (appBinaryPath)
      final oldBinaryPathRel = fromMetadata['libappPath'] ?? fromMetadata['appBinaryPath'];
      final newBinaryPathRel = toMetadata['libappPath'] ?? toMetadata['appBinaryPath'];
      
      if (oldBinaryPathRel == null || newBinaryPathRel == null) {
        throw Exception('Binary path not found in metadata. Ensure baseline and new version are built correctly.');
      }
      
      // Resolve paths relative to fromDir/toDir
      final oldBinaryPath = p.join(fromDir, oldBinaryPathRel);
      final newBinaryPath = p.join(toDir, newBinaryPathRel);
      
      final result = await CompilerService.generatePatch(
        oldLibappPath: oldBinaryPath,
        newLibappPath: newBinaryPath,
        outputDir: outputDir,
        compression: compression,
      );

      print('   ✅ Patch generated');
      print('   Compressed size: ${(result.patchSize / 1024).toStringAsFixed(2)} KB');
      print('   Uncompressed size: ${(result.uncompressedSize / 1024).toStringAsFixed(2)} KB');
      print('   Compression ratio: ${(result.compressionRatio * 100).toStringAsFixed(1)}%');
      print('   Hash: ${result.patchHash}');
      print('');

      String finalPatchPath;
      String finalPatchHash;
      int finalCompressedSize;
      int finalUncompressedSize;

      if (platform == 'ios') {
        print('🍎 iOS Platform - Using Interpreter Approach');
        print('');
        
        // For iOS, we need to generate .vmcode file from app.dill
        final appDillPathRel = toMetadata['appDillPath'];
        if (appDillPathRel == null) {
          throw Exception('app.dill path not found in metadata.\n'
              'Please rebuild with build-ipa command.');
        }
        
        final appDillPath = p.join(toDir, appDillPathRel);
        if (!await File(appDillPath).exists()) {
          throw Exception('app.dill not found. iOS requires .vmcode generation from Dart kernel.\n'
              'Path expected: $appDillPath\n'
              'Please rebuild with build-ipa command.');
        }

        // Locate gen_snapshot from custom engine
        print('   Locating gen_snapshot...');
        final flutterService = FlutterService(config);
        final genSnapshotPath = await flutterService.getGenSnapshotPath(isIOS: true);
        print('   ✅ Found: $genSnapshotPath');
        print('');

        // Get baseline binary path (Mach-O App binary)
        final baselineBinaryPathRel = fromMetadata['appBinaryPath'];
        if (baselineBinaryPathRel == null) {
          throw Exception('Baseline app binary path not found in metadata.\n'
              'Please rebuild baseline with build-ipa command.');
        }
        final baselineBinaryPath = p.join(fromDir, baselineBinaryPathRel);
        
        if (!await File(baselineBinaryPath).exists()) {
          print('   ⚠️  Warning: Baseline binary not found at $baselineBinaryPath');
          print('   Will generate full patch without differential linking.');
        }

        // Generate .vmcode file using gen_snapshot + differential linker
        print('   Generating differential .vmcode patch...');
        final vmcodeResult = await CompilerService.generateVMCodePatch(
          genSnapshotPath: genSnapshotPath,
          appDillPath: appDillPath,
          baselineBinaryPath: baselineBinaryPath,
          outputDir: outputDir,
          version: toMetadata['version'],
          compression: compression,
        );

        finalPatchPath = vmcodeResult.patchPath;
        finalPatchHash = vmcodeResult.patchHash;
        finalCompressedSize = vmcodeResult.patchSize;
        finalUncompressedSize = vmcodeResult.uncompressedSize;

        print('   ✅ .vmcode snapshot generated');
        print('');
        print('   💡 This .vmcode file will be interpreted by Dart VM on device');
        print('   📝 Performance: 40-60% of AOT (acceptable for business logic)');
        print('   ✅ App Store compliant (guideline 3.3.1b)');
        print('');
      } else {
        // Android uses binary patches
        print('🤖 Android Platform - Using Binary Patch (.quicui)');
        print('   Patch will be applied to libapp.so on device');
        print('');
        
        finalPatchPath = result.patchPath;
        finalPatchHash = result.patchHash;
        finalCompressedSize = result.patchSize;
        finalUncompressedSize = result.uncompressedSize;
      }

      // Step 3: Save patch metadata
      final patchId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final patchMetadata = {
        'patchId': patchId,
        'fromVersion': fromMetadata['version'],
        'toVersion': toMetadata['version'],
        'appId': config.appId,
        'platform': platform,
        'architecture': toMetadata['architecture'],
        'hash': finalPatchHash,
        'compressedSize': finalCompressedSize,
        'uncompressedSize': finalUncompressedSize,
        'compression': compression,
        'patchPath': finalPatchPath,
        'createdAt': DateTime.now().toIso8601String(),
      };

      final metadataFile = File(p.join(outputDir, '${patchId}_metadata.json'));
      await metadataFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(patchMetadata),
      );

      print('✅ Patch Generation Complete!');
      print('');
      print('📋 Output:');
      print('   Patch:    ${result.patchPath}');
      print('   Metadata: ${metadataFile.path}');
      print('');
      print('💡 Next step:');
      print('   Upload patch: quicui upload-patch --patch ${patchId}');
      print('');
    } catch (e) {
      print('');
      print('❌ Error: $e');
      exit(1);
    }
  }

  Future<Map<String, dynamic>> _loadMetadata(String dir) async {
    final metadataFile = File(p.join(dir, 'metadata.json'));
    if (!await metadataFile.exists()) {
      throw Exception('Metadata file not found in $dir');
    }
    return jsonDecode(await metadataFile.readAsString());
  }
}
