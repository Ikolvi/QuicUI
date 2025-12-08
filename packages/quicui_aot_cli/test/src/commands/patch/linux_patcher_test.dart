import 'dart:io';

import 'package:args/args.dart';
import 'package:crypto/crypto.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/archive_analysis/linux_bundle_differ.dart';
import 'package:quicui_aot_cli/src/artifact_builder/artifact_builder.dart';
import 'package:quicui_aot_cli/src/artifact_manager.dart';
import 'package:quicui_aot_cli/src/code_push_client_wrapper.dart';
import 'package:quicui_aot_cli/src/code_signer.dart';
import 'package:quicui_aot_cli/src/commands/commands.dart';
import 'package:quicui_aot_cli/src/common_arguments.dart';
import 'package:quicui_aot_cli/src/doctor.dart';
import 'package:quicui_aot_cli/src/engine_config.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/patch_diff_checker.dart';
import 'package:quicui_aot_cli/src/platform/platform.dart';
import 'package:quicui_aot_cli/src/release_type.dart';
import 'package:quicui_aot_cli/src/quicui_artifacts.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:quicui_aot_cli/src/quicui_flutter.dart';
import 'package:quicui_aot_cli/src/quicui_process.dart';
import 'package:quicui_aot_cli/src/quicui_validator.dart';
import 'package:quicui_aot_cli/src/third_party/flutter_tools/lib/flutter_tools.dart';
import 'package:quicui_aot_code_push_protocol/quicui_aot_code_push_protocol.dart';
import 'package:test/test.dart';

import '../../mocks.dart';

void main() {
  group(LinuxPatcher, () {
    late LinuxPatcher patcher;

    late ArgParser argParser;
    late ArgResults argResults;
    late ArtifactBuilder artifactBuilder;
    late ArtifactManager artifactManager;
    late CodePushClientWrapper codePushClientWrapper;
    late CodeSigner codeSigner;
    late Doctor doctor;
    late EngineConfig engineConfig;
    late Directory projectRoot;
    late Linux linux;
    late QuicuiLogger logger;
    late PatchDiffChecker patchDiffChecker;
    late Progress progress;
    late QuicuiArtifacts quicuiArtifacts;
    late QuicuiProcess quicuiProcess;
    late QuicuiEnv quicuiEnv;
    late QuicuiFlutter quicuiFlutter;
    late QuicuiValidator quicuiValidator;

    R runWithOverrides<R>(R Function() body) {
      return runScoped(
        body,
        values: {
          artifactBuilderRef.overrideWith(() => artifactBuilder),
          artifactManagerRef.overrideWith(() => artifactManager),
          codePushClientWrapperRef.overrideWith(() => codePushClientWrapper),
          codeSignerRef.overrideWith(() => codeSigner),
          doctorRef.overrideWith(() => doctor),
          engineConfigRef.overrideWith(() => engineConfig),
          linuxRef.overrideWith(() => linux),
          loggerRef.overrideWith(() => logger),
          patchDiffCheckerRef.overrideWith(() => patchDiffChecker),
          processRef.overrideWith(() => quicuiProcess),
          quicuiArtifactsRef.overrideWith(() => quicuiArtifacts),
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
      registerFallbackValue(QuicuiArtifact.genSnapshotMacosArm64);
      registerFallbackValue(Uri.parse('https://example.com'));
      registerFallbackValue(const LinuxBundleDiffer());
    });

    setUp(() {
      argParser = MockArgParser();
      argResults = MockArgResults();
      artifactBuilder = MockArtifactBuilder();
      artifactManager = MockArtifactManager();
      codePushClientWrapper = MockCodePushClientWrapper();
      codeSigner = MockCodeSigner();
      doctor = MockDoctor();
      engineConfig = MockEngineConfig();
      linux = MockLinux();
      patchDiffChecker = MockPatchDiffChecker();
      progress = MockProgress();
      projectRoot = Directory.systemTemp.createTempSync();
      logger = MockQuicuiLogger();
      quicuiArtifacts = MockQuicuiArtifacts();
      quicuiProcess = MockQuicuiProcess();
      quicuiEnv = MockQuicuiEnv();
      quicuiFlutter = MockQuicuiFlutter();
      quicuiValidator = MockQuicuiValidator();

      when(() => argParser.options).thenReturn({});

      when(() => argResults.options).thenReturn([]);
      when(() => argResults.rest).thenReturn([]);
      when(() => argResults.wasParsed(any())).thenReturn(false);

      when(() => logger.progress(any())).thenReturn(progress);

      when(
        () => quicuiEnv.getQuicuiProjectRoot(),
      ).thenReturn(projectRoot);

      patcher = LinuxPatcher(
        argParser: argParser,
        argResults: argResults,
        flavor: null,
        target: null,
      );
    });

    group('releaseType', () {
      test('is linux', () {
        expect(patcher.releaseType, ReleaseType.linux);
      });
    });

    group('primaryReleaseArtifactArch', () {
      test('is bundle', () {
        expect(
          patcher.primaryReleaseArtifactArch,
          primaryLinuxReleaseArtifactArch,
        );
      });
    });

    group('assertPreconditions', () {
      test('does nothing', () async {
        await patcher.assertPreconditions();
      });
    });

    group('assertUnpatchableDiffs', () {
      late ReleaseArtifact releaseArtifact;
      late File releaseArchive;
      late File patchArchive;
      late DiffStatus diffStatus;

      setUp(() {
        diffStatus = const DiffStatus(
          hasAssetChanges: false,
          hasNativeChanges: false,
        );
        releaseArtifact = MockReleaseArtifact();
        final tempDir = Directory.systemTemp.createTempSync();
        releaseArchive = File(p.join(tempDir.path, 'release.zip'));
        patchArchive = File(p.join(tempDir.path, 'patch.zip'));

        when(
          () => patchDiffChecker.confirmUnpatchableDiffsIfNecessary(
            localArchive: any(named: 'localArchive'),
            releaseArchive: any(named: 'releaseArchive'),
            archiveDiffer: any(named: 'archiveDiffer'),
            allowAssetChanges: any(named: 'allowAssetChanges'),
            allowNativeChanges: any(named: 'allowNativeChanges'),
          ),
        ).thenAnswer((_) async => diffStatus);
      });

      test('returns result from patchDiffChecker', () async {
        final diffStatus = await runWithOverrides(
          () => patcher.assertUnpatchableDiffs(
            releaseArtifact: releaseArtifact,
            releaseArchive: releaseArchive,
            patchArchive: patchArchive,
          ),
        );

        expect(
          diffStatus,
          const DiffStatus(hasAssetChanges: false, hasNativeChanges: false),
        );
        verify(
          () => patchDiffChecker.confirmUnpatchableDiffsIfNecessary(
            localArchive: patchArchive,
            releaseArchive: releaseArchive,
            archiveDiffer: const LinuxBundleDiffer(),
            allowAssetChanges: false,
            allowNativeChanges: false,
          ),
        ).called(1);
      });
    });

    group('buildPatchArtifact', () {
      const flutterVersionAndRevision = '3.27.1 (8495dee1fd)';

      setUp(() {
        when(
          () => quicuiFlutter.getVersionAndRevision(),
        ).thenAnswer((_) async => flutterVersionAndRevision);
        when(
          () => quicuiFlutter.getVersion(),
        ).thenAnswer((_) async => Version(3, 27, 1));
      });

      group('when build fails', () {
        final exception = Exception('Failed to build Windows app');
        setUp(() {
          when(() => artifactBuilder.buildLinuxApp()).thenThrow(exception);
        });

        test('throws exception', () async {
          expect(
            () => runWithOverrides(() => patcher.buildPatchArtifact()),
            throwsA(exception),
          );
        });
      });

      group('when build succeeds', () {
        setUp(() {
          final releaseDir = Directory(
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
            () => artifactManager.linuxBundleDirectory,
          ).thenReturn(releaseDir);
          when(
            () => artifactBuilder.buildLinuxApp(),
          ).thenAnswer((_) async => {});
        });

        test('returns a zipped exe file', () async {
          await expectLater(
            runWithOverrides(() => patcher.buildPatchArtifact()),
            completion(
              isA<File>().having((f) => f.path, 'path', endsWith('.zip')),
            ),
          );
        });
      });
    });

    group('createPatchArtifacts', () {
      const appId = 'app-id';
      const releaseId = 42;

      late Directory releaseDirectory;
      late File releaseArtifact;
      late File patchArtifact;
      late File diffFile;

      setUp(() {
        final tempDir = Directory.systemTemp.createTempSync();
        releaseArtifact = File(p.join(tempDir.path, 'release.zip'))
          ..createSync(recursive: true);

        diffFile = File(p.join(tempDir.path, 'diff.so'))
          ..createSync(recursive: true);

        releaseDirectory = Directory(
          p.join(
            projectRoot.path,
            'build',
            'linux',
            'x64',
            'release',
            'bundle',
          ),
        )..createSync(recursive: true);

        patchArtifact = File(p.join(releaseDirectory.path, 'lib', 'libapp.so'))
          ..createSync(recursive: true);

        when(
          () => artifactManager.linuxBundleDirectory,
        ).thenReturn(releaseDirectory);
        when(
          () => artifactManager.extractZip(
            zipFile: any(named: 'zipFile'),
            outputDirectory: any(named: 'outputDirectory'),
          ),
        ).thenAnswer((invocation) async {
          (invocation.namedArguments[#outputDirectory] as Directory).createSync(
            recursive: true,
          );
        });
      });

      group('when creating diff fails', () {
        setUp(() {
          when(
            () => artifactManager.createDiff(
              releaseArtifactPath: any(named: 'releaseArtifactPath'),
              patchArtifactPath: any(named: 'patchArtifactPath'),
            ),
          ).thenThrow(Exception('Failed to create diff'));
        });

        test('exits with software error code', () async {
          expect(
            () => runWithOverrides(
              () => patcher.createPatchArtifacts(
                appId: appId,
                releaseId: releaseId,
                releaseArtifact: releaseArtifact,
              ),
            ),
            throwsA(
              isA<ProcessExit>().having((e) => e.exitCode, 'exitCode', 70),
            ),
          );
        });
      });

      group('when creating artifacts succeeds', () {
        setUp(() {
          when(
            () => artifactManager.createDiff(
              releaseArtifactPath: any(named: 'releaseArtifactPath'),
              patchArtifactPath: any(named: 'patchArtifactPath'),
            ),
          ).thenAnswer((_) async => diffFile.path);
        });

        test('returns patch artifacts', () async {
          final patchArtifacts = await runWithOverrides(
            () => patcher.createPatchArtifacts(
              appId: 'com.example.app',
              releaseId: 1,
              releaseArtifact: releaseArtifact,
              supplementArtifact: File('supplement.zip'),
            ),
          );

          final expectedHash = sha256
              .convert(await patchArtifact.readAsBytes())
              .toString();

          expect(
            patchArtifacts,
            equals({
              Arch.x86_64: PatchArtifactBundle(
                arch: Arch.x86_64.arch,
                path: diffFile.path,
                hash: expectedHash,
                size: diffFile.lengthSync(),
              ),
            }),
          );
        });
      });

      group('when signing keys are provided', () {
        setUp(() {
          when(
            () => artifactManager.createDiff(
              releaseArtifactPath: any(named: 'releaseArtifactPath'),
              patchArtifactPath: any(named: 'patchArtifactPath'),
            ),
          ).thenAnswer((_) async => diffFile.path);
          when(
            () => argResults[CommonArguments.publicKeyArg.name],
          ).thenReturn('public-key.pem');
          when(
            () => argResults[CommonArguments.privateKeyArg.name],
          ).thenReturn('private-key.pem');
          when(
            () => codeSigner.sign(
              message: any(named: 'message'),
              privateKeyPemFile: any(named: 'privateKeyPemFile'),
            ),
          ).thenReturn('signature');
        });

        test('signs patch', () async {
          final result = await runWithOverrides(
            () => patcher.createPatchArtifacts(
              appId: appId,
              releaseId: releaseId,
              releaseArtifact: releaseArtifact,
            ),
          );

          expect(result[Arch.x86_64]!.hashSignature, equals('signature'));
          verify(
            () => codeSigner.sign(
              message: any(named: 'message'),
              privateKeyPemFile: any(
                named: 'privateKeyPemFile',
                that: isA<File>().having(
                  (f) => f.path,
                  'path',
                  equals('private-key.pem'),
                ),
              ),
            ),
          ).called(1);
        });
      });
    });

    group('extractReleaseVersionFromArtifact', () {
      setUp(() async {
        when(
          () => artifactManager.extractZip(
            zipFile: any(named: 'zipFile'),
            outputDirectory: any(named: 'outputDirectory'),
          ),
        ).thenAnswer((invocation) async {
          (invocation.namedArguments[#outputDirectory] as Directory).createSync(
            recursive: true,
          );
        });

        when(
          () => linux.versionFromLinuxBundle(
            bundleRoot: any(named: 'bundleRoot'),
          ),
        ).thenReturn('1.2.3');
      });

      test('returns version from archived exe', () async {
        final version = await runWithOverrides(
          () => patcher.extractReleaseVersionFromArtifact(File('bundle.zip')),
        );

        expect(version, '1.2.3');
      });
    });
  });
}
