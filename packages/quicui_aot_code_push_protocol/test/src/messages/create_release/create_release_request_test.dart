import 'package:quicui_aot_code_push_protocol/quicui_aot_code_push_protocol.dart';
import 'package:test/test.dart';

void main() {
  group(CreateReleaseRequest, () {
    test('can be (de)serialized', () {
      const request = CreateReleaseRequest(
        version: '1.2.3',
        flutterRevision: 'abc123',
        flutterVersion: '3.22.0',
        displayName: 'display_name',
      );
      expect(
        CreateReleaseRequest.fromJson(request.toJson()).toJson(),
        equals(request.toJson()),
      );
    });
  });
}
