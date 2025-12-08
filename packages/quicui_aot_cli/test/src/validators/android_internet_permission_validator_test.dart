import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:quicui_aot_cli/src/validators/validators.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  const manifestWithInternetPermission = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="dev.quicui.u_quicui_clock">
    <uses-permission android:name="android.permission.INTERNET"/>
</manifest>
''';

  const manifestWithCommentedOutInternetPermission = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="dev.quicui.u_quicui_clock">
    <!-- <uses-permission android:name="android.permission.INTERNET"/> -->
</manifest>
''';

  const manifestWithNonInternetPermissions = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="dev.quicui.u_quicui_clock">
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
</manifest>
''';

  const manifestWithNoPermissions = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="dev.quicui.u_quicui_clock">
</manifest>
''';

  group(AndroidInternetPermissionValidator, () {
    late Directory projectRoot;
    late QuicuiEnv quicuiEnv;

    void writeManifestToPath(String manifestContents, String path) {
      Directory(path).createSync(recursive: true);
      File(
        p.join(path, 'AndroidManifest.xml'),
      ).writeAsStringSync(manifestContents);
    }

    R runWithOverrides<R>(R Function() body) {
      return runScoped(
        body,
        values: {quicuiEnvRef.overrideWith(() => quicuiEnv)},
      );
    }

    setUp(() {
      projectRoot = Directory.systemTemp.createTempSync();
      quicuiEnv = MockQuicuiEnv();

      when(() => quicuiEnv.getFlutterProjectRoot()).thenReturn(projectRoot);
    });

    test('has a non-empty description', () {
      expect(AndroidInternetPermissionValidator().description, isNotEmpty);
    });

    group('canRunInContext', () {
      test('returns false if no android src directory exists', () {
        final result = runWithOverrides(
          () => AndroidInternetPermissionValidator().canRunInCurrentContext(),
        );

        expect(result, isFalse);
      });

      test('returns true if an android src directory exists', () {
        writeManifestToPath(
          manifestWithInternetPermission,
          p.join(projectRoot.path, 'android', 'app', 'src', 'main'),
        );

        final result = runWithOverrides(
          () => AndroidInternetPermissionValidator().canRunInCurrentContext(),
        );

        expect(result, isTrue);
      });
    });

    test(
      '''returns successful result if the main AndroidManifest.xml file has the INTERNET permission''',
      () async {
        writeManifestToPath(
          manifestWithInternetPermission,
          p.join(projectRoot.path, 'android', 'app', 'src', 'main'),
        );

        final results = await runWithOverrides(
          AndroidInternetPermissionValidator().validate,
        );

        expect(results.map((res) => res.severity), isEmpty);
      },
    );

    test(
      'returns an error if AndroidManifest.xml file does not exist',
      () async {
        Directory(
          p.join(projectRoot.path, 'android', 'app', 'src', 'main'),
        ).createSync(recursive: true);

        final results = await runWithOverrides(
          AndroidInternetPermissionValidator().validate,
        );

        expect(results, hasLength(1));
        expect(results.first.severity, ValidationIssueSeverity.error);
        expect(
          results.first.message,
          startsWith('No AndroidManifest.xml file found at'),
        );
        expect(results.first.fix, isNull);
      },
    );

    group('when the INTERNET permission is commented out', () {
      test('returns error', () async {
        final manifestPath = p.join(
          projectRoot.path,
          'android',
          'app',
          'src',
          'main',
        );

        writeManifestToPath(
          manifestWithCommentedOutInternetPermission,
          manifestPath,
        );

        final results = await runWithOverrides(
          AndroidInternetPermissionValidator().validate,
        );

        expect(results, hasLength(1));
        expect(
          results.first,
          equals(
            ValidationIssue(
              severity: ValidationIssueSeverity.error,
              message:
                  '''${p.join('android', 'app', 'src', 'main', 'AndroidManifest.xml')} is missing the INTERNET permission.''',
            ),
          ),
        );
      });
    });

    group('when the INTERNET permission is missing', () {
      test('returns error', () async {
        final manifestPath = p.join(
          projectRoot.path,
          'android',
          'app',
          'src',
          'main',
        );

        writeManifestToPath(manifestWithNoPermissions, manifestPath);

        final results = await runWithOverrides(
          AndroidInternetPermissionValidator().validate,
        );

        expect(results, hasLength(1));
        expect(
          results.first,
          equals(
            ValidationIssue(
              severity: ValidationIssueSeverity.error,
              message:
                  '''${p.join('android', 'app', 'src', 'main', 'AndroidManifest.xml')} is missing the INTERNET permission.''',
            ),
          ),
        );
      });
    });

    group('when manifest has non-INTERNET permissions', () {
      test('returns error', () async {
        final manifestPath = p.join(
          projectRoot.path,
          'android',
          'app',
          'src',
          'main',
        );

        writeManifestToPath(manifestWithNonInternetPermissions, manifestPath);

        final results = await runWithOverrides(
          AndroidInternetPermissionValidator().validate,
        );

        expect(results, hasLength(1));
        expect(
          results.first,
          equals(
            ValidationIssue(
              severity: ValidationIssueSeverity.error,
              message:
                  '''${p.join('android', 'app', 'src', 'main', 'AndroidManifest.xml')} is missing the INTERNET permission.''',
            ),
          ),
        );
      });
    });

    group('fix', () {
      test('adds permission to manifest file', () async {
        writeManifestToPath(
          manifestWithNonInternetPermissions,
          p.join(projectRoot.path, 'android', 'app', 'src', 'main'),
        );

        var results = await runWithOverrides(
          AndroidInternetPermissionValidator().validate,
        );
        expect(results, hasLength(1));
        expect(results.first.fix, isNotNull);

        await runWithOverrides(() => results.first.fix!());

        results = await runWithOverrides(
          AndroidInternetPermissionValidator().validate,
        );
        expect(results, isEmpty);
      });
    });
  });
}
