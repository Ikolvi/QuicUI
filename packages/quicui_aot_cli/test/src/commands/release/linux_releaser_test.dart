import 'dart:io';

import 'package:args/args.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:platform/platform.dart';
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/artifact_builder/artifact_builder.dart';
import 'package:quicui_aot_cli/src/artifact_manager.dart';
import 'package:quicui_aot_cli/src/code_push_client_wrapper.dart';
import 'package:quicui_aot_cli/src/code_signer.dart';
import 'package:quicui_aot_cli/src/commands/commands.dart';
import 'package:quicui_aot_cli/src/common_arguments.dart';
import 'package:quicui_aot_cli/src/doctor.dart';
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
  group(LinuxReleaser, () {
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
    late Linux linux;
    late Progress progress;
    late QuicuiProcess quicuiProcess;
    late QuicuiEnv quicuiEnv;
    late QuicuiFlutter quicuiFlutter;
    late QuicuiValidator quicuiValidator;
    late LinuxReleaser releaser;

    R runWithOverrides<R>(R Function() body) {
      return runScoped(
        body,
        values: {
          artifactBuilderRef.overrideWith(() => artifactBuilder),
          artifactManagerRef.overrideWith(() => artifactManager),
          codePushClientWrapperRef.overrideWith(() => codePushClientWrapper),
          codeSignerRef.overrideWith(() => codeSigner),
          doctorRef.overrideWith(() => doctor),
          linuxRef.overrideWith(() => linux),
          loggerRef.overrideWith(() => logger),
          processRef.overrideWith(() => quicuiProcess),
          quicuiEnvRef.overrideWith(() => quicuiEnv),
          quicuiFlutterRef.overrideWith(() => quicuiFlutter),
          quicuiValidatorRef.overrideWith(() => quicuiValidator),
        },
      );
    }

    setUpAll(() {
      registerFallbackValue(Directory(''));
      registerFallbackValue(File(''));
      registerFallbackValue(ReleasePlatform.linux);
    });

    setUp(() {
      argResults = MockArgResults();
      artifactBuilder = MockArtifactBuilder();
      artifactManager = MockArtifactManager();
      codePushClientWrapper = MockCodePushClientWrapper();
      codeSigner = MockCodeSigner();
      doctor = MockDoctor();
      flavorValidator = MockFlavorValidator();
      linux = MockLinux();
      progress = MockProgress();
      projectRoot = Directory.systemTemp.createTempSync();
      logger = MockQuicuiLogger();
      quicuiProcess = MockQuicuiProcess();
      quicuiEnv = MockQuicuiEnv();
      quicuiFlutter = MockQuicuiFlutter();
      quicuiValidator = MockQuicuiValidator();

      when(() => argResults.rest).thenReturn([]);
      when(() => argResults.wasParsed(any())).thenReturn(false);
      when(() => argResults['flutter-version']).thenReturn('latest');

      releaseDirectory = Directory(
        p.join(projectRoot.path, 'build', 'linux', 'x64', 'release', 'bundle'),
      )..createSync(recursive: true);

      when(
        () => artifactManager.linuxBundleDirectory,
      ).thenReturn(releaseDirectory);

      when(() => logger.progress(any())).thenReturn(progress);

      when(
        () => quicuiEnv.getQuicuiProjectRoot(),
      ).thenReturn(projectRoot);

      releaser = LinuxReleaser(
        argResults: argResults,
        flavor: null,
        target: null,
      );
    });

    group('releaseType', () {
      test('is linux', () {
        expect(releaser.releaseType, ReleaseType.linux);
      });
    });

    group('minimumFlutterVersion', () {
      test('is 3.27.4', () {
        expect(releaser.minimumFlutterVersion, Version(3, 27, 4));
      });
    });

    group('artifactDisplayName', () {
      test('has expected value', () {
        expect(releaser.artifactDisplayName, 'Linux app');
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
        when(() => doctor.linuxCommandValidators).thenReturn([flavorValidator]);
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
              supportedOperatingSystems: {Platform.linux},
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
          () => artifactBuilder.buildLinuxApp(
            target: any(named: 'target'),
            args: any(named: 'args'),
            base64PublicKey: any(named: 'base64PublicKey'),
          ),
        ).thenAnswer((_) async => projectRoot);
      });

      test('returns path to release directory', () async {
        final releaseDir = await runWithOverrides(
          releaser.buildReleaseArtifacts,
        );
        expect(releaseDir, releaseDirectory);
      });

      group('when target and flavor are specified', () {
        const flavor = 'my-flavor';
        const target = 'my-target';

        setUp(() {
          releaser = LinuxReleaser(
            argResults: argResults,
            flavor: flavor,
            target: target,
          );
        });

        test('builds artifacts with flavor and target', () async {
          await runWithOverrides(releaser.buildReleaseArtifacts);
          verify(
            () => artifactBuilder.buildLinuxApp(target: target, args: []),
          ).called(1);
        });
      });

      group('when additional args are specified', () {
        final args = ['--build-number=0 --build-name=1.0.0+1'];
        setUp(() {
          when(() => argResults.rest).thenReturn(args);
        });

        test('forwards args to artifact builder', () async {
          await runWithOverrides(releaser.buildReleaseArtifacts);
          verify(() => artifactBuilder.buildLinuxApp(args: args)).called(1);
        });
      });

      group('when public key is passed as an arg', () {
        setUp(() {
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

        test('passes public key to buildLinuxApp', () async {
          await runWithOverrides(releaser.buildReleaseArtifacts);
          verify(
            () => artifactBuilder.buildLinuxApp(
              base64PublicKey: 'encoded_public_key',
              target: any(named: 'target'),
              args: any(named: 'args'),
            ),
          ).called(1);
        });
      });
    });

    group('getReleaseVersion', () {
      setUp(() {
        when(
          () => linux.versionFromLinuxBundle(
            bundleRoot: any(named: 'bundleRoot'),
          ),
        ).thenReturn('3.27.3');
      });

      test('returns version from linux bundle', () async {
        final version = await runWithOverrides(
          () =>
              releaser.getReleaseVersion(releaseArtifactRoot: releaseDirectory),
        );
        expect(version, '3.27.3');
      });
    });

    group('uploadReleaseArtifacts', () {
      const appId = 'my-app';
      const releaseId = 123;
      late Release release;

      setUp(() {
        release = MockRelease();
        when(() => release.id).thenReturn(releaseId);
        when(
          () => codePushClientWrapper.createLinuxReleaseArtifacts(
            appId: any(named: 'appId'),
            releaseId: any(named: 'releaseId'),
            bundle: any(named: 'bundle'),
          ),
        ).thenAnswer((_) async {});
      });

      test('zips and uploads release directory', () async {
        await runWithOverrides(
          () => releaser.uploadReleaseArtifacts(release: release, appId: appId),
        );
        verify(
          () => codePushClientWrapper.createLinuxReleaseArtifacts(
            appId: appId,
            releaseId: releaseId,
            bundle: any(named: 'bundle'),
          ),
        ).called(1);
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

Linux release created at ${artifactManager.linuxBundleDirectory.path}.
'''),
        );
      });
    });
  });
}
