import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/executables/executables.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:quicui_aot_cli/src/quicui_process.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('QuicuiTools', () {
    late File dartBinaryFile;
    late Directory flutterDirectory;
    late Directory tempDir;
    late QuicuiLogger logger;
    late QuicuiEnv quicuiEnv;
    late QuicuiProcess process;
    late QuicuiProcessResult processResult;

    R runWithOverrides<R>(R Function() body) {
      return runScoped(
        () => body(),
        values: {
          processRef.overrideWith(() => process),
          quicuiEnvRef.overrideWith(() => quicuiEnv),
          loggerRef.overrideWith(() => logger),
          quicuiToolsRef,
        },
      );
    }

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
      flutterDirectory = Directory(p.join(tempDir.path, 'flutter'))
        ..createSync();
      dartBinaryFile = File(p.join(tempDir.path, 'dart'))..createSync();
      processResult = MockProcessResult();
      quicuiEnv = MockQuicuiEnv();
      process = MockQuicuiProcess();
      logger = MockQuicuiLogger();

      when(() => processResult.exitCode).thenReturn(0);
      when(() => processResult.stdout).thenReturn('');
      when(() => processResult.stderr).thenReturn('');

      when(() => quicuiEnv.flutterDirectory).thenReturn(flutterDirectory);
      when(() => quicuiEnv.dartBinaryFile).thenReturn(dartBinaryFile);

      when(
        () => process.run(
          any(),
          any(),
          workingDirectory: any(named: 'workingDirectory'),
        ),
      ).thenAnswer((_) async => processResult);
    });

    test('have access a reference to quicui tool', () {
      expect(
        runScoped(() => quicuiTools, values: {quicuiToolsRef}),
        isA<QuicuiTools>(),
      );
    });

    test('makes the correct cli call', () async {
      await runWithOverrides(
        () => quicuiTools.package(
          patchPath: 'patchPath',
          outputPath: 'outputPath',
        ),
      );

      verify(
        () => process.run(
          dartBinaryFile.path,
          any(
            that: containsAllInOrder([
              'run',
              'quicui_tools',
              'package',
              '-p',
              'patchPath',
              '-o',
              'outputPath',
            ]),
          ),
          workingDirectory: p.join(
            flutterDirectory.path,
            'packages',
            'quicui_tools',
          ),
        ),
      ).called(1);
    });

    group('when the command fails', () {
      setUp(() {
        when(() => processResult.exitCode).thenReturn(1);
        when(() => processResult.stdout).thenReturn('stdout');
        when(() => processResult.stderr).thenReturn('stderr');
      });

      test('throws a PackageFailedException', () {
        expect(
          () => runWithOverrides(
            () => quicuiTools.package(
              patchPath: 'patchPath',
              outputPath: 'outputPath',
            ),
          ),
          throwsA(
            isA<PackageFailedException>().having(
              (e) => e.toString(),
              'message',
              '''
Failed to create package (exit code ${processResult.exitCode}).
  stdout: ${processResult.stdout}
  stderr: ${processResult.stderr}''',
            ),
          ),
        );
      });
    });

    group('when the quicui tools directory exists', () {
      test('isSupported returns true', () {
        Directory(
          p.join(flutterDirectory.path, 'packages', 'quicui_tools'),
        ).createSync(recursive: true);
        final isSupported = runWithOverrides(
          () => quicuiTools.isSupported(),
        );
        expect(isSupported, isTrue);
      });
    });

    group('when the quicui tools directory does not exist', () {
      test('isSupported returns false', () {
        final isSupported = runWithOverrides(
          () => quicuiTools.isSupported(),
        );
        expect(isSupported, isFalse);
      });
    });
  });
}
