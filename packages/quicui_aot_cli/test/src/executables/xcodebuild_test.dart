import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/executables/executables.dart';
import 'package:quicui_aot_cli/src/quicui_process.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group(XcodeBuild, () {
    late QuicuiProcess process;
    late XcodeBuild xcodeBuild;

    R runWithOverrides<R>(R Function() body) {
      return runScoped(body, values: {processRef.overrideWith(() => process)});
    }

    setUp(() {
      process = MockQuicuiProcess();
      xcodeBuild = runWithOverrides(XcodeBuild.new);
    });

    group('version', () {
      group('when command exits with non-zero code', () {
        setUp(() {
          when(() => process.run('xcodebuild', ['-version'])).thenAnswer(
            (_) async => QuicuiProcessResult(
              exitCode: ExitCode.software.code,
              stdout: '',
              stderr: 'error',
            ),
          );
        });

        test('throws ProcessException', () async {
          expect(
            () => runWithOverrides(xcodeBuild.version),
            throwsA(isA<ProcessException>()),
          );
        });
      });

      group('when command exits with success code', () {
        setUp(() {
          when(() => process.run('xcodebuild', ['-version'])).thenAnswer(
            (_) async => QuicuiProcessResult(
              exitCode: ExitCode.success.code,
              stdout: '''
Xcode 15.3
Build version 15E204a
''',
              stderr: '',
            ),
          );
        });

        test('returns output lines joined by spaces', () async {
          expect(
            await runWithOverrides(xcodeBuild.version),
            equals('Xcode 15.3 Build version 15E204a'),
          );
        });
      });
    });
  });
}
