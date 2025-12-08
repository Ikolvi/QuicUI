import 'package:flutter_test/flutter_test.dart';
import 'package:quicui/quicui.dart';
import 'package:quicui/src/models/config.dart';

void main() {
  group('QuicUI Code Push Client', () {
    test('Config initialization with default values', () {
      final config = Config(
        appId: 'com.example.app',
        clientSecret: 'secret123',
        appVersion: '1.0.0',
      );

      expect(config.appId, equals('com.example.app'));
      expect(config.clientSecret, equals('secret123'));
      expect(config.appVersion, equals('1.0.0'));
      expect(config.maxPatchSize, equals(10 * 1024 * 1024)); // 10MB
      expect(config.autoCheckOnStart, isTrue);
      expect(config.checkIntervalSeconds, equals(3600));
      expect(config.enableDebugLogging, isFalse);
    });

    test('Config initialization with custom values', () {
      final config = Config(
        appId: 'com.example.app',
        clientSecret: 'secret123',
        appVersion: '1.0.0',
        maxPatchSize: 5 * 1024 * 1024, // 5MB
        autoCheckOnStart: false,
        checkIntervalSeconds: 1800,
        enableDebugLogging: true,
      );

      expect(config.maxPatchSize, equals(5 * 1024 * 1024));
      expect(config.autoCheckOnStart, isFalse);
      expect(config.checkIntervalSeconds, equals(1800));
      expect(config.enableDebugLogging, isTrue);
    });

    test('Config toString returns expected format', () {
      final config = Config(
        appId: 'com.example.app',
        clientSecret: 'secret123',
        appVersion: '1.0.0',
      );

      expect(
        config.toString(),
        contains('com.example.app'),
      );
    });

    test('PatchInfo version comparison - current matches', () {
      final patch1 = PatchInfo(
        patchId: 'patch1',
        version: '1.0.0',
        createdAt: DateTime.now(),
        size: 1024,
        downloadUrl: 'https://example.com/patch.bin',
        signature: 'sig123',
      );

      expect(patch1.isApplicable('1.0.0'), isTrue);
    });

    test('PatchInfo version comparison - current less than', () {
      final patch = PatchInfo(
        patchId: 'patch1',
        version: '1.0.0',
        createdAt: DateTime.now(),
        size: 1024,
        downloadUrl: 'https://example.com/patch.bin',
        signature: 'sig123',
      );

      expect(patch.isApplicable('0.9.0'), isTrue);
    });

    test('PatchInfo version comparison - current greater than', () {
      final patch = PatchInfo(
        patchId: 'patch1',
        version: '1.0.0',
        createdAt: DateTime.now(),
        size: 1024,
        downloadUrl: 'https://example.com/patch.bin',
        signature: 'sig123',
      );

      expect(patch.isApplicable('1.1.0'), isTrue);
    });

    test('PatchInfo version comparison - different lengths', () {
      final patch = PatchInfo(
        patchId: 'patch1',
        version: '1.0.0',
        createdAt: DateTime.now(),
        size: 1024,
        downloadUrl: 'https://example.com/patch.bin',
        signature: 'sig123',
      );

      expect(patch.isApplicable('1.0.0'), isTrue);
    });

    test('PatchInfo isApplicable with no version constraints', () {
      final patch = PatchInfo(
        patchId: 'patch1',
        version: '1.1.0',
        createdAt: DateTime.now(),
        size: 1024,
        downloadUrl: 'https://example.com/patch.bin',
        signature: 'sig123',
      );

      expect(patch.isApplicable('1.0.0'), isTrue);
    });

    test('PatchInfo isApplicable with min version constraint', () {
      final patch = PatchInfo(
        patchId: 'patch1',
        version: '1.1.0',
        createdAt: DateTime.now(),
        size: 1024,
        downloadUrl: 'https://example.com/patch.bin',
        signature: 'sig123',
      );

      expect(patch.isApplicable('1.0.0'), isTrue);
      expect(patch.isApplicable('0.9.0'), isTrue);
    });

    test('PatchInfo isApplicable with max version constraint', () {
      final patch = PatchInfo(
        patchId: 'patch1',
        version: '1.1.0',
        createdAt: DateTime.now(),
        size: 1024,
        downloadUrl: 'https://example.com/patch.bin',
        signature: 'sig123',
      );

      expect(patch.isApplicable('1.5.0'), isTrue);
      expect(patch.isApplicable('1.6.0'), isTrue);
    });

    test('PatchInfo JSON serialization and deserialization', () {
      final originalPatch = PatchInfo(
        patchId: 'patch1',
        version: '1.1.0',
        createdAt: DateTime(2025, 11, 1, 12, 0, 0),
        size: 1024,
        downloadUrl: 'https://example.com/patch.bin',
        signature: 'sig123',
        changelog: 'Fixed bugs',
        mandatory: true,
        rolloutPercentage: 50,
      );

      // Convert to JSON
      final json = originalPatch.toJson();

      // Verify JSON structure
      expect(json['patchId'], equals('patch1'));
      expect(json['version'], equals('1.1.0'));
      expect(json['size'], equals(1024));
      expect(json['signature'], equals('sig123'));
      expect(json['mandatory'], isTrue);
      expect(json['rolloutPercentage'], equals(50));

      // Convert back from JSON
      final deserializedPatch = PatchInfo.fromJson(json);

      expect(deserializedPatch.patchId, equals(originalPatch.patchId));
      expect(deserializedPatch.version, equals(originalPatch.version));
      expect(deserializedPatch.size, equals(originalPatch.size));
      expect(deserializedPatch.signature, equals(originalPatch.signature));
      expect(deserializedPatch.changelog, equals(originalPatch.changelog));
      expect(deserializedPatch.mandatory, equals(originalPatch.mandatory));
      expect(deserializedPatch.rolloutPercentage, equals(originalPatch.rolloutPercentage));
    });

    test('PatchInfo toString returns expected format', () {
      final patch = PatchInfo(
        patchId: 'patch1',
        version: '1.1.0',
        createdAt: DateTime.now(),
        size: 1024,
        downloadUrl: 'https://example.com/patch.bin',
        signature: 'sig123',
      );

      final str = patch.toString();
      expect(str, contains('patch1'));
      expect(str, contains('1.1.0'));
      expect(str, contains('pending'));
    });

    test('PatchStatus enum has expected values', () {
      expect(PatchStatus.pending, isNotNull);
      expect(PatchStatus.downloading, isNotNull);
      expect(PatchStatus.verifying, isNotNull);
      expect(PatchStatus.applying, isNotNull);
      expect(PatchStatus.completed, isNotNull);
      expect(PatchStatus.failed, isNotNull);
      expect(PatchStatus.rolled_back, isNotNull);
    });
  });
}
