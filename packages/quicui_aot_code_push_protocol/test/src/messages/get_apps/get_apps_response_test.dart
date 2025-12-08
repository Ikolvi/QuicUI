import 'package:quicui_aot_code_push_protocol/quicui_aot_code_push_protocol.dart';
import 'package:test/test.dart';

void main() {
  group(GetAppsResponse, () {
    test('can be (de)serialized', () {
      final response = GetAppsResponse(
        apps: [
          AppMetadata(
            appId: 'app-id',
            displayName: 'display-name',
            createdAt: DateTime(2022),
            updatedAt: DateTime(2023),
          ),
        ],
      );
      expect(
        GetAppsResponse.fromJson(response.toJson()).toJson(),
        equals(response.toJson()),
      );
    });
  });
}
