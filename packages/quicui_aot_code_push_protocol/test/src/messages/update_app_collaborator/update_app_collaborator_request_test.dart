import 'package:quicui_aot_code_push_protocol/quicui_aot_code_push_protocol.dart';
import 'package:test/test.dart';

void main() {
  group(UpdateAppCollaboratorRequest, () {
    test('can be (de)serialized', () {
      const request = UpdateAppCollaboratorRequest(
        role: AppCollaboratorRole.admin,
      );
      expect(
        UpdateAppCollaboratorRequest.fromJson(request.toJson()).toJson(),
        equals(request.toJson()),
      );
    });
  });
}
