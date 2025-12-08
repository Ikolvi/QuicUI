import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/quicui_version.dart';
import 'package:quicui_aot_cli/src/validators/validators.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('QuicuiVersionValidator', () {
    late QuicuiVersion quicuiVersion;
    late QuicuiVersionValidator validator;

    R runWithOverrides<R>(R Function() body) {
      return runScoped(
        body,
        values: {quicuiVersionRef.overrideWith(() => quicuiVersion)},
      );
    }

    setUp(() {
      quicuiVersion = MockQuicuiVersion();
      validator = QuicuiVersionValidator();

      when(quicuiVersion.isLatest).thenAnswer((_) async => false);
    });

    test('has a non-empty description', () {
      expect(validator.description, isNotEmpty);
    });

    test('canRunInContext always returns true', () {
      expect(validator.canRunInCurrentContext(), isTrue);
    });

    test('returns no issues when quicui is up-to-date', () async {
      when(quicuiVersion.isLatest).thenAnswer((_) async => true);

      final results = await runWithOverrides(validator.validate);

      expect(results, isEmpty);
    });

    test(
      'returns an error when quicui version cannot be determined',
      () async {
        when(
          quicuiVersion.isLatest,
        ).thenThrow(const ProcessException('git', ['rev-parse', 'HEAD']));

        final results = await runWithOverrides(validator.validate);

        expect(results, hasLength(1));
        expect(results.first.severity, ValidationIssueSeverity.error);
        expect(
          results.first.message,
          contains('Failed to get quicui version'),
        );
      },
    );

    test('returns a warning when a newer quicui is available', () async {
      when(quicuiVersion.isLatest).thenAnswer((_) async => false);

      final results = await runWithOverrides(validator.validate);

      expect(results, hasLength(1));
      expect(results.first.severity, ValidationIssueSeverity.warning);
      expect(
        results.first.message,
        contains('A new version of quicui is available!'),
      );
    });
  });
}
