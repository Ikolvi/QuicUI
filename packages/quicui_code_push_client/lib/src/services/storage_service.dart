import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Manages storage of patches and cached data
class StorageService {
  late Directory _patchDirectory;
  late Directory _cacheDirectory;

  /// Initialize storage directories
  Future<void> initialize() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    _patchDirectory = Directory(path.join(appDocDir.path, 'quicui', 'patches'));
    _cacheDirectory = Directory(path.join(appDocDir.path, 'quicui', 'cache'));

    // Create directories if they don't exist
    if (!_patchDirectory.existsSync()) {
      _patchDirectory.createSync(recursive: true);
    }
    if (!_cacheDirectory.existsSync()) {
      _cacheDirectory.createSync(recursive: true);
    }
  }

  /// Get patch directory
  Directory get patchDirectory => _patchDirectory;

  /// Get cache directory
  Directory get cacheDirectory => _cacheDirectory;

  /// Save a patch file with platform-specific extension
  Future<File> savePatch(String patchId, List<int> bytes, {String platform = 'android'}) async {
    final extension = platform == 'ios' ? 'vmcode' : 'so';
    final file = File(path.join(_patchDirectory.path, '$patchId.$extension'));
    return file.writeAsBytes(bytes);
  }

  /// Load a patch file with platform-specific extension
  Future<File?> loadPatch(String patchId, {String platform = 'android'}) async {
    final extension = platform == 'ios' ? 'vmcode' : 'so';
    final file = File(path.join(_patchDirectory.path, '$patchId.$extension'));
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// Delete a patch file with platform-specific extension
  Future<void> deletePatch(String patchId, {String platform = 'android'}) async {
    final extension = platform == 'ios' ? 'vmcode' : 'so';
    final file = File(path.join(_patchDirectory.path, '$patchId.$extension'));
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Get all stored patches (both .vmcode and .so files)
  Future<List<String>> getAllPatches() async {
    final files = _patchDirectory.listSync();
    return files
        .whereType<File>()
        .where((f) => f.path.endsWith('.vmcode') || f.path.endsWith('.so'))
        .map((f) => path.basenameWithoutExtension(f.path))
        .toList();
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    if (_cacheDirectory.existsSync()) {
      _cacheDirectory.deleteSync(recursive: true);
      _cacheDirectory.createSync(recursive: true);
    }
  }

  /// Clear all patches
  Future<void> clearAllPatches() async {
    if (_patchDirectory.existsSync()) {
      _patchDirectory.deleteSync(recursive: true);
      _patchDirectory.createSync(recursive: true);
    }
  }

  /// Get total size of all patches in bytes
  Future<int> getTotalPatchSize() async {
    int totalSize = 0;
    final files = _patchDirectory.listSync();
    for (var file in files) {
      if (file is File) {
        totalSize += await file.length();
      }
    }
    return totalSize;
  }
}
