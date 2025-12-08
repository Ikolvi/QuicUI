import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

/// Service for building Flutter APK
class FlutterBuildService {
  final _log = Logger('FlutterBuildService');
  final String projectPath;

  FlutterBuildService({required this.projectPath});

  /// Build Flutter APK in release mode
  /// Returns the path to the built APK
  Future<String> buildApk({
    bool verbose = false,
    List<String> additionalArgs = const [],
  }) async {
    _log.info('Building Flutter APK...');
    _log.info('Project path: $projectPath');

    // Verify flutter command is available
    final flutterCheck = await Process.run('which', ['flutter']);
    if (flutterCheck.exitCode != 0) {
      throw Exception('Flutter command not found. Make sure Flutter is installed and in PATH.');
    }

    // Build command arguments
    final args = [
      'build',
      'apk',
      '--release',
      ...additionalArgs,
    ];

    if (verbose) {
      args.add('--verbose');
    }

    _log.info('Running: flutter ${args.join(' ')}');

    final stopwatch = Stopwatch()..start();

    // Run Flutter build
    final process = await Process.start(
      'flutter',
      args,
      workingDirectory: projectPath,
      mode: ProcessStartMode.inheritStdio,
    );

    final exitCode = await process.exitCode;
    stopwatch.stop();

    if (exitCode != 0) {
      throw Exception('Flutter build failed with exit code $exitCode');
    }

    _log.info('✅ Build completed in ${stopwatch.elapsed.inSeconds}s');

    // Return APK path
    final apkPath = p.join(
      projectPath,
      'build',
      'app',
      'outputs',
      'flutter-apk',
      'app-release.apk',
    );

    // Verify APK exists
    if (!await File(apkPath).exists()) {
      throw Exception('APK not found at expected location: $apkPath');
    }

    final apkSize = await File(apkPath).length();
    _log.info('APK size: ${_formatBytes(apkSize)}');
    _log.info('APK path: $apkPath');

    return apkPath;
  }

  /// Clean build artifacts
  Future<void> clean() async {
    _log.info('Cleaning build artifacts...');

    final result = await Process.run(
      'flutter',
      ['clean'],
      workingDirectory: projectPath,
    );

    if (result.exitCode != 0) {
      throw Exception('Flutter clean failed: ${result.stderr}');
    }

    _log.info('✅ Clean completed');
  }

  /// Get Flutter version info
  Future<String> getFlutterVersion() async {
    final result = await Process.run('flutter', ['--version']);
    if (result.exitCode != 0) {
      throw Exception('Failed to get Flutter version');
    }
    return result.stdout.toString().split('\n').first;
  }

  /// Format bytes for display
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
