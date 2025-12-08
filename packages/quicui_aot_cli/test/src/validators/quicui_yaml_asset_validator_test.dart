import 'package:mocktail/mocktail.dart';
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/pubspec_editor.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:quicui_aot_cli/src/validators/validators.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group(QuicuiYamlAssetValidator, () {
    late QuicuiEnv quicuiEnv;
    late PubspecEditor pubspecEditor;

    R runWithOverrides<R>(R Function() body) {
      return runScoped(
        body,
        values: {
          quicuiEnvRef.overrideWith(() => quicuiEnv),
          pubspecEditorRef.overrideWith(() => pubspecEditor),
        },
      );
    }

    setUp(() {
      quicuiEnv = MockQuicuiEnv();
      pubspecEditor = MockPubspecEditor();
    });

    test('has a non-empty description', () {
      expect(QuicuiYamlAssetValidator().description, isNotEmpty);
    });

    test('has a non-empty incorrectContextMessage', () {
      expect(QuicuiYamlAssetValidator().incorrectContextMessage, isNotEmpty);
    });

    group('canRunInContext', () {
      test('returns false if no pubspec.yaml file exists', () {
        when(() => quicuiEnv.hasPubspecYaml).thenReturn(false);
        final result = runWithOverrides(
          () => QuicuiYamlAssetValidator().canRunInCurrentContext(),
        );
        expect(result, isFalse);
      });

      test('returns true if a pubspec.yaml file exists', () {
        when(() => quicuiEnv.hasPubspecYaml).thenReturn(true);
        final result = runWithOverrides(
          () => QuicuiYamlAssetValidator().canRunInCurrentContext(),
        );
        expect(result, isTrue);
      });
    });

    group('validate', () {
      test(
        'returns with no errors if pubspec.yaml has quicui.yaml in assets',
        () async {
          when(() => quicuiEnv.hasPubspecYaml).thenReturn(true);
          when(
            () => quicuiEnv.pubspecContainsQuicuiYaml,
          ).thenReturn(true);
          final results = await runWithOverrides(
            QuicuiYamlAssetValidator().validate,
          );
          expect(results.map((res) => res.severity), isEmpty);
        },
      );

      test('returns an error if pubspec.yaml file does not exist', () async {
        when(() => quicuiEnv.hasPubspecYaml).thenReturn(false);
        final results = await runWithOverrides(
          QuicuiYamlAssetValidator().validate,
        );
        expect(results, hasLength(1));
        expect(results.first.severity, ValidationIssueSeverity.error);
        expect(results.first.message, startsWith('No pubspec.yaml file found'));
        expect(results.first.fix, isNull);
      });

      test('returns error if quicui.yaml is missing from assets', () async {
        when(() => quicuiEnv.hasPubspecYaml).thenReturn(true);
        when(() => quicuiEnv.pubspecContainsQuicuiYaml).thenReturn(false);
        final results = await runWithOverrides(
          QuicuiYamlAssetValidator().validate,
        );
        expect(results, hasLength(1));
        expect(
          results.first,
          equals(
            const ValidationIssue(
              severity: ValidationIssueSeverity.error,
              message: 'No quicui.yaml found in pubspec.yaml assets',
            ),
          ),
        );
      });
    });

    group('fix', () {
      test('adds quicui.yaml to pubspec.yaml', () async {
        when(() => quicuiEnv.hasPubspecYaml).thenReturn(true);
        when(() => quicuiEnv.pubspecContainsQuicuiYaml).thenReturn(false);
        when(
          () => pubspecEditor.addQuicuiYamlToPubspecAssets(),
        ).thenAnswer((_) {});
        final results = await runWithOverrides(
          QuicuiYamlAssetValidator().validate,
        );
        expect(results, hasLength(1));
        expect(results.first.fix, isNotNull);
        await runWithOverrides(() => results.first.fix!());
        verify(pubspecEditor.addQuicuiYamlToPubspecAssets).called(1);
      });
    });
  });
}
