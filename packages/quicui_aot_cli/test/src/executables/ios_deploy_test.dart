import 'dart:async';
import 'dart:convert';
import 'dart:io' hide Platform;

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:platform/platform.dart';
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/executables/executables.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/platform.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:quicui_aot_cli/src/quicui_process.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group(IOSDeploy, () {
    late QuicuiLogger logger;
    late Platform platform;
    late Progress progress;
    late QuicuiProcess quicuiProcess;
    late Process process;
    late IOSink ioSink;
    late QuicuiEnv quicuiEnv;
    late IOSDeploy iosDeploy;

    R runWithOverrides<R>(R Function() body) {
      return runScoped(
        body,
        values: {
          loggerRef.overrideWith(() => logger),
          platformRef.overrideWith(() => platform),
          processRef.overrideWith(() => quicuiProcess),
          quicuiEnvRef.overrideWith(() => quicuiEnv),
        },
      );
    }

    setUp(() {
      logger = MockQuicuiLogger();
      platform = MockPlatform();
      quicuiProcess = MockQuicuiProcess();
      process = MockProcess();
      progress = MockProgress();
      ioSink = MockIOSink();
      quicuiEnv = MockQuicuiEnv();
      iosDeploy = const IOSDeploy();

      final tempDir = Directory.systemTemp.createTempSync();

      when(() => quicuiEnv.quicuiRoot).thenReturn(tempDir);
      when(
        () => quicuiEnv.flutterDirectory,
      ).thenReturn(Directory(p.join(tempDir.path, 'bin', 'cache', 'flutter')));
      when(() => logger.progress(any())).thenReturn(progress);
      when(
        () => quicuiProcess.start(any(), any()),
      ).thenAnswer((_) async => process);
      when(() => process.stdout).thenAnswer((_) => const Stream.empty());
      when(() => process.stderr).thenAnswer((_) => const Stream.empty());
      when(() => process.stdin).thenReturn(ioSink);
      when(
        () => process.exitCode,
      ).thenAnswer((_) async => ExitCode.success.code);
      when(() => process.kill()).thenReturn(true);
    });

    group('installAndLaunchApp', () {
      setUp(() {
        runWithOverrides(
          () => IOSDeploy.iosDeployExecutable.createSync(recursive: true),
        );
      });

      test('executes correct command when deviceId is provided', () async {
        when(() => process.stdout).thenAnswer((_) => const Stream.empty());
        when(
          () => quicuiProcess.start(any(), any()),
        ).thenAnswer((_) async => process);
        const bundlePath = 'test-bundle-path';
        const deviceId = 'test-device-id';
        await runWithOverrides(
          () => iosDeploy.installAndLaunchApp(
            bundlePath: bundlePath,
            deviceId: deviceId,
          ),
        );
        verify(
          () => quicuiProcess.start(any(that: endsWith('ios-deploy')), [
            '--debug',
            '--id',
            deviceId,
            '-r',
            '--bundle',
            bundlePath,
          ]),
        ).called(1);
      });

      test('executes correct command when deviceId is not provided', () async {
        when(() => process.stdout).thenAnswer((_) => const Stream.empty());
        when(
          () => quicuiProcess.start(any(), any()),
        ).thenAnswer((_) async => process);
        const bundlePath = 'test-bundle-path';
        await runWithOverrides(
          () => iosDeploy.installAndLaunchApp(bundlePath: bundlePath),
        );
        verify(
          () => quicuiProcess.start(any(that: endsWith('ios-deploy')), [
            '--debug',
            '-r',
            '--bundle',
            bundlePath,
          ]),
        ).called(1);
      });

      test('exits with code 70 on process exception', () async {
        final exception = Exception('oops');
        when(() => quicuiProcess.start(any(), any())).thenThrow(exception);
        const bundlePath = 'test-bundle-path';
        final exitCode = await runWithOverrides(
          () => iosDeploy.installAndLaunchApp(bundlePath: bundlePath),
        );
        expect(exitCode, equals(ExitCode.software.code));
        verify(
          () => quicuiProcess.start(any(that: endsWith('ios-deploy')), [
            '--debug',
            '-r',
            '--bundle',
            bundlePath,
          ]),
        ).called(1);
        verify(() => logger.err('[ios-deploy] failed: $exception')).called(1);
      });

      test('dumps backtrace on process stopped', () async {
        final completer = Completer<int>();
        when(
          () => process.stdout,
        ).thenAnswer((_) => Stream.value(utf8.encode('PROCESS_STOPPED')));
        when(() => process.exitCode).thenAnswer((_) => completer.future);
        const bundlePath = 'test-bundle-path';
        final exitCode = runWithOverrides(
          () => iosDeploy.installAndLaunchApp(bundlePath: bundlePath),
        );
        await untilCalled(() => ioSink.writeln('thread backtrace all'));
        completer.complete(ExitCode.software.code);
        await expectLater(exitCode, completion(equals(ExitCode.software.code)));
        verify(
          () => quicuiProcess.start(any(that: endsWith('ios-deploy')), [
            '--debug',
            '-r',
            '--bundle',
            bundlePath,
          ]),
        ).called(1);
      });

      test('detaches on process stopped', () async {
        final completer = Completer<int>();
        when(() => process.stdout).thenAnswer(
          (_) =>
              File('test/fixtures/ios-deploy/process_stopped.txt').openRead(),
        );
        when(() => process.exitCode).thenAnswer((_) => completer.future);
        const bundlePath = 'test-bundle-path';
        final exitCode = runWithOverrides(
          () => iosDeploy.installAndLaunchApp(bundlePath: bundlePath),
        );
        await untilCalled(() => ioSink.writeln('thread backtrace all'));
        await untilCalled(() => ioSink.writeln('process detach'));
        completer.complete(ExitCode.software.code);
        await expectLater(exitCode, completion(equals(ExitCode.software.code)));
        verify(
          () => quicuiProcess.start(any(that: endsWith('ios-deploy')), [
            '--debug',
            '-r',
            '--bundle',
            bundlePath,
          ]),
        ).called(1);
      });

      test('kills process on process exited', () async {
        final completer = Completer<int>();
        when(() => process.stdout).thenAnswer(
          (_) => File('test/fixtures/ios-deploy/process_exited.txt').openRead(),
        );
        when(() => process.exitCode).thenAnswer((_) => completer.future);
        const bundlePath = 'test-bundle-path';
        final exitCode = runWithOverrides(
          () => iosDeploy.installAndLaunchApp(bundlePath: bundlePath),
        );
        await untilCalled(() => process.kill());
        completer.complete(ExitCode.software.code);
        await expectLater(exitCode, completion(equals(ExitCode.software.code)));
        verify(
          () => quicuiProcess.start(any(that: endsWith('ios-deploy')), [
            '--debug',
            '-r',
            '--bundle',
            bundlePath,
          ]),
        ).called(1);
      });

      test('kills process on process detached', () async {
        final completer = Completer<int>();
        when(() => process.stdout).thenAnswer(
          (_) =>
              File('test/fixtures/ios-deploy/process_detached.txt').openRead(),
        );
        when(() => process.exitCode).thenAnswer((_) => completer.future);
        const bundlePath = 'test-bundle-path';
        final exitCode = runWithOverrides(
          () => iosDeploy.installAndLaunchApp(bundlePath: bundlePath),
        );
        await untilCalled(() => process.kill());
        completer.complete(ExitCode.software.code);
        await expectLater(exitCode, completion(equals(ExitCode.software.code)));
        verify(
          () => quicuiProcess.start(any(that: endsWith('ios-deploy')), [
            '--debug',
            '-r',
            '--bundle',
            bundlePath,
          ]),
        ).called(1);
      });

      test('handles process resuming', () async {
        final completer = Completer<int>();
        when(() => process.stdout).thenAnswer(
          (_) =>
              File('test/fixtures/ios-deploy/process_resuming.txt').openRead(),
        );
        when(() => process.exitCode).thenAnswer((_) => completer.future);
        const bundlePath = 'test-bundle-path';
        final exitCode = runWithOverrides(
          () => iosDeploy.installAndLaunchApp(bundlePath: bundlePath),
        );
        await untilCalled(() => progress.complete('Started app'));
        completer.complete(ExitCode.success.code);
        await expectLater(exitCode, completion(equals(ExitCode.success.code)));
        verify(
          () => quicuiProcess.start(any(that: endsWith('ios-deploy')), [
            '--debug',
            '-r',
            '--bundle',
            bundlePath,
          ]),
        ).called(1);

        // Removes leading [...] from lines that start with [...]
        verify(
          () => progress.update(
            """Using 82b15a4a69ad47c74fe3e71b62a6a6e2842efe25 (D22AP, iPhone X, iphoneos, arm64, 16.3.1, 20D67) a.k.a. 'Felix’s iPhone'.""",
          ),
        ).called(1);

        // Does not remove leading [  x%] from lines that start with [  x%]
        verify(
          () => progress.update(
            '''[  7%] Copying /Users/felix/Development/github.com/quicuitech/_quicui/quicui/bin/cache/previews/b3be02c7-97a8-4135-be71-814cc43d096e/ios_1.0.4+7.app/Base.lproj/Main.storyboardc/BYZ-38-t0r-view-8bC-Xf-vdC.nib to device''',
          ),
        ).called(1);
      });

      test('kills process on sigint', () async {
        final signal = MockProcessSignal();
        final controller = StreamController<ProcessSignal>();
        iosDeploy = IOSDeploy(sigint: signal);
        when(signal.watch).thenAnswer((_) => controller.stream);
        final completer = Completer<int>();
        when(() => process.stdout).thenAnswer(
          (_) => File('test/fixtures/ios-deploy/success.txt').openRead(),
        );
        when(() => process.exitCode).thenAnswer((_) => completer.future);
        const bundlePath = 'test-bundle-path';
        final exitCode = runWithOverrides(
          () => iosDeploy.installAndLaunchApp(bundlePath: bundlePath),
        );
        await untilCalled(() => progress.complete('Started app'));
        controller.add(ProcessSignal.sigint);
        await untilCalled(() => process.kill());
        completer.complete(ExitCode.success.code);
        await expectLater(exitCode, completion(equals(ExitCode.success.code)));
        verify(
          () => quicuiProcess.start(any(that: endsWith('ios-deploy')), [
            '--debug',
            '-r',
            '--bundle',
            bundlePath,
          ]),
        ).called(1);
      });

      test('handles process stderr', () async {
        const message = 'test-stderr';
        final completer = Completer<int>();
        when(
          () => process.stderr,
        ).thenAnswer((_) => Stream.value(utf8.encode(message)));
        when(() => process.exitCode).thenAnswer((_) => completer.future);
        const bundlePath = 'test-bundle-path';
        final exitCode = runWithOverrides(
          () => iosDeploy.installAndLaunchApp(bundlePath: bundlePath),
        );
        await untilCalled(() => logger.detail(message));
        completer.complete(ExitCode.software.code);
        await expectLater(exitCode, completion(equals(ExitCode.software.code)));
        verify(
          () => quicuiProcess.start(any(that: endsWith('ios-deploy')), [
            '--debug',
            '-r',
            '--bundle',
            bundlePath,
          ]),
        ).called(1);
      });

      test('exits with code 0 on success', () async {
        final completer = Completer<int>();
        when(() => process.stdout).thenAnswer(
          (_) => File('test/fixtures/ios-deploy/success.txt').openRead(),
        );
        when(() => process.exitCode).thenAnswer((_) => completer.future);
        const bundlePath = 'test-bundle-path';
        final exitCode = runWithOverrides(
          () => iosDeploy.installAndLaunchApp(bundlePath: bundlePath),
        );
        await untilCalled(() => progress.complete('Started app'));
        completer.complete(ExitCode.success.code);
        await expectLater(exitCode, completion(equals(ExitCode.success.code)));
        verify(
          () => quicuiProcess.start(any(that: endsWith('ios-deploy')), [
            '--debug',
            '-r',
            '--bundle',
            bundlePath,
          ]),
        ).called(1);
      });
    });

    group('detectFailures', () {
      test('handles no provisioning profile error (1)', () {
        const line = IOSDeploy.noProvisioningProfileErrorOne;
        final result = detectFailures(line, logger);
        expect(result, equals(line));
        verify(
          () => logger.err(IOSDeploy.noProvisioningProfileInstructions),
        ).called(1);
      });

      test('handles no provisioning profile error (2)', () {
        const line = IOSDeploy.noProvisioningProfileErrorTwo;
        final result = detectFailures(line, logger);
        expect(result, equals(line));
        verify(
          () => logger.err(IOSDeploy.noProvisioningProfileInstructions),
        ).called(1);
      });

      test('handles device locked', () {
        const line = IOSDeploy.deviceLockedError;
        final result = detectFailures(line, logger);
        expect(result, equals(line));
        verify(
          () => logger.err(IOSDeploy.deviceLockedFixInstructions),
        ).called(1);
      });

      test('handles unknown error', () {
        const line = IOSDeploy.unknownAppLaunchError;
        final result = detectFailures(line, logger);
        expect(result, equals(line));
        verify(
          () => logger.err(IOSDeploy.unknownErrorFixInstructions),
        ).called(1);
      });

      test('always returns original line', () {
        const line = 'test-line';
        final result = detectFailures(line, logger);
        expect(result, equals(line));
        verifyNever(() => logger.err(any()));
      });
    });

    group('installIfNeeded', () {
      test('does nothing if ios-deploy is already installed', () async {
        runWithOverrides(
          () => IOSDeploy.iosDeployExecutable.createSync(recursive: true),
        );
        await expectLater(
          runWithOverrides(() async => iosDeploy.installIfNeeded()),
          completes,
        );

        verifyNever(() => quicuiProcess.run(any(), any()));
      });

      test('throws ProcessException if flutter precache fails', () async {
        when(() => quicuiProcess.run(any(), any())).thenAnswer(
          (_) async => QuicuiProcessResult(
            exitCode: ExitCode.software.code,
            stdout: null,
            stderr: 'oh no',
          ),
        );

        await expectLater(
          runWithOverrides(iosDeploy.installIfNeeded),
          throwsA(isA<ProcessException>()),
        );
      });

      test(
        '''throws Exception if ios-deploy is not installed after running flutter precache''',
        () async {
          when(() => quicuiProcess.run(any(), any())).thenAnswer(
            (_) async => QuicuiProcessResult(
              exitCode: ExitCode.success.code,
              stdout: null,
              stderr: null,
            ),
          );
          await expectLater(
            runWithOverrides(iosDeploy.installIfNeeded),
            throwsA(isA<Exception>()),
          );
        },
      );

      test(
        '''completes successfully if ios-deploy is installed after running flutter precache''',
        () async {
          when(() => quicuiProcess.run(any(), any())).thenAnswer((_) async {
            runWithOverrides(
              () => IOSDeploy.iosDeployExecutable.createSync(recursive: true),
            );
            return QuicuiProcessResult(
              exitCode: ExitCode.success.code,
              stdout: null,
              stderr: null,
            );
          });
          await expectLater(
            runWithOverrides(() async => iosDeploy.installIfNeeded()),
            completes,
          );

          verify(
            () => quicuiProcess.run('flutter', ['precache', '--ios']),
          ).called(1);
          verify(progress.complete).called(1);
        },
      );
    });
  });
}
