import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/quicui_command.dart';
import 'package:quicui_aot_cli/src/quicui_version.dart';

/// {@template upgrade_command}
/// `quicui upgrade`
/// A command which upgrades your copy of Quicui.
/// {@endtemplate}
class UpgradeCommand extends QuicuiCommand {
  /// {@macro upgrade_command}
  UpgradeCommand();

  @override
  String get description => 'Upgrade your copy of Quicui.';

  /// Name of the command, exposed for the [CommandRunner].
  static const String commandName = 'upgrade';

  @override
  String get name => commandName;

  @override
  Future<int> run() async {
    final updateCheckProgress = logger.progress('Checking for updates');

    late final String currentVersion;
    try {
      currentVersion = await quicuiVersion.fetchCurrentGitHash();
    } on ProcessException catch (error) {
      updateCheckProgress.fail();
      logger.err('Fetching current version failed: ${error.message}');
      return ExitCode.software.code;
    }

    late final String latestVersion;
    try {
      latestVersion = await quicuiVersion.fetchLatestGitHash();
    } on ProcessException catch (error) {
      updateCheckProgress.fail();
      logger.err('Checking for updates failed: ${error.message}');
      return ExitCode.software.code;
    }

    updateCheckProgress.complete('Checked for updates');

    final isUpToDate = currentVersion == latestVersion;
    if (isUpToDate) {
      logger.info('Quicui is already at the latest version.');
      return ExitCode.success.code;
    }

    final updateProgress = logger.progress('Updating');

    try {
      await quicuiVersion.attemptReset(revision: latestVersion);
    } on ProcessException catch (error) {
      updateProgress.fail();
      logger.err('Updating failed: ${error.message}');
      return ExitCode.software.code;
    }

    updateProgress.complete('Updated successfully.');

    return ExitCode.success.code;
  }
}
