import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/quicui_command.dart';
import 'package:quicui_aot_cli/src/quicui_flutter.dart';

/// {@template flutter_versions_list_command}
/// `quicui flutter versions list`
/// List available Flutter versions.
/// {@endtemplate}
class FlutterVersionsListCommand extends QuicuiCommand {
  /// {@macro flutter_versions_list_command}
  FlutterVersionsListCommand();

  @override
  String get description => 'List available Flutter versions.';

  @override
  String get name => 'list';

  @override
  Future<int> run() async {
    final progress = logger.progress('Fetching Flutter versions');

    String? currentVersion;
    try {
      currentVersion = await quicuiFlutter.getVersionString();
    } on ProcessException catch (error) {
      logger.detail('Unable to determine Flutter version.\n${error.message}');
    }

    final List<String> versions;
    try {
      versions = await quicuiFlutter.getVersions();
      progress.cancel();
    } on Exception catch (error) {
      progress.fail('Failed to fetch Flutter versions.');
      logger.err('$error');
      return ExitCode.software.code;
    }

    logger.info('📦 Flutter Versions');
    for (final version in versions.reversed) {
      logger.info(
        version == currentVersion ? lightCyan.wrap('✓ $version') : '  $version',
      );
    }
    return ExitCode.success.code;
  }
}
