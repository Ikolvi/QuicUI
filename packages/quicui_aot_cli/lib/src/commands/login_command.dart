import 'package:mason_logger/mason_logger.dart';
import 'package:quicui_aot_cli/src/auth/auth.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/quicui_command.dart';
import 'package:quicui_aot_code_push_protocol/quicui_aot_code_push_protocol.dart'
    as api;

/// {@template login_command}
/// `quicui login`
/// Login as a new Quicui user.
/// {@endtemplate}
class LoginCommand extends QuicuiCommand {
  /// {@macro login_command}
  LoginCommand() {
    argParser.addOption(
      'provider',
      abbr: 'p',
      allowed: api.AuthProvider.values.map((e) => e.name),
      help: 'The authentication provider to use.',
    );
  }

  @override
  String get description => 'Login as a new Quicui user.';

  @override
  String get name => 'login';

  @override
  Future<int> run() async {
    if (auth.isAuthenticated) {
      logger
        ..info('You are already logged in as <${auth.email}>.')
        ..info(
          'Run ${lightCyan.wrap('quicui logout')} to log out and try again.',
        );
      return ExitCode.success.code;
    }

    final api.AuthProvider provider;
    if (results.wasParsed('provider')) {
      provider = api.AuthProvider.values.byName(results['provider'] as String);
    } else {
      provider = logger.chooseOne(
        'Choose an auth provider',
        choices: api.AuthProvider.values,
        display: (p) => p.displayName,
      );
    }

    try {
      await auth.login(provider, prompt: prompt);
    } on UserNotFoundException catch (error) {
      final consoleUri = Uri.https('console.quicui.dev');
      logger
        ..err('''
We could not find a Quicui account for ${error.email}.''')
        ..info(
          """If you have not yet created an account, you can do so at "${link(uri: consoleUri)}". If you believe this is an error, please reach out to us via Discord, we're happy to help!""",
        );
      return ExitCode.software.code;
    } on Exception catch (error) {
      logger.err(error.toString());
      return ExitCode.software.code;
    }

    logger.info('''

🎉 ${lightGreen.wrap('Welcome to Quicui! You are now logged in as <${auth.email}>.')}

🔑 Credentials are stored in ${lightCyan.wrap(auth.credentialsFilePath)}.
🚪 To logout use: "${lightCyan.wrap('quicui logout')}".''');
    return ExitCode.success.code;
  }

  /// Prompt the user to log in.
  void prompt(String url) {
    logger.info('''
The Quicui CLI needs your authorization to manage apps, releases, and patches on your behalf.

In a browser, visit this URL to log in:

${styleBold.wrap(styleUnderlined.wrap(lightCyan.wrap(url)))}

Waiting for your authorization...''');
  }
}
