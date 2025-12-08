import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/pubspec_editor.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:test/test.dart';

import 'mocks.dart';

class _FakeDirectory extends Fake implements Directory {}

void main() {
  group(PubspecEditor, () {
    late QuicuiEnv quicuiEnv;
    late PubspecEditor pubspecEditor;

    R runWithOverrides<R>(R Function() body) {
      return runScoped(
        () => body(),
        values: {quicuiEnvRef.overrideWith(() => quicuiEnv)},
      );
    }

    setUpAll(() {
      registerFallbackValue(_FakeDirectory());
    });

    setUp(() {
      quicuiEnv = MockQuicuiEnv();
      pubspecEditor = PubspecEditor();
    });

    group('addQuicuiYamlToPubspecAssets', () {
      group('when quicui.yaml is part of the pubspec.yaml assets', () {
        setUp(() {
          when(
            () => quicuiEnv.pubspecContainsQuicuiYaml,
          ).thenReturn(true);
        });

        test('does nothing', () {
          expect(
            () =>
                runWithOverrides(pubspecEditor.addQuicuiYamlToPubspecAssets),
            returnsNormally,
          );
          verifyNever(() => quicuiEnv.getFlutterProjectRoot());
        });
      });

      group('when quicui.yaml is not part of the pubspec.yaml assets', () {
        setUp(() {
          when(
            () => quicuiEnv.pubspecContainsQuicuiYaml,
          ).thenReturn(false);
        });

        group('when a flutter project root cannot be found', () {
          setUp(() {
            when(() => quicuiEnv.getFlutterProjectRoot()).thenReturn(null);
          });

          test('does nothing', () {
            expect(
              () => runWithOverrides(
                pubspecEditor.addQuicuiYamlToPubspecAssets,
              ),
              returnsNormally,
            );
            verify(() => quicuiEnv.getFlutterProjectRoot()).called(1);
          });
        });

        group('when a flutter project root can be found', () {
          const basePubspecContents = '''
name: test
version: 1.0.0
environment:
 sdk: ">=2.19.0 <3.0.0"''';
          late Directory tempDir;
          late File pubspecFile;

          setUp(() {
            tempDir = Directory.systemTemp.createTempSync();
            pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
            when(
              () => quicuiEnv.getFlutterProjectRoot(),
            ).thenReturn(tempDir);
            when(
              () => quicuiEnv.getPubspecYamlFile(cwd: any(named: 'cwd')),
            ).thenReturn(pubspecFile);
          });

          test('creates flutter.assets and adds quicui.yaml', () {
            pubspecFile
              ..createSync()
              ..writeAsStringSync(basePubspecContents);
            IOOverrides.runZoned(
              () => runWithOverrides(
                pubspecEditor.addQuicuiYamlToPubspecAssets,
              ),
              getCurrentDirectory: () => tempDir,
            );
            expect(
              pubspecFile.readAsStringSync(),
              equals('''
$basePubspecContents
flutter:
 assets:
   - quicui.yaml
'''),
            );
          });

          test('creates assets and adds quicui.yaml (empty flutter)', () {
            pubspecFile
              ..createSync()
              ..writeAsStringSync('''
$basePubspecContents
flutter:
''');
            IOOverrides.runZoned(
              () => runWithOverrides(
                pubspecEditor.addQuicuiYamlToPubspecAssets,
              ),
              getCurrentDirectory: () => tempDir,
            );
            expect(
              pubspecFile.readAsStringSync(),
              equals('''
$basePubspecContents
flutter:
 assets:
   - quicui.yaml
'''),
            );
          });
          test(
            'creates assets and adds quicui.yaml (non-empty flutter)',
            () {
              pubspecFile
                ..createSync()
                ..writeAsStringSync('''
$basePubspecContents
flutter:
 uses-material-design: true
''');
              IOOverrides.runZoned(
                () => runWithOverrides(
                  pubspecEditor.addQuicuiYamlToPubspecAssets,
                ),
                getCurrentDirectory: () => tempDir,
              );
              expect(
                pubspecFile.readAsStringSync(),
                equals('''
$basePubspecContents
flutter:
 uses-material-design: true
 assets:
  - quicui.yaml
'''),
              );
            },
          );
          test('adds quicui.yaml to assets (existing assets)', () {
            pubspecFile
              ..createSync()
              ..writeAsStringSync('''
$basePubspecContents
flutter:
 assets:
  - some/asset.txt
''');
            IOOverrides.runZoned(
              () => runWithOverrides(
                pubspecEditor.addQuicuiYamlToPubspecAssets,
              ),
              getCurrentDirectory: () => tempDir,
            );
            expect(
              pubspecFile.readAsStringSync(),
              equals('''
$basePubspecContents
flutter:
 assets:
  - some/asset.txt
  - quicui.yaml
'''),
            );
          });
        });
      });
    });
  });
}
