import 'package:checked_yaml/checked_yaml.dart';
import 'package:quicui_aot_cli/src/config/config.dart';
import 'package:test/test.dart';

void main() {
  group('QuicuiYaml', () {
    test('can be deserialized without flavors', () {
      const yaml = '''
app_id: test_app_id
base_url: https://example.com
''';
      final quicuiYaml = checkedYamlDecode(
        yaml,
        (m) => QuicuiYaml.fromJson(m!),
      );
      expect(quicuiYaml.appId, 'test_app_id');
      expect(quicuiYaml.flavors, isNull);
      expect(quicuiYaml.baseUrl, 'https://example.com');
    });

    test('can be deserialized with flavors', () {
      const yaml = '''
app_id: test_app_id1
flavors:
  development: test_app_id1
  production: test_app_id2
base_url: https://example.com
''';
      final quicuiYaml = checkedYamlDecode(
        yaml,
        (m) => QuicuiYaml.fromJson(m!),
      );
      expect(quicuiYaml.appId, equals('test_app_id1'));
      expect(quicuiYaml.flavors, {
        'development': 'test_app_id1',
        'production': 'test_app_id2',
      });
      expect(quicuiYaml.baseUrl, 'https://example.com');
    });

    test('can be deserialized without auto-update', () {
      const yaml = '''
app_id: test_app_id
''';
      final quicuiYaml = checkedYamlDecode(
        yaml,
        (m) => QuicuiYaml.fromJson(m!),
      );
      expect(quicuiYaml.appId, 'test_app_id');
      expect(quicuiYaml.flavors, isNull);
      expect(quicuiYaml.baseUrl, isNull);
      expect(quicuiYaml.autoUpdate, isNull);
    });

    test('can be deserialized with auto-update', () {
      const yaml = '''
app_id: test_app_id
auto_update: true
''';
      final quicuiYaml = checkedYamlDecode(
        yaml,
        (m) => QuicuiYaml.fromJson(m!),
      );
      expect(quicuiYaml.appId, 'test_app_id');
      expect(quicuiYaml.flavors, isNull);
      expect(quicuiYaml.baseUrl, isNull);
      expect(quicuiYaml.autoUpdate, isTrue);
    });

    group('AppIdExtension', () {
      test('getAppId returns base app id when no flavor is provided', () {
        const quicuiYaml = QuicuiYaml(appId: 'test_app_id');
        expect(quicuiYaml.getAppId(), 'test_app_id');
      });

      test('getAppId returns base app id when flavor is not found', () {
        const quicuiYaml = QuicuiYaml(
          appId: 'test_app_id',
          flavors: {
            'development': 'test_app_id1',
            'production': 'test_app_id2',
          },
        );
        expect(quicuiYaml.getAppId(flavor: 'staging'), 'test_app_id');
      });

      test('getAppId returns app id for flavor', () {
        const quicuiYaml = QuicuiYaml(
          appId: 'test_app_id',
          flavors: {
            'development': 'test_app_id1',
            'production': 'test_app_id2',
          },
        );
        expect(quicuiYaml.getAppId(flavor: 'development'), 'test_app_id1');
        expect(quicuiYaml.getAppId(flavor: 'production'), 'test_app_id2');
      });
    });
  });
}
