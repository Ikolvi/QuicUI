import 'package:quicui_aot_code_push_protocol/quicui_aot_code_push_protocol.dart';
import 'package:test/test.dart';

void main() {
  group(GetOrganizationsResponse, () {
    test('can be (de)serialized', () {
      final getOrganizationsResponse = GetOrganizationsResponse(
        organizations: [
          OrganizationMembership(
            organization: Organization.forTest(),
            role: Role.developer,
          ),
        ],
      );
      expect(
        GetOrganizationsResponse.fromJson(
          getOrganizationsResponse.toJson(),
        ).toJson(),
        equals(getOrganizationsResponse.toJson()),
      );
    });
  });
}
