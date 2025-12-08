import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:platform/platform.dart';
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/os/os.dart';
import 'package:quicui_aot_cli/src/platform.dart';
import 'package:quicui_aot_cli/src/quicui_process.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group(OperatingSystemInterface, () {
    late Platform platform;
    late QuicuiProcess process;
    late QuicuiProcessResult processResult;
    late OperatingSystemInterface osInterface;

    R runWithOverrides<R>(R Function() body) {
      return runScoped(
        () => body(),
        values: {
          platformRef.overrideWith(() => platform),
          processRef.overrideWith(() => process),
        },
      );
    }

    setUp(() {
      platform = MockPlatform();
      process = MockQuicuiProcess();
      processResult = MockProcessResult();

      when(() => platform.isLinux).thenReturn(false);
      when(() => platform.isMacOS).thenReturn(false);
      when(() => platform.isWindows).thenReturn(false);

      when(() => process.runSync(any(), any())).thenReturn(processResult);
      when(() => processResult.exitCode).thenReturn(ExitCode.success.code);
    });

    group('init', () {
      test(
        'throws UnsupportedError when operating system is not supported',
        () {
          expect(
            () => runWithOverrides(OperatingSystemInterface.new),
            throwsUnsupportedError,
          );
        },
      );
    });

    group('on macOS/Linux', () {
      setUp(() {
        when(() => platform.isMacOS).thenReturn(true);

        osInterface = runWithOverrides(OperatingSystemInterface.new);
      });

      group('which()', () {
        group('when no executable is found on PATH', () {
          setUp(() {
            when(() => processResult.exitCode).thenReturn(1);
          });

          test('returns null', () {
            expect(
              runWithOverrides(() => osInterface.which('quicui')),
              isNull,
            );
          });
        });

        group('when executable is found on PATH', () {
          const quicuiPath = '/path/to/quicui';
          setUp(() {
            when(() => processResult.stdout).thenReturn(quicuiPath);
          });

          test('returns path to executable', () {
            expect(
              runWithOverrides(() => osInterface.which('quicui')),
              quicuiPath,
            );
          });
        });

        group('when executable contains leading and trailing newlines', () {
          const quicuiPath = '''


/path/to/quicui

''';
          setUp(() {
            when(() => processResult.stdout).thenReturn(quicuiPath);
          });

          test('returns trimmed path to binary', () {
            expect(
              runWithOverrides(() => osInterface.which('quicui')),
              equals('/path/to/quicui'),
            );
          });
        });
      });
    });

    group('on Windows', () {
      setUp(() {
        when(() => platform.isWindows).thenReturn(true);
        osInterface = runWithOverrides(OperatingSystemInterface.new);
      });

      group('which()', () {
        group('when no executable is found on PATH', () {
          setUp(() {
            when(() => processResult.exitCode).thenReturn(1);
          });

          test('returns null', () {
            expect(
              runWithOverrides(() => osInterface.which('quicui')),
              isNull,
            );
          });
        });

        group('when executable is found on PATH', () {
          const quicuiPath = r'C:\path\to\quicui';
          setUp(() {
            when(() => processResult.stdout).thenReturn(quicuiPath);
          });

          test('returns path to executable', () {
            expect(
              runWithOverrides(() => osInterface.which('quicui')),
              quicuiPath,
            );
          });
        });

        group('when multiple executables are found on PATH', () {
          const quicuiPath = r'C:\path\to\quicui';
          const quicuiPaths = [
            r'C:\path\to\quicui',
            r'C:\path\to\quicui1',
            r'C:\path\to\quicui2',
            r'C:\path\to\quicui3',
          ];

          setUp(() {
            when(
              () => processResult.stdout,
            ).thenReturn(quicuiPaths.join('\r\n'));
          });

          test('returns first path to executable', () {
            expect(
              runWithOverrides(() => osInterface.which('quicui')),
              quicuiPath,
            );
          });
        });
      });
    });
  });
}
