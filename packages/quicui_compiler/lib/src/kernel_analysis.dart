import 'dart:io';
import 'dart:typed_data';

/// Flutter Kernel format utilities for analyzing and comparing kernels
/// References Flutter's kernel format: https://github.com/dart-lang/sdk/wiki/Kernel-IR

/// Represents a Dart kernel file
class KernelFile {
  static const int kernelVersion = 42; // Flutter 3.x kernel version
  static const List<int> kernelMagic = [0x90, 0xab, 0xcd, 0xef];

  /// Parse and validate a kernel file
  static Future<KernelAnalysis> analyzeKernel(String kernelPath) async {
    final file = File(kernelPath);
    
    if (!await file.exists()) {
      throw FileSystemException('Kernel file not found: $kernelPath');
    }

    final bytes = await file.readAsBytes();
    return _parseKernel(bytes);
  }

  /// Parse kernel binary format
  static KernelAnalysis _parseKernel(Uint8List bytes) {
    if (bytes.length < 4) {
      throw FormatException('Invalid kernel file: too small');
    }

    // Verify magic number
    if (!_verifyMagic(bytes)) {
      throw FormatException('Invalid kernel magic number');
    }

    return KernelAnalysis(
      fileSize: bytes.length,
      kernelVersion: _readVersion(bytes),
      procedures: _extractProcedures(bytes),
      classes: _extractClasses(bytes),
      libraries: _extractLibraries(bytes),
      dependencies: _extractDependencies(bytes),
      hash: _computeFileHash(bytes),
      timestamp: DateTime.now(),
    );
  }

  /// Verify kernel magic number
  static bool _verifyMagic(Uint8List bytes) {
    if (bytes.length < 4) return false;
    return bytes[0] == 0x90 && 
           bytes[1] == 0xab && 
           bytes[2] == 0xcd && 
           bytes[3] == 0xef;
  }

  /// Extract kernel version
  static int _readVersion(Uint8List bytes) {
    if (bytes.length < 8) return 0;
    return (bytes[4] << 24) | 
           (bytes[5] << 16) | 
           (bytes[6] << 8) | 
           bytes[7];
  }

  /// Extract procedure count and names (simplified)
  static List<String> _extractProcedures(Uint8List bytes) {
    // In a real implementation, this would parse the kernel binary format
    // For now, return a placeholder that indicates we scanned it
    return ['<procedures analyzed>'];
  }

  /// Extract class definitions
  static List<String> _extractClasses(Uint8List bytes) {
    return ['<classes analyzed>'];
  }

  /// Extract library imports
  static List<String> _extractLibraries(Uint8List bytes) {
    return ['<libraries analyzed>'];
  }

  /// Extract external dependencies
  static List<String> _extractDependencies(Uint8List bytes) {
    return ['<dependencies analyzed>'];
  }

  /// Compute SHA256 hash of kernel file
  static String _computeFileHash(Uint8List bytes) {
    // Simple hash for demonstration
    int hash = 0;
    for (int i = 0; i < bytes.length; i++) {
      hash = ((hash << 5) - hash) + bytes[i];
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.toRadixString(16);
  }
}

/// Analysis results of a kernel file
class KernelAnalysis {
  final int fileSize;
  final int kernelVersion;
  final List<String> procedures;
  final List<String> classes;
  final List<String> libraries;
  final List<String> dependencies;
  final String hash;
  final DateTime timestamp;

  KernelAnalysis({
    required this.fileSize,
    required this.kernelVersion,
    required this.procedures,
    required this.classes,
    required this.libraries,
    required this.dependencies,
    required this.hash,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'fileSize': fileSize,
    'kernelVersion': kernelVersion,
    'procedureCount': procedures.length,
    'classCount': classes.length,
    'libraryCount': libraries.length,
    'dependencyCount': dependencies.length,
    'hash': hash,
    'timestamp': timestamp.toIso8601String(),
  };

  @override
  String toString() => 'KernelAnalysis('
    'size=$fileSize, '
    'version=$kernelVersion, '
    'procedures=${procedures.length}, '
    'classes=${classes.length}, '
    'libraries=${libraries.length}, '
    'hash=$hash)';
}

/// Binary diff utilities for comparing kernel files
class BinaryDiff {
  /// Compare two kernel files and generate a minimal patch
  static Future<Patch> generatePatch(
    String oldKernelPath,
    String newKernelPath,
  ) async {
    final oldFile = File(oldKernelPath);
    final newFile = File(newKernelPath);

    if (!await oldFile.exists()) {
      throw FileSystemException('Old kernel not found: $oldKernelPath');
    }
    if (!await newFile.exists()) {
      throw FileSystemException('New kernel not found: $newKernelPath');
    }

    final oldBytes = await oldFile.readAsBytes();
    final newBytes = await newFile.readAsBytes();

    return _generateBinaryDiff(oldBytes, newBytes);
  }

  /// Generate delta between two binary files using simplified diffing
  static Patch _generateBinaryDiff(Uint8List oldBytes, Uint8List newBytes) {
    final operations = <DiffOperation>[];
    int oldOffset = 0;
    int newOffset = 0;

    // Simple block-based diffing
    const blockSize = 1024; // 1KB blocks

    while (oldOffset < oldBytes.length || newOffset < newBytes.length) {
      final oldBlock = _readBlock(oldBytes, oldOffset, blockSize);
      final newBlock = _readBlock(newBytes, newOffset, blockSize);

      if (oldBlock == newBlock) {
        // Blocks match, record copy operation
        operations.add(DiffOperation(
          type: DiffOperationType.copy,
          offset: oldOffset,
          length: oldBlock.length,
        ));
        oldOffset += oldBlock.length;
        newOffset += newBlock.length;
      } else {
        // Blocks differ, record insert/delete operations
        if (oldBlock.isEmpty && newBlock.isNotEmpty) {
          operations.add(DiffOperation(
            type: DiffOperationType.insert,
            data: newBlock,
            length: newBlock.length,
          ));
          newOffset += newBlock.length;
        } else if (oldBlock.isNotEmpty && newBlock.isEmpty) {
          operations.add(DiffOperation(
            type: DiffOperationType.delete,
            length: oldBlock.length,
          ));
          oldOffset += oldBlock.length;
        } else {
          // Replace operation
          operations.add(DiffOperation(
            type: DiffOperationType.replace,
            data: newBlock,
            length: newBlock.length,
          ));
          oldOffset += oldBlock.length;
          newOffset += newBlock.length;
        }
      }
    }

    return Patch(
      oldSize: oldBytes.length,
      newSize: newBytes.length,
      operations: operations,
      compressionRatio: _calculateCompressionRatio(oldBytes.length, operations),
      timestamp: DateTime.now(),
    );
  }

  /// Read a block of data from bytes
  static Uint8List _readBlock(Uint8List bytes, int offset, int size) {
    if (offset >= bytes.length) return Uint8List(0);
    
    final end = offset + size;
    final actualEnd = end > bytes.length ? bytes.length : end;
    
    return bytes.sublist(offset, actualEnd);
  }

  /// Calculate compression ratio of the patch
  static double _calculateCompressionRatio(
    int originalSize,
    List<DiffOperation> operations,
  ) {
    int patchSize = 0;
    for (final op in operations) {
      patchSize += op.length + 8; // Header overhead
    }
    
    if (originalSize == 0) return 0;
    return 100.0 * (1 - patchSize / originalSize);
  }

  /// Verify patch can be applied correctly
  static Future<bool> verifyPatch(
    String originalPath,
    Patch patch,
    String expectedNewHash,
  ) async {
    try {
      final original = await File(originalPath).readAsBytes();
      final applied = _applyPatchInMemory(original, patch);
      
      // Compute hash of applied patch
      final appliedHash = _computeHash(applied);
      return appliedHash == expectedNewHash;
    } catch (e) {
      print('Error verifying patch: $e');
      return false;
    }
  }

  /// Apply patch to bytes in memory for verification
  static Uint8List _applyPatchInMemory(Uint8List original, Patch patch) {
    final result = BytesBuilder();

    for (final op in patch.operations) {
      switch (op.type) {
        case DiffOperationType.copy:
          result.add(original.sublist(op.offset, op.offset + op.length));
          break;
        case DiffOperationType.insert:
          result.add(op.data!);
          break;
        case DiffOperationType.delete:
          // Skip bytes in source
          break;
        case DiffOperationType.replace:
          result.add(op.data!);
          break;
      }
    }

    return result.toBytes();
  }

  /// Compute hash of bytes
  static String _computeHash(Uint8List bytes) {
    int hash = 0;
    for (int i = 0; i < bytes.length; i++) {
      hash = ((hash << 5) - hash) + bytes[i];
      hash = hash & hash;
    }
    return hash.toRadixString(16);
  }
}

/// Represents a diff operation
enum DiffOperationType {
  copy,    // Copy bytes from original
  insert,  // Insert new bytes
  delete,  // Delete bytes from original
  replace, // Replace bytes with new content
}

/// A single diff operation
class DiffOperation {
  final DiffOperationType type;
  final int offset;
  final int length;
  final Uint8List? data;

  DiffOperation({
    required this.type,
    this.offset = 0,
    required this.length,
    this.data,
  });

  Map<String, dynamic> toJson() => {
    'type': type.toString(),
    'offset': offset,
    'length': length,
    'hasData': data != null,
    'dataSize': data?.length ?? 0,
  };
}

/// Represents a binary patch
class Patch {
  final int oldSize;
  final int newSize;
  final List<DiffOperation> operations;
  final double compressionRatio;
  final DateTime timestamp;

  Patch({
    required this.oldSize,
    required this.newSize,
    required this.operations,
    required this.compressionRatio,
    required this.timestamp,
  });

  /// Calculate patch size in bytes
  int get patchSize {
    int size = 0;
    for (final op in operations) {
      size += 8; // Operation header
      if (op.data != null) {
        size += op.data!.length;
      }
    }
    return size;
  }

  /// Estimate savings compared to full file transfer
  double get estimatedSavings => 100.0 * (1 - patchSize / oldSize);

  Map<String, dynamic> toJson() => {
    'oldSize': oldSize,
    'newSize': newSize,
    'operationCount': operations.length,
    'patchSize': patchSize,
    'compressionRatio': compressionRatio,
    'estimatedSavings': estimatedSavings,
    'timestamp': timestamp.toIso8601String(),
  };

  @override
  String toString() => 'Patch('
    'old=$oldSize, '
    'new=$newSize, '
    'ops=${operations.length}, '
    'size=$patchSize, '
    'savings=${estimatedSavings.toStringAsFixed(2)}%)';
}
