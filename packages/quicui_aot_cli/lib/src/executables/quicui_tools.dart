import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:quicui_aot_cli/src/quicui_process.dart';

/// A reference to a [QuicuiTools] instance.
final quicuiToolsRef = create(QuicuiTools.new);

/// The [QuicuiTools] instance available in the current zone.
QuicuiTools get quicuiTools => read(quicuiToolsRef);

/// {@template package_failed_exception}
/// An exception thrown when packaging a patch fails.
/// {@endtemplate}
class PackageFailedException implements Exception {
  /// {@macro package_failed_exception}
  PackageFailedException(this.message);

  /// The error message.
  final String message;

  @override
  String toString() => message;
}

/// A wrapper around the `quicui_tools` executable.
///
/// Used to access many commands related to Quicui's flutter tooling.
class QuicuiTools {
  /// Returns whether the current flutter version supports this tool.
  ///
  /// This should be used to check if the tool is supported before running
  /// any commands.
  bool isSupported() {
    return quicuiToolsDirectory.existsSync();
  }

  /// The directory containing the `quicui_tools` package.
  Directory get quicuiToolsDirectory {
    final dir = Directory(
      p.join(quicuiEnv.flutterDirectory.path, 'packages', 'quicui_tools'),
    );
    return dir;
  }

  Future<QuicuiProcessResult> _run(List<String> args) {
    return process.run(
      quicuiEnv.dartBinaryFile.path,
      ['run', 'quicui_tools', 'package', ...args],
      workingDirectory: quicuiToolsDirectory.path,
    );
  }

  /// Creates a package with the [patchPath] and writes it to [outputPath].
  ///
  /// Packages contains all the information needed by Quicui for an update.
  Future<void> package({
    required String patchPath,
    required String outputPath,
  }) async {
    final packageArguments = ['-p', patchPath, '-o', outputPath];

    final result = await _run(packageArguments);

    if (result.exitCode != ExitCode.success.code) {
      throw PackageFailedException('''
Failed to create package (exit code ${result.exitCode}).
  stdout: ${result.stdout}
  stderr: ${result.stderr}''');
    }
  }
}
