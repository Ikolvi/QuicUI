import 'dart:async';

import 'package:quicui_aot_cli/src/quicui_command.dart';
import 'package:quicui_aot_cli/src/quicui_process.dart';

/// {@template flutter_config_command}
/// `quicui flutter config`
/// Manage your Quicui Flutter Config.
/// {@endtemplate}
class FlutterConfigCommand extends QuicuiProxyCommand {
  @override
  String get description =>
      '''Configure Flutter settings. This proxies to the underlying `flutter config` command.''';

  @override
  String get name => 'config';

  @override
  FutureOr<int> run() => process.stream('flutter', ['config', ...results.rest]);
}
