import 'dart:io';

import 'package:clock/clock.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';

/// A reference to a [Logger] instance.
final loggerRef = create(QuicuiLogger.new);

/// The [Logger] instance available in the current zone.
QuicuiLogger get logger => read(loggerRef);

const _logFileName = 'quicui.log';

/// Where logs are written for the current Quicui CLI run. A new file will
/// be created for every run of the Quicui CLI, and will have the name
/// `timestamp_quicui.log`.
final File currentRunLogFile = (() {
  final timestamp = clock.now().millisecondsSinceEpoch;
  final file = File(
    p.join(quicuiEnv.logsDirectory.path, '${timestamp}_$_logFileName'),
  );

  if (!file.existsSync()) {
    file.createSync(recursive: true);
  }

  return file;
})();

/// {@template quicui_logger}
/// A [Logger] that
/// {@endtemplate}
class QuicuiLogger extends Logger {
  /// {@macro quicui_logger}
  QuicuiLogger({super.level});

  @override
  void detail(String? message, {LogStyle? style}) {
    super.detail(message, style: style);
    if (level.index > Level.debug.index) {
      // We only need to write the message to the log file if this will not
      // be written to stdout. If it is written to stdout, [LoggingStdout] will
      // written to the log file.
      writeToLogFile(message ?? '', logFile: currentRunLogFile);
    }
  }
}

/// Writes the given [message] to the [logFile] on its own line, prefixed with
/// the current timestamp.
void writeToLogFile(Object? message, {required File logFile}) {
  if (message == null) {
    return;
  }

  final timestampString = DateTime.now().toIso8601String();
  final messageString = message.toString();
  logFile.writeAsStringSync(
    '$timestampString $messageString\n',
    mode: FileMode.append,
  );
}
