import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import '../config/cli_config.dart';
import '../services/flutter_service.dart';

/// Command to build Android App Bundle (AAB) with QuicUI engine
class BuildAabCommand extends Command {
  @override
  final name = 'build-aab';
  
  @override
  final description = 'Build Android App Bundle (AAB) with QuicUI engine (includes all architectures)';

  BuildAabCommand() {
    argParser
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
    final verbose = argResults!['verbose'] as bool;

    projectPath = p.normalize(p.absolute(projectPath));

    print('');
    print('🏗️  QuicUI Build AAB');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');

    try {
      // Load config
      final config = await CliConfig.load(projectPath);
      final version = await _getVersionFromPubspec(projectPath);
      
      print('📋 Build Info:');
      print('   App ID:   ${config.appId}');
      print('   Version:  $version');
      print('   Format:   Android App Bundle (AAB)');
      print('   Archs:    arm64-v8a, armeabi-v7a, x86_64');
      print('');

      // Build AAB
      print('📦 Building AAB (this may take a few minutes)...');
      final flutterService = FlutterService(config);
      final aabPath = await flutterService.buildAab(
        projectPath: projectPath,
        version: version,
      );
      
      // Verify output
      final aabFile = File(aabPath);
      if (!await aabFile.exists()) {
        throw Exception('AAB file not found at: $aabPath');
      }
      
      final aabSize = await aabFile.length();
      
      print('');
      print('═══════════════════════════════════════════');
      print('✅ Build Complete!');
      print('');
      print('📦 Output:');
      print('   Path: $aabPath');
      print('   Size: ${(aabSize / 1024 / 1024).toStringAsFixed(2)} MB');
      print('');
      print('💡 Next steps:');
      print('   1. Upload to Google Play Console');
      print('   2. Or use: quicui release --format aab');
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
}
