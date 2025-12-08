import 'package:quicui_aot_cli/src/commands/commands.dart';
import 'package:quicui_aot_cli/src/quicui_command.dart';

/// {@template flutter_command}
/// `quicui flutter`
/// Manage your Quicui Flutter installation.
/// {@endtemplate}
class FlutterCommand extends QuicuiCommand {
  /// {@macro flutter_command}
  FlutterCommand() {
    addSubcommand(FlutterVersionsCommand());
    addSubcommand(FlutterConfigCommand());
  }

  @override
  String get description => 'Manage your Quicui Flutter installation.';

  @override
  String get name => 'flutter';
}
