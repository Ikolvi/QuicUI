import 'dart:io';

import 'package:io/io.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:platform/platform.dart';
import 'package:quicui_aot_cli/src/artifact_builder/artifact_builder.dart';
import 'package:quicui_aot_cli/src/artifact_manager.dart';
import 'package:quicui_aot_cli/src/code_push_client_wrapper.dart';
import 'package:quicui_aot_cli/src/commands/release/releaser.dart';
import 'package:quicui_aot_cli/src/doctor.dart';
import 'package:quicui_aot_cli/src/executables/xcodebuild.dart';
import 'package:quicui_aot_cli/src/extensions/arg_results.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/metadata/metadata.dart';
import 'package:quicui_aot_cli/src/platform/apple.dart';
import 'package:quicui_aot_cli/src/release_type.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:quicui_aot_cli/src/quicui_validator.dart';
import 'package:quicui_aot_cli/src/third_party/flutter_tools/lib/flutter_tools.dart';
import 'package:quicui_aot_code_push_client/quicui_aot_code_push_client.dart';

/// {@template ios_framework_releaser}
/// Functions to create an iOS framework release.
/// {@endtemplate}
class IosFrameworkReleaser extends Releaser {
  /// {@macro ios_framework_releaser}
  IosFrameworkReleaser({
    required super.argResults,
    required super.flavor,
    required super.target,
  });

  /// The directory where the release artifacts are stored.
  Directory get releaseDirectory => Directory(
    p.join(quicuiEnv.getQuicuiProjectRoot()!.path, 'release'),
  );

  @override
  String get artifactDisplayName => 'iOS framework';

  @override
  ReleaseType get releaseType => ReleaseType.iosFramework;

  @override
  Future<void> assertArgsAreValid() async {
    if (!argResults.wasParsed('release-version')) {
      logger.err('Missing required argument: --release-version');
      throw ProcessExit(ExitCode.usage.code);
    }
  }

  @override
  Version? get minimumFlutterVersion => minimumSupportedIosFlutterVersion;

  @override
  Future<void> assertPreconditions() async {
    try {
      await quicuiValidator.validatePreconditions(
        checkUserIsAuthenticated: true,
        checkQuicuiInitialized: true,
        supportedOperatingSystems: {Platform.macOS},
        validators: doctor.iosCommandValidators,
      );
    } on PreconditionFailedException catch (e) {
      throw ProcessExit(e.exitCode.code);
    }
  }

  @override
  Future<FileSystemEntity> buildReleaseArtifacts() async {
    // Delete the Quicui supplement directory if it exists.
    // This is to ensure that we don't accidentally upload stale artifacts
    // when building with older versions of Flutter.
    final quicuiSupplementDir = artifactManager
        .getIosReleaseSupplementDirectory();
    if (quicuiSupplementDir?.existsSync() ?? false) {
      quicuiSupplementDir!.deleteSync(recursive: true);
    }

    await artifactBuilder.buildIosFramework(
      args: argResults.forwardedArgs,
      base64PublicKey: argResults.encodedPublicKey,
    );

    // Copy release xcframework to a new directory to avoid overwriting with
    // subsequent patch builds.
    final sourceLibraryDirectory = artifactManager.getAppXcframeworkDirectory();
    final targetLibraryDirectory = Directory(
      p.join(quicuiEnv.getQuicuiProjectRoot()!.path, 'release'),
    );
    if (targetLibraryDirectory.existsSync()) {
      targetLibraryDirectory.deleteSync(recursive: true);
    }
    await copyPath(sourceLibraryDirectory.path, targetLibraryDirectory.path);

    // Rename Flutter.xcframework to QuicuiFlutter.xcframework to avoid
    // Xcode warning users about the .xcframework signature changing.
    Directory(
      p.join(targetLibraryDirectory.path, 'Flutter.xcframework'),
    ).renameSync(
      p.join(targetLibraryDirectory.path, 'QuicuiFlutter.xcframework'),
    );

    return targetLibraryDirectory;
  }

  @override
  Future<String> getReleaseVersion({
    required FileSystemEntity releaseArtifactRoot,
  }) async {
    return argResults['release-version'] as String;
  }

  @override
  Future<void> uploadReleaseArtifacts({
    required Release release,
    required String appId,
  }) {
    return codePushClientWrapper.createIosFrameworkReleaseArtifacts(
      appId: appId,
      releaseId: release.id,
      appFrameworkPath: p.join(releaseDirectory.path, 'App.xcframework'),
      supplementPath: artifactManager.getIosReleaseSupplementDirectory()?.path,
    );
  }

  @override
  Future<UpdateReleaseMetadata> updatedReleaseMetadata(
    UpdateReleaseMetadata metadata,
  ) async => metadata.copyWith(
    environment: metadata.environment.copyWith(
      xcodeVersion: await xcodeBuild.version(),
    ),
  );

  @override
  String get postReleaseInstructions {
    final relativeFrameworkDirectoryPath = p.relative(releaseDirectory.path);
    return '''

Your next step is to add the .xcframework files found in the ${lightCyan.wrap(relativeFrameworkDirectoryPath)} directory to your iOS app.

To do this:
    1. Add the relative path to the ${lightCyan.wrap(relativeFrameworkDirectoryPath)} directory to your app's Framework Search Paths in your Xcode build settings.
    2. Embed the App.xcframework and QuicuiFlutter.framework in your Xcode project.

Instructions for these steps can be found at https://docs.flutter.dev/add-to-app/ios/project-setup#option-b---embed-frameworks-in-xcode.
''';
  }
}
