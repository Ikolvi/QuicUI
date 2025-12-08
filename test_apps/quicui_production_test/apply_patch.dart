import 'dart:io';
import '../../packages/quicui_compiler/lib/src/bsdiff.dart';

void main() async {
  print('[Dart BsPatch] Applying patch...');
  await BsDiff.applyPatch(
    './baseline/App-v3.0.28',
    './patches/patch_1764180399125.quicui',
    './patches/App-v3.0.30-patched',
  );
  print('[Dart BsPatch] ✅ Done!');
  
  // Get file size
  final file = File('./patches/App-v3.0.30-patched');
  final size = await file.length();
  print('[Dart BsPatch] Patched binary size: ${(size / 1024 / 1024).toStringAsFixed(2)} MB');
}
