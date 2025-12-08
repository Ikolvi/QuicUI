import 'dart:async';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/quicui_command.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:quicui_aot_cli/src/quicui_process.dart';

/// {@template quicui_create_command}
/// `quicui create`
/// Create a new Flutter app with Quicui.
/// {@endtemplate}
class CreateCommand extends QuicuiProxyCommand {
  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Flutter project with Quicui.';

  @override
  Future<int> run() async {
    final createExitCode = await process.stream('flutter', [
      'create',
      ...results.rest,
    ]);
    if (createExitCode != ExitCode.success.code) return createExitCode;
    if (results.rest.contains('-h') || results.rest.contains('--help')) {
      return createExitCode;
    }
    return runScoped(
      () => runner!.run(['init']),
      values: {
        quicuiEnvRef.overrideWith(
          () => QuicuiEnv(
            flutterProjectRootOverride: p.absolute(
              p.normalize(results.rest.first),
            ),
          ),
        ),
      },
    );
  }
}
