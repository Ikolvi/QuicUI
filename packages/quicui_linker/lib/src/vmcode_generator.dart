import 'dart:io';
import 'dart:typed_data';

import 'link_info.dart';

/// QuicUI .vmcode file format constants.
///
/// The vmcode format is:
/// - 64KB header containing magic, version, link info, and metadata
/// - ELF payload (Dart AOT snapshot)
class VmcodeFormat {
  /// Magic bytes: "QUIC" (0x51 0x55 0x49 0x43)
  static const magic = [0x51, 0x55, 0x49, 0x43];

  /// Current format version
  static const version = 1;

  /// Header size (64KB)
  static const headerSize = 65536;

  /// Header offsets
  static const offsetMagic = 0; // 4 bytes
  static const offsetVersion = 4; // 4 bytes
  static const offsetFlags = 8; // 4 bytes
  static const offsetLinkInfoOffset = 12; // 4 bytes
  static const offsetLinkInfoSize = 16; // 4 bytes
  static const offsetElfOffset = 20; // 8 bytes (64-bit)
  static const offsetElfSize = 28; // 8 bytes (64-bit)
  static const offsetChecksum = 36; // 4 bytes
  static const offsetReserved = 40; // Reserved for future use
  static const offsetLinkInfoData = 256; // Link info starts here

  /// Flag bits
  static const flagHasLinkInfo = 0x01;
  static const flagCompressed = 0x02;
  static const flagSigned = 0x04;
}

/// Generates .vmcode files with QuicUI header + ELF data.
///
/// The vmcode format allows the QuicUI runtime to:
/// 1. Validate the patch (magic, version, checksum)
/// 2. Read link info for remapping (class IDs, field offsets, etc.)
/// 3. Load the ELF payload into the Dart VM
class VmcodeGenerator {
  /// Create .vmcode file with 64KB header + ELF data.
  ///
  /// [patchElf] - The ELF data from gen_snapshot
  /// [outputFile] - Output .vmcode file
  /// [linkInfo] - Optional link information for remapping
  Future<File> generate({
    required Uint8List patchElf,
    required File outputFile,
    LinkInfo? linkInfo,
  }) async {
    print('\n=== Generating .vmcode File ===');

    final header = Uint8List(VmcodeFormat.headerSize);
    final headerData = ByteData.view(header.buffer);

    // Write magic bytes
    header[0] = VmcodeFormat.magic[0]; // 'Q'
    header[1] = VmcodeFormat.magic[1]; // 'U'
    header[2] = VmcodeFormat.magic[2]; // 'I'
    header[3] = VmcodeFormat.magic[3]; // 'C'

    // Version (bytes 4-7)
    headerData.setUint32(VmcodeFormat.offsetVersion, VmcodeFormat.version, Endian.little);

    // Flags
    int flags = 0;
    if (linkInfo != null && linkInfo.byteSize > 0) {
      flags |= VmcodeFormat.flagHasLinkInfo;
    }
    headerData.setUint32(VmcodeFormat.offsetFlags, flags, Endian.little);

    // Link info
    int linkInfoSize = 0;
    if (linkInfo != null) {
      final linkInfoBytes = linkInfo.toBytes();
      linkInfoSize = linkInfoBytes.length;

      // Check if link info fits in header (between offset 256 and 65536)
      if (VmcodeFormat.offsetLinkInfoData + linkInfoSize > VmcodeFormat.headerSize) {
        throw Exception(
            'Link info too large: $linkInfoSize bytes (max: ${VmcodeFormat.headerSize - VmcodeFormat.offsetLinkInfoData})');
      }

      // Write link info offset and size
      headerData.setUint32(VmcodeFormat.offsetLinkInfoOffset, VmcodeFormat.offsetLinkInfoData, Endian.little);
      headerData.setUint32(VmcodeFormat.offsetLinkInfoSize, linkInfoSize, Endian.little);

      // Copy link info into header
      header.setRange(VmcodeFormat.offsetLinkInfoData, VmcodeFormat.offsetLinkInfoData + linkInfoSize, linkInfoBytes);

      print('Link info: $linkInfoSize bytes at offset ${VmcodeFormat.offsetLinkInfoData}');
    } else {
      headerData.setUint32(VmcodeFormat.offsetLinkInfoOffset, 0, Endian.little);
      headerData.setUint32(VmcodeFormat.offsetLinkInfoSize, 0, Endian.little);
    }

    // ELF offset (always at end of header)
    headerData.setUint64(VmcodeFormat.offsetElfOffset, VmcodeFormat.headerSize, Endian.little);

    // ELF size
    headerData.setUint64(VmcodeFormat.offsetElfSize, patchElf.length, Endian.little);

    // Calculate simple checksum (sum of all ELF bytes mod 2^32)
    int checksum = 0;
    for (final byte in patchElf) {
      checksum = (checksum + byte) & 0xFFFFFFFF;
    }
    headerData.setUint32(VmcodeFormat.offsetChecksum, checksum, Endian.little);

    // Write header + ELF to output file
    final sink = outputFile.openWrite();
    sink.add(header);
    sink.add(patchElf);
    await sink.close();

    final fileSize = await outputFile.length();
    print('Created .vmcode file: ${outputFile.path}');
    print('  Magic: QUIC');
    print('  Version: ${VmcodeFormat.version}');
    print('  Flags: 0x${flags.toRadixString(16)}');
    print('  Link info: $linkInfoSize bytes');
    print('  Header: ${VmcodeFormat.headerSize} bytes');
    print('  ELF: ${patchElf.length} bytes');
    print('  Total: $fileSize bytes');
    print('  Checksum: 0x${checksum.toRadixString(16)}');

    return outputFile;
  }

  /// Read and validate a .vmcode file header.
  static Future<VmcodeHeader> readHeader(File file) async {
    final data = await file.openRead(0, VmcodeFormat.headerSize).fold<List<int>>(
      [],
      (previous, element) => previous..addAll(element),
    );

    if (data.length < VmcodeFormat.headerSize) {
      throw Exception('File too small: ${data.length} bytes (expected at least ${VmcodeFormat.headerSize})');
    }

    final header = Uint8List.fromList(data);
    return VmcodeHeader.fromBytes(header);
  }
}

/// Parsed vmcode header information.
class VmcodeHeader {
  final bool isValid;
  final int version;
  final int flags;
  final int linkInfoOffset;
  final int linkInfoSize;
  final int elfOffset;
  final int elfSize;
  final int checksum;
  final LinkInfo? linkInfo;

  VmcodeHeader({
    required this.isValid,
    required this.version,
    required this.flags,
    required this.linkInfoOffset,
    required this.linkInfoSize,
    required this.elfOffset,
    required this.elfSize,
    required this.checksum,
    this.linkInfo,
  });

  factory VmcodeHeader.fromBytes(Uint8List header) {
    // Verify magic
    final isValid = header[0] == 0x51 && // 'Q'
        header[1] == 0x55 && // 'U'
        header[2] == 0x49 && // 'I'
        header[3] == 0x43; // 'C'

    final data = ByteData.view(header.buffer, header.offsetInBytes);

    final version = data.getUint32(VmcodeFormat.offsetVersion, Endian.little);
    final flags = data.getUint32(VmcodeFormat.offsetFlags, Endian.little);
    final linkInfoOffset = data.getUint32(VmcodeFormat.offsetLinkInfoOffset, Endian.little);
    final linkInfoSize = data.getUint32(VmcodeFormat.offsetLinkInfoSize, Endian.little);
    final elfOffset = data.getUint64(VmcodeFormat.offsetElfOffset, Endian.little);
    final elfSize = data.getUint64(VmcodeFormat.offsetElfSize, Endian.little);
    final checksum = data.getUint32(VmcodeFormat.offsetChecksum, Endian.little);

    // Parse link info if present
    LinkInfo? linkInfo;
    if ((flags & VmcodeFormat.flagHasLinkInfo) != 0 && linkInfoSize > 0) {
      final linkInfoBytes = header.sublist(linkInfoOffset, linkInfoOffset + linkInfoSize);
      linkInfo = LinkInfo.fromBytes(linkInfoBytes);
    }

    return VmcodeHeader(
      isValid: isValid,
      version: version,
      flags: flags,
      linkInfoOffset: linkInfoOffset,
      linkInfoSize: linkInfoSize,
      elfOffset: elfOffset,
      elfSize: elfSize,
      checksum: checksum,
      linkInfo: linkInfo,
    );
  }

  bool get hasLinkInfo => (flags & VmcodeFormat.flagHasLinkInfo) != 0;
  bool get isCompressed => (flags & VmcodeFormat.flagCompressed) != 0;
  bool get isSigned => (flags & VmcodeFormat.flagSigned) != 0;

  @override
  String toString() => '''VmcodeHeader(
  isValid: $isValid,
  version: $version,
  flags: 0x${flags.toRadixString(16)},
  linkInfoOffset: $linkInfoOffset,
  linkInfoSize: $linkInfoSize,
  elfOffset: $elfOffset,
  elfSize: $elfSize,
  checksum: 0x${checksum.toRadixString(16)},
  hasLinkInfo: $hasLinkInfo,
)''';
}
