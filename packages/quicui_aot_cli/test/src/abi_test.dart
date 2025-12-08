import 'dart:ffi';

import 'package:quicui_aot_cli/src/abi.dart';
import 'package:test/test.dart';

void main() {
  group(LocalAbi, () {
    test('returns the current ABI', () {
      expect(const LocalAbi().current, equals(Abi.current()));
    });
  });
}
