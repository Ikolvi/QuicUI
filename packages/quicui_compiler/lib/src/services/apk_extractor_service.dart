import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

/// Service for extracting libapp.so snapshots from Flutter APK
class ApkExtractorService {
  final _log = Logger('ApkExtractorService');

  /// Extract libapp.so files from APK for specified architectures
  /// Returns map of architecture -> extracted libapp.so path
  Future<Map<String, String>> extractLibApp(
    String apkPath,
    List<String> architectures, {
    String? outputDir,
  }) async {
    _log.info('Extracting libapp.so from APK...');
    _log.info('APK: $apkPath');

    // Verify APK exists
    final apkFile = File(apkPath);
    if (!await apkFile.exists()) {
      throw FileSystemException('APK not found: $apkPath');
    }

    // Create output directory
    outputDir ??= p.join(
      p.dirname(apkPath),
      '.quicui_extracted',
    );

    final outputDirObj = Directory(outputDir);
    if (await outputDirObj.exists()) {
      await outputDirObj.delete(recursive: true);
    }
    await outputDirObj.create(recursive: true);

    _log.info('Output dir: $outputDir');

    // Extract APK (it's a ZIP file)
    final bytes = await apkFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final extractedPaths = <String, String>{};

    // Extract libapp.so for each architecture
    for (final arch in architectures) {
      final libPath = 'lib/$arch/libapp.so';
      _log.info('Looking for: $libPath');

      // Find file in archive
      final file = archive.findFile(libPath);
      if (file == null) {
        _log.warning('⚠️  $libPath not found in APK (architecture may not be included in build)');
        continue;
      }

      if (!file.isFile) {
        _log.warning('⚠️  $libPath is not a file');
        continue;
      }

      // Extract to output directory
      final outputPath = p.join(outputDir, 'libapp_$arch.so');
      final outputFile = File(outputPath);

      _log.info('Extracting: $libPath -> $outputPath');
      await outputFile.writeAsBytes(file.content as List<int>);

      final size = await outputFile.length();
      _log.info('✅ Extracted $arch: ${_formatBytes(size)}');

      extractedPaths[arch] = outputPath;
    }

    if (extractedPaths.isEmpty) {
      throw Exception(
        'No libapp.so files found in APK for specified architectures: ${architectures.join(', ')}\n'
        'Make sure the APK was built with --release and contains native code.',
      );
    }

    _log.info('✅ Extracted ${extractedPaths.length} libapp.so files');

    return extractedPaths;
  }

  /// Get list of all architectures present in APK
  Future<List<String>> getAvailableArchitectures(String apkPath) async {
    final apkFile = File(apkPath);
    if (!await apkFile.exists()) {
      throw FileSystemException('APK not found: $apkPath');
    }

    final bytes = await apkFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final architectures = <String>[];

    // Common architecture names
    final knownArchs = [
      'arm64-v8a',
      'armeabi-v7a',
      'x86_64',
      'x86',
    ];

    for (final arch in knownArchs) {
      final libPath = 'lib/$arch/libapp.so';
      final file = archive.findFile(libPath);
      if (file != null && file.isFile) {
        architectures.add(arch);
      }
    }

    return architectures;
  }

  /// Get file info from APK without extracting
  Future<Map<String, dynamic>> getLibAppInfo(
    String apkPath,
    String architecture,
  ) async {
    final apkFile = File(apkPath);
    if (!await apkFile.exists()) {
      throw FileSystemException('APK not found: $apkPath');
    }

    final bytes = await apkFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final libPath = 'lib/$architecture/libapp.so';
    final file = archive.findFile(libPath);

    if (file == null || !file.isFile) {
      throw Exception('libapp.so not found for architecture: $architecture');
    }

    return {
      'architecture': architecture,
      'size': file.size,
    };
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
