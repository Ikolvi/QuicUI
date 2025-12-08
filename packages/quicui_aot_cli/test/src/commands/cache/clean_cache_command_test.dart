import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:platform/platform.dart';
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/cache.dart';
import 'package:quicui_aot_cli/src/commands/commands.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/platform.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:test/test.dart';

import '../../mocks.dart';

void main() {
  group('cache clean', () {
    late Cache cache;
    late QuicuiLogger logger;
    late Platform platform;
    late Progress progress;
    late QuicuiEnv quicuiEnv;
    late CleanCacheCommand command;

    R runWithOverrides<R>(R Function() body) {
      return runScoped(
        body,
        values: {
          cacheRef.overrideWith(() => cache),
          loggerRef.overrideWith(() => logger),
          platformRef.overrideWith(() => platform),
          quicuiEnvRef.overrideWith(() => quicuiEnv),
        },
      );
    }

    setUp(() {
      cache = MockCache();
      logger = MockQuicuiLogger();
      platform = MockPlatform();
      progress = MockProgress();
      quicuiEnv = MockQuicuiEnv();
      command = runWithOverrides(CleanCacheCommand.new);

      when(() => logger.progress(any())).thenReturn(progress);
      when(
        () => quicuiEnv.quicuiRoot,
      ).thenReturn(Directory.systemTemp.createTempSync());
    });

    test('has a non-empty description', () {
      expect(command.description, isNotEmpty);
    });

    test('clears the cache', () async {
      when(cache.clear).thenAnswer((_) async {});
      final result = await runWithOverrides(command.run);
      expect(result, equals(ExitCode.success.code));
      verify(() => progress.complete('Cleared cache')).called(1);
      verify(cache.clear).called(1);
    });

    group('on failure', () {
      group('on Windows', () {
        setUp(() {
          when(() => platform.isWindows).thenReturn(true);
        });

        test(
          'tells the user how to find the issue and exits with code 70',
          () async {
            when(
              () => cache.clear(),
            ).thenThrow(const FileSystemException('Failed to delete'));

            final result = await runWithOverrides(command.run);

            expect(result, equals(ExitCode.software.code));
            verify(() => progress.fail(any())).called(1);
            verify(
              () => logger.info(
                any(
                  that: stringContainsInOrder([
                    '''This could be because a program is using a file in the cache directory. To find and stop such a program, see''',
                    'https://superuser.com/questions/1333118/cant-delete-empty-folder-because-it-is-used',
                  ]),
                ),
              ),
            ).called(1);
          },
        );
      });

      group('on a non-Windows OS', () {
        setUp(() {
          when(() => platform.isWindows).thenReturn(false);
        });

        test('prints error message and exits with code 70', () async {
          when(
            () => cache.clear(),
          ).thenThrow(const FileSystemException('Failed to delete'));

          final result = await runWithOverrides(command.run);

          expect(result, equals(ExitCode.software.code));
          verify(() => progress.fail(any())).called(1);
          verifyNever(() => logger.info(any()));
        });
      });
    });
  });
}
