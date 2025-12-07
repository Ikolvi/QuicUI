import 'dart:io';
import 'dart:convert';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import '../services/flutter_service.dart';
import '../services/apk_extractor_service.dart';
import '../config/cli_config.dart';

/// Command to build APK and extract libapp.so
class BuildApkCommand extends Command {
  @override
  final name = 'build-apk';
  
  @override
  final description = 'Build APK and extract libapp.so for baseline or new version';

  BuildApkCommand() {
    argParser
      ..addOption(
        'version',
        abbr: 'v',
        help: 'Version number (e.g., 1.0.0)',
        mandatory: true,
      )
      ..addOption(
        'project',
        abbr: 'p',
        help: 'Path to Flutter project',
        defaultsTo: '.',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Output directory for APK and libapp.so',
      )
      ..addFlag(
        'baseline',
        abbr: 'b',
        help: 'Mark this as a baseline version',
        negatable: false,
      )
      ..addOption(
        'architecture',
        abbr: 'a',
        help: 'Target architecture',
        defaultsTo: 'arm64-v8a',
        allowed: ['arm64-v8a', 'armeabi-v7a', 'x86', 'x86_64'],
      );
  }

  @override
  Future<void> run() async {
    final version = argResults!['version'] as String;
    final projectPath = argResults!['project'] as String;
    final architecture = argResults!['architecture'] as String;
    final isBaseline = argResults!['baseline'] as bool;
    
    print('');
    print('🔨 QuicUI APK Builder');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Version:      $version');
    print('Project:      $projectPath');
    print('Architecture: $architecture');
    print('Type:         ${isBaseline ? "Baseline" : "New Version"}');
    print('');

    final config = await CliConfig.load(projectPath);
    final flutterService = FlutterService(config);
    final extractorService = ApkExtractorService();

    // Determine output directory
    final outputDir = argResults!['output'] as String? ?? 
                      p.join(projectPath, isBaseline ? 'baseline' : 'v$version');
    await Directory(outputDir).create(recursive: true);

    try {
      // Step 1: Build APK
      print('📦 Building APK...');
      final apkPath = await flutterService.buildApk(
        projectPath: projectPath,
        version: version,
        architecture: architecture,
      );
      print('   ✅ APK built: $apkPath');
      print('');

      // Step 2: Copy APK to output directory
      final apkOutputPath = p.join(outputDir, 'app-v$version.apk');
      await File(apkPath).copy(apkOutputPath);
      print('📁 APK saved: $apkOutputPath');
      print('');

      // Step 3: Extract libapp.so
      print('📂 Extracting libapp.so...');
      final libappPath = await extractorService.extractLibapp(
        apkPath: apkOutputPath,
        architecture: architecture,
        outputDir: outputDir,
      );
      print('   ✅ Extracted: $libappPath');
      print('');

      // Step 4: Store metadata
      final metadata = {
        'version': version,
        'architecture': architecture,
        'isBaseline': isBaseline,
        'apkPath': apkOutputPath,
        'libappPath': libappPath,
        'timestamp': DateTime.now().toIso8601String(),
        'appId': config.appId,
      };

      final metadataFile = File(p.join(outputDir, 'metadata.json'));
      await metadataFile.writeAsString(
        JsonEncoder.withIndent('  ').convert(metadata),
      );

      print('✅ Build Complete!');
      print('');
      print('📋 Output:');
      print('   APK:      $apkOutputPath');
      print('   libapp:   $libappPath');
      print('   Metadata: ${metadataFile.path}');
      print('');

      if (isBaseline) {
        print('💡 This is a baseline version.');
        print('   Use this as the base for generating patches.');
      } else {
        print('💡 Next steps:');
        print('   1. Upload baseline: quicui upload-baseline');
        print('   2. Generate patch: quicui generate-patch --from baseline --to v$version');
        print('   3. Upload patch: quicui upload-patch');
      }
      print('');
    } catch (e) {
      print('');
      print('❌ Error: $e');
      exit(1);
    }
  }
}
