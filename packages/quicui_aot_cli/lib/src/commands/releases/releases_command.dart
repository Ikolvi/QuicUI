import 'package:quicui_aot_cli/src/commands/releases/releases.dart';
import 'package:quicui_aot_cli/src/quicui_command.dart';

/// {@template releases_command}
/// Commands for managing Quicui releases.
/// {@endtemplate}
class ReleasesCommand extends QuicuiCommand {
  /// {@macro releases_command}
  ReleasesCommand() {
    addSubcommand(GetApksCommand());
  }

  @override
  String get name => 'releases';

  @override
  String get description => 'Manage Quicui releases';
}
