import 'package:flutter_test/flutter_test.dart';

import 'package:quicui/quicui.dart';

void main() {
  test('QuicUI library exports', () {
    // Test that QuicUI library is properly exported
    expect(ScreenRepository, isNotNull);
    expect(SyncRepository, isNotNull);
    expect(Validators, isNotNull);
  });

  test('Constants are defined', () {
    expect(StorageKeys.appConfig, 'app_config');
    expect(StorageKeys.userSession, 'user_session');
    expect(WidgetTypes.column, 'column');
    expect(WidgetTypes.row, 'row');
    expect(WidgetTypes.text, 'text');
  });

  test('Validators work correctly', () {
    expect(Validators.validateRequired(''), isNotNull);
    expect(Validators.validateRequired('valid'), isNull);
    expect(Validators.validateEmail('invalid'), isNotNull);
    expect(Validators.validateEmail('test@example.com'), isNull);
  });
}
