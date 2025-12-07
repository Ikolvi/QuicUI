import 'dart:io';
import 'package:args/command_runner.dart';
import '../services/engine_service.dart';

/// Command to download/update QuicUI Flutter SDK
class EngineCommand extends Command<void> {
  @override
  final name = 'engine';

  @override
  final description = 'Manage QuicUI Flutter SDK (download, update, status)';

  EngineCommand() {
    addSubcommand(_EngineDownloadCommand());
    addSubcommand(_EngineStatusCommand());
    addSubcommand(_EngineCleanCommand());
  }

  @override
  void run() {
    printUsage();
  }
}

class _EngineDownloadCommand extends Command<void> {
  @override
  final name = 'download';

  @override
  final description = 'Download QuicUI Flutter SDK from GitHub';

  _EngineDownloadCommand() {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Force re-download even if cached',
      defaultsTo: false,
    );
  }

  @override
  Future<void> run() async {
    final force = argResults?['force'] as bool? ?? false;
    
    print('🔧 QuicUI SDK Manager');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    await EngineService.downloadSdk(force: force);
    
    print('\n✅ QuicUI Flutter SDK ready at: ${EngineService.sdkCacheDir}');
    print('   Flutter: ${EngineService.flutterPath}');
  }
}

class _EngineStatusCommand extends Command<void> {
  @override
  final name = 'status';

  @override
  final description = 'Check QuicUI Flutter SDK status';

  @override
  Future<void> run() async {
    print('🔧 QuicUI SDK Status');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    
    // Check local development engine
    final localEngine = await EngineService.getLocalEnginePath();
    if (localEngine != null) {
      print('🔨 Local development engine: $localEngine');
    } else {
      print('🔨 Local development engine: Not found');
    }
    
    // Check cached SDK
    final isCached = await EngineService.isSdkCached();
    print('\n📦 Cached QuicUI Flutter SDK:');
    print('   Status: ${isCached ? "✅ Installed" : "❌ Not installed"}');
    print('   Location: ${EngineService.sdkCacheDir}');
    
    if (isCached) {
      print('   Flutter: ${EngineService.flutterPath}');
    }
    
    // Check QuicUI Maven repository
    final mavenDir = Directory(EngineService.quicuiMavenDir);
    final mavenExists = await mavenDir.exists();
    print('\n📚 QuicUI Maven Repository (isolated):');
    print('   Status: ${mavenExists ? "✅ Configured" : "❌ Not configured"}');
    print('   Location: ${EngineService.quicuiMavenDir}');
    print('   Note: Does NOT affect system Flutter or ~/.m2');
    
    print('\n💡 To download/update SDK: quicui engine download');
  }
}

class _EngineCleanCommand extends Command<void> {
  @override
  final name = 'clean';

  @override
  final description = 'Remove cached QuicUI Flutter SDK';

  @override
  Future<void> run() async {
    print('🧹 Cleaning cached QuicUI Flutter SDK...');
    
    final cacheDir = Directory(EngineService.sdkCacheDir);
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
      print('✅ Cached SDK removed from: ${EngineService.sdkCacheDir}');
    } else {
      print('ℹ️  No cached SDK found');
    }
  }
}
