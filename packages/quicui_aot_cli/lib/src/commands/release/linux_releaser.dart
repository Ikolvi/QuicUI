import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:platform/platform.dart';
import 'package:quicui_aot_cli/src/artifact_builder/artifact_builder.dart';
import 'package:quicui_aot_cli/src/artifact_manager.dart';
import 'package:quicui_aot_cli/src/code_push_client_wrapper.dart';
import 'package:quicui_aot_cli/src/commands/release/releaser.dart';
import 'package:quicui_aot_cli/src/doctor.dart';
import 'package:quicui_aot_cli/src/extensions/arg_results.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/platform/platform.dart';
import 'package:quicui_aot_cli/src/release_type.dart';
import 'package:quicui_aot_cli/src/quicui_validator.dart';
import 'package:quicui_aot_cli/src/third_party/flutter_tools/lib/flutter_tools.dart';
import 'package:quicui_aot_code_push_client/quicui_aot_code_push_client.dart';

/// {@template linux_releaser}
/// Functions to create a linux release.
/// {@endtemplate}
class LinuxReleaser extends Releaser {
  /// {@macro linux_releaser}
  LinuxReleaser({
    required super.argResults,
    required super.flavor,
    required super.target,
  });

  @override
  ReleaseType get releaseType => ReleaseType.linux;

  @override
  String get artifactDisplayName => 'Linux app';

  @override
  Future<void> assertArgsAreValid() async {
    if (argResults.wasParsed('release-version')) {
      logger.err(
        '''
The "--release-version" flag is only supported for aar and ios-framework releases.

To change the version of this release, change your app's version in your pubspec.yaml.''',
      );
      throw ProcessExit(ExitCode.usage.code);
    }
  }

  @override
  Version? get minimumFlutterVersion => minimumSupportedLinuxFlutterVersion;

  @override
  Future<void> assertPreconditions() async {
    try {
      await quicuiValidator.validatePreconditions(
        checkUserIsAuthenticated: true,
        checkQuicuiInitialized: true,
        validators: doctor.linuxCommandValidators,
        supportedOperatingSystems: {Platform.linux},
      );
    } on PreconditionFailedException catch (e) {
      throw ProcessExit(e.exitCode.code);
    }
  }

  @override
  Future<FileSystemEntity> buildReleaseArtifacts() async {
    await artifactBuilder.buildLinuxApp(
      target: target,
      args: argResults.forwardedArgs,
      base64PublicKey: argResults.encodedPublicKey,
    );

    return artifactManager.linuxBundleDirectory;
  }

  @override
  Future<String> getReleaseVersion({
    required FileSystemEntity releaseArtifactRoot,
  }) async => linux.versionFromLinuxBundle(
    bundleRoot: releaseArtifactRoot as Directory,
  );

  @override
  String get postReleaseInstructions =>
      '''

Linux release created at ${artifactManager.linuxBundleDirectory.path}.
''';

  @override
  Future<void> uploadReleaseArtifacts({
    required Release release,
    required String appId,
  }) => codePushClientWrapper.createLinuxReleaseArtifacts(
    appId: appId,
    releaseId: release.id,
    bundle: artifactManager.linuxBundleDirectory,
  );
}
