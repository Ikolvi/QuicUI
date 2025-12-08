import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/commands/commands.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/quicui_version.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  const currentQuicuiRevision = 'revision-1';
  const newerQuicuiRevision = 'revision-2';

  group('upgrade', () {
    late QuicuiLogger logger;
    late QuicuiVersion quicuiVersion;
    late UpgradeCommand command;

    R runWithOverrides<R>(R Function() body) {
      return runScoped(
        body,
        values: {
          loggerRef.overrideWith(() => logger),
          quicuiVersionRef.overrideWith(() => quicuiVersion),
        },
      );
    }

    setUp(() {
      final progress = MockProgress();
      final progressLogs = <String>[];

      logger = MockQuicuiLogger();
      quicuiVersion = MockQuicuiVersion();
      command = runWithOverrides(UpgradeCommand.new);

      when(
        quicuiVersion.fetchCurrentGitHash,
      ).thenAnswer((_) async => currentQuicuiRevision);
      when(
        quicuiVersion.fetchLatestGitHash,
      ).thenAnswer((_) async => newerQuicuiRevision);
      when(
        () => quicuiVersion.attemptReset(revision: any(named: 'revision')),
      ).thenAnswer((_) async => {});

      when(() => progress.complete(any())).thenAnswer((invocation) {
        final message = invocation.positionalArguments.elementAt(0) as String?;
        if (message != null) progressLogs.add(message);
      });
      when(() => logger.progress(any())).thenReturn(progress);
    });

    test('can be instantiated', () {
      final command = UpgradeCommand();
      expect(command, isNotNull);
    });

    test('handles errors when determining the current version', () async {
      const errorMessage = 'oops';
      when(
        quicuiVersion.fetchCurrentGitHash,
      ).thenThrow(const ProcessException('git', ['rev-parse'], errorMessage));

      final result = await runWithOverrides(command.run);

      expect(result, equals(ExitCode.software.code));
      verify(() => logger.progress('Checking for updates')).called(1);
      verify(
        () => logger.err('Fetching current version failed: $errorMessage'),
      ).called(1);
    });

    test('handles errors when determining the latest version', () async {
      const errorMessage = 'oops';
      when(
        quicuiVersion.fetchLatestGitHash,
      ).thenThrow(const ProcessException('git', ['rev-parse'], errorMessage));

      final result = await runWithOverrides(command.run);

      expect(result, equals(ExitCode.software.code));
      verify(() => logger.progress('Checking for updates')).called(1);
      verify(() => logger.err('Checking for updates failed: oops')).called(1);
    });

    test('handles errors when updating', () async {
      const errorMessage = 'oops';
      when(
        () => quicuiVersion.attemptReset(revision: any(named: 'revision')),
      ).thenThrow(const ProcessException('git', ['reset'], errorMessage));

      final result = await runWithOverrides(command.run);

      expect(result, equals(ExitCode.software.code));
      verify(() => logger.progress('Checking for updates')).called(1);
      verify(() => logger.err('Updating failed: oops')).called(1);
    });

    test('updates when newer version exists', () async {
      when(() => logger.progress(any())).thenReturn(MockProgress());

      final result = await runWithOverrides(command.run);

      expect(result, equals(ExitCode.success.code));
      verify(() => logger.progress('Checking for updates')).called(1);
      verify(() => logger.progress('Updating')).called(1);
    });

    test('does not update when already on latest version', () async {
      when(
        quicuiVersion.fetchLatestGitHash,
      ).thenAnswer((_) async => currentQuicuiRevision);
      when(() => logger.progress(any())).thenReturn(MockProgress());

      final result = await runWithOverrides(command.run);

      expect(result, equals(ExitCode.success.code));
      verify(
        () => logger.info('Quicui is already at the latest version.'),
      ).called(1);
    });
  });
}
