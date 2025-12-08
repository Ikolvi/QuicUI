import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:platform/platform.dart';
import 'package:quicui_aot_cli/src/archive/archive.dart';
import 'package:quicui_aot_cli/src/archive_analysis/windows_archive_differ.dart';
import 'package:quicui_aot_cli/src/artifact_builder/artifact_builder.dart';
import 'package:quicui_aot_cli/src/artifact_manager.dart';
import 'package:quicui_aot_cli/src/code_push_client_wrapper.dart';
import 'package:quicui_aot_cli/src/code_signer.dart';
import 'package:quicui_aot_cli/src/commands/patch/patcher.dart';
import 'package:quicui_aot_cli/src/common_arguments.dart';
import 'package:quicui_aot_cli/src/doctor.dart';
import 'package:quicui_aot_cli/src/executables/executables.dart';
import 'package:quicui_aot_cli/src/extensions/arg_results.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/patch_diff_checker.dart';
import 'package:quicui_aot_cli/src/platform/platform.dart';
import 'package:quicui_aot_cli/src/release_type.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:quicui_aot_cli/src/quicui_validator.dart';
import 'package:quicui_aot_cli/src/third_party/flutter_tools/lib/flutter_tools.dart';
import 'package:quicui_aot_code_push_client/quicui_aot_code_push_client.dart';

/// {@template windows_patcher}
/// Functions to create a Windows patch.
/// {@endtemplate}
class WindowsPatcher extends Patcher {
  /// {@macro windows_patcher}
  WindowsPatcher({
    required super.argParser,
    required super.argResults,
    required super.flavor,
    required super.target,
  });

  @override
  String get primaryReleaseArtifactArch => primaryWindowsReleaseArtifactArch;

  @override
  ReleaseType get releaseType => ReleaseType.windows;

  @override
  Future<void> assertPreconditions() async {
    try {
      await quicuiValidator.validatePreconditions(
        checkUserIsAuthenticated: true,
        checkQuicuiInitialized: true,
        validators: doctor.windowsCommandValidators,
        supportedOperatingSystems: {Platform.windows},
      );
    } on PreconditionFailedException catch (e) {
      throw ProcessExit(e.exitCode.code);
    }
  }

  @override
  Future<DiffStatus> assertUnpatchableDiffs({
    required ReleaseArtifact releaseArtifact,
    required File releaseArchive,
    required File patchArchive,
  }) {
    return patchDiffChecker.confirmUnpatchableDiffsIfNecessary(
      localArchive: patchArchive,
      releaseArchive: releaseArchive,
      archiveDiffer: const WindowsArchiveDiffer(),
      allowAssetChanges: allowAssetDiffs,
      allowNativeChanges: allowNativeDiffs,
    );
  }

  @override
  Future<File> buildPatchArtifact({String? releaseVersion}) async {
    final releaseDir = await artifactBuilder.buildWindowsApp(
      target: target,
      args: argResults.forwardedArgs,
      base64PublicKey: argResults.encodedPublicKey,
    );
    return releaseDir.zipToTempFile();
  }

  @override
  Future<Map<Arch, PatchArtifactBundle>> createPatchArtifacts({
    required String appId,
    required int releaseId,
    required File releaseArtifact,
    File? supplementArtifact,
  }) async {
    final createDiffProgress = logger.progress('Creating patch artifacts');
    final patchArtifactPath = p.join(
      artifactManager.getWindowsReleaseDirectory().path,
      'data',
      'app.so',
    );
    final patchArtifact = File(patchArtifactPath);
    final hash = sha256.convert(await patchArtifact.readAsBytes()).toString();

    final tempDir = Directory.systemTemp.createTempSync();
    final zipPath = p.join(tempDir.path, 'patch.zip');
    final zipFile = releaseArtifact.copySync(zipPath);
    await artifactManager.extractZip(
      zipFile: zipFile,
      outputDirectory: tempDir,
    );

    // The release artifact is the zipped directory at
    // build/windows/x64/runner/Release
    final appSoPath = p.join(tempDir.path, 'data', 'app.so');

    final privateKeyFile = argResults.file(CommonArguments.privateKeyArg.name);
    final hashSignature = privateKeyFile != null
        ? codeSigner.sign(message: hash, privateKeyPemFile: privateKeyFile)
        : null;

    final String diffPath;
    try {
      diffPath = await artifactManager.createDiff(
        releaseArtifactPath: appSoPath,
        patchArtifactPath: patchArtifactPath,
      );
    } on Exception catch (error) {
      createDiffProgress.fail('$error');
      throw ProcessExit(ExitCode.software.code);
    }

    createDiffProgress.complete();

    return {
      Arch.x86_64: PatchArtifactBundle(
        arch: Arch.x86_64.arch,
        path: diffPath,
        hash: hash,
        size: File(diffPath).lengthSync(),
        hashSignature: hashSignature,
      ),
    };
  }

  @override
  Future<String> extractReleaseVersionFromArtifact(File artifact) async {
    final outputDirectory = Directory.systemTemp.createTempSync();
    await artifactManager.extractZip(
      zipFile: artifact,
      outputDirectory: outputDirectory,
    );
    final executable = windows.findExecutable(
      releaseDirectory: outputDirectory,
      projectName: quicuiEnv.getPubspecYaml()!.name,
    );
    return powershell.getProductVersion(executable);
  }
}
