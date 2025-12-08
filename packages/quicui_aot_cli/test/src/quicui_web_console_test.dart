import 'package:quicui_aot_cli/src/quicui_web_console.dart';
import 'package:test/test.dart';

void main() {
  group(QuicuiWebConsole, () {
    test('uri returns the correct uri with the received path', () {
      expect(
        QuicuiWebConsole.uri('path'),
        Uri.parse('https://console.quicui.dev/path'),
      );
    });

    test('appReleaseUri returns the correct uri to an app release', () {
      expect(
        QuicuiWebConsole.appReleaseUri('appId', 123),
        Uri.parse('https://console.quicui.dev/apps/appId/releases/123'),
      );
    });
  });
}
