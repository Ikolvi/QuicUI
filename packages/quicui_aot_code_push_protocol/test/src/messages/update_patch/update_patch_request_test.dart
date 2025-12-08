import 'package:quicui_aot_code_push_protocol/quicui_aot_code_push_protocol.dart';
import 'package:test/test.dart';

void main() {
  group(UpdatePatchRequest, () {
    test('can be (de)serialized', () {
      const request = UpdatePatchRequest(notes: 'notes');
      expect(
        UpdatePatchRequest.fromJson(request.toJson()).toJson(),
        equals(request.toJson()),
      );
    });
  });
}
