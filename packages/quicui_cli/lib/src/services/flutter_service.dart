import 'dart:io';
import 'package:path/path.dart' as p;
import '../config/cli_config.dart';
import 'engine_service.dart';

/// Flutter build service
class FlutterService {
  final CliConfig config;

  FlutterService(this.config);

  Future<String> buildApk({
    required String projectPath,
    required String version,
    required String architecture,
  }) async {
    // Get QuicUI Flutter SDK (downloads if needed)
    final flutterPath = await EngineService.ensureSdk(projectPath: projectPath);
    print('✅ Using QuicUI Flutter SDK: $flutterPath');
    
    // Convert architecture format: arm64-v8a -> android-arm64, armeabi-v7a -> android-arm
    String targetPlatform;
    if (architecture == 'arm64-v8a') {
      targetPlatform = 'android-arm64';
    } else if (architecture == 'armeabi-v7a') {
      targetPlatform = 'android-arm';
    } else if (architecture == 'x86_64') {
      targetPlatform = 'android-x64';
    } else if (architecture == 'x86') {
      targetPlatform = 'android-x86';
    } else {
      targetPlatform = 'android-arm64'; // default
    }
    
    // Build arguments
    final args = [
      'build',
      'apk',
      '--release',
      '--target-platform',
      targetPlatform,
      '--no-tree-shake-icons',  // Skip icon tree shaking (const_finder not available)
    ];
    
    // Check for local development engine (for dev builds with --local-engine)
    final localEnginePath = await EngineService.getLocalEnginePath();
    
    if (localEnginePath != null) {
      // Use local development engine (for faster iteration during development)
      final hostEnginePath = '$localEnginePath/out/host_release';
      final androidEnginePath = 'android_release_arm64';
      
      print('🚀 Using local development engine');
      print('   Engine source: $localEnginePath');
      
      args.addAll([
        '--local-engine-src-path=$localEnginePath',
        '--local-engine=$androidEnginePath',
        '--local-engine-host=$hostEnginePath',
      ]);
    }
    // Note: When using cached QuicUI SDK from GitHub, the engine is already embedded
    
    print('📦 Running: flutter ${args.join(' ')}');
    
    // Run flutter build apk
    final result = await Process.run(
      flutterPath,
      args,
      workingDirectory: projectPath,
    );

    if (result.exitCode != 0) {
      throw Exception('Flutter build failed: ${result.stderr}');
    }

    return p.join(projectPath, 'build', 'app', 'outputs', 'flutter-apk', 'app-release.apk');
  }

  /// Build Android App Bundle (AAB) - includes all architectures
  Future<String> buildAab({
    required String projectPath,
    required String version,
  }) async {
    // Get QuicUI Flutter SDK (downloads if needed)
    final flutterPath = await EngineService.ensureSdk(projectPath: projectPath);
    print('✅ Using QuicUI Flutter SDK: $flutterPath');
    
    // Build arguments - AAB includes all architectures by default
    final args = [
      'build',
      'appbundle',
      '--release',
      '--no-tree-shake-icons',  // Skip icon tree shaking (const_finder not available)
    ];
    
    // Check for local development engine (for dev builds with --local-engine)
    final localEnginePath = await EngineService.getLocalEnginePath();
    
    if (localEnginePath != null) {
      // Use local development engine (for faster iteration during development)
      final hostEnginePath = '$localEnginePath/out/host_release';
      final androidEnginePath = 'android_release_arm64';
      
      print('🚀 Using local development engine');
      print('   Engine source: $localEnginePath');
      
      args.addAll([
        '--local-engine-src-path=$localEnginePath',
        '--local-engine=$androidEnginePath',
        '--local-engine-host=$hostEnginePath',
      ]);
    }
    // Note: When using cached QuicUI SDK from GitHub, the engine is already embedded
    
    print('📦 Running: flutter ${args.join(' ')}');
    
    // Run flutter build appbundle
    final result = await Process.run(
      flutterPath,
      args,
      workingDirectory: projectPath,
    );

    if (result.exitCode != 0) {
      throw Exception('Flutter build failed: ${result.stderr}');
    }

    return p.join(projectPath, 'build', 'app', 'outputs', 'bundle', 'release', 'app-release.aab');
  }

  Future<String> buildIos({
    required String projectPath,
    required String version,
    String? buildNumber,
  }) async {
    // Use custom QuicUI SDK from forks/flutter-quicui
    final customSdkPath = p.join(projectPath, '..', '..', 'forks', 'flutter-quicui');
    final customFlutterPath = p.absolute(p.join(customSdkPath, 'bin', 'flutter'));
    
    if (!await File(customFlutterPath).exists()) {
      throw Exception('Custom QuicUI SDK not found at: $customFlutterPath');
    }
    
    print('✅ Using custom QuicUI SDK: $customFlutterPath');
    
    // Resolve absolute project path
    final absoluteProjectPath = p.absolute(projectPath);
    
    // Clean before building to avoid Xcode cache issues with custom engine
    print('🧹 Cleaning project and Xcode cache...');
    
    // Clean ALL Xcode derived data (more aggressive)
    final homeDir = Platform.environment['HOME']!;
    await Process.run('rm', ['-rf', '$homeDir/Library/Developer/Xcode/DerivedData'], runInShell: true);
    
    // Clean pod cache
    final podCachePath = p.join(absoluteProjectPath, 'ios', 'Pods');
    if (await Directory(podCachePath).exists()) {
      await Process.run('rm', ['-rf', podCachePath], runInShell: true);
    }
    
    // Clean flutter
    final cleanResult = await Process.run(
      customFlutterPath,
      ['clean'],
      workingDirectory: absoluteProjectPath,
      runInShell: true,
    );
    
    if (cleanResult.exitCode != 0) {
      print('⚠️  Clean failed, continuing anyway...');
    }
    
    print('   ✅ Cleaned successfully');
    
    // Build arguments
    final args = [
      'build',
      'ios',
      '--release',
      '--no-tree-shake-icons',  // Skip icon tree shaking (const_finder may not be available)
    ];
    
    // Add build name and number if provided
    if (buildNumber != null) {
      args.addAll(['--build-number=$buildNumber']);
      args.addAll(['--build-name=$version']);
      print('📋 Build name: $version, Build number: $buildNumber');
    }
    
    // Use local engine for QuicUI builds ONLY if QUICUI_USE_LOCAL_ENGINE=1
    final engineSrcPath = '/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src';
    final iosEnginePath = 'ios_release';
    final hostEnginePath = 'host_release';
    
    final useLocalEngine = Platform.environment['QUICUI_USE_LOCAL_ENGINE'] == '1';
    
    if (useLocalEngine && await Directory(engineSrcPath).exists()) {
      print('🚀 Using custom QuicUI engine (local-engine)');
      print('   Engine source: $engineSrcPath');
      print('   iOS engine: $iosEnginePath');
      print('   Host engine: $hostEnginePath');
      
      args.addAll([
        '--local-engine-src-path=$engineSrcPath',
        '--local-engine=$iosEnginePath',
        '--local-engine-host=$hostEnginePath',
      ]);
    } else {
      print('📦 Using standard Flutter SDK (no local engine)');
    }
    
    print('📦 Running: flutter ${args.join(' ')}');
    print('📁 Working directory: $absoluteProjectPath');
    
    // Pre-copy missing headers to work around Flutter local-engine bug
    final buildFlutterFramework = p.join(absoluteProjectPath, 'build', 'ios', 'Release-iphoneos', 'Flutter.framework');
    final buildHeadersDir = p.join(buildFlutterFramework, 'Headers');
    if (await Directory(engineSrcPath).exists()) {
      await Directory(buildHeadersDir).create(recursive: true);
      final sourceHeaders = p.join(engineSrcPath, 'out', iosEnginePath, 'Flutter.framework', 'Headers');
      
      // Copy critical headers that Flutter build sometimes misses
      for (final header in ['Flutter.h', 'FlutterAppDelegate.h']) {
        final source = p.join(sourceHeaders, header);
        final dest = p.join(buildHeadersDir, header);
        if (await File(source).exists()) {
          await File(source).copy(dest);
        }
      }
    }
    
    // Run flutter build ios
    final result = await Process.run(
      customFlutterPath,
      args,
      workingDirectory: absoluteProjectPath,
      runInShell: true,
    );

    if (result.exitCode != 0) {
      print('📤 STDOUT: ${result.stdout}');
      print('📤 STDERR: ${result.stderr}');
      throw Exception('Flutter build failed: ${result.stderr}');
    }

    return p.join(absoluteProjectPath, 'build', 'ios', 'iphoneos', 'Runner.app');
  }

  Future<String> _findFlutter(String projectPath) async {
    // Check for FVM first (common Flutter version manager)
    final fvmPath = p.join(Platform.environment['HOME'] ?? '', 'fvm', 'versions', 'stable', 'bin', 'flutter');
    print('🔍 Checking for FVM Flutter at: $fvmPath');
    
    if (await File(fvmPath).exists()) {
      print('✅ Using FVM Flutter: $fvmPath');
      return fvmPath;
    }

    print('⚠️  FVM not found, checking system Flutter');
    
    // Check system Flutter in PATH
    final result = await Process.run('which', ['flutter']);
    if (result.exitCode == 0) {
      final systemFlutter = (result.stdout as String).trim();
      print('✅ Using system Flutter: $systemFlutter');
      return systemFlutter;
    }

    throw Exception('Flutter executable not found. Please install Flutter or FVM.');
  }

  /// Get gen_snapshot path for iOS .vmcode generation
  Future<String> getGenSnapshotPath({bool isIOS = false}) async {
    // For iOS, use the Flutter SDK's gen_snapshot (matches the kernel SDK hash)
    if (isIOS) {
      // Use absolute path to flutter-quicui SDK
      final flutterGenSnapshotPath = '/Users/admin/Documents/quicui2/forks/flutter-quicui/bin/cache/artifacts/engine/ios-release/gen_snapshot_arm64';
      
      if (await File(flutterGenSnapshotPath).exists()) {
        return flutterGenSnapshotPath;
      }
      
      // Fallback to custom engine if Flutter SDK gen_snapshot not available
      final engineSrcPath = '/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src';
      final customGenSnapshotPath = p.join(engineSrcPath, 'out', 'ios_release', 'clang_arm64', 'gen_snapshot');
      
      if (await File(customGenSnapshotPath).exists()) {
        return customGenSnapshotPath;
      }
    } else {
      // For Android, use host_release gen_snapshot from custom engine
      final engineSrcPath = '/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src';
      final genSnapshotPath = p.join(engineSrcPath, 'out', 'host_release', 'gen_snapshot');
      
      if (await File(genSnapshotPath).exists()) {
        return genSnapshotPath;
      }
    }
    
    throw Exception('gen_snapshot not found');
  }

  /// Get Dart executable path
  Future<String> getDartPath() async {
    // Check custom SDK first
    final customSdkPath = p.join('..', '..', 'forks', 'flutter-quicui');
    final customDartPath = p.absolute(p.join(customSdkPath, 'bin', 'cache', 'dart-sdk', 'bin', 'dart'));
    
    if (await File(customDartPath).exists()) {
      return customDartPath;
    }
    
    // Fallback to system dart
    final result = await Process.run('which', ['dart']);
    if (result.exitCode == 0) {
      return (result.stdout as String).trim();
    }
    
    throw Exception('Dart executable not found');
  }
}
