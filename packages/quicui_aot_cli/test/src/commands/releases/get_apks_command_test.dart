import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:args/args.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/artifact_manager.dart';
import 'package:quicui_aot_cli/src/code_push_client_wrapper.dart';
import 'package:quicui_aot_cli/src/commands/releases/releases.dart';
import 'package:quicui_aot_cli/src/config/config.dart';
import 'package:quicui_aot_cli/src/executables/bundletool.dart';
import 'package:quicui_aot_cli/src/logging/quicui_logger.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:quicui_aot_cli/src/quicui_validator.dart';
import 'package:quicui_aot_cli/src/third_party/flutter_tools/lib/flutter_tools.dart';
import 'package:quicui_aot_code_push_client/quicui_aot_code_push_client.dart';
import 'package:test/test.dart';

import '../../mocks.dart';

void main() {
  group(GetApksCommand, () {
    const appId = 'test-app-id';
    const releaseId = 123;
    const releaseVersion = '1.2.3';
    const releaseArtifactUrl = 'https://example.com/release.aab';
    const apkFileName = '${appId}_$releaseVersion.apk';

    late ArgResults argResults;
    late ArtifactManager artifactManager;
    late Bundletool bundletool;
    late CodePushClientWrapper codePushClientWrapper;
    late Progress progress;
    late Directory projectRoot;
    late Release release;
    late ReleaseArtifact releaseArtifact;
    late QuicuiEnv quicuiEnv;
    late QuicuiLogger logger;
    late QuicuiValidator quicuiValidator;
    late QuicuiYaml quicuiYaml;

    late GetApksCommand command;

    R runWithOverrides<R>(R Function() body) {
      return runScoped(
        body,
        values: {
          artifactManagerRef.overrideWith(() => artifactManager),
          bundletoolRef.overrideWith(() => bundletool),
          codePushClientWrapperRef.overrideWith(() => codePushClientWrapper),
          loggerRef.overrideWith(() => logger),
          quicuiEnvRef.overrideWith(() => quicuiEnv),
          quicuiValidatorRef.overrideWith(() => quicuiValidator),
        },
      );
    }

    /// Creates a zip file containing an apk file with the apks extension
    Future<File> createTempApksFile() async {
      final tempDir = Directory.systemTemp.createTempSync();
      final apksDir = Directory(p.join(tempDir.path, 'temp.apks'))
        ..createSync(recursive: true);
      final apksFile = File(p.join(tempDir.path, 'test.apks'));

      // Write an "apk" to zip
      File(p.join(apksDir.path, apkFileName))
        ..createSync(recursive: true)
        ..writeAsStringSync('hello');
      await ZipFileEncoder().zipDirectory(apksDir, filename: apksFile.path);
      return apksFile;
    }

    setUpAll(() {
      registerFallbackValue(Uri());
    });

    setUp(() {
      argResults = MockArgResults();
      artifactManager = MockArtifactManager();
      bundletool = MockBundleTool();
      codePushClientWrapper = MockCodePushClientWrapper();
      logger = MockQuicuiLogger();
      progress = MockProgress();
      projectRoot = Directory.systemTemp.createTempSync();
      release = MockRelease();
      releaseArtifact = MockReleaseArtifact();
      quicuiEnv = MockQuicuiEnv();
      quicuiValidator = MockQuicuiValidator();
      quicuiYaml = MockQuicuiYaml();

      when(() => argResults.wasParsed(any())).thenReturn(false);
      when(() => argResults['universal']).thenReturn(true);
      when(() => argResults.rest).thenReturn([]);

      when(
        () => artifactManager.downloadWithProgressUpdates(
          any(),
          message: any(named: 'message'),
        ),
      ).thenAnswer((_) async => File(''));

      when(
        () => bundletool.buildApks(
          bundle: any(named: 'bundle'),
          output: any(named: 'output'),
          universal: any(named: 'universal'),
        ),
      ).thenAnswer((invocation) async {
        final apksFile = await createTempApksFile();
        final outputPath = invocation.namedArguments[#output] as String;
        apksFile.renameSync(outputPath);
      });

      when(
        () => codePushClientWrapper.getRelease(
          appId: any(named: 'appId'),
          releaseVersion: any(named: 'releaseVersion'),
        ),
      ).thenAnswer((_) async => release);
      when(
        () => codePushClientWrapper.getReleases(
          appId: any(named: 'appId'),
          sideloadableOnly: any(named: 'sideloadableOnly'),
        ),
      ).thenAnswer((_) async => [release]);
      when(
        () => codePushClientWrapper.getReleaseArtifact(
          appId: any(named: 'appId'),
          releaseId: any(named: 'releaseId'),
          arch: any(named: 'arch'),
          platform: ReleasePlatform.android,
        ),
      ).thenAnswer((_) async => releaseArtifact);

      when(
        () => logger.chooseOne<Release>(
          any(),
          choices: any(named: 'choices'),
          display: any(named: 'display'),
        ),
      ).thenReturn(release);
      when(() => logger.progress(any())).thenReturn(progress);

      when(() => release.id).thenReturn(releaseId);
      when(() => release.version).thenReturn(releaseVersion);

      when(() => releaseArtifact.url).thenReturn(releaseArtifactUrl);

      when(
        () => quicuiEnv.getQuicuiProjectRoot(),
      ).thenReturn(projectRoot);
      when(() => quicuiEnv.getQuicuiYaml()).thenReturn(quicuiYaml);

      when(
        () => quicuiValidator.validatePreconditions(
          checkUserIsAuthenticated: any(named: 'checkUserIsAuthenticated'),
          checkQuicuiInitialized: any(named: 'checkQuicuiInitialized'),
        ),
      ).thenAnswer((_) async => {});

      when(() => quicuiYaml.appId).thenReturn(appId);

      command = GetApksCommand()..testArgResults = argResults;
    });

    test('has a description', () {
      expect(command.description, isNotEmpty);
    });

    group('when validation fails', () {
      final exception = ValidationFailedException();
      setUp(() {
        when(
          () => quicuiValidator.validatePreconditions(
            checkUserIsAuthenticated: any(named: 'checkUserIsAuthenticated'),
            checkQuicuiInitialized: any(named: 'checkQuicuiInitialized'),
          ),
        ).thenThrow(exception);
      });

      test('exits with exit code from validation error', () async {
        await expectLater(
          runWithOverrides(command.run),
          completion(equals(exception.exitCode.code)),
        );
        verify(
          () => quicuiValidator.validatePreconditions(
            checkUserIsAuthenticated: true,
            checkQuicuiInitialized: true,
          ),
        ).called(1);
      });
    });

    group('when querying for releases fails', () {
      setUp(() {
        when(
          () => codePushClientWrapper.getReleases(
            appId: any(named: 'appId'),
            sideloadableOnly: any(named: 'sideloadableOnly'),
          ),
        ).thenThrow(ProcessExit(ExitCode.software.code));
      });

      test('exits with code 70', () async {
        await expectLater(
          () => runWithOverrides(command.run),
          throwsA(
            isA<ProcessExit>().having(
              (e) => e.exitCode,
              'exitCode',
              ExitCode.software.code,
            ),
          ),
        );
        verify(
          () => codePushClientWrapper.getReleases(
            appId: appId,
            sideloadableOnly: true,
          ),
        ).called(1);
      });
    });

    group('when downloading aab fails', () {
      final exception = Exception('oops');

      setUp(() {
        when(
          () => artifactManager.downloadWithProgressUpdates(
            any(),
            message: any(named: 'message'),
          ),
        ).thenThrow(exception);
      });

      test('exits with code 70', () async {
        await expectLater(
          () => runWithOverrides(command.run),
          throwsA(
            isA<ProcessExit>().having(
              (e) => e.exitCode,
              'exitCode',
              ExitCode.software.code,
            ),
          ),
        );
      });
    });

    group('when app does not have any releases', () {
      setUp(() {
        when(
          () => codePushClientWrapper.getReleases(
            appId: appId,
            sideloadableOnly: any(named: 'sideloadableOnly'),
          ),
        ).thenAnswer((_) async => []);
      });

      test('exits with code 70', () async {
        await expectLater(
          () => runWithOverrides(command.run),
          throwsA(
            isA<ProcessExit>().having(
              (e) => e.exitCode,
              'exitCode',
              ExitCode.usage.code,
            ),
          ),
        );
        verify(
          () => codePushClientWrapper.getReleases(
            appId: appId,
            sideloadableOnly: true,
          ),
        ).called(1);
        verify(() => logger.err('No releases found for app $appId')).called(1);
      });
    });

    group('when release version is not specified', () {
      setUp(() {
        when(() => argResults.wasParsed('release-version')).thenReturn(false);
      });

      test('prompts for release', () async {
        await runWithOverrides(command.run);

        final capturedDisplay =
            verify(
                  () => logger.chooseOne<Release>(
                    any(),
                    choices: any(named: 'choices'),
                    display: captureAny(named: 'display'),
                  ),
                ).captured.single
                as String Function(Release);

        expect(capturedDisplay(release), equals(releaseVersion));
      });
    });

    group('when release version is specified', () {
      const releaseVersionArg = '1.2.3';

      setUp(() {
        when(() => argResults['release-version']).thenReturn(releaseVersionArg);
        when(() => argResults.wasParsed('release-version')).thenReturn(true);
      });

      test('queries for release with specified version', () async {
        await runWithOverrides(command.run);

        verify(
          () => codePushClientWrapper.getRelease(
            appId: appId,
            releaseVersion: releaseVersionArg,
          ),
        ).called(1);
      });

      test('does not prompt for release', () async {
        await runWithOverrides(command.run);

        verifyNever(
          () => logger.chooseOne<Release>(
            any(),
            choices: any(named: 'choices'),
            display: any(named: 'display'),
          ),
        );
      });
    });

    group('when buildApk fails', () {
      final exception = Exception('oops');

      setUp(() {
        when(
          () => bundletool.buildApks(
            bundle: any(named: 'bundle'),
            output: any(named: 'output'),
            universal: any(named: 'universal'),
          ),
        ).thenThrow(exception);
      });

      test('exits with code 70', () async {
        await expectLater(
          runWithOverrides(command.run),
          completion(ExitCode.software.code),
        );
        verify(() => progress.fail('$exception')).called(1);
      });
    });

    group('when output directory is specified', () {
      late Directory outDirectory;

      setUp(() {
        outDirectory = Directory.systemTemp.createTempSync();
        // Delete to ensure the command creates the directory if needed
        // ignore: cascade_invocations
        outDirectory.deleteSync();
        when(() => argResults['out']).thenReturn(outDirectory.path);
        when(() => argResults.wasParsed('out')).thenReturn(true);
      });

      test('creates apk in specified directory', () async {
        await expectLater(
          runWithOverrides(command.run),
          completion(ExitCode.success.code),
        );
        final expectedMessage =
            '''apk(s) generated at ${lightCyan.wrap(outDirectory.path)}''';
        verify(() => logger.info(expectedMessage)).called(1);
      });
    });

    group('when no output directory is specified', () {
      test('creates apk in project build subdirectory', () async {
        await expectLater(
          runWithOverrides(command.run),
          completion(ExitCode.success.code),
        );

        final apkPath = p.join(
          projectRoot.path,
          'build',
          'app',
          'outputs',
          'quicui-apk',
        );
        final expectedMessage =
            'apk(s) generated at ${lightCyan.wrap(apkPath)}';
        verify(() => logger.info(expectedMessage)).called(1);
      });
    });

    group('when user passes --no-universal', () {
      setUp(() {
        when(() => argResults['universal']).thenReturn(false);
      });

      test('builds apks without universal flag', () async {
        await runWithOverrides(command.run);

        verify(
          () => bundletool.buildApks(
            bundle: any(named: 'bundle'),
            output: any(named: 'output'),
            universal: false,
          ),
        ).called(1);
      });
    });

    group('when apks extraction fails', () {
      late Directory outDirectory;
      late String apksFilePath;

      setUp(() {
        outDirectory = Directory.systemTemp.createTempSync();
        // Delete to ensure the command creates the directory if needed
        // ignore: cascade_invocations
        outDirectory.deleteSync();
        when(() => argResults['out']).thenReturn(outDirectory.path);
        when(() => argResults.wasParsed('out')).thenReturn(true);

        Future<File> createEmptyTempApksFile() async {
          final tempDir = Directory.systemTemp.createTempSync();
          final apksDir = Directory(p.join(tempDir.path, 'temp.apks'))
            ..createSync(recursive: true);
          final apksFile = File(p.join(tempDir.path, 'test.apks'));
          await ZipFileEncoder().zipDirectory(apksDir, filename: apksFile.path);
          return apksFile;
        }

        when(
          () => bundletool.buildApks(
            bundle: any(named: 'bundle'),
            output: any(named: 'output'),
            universal: any(named: 'universal'),
          ),
        ).thenAnswer((invocation) async {
          final apksFile = await createEmptyTempApksFile();
          final outputPath = invocation.namedArguments[#output] as String;
          apksFilePath = outputPath;
          apksFile.renameSync(outputPath);
        });
      });

      // Working around a package:archive bug where it silently fails when
      // extracting the apks zip, leaving an empty directory.
      test('apks zip is empty', () async {
        await expectLater(
          runWithOverrides(command.run),
          completion(ExitCode.software.code),
        );
        final expectedMessage =
            'Failed to extract apks from $apksFilePath.zip '
            'to ${outDirectory.path}';
        verify(() => logger.err(expectedMessage)).called(1);
      });
    });
  });
}
