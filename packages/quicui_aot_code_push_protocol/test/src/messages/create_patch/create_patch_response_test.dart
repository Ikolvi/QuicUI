import 'package:quicui_aot_code_push_protocol/quicui_aot_code_push_protocol.dart';
import 'package:test/test.dart';

void main() {
  group(CreatePatchResponse, () {
    test('can be (de)serialized', () {
      const response = CreatePatchResponse(id: 42, number: 1);
      expect(
        CreatePatchResponse.fromJson(response.toJson()).toJson(),
        equals(response.toJson()),
      );
    });
  });
}
