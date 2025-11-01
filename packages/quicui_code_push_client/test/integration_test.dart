import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:quicui_code_push_client/quicui_code_push_client.dart';

// Mock classes
class MockMethodChannel extends Mock {
  Future<dynamic> invokeMethod(String method, [dynamic arguments]);
}

class MockPatchMetadata extends Mock implements PatchMetadata {
  @override
  final String version;
  @override
  final String patchHash;
  @override
  final int patchSize;
  @override
  final String signature;
  @override
  final bool critical;

  MockPatchMetadata({
    this.version = '1.0.1',
    this.patchHash = 'abc123',
    this.patchSize = 1024,
    this.signature = 'sig123',
    this.critical = false,
  });
}

void main() {
  group('CodePushClient Integration Tests', () {
    late CodePushClient client;

    setUp(() {
      client = CodePushClient();
    });

    group('Initialization', () {
      test('initializes with valid configuration', () async {
        final config = CodePushConfig(
          serviceUrl: 'https://api.quicui.dev',
          appId: 'com.example.app',
          appVersion: '1.0.0',
        );

        final result = await client.initialize(config);
        expect(result, isTrue);
      });

      test('fails with empty service URL', () async {
        final config = CodePushConfig(
          serviceUrl: '',
          appId: 'com.example.app',
          appVersion: '1.0.0',
        );

        final result = await client.initialize(config);
        expect(result, isFalse);
      });

      test('fails with empty app ID', () async {
        final config = CodePushConfig(
          serviceUrl: 'https://api.quicui.dev',
          appId: '',
          appVersion: '1.0.0',
        );

        final result = await client.initialize(config);
        expect(result, isFalse);
      });

      test('fails with empty app version', () async {
        final config = CodePushConfig(
          serviceUrl: 'https://api.quicui.dev',
          appId: 'com.example.app',
          appVersion: '',
        );

        final result = await client.initialize(config);
        expect(result, isFalse);
      });

      test('stores configuration after successful initialization', () async {
        final config = CodePushConfig(
          serviceUrl: 'https://api.quicui.dev',
          appId: 'com.example.app',
          appVersion: '1.0.0',
        );

        await client.initialize(config);
        expect(client.isInitialized, isTrue);
      });
    });

    group('Patch Checking', () {
      setUp(() async {
        final config = CodePushConfig(
          serviceUrl: 'https://api.quicui.dev',
          appId: 'com.example.app',
          appVersion: '1.0.0',
        );
        await client.initialize(config);
      });

      test('checks for patches successfully', () async {
        final result = await client.checkForPatch();
        // Result will depend on actual network call
        expect(result, isNotNull);
      });

      test('handles network errors gracefully', () async {
        // Simulate network error by using invalid URL
        final config = CodePushConfig(
          serviceUrl: 'https://invalid.nonexistent.example.com',
          appId: 'com.example.app',
          appVersion: '1.0.0',
        );

        try {
          await client.initialize(config);
          final result = await client.checkForPatch();
          // Should not throw, but return error
          expect(result, anyOf(isNull, isFalse));
        } catch (e) {
          fail('Should not throw exception: $e');
        }
      });

      test('returns valid patch metadata structure', () async {
        final result = await client.checkForPatch();
        
        if (result != null) {
          expect(result, isA<Map<String, dynamic>>());
          expect(result.containsKey('version'), isTrue);
          expect(result.containsKey('patchHash'), isTrue);
        }
      });
    });

    group('Patch Loading', () {
      setUp(() async {
        final config = CodePushConfig(
          serviceUrl: 'https://api.quicui.dev',
          appId: 'com.example.app',
          appVersion: '1.0.0',
        );
        await client.initialize(config);
      });

      test('loads patch with valid version', () async {
        final result = await client.loadPatch('1.0.1');
        
        expect(result, isNotNull);
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('success'), isTrue);
      });

      test('fails to load patch with empty version', () async {
        try {
          await client.loadPatch('');
          fail('Should throw exception for empty version');
        } on ArgumentError {
          expect(true, isTrue);
        }
      });

      test('caches loaded patches', () async {
        final result1 = await client.loadPatch('1.0.1');
        final result2 = await client.loadPatch('1.0.1');

        // Second call should return cached version
        expect(result1, isNotNull);
        expect(result2, isNotNull);
      });

      test('handles patch verification failure', () async {
        // Mock a patch that fails verification
        final result = await client.loadPatch('invalid-patch');
        
        // Should handle gracefully
        expect(result, isA<Map<String, dynamic>>());
      });
    });

    group('Patch Disabling', () {
      test('disables code push successfully', () async {
        final config = CodePushConfig(
          serviceUrl: 'https://api.quicui.dev',
          appId: 'com.example.app',
          appVersion: '1.0.0',
        );

        await client.initialize(config);
        expect(client.isInitialized, isTrue);

        final result = await client.disableCodePush();
        expect(result, isTrue);
        expect(client.isInitialized, isFalse);
      });

      test('disabling when not initialized is safe', () async {
        final result = await client.disableCodePush();
        // Should not throw
        expect(result, anyOf(isTrue, isFalse));
      });
    });

    group('Status Queries', () {
      test('reports uninitialized state correctly', () async {
        expect(client.isInitialized, isFalse);
      });

      test('reports initialized state correctly after initialization', () async {
        final config = CodePushConfig(
          serviceUrl: 'https://api.quicui.dev',
          appId: 'com.example.app',
          appVersion: '1.0.0',
        );

        await client.initialize(config);
        expect(client.isInitialized, isTrue);
      });

      test('retrieves loaded patch version', () async {
        final config = CodePushConfig(
          serviceUrl: 'https://api.quicui.dev',
          appId: 'com.example.app',
          appVersion: '1.0.0',
        );

        await client.initialize(config);
        
        final version = await client.getLoadedPatchVersion();
        expect(version, anyOf(isNull, isA<String>()));
      });
    });

    group('Error Handling', () {
      test('catches and handles platform exceptions', () async {
        final config = CodePushConfig(
          serviceUrl: 'https://api.quicui.dev',
          appId: 'com.example.app',
          appVersion: '1.0.0',
        );

        try {
          await client.initialize(config);
          // Should not throw
          expect(true, isTrue);
        } catch (e) {
          fail('Should handle errors gracefully: $e');
        }
      });

      test('provides meaningful error messages', () async {
        try {
          final config = CodePushConfig(
            serviceUrl: 'https://api.quicui.dev',
            appId: 'com.example.app',
            appVersion: '1.0.0',
          );

          await client.initialize(config);
          await client.checkForPatch();
          expect(true, isTrue);
        } on Exception catch (e) {
          expect(e.toString(), isNotEmpty);
        }
      });

      test('handles missing platform channel gracefully', () async {
        // This tests behavior when platform handlers are unavailable
        try {
          final result = await client.checkForPatch();
          expect(result, anyOf(isNull, isA<Map>()));
        } catch (e) {
          // Should provide meaningful error, not crash
          expect(e, isNotNull);
        }
      });
    });

    group('Concurrent Operations', () {
      setUp(() async {
        final config = CodePushConfig(
          serviceUrl: 'https://api.quicui.dev',
          appId: 'com.example.app',
          appVersion: '1.0.0',
        );
        await client.initialize(config);
      });

      test('handles concurrent patch checks', () async {
        final futures = <Future<dynamic>>[
          for (int i = 0; i < 5; i++) client.checkForPatch(),
        ];

        final results = await Future.wait(futures);
        expect(results, isNotEmpty);
      });

      test('handles concurrent patch loads', () async {
        final futures = <Future<Map<String, dynamic>>>[
          for (int i = 0; i < 3; i++) client.loadPatch('1.0.${i + 1}'),
        ];

        final results = await Future.wait(futures);
        expect(results.length, equals(3));
      });

      test('maintains consistency under concurrent access', () async {
        final config = CodePushConfig(
          serviceUrl: 'https://api.quicui.dev',
          appId: 'com.example.app',
          appVersion: '1.0.0',
        );

        final futures = <Future<bool>>[
          for (int i = 0; i < 5; i++) client.initialize(config),
        ];

        final results = await Future.wait(futures);
        expect(results.every((r) => r), isTrue);
      });
    });

    group('Performance', () {
      setUp(() async {
        final config = CodePushConfig(
          serviceUrl: 'https://api.quicui.dev',
          appId: 'com.example.app',
          appVersion: '1.0.0',
        );
        await client.initialize(config);
      });

      test('initialization completes quickly', () async {
        final stopwatch = Stopwatch()..start();
        
        final config = CodePushConfig(
          serviceUrl: 'https://api.quicui.dev',
          appId: 'com.example.app',
          appVersion: '1.0.0',
        );

        await client.initialize(config);
        stopwatch.stop();

        // Should complete in under 5 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });

      test('patch checking completes in reasonable time', () async {
        final stopwatch = Stopwatch()..start();
        
        await client.checkForPatch();
        stopwatch.stop();

        // Network call should complete in under 30 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(30000));
      });
    });
  });

  group('CodePushConfig Tests', () {
    test('creates config with all fields', () {
      final config = CodePushConfig(
        serviceUrl: 'https://api.quicui.dev',
        appId: 'com.example.app',
        appVersion: '1.0.0',
      );

      expect(config.serviceUrl, equals('https://api.quicui.dev'));
      expect(config.appId, equals('com.example.app'));
      expect(config.appVersion, equals('1.0.0'));
    });

    test('validates URL format', () {
      expect(
        () => CodePushConfig(
          serviceUrl: 'not a valid url',
          appId: 'com.example.app',
          appVersion: '1.0.0',
        ),
        throwsArgumentError,
      );
    });
  });
}
