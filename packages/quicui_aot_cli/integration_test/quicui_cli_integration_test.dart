import 'dart:convert';
import 'dart:io';

import 'package:checked_yaml/checked_yaml.dart';
import 'package:http/http.dart' as http;
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/auth/auth.dart';
import 'package:quicui_aot_cli/src/config/config.dart';
import 'package:quicui_aot_cli/src/http_client/http_client.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/platform.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:quicui_aot_code_push_client/quicui_aot_code_push_client.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

R runWithOverrides<R>(R Function() body) {
  return runScoped(
    body,
    values: {authRef, httpClientRef, loggerRef, platformRef, quicuiEnvRef},
  );
}

void main() {
  final quicuiHostedURL = Platform.environment['QUICUI_HOSTED_URL'];
  if (quicuiHostedURL == null || quicuiHostedURL.isEmpty) {
    throw Exception('QUICUI_HOSTED_URL environment variable is not set.');
  }
  final logger = Logger();
  final client = runWithOverrides(
    () => CodePushClient(
      httpClient: Auth().client,
      hostedUri: Uri.parse(quicuiHostedURL),
    ),
  );

  /// Helper function to run a command in the shell, meant to be used in tests.
  ///
  /// It will take a command string, like `quicui --version`, run it in the
  /// shell, and return the result.
  ProcessResult runCommand(
    String command, {
    required String workingDirectory,
    Logger? logger,
  }) {
    logger ??= Logger();
    final parts = command.split(' ');
    final executable = parts.first;
    final arguments = parts.skip(1).toList();
    logger.info('Running $command in $workingDirectory');
    final result = Process.runSync(
      executable,
      arguments,
      runInShell: true,
      workingDirectory: workingDirectory,
    );
    logger
      ..info('Exited with code: ${result.exitCode}')
      ..info(result.stdout.toString());
    if (result.exitCode != ExitCode.success.code) {
      logger.err(result.stderr.toString());
    }
    return result;
  }

  test('--version', () {
    final result = runCommand('quicui --version', workingDirectory: '.');
    expect(result.exitCode, equals(0));
    expect(result.stdout, stringContainsInOrder(['Engine', 'revision']));
  });

  test(
    'create an app with a release and patch',
    () async {
      final authToken = Platform.environment[quicuiTokenEnvVar];
      if (authToken == null || authToken.isEmpty) {
        throw Exception(
          '$quicuiTokenEnvVar environment variable is not set.',
        );
      }
      const releaseVersion = '1.0.0+1';
      const platform = 'android';
      const arch = 'aarch64';
      const channel = 'stable';

      final uuid = const Uuid().v4().replaceAll('-', '_');
      final testAppName = 'test_app_$uuid';
      final tempDir = Directory.systemTemp.createTempSync();
      final subDirWithSpace = Directory(
        p.join(tempDir.path, 'flutter directory'),
      )..createSync();
      var cwd = subDirWithSpace.path;

      // Create the default flutter counter app
      logger.info('running `quicui create $testAppName` in $cwd');
      final createAppResult = runCommand(
        'quicui create $testAppName',
        workingDirectory: cwd,
      );
      expect(createAppResult.exitCode, equals(0));

      cwd = p.join(cwd, testAppName);

      final quicuiYamlPath = p.join(cwd, 'quicui.yaml');
      final quicuiYamlText = File(quicuiYamlPath).readAsStringSync();
      final quicuiYaml = checkedYamlDecode(
        quicuiYamlText,
        (m) => QuicuiYaml.fromJson(m!),
      );

      // Verify that we have no releases for this app
      await expectLater(
        runWithOverrides(client.getApps),
        completion(
          contains(
            isA<AppMetadata>()
                .having((a) => a.appId, 'appId', quicuiYaml.appId)
                .having(
                  (a) => a.latestReleaseVersion,
                  'latestReleaseVersion',
                  null,
                )
                .having((a) => a.latestPatchNumber, 'latestPatchNumber', null),
          ),
        ),
      );

      // Create an Android release.
      final quicuiReleaseResult = runCommand(
        'quicui release android --verbose',
        workingDirectory: cwd,
      );
      expect(quicuiReleaseResult.exitCode, equals(0));
      expect(
        quicuiReleaseResult.stdout,
        contains('Published Release $releaseVersion!'),
      );

      // Verify that no patch is available.
      await expectLater(
        isPatchAvailable(
          appId: quicuiYaml.appId,
          releaseVersion: releaseVersion,
          platform: platform,
          arch: arch,
          channel: channel,
        ),
        completion(isFalse),
      );

      // Verify that the release was created.
      await expectLater(
        runWithOverrides(client.getApps),
        completion(
          contains(
            isA<AppMetadata>()
                .having((a) => a.appId, 'appId', quicuiYaml.appId)
                .having(
                  (a) => a.latestReleaseVersion,
                  'latestReleaseVersion',
                  releaseVersion,
                )
                .having((a) => a.latestPatchNumber, 'latestPatchNumber', null),
          ),
        ),
      );

      // Create an Android patch.
      final quicuiPatchResult = runCommand(
        'quicui patch android --verbose',
        workingDirectory: cwd,
      );
      expect(quicuiPatchResult.exitCode, equals(0));
      expect(quicuiPatchResult.stdout, contains('Published Patch 1!'));

      // Verify that the patch is available.
      await expectLater(
        isPatchAvailable(
          appId: quicuiYaml.appId,
          releaseVersion: releaseVersion,
          platform: platform,
          arch: arch,
          channel: channel,
        ),
        completion(isTrue),
      );

      // Verify that the patch was created.
      await expectLater(
        runWithOverrides(client.getApps),
        completion(
          contains(
            isA<AppMetadata>()
                .having((a) => a.appId, 'appId', quicuiYaml.appId)
                .having(
                  (a) => a.latestReleaseVersion,
                  'latestReleaseVersion',
                  '1.0.0+1',
                )
                .having((a) => a.latestPatchNumber, 'latestPatchNumber', 1),
          ),
        ),
      );

      // Delete the app to clean up after ourselves.
      await expectLater(
        runWithOverrides(() => client.deleteApp(appId: quicuiYaml.appId)),
        completes,
      );

      // Verify that the app was deleted.
      await expectLater(
        runWithOverrides(client.getApps),
        completion(
          isNot(
            contains(
              isA<AppMetadata>().having(
                (a) => a.appId,
                'appId',
                quicuiYaml.appId,
              ),
            ),
          ),
        ),
      );

      // Verify that no patch is available.
      await expectLater(
        isPatchAvailable(
          appId: quicuiYaml.appId,
          releaseVersion: releaseVersion,
          platform: platform,
          arch: arch,
          channel: channel,
        ),
        completion(isFalse),
      );
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}

Future<bool> isPatchAvailable({
  required String appId,
  required String releaseVersion,
  required String platform,
  required String arch,
  required String channel,
}) async {
  final response = await http.post(
    Uri.parse(
      Platform.environment['QUICUI_HOSTED_URL']!,
    ).replace(path: '/api/v1/patches/check'),
    body: jsonEncode({
      'release_version': releaseVersion,
      'platform': platform,
      'arch': arch,
      'app_id': appId,
      'channel': channel,
    }),
  );
  if (response.statusCode != HttpStatus.ok) {
    throw Exception('Patch Check Failure: ${response.statusCode}');
  }
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  return json['patch_available'] as bool;
}
