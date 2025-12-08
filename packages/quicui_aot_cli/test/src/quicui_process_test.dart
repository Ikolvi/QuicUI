// cspell:ignore asdfasdf
import 'dart:io' hide Platform;

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:platform/platform.dart';
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/engine_config.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/platform.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:quicui_aot_cli/src/quicui_process.dart';
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  group('QuicuiProcess', () {
    const flutterStorageBaseUrlEnv = {
      'FLUTTER_STORAGE_BASE_URL': 'https://download.quicui.dev',
    };

    late EngineConfig engineConfig;
    late QuicuiLogger logger;
    late Platform platform;
    late ProcessWrapper processWrapper;
    late Process startProcess;
    late QuicuiProcessResult runProcessResult;
    late QuicuiEnv quicuiEnv;
    late QuicuiProcess quicuiProcess;

    R runWithOverrides<R>(R Function() body) {
      return runScoped(
        () => body(),
        values: {
          engineConfigRef.overrideWith(() => engineConfig),
          loggerRef.overrideWith(() => logger),
          platformRef.overrideWith(() => platform),
          quicuiEnvRef.overrideWith(() => quicuiEnv),
        },
      );
    }

    setUp(() {
      engineConfig = const EngineConfig.empty();
      logger = MockQuicuiLogger();
      platform = MockPlatform();
      processWrapper = MockProcessWrapper();
      runProcessResult = MockProcessResult();
      startProcess = MockProcess();
      quicuiEnv = MockQuicuiEnv();
      quicuiProcess = runWithOverrides(
        () => QuicuiProcess(processWrapper: processWrapper),
      );

      when(
        () => quicuiEnv.flutterBinaryFile,
      ).thenReturn(File(p.join('bin', 'cache', 'flutter', 'bin', 'flutter')));

      when(() => runProcessResult.stderr).thenReturn('stderr');
      when(() => runProcessResult.stdout).thenReturn('stdout');
      when(() => runProcessResult.exitCode).thenReturn(ExitCode.success.code);

      when(() => logger.level).thenReturn(Level.info);

      when(() => platform.isWindows).thenReturn(false);
    });

    test('QuicuiProcessResult can be instantiated as a const', () {
      expect(
        () => const QuicuiProcessResult(exitCode: 0, stdout: '', stderr: ''),
        returnsNormally,
      );
    });

    group('run', () {
      setUp(() {
        when(
          () => processWrapper.run(
            any(),
            any(),
            environment: any(named: 'environment'),
            workingDirectory: any(named: 'workingDirectory'),
            runInShell: any(named: 'runInShell'),
          ),
        ).thenAnswer((_) async => runProcessResult);
      });

      test('can override runInShell', () async {
        await runWithOverrides(
          () => quicuiProcess.run('git', ['pull'], runInShell: true),
        );

        verify(
          () => processWrapper.run(
            'git',
            ['pull'],
            environment: {},
            workingDirectory: any(named: 'workingDirectory'),
            runInShell: true,
          ),
        ).called(1);
      });

      test('forwards non-flutter executables to Process.run', () async {
        await runWithOverrides(
          () => quicuiProcess.run('git', ['pull'], workingDirectory: '~'),
        );

        verify(
          () => processWrapper.run(
            'git',
            ['pull'],
            environment: {},
            workingDirectory: '~',
          ),
        ).called(1);
      });

      test('sanitizes executable on windows', () async {
        when(() => platform.isWindows).thenReturn(true);
        const executable =
            r'C:\Program Files\Android\Android Studio\jbr\bin\java.exe';
        await runWithOverrides(
          () => quicuiProcess.run(executable, ['--version']),
        );
        verify(
          () => processWrapper.run(
            '"$executable"',
            ['--version'],
            environment: any(named: 'environment'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).called(1);
      });

      test('replaces "flutter" with our local flutter', () async {
        await runWithOverrides(
          () => quicuiProcess.run('flutter', [
            '--version',
          ], workingDirectory: '~'),
        );

        verify(
          () => processWrapper.run(
            any(
              that: contains(
                p.join('bin', 'cache', 'flutter', 'bin', 'flutter'),
              ),
            ),
            ['--version'],
            environment: flutterStorageBaseUrlEnv,
            workingDirectory: '~',
          ),
        ).called(1);
      });

      test('does not replace flutter with our local flutter if'
          ' useVendedFlutter is false', () async {
        await runWithOverrides(
          () => quicuiProcess.run(
            'flutter',
            ['--version'],
            workingDirectory: '~',
            useVendedFlutter: false,
          ),
        );

        verify(
          () => processWrapper.run(
            'flutter',
            ['--version'],
            environment: {},
            workingDirectory: '~',
          ),
        ).called(1);
      });

      test('Updates environment if useVendedFlutter is true', () async {
        await runWithOverrides(
          () => quicuiProcess.run(
            'flutter',
            ['--version'],
            workingDirectory: '~',
            useVendedFlutter: false,
            environment: {'ENV_VAR': 'asdfasdf'},
          ),
        );

        verify(
          () => processWrapper.run(
            'flutter',
            ['--version'],
            workingDirectory: '~',
            environment: {'ENV_VAR': 'asdfasdf'},
          ),
        ).called(1);
      });

      test(
        'Makes no changes to environment if useVendedFlutter is false',
        () async {
          await runWithOverrides(
            () => quicuiProcess.run(
              'flutter',
              ['--version'],
              workingDirectory: '~',
              useVendedFlutter: false,
              environment: {'ENV_VAR': 'asdfasdf'},
            ),
          );

          verify(
            () => processWrapper.run(
              'flutter',
              ['--version'],
              workingDirectory: '~',
              environment: {'ENV_VAR': 'asdfasdf'},
            ),
          ).called(1);
        },
      );

      test('adds local-engine arguments if set', () async {
        engineConfig = EngineConfig(
          localEngineSrcPath: p.join('path', 'to', 'engine', 'src'),
          localEngine: 'android_release_arm64',
          localEngineHost: 'host_release',
        );
        final localEngineSrcPath = p.join('path', 'to', 'engine', 'src');
        quicuiProcess = QuicuiProcess(processWrapper: processWrapper);

        await runWithOverrides(() => quicuiProcess.run('flutter', []));

        verify(
          () => processWrapper.run(
            any(),
            [
              '--local-engine-src-path=$localEngineSrcPath',
              '--local-engine=android_release_arm64',
              '--local-engine-host=host_release',
            ],
            environment: any(named: 'environment'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).called(1);
      });

      test('logs stdout and stderr', () async {
        await runWithOverrides(() => quicuiProcess.run('flutter', []));

        verify(() => logger.detail(any(that: contains('stdout')))).called(1);
        verify(() => logger.detail(any(that: contains('stderr')))).called(1);
      });
    });

    group('runSync', () {
      setUp(() {
        when(
          () => processWrapper.runSync(
            any(),
            any(),
            environment: any(named: 'environment'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).thenReturn(runProcessResult);
      });

      test('forwards non-flutter executables to Process.runSync', () async {
        runWithOverrides(
          () =>
              quicuiProcess.runSync('git', ['pull'], workingDirectory: '~'),
        );

        verify(
          () => processWrapper.runSync(
            'git',
            ['pull'],
            environment: {},
            workingDirectory: '~',
          ),
        ).called(1);
      });

      test('sanitizes executable on windows', () {
        when(() => platform.isWindows).thenReturn(true);
        const executable =
            r'C:\Program Files\Android\Android Studio\jbr\bin\java.exe';
        runWithOverrides(
          () => quicuiProcess.runSync(executable, ['--version']),
        );
        verify(
          () => processWrapper.runSync(
            '"$executable"',
            ['--version'],
            environment: any(named: 'environment'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).called(1);
      });

      test('replaces "flutter" with our local flutter', () {
        runWithOverrides(
          () => quicuiProcess.runSync('flutter', [
            '--version',
          ], workingDirectory: '~'),
        );

        verify(
          () => processWrapper.runSync(
            any(
              that: contains(
                p.join('bin', 'cache', 'flutter', 'bin', 'flutter'),
              ),
            ),
            ['--version'],
            environment: flutterStorageBaseUrlEnv,
            workingDirectory: '~',
          ),
        ).called(1);
      });

      test(
        '''does not replace flutter with our local flutter if useVendedFlutter is false''',
        () {
          runWithOverrides(
            () => quicuiProcess.runSync(
              'flutter',
              ['--version'],
              workingDirectory: '~',
              useVendedFlutter: false,
            ),
          );

          verify(
            () => processWrapper.runSync(
              'flutter',
              ['--version'],
              environment: {},
              workingDirectory: '~',
            ),
          ).called(1);
        },
      );

      test('Updates environment if useVendedFlutter is true', () {
        runWithOverrides(
          () => quicuiProcess.runSync(
            'flutter',
            ['--version'],
            workingDirectory: '~',
            useVendedFlutter: false,
            environment: {'ENV_VAR': 'asdfasdf'},
          ),
        );

        verify(
          () => processWrapper.runSync(
            'flutter',
            ['--version'],
            workingDirectory: '~',
            environment: {'ENV_VAR': 'asdfasdf'},
          ),
        ).called(1);
      });

      test('Makes no changes to environment if useVendedFlutter is false', () {
        runWithOverrides(
          () => quicuiProcess.runSync(
            'flutter',
            ['--version'],
            workingDirectory: '~',
            useVendedFlutter: false,
            environment: {'ENV_VAR': 'asdfasdf'},
          ),
        );

        verify(
          () => processWrapper.runSync(
            'flutter',
            ['--version'],
            workingDirectory: '~',
            environment: {'ENV_VAR': 'asdfasdf'},
          ),
        ).called(1);
      });

      group('when log level is verbose', () {
        setUp(() {
          when(() => logger.level).thenReturn(Level.verbose);
        });

        test('passes --verbose to flutter executable', () {
          runWithOverrides(() => quicuiProcess.runSync('flutter', []));

          verify(
            () => processWrapper.runSync(
              any(),
              ['--verbose'],
              environment: any(named: 'environment'),
              workingDirectory: any(named: 'workingDirectory'),
            ),
          ).called(1);
        });
      });

      group('when result has non-zero exit code', () {
        setUp(() {
          when(() => runProcessResult.exitCode).thenReturn(1);
          when(() => runProcessResult.stdout).thenReturn('out');
          when(() => runProcessResult.stderr).thenReturn('err');
        });

        test('logs stdout and stderr if present', () {
          runWithOverrides(() => quicuiProcess.runSync('flutter', []));

          verify(() => logger.detail(any(that: contains('stdout')))).called(1);
          verify(() => logger.detail(any(that: contains('stderr')))).called(1);
        });
      });
    });

    group('stream', () {
      late Process streamProcess;

      setUp(() {
        streamProcess = MockProcess();
        when(
          () => processWrapper.start(
            any(),
            any(),
            environment: any(named: 'environment'),
            mode: ProcessStartMode.inheritStdio,
          ),
        ).thenAnswer((_) async => streamProcess);
        when(
          () => streamProcess.exitCode,
        ).thenAnswer((_) async => ExitCode.success.code);
      });

      test('proxies to start with correct mode', () async {
        await expectLater(
          runWithOverrides(() => quicuiProcess.stream('git', ['pull'])),
          completion(equals(ExitCode.success.code)),
        );

        verify(
          () => processWrapper.start(
            'git',
            ['pull'],
            environment: {},
            mode: ProcessStartMode.inheritStdio,
          ),
        ).called(1);
      });
    });

    group('start', () {
      setUp(() {
        when(
          () => processWrapper.start(
            any(),
            any(),
            runInShell: any(named: 'runInShell'),
            environment: any(named: 'environment'),
          ),
        ).thenAnswer((_) async => startProcess);
      });

      test('forwards non-flutter executables to Process.run', () async {
        await runWithOverrides(() => quicuiProcess.start('git', ['pull']));

        verify(
          () => processWrapper.start('git', ['pull'], environment: {}),
        ).called(1);
      });

      test('can override runInShell', () async {
        await runWithOverrides(
          () => quicuiProcess.start('git', ['pull'], runInShell: true),
        );

        verify(
          () => processWrapper.start(
            'git',
            ['pull'],
            environment: {},
            workingDirectory: any(named: 'workingDirectory'),
            runInShell: true,
          ),
        ).called(1);
      });

      test('sanitizes executable on windows', () async {
        when(() => platform.isWindows).thenReturn(true);
        const executable =
            r'C:\Program Files\Android\Android Studio\jbr\bin\java.exe';
        await runWithOverrides(
          () => quicuiProcess.start(executable, ['--version']),
        );
        verify(
          () => processWrapper.start(
            '"$executable"',
            ['--version'],
            environment: any(named: 'environment'),
            workingDirectory: any(named: 'workingDirectory'),
          ),
        ).called(1);
      });

      test('replaces "flutter" with our local flutter', () async {
        await runWithOverrides(
          () => quicuiProcess.start('flutter', ['run']),
        );

        verify(
          () => processWrapper.start(
            any(
              that: contains(
                p.join('bin', 'cache', 'flutter', 'bin', 'flutter'),
              ),
            ),
            ['run'],
            environment: flutterStorageBaseUrlEnv,
          ),
        ).called(1);
      });

      test('does not replace flutter with our local flutter if'
          ' useVendedFlutter is false', () async {
        await runWithOverrides(
          () => quicuiProcess.start('flutter', [
            '--version',
          ], useVendedFlutter: false),
        );

        verify(
          () => processWrapper.start('flutter', ['--version'], environment: {}),
        ).called(1);
      });
      test('Updates environment if useVendedFlutter is true', () async {
        await runWithOverrides(
          () => quicuiProcess.start(
            'flutter',
            ['--version'],
            environment: {'ENV_VAR': 'asdfasdf'},
          ),
        );

        verify(
          () => processWrapper.start(
            any(
              that: contains(
                p.join('bin', 'cache', 'flutter', 'bin', 'flutter'),
              ),
            ),
            ['--version'],
            environment: {'ENV_VAR': 'asdfasdf', ...flutterStorageBaseUrlEnv},
          ),
        ).called(1);
      });

      test(
        'Makes no changes to environment if useVendedFlutter is false',
        () async {
          await runWithOverrides(
            () => quicuiProcess.start(
              'flutter',
              ['--version'],
              useVendedFlutter: false,
              environment: {'hello': 'world'},
            ),
          );

          verify(
            () => processWrapper.start(
              'flutter',
              ['--version'],
              environment: {'hello': 'world'},
            ),
          ).called(1);
        },
      );
    });
  });
}
