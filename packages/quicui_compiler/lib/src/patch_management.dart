import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Patch metadata with diff information
class PatchMetadata {
  final String version;
  final String baseVersion;
  final String targetVersion;
  final DateTime timestamp;
  final String description;
  final int fileSize;
  final String checksum;
  final List<FileDiff> fileDiffs;
  final bool critical;
  final String? releaseNotes;

  PatchMetadata({
    required this.version,
    required this.baseVersion,
    required this.targetVersion,
    required this.timestamp,
    required this.description,
    required this.fileSize,
    required this.checksum,
    required this.fileDiffs,
    this.critical = false,
    this.releaseNotes,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'version': version,
    'baseVersion': baseVersion,
    'targetVersion': targetVersion,
    'timestamp': timestamp.toIso8601String(),
    'description': description,
    'fileSize': fileSize,
    'checksum': checksum,
    'critical': critical,
    'releaseNotes': releaseNotes,
    'fileDiffs': fileDiffs.map((d) => d.toJson()).toList(),
  };

  /// Create from JSON
  factory PatchMetadata.fromJson(Map<String, dynamic> json) {
    return PatchMetadata(
      version: json['version'] as String,
      baseVersion: json['baseVersion'] as String,
      targetVersion: json['targetVersion'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      description: json['description'] as String,
      fileSize: json['fileSize'] as int,
      checksum: json['checksum'] as String,
      fileDiffs: (json['fileDiffs'] as List)
          .cast<Map<String, dynamic>>()
          .map(FileDiff.fromJson)
          .toList(),
      critical: json['critical'] as bool? ?? false,
      releaseNotes: json['releaseNotes'] as String?,
    );
  }
}

/// Individual file difference
class FileDiff {
  final String filePath;
  final String changeType; // 'added', 'modified', 'deleted'
  final String? oldHash;
  final String? newHash;
  final int oldSize;
  final int newSize;
  final List<String> changes; // Line-level or block-level changes
  final double compressionRatio;

  FileDiff({
    required this.filePath,
    required this.changeType,
    this.oldHash,
    this.newHash,
    this.oldSize = 0,
    this.newSize = 0,
    this.changes = const [],
    this.compressionRatio = 1.0,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'filePath': filePath,
    'changeType': changeType,
    'oldHash': oldHash,
    'newHash': newHash,
    'oldSize': oldSize,
    'newSize': newSize,
    'changes': changes,
    'compressionRatio': compressionRatio,
  };

  /// Create from JSON
  factory FileDiff.fromJson(Map<String, dynamic> json) {
    return FileDiff(
      filePath: json['filePath'] as String,
      changeType: json['changeType'] as String,
      oldHash: json['oldHash'] as String?,
      newHash: json['newHash'] as String?,
      oldSize: json['oldSize'] as int? ?? 0,
      newSize: json['newSize'] as int? ?? 0,
      changes: (json['changes'] as List?)?.cast<String>() ?? [],
      compressionRatio: json['compressionRatio'] as double? ?? 1.0,
    );
  }

  /// Get summary
  String getSummary() {
    if (changeType == 'added') {
      return '$filePath (NEW, $newSize bytes)';
    } else if (changeType == 'deleted') {
      return '$filePath (DELETED, was $oldSize bytes)';
    } else {
      final sizeDiff = newSize - oldSize;
      final sizeStr = sizeDiff > 0 ? '+$sizeDiff' : '$sizeDiff';
      return '$filePath (MODIFIED, $sizeStr bytes, ${(compressionRatio * 100).toStringAsFixed(1)}% compressed)';
    }
  }
}

/// Patch storage and management
class PatchStorage {
  final String storagePath;
  late final Directory patchDir;
  late final Directory diffDir;
  late final Directory metadataDir;

  PatchStorage(this.storagePath);

  /// Initialize storage directories
  Future<void> initialize() async {
    patchDir = Directory('$storagePath/patches');
    diffDir = Directory('$storagePath/diffs');
    metadataDir = Directory('$storagePath/metadata');

    await patchDir.create(recursive: true);
    await diffDir.create(recursive: true);
    await metadataDir.create(recursive: true);

    print('✅ Patch storage initialized at: $storagePath');
  }

  /// Save patch with metadata and diffs
  Future<void> savePatch({
    required String patchVersion,
    required File patchFile,
    required PatchMetadata metadata,
  }) async {
    // Save patch file
    final destinationPath = '${patchDir.path}/$patchVersion.patch';
    await patchFile.copy(destinationPath);
    print('✅ Patch saved: $destinationPath');

    // Save metadata
    final metadataPath = '${metadataDir.path}/$patchVersion.json';
    await File(metadataPath).writeAsString(
      jsonEncode(metadata.toJson()),
      flush: true,
    );
    print('✅ Metadata saved: $metadataPath');

    // Save diffs
    await _saveDiffs(patchVersion, metadata.fileDiffs);
  }

  /// Save file diffs
  Future<void> _saveDiffs(String patchVersion, List<FileDiff> diffs) async {
    final diffPath = '${diffDir.path}/$patchVersion.diffs.json';
    final diffData = {
      'patchVersion': patchVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'totalFiles': diffs.length,
      'files': diffs.map((d) => d.toJson()).toList(),
    };

    await File(diffPath).writeAsString(
      jsonEncode(diffData),
      flush: true,
    );
    print('✅ Diffs saved: $diffPath');
  }

  /// Retrieve patch metadata
  Future<PatchMetadata?> getPatchMetadata(String patchVersion) async {
    final metadataPath = '${metadataDir.path}/$patchVersion.json';
    final metadataFile = File(metadataPath);

    if (!await metadataFile.exists()) {
      return null;
    }

    final jsonStr = await metadataFile.readAsString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return PatchMetadata.fromJson(json);
  }

  /// List all stored patches
  Future<List<String>> listPatches() async {
    final files = await patchDir.list().toList();
    return files
        .whereType<File>()
        .map((f) => f.path.split('/').last.replaceAll('.patch', ''))
        .toList();
  }

  /// Get storage usage
  Future<Map<String, int>> getStorageUsage() async {
    int patchesSize = 0;
    int diffsSize = 0;
    int metadataSize = 0;

    final patchFiles = await patchDir.list().toList();
    for (final file in patchFiles.whereType<File>()) {
      patchesSize += await file.length();
    }

    final diffFiles = await diffDir.list().toList();
    for (final file in diffFiles.whereType<File>()) {
      diffsSize += await file.length();
    }

    final metadataFiles = await metadataDir.list().toList();
    for (final file in metadataFiles.whereType<File>()) {
      metadataSize += await file.length();
    }

    return {
      'patches': patchesSize,
      'diffs': diffsSize,
      'metadata': metadataSize,
      'total': patchesSize + diffsSize + metadataSize,
    };
  }
}

/// Server upload manager using curl for HTTP
class PatchUploadManager {
  final String serverUrl;
  final String? authToken;

  PatchUploadManager({
    required this.serverUrl,
    this.authToken,
  });

  /// Upload patch to server using curl
  Future<UploadResponse> uploadPatch({
    required String patchVersion,
    required File patchFile,
    required PatchMetadata metadata,
  }) async {
    try {
      print('📤 Uploading patch v$patchVersion to $serverUrl...');

      final metadataJson = jsonEncode(metadata.toJson());

      // Use curl to upload
      final curlArgs = [
        '-X', 'POST',
        '-F', 'patch=@${patchFile.path}',
        '-F', 'metadata=$metadataJson',
        '-F', 'version=$patchVersion',
      ];

      if (authToken != null) {
        curlArgs.add('-H');
        curlArgs.add('Authorization: Bearer $authToken');
      }

      curlArgs.add('$serverUrl/api/v1/patches/upload');

      final process = await Process.run('curl', curlArgs);

      if (process.exitCode == 0) {
        print('✅ Upload successful!');
        return UploadResponse(
          success: true,
          message: 'Patch uploaded successfully',
          patchVersion: patchVersion,
          serverUrl: serverUrl,
        );
      } else {
        return UploadResponse(
          success: false,
          message: 'Upload failed',
          error: process.stderr.toString(),
        );
      }
    } catch (e) {
      print('❌ Upload error: $e');
      return UploadResponse(
        success: false,
        message: 'Upload failed',
        error: e.toString(),
      );
    }
  }

  /// Upload only metadata and diffs using curl
  Future<UploadResponse> uploadMetadata({
    required String patchVersion,
    required PatchMetadata metadata,
  }) async {
    try {
      print('📤 Uploading metadata for v$patchVersion...');

      final metadataJson = jsonEncode(metadata.toJson());
      final diffsJson = jsonEncode(
        metadata.fileDiffs.map((d) => d.toJson()).toList(),
      );

      // Use curl to upload
      final curlArgs = [
        '-X', 'POST',
        '-F', 'metadata=$metadataJson',
        '-F', 'version=$patchVersion',
        '-F', 'diffs=$diffsJson',
      ];

      if (authToken != null) {
        curlArgs.add('-H');
        curlArgs.add('Authorization: Bearer $authToken');
      }

      curlArgs.add('$serverUrl/api/v1/patches/metadata');

      final process = await Process.run('curl', curlArgs);

      if (process.exitCode == 0) {
        print('✅ Metadata uploaded successfully!');
        return UploadResponse(
          success: true,
          message: 'Metadata uploaded',
          patchVersion: patchVersion,
        );
      } else {
        return UploadResponse(
          success: false,
          message: 'Metadata upload failed',
          error: process.stderr.toString(),
        );
      }
    } catch (e) {
      print('❌ Metadata upload error: $e');
      return UploadResponse(
        success: false,
        message: 'Metadata upload failed',
        error: e.toString(),
      );
    }
  }
}

/// Upload response model
class UploadResponse {
  final bool success;
  final String message;
  final String? patchVersion;
  final String? serverUrl;
  final String? error;

  UploadResponse({
    required this.success,
    required this.message,
    this.patchVersion,
    this.serverUrl,
    this.error,
  });
}

/// Individual file difference
class FileDiff {
  final String filePath;
  final String changeType; // 'added', 'modified', 'deleted'
  final String? oldHash;
  final String? newHash;
  final int oldSize;
  final int newSize;
  final List<String> changes; // Line-level or block-level changes
  final double compressionRatio;

  FileDiff({
    required this.filePath,
    required this.changeType,
    this.oldHash,
    this.newHash,
    this.oldSize = 0,
    this.newSize = 0,
    this.changes = const [],
    this.compressionRatio = 1.0,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'filePath': filePath,
    'changeType': changeType,
    'oldHash': oldHash,
    'newHash': newHash,
    'oldSize': oldSize,
    'newSize': newSize,
    'changes': changes,
    'compressionRatio': compressionRatio,
  };

  /// Create from JSON
  factory FileDiff.fromJson(Map<String, dynamic> json) {
    return FileDiff(
      filePath: json['filePath'] as String,
      changeType: json['changeType'] as String,
      oldHash: json['oldHash'] as String?,
      newHash: json['newHash'] as String?,
      oldSize: json['oldSize'] as int? ?? 0,
      newSize: json['newSize'] as int? ?? 0,
      changes: (json['changes'] as List?)?.cast<String>() ?? [],
      compressionRatio: json['compressionRatio'] as double? ?? 1.0,
    );
  }

  /// Get summary
  String getSummary() {
    if (changeType == 'added') {
      return '$filePath (NEW, $newSize bytes)';
    } else if (changeType == 'deleted') {
      return '$filePath (DELETED, was $oldSize bytes)';
    } else {
      final sizeDiff = newSize - oldSize;
      final sizeStr = sizeDiff > 0 ? '+$sizeDiff' : '$sizeDiff';
      return '$filePath (MODIFIED, $sizeStr bytes, ${(compressionRatio * 100).toStringAsFixed(1)}% compressed)';
    }
  }
}

/// Patch storage and management
class PatchStorage {
  final String storagePath;
  late final Directory patchDir;
  late final Directory diffDir;
  late final Directory metadataDir;

  PatchStorage(this.storagePath);

  /// Initialize storage directories
  Future<void> initialize() async {
    patchDir = Directory('$storagePath/patches');
    diffDir = Directory('$storagePath/diffs');
    metadataDir = Directory('$storagePath/metadata');

    await patchDir.create(recursive: true);
    await diffDir.create(recursive: true);
    await metadataDir.create(recursive: true);

    print('✅ Patch storage initialized at: $storagePath');
  }

  /// Save patch with metadata and diffs
  Future<void> savePatch({
    required String patchVersion,
    required File patchFile,
    required PatchMetadata metadata,
  }) async {
    // Save patch file
    final destinationPath = '${patchDir.path}/$patchVersion.patch';
    await patchFile.copy(destinationPath);
    print('✅ Patch saved: $destinationPath');

    // Save metadata
    final metadataPath = '${metadataDir.path}/$patchVersion.json';
    await File(metadataPath).writeAsString(
      jsonEncode(metadata.toJson()),
      flush: true,
    );
    print('✅ Metadata saved: $metadataPath');

    // Save diffs
    await _saveDiffs(patchVersion, metadata.fileDiffs);
  }

  /// Save file diffs
  Future<void> _saveDiffs(String patchVersion, List<FileDiff> diffs) async {
    final diffPath = '${diffDir.path}/$patchVersion.diffs.json';
    final diffData = {
      'patchVersion': patchVersion,
      'timestamp': DateTime.now().toIso8601String(),
      'totalFiles': diffs.length,
      'files': diffs.map((d) => d.toJson()).toList(),
    };

    await File(diffPath).writeAsString(
      jsonEncode(diffData),
      flush: true,
    );
    print('✅ Diffs saved: $diffPath');
  }

  /// Retrieve patch metadata
  Future<PatchMetadata?> getPatchMetadata(String patchVersion) async {
    final metadataPath = '${metadataDir.path}/$patchVersion.json';
    final metadataFile = File(metadataPath);

    if (!await metadataFile.exists()) {
      return null;
    }

    final jsonStr = await metadataFile.readAsString();
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return PatchMetadata.fromJson(json);
  }

  /// List all stored patches
  Future<List<String>> listPatches() async {
    final files = await patchDir.list().toList();
    return files
        .whereType<File>()
        .map((f) => f.path.split('/').last.replaceAll('.patch', ''))
        .toList();
  }

  /// Get storage usage
  Future<Map<String, int>> getStorageUsage() async {
    int patchesSize = 0;
    int diffsSize = 0;
    int metadataSize = 0;

    final patchFiles = await patchDir.list().toList();
    for (final file in patchFiles.whereType<File>()) {
      patchesSize += await file.length();
    }

    final diffFiles = await diffDir.list().toList();
    for (final file in diffFiles.whereType<File>()) {
      diffsSize += await file.length();
    }

    final metadataFiles = await metadataDir.list().toList();
    for (final file in metadataFiles.whereType<File>()) {
      metadataSize += await file.length();
    }

    return {
      'patches': patchesSize,
      'diffs': diffsSize,
      'metadata': metadataSize,
      'total': patchesSize + diffsSize + metadataSize,
    };
  }
}

/// Server upload manager
class PatchUploadManager {
  final String serverUrl;
  final String? authToken;

  PatchUploadManager({
    required this.serverUrl,
    this.authToken,
  });

  /// Upload patch to server
  Future<UploadResponse> uploadPatch({
    required String patchVersion,
    required File patchFile,
    required PatchMetadata metadata,
  }) async {
    try {
      print('📤 Uploading patch v$patchVersion to $serverUrl...');

      // Read patch data
      final patchData = await patchFile.readAsBytes();

      // Create multipart request
      final uri = Uri.parse('$serverUrl/api/v1/patches/upload');
      final request = MultipartRequest('POST', uri);

      // Add headers
      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      // Add patch file
      request.files.add(
        MultipartFile.fromBytes(
          'patch',
          patchData,
          filename: '$patchVersion.patch',
        ),
      );

      // Add metadata
      request.fields['metadata'] = jsonEncode(metadata.toJson());
      request.fields['version'] = patchVersion;

      // Send request
      final streamedResponse = await request.send();
      final response = await Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print('✅ Upload successful!');
        return UploadResponse(
          success: true,
          message: 'Patch uploaded successfully',
          patchVersion: patchVersion,
          serverUrl: serverUrl,
        );
      } else {
        return UploadResponse(
          success: false,
          message: 'Upload failed: ${response.statusCode}',
          error: response.body,
        );
      }
    } catch (e) {
      print('❌ Upload error: $e');
      return UploadResponse(
        success: false,
        message: 'Upload failed',
        error: e.toString(),
      );
    }
  }

  /// Upload only metadata and diffs (without patch binary)
  Future<UploadResponse> uploadMetadata({
    required String patchVersion,
    required PatchMetadata metadata,
  }) async {
    try {
      print('📤 Uploading metadata for v$patchVersion...');

      final uri = Uri.parse('$serverUrl/api/v1/patches/metadata');
      final request = MultipartRequest('POST', uri);

      if (authToken != null) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }

      request.fields['metadata'] = jsonEncode(metadata.toJson());
      request.fields['version'] = patchVersion;
      request.fields['diffs'] = jsonEncode(
        metadata.fileDiffs.map((d) => d.toJson()).toList(),
      );

      final streamedResponse = await request.send();
      final response = await Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print('✅ Metadata uploaded successfully!');
        return UploadResponse(
          success: true,
          message: 'Metadata uploaded',
          patchVersion: patchVersion,
        );
      } else {
        return UploadResponse(
          success: false,
          message: 'Metadata upload failed',
          error: response.body,
        );
      }
    } catch (e) {
      print('❌ Metadata upload error: $e');
      return UploadResponse(
        success: false,
        message: 'Metadata upload failed',
        error: e.toString(),
      );
    }
  }
}

/// Upload response model
class UploadResponse {
  final bool success;
  final String message;
  final String? patchVersion;
  final String? serverUrl;
  final String? error;

  UploadResponse({
    required this.success,
    required this.message,
    this.patchVersion,
    this.serverUrl,
    this.error,
  };
}

