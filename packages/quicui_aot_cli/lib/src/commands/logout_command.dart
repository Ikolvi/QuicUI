import 'package:mason_logger/mason_logger.dart';
import 'package:quicui_aot_cli/src/auth/auth.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/quicui_command.dart';

/// {@template logout_command}
///
/// `quicui logout`
/// Logout of the current Quicui user.
/// {@endtemplate}
class LogoutCommand extends QuicuiCommand {
  @override
  String get description => 'Logout of the current Quicui user';

  @override
  String get name => 'logout';

  @override
  Future<int> run() async {
    if (!auth.isAuthenticated) {
      logger.info('You are already logged out.');
      return ExitCode.success.code;
    }

    final logoutProgress = logger.progress('Logging out of quicui.dev');
    auth.logout();
    logoutProgress.complete();

    logger.info('${lightGreen.wrap('You are now logged out.')}');

    return ExitCode.success.code;
  }
}
