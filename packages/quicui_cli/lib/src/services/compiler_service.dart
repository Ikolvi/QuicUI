import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'package:quicui_compiler/src/bsdiff.dart';
import 'package:quicui_linker/quicui_linker.dart';

/// Wrapper for QuicUI Compiler functionality
class CompilerService {
  /// Generate a patch using bsdiff
  static Future<PatchResult> generatePatch({
    required String oldLibappPath,
    required String newLibappPath,
    required String outputDir,
    required String compression,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final patchPath = p.join(outputDir, 'patch_$timestamp.quicui');

    // Generate patch using BsDiff
    await BsDiff.generatePatch(
      oldLibappPath,
      newLibappPath,
      outputPath: patchPath,
    );

    // Get uncompressed patch info
    final uncompressedBytes = await File(patchPath).readAsBytes();
    final uncompressedSize = uncompressedBytes.length;
    final uncompressedHash = sha256.convert(uncompressedBytes).toString();

    // Verify patch header (support both QUICUI01 and BSDIFF40)
    if (uncompressedBytes.length < 8) {
      throw Exception('Invalid patch file: too small');
    }
    final header = String.fromCharCodes(uncompressedBytes.sublist(0, 8));
    if (header != 'QUICUI01' && header != 'BSDIFF40') {
      throw Exception('Invalid patch file: unsupported format (found: $header)');
    }
    print('✓ $header format verified');

    // Apply compression if specified
    String finalPatchPath = patchPath;
    int compressedSize = uncompressedSize;
    if (compression == 'xz') {
      print('Compressing patch with XZ...');
      finalPatchPath = await _compressXz(patchPath);
      compressedSize = await File(finalPatchPath).length();
      await File(patchPath).delete(); // Remove uncompressed patch
    }

    return PatchResult(
      patchPath: finalPatchPath,
      patchHash: uncompressedHash, // Hash of uncompressed patch
      patchSize: compressedSize,
      uncompressedSize: uncompressedSize,
      oldSize: await File(oldLibappPath).length(),
      newSize: await File(newLibappPath).length(),
      compression: compression,
    );
  }

  static Future<String> _compressXz(String inputPath) async {
    final result = await Process.run('xz', ['-z', '-9', '-k', inputPath]);

    if (result.exitCode != 0) {
      throw Exception('XZ compression failed: ${result.stderr}');
    }

    // xz creates .xz file automatically
    final xzFile = File('$inputPath.xz');
    if (await xzFile.exists()) {
      return xzFile.path;
    }

    throw Exception('XZ compression output not found');
  }

  /// Generate .vmcode patch for iOS (differential AOT approach with linker)
  static Future<PatchResult> generateVMCodePatch({
    required String genSnapshotPath,
    required String appDillPath,
    required String baselineBinaryPath,
    required String outputDir,
    required String version,
    required String compression,
  }) async {
    print('[iOS] Generating differential .vmcode patch...');
    print('[iOS] Using gen_snapshot: $genSnapshotPath');
    print('[iOS] Baseline: $baselineBinaryPath');
    print('[iOS] Input: $appDillPath');
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final patchAotPath = p.join(outputDir, 'patch_${version}_$timestamp.aot');
    final vmcodePath = p.join(outputDir, 'patch_${version}_$timestamp.vmcode');
    
    // Step 1: Generate patch AOT snapshot (ELF format)
    print('[iOS] Step 1: Generating patch AOT snapshot...');
    final args = [
      '--deterministic',
      '--snapshot_kind=app-aot-elf',
      '--elf=$patchAotPath',
      appDillPath,
    ];
    
    print('[iOS] Running: $genSnapshotPath ${args.join(" ")}');
    final result = await Process.run(genSnapshotPath, args);
    
    if (result.exitCode != 0) {
      print('[iOS] gen_snapshot stderr: ${result.stderr}');
      print('[iOS] gen_snapshot stdout: ${result.stdout}');
      throw Exception('gen_snapshot failed with exit code ${result.exitCode}');
    }
    
    print('[iOS] ✅ Generated patch AOT: $patchAotPath');
    
    // Step 2: Use differential linker to create patch with QUIC header
    print('[iOS] Step 2: Creating differential patch...');
    
    try {
      // Parse baseline Mach-O (for analysis/logging)
      final baselineFile = File(baselineBinaryPath);
      if (!await baselineFile.exists()) {
        throw Exception('Baseline binary not found: $baselineBinaryPath');
      }
      
      final machoBaseline = await parseMachoFile(baselineFile);
      print('[iOS]   ✅ Parsed Mach-O baseline (${machoBaseline.segments.length} segments)');
      
      // Parse patch ELF from gen_snapshot
      final patchFile = File(patchAotPath);
      final patch = await parseElfFile(patchFile);
      print('[iOS]   ✅ Parsed patch ELF (${patch.sections.length} sections)');
      
      // Analyze differences (for logging)
      final analyzer = SnapshotAnalyzer.fromMacho(machoBaseline, patch);
      final diff = await analyzer.analyze();
      
      // Generate patch ELF (currently returns full ELF with proper symbols)
      final linker = DifferentialLinker(patch, diff);
      final patchElf = await linker.generatePatch();
      
      // Add 64KB QUIC header to create .vmcode
      print('[iOS] Step 3: Adding 64KB QUIC header...');
      final generator = VmcodeGenerator();
      await generator.generate(
        patchElf: patchElf,
        outputFile: File(vmcodePath),
      );
      
      print('[iOS] ✅ Differential .vmcode created');
    } catch (e) {
      print('[iOS] ⚠️  Differential linker error: $e');
      print('[iOS] Falling back to full ELF with header...');
      
      // Fallback: Create .vmcode with full ELF
      final patchBytes = await File(patchAotPath).readAsBytes();
      
      // Create 64KB header (QUIC format)
      // Engine reads ELF offset from bytes 16-23 (little-endian uint64)
      final header = ByteData(65536);
      header.setUint32(0, 0x51554943, Endian.little); // Magic: "QUIC"
      header.setUint32(4, 1, Endian.little); // Version: 1
      // Bytes 8-15: Reserved
      // Bytes 16-23: ELF offset (65536) in little-endian uint64
      header.setUint64(16, 65536, Endian.little); // ELF offset at correct position
      
      // Combine header + ELF
      final vmcodeBytes = Uint8List(65536 + patchBytes.length);
      vmcodeBytes.setRange(0, 65536, header.buffer.asUint8List());
      vmcodeBytes.setRange(65536, 65536 + patchBytes.length, patchBytes);
      
      await File(vmcodePath).writeAsBytes(vmcodeBytes);
    }
    
    // Clean up intermediate .aot file
    await File(patchAotPath).delete();
    
    if (result.exitCode != 0) {
      print('[iOS] gen_snapshot stderr: ${result.stderr}');
      print('[iOS] gen_snapshot stdout: ${result.stdout}');
      throw Exception('gen_snapshot failed with exit code ${result.exitCode}');
    }
    
    print('[iOS] ✅ Generated .vmcode snapshot');
    
    // Get uncompressed info
    final vmcodeFile = File(vmcodePath);
    if (!await vmcodeFile.exists()) {
      throw Exception('.vmcode file not generated: $vmcodePath');
    }
    
    final uncompressedBytes = await vmcodeFile.readAsBytes();
    final uncompressedSize = uncompressedBytes.length;
    final uncompressedHash = sha256.convert(uncompressedBytes).toString();
    
    print('[iOS] Size: ${(uncompressedSize / 1024 / 1024).toStringAsFixed(2)} MB');
    print('[iOS] Hash: $uncompressedHash');
    
    // Verify .vmcode format (header at offset 0, ELF at offset 65536)
    if (uncompressedBytes.length < 65536 + 4) {
      throw Exception('Invalid .vmcode file: file too small');
    }
    
    // Check QUIC header magic at offset 0
    if (uncompressedBytes[0] == 0x51 && // 'Q'
        uncompressedBytes[1] == 0x55 && // 'U'
        uncompressedBytes[2] == 0x49 && // 'I'
        uncompressedBytes[3] == 0x43) {  // 'C'
      print('[iOS] ✓ QUIC header detected');
      
      // Check ELF magic at offset 65536
      if (uncompressedBytes[65536] == 0x7f &&
          uncompressedBytes[65537] == 0x45 && // 'E'
          uncompressedBytes[65538] == 0x4c && // 'L'
          uncompressedBytes[65539] == 0x46) {  // 'F'
        print('[iOS] ✓ ELF at offset 65536 verified (differential linker format)');
      } else {
        throw Exception('Invalid .vmcode file: ELF not found at offset 65536');
      }
    } else {
      // Old format without header - shouldn't happen with linker
      throw Exception('Invalid .vmcode file: QUIC header not found');
    }
    
    final finalUncompressedSize = uncompressedBytes.length;
    
    // Apply compression
    String finalPath = vmcodePath;
    int compressedSize = finalUncompressedSize;
    if (compression == 'xz') {
      print('[iOS] Compressing with XZ...');
      finalPath = await _compressXz(vmcodePath);
      compressedSize = await File(finalPath).length();
      await vmcodeFile.delete(); // Remove uncompressed
      print('[iOS] ✅ Compressed: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
    }
    
    return PatchResult(
      patchPath: finalPath,
      patchHash: uncompressedHash,
      patchSize: compressedSize,
      uncompressedSize: uncompressedSize,
      oldSize: 0,
      newSize: uncompressedSize,
      compression: compression,
    );
  }

  /// Compress a binary for iOS (preserves code signature)
  /// iOS requires valid code signature, so we use the actual built binary
  static Future<PatchResult> compressBinary({
    required String binaryPath,
    required String outputDir,
    required String compression,
  }) async {
    print('[iOS Binary] Processing: $binaryPath');

    // Get uncompressed binary info
    final uncompressedBytes = await File(binaryPath).readAsBytes();
    final uncompressedSize = uncompressedBytes.length;
    final uncompressedHash = sha256.convert(uncompressedBytes).toString();

    print('[iOS Binary] Size: ${(uncompressedSize / 1024 / 1024).toStringAsFixed(2)} MB');
    print('[iOS Binary] Hash: $uncompressedHash');

    // Apply compression if specified
    String finalPath = binaryPath;
    int compressedSize = uncompressedSize;
    if (compression == 'xz') {
      print('[iOS Binary] Compressing with XZ...');
      
      // Check if already compressed
      final compressedPath = '$binaryPath.xz';
      if (await File(compressedPath).exists()) {
        print('[iOS Binary] Using existing compressed file');
        finalPath = compressedPath;
      } else {
        finalPath = await _compressXz(binaryPath);
      }
      
      compressedSize = await File(finalPath).length();
      print('[iOS Binary] ✅ Compressed: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
    }

    return PatchResult(
      patchPath: finalPath,
      patchHash: uncompressedHash, // Hash of uncompressed binary
      patchSize: compressedSize,
      uncompressedSize: uncompressedSize,
      oldSize: 0, // Not applicable
      newSize: uncompressedSize,
      compression: compression,
    );
  }
}

/// Result of patch generation
class PatchResult {
  final String patchPath;
  final String patchHash; // Hash of uncompressed patch
  final int patchSize; // Size of compressed patch
  final int uncompressedSize; // Size of uncompressed patch
  final int oldSize;
  final int newSize;
  final String compression;

  PatchResult({
    required this.patchPath,
    required this.patchHash,
    required this.patchSize,
    required this.uncompressedSize,
    required this.oldSize,
    required this.newSize,
    required this.compression,
  });

  double get compressionRatio => patchSize / uncompressedSize;
}
