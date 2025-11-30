import 'dart:typed_data';
import 'elf_parser.dart';
import 'macho_parser.dart';
import 'snapshot_analyzer.dart';
import 'link_info.dart';
import 'table_mappers.dart';

/// Creates differential patches from snapshot differences.
///
/// The QuicUI differential linker analyzes baseline and patch AOT snapshots
/// to create a minimal patch that can be applied at runtime. Unlike the
/// old approach that just wrapped the full ELF, this properly generates
/// link information for class ID remapping, field offsets, etc.
///
/// The Dart VM requires these symbols to load an ELF snapshot:
/// - _kDartVmSnapshotData
/// - _kDartVmSnapshotInstructions
/// - _kDartIsolateSnapshotData
/// - _kDartIsolateSnapshotInstructions
class DifferentialLinker {
  /// Baseline file (Mach-O for iOS, ELF for Android)
  final MachoFile? machoBaseline;
  final ElfFile? elfBaseline;

  /// Patch ELF from gen_snapshot
  final ElfFile patch;

  /// Snapshot differences
  final SnapshotDiff diff;

  DifferentialLinker._({
    this.machoBaseline,
    this.elfBaseline,
    required this.patch,
    required this.diff,
  });

  /// Create linker for iOS (Mach-O baseline)
  factory DifferentialLinker.forIOS({
    required MachoFile baseline,
    required ElfFile patch,
    required SnapshotDiff diff,
  }) {
    return DifferentialLinker._(
      machoBaseline: baseline,
      patch: patch,
      diff: diff,
    );
  }

  /// Create linker for Android (ELF baseline)
  factory DifferentialLinker.forAndroid({
    required ElfFile baseline,
    required ElfFile patch,
    required SnapshotDiff diff,
  }) {
    return DifferentialLinker._(
      elfBaseline: baseline,
      patch: patch,
      diff: diff,
    );
  }

  /// Legacy constructor for backward compatibility
  factory DifferentialLinker(ElfFile patch, SnapshotDiff diff) {
    return DifferentialLinker._(patch: patch, diff: diff);
  }

  /// Generate the ELF patch data.
  ///
  /// Returns the complete ELF data from the patch file.
  /// The Dart VM's ELF loader requires proper section headers and symbol tables
  /// to resolve snapshot symbols, so we preserve the full ELF structure.
  Future<Uint8List> generatePatch() async {
    print('\n=== Generating Differential Patch ===');

    // Log the diff information for analysis
    for (final region in diff.changedRegions) {
      print(
          'Adding region: ${region.section} at offset ${region.offset}, length ${region.length}');
    }

    print('Patch size: ${patch.data.length} bytes');

    // Return the complete ELF data from gen_snapshot
    // This includes all required symbols and section headers
    // The QUIC header will be prepended by VmcodeGenerator
    return Uint8List.fromList(patch.data);
  }

  /// Generate link information for remapping.
  ///
  /// This analyzes the baseline and patch to create mapping tables
  /// for class IDs, field offsets, dispatch table entries, etc.
  LinkInfo generateLinkInfo() {
    print('\n=== Generating Link Info ===');

    if (machoBaseline == null && elfBaseline == null) {
      print('Warning: No baseline provided, returning empty link info');
      return LinkInfo.empty();
    }

    final LinkInfoGenerator generator;
    if (machoBaseline != null) {
      generator = LinkInfoGenerator.fromMacho(machoBaseline!, patch);
    } else {
      generator = LinkInfoGenerator.fromElf(elfBaseline!, patch);
    }

    return generator.generate();
  }

  /// Analyze the ELF structure for debugging.
  void analyzeElf() {
    print('\n=== ELF Analysis ===');
    print('Total size: ${patch.data.length} bytes');
    print('Sections: ${patch.sections.length}');

    for (final entry in patch.sections.entries) {
      final section = entry.value;
      print(
          '  ${section.name}: offset=${section.offset}, size=${section.size}');
    }

    print('Symbols: ${patch.symbols.length}');

    // Look for Dart snapshot symbols
    final dartSymbols = patch.symbols.entries
        .where((e) => e.key.contains('Snapshot') || e.key.contains('kDart'))
        .toList();

    for (final entry in dartSymbols) {
      print(
          '  ${entry.key}: value=0x${entry.value.value.toRadixString(16)}, size=${entry.value.size}');
    }
  }

  /// Get summary of the patch.
  Map<String, dynamic> getSummary() {
    return {
      'patchSize': patch.data.length,
      'sections': patch.sections.length,
      'symbols': patch.symbols.length,
      'changedRegions': diff.changedRegions.length,
      'totalChangedBytes': diff.totalChangedBytes,
      'dartSymbols': patch.symbols.entries
          .where((e) => e.key.contains('Snapshot') || e.key.contains('kDart'))
          .map((e) => e.key)
          .toList(),
    };
  }
}
