import 'dart:io';
import 'dart:typed_data';

/// Represents an ELF file structure with symbols and sections
class ElfFile {
  final File file;
  final Uint8List data;
  final Map<String, ElfSymbol> symbols = {};
  final Map<String, ElfSection> sections = {};
  
  ElfFile(this.file, this.data);
  
  /// Parse ELF header and extract symbols
  Future<void> parse() async {
    // Verify ELF magic
    if (data.length < 4 || 
        data[0] != 0x7f || 
        data[1] != 0x45 || 
        data[2] != 0x4c || 
        data[3] != 0x46) {
      throw Exception('Not a valid ELF file: ${file.path}');
    }
    
    final is64Bit = data[4] == 2;
    final isLittleEndian = data[5] == 1;
    
    print('ELF file: ${file.path}');
    print('  64-bit: $is64Bit');
    print('  Little-endian: $isLittleEndian');
    
    // Parse section headers
    await _parseSectionHeaders(is64Bit, isLittleEndian);
    
    // Parse symbol table
    await _parseSymbolTable(is64Bit, isLittleEndian);
  }
  
  Future<void> _parseSectionHeaders(bool is64Bit, bool isLittleEndian) async {
    // Get section header offset from ELF header
    final shoff = is64Bit ? _read64(data, 40, isLittleEndian) : _read32(data, 32, isLittleEndian);
    final shentsize = is64Bit ? _read16(data, 58, isLittleEndian) : _read16(data, 46, isLittleEndian);
    final shnum = is64Bit ? _read16(data, 60, isLittleEndian) : _read16(data, 48, isLittleEndian);
    final shstrndx = is64Bit ? _read16(data, 62, isLittleEndian) : _read16(data, 50, isLittleEndian);
    
    print('  Section headers: $shnum at offset $shoff (size: $shentsize)');
    
    // Read section header string table
    final strTabOffset = shoff + (shstrndx * shentsize);
    final strTabSectionOffset = is64Bit 
        ? _read64(data, strTabOffset + 24, isLittleEndian)
        : _read32(data, strTabOffset + 16, isLittleEndian);
    // strTabSize is read but not used currently - reserved for future validation
    final _ = is64Bit
        ? _read64(data, strTabOffset + 32, isLittleEndian)
        : _read32(data, strTabOffset + 20, isLittleEndian);
    
    // Parse each section header
    for (int i = 0; i < shnum; i++) {
      final offset = shoff + (i * shentsize);
      final nameOffset = _read32(data, offset, isLittleEndian);
      final type = _read32(data, offset + 4, isLittleEndian);
      final sectionOffset = is64Bit
          ? _read64(data, offset + 24, isLittleEndian)
          : _read32(data, offset + 16, isLittleEndian);
      final size = is64Bit
          ? _read64(data, offset + 32, isLittleEndian)
          : _read32(data, offset + 20, isLittleEndian);
      
      // Read section name from string table
      String name = '';
      int idx = strTabSectionOffset + nameOffset;
      while (idx < data.length && data[idx] != 0) {
        name += String.fromCharCode(data[idx]);
        idx++;
      }
      
      if (name.isNotEmpty) {
        sections[name] = ElfSection(name, type, sectionOffset, size);
      }
    }
    
    print('  Sections found: ${sections.length}');
  }
  
  Future<void> _parseSymbolTable(bool is64Bit, bool isLittleEndian) async {
    // Find .symtab or .dynsym section
    final symtabSection = sections['.symtab'] ?? sections['.dynsym'];
    if (symtabSection == null) {
      print('  No symbol table found');
      return;
    }
    
    final entsize = is64Bit ? 24 : 16;
    final numSymbols = symtabSection.size ~/ entsize;
    
    print('  Symbols: $numSymbols');
    
    // Find associated string table
    final strtabSection = sections['.strtab'] ?? sections['.dynstr'];
    if (strtabSection == null) {
      print('  No string table found');
      return;
    }
    
    // Parse each symbol
    for (int i = 0; i < numSymbols; i++) {
      final offset = symtabSection.offset + (i * entsize);
      
      final nameOffset = _read32(data, offset, isLittleEndian);
      final value = is64Bit
          ? _read64(data, offset + 8, isLittleEndian)
          : _read32(data, offset + 4, isLittleEndian);
      final size = is64Bit
          ? _read64(data, offset + 16, isLittleEndian)
          : _read32(data, offset + 8, isLittleEndian);
      
      // Read symbol name
      String name = '';
      int idx = strtabSection.offset + nameOffset;
      while (idx < data.length && data[idx] != 0) {
        name += String.fromCharCode(data[idx]);
        idx++;
      }
      
      if (name.isNotEmpty && size > 0) {
        symbols[name] = ElfSymbol(name, value, size);
      }
    }
    
    print('  Named symbols: ${symbols.length}');
  }
  
  int _read16(Uint8List data, int offset, bool isLittleEndian) {
    if (isLittleEndian) {
      return data[offset] | (data[offset + 1] << 8);
    } else {
      return (data[offset] << 8) | data[offset + 1];
    }
  }
  
  int _read32(Uint8List data, int offset, bool isLittleEndian) {
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
  
  int _read64(Uint8List data, int offset, bool isLittleEndian) {
    final low = _read32(data, offset, isLittleEndian);
    final high = _read32(data, offset + 4, isLittleEndian);
    return isLittleEndian ? (high << 32) | low : (low << 32) | high;
  }
}

class ElfSection {
  final String name;
  final int type;
  final int offset;
  final int size;
  
  ElfSection(this.name, this.type, this.offset, this.size);
  
  @override
  String toString() => 'Section($name, offset=$offset, size=$size)';
}

class ElfSymbol {
  final String name;
  final int value;
  final int size;
  
  ElfSymbol(this.name, this.value, this.size);
  
  @override
  String toString() => 'Symbol($name, value=0x${value.toRadixString(16)}, size=$size)';
}

/// Parse an ELF file and extract its structure
Future<ElfFile> parseElfFile(File file) async {
  final data = await file.readAsBytes();
  final elf = ElfFile(file, data);
  await elf.parse();
  return elf;
}
