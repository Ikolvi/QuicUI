// Copyright (c) 2024, QuicUI. All rights reserved.
// Use of this source code is governed by a BSD-style license.

import 'dart:typed_data';

/// Link information for differential patches.
///
/// When creating a patch, we need to map IDs/indices from the new build
/// to the baseline build. This is because the Dart VM assigns IDs at
/// compile time, and they may differ between builds.

/// Entry in the class ID remapping table.
///
/// Maps a class ID from the patch build to the baseline build.
class ClassTableEntry {
  /// Class ID in the new (patch) build.
  final int patchClassId;

  /// Class ID in the baseline build.
  final int baselineClassId;

  /// Name of the class (for debugging).
  final String? className;

  ClassTableEntry({
    required this.patchClassId,
    required this.baselineClassId,
    this.className,
  });

  /// Serialize to bytes (8 bytes: 4 for patch ID, 4 for baseline ID).
  Uint8List toBytes() {
    final data = ByteData(8);
    data.setUint32(0, patchClassId, Endian.little);
    data.setUint32(4, baselineClassId, Endian.little);
    return data.buffer.asUint8List();
  }

  /// Deserialize from bytes.
  factory ClassTableEntry.fromBytes(Uint8List bytes, [int offset = 0]) {
    final data = ByteData.view(bytes.buffer, bytes.offsetInBytes + offset);
    return ClassTableEntry(
      patchClassId: data.getUint32(0, Endian.little),
      baselineClassId: data.getUint32(4, Endian.little),
    );
  }

  @override
  String toString() =>
      'ClassTableEntry(patch=$patchClassId -> baseline=$baselineClassId${className != null ? ', $className' : ''})';
}

/// Entry in the field offset remapping table.
class FieldTableEntry {
  /// Field offset in the new (patch) build.
  final int patchOffset;

  /// Field offset in the baseline build.
  final int baselineOffset;

  /// Class ID this field belongs to.
  final int classId;

  /// Name of the field (for debugging).
  final String? fieldName;

  FieldTableEntry({
    required this.patchOffset,
    required this.baselineOffset,
    required this.classId,
    this.fieldName,
  });

  /// Serialize to bytes (12 bytes).
  Uint8List toBytes() {
    final data = ByteData(12);
    data.setUint32(0, patchOffset, Endian.little);
    data.setUint32(4, baselineOffset, Endian.little);
    data.setUint32(8, classId, Endian.little);
    return data.buffer.asUint8List();
  }

  /// Deserialize from bytes.
  factory FieldTableEntry.fromBytes(Uint8List bytes, [int offset = 0]) {
    final data = ByteData.view(bytes.buffer, bytes.offsetInBytes + offset);
    return FieldTableEntry(
      patchOffset: data.getUint32(0, Endian.little),
      baselineOffset: data.getUint32(4, Endian.little),
      classId: data.getUint32(8, Endian.little),
    );
  }

  @override
  String toString() =>
      'FieldTableEntry(patch=$patchOffset -> baseline=$baselineOffset, class=$classId${fieldName != null ? ', $fieldName' : ''})';
}

/// Entry in the dispatch table remapping.
///
/// The dispatch table is used for virtual method calls.
/// Each entry maps a selector to a method implementation.
class DispatchTableEntry {
  /// Index in the patch dispatch table.
  final int patchIndex;

  /// Index in the baseline dispatch table.
  final int baselineIndex;

  /// Selector ID for this dispatch entry.
  final int selectorId;

  DispatchTableEntry({
    required this.patchIndex,
    required this.baselineIndex,
    required this.selectorId,
  });

  /// Serialize to bytes (12 bytes).
  Uint8List toBytes() {
    final data = ByteData(12);
    data.setUint32(0, patchIndex, Endian.little);
    data.setUint32(4, baselineIndex, Endian.little);
    data.setUint32(8, selectorId, Endian.little);
    return data.buffer.asUint8List();
  }

  /// Deserialize from bytes.
  factory DispatchTableEntry.fromBytes(Uint8List bytes, [int offset = 0]) {
    final data = ByteData.view(bytes.buffer, bytes.offsetInBytes + offset);
    return DispatchTableEntry(
      patchIndex: data.getUint32(0, Endian.little),
      baselineIndex: data.getUint32(4, Endian.little),
      selectorId: data.getUint32(8, Endian.little),
    );
  }

  @override
  String toString() =>
      'DispatchTableEntry(patch=$patchIndex -> baseline=$baselineIndex, selector=$selectorId)';
}

/// Entry in the object pool remapping.
///
/// The object pool contains constants, strings, and other objects
/// that are referenced by compiled code.
class ObjectPoolEntry {
  /// Index in the patch object pool.
  final int patchIndex;

  /// Index in the baseline object pool.
  final int baselineIndex;

  /// Type of object (for validation).
  final ObjectPoolEntryType type;

  ObjectPoolEntry({
    required this.patchIndex,
    required this.baselineIndex,
    required this.type,
  });

  /// Serialize to bytes (12 bytes).
  Uint8List toBytes() {
    final data = ByteData(12);
    data.setUint32(0, patchIndex, Endian.little);
    data.setUint32(4, baselineIndex, Endian.little);
    data.setUint32(8, type.index, Endian.little);
    return data.buffer.asUint8List();
  }

  /// Deserialize from bytes.
  factory ObjectPoolEntry.fromBytes(Uint8List bytes, [int offset = 0]) {
    final data = ByteData.view(bytes.buffer, bytes.offsetInBytes + offset);
    return ObjectPoolEntry(
      patchIndex: data.getUint32(0, Endian.little),
      baselineIndex: data.getUint32(4, Endian.little),
      type: ObjectPoolEntryType.values[data.getUint32(8, Endian.little)],
    );
  }

  @override
  String toString() =>
      'ObjectPoolEntry(patch=$patchIndex -> baseline=$baselineIndex, type=$type)';
}

/// Types of entries in the object pool.
enum ObjectPoolEntryType {
  /// Null or immediate value.
  immediate,

  /// Class object.
  classObject,

  /// Type arguments.
  typeArguments,

  /// Closure function.
  closure,

  /// String constant.
  string,

  /// Integer constant.
  integer,

  /// Double constant.
  double_,

  /// Other object.
  other,
}

/// Complete link information for a differential patch.
///
/// This contains all the mapping tables needed for the runtime
/// to link a patch against the baseline.
class LinkInfo {
  /// Class ID remapping table.
  final List<ClassTableEntry> classTable;

  /// Field offset remapping table.
  final List<FieldTableEntry> fieldTable;

  /// Dispatch table remapping.
  final List<DispatchTableEntry> dispatchTable;

  /// Object pool remapping.
  final List<ObjectPoolEntry> objectPool;

  /// Version of the link format.
  final int version;

  LinkInfo({
    required this.classTable,
    required this.fieldTable,
    required this.dispatchTable,
    required this.objectPool,
    this.version = 1,
  });

  /// Create empty link info.
  factory LinkInfo.empty() => LinkInfo(
        classTable: [],
        fieldTable: [],
        dispatchTable: [],
        objectPool: [],
      );

  /// Serialize to bytes for embedding in vmcode header.
  ///
  /// Format:
  /// - 4 bytes: version
  /// - 4 bytes: class table count
  /// - 4 bytes: field table count
  /// - 4 bytes: dispatch table count
  /// - 4 bytes: object pool count
  /// - N * 8 bytes: class table entries
  /// - N * 12 bytes: field table entries
  /// - N * 12 bytes: dispatch table entries
  /// - N * 12 bytes: object pool entries
  Uint8List toBytes() {
    // Calculate total size
    final headerSize = 20; // 5 x 4 bytes
    final classTableSize = classTable.length * 8;
    final fieldTableSize = fieldTable.length * 12;
    final dispatchTableSize = dispatchTable.length * 12;
    final objectPoolSize = objectPool.length * 12;
    final totalSize = headerSize +
        classTableSize +
        fieldTableSize +
        dispatchTableSize +
        objectPoolSize;

    final result = ByteData(totalSize);
    var offset = 0;

    // Header
    result.setUint32(offset, version, Endian.little);
    offset += 4;
    result.setUint32(offset, classTable.length, Endian.little);
    offset += 4;
    result.setUint32(offset, fieldTable.length, Endian.little);
    offset += 4;
    result.setUint32(offset, dispatchTable.length, Endian.little);
    offset += 4;
    result.setUint32(offset, objectPool.length, Endian.little);
    offset += 4;

    // Class table
    for (final entry in classTable) {
      final bytes = entry.toBytes();
      result.buffer.asUint8List().setRange(offset, offset + 8, bytes);
      offset += 8;
    }

    // Field table
    for (final entry in fieldTable) {
      final bytes = entry.toBytes();
      result.buffer.asUint8List().setRange(offset, offset + 12, bytes);
      offset += 12;
    }

    // Dispatch table
    for (final entry in dispatchTable) {
      final bytes = entry.toBytes();
      result.buffer.asUint8List().setRange(offset, offset + 12, bytes);
      offset += 12;
    }

    // Object pool
    for (final entry in objectPool) {
      final bytes = entry.toBytes();
      result.buffer.asUint8List().setRange(offset, offset + 12, bytes);
      offset += 12;
    }

    return result.buffer.asUint8List();
  }

  /// Deserialize from bytes.
  factory LinkInfo.fromBytes(Uint8List bytes) {
    final data = ByteData.view(bytes.buffer, bytes.offsetInBytes);
    var offset = 0;

    final version = data.getUint32(offset, Endian.little);
    offset += 4;
    final classCount = data.getUint32(offset, Endian.little);
    offset += 4;
    final fieldCount = data.getUint32(offset, Endian.little);
    offset += 4;
    final dispatchCount = data.getUint32(offset, Endian.little);
    offset += 4;
    final poolCount = data.getUint32(offset, Endian.little);
    offset += 4;

    final classTable = <ClassTableEntry>[];
    for (var i = 0; i < classCount; i++) {
      classTable.add(ClassTableEntry.fromBytes(bytes, offset));
      offset += 8;
    }

    final fieldTable = <FieldTableEntry>[];
    for (var i = 0; i < fieldCount; i++) {
      fieldTable.add(FieldTableEntry.fromBytes(bytes, offset));
      offset += 12;
    }

    final dispatchTable = <DispatchTableEntry>[];
    for (var i = 0; i < dispatchCount; i++) {
      dispatchTable.add(DispatchTableEntry.fromBytes(bytes, offset));
      offset += 12;
    }

    final objectPool = <ObjectPoolEntry>[];
    for (var i = 0; i < poolCount; i++) {
      objectPool.add(ObjectPoolEntry.fromBytes(bytes, offset));
      offset += 12;
    }

    return LinkInfo(
      classTable: classTable,
      fieldTable: fieldTable,
      dispatchTable: dispatchTable,
      objectPool: objectPool,
      version: version,
    );
  }

  /// Size in bytes when serialized.
  int get byteSize =>
      20 + // header
      classTable.length * 8 +
      fieldTable.length * 12 +
      dispatchTable.length * 12 +
      objectPool.length * 12;

  @override
  String toString() => '''LinkInfo(
  version: $version,
  classTable: ${classTable.length} entries,
  fieldTable: ${fieldTable.length} entries,
  dispatchTable: ${dispatchTable.length} entries,
  objectPool: ${objectPool.length} entries,
  totalBytes: $byteSize
)''';
}
