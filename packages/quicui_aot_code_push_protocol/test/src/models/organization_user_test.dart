import 'package:quicui_aot_code_push_protocol/quicui_aot_code_push_protocol.dart';
import 'package:test/test.dart';

void main() {
  group(OrganizationUser, () {
    test('can be (de)serialized', () {
      final organizationUser = OrganizationUser(
        user: PublicUser.fromPrivateUser(PrivateUser.forTest()),
        role: Role.developer,
      );
      expect(
        OrganizationUser.fromJson(organizationUser.toJson()).toJson(),
        equals(organizationUser.toJson()),
      );
    });
  });
}
