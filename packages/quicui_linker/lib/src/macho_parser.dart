import 'dart:io';
import 'dart:typed_data';

/// Segment in a Mach-O file
class MachoSegment {
  final String name;
  final int vmaddr;
  final int vmsize;
  final int fileoff;
  final int filesize;
  final Uint8List data;
  
  MachoSegment({
    required this.name,
    required this.vmaddr,
    required this.vmsize,
    required this.fileoff,
    required this.filesize,
    required this.data,
  });
}

/// Symbol in a Mach-O file
class MachoSymbol {
  final String name;
  final int value;
  
  MachoSymbol({required this.name, required this.value});
}

/// Mach-O file parser for iOS App binaries
/// 
/// Mach-O (Mach Object) is Apple's executable format used on macOS and iOS.
/// This parser extracts code segments and symbols needed for differential linking.
class MachoFile {
  final File file;
  final Uint8List data;
  
  // Mach-O header constants
  static const MH_MAGIC_64 = 0xFEEDFACF; // 64-bit Mach-O magic
  static const MH_CIGAM_64 = 0xCFFAEDFE; // 64-bit Mach-O magic (byte-swapped)
  static const FAT_MAGIC = 0xCAFEBABE;   // Universal binary magic
  static const FAT_CIGAM = 0xBEBAFECA;   // Universal binary magic (byte-swapped)
  
  // Load command types
  static const LC_SEGMENT_64 = 0x19;
  static const LC_SYMTAB = 0x2;
  
  // Segment names
  static const SEG_TEXT = '__TEXT';
  static const SEG_DATA = '__DATA';
  
  bool isLittleEndian = true;
  int ncmds = 0;
  int sizeofcmds = 0;
  
  List<MachoSegment> segments = [];
  List<MachoSymbol> symbols = [];
  
  MachoFile(this.file, this.data);
  
  /// Parse a Mach-O file
  static Future<MachoFile> parse(File file) async {
    final data = await file.readAsBytes();
    
    // Check for universal binary (FAT)
    final magic32 = ByteData.sublistView(data, 0, 4).getUint32(0, Endian.big);
    
    Uint8List actualData = data;
    
    if (magic32 == FAT_MAGIC || magic32 == FAT_CIGAM) {
      print('[Mach-O] Universal binary detected, extracting arm64 slice...');
      
      // struct fat_header {
      //   uint32_t magic;      // 0
      //   uint32_t nfat_arch;  // 4 - number of architectures
      // };
      final nfat_arch = ByteData.sublistView(data, 4, 8).getUint32(0, Endian.big);
      print('[Mach-O] Found $nfat_arch architecture(s)');
      
      // Find arm64 slice
      // struct fat_arch {
      //   int32_t  cputype;    // 0
      //   int32_t  cpusubtype; // 4
      //   uint32_t offset;     // 8 - file offset
      //   uint32_t size;       // 12 - size of slice
      //   uint32_t align;      // 16 - alignment
      // };
      
      const CPU_TYPE_ARM64 = 0x0100000C; // ARM64 CPU type
      
      for (int i = 0; i < nfat_arch; i++) {
        final archOffset = 8 + (i * 20); // Header is 8 bytes, each arch is 20 bytes
        final cputype = ByteData.sublistView(data, archOffset, archOffset + 4).getInt32(0, Endian.big);
        
        if (cputype == CPU_TYPE_ARM64) {
          final sliceOffset = ByteData.sublistView(data, archOffset + 8, archOffset + 12).getUint32(0, Endian.big);
          final sliceSize = ByteData.sublistView(data, archOffset + 12, archOffset + 16).getUint32(0, Endian.big);
          
          print('[Mach-O] Found ARM64 slice at offset $sliceOffset, size $sliceSize');
          actualData = data.sublist(sliceOffset, sliceOffset + sliceSize);
          break;
        }
      }
    }
    
    final macho = MachoFile(file, actualData);
    
    // Check for Mach-O magic
    final magic = macho._read32(0);
    if (magic == MH_MAGIC_64) {
      macho.isLittleEndian = true;
    } else if (magic == MH_CIGAM_64) {
      macho.isLittleEndian = false;
    } else {
      throw Exception('Not a valid 64-bit Mach-O file: ${file.path} (magic: 0x${magic.toRadixString(16)})');
    }
    
    // Parse Mach-O header (offset 0)
    // struct mach_header_64 {
    //   uint32_t magic;        // 0
    //   int32_t  cputype;      // 4
    //   int32_t  cpusubtype;   // 8
    //   uint32_t filetype;     // 12
    //   uint32_t ncmds;        // 16
    //   uint32_t sizeofcmds;   // 20
    //   uint32_t flags;        // 24
    //   uint32_t reserved;     // 28
    // };
    
    macho.ncmds = macho._read32(16);
    macho.sizeofcmds = macho._read32(20);
    
    print('[Mach-O] Parsing ${file.path}');
    print('[Mach-O] Commands: ${macho.ncmds}');
    print('[Mach-O] Command size: ${macho.sizeofcmds} bytes');
    
    // Parse load commands (start after header at offset 32)
    int offset = 32;
    for (int i = 0; i < macho.ncmds; i++) {
      final cmd = macho._read32(offset);
      final cmdsize = macho._read32(offset + 4);
      
      if (cmd == LC_SEGMENT_64) {
        final segment = macho._parseSegment64(offset);
        macho.segments.add(segment);
        print('[Mach-O]   Segment: ${segment.name} (${segment.filesize} bytes)');
      } else if (cmd == LC_SYMTAB) {
        macho._parseSymtab(offset);
      }
      
      offset += cmdsize;
    }
    
    print('[Mach-O] ✅ Parsed ${macho.segments.length} segments, ${macho.symbols.length} symbols');
    
    return macho;
  }
  
  MachoSegment _parseSegment64(int offset) {
    // struct segment_command_64 {
    //   uint32_t cmd;           // 0
    //   uint32_t cmdsize;       // 4
    //   char segname[16];       // 8
    //   uint64_t vmaddr;        // 24
    //   uint64_t vmsize;        // 32
    //   uint64_t fileoff;       // 40
    //   uint64_t filesize;      // 48
    //   ...
    // };
    
    final name = _readString(offset + 8, 16);
    final vmaddr = _read64(offset + 24);
    final vmsize = _read64(offset + 32);
    final fileoff = _read64(offset + 40);
    final filesize = _read64(offset + 48);
    
    return MachoSegment(
      name: name,
      vmaddr: vmaddr,
      vmsize: vmsize,
      fileoff: fileoff,
      filesize: filesize,
      data: data.sublist(fileoff, fileoff + filesize),
    );
  }
  
  void _parseSymtab(int offset) {
    // struct symtab_command {
    //   uint32_t cmd;        // 0
    //   uint32_t cmdsize;    // 4
    //   uint32_t symoff;     // 8  - symbol table offset
    //   uint32_t nsyms;      // 12 - number of symbols
    //   uint32_t stroff;     // 16 - string table offset
    //   uint32_t strsize;    // 20 - string table size
    // };
    
    final symoff = _read32(offset + 8);
    final nsyms = _read32(offset + 12);
    final stroff = _read32(offset + 16);
    
    print('[Mach-O]   Symbol table: $nsyms symbols');
    
    // Parse symbols (each is 16 bytes for 64-bit)
    for (int i = 0; i < nsyms; i++) {
      final symOffset = symoff + (i * 16);
      
      // struct nlist_64 {
      //   uint32_t n_strx;   // 0 - string table index
      //   uint8_t  n_type;   // 4 - symbol type
      //   uint8_t  n_sect;   // 5 - section number
      //   uint16_t n_desc;   // 6 - description
      //   uint64_t n_value;  // 8 - symbol value (address)
      // };
      
      final strx = _read32(symOffset);
      final value = _read64(symOffset + 8);
      
      // Read symbol name from string table
      final name = _readCString(stroff + strx);
      
      if (name.isNotEmpty && value > 0) {
        symbols.add(MachoSymbol(name: name, value: value));
      }
    }
  }
  
  String _readString(int offset, int maxLen) {
    final bytes = <int>[];
    for (int i = 0; i < maxLen; i++) {
      final byte = data[offset + i];
      if (byte == 0) break;
      bytes.add(byte);
    }
    return String.fromCharCodes(bytes);
  }
  
  String _readCString(int offset) {
    final bytes = <int>[];
    int i = offset;
    while (i < data.length && data[i] != 0) {
      bytes.add(data[i]);
      i++;
    }
    return String.fromCharCodes(bytes);
  }
  
  int _read32(int offset) {
    if (isLittleEndian) {
      return data[offset] |
             (data[offset + 1] << 8) |
             (data[offset + 2] << 16) |
             (data[offset + 3] << 24);
    } else {
      return (data[offset] << 24) |
             (data[offset + 1] << 16) |
             (data[offset + 2] << 8) |
             data[offset + 3];
    }
  }
  
  int _read64(int offset) {
    if (isLittleEndian) {
      return _read32(offset) | (_read32(offset + 4) << 32);
    } else {
      return (_read32(offset) << 32) | _read32(offset + 4);
    }
  }
  
  /// Find a segment by name
  MachoSegment? findSegment(String name) {
    return segments.where((s) => s.name == name).firstOrNull;
  }
}

/// Parse a Mach-O file and return the parsed structure
Future<MachoFile> parseMachoFile(File file) async {
  return await MachoFile.parse(file);
}
