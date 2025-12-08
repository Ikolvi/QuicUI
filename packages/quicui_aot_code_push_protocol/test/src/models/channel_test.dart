import 'package:quicui_aot_code_push_protocol/quicui_aot_code_push_protocol.dart';
import 'package:test/test.dart';

void main() {
  group(Channel, () {
    test('can be (de)serialized', () {
      const channel = Channel(id: 1, appId: 'app-id', name: 'stable');
      expect(
        Channel.fromJson(channel.toJson()).toJson(),
        equals(channel.toJson()),
      );
    });
  });
}
