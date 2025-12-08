import 'dart:io';

import 'package:args/args.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:platform/platform.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/artifact_builder/artifact_builder.dart';
import 'package:quicui_aot_cli/src/artifact_manager.dart';
import 'package:quicui_aot_cli/src/code_push_client_wrapper.dart';
import 'package:quicui_aot_cli/src/code_signer.dart';
import 'package:quicui_aot_cli/src/commands/commands.dart';
import 'package:quicui_aot_cli/src/common_arguments.dart';
import 'package:quicui_aot_cli/src/doctor.dart';
import 'package:quicui_aot_cli/src/executables/executables.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/platform/platform.dart';
import 'package:quicui_aot_cli/src/release_type.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:quicui_aot_cli/src/quicui_flutter.dart';
import 'package:quicui_aot_cli/src/quicui_process.dart';
import 'package:quicui_aot_cli/src/quicui_validator.dart';
import 'package:quicui_aot_cli/src/validators/validators.dart';
import 'package:quicui_aot_code_push_client/quicui_aot_code_push_client.dart';
import 'package:test/test.dart';

import '../../matchers.dart';
import '../../mocks.dart';

void main() {
  group(WindowsReleaser, () {
    late ArgResults argResults;
    late ArtifactBuilder artifactBuilder;
    late ArtifactManager artifactManager;
    late CodePushClientWrapper codePushClientWrapper;
    late CodeSigner codeSigner;
    late Directory releaseDirectory;
    late Doctor doctor;
    late QuicuiLogger logger;
    late FlavorValidator flavorValidator;
    late Directory projectRoot;
    late Powershell powershell;
    late Progress progress;
    late QuicuiProcess quicuiProcess;
    late QuicuiEnv quicuiEnv;
    late QuicuiFlutter quicuiFlutter;
    late QuicuiValidator quicuiValidator;
    late Windows windows;
    late WindowsReleaser releaser;

    R runWithOverrides<R>(R Function() body) {
      return runScoped(
        body,
        values: {
          artifactBuilderRef.overrideWith(() => artifactBuilder),
          artifactManagerRef.overrideWith(() => artifactManager),
          codePushClientWrapperRef.overrideWith(() => codePushClientWrapper),
          codeSignerRef.overrideWith(() => codeSigner),
          doctorRef.overrideWith(() => doctor),
          loggerRef.overrideWith(() => logger),
          powershellRef.overrideWith(() => powershell),
          processRef.overrideWith(() => quicuiProcess),
          quicuiEnvRef.overrideWith(() => quicuiEnv),
          quicuiFlutterRef.overrideWith(() => quicuiFlutter),
          quicuiValidatorRef.overrideWith(() => quicuiValidator),
          windowsRef.overrideWith(() => windows),
        },
      );
    }

    setUpAll(() {
      registerFallbackValue(Directory(''));
      registerFallbackValue(File(''));
      registerFallbackValue(ReleasePlatform.windows);
    });

    setUp(() {
      argResults = MockArgResults();
      artifactBuilder = MockArtifactBuilder();
      artifactManager = MockArtifactManager();
      codePushClientWrapper = MockCodePushClientWrapper();
      codeSigner = MockCodeSigner();
      doctor = MockDoctor();
      flavorValidator = MockFlavorValidator();
      powershell = MockPowershell();
      progress = MockProgress();
      projectRoot = Directory.systemTemp.createTempSync();
      logger = MockQuicuiLogger();
      quicuiProcess = MockQuicuiProcess();
      quicuiEnv = MockQuicuiEnv();
      quicuiFlutter = MockQuicuiFlutter();
      quicuiValidator = MockQuicuiValidator();
      windows = MockWindows();

      when(() => argResults.rest).thenReturn([]);
      when(() => argResults.wasParsed(any())).thenReturn(false);
      when(() => argResults['flutter-version']).thenReturn('latest');

      releaseDirectory = Directory(
        p.join(
          projectRoot.path,
          'build',
          'windows',
          'x64',
          'runner',
          'Release',
        ),
      )..createSync(recursive: true);

      when(
        () => artifactManager.getWindowsReleaseDirectory(),
      ).thenReturn(releaseDirectory);

      when(() => logger.progress(any())).thenReturn(progress);

      when(
        () => quicuiEnv.getQuicuiProjectRoot(),
      ).thenReturn(projectRoot);

      releaser = WindowsReleaser(
        argResults: argResults,
        flavor: null,
        target: null,
      );
    });

    group('releaseType', () {
      test('is windows', () {
        expect(releaser.releaseType, ReleaseType.windows);
      });
    });

    group('minimumFlutterVersion', () {
      test('is 3.32.6', () {
        expect(releaser.minimumFlutterVersion, Version(3, 32, 6));
      });
    });

    group('artifactDisplayName', () {
      test('has expected value', () {
        expect(releaser.artifactDisplayName, 'Windows app');
      });
    });

    group('assertArgsAreValid', () {
      group('when release-version is passed', () {
        setUp(() {
          when(() => argResults.wasParsed('release-version')).thenReturn(true);
        });

        test('logs error and exits with usage err', () async {
          await expectLater(
            () => runWithOverrides(releaser.assertArgsAreValid),
            exitsWithCode(ExitCode.usage),
          );

          verify(
            () => logger.err(
              '''
The "--release-version" flag is only supported for aar and ios-framework releases.
        
To change the version of this release, change your app's version in your pubspec.yaml.''',
            ),
          ).called(1);
        });
      });
    });

    group('assertPreconditions', () {
      setUp(() {
        when(
          () => doctor.windowsCommandValidators,
        ).thenReturn([flavorValidator]);
        when(flavorValidator.validate).thenAnswer((_) async => []);
      });

      group('when validation succeeds', () {
        setUp(() {
          when(
            () => quicuiValidator.validatePreconditions(
              checkUserIsAuthenticated: any(named: 'checkUserIsAuthenticated'),
              checkQuicuiInitialized: any(
                named: 'checkQuicuiInitialized',
              ),
              validators: any(named: 'validators'),
              supportedOperatingSystems: any(
                named: 'supportedOperatingSystems',
              ),
            ),
          ).thenAnswer((_) async {});
        });

        test('returns normally', () async {
          await expectLater(
            () => runWithOverrides(releaser.assertPreconditions),
            returnsNormally,
          );
        });
      });

      group('when validation fails', () {
        final exception = ValidationFailedException();

        setUp(() {
          when(
            () => quicuiValidator.validatePreconditions(
              checkUserIsAuthenticated: any(named: 'checkUserIsAuthenticated'),
              checkQuicuiInitialized: any(
                named: 'checkQuicuiInitialized',
              ),
              validators: any(named: 'validators'),
              supportedOperatingSystems: any(
                named: 'supportedOperatingSystems',
              ),
            ),
          ).thenThrow(exception);
        });

        test('exits with code 70', () async {
          await expectLater(
            () => runWithOverrides(releaser.assertPreconditions),
            exitsWithCode(exception.exitCode),
          );
          verify(
            () => quicuiValidator.validatePreconditions(
              checkUserIsAuthenticated: true,
              checkQuicuiInitialized: true,
              validators: [flavorValidator],
              supportedOperatingSystems: {Platform.windows},
            ),
          ).called(1);
        });
      });

      group('when flutter version is too old', () {
        setUp(() {
          when(
            () => quicuiValidator.validatePreconditions(
              checkUserIsAuthenticated: any(named: 'checkUserIsAuthenticated'),
              checkQuicuiInitialized: any(
                named: 'checkQuicuiInitialized',
              ),
              validators: any(named: 'validators'),
              supportedOperatingSystems: any(
                named: 'supportedOperatingSystems',
              ),
            ),
          ).thenAnswer((_) async {});
          when(
            () => argResults['flutter-version'] as String?,
          ).thenReturn('3.27.1');
          when(
            () => quicuiFlutter.resolveFlutterVersion('3.27.1'),
          ).thenAnswer((_) async => Version(3, 27, 1));
        });
      });
    });

    group('buildReleaseArtifacts', () {
      setUp(() {
        when(
          () => artifactBuilder.buildWindowsApp(
            target: any(named: 'target'),
            args: any(named: 'args'),
          ),
        ).thenAnswer((_) async => projectRoot);
      });

      test('returns path to release directory', () async {
        final releaseDir = await runWithOverrides(
          releaser.buildReleaseArtifacts,
        );
        expect(releaseDir, projectRoot);
      });

      group('when target and flavor are specified', () {
        const flavor = 'my-flavor';
        const target = 'my-target';

        setUp(() {
          releaser = WindowsReleaser(
            argResults: argResults,
            flavor: flavor,
            target: target,
          );
        });

        test('builds correct artifacts', () async {
          await runWithOverrides(releaser.buildReleaseArtifacts);
          verify(
            () => artifactBuilder.buildWindowsApp(target: target, args: []),
          ).called(1);
        });
      });

      group('when public key is passed as an arg', () {
        setUp(() {
          when(
            () => artifactBuilder.buildWindowsApp(
              target: any(named: 'target'),
              args: any(named: 'args'),
              base64PublicKey: any(named: 'base64PublicKey'),
            ),
          ).thenAnswer((_) async => projectRoot);
          when(
            () => argResults.wasParsed(CommonArguments.publicKeyArg.name),
          ).thenReturn(true);
          when(
            () => argResults[CommonArguments.publicKeyArg.name],
          ).thenReturn('public_key');
          when(
            () => codeSigner.base64PublicKey(any()),
          ).thenReturn('encoded_public_key');
        });

        test('passes public key to buildWindowsApp', () async {
          await runWithOverrides(releaser.buildReleaseArtifacts);
          verify(
            () => artifactBuilder.buildWindowsApp(
              base64PublicKey: 'encoded_public_key',
              target: any(named: 'target'),
              args: any(named: 'args'),
            ),
          ).called(1);
        });
      });
    });

    group('getReleaseVersion', () {
      const projectName = 'my_app';

      late Pubspec pubspec;

      setUp(() {
        pubspec = MockPubspec();

        when(
          () => windows.findExecutable(
            releaseDirectory: any(named: 'releaseDirectory'),
            projectName: any(named: 'projectName'),
          ),
        ).thenThrow(Exception('No .exe found in release artifact'));
        when(() => quicuiEnv.getPubspecYaml()).thenReturn(pubspec);
        when(() => pubspec.name).thenReturn(projectName);
      });

      group('when an executable does not exist', () {
        test('throws exception', () {
          expect(
            () => runWithOverrides(
              () =>
                  releaser.getReleaseVersion(releaseArtifactRoot: projectRoot),
            ),
            throwsA(isA<Exception>()),
          );
        });
      });

      group('when an executable exists', () {
        const productVersion = '1.2.3';
        late File executable;

        setUp(() {
          executable = File(p.join(projectRoot.path, 'app.exe'));
          when(
            () => windows.findExecutable(
              releaseDirectory: any(named: 'releaseDirectory'),
              projectName: any(named: 'projectName'),
            ),
          ).thenReturn(executable);
          when(
            () => powershell.getProductVersion(any()),
          ).thenAnswer((_) async => productVersion);
        });

        test('returns result of powershell.getProductVersion', () async {
          await expectLater(
            runWithOverrides(
              () => releaser.getReleaseVersion(
                releaseArtifactRoot: projectRoot,
              ),
            ),
            completion(equals(productVersion)),
          );
          verify(
            () => windows.findExecutable(
              releaseDirectory: projectRoot,
              projectName: projectName,
            ),
          ).called(1);
          verify(() => powershell.getProductVersion(executable)).called(1);
        });
      });
    });

    group('uploadReleaseArtifacts', () {
      const appId = 'my-app';
      const releaseId = 123;
      late Release release;

      setUp(() {
        release = MockRelease();
        when(() => release.id).thenReturn(releaseId);
      });

      group('when release directory does not exist', () {
        setUp(() {
          releaseDirectory.deleteSync();
        });

        test('fails progress, exits', () async {
          await expectLater(
            () => runWithOverrides(
              () => releaser.uploadReleaseArtifacts(
                release: release,
                appId: appId,
              ),
            ),
            exitsWithCode(ExitCode.software),
          );
          verify(
            () => logger.err(
              any(that: startsWith('No release directory found at')),
            ),
          ).called(1);
        });
      });

      group('when release directory exists', () {
        setUp(() {
          when(
            () => codePushClientWrapper.createWindowsReleaseArtifacts(
              appId: any(named: 'appId'),
              releaseId: any(named: 'releaseId'),
              projectRoot: any(named: 'projectRoot'),
              releaseZipPath: any(named: 'releaseZipPath'),
            ),
          ).thenAnswer((_) async {});
        });

        test('zips and uploads release directory', () async {
          await runWithOverrides(
            () =>
                releaser.uploadReleaseArtifacts(release: release, appId: appId),
          );
          verify(
            () => codePushClientWrapper.createWindowsReleaseArtifacts(
              appId: appId,
              releaseId: releaseId,
              projectRoot: projectRoot.path,
              releaseZipPath: any(named: 'releaseZipPath'),
            ),
          ).called(1);
        });
      });
    });

    group('postReleaseInstructions', () {
      test('returns nonempty instructions', () {
        final instructions = runWithOverrides(
          () => releaser.postReleaseInstructions,
        );
        expect(
          instructions,
          equals('''

Windows executable created at ${artifactManager.getWindowsReleaseDirectory().path}.
'''),
        );
      });
    });
  });
}
