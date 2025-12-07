import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';

/// Service to extract libapp.so from APK
class ApkExtractorService {
  Future<String> extractLibapp({
    required String apkPath,
    required String architecture,
    required String outputDir,
  }) async {
    final apkFile = File(apkPath);
    if (!await apkFile.exists()) {
      throw Exception('APK not found: $apkPath');
    }

    // Read APK as ZIP
    final bytes = await apkFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Find libapp.so for the architecture
    final libappPath = 'lib/$architecture/libapp.so';
    final libappFile = archive.findFile(libappPath);

    if (libappFile == null) {
      throw Exception('libapp.so not found for $architecture in APK');
    }

    // Extract to output directory
    final outputPath = p.join(outputDir, 'libapp.so');
    final output = File(outputPath);
    await output.writeAsBytes(libappFile.content as List<int>);

    return outputPath;
  }
}
