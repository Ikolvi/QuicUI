import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:platform/platform.dart';
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart' hide logger;
import 'package:quicui_aot_cli/src/platform.dart';
import 'package:quicui_aot_cli/src/quicui_aot_cli_command_runner.dart';
import 'package:quicui_aot_cli/src/quicui_command.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:quicui_aot_cli/src/quicui_flutter.dart';
import 'package:quicui_aot_cli/src/quicui_version.dart';
import 'package:quicui_aot_cli/src/third_party/flutter_tools/lib/flutter_tools.dart';
import 'package:quicui_aot_cli/src/version.dart';
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  group(QuicuiAotCliCommandRunner, () {
    const quicuiEngineRevision = 'test-engine-revision';
    const flutterRevision = 'test-flutter-revision';
    const flutterVersion = '1.2.3';

    late QuicuiLogger logger;
    late Platform platform;
    late QuicuiEnv quicuiEnv;
    late QuicuiFlutter quicuiFlutter;
    late QuicuiVersion quicuiVersion;
    late QuicuiAotCliCommandRunner commandRunner;

    R runWithOverrides<R>(R Function() body) {
      return runScoped(
        body,
        values: {
          loggerRef.overrideWith(() => logger),
          platformRef.overrideWith(() => platform),
          quicuiEnvRef.overrideWith(() => quicuiEnv),
          quicuiFlutterRef.overrideWith(() => quicuiFlutter),
          quicuiVersionRef.overrideWith(() => quicuiVersion),
        },
      );
    }

    setUp(() {
      logger = MockQuicuiLogger();
      platform = MockPlatform();
      quicuiEnv = MockQuicuiEnv();
      quicuiFlutter = MockQuicuiFlutter();
      quicuiVersion = MockQuicuiVersion();
      when(() => logger.level).thenReturn(Level.info);
      final logFile = MockFile();
      when(
        () => quicuiEnv.logsDirectory,
      ).thenReturn(Directory.systemTemp.createTempSync());
      when(() => logFile.absolute).thenReturn(logFile);
      when(() => logFile.path).thenReturn('test.log');
      when(
        () => quicuiEnv.quicuiEngineRevision,
      ).thenReturn(quicuiEngineRevision);
      when(() => platform.isWindows).thenReturn(false);
      when(() => quicuiEnv.flutterRevision).thenReturn(flutterRevision);
      when(
        () => quicuiFlutter.getVersionString(),
      ).thenAnswer((_) async => flutterVersion);
      when(quicuiVersion.isLatest).thenAnswer((_) async => true);
      when(quicuiVersion.isTrackingStable).thenAnswer((_) async => true);
      commandRunner = runWithOverrides(QuicuiAotCliCommandRunner.new);
    });

    group('handles ProcessExit', () {
      test('does nothing when exit code is 0', () async {
        commandRunner.addCommand(_TestCommand(ExitCode.success));
        final result = await runWithOverrides(
          () => commandRunner.run(['test']),
        );
        expect(result, equals(ExitCode.success.code));
      });

      test('exits with the correct code', () async {
        commandRunner.addCommand(_TestCommand(ExitCode.unavailable));
        final result = await runWithOverrides(
          () => commandRunner.run(['test']),
        );
        expect(result, equals(ExitCode.unavailable.code));
        verify(
          () => logger.info(
            any(
              that: contains('''If you aren't sure why this command failed'''),
            ),
          ),
        ).called(1);
      });
    });

    test('handles FormatException', () async {
      const exception = FormatException('oops!');
      var isFirstInvocation = true;
      when(() => logger.info(any())).thenAnswer((_) {
        if (isFirstInvocation) {
          isFirstInvocation = false;
          throw exception;
        }
      });
      final result = await runWithOverrides(
        () => commandRunner.run(['--version']),
      );
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(exception.message)).called(1);
      verify(() => logger.info(commandRunner.usage)).called(1);
    });

    group('when runCommand returns null exitCode', () {
      test('does not print failure text', () async {
        final result = await runWithOverrides(
          () => commandRunner.run(['--help']),
        );
        expect(result, equals(ExitCode.success.code));
        verifyNever(
          () => logger.info(
            any(that: contains("If you aren't sure why this command failed")),
          ),
        );
      });
    });

    test('handles UsageException', () async {
      final result = await runWithOverrides(
        // fly_to_the_moon is not a valid command.
        () => commandRunner.run(['fly_to_the_moon']),
      );
      expect(result, equals(ExitCode.usage.code));
      verify(
        () => logger.err('Could not find a command named "fly_to_the_moon".'),
      ).called(1);
      verify(
        () => logger.info(
          any(that: contains('Usage: quicui <command> [arguments]')),
        ),
      ).called(1);
    });

    test('handles missing option error', () async {
      final exception = UsageException(
        'Could not find an option named "foo".',
        'exception usage',
      );
      var isFirstInvocation = true;
      when(() => logger.info(any())).thenAnswer((_) {
        if (isFirstInvocation) {
          isFirstInvocation = false;
          throw exception;
        }
      });
      final result = await runWithOverrides(
        () => commandRunner.run(['--version']),
      );
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(exception.message)).called(1);
      verify(
        () => logger.err('''
To proxy an option to the flutter command, use the -- --<option> syntax.

Example:

${lightCyan.wrap('quicui release android -- --no-pub lib/main.dart')}'''),
      ).called(1);
      verify(() => logger.info('exception usage')).called(1);
    });

    test('handles missing option error on Windows', () async {
      when(() => platform.isWindows).thenReturn(true);
      final exception = UsageException(
        'Could not find an option named "foo".',
        'exception usage',
      );
      var isFirstInvocation = true;
      when(() => logger.info(any())).thenAnswer((_) {
        if (isFirstInvocation) {
          isFirstInvocation = false;
          throw exception;
        }
      });
      final result = await runWithOverrides(
        () => commandRunner.run(['--version']),
      );
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(exception.message)).called(1);
      verify(
        () => logger.err('''
To proxy an option to the flutter command, use the '--' --<option> syntax.

Example:

${lightCyan.wrap("quicui release android '--' --no-pub lib/main.dart")}'''),
      ).called(1);
      verify(() => logger.info('exception usage')).called(1);
    });

    group('--version', () {
      test('outputs current version info', () async {
        final result = await runWithOverrides(
          () => commandRunner.run(['--version']),
        );
        expect(result, equals(ExitCode.success.code));

        verify(
          () => logger.info('''
Quicui $packageVersion • git@github.com:quicuitech/quicui.git
Flutter $flutterVersion • revision $flutterRevision
Engine • revision $quicuiEngineRevision'''),
        ).called(1);

        // Making sure the only thing that was logged was the version info.
        // https://github.com/quicuitech/quicui/issues/2260
        verifyNever(() => logger.info(any()));
      });
    });

    group('--verbose', () {
      test('enables verbose logging', () async {
        final result = await runWithOverrides(
          () => commandRunner.run(['--verbose']),
        );
        expect(result, equals(ExitCode.success.code));
      });
    });

    group('local engine', () {
      group('when all local engine args are provided', () {
        test('creates engine config with arguments', () async {
          final result = await runWithOverrides(
            () => commandRunner.run([
              '--local-engine',
              'foo',
              '--local-engine-src-path',
              'bar',
              '--local-engine-host',
              'baz',
            ]),
          );
          expect(result, equals(ExitCode.success.code));
        });
      });

      group('when no local engine args are provided', () {
        test('uses empty engine config', () async {
          final result = await runWithOverrides(() => commandRunner.run([]));
          expect(result, equals(ExitCode.success.code));
        });
      });

      group('when some local engine args are provided', () {
        test('throws ArgumentException', () async {
          await expectLater(
            () async => runWithOverrides(
              () => commandRunner.run(['--local-engine', 'foo']),
            ),
            throwsArgumentError,
          );
        });
      });
    });

    group('on command failure', () {
      test('logs error and stack trace using detail', () async {
        // This will fail with a StateError due to the release android command
        // missing scoped dependencies.
        // Note: the --verbose flag is here for illustrative purposes only.
        // Because logger is a mock, setting the log level in code does
        // nothing.
        await runWithOverrides(
          () => commandRunner.run(['release', 'android', '--verbose']),
        );
        verify(() => logger.err(any(that: contains('Bad state')))).called(1);
        verify(() => logger.detail(any(that: contains('#0')))).called(1);
      });

      group('when running with --verbose', () {
        setUp(() {
          when(() => logger.level).thenReturn(Level.verbose);
        });

        test('does not suggest running with --verbose', () async {
          // This will fail due to the release android command missing scoped
          // dependencies.
          // Note: the --verbose flag is here for illustrative purposes only.
          // Because logger is a mock, setting the log level in code does
          // nothing.
          await runWithOverrides(
            () => commandRunner.run(['release', 'android', '--verbose']),
          );
          verifyNever(() => logger.info(any(that: contains('--verbose'))));
        });
      });

      group('when running without --verbose', () {
        test('suggests using --verbose flag', () async {
          // This will fail due to the release android command missing scoped
          // dependencies.
          await runWithOverrides(
            () => commandRunner.run(['release', 'android']),
          );
          verify(() => logger.info(any(that: contains('--verbose')))).called(1);
        });
      });
    });

    group('completion', () {
      test('fast tracks completion', () async {
        final result = await runWithOverrides(
          () => commandRunner.run(['completion']),
        );
        expect(result, equals(ExitCode.success.code));
      });
    });

    group('update check', () {
      group('when running upgrade command', () {
        setUp(() {
          when(() => logger.progress(any())).thenReturn(MockProgress());
          when(
            quicuiVersion.fetchCurrentGitHash,
          ).thenAnswer((_) async => 'current');
          when(
            quicuiVersion.fetchLatestGitHash,
          ).thenAnswer((_) async => 'current');
        });
        test('does not check for update', () async {
          final result = await runWithOverrides(
            () => commandRunner.run(['upgrade']),
          );
          expect(result, equals(ExitCode.success.code));
          verifyNever(() => quicuiVersion.isTrackingStable());
          verifyNever(() => quicuiVersion.isLatest());
        });
      });

      group('when tracking the stable branch', () {
        setUp(() {
          when(quicuiVersion.isTrackingStable).thenAnswer((_) async => true);
        });

        test(
          'gracefully handles case when latest version cannot be determined',
          () async {
            when(quicuiVersion.isLatest).thenThrow(Exception('error'));
            final result = await runWithOverrides(
              () => commandRunner.run(['--version']),
            );
            expect(result, equals(ExitCode.success.code));
            verify(
              () => logger.detail(
                'Unable to check for updates.\nException: error',
              ),
            ).called(1);
          },
        );

        group('when update is available', () {
          test('logs update message', () async {
            when(quicuiVersion.isLatest).thenAnswer((_) async => false);
            final result = await runWithOverrides(
              () => commandRunner.run(['--version']),
            );
            verify(
              () => logger.info('A new version of quicui is available!'),
            ).called(1);
            verify(
              () => logger.info(
                'Run ${lightCyan.wrap('quicui upgrade')} to upgrade.',
              ),
            ).called(1);

            expect(result, equals(ExitCode.success.code));
          });
        });

        group('when no update is available', () {
          setUp(() {
            when(quicuiVersion.isLatest).thenAnswer((_) async => true);
          });

          test('does not log update message', () async {
            final result = await runWithOverrides(
              () => commandRunner.run(['--version']),
            );
            expect(result, equals(ExitCode.success.code));
            verifyNever(
              () => logger.info('A new version of quicui is available!'),
            );
          });
        });

        test(
          'gracefully handles case when flutter version cannot be determined',
          () async {
            when(
              quicuiFlutter.getVersionString,
            ).thenThrow(Exception('error'));
            final result = await runWithOverrides(
              () => commandRunner.run(['--version']),
            );
            expect(result, equals(ExitCode.success.code));
            verify(
              () => logger.detail(
                'Unable to determine Flutter version.\nException: error',
              ),
            ).called(1);
          },
        );
      });

      group('when not tracking the stable branch', () {
        setUp(() {
          when(
            quicuiVersion.isTrackingStable,
          ).thenAnswer((_) async => false);
          when(quicuiVersion.isLatest).thenAnswer((_) async => false);
        });

        test('does not check for updates or print update message', () async {
          final result = await runWithOverrides(
            () => commandRunner.run(['--version']),
          );
          expect(result, equals(ExitCode.success.code));

          verifyNever(quicuiVersion.isLatest);
          verifyNever(
            () => logger.info('A new version of quicui is available!'),
          );
        });
      });
    });
  });
}

class _TestCommand extends QuicuiCommand {
  _TestCommand(this.exitCode);

  final ExitCode exitCode;

  @override
  String get name => 'test';

  @override
  String get description => 'Test command';

  @override
  Future<int> run() async {
    throw ProcessExit(exitCode.code);
  }
}
