import 'package:quicui_aot_code_push_protocol/quicui_aot_code_push_protocol.dart';
import 'package:test/test.dart';

void main() {
  group(CreateChannelRequest, () {
    test('can be (de)serialized', () {
      const request = CreateChannelRequest(channel: 'my_channel');
      expect(
        CreateChannelRequest.fromJson(request.toJson()).toJson(),
        equals(request.toJson()),
      );
    });
  });
}
