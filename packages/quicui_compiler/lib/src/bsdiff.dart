import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// BsDiff-style binary diff implementation for Flutter AOT snapshots
/// 
/// This implements a simplified version of bsdiff algorithm optimized for
/// Flutter's AOT snapshot format. The algorithm finds matching blocks between
/// old and new files and generates a compact patch.
/// 
/// Patch Format:
/// - Header (32 bytes)
/// - Control block (instructions)
/// - Diff block (changed data)
/// - Extra block (new data)

class BsDiff {
  static const int _headerSize = 32;
  static const int _blockSize = 4096; // 4KB blocks
  static const String _magic = 'QUICUI01'; // Magic signature

  /// Generate a binary patch from old file to new file
  static Future<BsPatch> generatePatch(
    String oldFilePath,
    String newFilePath, {
    String? outputPath,
  }) async {
    print('[BsDiff] Reading old file: $oldFilePath');
    final oldFile = File(oldFilePath);
    if (!await oldFile.exists()) {
      throw FileSystemException('Old file not found: $oldFilePath');
    }

    print('[BsDiff] Reading new file: $newFilePath');
    final newFile = File(newFilePath);
    if (!await newFile.exists()) {
      throw FileSystemException('New file not found: $newFilePath');
    }

    final oldBytes = await oldFile.readAsBytes();
    final newBytes = await newFile.readAsBytes();

    print('[BsDiff] Old size: ${oldBytes.length} bytes');
    print('[BsDiff] New size: ${newBytes.length} bytes');

    final patch = await _createPatch(oldBytes, newBytes);

    // Write patch to file if output path specified
    if (outputPath != null) {
      await _writePatchToFile(patch, outputPath);
      print('[BsDiff] Patch written to: $outputPath');
      print('[BsDiff] Patch size: ${patch.patchSize} bytes');
      print('[BsDiff] Compression: ${patch.compressionRatio.toStringAsFixed(2)}%');
    }

    return patch;
  }

  /// Apply a patch to an old file to produce a new file
  static Future<void> applyPatch(
    String oldFilePath,
    String patchFilePath,
    String newFilePath,
  ) async {
    print('[BsPatch] Reading old file: $oldFilePath');
    final oldFile = File(oldFilePath);
    if (!await oldFile.exists()) {
      throw FileSystemException('Old file not found: $oldFilePath');
    }

    print('[BsPatch] Reading patch: $patchFilePath');
    final patchFile = File(patchFilePath);
    if (!await patchFile.exists()) {
      throw FileSystemException('Patch file not found: $patchFilePath');
    }

    final oldBytes = await oldFile.readAsBytes();
    final patchData = await patchFile.readAsBytes();

    final patch = await _readPatchFromBytes(patchData);

    print('[BsPatch] Applying patch...');
    final newBytes = await _applyPatchData(oldBytes, patch);

    print('[BsPatch] Writing new file: $newFilePath');
    await File(newFilePath).writeAsBytes(newBytes);
    print('[BsPatch] Done! New file size: ${newBytes.length} bytes');
  }

  /// Create patch data structure from old and new bytes
  static Future<BsPatch> _createPatch(
    Uint8List oldBytes,
    Uint8List newBytes,
  ) async {
    final operations = <PatchOperation>[];
    int oldPos = 0;
    int newPos = 0;

    while (newPos < newBytes.length) {
      // Find longest matching block
      final match = _findLongestMatch(
        oldBytes,
        newBytes,
        oldPos,
        newPos,
      );

      if (match.length >= 16) {
        // Found good match, create copy operation
        // First, handle any unmatched bytes before this match
        if (newPos < match.newPos) {
          final diffLength = match.newPos - newPos;
          final diffData = newBytes.sublist(newPos, match.newPos);
          operations.add(PatchOperation(
            type: OperationType.add,
            length: diffLength,
            data: diffData,
          ));
          newPos = match.newPos;
        }

        // Create copy operation for the match
        operations.add(PatchOperation(
          type: OperationType.copy,
          oldOffset: match.oldPos,
          length: match.length,
        ));

        oldPos = match.oldPos + match.length;
        newPos = match.newPos + match.length;
      } else {
        // No good match found, treat as new data
        final blockEnd = (newPos + _blockSize < newBytes.length)
            ? newPos + _blockSize
            : newBytes.length;
        final blockData = newBytes.sublist(newPos, blockEnd);

        operations.add(PatchOperation(
          type: OperationType.add,
          length: blockData.length,
          data: blockData,
        ));

        newPos = blockEnd;
        oldPos = (oldPos + _blockSize < oldBytes.length)
            ? oldPos + _blockSize
            : oldBytes.length;
      }
    }

    // Calculate hashes
    final oldHash = sha256.convert(oldBytes).toString();
    final newHash = sha256.convert(newBytes).toString();

    return BsPatch(
      oldSize: oldBytes.length,
      newSize: newBytes.length,
      oldHash: oldHash,
      newHash: newHash,
      operations: operations,
    );
  }

  /// Find longest matching block between old and new bytes
  static _MatchInfo _findLongestMatch(
    Uint8List oldBytes,
    Uint8List newBytes,
    int oldStart,
    int newStart,
  ) {
    int bestOldPos = oldStart;
    int bestNewPos = newStart;
    int bestLength = 0;

    // Scan for matches in a window
    final scanWindow = 1024; // Look ahead 1KB
    final oldEnd = (oldStart + scanWindow < oldBytes.length)
        ? oldStart + scanWindow
        : oldBytes.length;

    for (int oldPos = oldStart; oldPos < oldEnd; oldPos++) {
      int matchLength = 0;
      int newPos = newStart;

      // Count matching bytes
      while (newPos < newBytes.length &&
          oldPos + matchLength < oldBytes.length &&
          oldBytes[oldPos + matchLength] == newBytes[newPos + matchLength]) {
        matchLength++;
      }

      if (matchLength > bestLength) {
        bestLength = matchLength;
        bestOldPos = oldPos;
        bestNewPos = newStart;
      }

      // Stop if we found a very good match
      if (bestLength > 256) break;
    }

    return _MatchInfo(
      oldPos: bestOldPos,
      newPos: bestNewPos,
      length: bestLength,
    );
  }

  /// Apply patch data to old bytes to produce new bytes
  static Future<Uint8List> _applyPatchData(
    Uint8List oldBytes,
    BsPatch patch,
  ) async {
    final result = BytesBuilder();

    for (final op in patch.operations) {
      switch (op.type) {
        case OperationType.copy:
          // Copy bytes from old file
          final end = op.oldOffset + op.length;
          if (end > oldBytes.length) {
            throw Exception('Invalid copy operation: offset out of range');
          }
          result.add(oldBytes.sublist(op.oldOffset, end));
          break;

        case OperationType.add:
          // Add new bytes
          if (op.data == null) {
            throw Exception('Invalid add operation: no data');
          }
          result.add(op.data!);
          break;
      }
    }

    final newBytes = result.toBytes();

    // Verify hash
    final actualHash = sha256.convert(newBytes).toString();
    if (actualHash != patch.newHash) {
      throw Exception('Hash mismatch after applying patch!\n'
          'Expected: ${patch.newHash}\n'
          'Actual: $actualHash');
    }

    return newBytes;
  }

  /// Write patch to file in custom format
  static Future<void> _writePatchToFile(BsPatch patch, String path) async {
    final builder = BytesBuilder();

    // Write header
    builder.add(utf8.encode(_magic));
    builder.add(_int64ToBytes(patch.oldSize));
    builder.add(_int64ToBytes(patch.newSize));
    builder.add(_int32ToBytes(patch.operations.length));

    // Write old hash
    builder.add(utf8.encode(patch.oldHash));

    // Write new hash
    builder.add(utf8.encode(patch.newHash));

    // Write operations
    for (final op in patch.operations) {
      builder.add([op.type == OperationType.copy ? 0 : 1]);
      builder.add(_int64ToBytes(op.oldOffset));
      builder.add(_int32ToBytes(op.length));

      if (op.type == OperationType.add && op.data != null) {
        builder.add(op.data!);
      }
    }

    await File(path).writeAsBytes(builder.toBytes());
  }

  /// Read patch from file
  static Future<BsPatch> _readPatchFromBytes(Uint8List bytes) async {
    int offset = 0;

    // Read and verify magic
    final magic = utf8.decode(bytes.sublist(offset, offset + 8));
    if (magic != _magic) {
      throw Exception('Invalid patch file: bad magic');
    }
    offset += 8;

    // Read header
    final oldSize = _bytesToInt64(bytes, offset);
    offset += 8;
    final newSize = _bytesToInt64(bytes, offset);
    offset += 8;
    final opCount = _bytesToInt32(bytes, offset);
    offset += 4;

    // Read hashes
    final oldHash = utf8.decode(bytes.sublist(offset, offset + 64));
    offset += 64;
    final newHash = utf8.decode(bytes.sublist(offset, offset + 64));
    offset += 64;

    // Read operations
    final operations = <PatchOperation>[];
    for (int i = 0; i < opCount; i++) {
      final typeFlag = bytes[offset++];
      final type =
          typeFlag == 0 ? OperationType.copy : OperationType.add;
      final oldOffset = _bytesToInt64(bytes, offset);
      offset += 8;
      final length = _bytesToInt32(bytes, offset);
      offset += 4;

      Uint8List? data;
      if (type == OperationType.add) {
        data = bytes.sublist(offset, offset + length);
        offset += length;
      }

      operations.add(PatchOperation(
        type: type,
        oldOffset: oldOffset,
        length: length,
        data: data,
      ));
    }

    return BsPatch(
      oldSize: oldSize,
      newSize: newSize,
      oldHash: oldHash,
      newHash: newHash,
      operations: operations,
    );
  }

  // Helper methods for byte conversion
  static Uint8List _int64ToBytes(int value) {
    return Uint8List(8)
      ..buffer.asByteData().setInt64(0, value, Endian.little);
  }

  static int _bytesToInt64(Uint8List bytes, int offset) {
    return bytes.buffer.asByteData().getInt64(offset, Endian.little);
  }

  static Uint8List _int32ToBytes(int value) {
    return Uint8List(4)
      ..buffer.asByteData().setInt32(0, value, Endian.little);
  }

  static int _bytesToInt32(Uint8List bytes, int offset) {
    return bytes.buffer.asByteData().getInt32(offset, Endian.little);
  }
}

/// Represents a binary patch
class BsPatch {
  final int oldSize;
  final int newSize;
  final String oldHash;
  final String newHash;
  final List<PatchOperation> operations;

  BsPatch({
    required this.oldSize,
    required this.newSize,
    required this.oldHash,
    required this.newHash,
    required this.operations,
  });

  /// Calculate total patch size
  int get patchSize {
    int size = BsDiff._headerSize + 128; // Header + hashes
    for (final op in operations) {
      size += 13; // Operation header (1 + 8 + 4)
      if (op.type == OperationType.add && op.data != null) {
        size += op.data!.length;
      }
    }
    return size;
  }

  /// Calculate compression ratio
  double get compressionRatio {
    if (newSize == 0) return 0.0;
    return 100.0 * (1 - patchSize / newSize);
  }

  Map<String, dynamic> toJson() => {
        'oldSize': oldSize,
        'newSize': newSize,
        'oldHash': oldHash,
        'newHash': newHash,
        'operationCount': operations.length,
        'patchSize': patchSize,
        'compressionRatio': compressionRatio,
      };

  @override
  String toString() => 'BsPatch(\n'
      '  oldSize: $oldSize bytes\n'
      '  newSize: $newSize bytes\n'
      '  operations: ${operations.length}\n'
      '  patchSize: $patchSize bytes\n'
      '  compression: ${compressionRatio.toStringAsFixed(2)}%\n'
      ')';
}

/// Type of patch operation
enum OperationType {
  copy, // Copy bytes from old file
  add, // Add new bytes
}

/// Single patch operation
class PatchOperation {
  final OperationType type;
  final int oldOffset; // For copy operations
  final int length;
  final Uint8List? data; // For add operations

  PatchOperation({
    required this.type,
    this.oldOffset = 0,
    required this.length,
    this.data,
  });

  @override
  String toString() => 'PatchOperation('
      'type=$type, '
      'oldOffset=$oldOffset, '
      'length=$length, '
      'hasData=${data != null})';
}

/// Match information for diffing
class _MatchInfo {
  final int oldPos;
  final int newPos;
  final int length;

  _MatchInfo({
    required this.oldPos,
    required this.newPos,
    required this.length,
  });
}
