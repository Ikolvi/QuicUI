import 'dart:typed_data';
import 'elf_parser.dart';
import 'macho_parser.dart';

/// Analyzes Dart AOT snapshots to identify changed functions
/// Supports comparing Mach-O baseline (iOS) with ELF patch
class SnapshotAnalyzer {
  final MachoFile? machoBaseline;
  final ElfFile? elfBaseline;
  final ElfFile patch;
  
  SnapshotAnalyzer.fromMacho(this.machoBaseline, this.patch)
      : elfBaseline = null;
  
  SnapshotAnalyzer.fromElf(this.elfBaseline, this.patch)
      : machoBaseline = null;
  
  /// Compare snapshots and identify differences
  Future<SnapshotDiff> analyze() async {
    print('\n=== Analyzing Snapshot Differences ===');
    
    final diff = SnapshotDiff();
    
    if (machoBaseline != null) {
      // Compare Mach-O baseline with ELF patch (iOS workflow)
      return _analyzeMachoVsElf(diff);
    } else if (elfBaseline != null) {
      // Compare ELF baseline with ELF patch (Android workflow)
      return _analyzeElfVsElf(diff);
    } else {
      throw Exception('No baseline provided');
    }
  }
  
  Future<SnapshotDiff> _analyzeMachoVsElf(SnapshotDiff diff) async {
    print('Comparing Mach-O baseline with ELF patch...');
    
    // Find Dart symbols in Mach-O
    final baseInstrSym = machoBaseline!.symbols
        .where((s) => s.name.contains('kDartIsolateSnapshotInstructions'))
        .firstOrNull;
    
    if (baseInstrSym == null) {
      throw Exception('Could not find kDartIsolateSnapshotInstructions in Mach-O baseline');
    }
    
    print('Baseline isolate instructions @ 0x${baseInstrSym.value.toRadixString(16)}');
    
    // Find corresponding section in ELF patch
    final patchTextSection = patch.sections['.text'];
    if (patchTextSection == null) {
      throw Exception('Could not find .text section in ELF patch');
    }
    
    print('Patch .text section: ${patchTextSection.size} bytes');
    
    // For now, mark entire patch as changed (full differential)
    // TODO: Implement byte-level comparison between Mach-O and ELF
    diff.changedRegions.add(ChangedRegion(
      '.text',
      0,
      patchTextSection.size,
    ));
    diff.totalChangedBytes = patchTextSection.size;
    
    // Find __TEXT segment in Mach-O for baseline size
    final textSeg = machoBaseline!.findSegment('__TEXT');
    final baselineSize = textSeg?.filesize ?? 0;
    
    print('\nDifferences found:');
    print('  Baseline __TEXT size: $baselineSize bytes');
    print('  Patch .text size: ${patchTextSection.size} bytes');
    print('  Total changed bytes: ${diff.totalChangedBytes}');
    if (baselineSize > 0) {
      print('  Change percentage: ${((diff.totalChangedBytes / baselineSize) * 100).toStringAsFixed(2)}%');
    }
    
    return diff;
  }
  
  Future<SnapshotDiff> _analyzeElfVsElf(SnapshotDiff diff) async {
    print('Comparing ELF baseline with ELF patch...');
    
    // Find Dart-specific symbols
    final baselineIsolateData = elfBaseline!.symbols['kDartIsolateSnapshotData'];
    final baselineIsolateInstr = elfBaseline!.symbols['kDartIsolateSnapshotInstructions'];
    final patchIsolateData = patch.symbols['kDartIsolateSnapshotData'];
    final patchIsolateInstr = patch.symbols['kDartIsolateSnapshotInstructions'];
    
    if (baselineIsolateData == null || patchIsolateData == null) {
      throw Exception('Could not find isolate data symbols');
    }
    
    if (baselineIsolateInstr == null || patchIsolateInstr == null) {
      throw Exception('Could not find isolate instruction symbols');
    }
    
    print('Baseline isolate data: ${baselineIsolateData.size} bytes');
    print('Patch isolate data: ${patchIsolateData.size} bytes');
    print('Baseline isolate instructions: ${baselineIsolateInstr.size} bytes');
    print('Patch isolate instructions: ${patchIsolateInstr.size} bytes');
    
    // Compare instruction sections (this is where code changes appear)
    final baseDataSection = elfBaseline!.sections['.rodata'] ?? elfBaseline!.sections['.data.rel.ro'];
    final patchDataSection = patch.sections['.rodata'] ?? patch.sections['.data.rel.ro'];
    
    if (baseDataSection != null && patchDataSection != null) {
      _compareSection(baseDataSection, patchDataSection, elfBaseline!.data, patch.data, diff);
    }
    
    // Compare text sections (executable code)
    final baseTextSection = elfBaseline!.sections['.text'];
    final patchTextSection = patch.sections['.text'];
    
    if (baseTextSection != null && patchTextSection != null) {
      _compareSection(baseTextSection, patchTextSection, elfBaseline!.data, patch.data, diff);
    }
    
    print('\nDifferences found:');
    print('  Changed symbols: ${diff.changedSymbols.length}');
    print('  New symbols: ${diff.newSymbols.length}');
    print('  Total changed bytes: ${diff.totalChangedBytes}');
    print('  Change percentage: ${((diff.totalChangedBytes / baselineIsolateInstr.size) * 100).toStringAsFixed(2)}%');
    
    return diff;
  }
  
  void _compareSection(
    ElfSection baseSection,
    ElfSection updatedSection,
    Uint8List baseData,
    Uint8List updatedData,
    SnapshotDiff diff,
  ) {
    print('\nComparing section: ${baseSection.name}');
    
    final minSize = baseSection.size < updatedSection.size ? baseSection.size : updatedSection.size;
    int changedBytes = 0;
    int currentDiffStart = -1;
    
    // Compare byte by byte to find changed regions
    for (int i = 0; i < minSize; i++) {
      final baseOffset = baseSection.offset + i;
      final updatedOffset = updatedSection.offset + i;
      
      if (baseData[baseOffset] != updatedData[updatedOffset]) {
        if (currentDiffStart == -1) {
          currentDiffStart = i;
        }
        changedBytes++;
      } else {
        if (currentDiffStart != -1) {
          // End of diff region
          final length = i - currentDiffStart;
          diff.changedRegions.add(ChangedRegion(
            baseSection.name,
            currentDiffStart,
            length,
          ));
          currentDiffStart = -1;
        }
      }
    }
    
    // Handle diff at end
    if (currentDiffStart != -1) {
      diff.changedRegions.add(ChangedRegion(
        baseSection.name,
        currentDiffStart,
        minSize - currentDiffStart,
      ));
    }
    
    // Handle size differences
    if (baseSection.size != updatedSection.size) {
      changedBytes += (baseSection.size - updatedSection.size).abs();
    }
    
    diff.totalChangedBytes += changedBytes;
    
    print('  Changed bytes: $changedBytes / $minSize (${((changedBytes / minSize) * 100).toStringAsFixed(2)}%)');
    print('  Changed regions: ${diff.changedRegions.where((r) => r.section == baseSection.name).length}');
  }
}

class SnapshotDiff {
  final List<String> changedSymbols = [];
  final List<String> newSymbols = [];
  final List<ChangedRegion> changedRegions = [];
  int totalChangedBytes = 0;
}

class ChangedRegion {
  final String section;
  final int offset;
  final int length;
  
  ChangedRegion(this.section, this.offset, this.length);
  
  @override
  String toString() => 'ChangedRegion($section, offset=$offset, length=$length)';
}
