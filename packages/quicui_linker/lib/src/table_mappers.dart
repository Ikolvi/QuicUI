// Copyright (c) 2024, QuicUI. All rights reserved.
// Use of this source code is governed by a BSD-style license.

import 'elf_parser.dart';
import 'macho_parser.dart';
import 'link_info.dart';

/// Maps class IDs between baseline and patch builds.
///
/// When the Dart compiler generates AOT snapshots, each class gets
/// a unique ID. These IDs can differ between builds, so we need
/// to create a mapping table.
class ClassTableMapper {
  /// Symbols containing class information from baseline.
  final Map<String, int> baselineClasses;

  /// Symbols containing class information from patch.
  final Map<String, int> patchClasses;

  ClassTableMapper({
    required this.baselineClasses,
    required this.patchClasses,
  });

  /// Create mapper from ELF files.
  factory ClassTableMapper.fromElf(ElfFile baseline, ElfFile patch) {
    return ClassTableMapper(
      baselineClasses: _extractClassIdsFromElf(baseline),
      patchClasses: _extractClassIdsFromElf(patch),
    );
  }

  /// Create mapper from Mach-O baseline and ELF patch.
  factory ClassTableMapper.fromMacho(MachoFile baseline, ElfFile patch) {
    return ClassTableMapper(
      baselineClasses: _extractClassIdsFromMacho(baseline),
      patchClasses: _extractClassIdsFromElf(patch),
    );
  }

  /// Extract class IDs from ELF symbols.
  ///
  /// Dart AOT snapshots contain class information in the isolate data section.
  /// We look for symbols related to class table.
  static Map<String, int> _extractClassIdsFromElf(ElfFile elf) {
    final classes = <String, int>{};

    // Look for class-related symbols
    // The class table is part of the isolate snapshot
    for (final entry in elf.symbols.entries) {
      final name = entry.key;
      final symbol = entry.value;

      // Class symbols follow patterns like:
      // - _kDart*Class*
      // - Allocation stubs: *AllocationStub
      if (name.contains('Class') ||
          name.contains('AllocationStub') ||
          name.contains('_Type_')) {
        classes[name] = symbol.value;
      }
    }

    return classes;
  }

  /// Extract class IDs from Mach-O symbols.
  static Map<String, int> _extractClassIdsFromMacho(MachoFile macho) {
    final classes = <String, int>{};

    for (final symbol in macho.symbols) {
      if (symbol.name.contains('Class') ||
          symbol.name.contains('AllocationStub') ||
          symbol.name.contains('_Type_')) {
        classes[symbol.name] = symbol.value;
      }
    }

    return classes;
  }

  /// Generate class table entries by matching class names.
  List<ClassTableEntry> generateTable() {
    final entries = <ClassTableEntry>[];

    // Match classes by name
    for (final patchEntry in patchClasses.entries) {
      final name = patchEntry.key;
      final patchId = patchEntry.value;

      // Find corresponding class in baseline
      if (baselineClasses.containsKey(name)) {
        final baselineId = baselineClasses[name]!;

        // Only add if IDs differ
        if (patchId != baselineId) {
          entries.add(ClassTableEntry(
            patchClassId: patchId,
            baselineClassId: baselineId,
            className: name,
          ));
        }
      }
    }

    return entries;
  }

  /// Get statistics about the mapping.
  Map<String, int> get stats => {
        'baselineClasses': baselineClasses.length,
        'patchClasses': patchClasses.length,
        'mappedClasses':
            patchClasses.keys.where(baselineClasses.containsKey).length,
        'newClasses':
            patchClasses.keys.where((k) => !baselineClasses.containsKey(k)).length,
        'removedClasses':
            baselineClasses.keys.where((k) => !patchClasses.containsKey(k)).length,
      };
}

/// Maps field offsets between baseline and patch builds.
class FieldTableMapper {
  final ElfFile? elfBaseline;
  final MachoFile? machoBaseline;
  final ElfFile patch;

  FieldTableMapper._({
    this.elfBaseline,
    this.machoBaseline,
    required this.patch,
  });

  factory FieldTableMapper.fromElf(ElfFile baseline, ElfFile patch) {
    return FieldTableMapper._(elfBaseline: baseline, patch: patch);
  }

  factory FieldTableMapper.fromMacho(MachoFile baseline, ElfFile patch) {
    return FieldTableMapper._(machoBaseline: baseline, patch: patch);
  }

  /// Generate field table entries.
  ///
  /// Field offsets are embedded in the code and need to be remapped
  /// if the class layout changed.
  List<FieldTableEntry> generateTable() {
    // TODO: Implement actual field offset extraction from AOT data
    // This requires parsing the Dart snapshot format
    return [];
  }
}

/// Maps dispatch table indices between baseline and patch.
class DispatchTableMapper {
  final ElfFile? elfBaseline;
  final MachoFile? machoBaseline;
  final ElfFile patch;

  DispatchTableMapper._({
    this.elfBaseline,
    this.machoBaseline,
    required this.patch,
  });

  factory DispatchTableMapper.fromElf(ElfFile baseline, ElfFile patch) {
    return DispatchTableMapper._(elfBaseline: baseline, patch: patch);
  }

  factory DispatchTableMapper.fromMacho(MachoFile baseline, ElfFile patch) {
    return DispatchTableMapper._(machoBaseline: baseline, patch: patch);
  }

  /// Generate dispatch table entries.
  List<DispatchTableEntry> generateTable() {
    // TODO: Implement dispatch table extraction
    // The dispatch table is used for virtual method calls
    return [];
  }
}

/// Maps object pool indices between baseline and patch.
class ObjectPoolMapper {
  final ElfFile? elfBaseline;
  final MachoFile? machoBaseline;
  final ElfFile patch;

  ObjectPoolMapper._({
    this.elfBaseline,
    this.machoBaseline,
    required this.patch,
  });

  factory ObjectPoolMapper.fromElf(ElfFile baseline, ElfFile patch) {
    return ObjectPoolMapper._(elfBaseline: baseline, patch: patch);
  }

  factory ObjectPoolMapper.fromMacho(MachoFile baseline, ElfFile patch) {
    return ObjectPoolMapper._(machoBaseline: baseline, patch: patch);
  }

  /// Generate object pool entries.
  List<ObjectPoolEntry> generateTable() {
    // TODO: Implement object pool extraction
    // The object pool contains constants and cached objects
    return [];
  }
}

/// Main class for generating link info from baseline and patch.
class LinkInfoGenerator {
  final ElfFile? elfBaseline;
  final MachoFile? machoBaseline;
  final ElfFile patch;

  LinkInfoGenerator._({
    this.elfBaseline,
    this.machoBaseline,
    required this.patch,
  });

  /// Create generator for ELF baseline (Android).
  factory LinkInfoGenerator.fromElf(ElfFile baseline, ElfFile patch) {
    return LinkInfoGenerator._(elfBaseline: baseline, patch: patch);
  }

  /// Create generator for Mach-O baseline (iOS).
  factory LinkInfoGenerator.fromMacho(MachoFile baseline, ElfFile patch) {
    return LinkInfoGenerator._(machoBaseline: baseline, patch: patch);
  }

  /// Generate complete link information.
  LinkInfo generate() {
    print('\n=== Generating Link Info ===');

    // Generate class table
    final ClassTableMapper classMapper;
    if (machoBaseline != null) {
      classMapper = ClassTableMapper.fromMacho(machoBaseline!, patch);
    } else {
      classMapper = ClassTableMapper.fromElf(elfBaseline!, patch);
    }
    final classTable = classMapper.generateTable();
    print('Class table: ${classTable.length} remapped entries');
    print('  Stats: ${classMapper.stats}');

    // Generate field table
    final FieldTableMapper fieldMapper;
    if (machoBaseline != null) {
      fieldMapper = FieldTableMapper.fromMacho(machoBaseline!, patch);
    } else {
      fieldMapper = FieldTableMapper.fromElf(elfBaseline!, patch);
    }
    final fieldTable = fieldMapper.generateTable();
    print('Field table: ${fieldTable.length} remapped entries');

    // Generate dispatch table
    final DispatchTableMapper dispatchMapper;
    if (machoBaseline != null) {
      dispatchMapper = DispatchTableMapper.fromMacho(machoBaseline!, patch);
    } else {
      dispatchMapper = DispatchTableMapper.fromElf(elfBaseline!, patch);
    }
    final dispatchTable = dispatchMapper.generateTable();
    print('Dispatch table: ${dispatchTable.length} remapped entries');

    // Generate object pool
    final ObjectPoolMapper poolMapper;
    if (machoBaseline != null) {
      poolMapper = ObjectPoolMapper.fromMacho(machoBaseline!, patch);
    } else {
      poolMapper = ObjectPoolMapper.fromElf(elfBaseline!, patch);
    }
    final objectPool = poolMapper.generateTable();
    print('Object pool: ${objectPool.length} remapped entries');

    final linkInfo = LinkInfo(
      classTable: classTable,
      fieldTable: fieldTable,
      dispatchTable: dispatchTable,
      objectPool: objectPool,
    );

    print('Total link info size: ${linkInfo.byteSize} bytes');

    return linkInfo;
  }
}
