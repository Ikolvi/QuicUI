/// QuicUI Differential AOT Linker
///
/// This library provides functionality to create differential patches
/// between baseline and updated AOT snapshots for iOS and Android code push.
///
/// ## Architecture
///
/// The linker works in two parts:
///
/// 1. **Dart CLI Tools** (this package - can be separate git repo):
///    - [ElfFile] - Parse ELF files (Android AOT, patch snapshots)
///    - [MachoFile] - Parse Mach-O files (iOS App binaries)
///    - [SnapshotAnalyzer] - Compare baseline and patch snapshots
///    - [DifferentialLinker] - Generate differential patches
///    - [VmcodeGenerator] - Create .vmcode files with QUIC header
///    - [LinkInfo] - Link tables for class/field/dispatch remapping
///
/// 2. **C++ Runtime** (must be in Dart SDK/Flutter engine):
///    - QuicuiLinker - Runtime linking of patches
///    - WrapperAllocator - CPU↔Interpreter transitions
///    - See: runtime/vm/quicui/ in engine build
///
/// ## Usage
///
/// ```dart
/// // Parse baseline and patch
/// final baseline = await parseMachoFile(iosAppFile);
/// final patch = await parseElfFile(patchElfFile);
///
/// // Analyze differences
/// final analyzer = SnapshotAnalyzer.fromMacho(baseline, patch);
/// final diff = await analyzer.analyze();
///
/// // Generate patch with link info
/// final linker = DifferentialLinker.forIOS(
///   baseline: baseline,
///   patch: patch,
///   diff: diff,
/// );
/// final patchData = await linker.generatePatch();
/// final linkInfo = linker.generateLinkInfo();
///
/// // Create .vmcode file
/// final generator = VmcodeGenerator();
/// await generator.generate(
///   patchElf: patchData,
///   outputFile: outputFile,
///   linkInfo: linkInfo,
/// );
/// ```
library quicui_linker;

// File parsers
export 'src/elf_parser.dart';
export 'src/macho_parser.dart';

// Snapshot analysis
export 'src/snapshot_analyzer.dart';

// Differential linking
export 'src/differential_linker.dart';
export 'src/link_info.dart';
export 'src/table_mappers.dart';

// Output generation
export 'src/vmcode_generator.dart';
