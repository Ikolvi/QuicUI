import 'dart:io';
import 'dart:convert';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import '../services/flutter_service.dart';
import '../services/app_extractor_service.dart';
import '../config/cli_config.dart';

/// Command to build iOS app and extract App binary
class BuildIpaCommand extends Command {
  @override
  final name = 'build-ipa';
  
  @override
  final description = 'Build iOS release app with code signing and extract App binary';

  BuildIpaCommand() {
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
        help: 'Output directory for app and App binary',
      )
      ..addOption(
        'build-number',
        help: 'Build number (e.g., 14)',
      )
      ..addFlag(
        'baseline',
        abbr: 'b',
        help: 'Mark this as a baseline version',
        negatable: false,
      );
  }

  @override
  Future<void> run() async {
    final version = argResults!['version'] as String;
    final projectPath = argResults!['project'] as String;
    final buildNumber = argResults!['build-number'] as String?;
    final isBaseline = argResults!['baseline'] as bool;
    
    print('');
    print('🔨 QuicUI iOS Builder');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('Version:      $version');
    print('Project:      $projectPath');
    print('Platform:     iOS (arm64)');
    print('Type:         ${isBaseline ? "Baseline" : "New Version"}');
    print('');

    final config = await CliConfig.load(projectPath);
    final flutterService = FlutterService(config);
    final extractorService = AppExtractorService();

    // Determine output directory
    final outputDir = argResults!['output'] as String? ?? 
                      p.join(projectPath, isBaseline ? 'baseline' : 'v$version');
    await Directory(outputDir).create(recursive: true);

    try {
      // Step 1: Build iOS app
      print('📦 Building iOS app...');
      final appPath = await flutterService.buildIos(
        projectPath: projectPath,
        version: version,
        buildNumber: buildNumber,
      );
      print('   ✅ iOS app built: $appPath');
      print('');

      // Step 2: Extract App binary
      print('📂 Extracting App binary...');
      final appBinaryPath = await extractorService.extractApp(
        appPath: appPath,
        outputDir: outputDir,
        version: version,
      );
      print('   ✅ Extracted: $appBinaryPath');
      print('');

      // Step 3: Extract app.dill (Dart kernel) for .vmcode patch generation
      print('📝 Extracting Dart kernel for .vmcode generation...');
      final appDillDest = p.join(outputDir, 'app.dill');
      
      // app.dill is generated during flutter build in .dart_tool/flutter_build/
      // Find the most recent app.dill
      final dartToolPath = p.join(projectPath, '.dart_tool', 'flutter_build');
      final dartToolDir = Directory(dartToolPath);
      
      if (await dartToolDir.exists()) {
        final buildDirs = await dartToolDir.list().toList();
        File? latestAppDill;
        DateTime? latestTime;
        
        for (final dir in buildDirs) {
          if (dir is Directory) {
            final dillFile = File(p.join(dir.path, 'app.dill'));
            if (await dillFile.exists()) {
              final modified = await dillFile.lastModified();
              if (latestTime == null || modified.isAfter(latestTime)) {
                latestTime = modified;
                latestAppDill = dillFile;
              }
            }
          }
        }
        
        if (latestAppDill != null) {
          await latestAppDill.copy(appDillDest);
          final dillSize = await File(appDillDest).length();
          print('   ✅ Extracted app.dill: ${(dillSize / 1024 / 1024).toStringAsFixed(2)} MB');
          print('   💡 This kernel will be used for .vmcode generation');
        } else {
          print('   ⚠️  app.dill not found in .dart_tool/flutter_build/');
          print('   ⚠️  .vmcode patch generation will fail');
        }
      } else {
        print('   ⚠️  .dart_tool/flutter_build/ not found');
        print('   ⚠️  .vmcode patch generation will require app.dill');
      }
      print('');

      // Step 4: Store metadata
      final appDillPath = p.join(outputDir, 'app.dill');
      final metadata = {
        'version': version,
        'platform': 'ios',
        'architecture': 'arm64',
        'isBaseline': isBaseline,
        'appBinaryPath': p.basename(appBinaryPath),  // Relative path
        'appDillPath': await File(appDillPath).exists() ? 'app.dill' : null,  // Relative path
        'timestamp': DateTime.now().toIso8601String(),
      };

      final metadataFile = File(p.join(outputDir, 'metadata.json'));
      await metadataFile.writeAsString(
        JsonEncoder.withIndent('  ').convert(metadata),
      );

      print('✅ Build Complete!');
      print('');
      print('📋 Output:');
      print('   App:      $appPath');
      print('   Binary:   $appBinaryPath');
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
      
      print('📱 To install on iOS device:');
      print('   xcrun devicectl device install app --device <DEVICE_ID> $appPath');
      print('   (Use: xcrun devicectl list devices)');
      print('');
    } catch (e) {
      print('');
      print('❌ Error: $e');
      exit(1);
    }
  }
}
