import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:quicui_aot_cli/src/android_sdk.dart';
import 'package:quicui_aot_cli/src/android_studio.dart';
import 'package:quicui_aot_cli/src/doctor.dart';
import 'package:quicui_aot_cli/src/executables/executables.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/network_checker.dart';
import 'package:quicui_aot_cli/src/quicui_command.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:quicui_aot_cli/src/quicui_flutter.dart';
import 'package:quicui_aot_cli/src/version.dart';

/// {@template doctor_command}
/// `quicui doctor`
/// A command that checks for potential issues with the current quicui
/// environment.
/// {@endtemplate}
class DoctorCommand extends QuicuiCommand {
  /// {@macro doctor_command}
  DoctorCommand() {
    argParser
      ..addFlag(
        'fix',
        abbr: 'f',
        help: 'Fix issues where possible.',
        negatable: false,
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Enable verbose output.',
        negatable: false,
      );
  }

  @override
  String get name => 'doctor';

  @override
  String get description => 'Show information about the installed tooling.';

  @override
  Future<int> run() async {
    final verbose = results['verbose'] == true;
    final shouldFix = results['fix'] == true;
    final flutterVersion = await _tryGetFlutterVersion();
    final output = StringBuffer();
    final quicuiFlutterPrefix = StringBuffer('Flutter');

    if (flutterVersion != null) {
      quicuiFlutterPrefix.write(' $flutterVersion');
    }
    output.writeln('''
Quicui $packageVersion • git@github.com:quicuitech/quicui.git
$quicuiFlutterPrefix • revision ${quicuiEnv.flutterRevision}
Engine • revision ${quicuiEnv.quicuiEngineRevision}''');

    if (verbose) {
      final notDetected = red.wrap('not detected');
      var javaVersion = notDetected;

      final javaExe = java.executable;
      if (javaExe != null) {
        final result = java.version;
        if (result != null) {
          javaVersion = result
              .split(Platform.lineTerminator)
              // Adds empty space to the version will be padded with the
              // JAVA_VERSION label.
              .join('${Platform.lineTerminator}                  ');
        }
      }

      String? gradlewVersion;
      if (gradlew.exists(Directory.current.path)) {
        gradlewVersion = await gradlew.version(Directory.current.path);
      }

      output.writeln('''

Logs: ${quicuiEnv.logsDirectory.path}
Android Toolchain
  • Android Studio: ${androidStudio.path ?? notDetected}
  • Android SDK: ${androidSdk.path ?? notDetected}
  • ADB: ${androidSdk.adbPath ?? notDetected}
  • JAVA_HOME: ${java.home ?? notDetected}
  • JAVA_EXECUTABLE: ${javaExe ?? notDetected}
  • JAVA_VERSION: $javaVersion
  • Gradle: ${gradlewVersion ?? notDetected}''');
    }

    logger
      ..info(output.toString())
      ..info('URL Reachability');
    await networkChecker.checkReachability();
    logger.info('');

    if (verbose) {
      logger.info('Network Speed');
      final uploadProgress = logger.progress('Measuring GCP upload speed');

      try {
        final uploadSpeed = await networkChecker.performGCPUploadSpeedTest();
        uploadProgress.complete(
          'GCP Upload Speed: ${uploadSpeed.toStringAsFixed(2)} MB/s',
        );
      } on NetworkCheckerException catch (error) {
        uploadProgress.fail('GCP upload speed test failed: ${error.message}');
      } on Exception catch (error) {
        uploadProgress.fail('GCP upload speed test failed: $error');
      }

      final downloadProgress = logger.progress('Measuring GCP download speed');

      try {
        final downloadSpeed = await networkChecker
            .performGCPDownloadSpeedTest();
        downloadProgress.complete(
          'GCP Download Speed: ${downloadSpeed.toStringAsFixed(2)} MB/s',
        );
      } on NetworkCheckerException catch (error) {
        downloadProgress.fail(
          'GCP download speed test failed: ${error.message}',
        );
      } on Exception catch (error) {
        downloadProgress.fail('GCP download speed test failed: $error');
      }
      logger.info('');
    }

    await doctor.runValidators(doctor.generalValidators, applyFixes: shouldFix);

    return ExitCode.success.code;
  }

  Future<String?> _tryGetFlutterVersion() async {
    try {
      return await quicuiFlutter.getVersionString();
    } on Exception catch (error) {
      logger.detail('Unable to determine Flutter version.\n$error');
      return null;
    }
  }
}
