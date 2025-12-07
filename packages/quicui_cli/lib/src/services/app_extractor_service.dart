import 'dart:io';
import 'package:path/path.dart' as p;

/// Service to extract App binary from iOS .app bundle
class AppExtractorService {
  Future<String> extractApp({
    required String appPath,
    required String outputDir,
    required String version,
  }) async {
    final appDir = Directory(appPath);
    if (!await appDir.exists()) {
      throw Exception('App bundle not found: $appPath');
    }

    // iOS App binary location: Runner.app/Frameworks/App.framework/App
    final appBinaryPath = p.join(appPath, 'Frameworks', 'App.framework', 'App');
    final appBinaryFile = File(appBinaryPath);

    if (!await appBinaryFile.exists()) {
      throw Exception('App binary not found at: $appBinaryPath');
    }

    // Copy to output directory with version suffix
    final outputPath = p.join(outputDir, 'App-v$version');
    final output = File(outputPath);
    await appBinaryFile.copy(output.path);

    // Verify the extracted file
    final stat = await output.stat();
    print('   📊 Binary size: ${(stat.size / (1024 * 1024)).toStringAsFixed(2)} MB');

    return outputPath;
  }
}
