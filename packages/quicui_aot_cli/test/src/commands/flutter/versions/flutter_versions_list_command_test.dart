import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/commands/commands.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/quicui_flutter.dart';
import 'package:test/test.dart';

import '../../../mocks.dart';

void main() {
  group(FlutterVersionsListCommand, () {
    late Progress progress;
    late QuicuiLogger logger;
    late QuicuiFlutter quicuiFlutter;
    late FlutterVersionsListCommand command;

    R runWithOverrides<R>(R Function() body) {
      return runScoped(
        body,
        values: {
          loggerRef.overrideWith(() => logger),
          quicuiFlutterRef.overrideWith(() => quicuiFlutter),
        },
      );
    }

    setUp(() {
      progress = MockProgress();
      logger = MockQuicuiLogger();
      quicuiFlutter = MockQuicuiFlutter();
      command = runWithOverrides(FlutterVersionsListCommand.new);

      when(() => logger.progress(any())).thenReturn(progress);
    });

    test('has correct name and description', () {
      expect(command.name, equals('list'));
      expect(command.description, equals('List available Flutter versions.'));
    });

    test(
      'exits with code 70 when unable to determine Flutter versions',
      () async {
        when(
          () => quicuiFlutter.getVersionString(),
        ).thenAnswer((_) async => '1.0.0');
        when(
          () => quicuiFlutter.getVersions(),
        ).thenThrow(Exception('error'));
        await expectLater(
          runWithOverrides(command.run),
          completion(equals(ExitCode.software.code)),
        );
        verifyInOrder([
          () => logger.progress('Fetching Flutter versions'),
          () => quicuiFlutter.getVersionString(),
          () => quicuiFlutter.getVersions(),
          () => progress.fail('Failed to fetch Flutter versions.'),
          () => logger.err('Exception: error'),
        ]);
      },
    );

    test(
      'exits with code 0 when able to determine Flutter versions w/out current version',
      () async {
        const versions = ['1.0.0', '1.0.1'];
        when(() => quicuiFlutter.getVersionString()).thenThrow(
          const ProcessException('flutter', ['--version'], 'Flutter 1.0.0'),
        );
        when(
          () => quicuiFlutter.getVersions(),
        ).thenAnswer((_) async => versions);
        await expectLater(
          runWithOverrides(command.run),
          completion(equals(ExitCode.success.code)),
        );
        verifyInOrder([
          () => logger.progress('Fetching Flutter versions'),
          () => quicuiFlutter.getVersionString(),
          () => quicuiFlutter.getVersions(),
          () => progress.cancel(),
          () => logger.info('📦 Flutter Versions'),
          () => logger.info('  1.0.1'),
          () => logger.info('  1.0.0'),
        ]);
      },
    );

    test('exits with code 0 when able to determine Flutter versions '
        'as well as the current version', () async {
      const versions = ['1.0.0', '1.0.1'];
      when(
        () => quicuiFlutter.getVersionString(),
      ).thenAnswer((_) async => versions.first);

      when(
        () => quicuiFlutter.getVersions(),
      ).thenAnswer((_) async => versions);
      await expectLater(
        runWithOverrides(command.run),
        completion(equals(ExitCode.success.code)),
      );
      verifyInOrder([
        () => logger.progress('Fetching Flutter versions'),
        () => quicuiFlutter.getVersionString(),
        () => quicuiFlutter.getVersions(),
        () => progress.cancel(),
        () => logger.info('📦 Flutter Versions'),
        () => logger.info('  1.0.1'),
        () => logger.info(lightCyan.wrap('✓ 1.0.0')),
      ]);
    });
  });
}
