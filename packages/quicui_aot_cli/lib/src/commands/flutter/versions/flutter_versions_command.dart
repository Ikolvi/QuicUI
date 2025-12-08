import 'package:quicui_aot_cli/src/commands/commands.dart';
import 'package:quicui_aot_cli/src/quicui_command.dart';

/// {@template flutter_versions_command}
/// `quicui flutter versions`
/// Manage your Quicui Flutter versions.
/// {@endtemplate}
class FlutterVersionsCommand extends QuicuiCommand {
  /// {@macro flutter_versions_command}
  FlutterVersionsCommand() {
    addSubcommand(FlutterVersionsListCommand());
  }

  @override
  String get description => 'Manage your Quicui Flutter versions.';

  @override
  String get name => 'versions';
}
