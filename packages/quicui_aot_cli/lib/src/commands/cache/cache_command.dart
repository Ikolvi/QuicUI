import 'package:quicui_aot_cli/src/commands/commands.dart';
import 'package:quicui_aot_cli/src/quicui_command.dart';

/// {@template cache_command}
/// `quicui cache`
/// Manage the Quicui cache.
/// {@endtemplate}
class CacheCommand extends QuicuiCommand {
  /// {@macro cache_command}
  CacheCommand() {
    addSubcommand(CleanCacheCommand());
  }

  @override
  String get description => 'Manage the Quicui cache.';

  @override
  String get name => 'cache';
}
