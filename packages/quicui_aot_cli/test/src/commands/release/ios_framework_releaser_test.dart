import 'dart:io';

import 'package:args/args.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:platform/platform.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/artifact_builder/artifact_builder.dart';
import 'package:quicui_aot_cli/src/artifact_manager.dart';
import 'package:quicui_aot_cli/src/code_push_client_wrapper.dart';
import 'package:quicui_aot_cli/src/code_signer.dart';
import 'package:quicui_aot_cli/src/commands/release/ios_framework_releaser.dart';
import 'package:quicui_aot_cli/src/common_arguments.dart';
import 'package:quicui_aot_cli/src/config/config.dart';
import 'package:quicui_aot_cli/src/doctor.dart';
import 'package:quicui_aot_cli/src/executables/executables.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/metadata/metadata.dart';
import 'package:quicui_aot_cli/src/os/operating_system_interface.dart';
import 'package:quicui_aot_cli/src/release_type.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:quicui_aot_cli/src/quicui_flutter.dart';
import 'package:quicui_aot_cli/src/quicui_process.dart';
import 'package:quicui_aot_cli/src/quicui_validator.dart';
import 'package:quicui_aot_cli/src/validators/validators.dart';
import 'package:quicui_aot_cli/src/version.dart';
import 'package:quicui_aot_code_push_client/quicui_aot_code_push_client.dart';
import 'package:test/test.dart';

import '../../matchers.dart';
import '../../mocks.dart';

void main() {
  group(IosFrameworkReleaser, () {
    late ArgResults argResults;
    late ArtifactBuilder artifactBuilder;
    late ArtifactManager artifactManager;
    late CodePushClientWrapper codePushClientWrapper;
    late CodeSigner codeSigner;
    late Doctor doctor;
    late Directory projectRoot;
    late FlavorValidator flavorValidator;
    late QuicuiLogger logger;
    late OperatingSystemInterface operatingSystemInterface;
    late Progress progress;
    late QuicuiProcess quicuiProcess;
    late QuicuiEnv quicuiEnv;
    late QuicuiFlutter quicuiFlutter;
    late QuicuiValidator quicuiValidator;
    late XcodeBuild xcodeBuild;
    late IosFrameworkReleaser iosFrameworkReleaser;

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
          osInterfaceRef.overrideWith(() => operatingSystemInterface),
          processRef.overrideWith(() => quicuiProcess),
          quicuiEnvRef.overrideWith(() => quicuiEnv),
          quicuiFlutterRef.overrideWith(() => quicuiFlutter),
          quicuiValidatorRef.overrideWith(() => quicuiValidator),
          xcodeBuildRef.overrideWith(() => xcodeBuild),
        },
      );
    }

    setUpAll(() {
      registerFallbackValue(Directory(''));
      registerFallbackValue(File(''));
      registerFallbackValue(ReleasePlatform.ios);
    });

    setUp(() {
      argResults = MockArgResults();
      artifactBuilder = MockArtifactBuilder();
      artifactManager = MockArtifactManager();
      codePushClientWrapper = MockCodePushClientWrapper();
      codeSigner = MockCodeSigner();
      doctor = MockDoctor();
      flavorValidator = MockFlavorValidator();
      operatingSystemInterface = MockOperatingSystemInterface();
      progress = MockProgress();
      projectRoot = Directory.systemTemp.createTempSync();
      logger = MockQuicuiLogger();
      quicuiProcess = MockQuicuiProcess();
      quicuiEnv = MockQuicuiEnv();
      quicuiFlutter = MockQuicuiFlutter();
      quicuiValidator = MockQuicuiValidator();
      xcodeBuild = MockXcodeBuild();

      when(() => argResults.rest).thenReturn([]);
      when(() => argResults.wasParsed(any())).thenReturn(false);
      when(() => argResults['flutter-version']).thenReturn('latest');

      when(() => logger.progress(any())).thenReturn(progress);

      when(
        () => quicuiEnv.getQuicuiProjectRoot(),
      ).thenReturn(projectRoot);

      iosFrameworkReleaser = IosFrameworkReleaser(
        argResults: argResults,
        flavor: null,
        target: null,
      );
    });

    group('releaseType', () {
      test('is xcframework', () {
        expect(iosFrameworkReleaser.releaseType, ReleaseType.iosFramework);
      });
    });

    group('minimumFlutterVersion', () {
      test('is 3.22.2', () {
        expect(iosFrameworkReleaser.minimumFlutterVersion, Version(3, 22, 2));
      });
    });

    group('artifactDisplayName', () {
      test('has expected value', () {
        expect(iosFrameworkReleaser.artifactDisplayName, 'iOS framework');
      });
    });

    group('assertArgsAreValid', () {
      group('when split-per-abi is true', () {
        setUp(() {
          when(() => argResults.wasParsed('release-version')).thenReturn(false);
        });

        test('exits with code 64', () async {
          await expectLater(
            () => runWithOverrides(iosFrameworkReleaser.assertArgsAreValid),
            exitsWithCode(ExitCode.usage),
          );
        });
      });

      group('when arguments are valid', () {
        setUp(() {
          when(() => argResults.wasParsed('release-version')).thenReturn(true);
        });

        test('returns normally', () {
          expect(
            () => runWithOverrides(iosFrameworkReleaser.assertArgsAreValid),
            returnsNormally,
          );
        });
      });
    });

    group('assertPreconditions', () {
      final flutterVersion = Version(3, 0, 0);

      setUp(() {
        when(() => doctor.iosCommandValidators).thenReturn([flavorValidator]);
        when(
          () => quicuiFlutter.resolveFlutterVersion(any()),
        ).thenAnswer((_) async => flutterVersion);
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
            () => runWithOverrides(iosFrameworkReleaser.assertPreconditions),
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
            () => runWithOverrides(iosFrameworkReleaser.assertPreconditions),
            exitsWithCode(exception.exitCode),
          );
          verify(
            () => quicuiValidator.validatePreconditions(
              checkUserIsAuthenticated: true,
              checkQuicuiInitialized: true,
              validators: [flavorValidator],
              supportedOperatingSystems: {Platform.macOS},
            ),
          ).called(1);
        });
      });

      group('when specified flutter version is less than minimum', () {
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
          when(() => argResults['flutter-version']).thenReturn('3.0.0');
        });
      });
    });

    group('buildReleaseArtifacts', () {
      void setUpProjectRootArtifacts() {
        // Create an xcframework in the release directory to simulate running
        // this command a subsequent time.
        Directory(
          p.join(projectRoot.path, 'release', 'Flutter.xcframework'),
        ).createSync(recursive: true);
        Directory(
          p.join(
            projectRoot.path,
            'build',
            'ios',
            'framework',
            'Release',
            'Flutter.xcframework',
          ),
        ).createSync(recursive: true);
      }

      setUp(() {
        when(
          () => artifactBuilder.buildIosFramework(args: any(named: 'args')),
        ).thenAnswer(
          (_) async => AppleBuildResult(kernelFile: File('/path/to/app.dill')),
        );
        when(() => artifactManager.getAppXcframeworkDirectory()).thenReturn(
          Directory(
            p.join(projectRoot.path, 'build', 'ios', 'framework', 'Release'),
          ),
        );

        setUpProjectRootArtifacts();
      });

      group('when a patch signing key path is provided', () {
        const base64PublicKey = 'base64PublicKey';
        setUp(() {
          final patchSigningPublicKeyFile = File(
            p.join(
              Directory.systemTemp.createTempSync().path,
              'patch-signing-public-key.pem',
            ),
          )..createSync(recursive: true);
          when(
            () => argResults[CommonArguments.publicKeyArg.name],
          ).thenReturn(patchSigningPublicKeyFile.path);

          when(
            () => artifactBuilder.buildIosFramework(
              args: any(named: 'args'),
              base64PublicKey: any(named: 'base64PublicKey'),
            ),
          ).thenAnswer(
            (_) async =>
                AppleBuildResult(kernelFile: File('/path/to/app.dill')),
          );
          when(
            () => codeSigner.base64PublicKey(any()),
          ).thenReturn(base64PublicKey);
        });

        test(
          'encodes the patch signing public key and '
          'forward it to buildIosFramework',
          () async {
            await runWithOverrides(
              () => iosFrameworkReleaser.buildReleaseArtifacts(),
            );

            verify(
              () => artifactBuilder.buildIosFramework(
                args: any(named: 'args'),
                base64PublicKey: base64PublicKey,
              ),
            ).called(1);
          },
        );
      });

      group('when stale build/ios/quicui directory exists', () {
        late Directory quicuiSupplementDir;

        setUp(() {
          quicuiSupplementDir = Directory(
            p.join(projectRoot.path, 'build', 'ios', 'quicui'),
          )..createSync(recursive: true);
          when(
            () => artifactManager.getIosReleaseSupplementDirectory(),
          ).thenReturn(quicuiSupplementDir);
        });

        test('deletes the directory', () async {
          expect(quicuiSupplementDir.existsSync(), isTrue);
          await runWithOverrides(iosFrameworkReleaser.buildReleaseArtifacts);
          expect(quicuiSupplementDir.existsSync(), isFalse);
        });
      });

      group('when platform was specified via arg results rest', () {
        setUp(() {
          when(() => argResults.rest).thenReturn(['ios', '--verbose']);
        });

        test('produces xcframework in release directory', () async {
          final xcframework = await runWithOverrides(
            iosFrameworkReleaser.buildReleaseArtifacts,
          );

          expect(xcframework.path, p.join(projectRoot.path, 'release'));
          verify(
            () => artifactBuilder.buildIosFramework(args: ['--verbose']),
          ).called(1);
        });
      });

      test('produces xcframework in release directory', () async {
        final xcframework = await runWithOverrides(
          iosFrameworkReleaser.buildReleaseArtifacts,
        );

        expect(xcframework.path, p.join(projectRoot.path, 'release'));
        verify(() => artifactBuilder.buildIosFramework(args: [])).called(1);
      });
    });

    group('getReleaseVersion', () {
      const releaseVersion = '1.0.0';
      setUp(() {
        when(() => argResults['release-version']).thenReturn(releaseVersion);
      });

      test('returns value from argResults', () async {
        final result = await runWithOverrides(
          () => iosFrameworkReleaser.getReleaseVersion(
            releaseArtifactRoot: Directory(''),
          ),
        );
        expect(result, releaseVersion);
      });
    });

    group('uploadReleaseArtifacts', () {
      const releaseVersion = '1.0.0';
      const appId = 'appId';
      const flutterRevision = 'deadbeef';
      const flutterVersion = '3.22.1';

      final release = Release(
        id: 42,
        appId: appId,
        version: releaseVersion,
        flutterRevision: flutterRevision,
        flutterVersion: flutterVersion,
        displayName: '1.2.3+1',
        platformStatuses: const {},
        createdAt: DateTime(2023),
        updatedAt: DateTime(2023),
      );

      setUp(() {
        when(
          () => codePushClientWrapper.createIosFrameworkReleaseArtifacts(
            appId: any(named: 'appId'),
            releaseId: any(named: 'releaseId'),
            appFrameworkPath: any(named: 'appFrameworkPath'),
            supplementPath: any(named: 'supplementPath'),
          ),
        ).thenAnswer((_) async {});
      });

      test('uploads artifacts', () async {
        await runWithOverrides(
          () => iosFrameworkReleaser.uploadReleaseArtifacts(
            release: release,
            appId: appId,
          ),
        );

        verify(
          () => codePushClientWrapper.createIosFrameworkReleaseArtifacts(
            appId: appId,
            releaseId: release.id,
            appFrameworkPath: p.join(
              projectRoot.path,
              'release',
              ArtifactManager.appXcframeworkName,
            ),
            supplementPath: null,
          ),
        ).called(1);
      });
    });

    group('updatedReleaseMetadata', () {
      const flutterRevision = '853d13d954df3b6e9c2f07b72062f33c52a9a64b';
      const operatingSystem = 'macos';
      const operatingSystemVersion = '11.0.0';
      const xcodeVersion = '123';
      const metadata = UpdateReleaseMetadata(
        releasePlatform: ReleasePlatform.ios,
        flutterVersionOverride: null,
        includesPublicKey: false,
        environment: BuildEnvironmentMetadata(
          flutterRevision: flutterRevision,
          operatingSystem: operatingSystem,
          operatingSystemVersion: operatingSystemVersion,
          quicuiVersion: packageVersion,
          quicuiYaml: QuicuiYaml(appId: 'app-id'),
          usesQuicuiCodePushPackage: false,
        ),
      );

      setUp(() {
        when(() => xcodeBuild.version()).thenAnswer((_) async => xcodeVersion);
      });

      test('returns expected metadata', () async {
        expect(
          runWithOverrides(
            () => iosFrameworkReleaser.updatedReleaseMetadata(metadata),
          ),
          completion(
            const UpdateReleaseMetadata(
              releasePlatform: ReleasePlatform.ios,
              flutterVersionOverride: null,
              includesPublicKey: false,
              environment: BuildEnvironmentMetadata(
                flutterRevision: flutterRevision,
                operatingSystem: operatingSystem,
                operatingSystemVersion: operatingSystemVersion,
                quicuiVersion: packageVersion,
                quicuiYaml: QuicuiYaml(appId: 'app-id'),
                usesQuicuiCodePushPackage: false,
                xcodeVersion: xcodeVersion,
              ),
            ),
          ),
        );
      });
    });

    group('postReleaseInstructions', () {
      test('returns expected instructions', () {
        final relativeFrameworkDirectoryPath = p.relative(
          p.join(projectRoot.path, 'release'),
        );
        expect(
          runWithOverrides(() => iosFrameworkReleaser.postReleaseInstructions),
          equals('''

Your next step is to add the .xcframework files found in the ${lightCyan.wrap(relativeFrameworkDirectoryPath)} directory to your iOS app.

To do this:
    1. Add the relative path to the ${lightCyan.wrap(relativeFrameworkDirectoryPath)} directory to your app's Framework Search Paths in your Xcode build settings.
    2. Embed the App.xcframework and QuicuiFlutter.framework in your Xcode project.

Instructions for these steps can be found at https://docs.flutter.dev/add-to-app/ios/project-setup#option-b---embed-frameworks-in-xcode.
'''),
        );
      });
    });
  }, testOn: 'mac-os');
}
