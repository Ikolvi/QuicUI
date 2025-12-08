import 'package:quicui_aot_cli/src/commands/patches/patches.dart';
import 'package:quicui_aot_cli/src/quicui_command.dart';

/// {@template patches_command}
/// Commands for managing Quicui patches.
/// {@endtemplate}
class PatchesCommand extends QuicuiCommand {
  /// {@macro patches_command}
  PatchesCommand() {
    addSubcommand(PromoteCommand());
  }

  @override
  String get name => 'patches';

  @override
  String get description => 'Manage Quicui patches';
}
