import 'dart:io';
import 'package:quicui_linker/src/macho_parser.dart';

void main() async {
  final file = File('/Users/admin/Documents/quicui2/test_apps/quicui_production_test/build/ios/Release-iphoneos/App.framework/App');
  
  if (!await file.exists()) {
    print('❌ File not found: ${file.path}');
    exit(1);
  }
  
  print('Testing Mach-O parser...\n');
  
  final macho = await parseMachoFile(file);
  print('\n✅ Parsed successfully:');
  print('   Segments: ${macho.segments.length}');
  print('   Symbols: ${macho.symbols.length}');
  
  print('\nSegments:');
  for (final seg in macho.segments) {
    print('   ${seg.name.padRight(16)} ${seg.filesize.toString().padLeft(10)} bytes at offset ${seg.fileoff}');
  }
  
  final textSeg = macho.findSegment('__TEXT');
  if (textSeg != null) {
    print('\n__TEXT segment details:');
    print('   VM address: 0x${textSeg.vmaddr.toRadixString(16)}');
    print('   VM size: ${textSeg.vmsize} bytes');
    print('   File offset: ${textSeg.fileoff}');
    print('   File size: ${textSeg.filesize} bytes');
  }
  
  if (macho.symbols.isNotEmpty) {
    print('\nSample symbols (first 10):');
    for (int i = 0; i < 10 && i < macho.symbols.length; i++) {
      final sym = macho.symbols[i];
      print('   ${sym.name} @ 0x${sym.value.toRadixString(16)}');
    }
  }
}
