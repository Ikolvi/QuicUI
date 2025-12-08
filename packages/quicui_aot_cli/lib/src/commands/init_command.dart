import 'dart:io';

import 'package:collection/collection.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:quicui_aot_cli/src/code_push_client_wrapper.dart';
import 'package:quicui_aot_cli/src/config/config.dart';
import 'package:quicui_aot_cli/src/doctor.dart';
import 'package:quicui_aot_cli/src/executables/executables.dart';
import 'package:quicui_aot_cli/src/logging/logging.dart';
import 'package:quicui_aot_cli/src/platform/platform.dart';
import 'package:quicui_aot_cli/src/pubspec_editor.dart';
import 'package:quicui_aot_cli/src/quicui_command.dart';
import 'package:quicui_aot_cli/src/quicui_documentation.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:quicui_aot_cli/src/quicui_validator.dart';
import 'package:quicui_aot_code_push_client/quicui_aot_code_push_client.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// {@template init_command}
///
/// `quicui init`
/// Initialize Quicui.
/// {@endtemplate}
class InitCommand extends QuicuiCommand {
  /// {@macro init_command}
  InitCommand() {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Initialize the app even if a "quicui.yaml" already exists.',
        negatable: false,
      )
      ..addOption('display-name', help: 'The display name of the app.')
      ..addOption('organization-id', help: 'The organization ID to use.');
  }

  @override
  String get description => 'Initialize Quicui.';

  @override
  String get name => 'init';

  @override
  Future<int> run() async {
    try {
      await quicuiValidator.validatePreconditions(
        checkUserIsAuthenticated: true,
      );
    } on PreconditionFailedException catch (e) {
      return e.exitCode.code;
    }

    try {
      if (!quicuiEnv.hasPubspecYaml) {
        logger.err('''
Could not find a "pubspec.yaml".
Please make sure you are running "quicui init" from within your Flutter project.
''');
        return ExitCode.noInput.code;
      }
    } on Exception catch (error) {
      logger.err('Error parsing "pubspec.yaml": $error');
      return ExitCode.software.code;
    }

    final organizationMemberships = await codePushClientWrapper
        .getOrganizationMemberships();
    if (organizationMemberships.isEmpty) {
      logger.err(
        '''You do not have any organizations. This should never happen. Please contact us on Discord or send us an email at contact@quicui.dev.''',
      );
      return ExitCode.software.code;
    }

    final Organization organization;
    final orgIdArg = results['organization-id'] as String?;
    if (orgIdArg != null) {
      final orgId = int.tryParse(orgIdArg);
      if (orgId == null) {
        logger.err('Invalid organization ID: "$orgIdArg"');
        return ExitCode.usage.code;
      }

      final organizationMembership = organizationMemberships.firstWhereOrNull(
        (o) => o.organization.id == orgId,
      );
      if (organizationMembership == null) {
        logger.err('Organization with ID "$orgId" not found.');
        return ExitCode.usage.code;
      }
      organization = organizationMembership.organization;
    } else if (organizationMemberships.length > 1) {
      organization = logger.chooseOne(
        'Which organization should this app belong to?',
        choices: organizationMemberships.map((o) => o.organization).toList(),
        display: (o) => o.name,
      );
    } else {
      organization = organizationMemberships.first.organization;
    }

    final force = results['force'] == true;

    Set<String>? androidFlavors;
    Set<String>? iosFlavors;
    Set<String>? macosFlavors;
    var productFlavors = <String>{};
    final projectRoot = quicuiEnv.getFlutterProjectRoot()!;
    final initializeGradleProgress = logger.progress('Initializing gradlew');
    final bool shouldStartGradleDaemon;
    try {
      shouldStartGradleDaemon = await _shouldStartGradleDaemon(
        projectRoot.path,
      );
    } on Exception {
      initializeGradleProgress.fail();
      logger.err('Unable to initialize gradlew.');
      return ExitCode.software.code;
    }
    initializeGradleProgress.complete();

    if (shouldStartGradleDaemon) {
      try {
        await gradlew.startDaemon(projectRoot.path);
      } on Exception {
        logger.err('Unable to start gradle daemon.');
        return ExitCode.software.code;
      }
    }

    final detectFlavorsProgress = logger.progress('Detecting product flavors');
    try {
      androidFlavors = await _maybeGetAndroidFlavors(projectRoot.path);
      iosFlavors = apple.flavors(platform: ApplePlatform.ios);
      macosFlavors = apple.flavors(platform: ApplePlatform.macos);
      productFlavors = <String>{
        if (androidFlavors != null) ...androidFlavors,
        if (iosFlavors != null) ...iosFlavors,
        if (macosFlavors != null) ...macosFlavors,
      };
      if (productFlavors.isEmpty) {
        detectFlavorsProgress.complete('No product flavors detected.');
      } else {
        detectFlavorsProgress.complete(
          '${productFlavors.length} product flavors detected:',
        );
        for (final flavor in productFlavors) {
          logger.info('  - $flavor');
        }
      }
    } on Exception catch (error) {
      detectFlavorsProgress.fail();
      logger.err('Unable to extract product flavors.\n$error');
      return ExitCode.software.code;
    }

    final quicuiYaml = quicuiEnv.getQuicuiYaml();
    final existingFlavors = quicuiYaml?.flavors;
    Set<String> newFlavors;
    if (existingFlavors != null) {
      final existingFlavorNames = existingFlavors.keys.toSet();
      newFlavors = productFlavors.difference(existingFlavorNames);
    } else {
      newFlavors = {};
    }

    // New flavors not being empty means that we have existing flavors, which
    // means that there is already an existing app.
    // If the --force flag is present, we will completely reinit the app and
    // don't care about which flavors are new.
    if (!force && newFlavors.isNotEmpty) {
      logger.info('New flavors detected: ${newFlavors.join(', ')}');
      final updateQuicuiYamlProgress = logger.progress(
        'Adding flavors to quicui.yaml',
      );

      final AppMetadata existingApp;
      try {
        existingApp = await codePushClientWrapper.getApp(
          appId: quicuiYaml!.appId,
        );
      } on Exception catch (e) {
        updateQuicuiYamlProgress.fail('Failed to get existing app info: $e');
        return ExitCode.software.code;
      }

      final deflavoredAppName = existingApp.displayName
          .replaceAll(RegExp(r'\(.*\)'), '')
          .trim();
      final flavorsToAppIds = quicuiYaml.flavors!;
      for (final flavor in newFlavors) {
        final app = await codePushClientWrapper.createApp(
          appName: '$deflavoredAppName ($flavor)',
          organizationId: organization.id,
        );
        flavorsToAppIds[flavor] = app.id;
      }
      _addQuicuiYamlToProject(
        projectRoot: projectRoot,
        appId: quicuiYaml.appId,
        flavors: flavorsToAppIds,
      );
      updateQuicuiYamlProgress.complete('Flavors added to quicui.yaml');
      return ExitCode.success.code;
    }

    if (!force && quicuiEnv.hasQuicuiYaml) {
      logger
        ..err('A "quicui.yaml" file already exists and seems up-to-date.')
        ..info(
          '''If you want to reinitialize Quicui, please run ${lightCyan.wrap('quicui init --force')}.''',
        );
      return ExitCode.software.code;
    }

    final String appId;
    Map<String, String>? flavors;
    try {
      final needsConfirmation = !force && quicuiEnv.canAcceptUserInput;
      final pubspecName = quicuiEnv.getPubspecYaml()!.name;
      var displayName = results['display-name'] as String?;
      displayName ??= needsConfirmation
          ? logger.prompt(
              '${lightGreen.wrap('?')} How should we refer to this app?',
              defaultValue: pubspecName,
            )
          : pubspecName;
      final hasNoFlavors = productFlavors.isEmpty;
      final hasSomeFlavors =
          productFlavors.isNotEmpty &&
          ((androidFlavors?.isEmpty ?? false) ||
              (iosFlavors?.isEmpty ?? false));

      if (hasNoFlavors) {
        // No platforms have any flavors so we just create a single app
        // and assign it as the default.
        final app = await codePushClientWrapper.createApp(
          appName: displayName,
          organizationId: organization.id,
        );
        appId = app.id;
      } else if (hasSomeFlavors) {
        // Some platforms have flavors and some do not so we create an app
        // for the default (no flavor) and then create an app per flavor.
        final app = await codePushClientWrapper.createApp(
          appName: displayName,
          organizationId: organization.id,
        );
        appId = app.id;
        final values = <String, String>{};
        for (final flavor in productFlavors) {
          final app = await codePushClientWrapper.createApp(
            appName: '$displayName ($flavor)',
            organizationId: organization.id,
          );
          values[flavor] = app.id;
        }
        flavors = values;
      } else {
        // All platforms have flavors so we create an app per flavor
        // and assign the default to the first flavor.
        final values = <String, String>{};
        for (final flavor in productFlavors) {
          final app = await codePushClientWrapper.createApp(
            appName: '$displayName ($flavor)',
            organizationId: organization.id,
          );
          values[flavor] = app.id;
        }
        flavors = values;
        appId = flavors.values.first;
      }
    } on Exception catch (error) {
      logger.err('$error');
      return ExitCode.software.code;
    }

    _addQuicuiYamlToProject(
      projectRoot: projectRoot,
      appId: appId,
      flavors: flavors,
    );

    if (!quicuiEnv.pubspecContainsQuicuiYaml) {
      pubspecEditor.addQuicuiYamlToPubspecAssets();
    }

    logger.info(
      '''

${lightGreen.wrap('🐦 Quicui initialized successfully!')}

✅ A quicui app has been created.
✅ A "quicui.yaml" has been created.
✅ The "pubspec.yaml" has been updated to include "quicui.yaml" as an asset.

Reference the following commands to get started:

📦 To create a new release use: "${lightCyan.wrap('quicui release')}".
🚀 To push an update use: "${lightCyan.wrap('quicui patch')}".
👀 To preview a release use: "${lightCyan.wrap('quicui preview')}".

For more information about Quicui, visit ${link(uri: Uri.parse('https://quicui.dev'))}''',
    );

    await doctor.runValidators(doctor.generalValidators, applyFixes: true);

    return ExitCode.success.code;
  }

  Future<bool> _shouldStartGradleDaemon(String projectPath) async {
    try {
      final isAvailable = await gradlew.isDaemonAvailable(projectPath);
      return !isAvailable;
    } on MissingAndroidProjectException {
      return false;
    }
  }

  Future<Set<String>?> _maybeGetAndroidFlavors(String projectPath) async {
    try {
      return await gradlew.productFlavors(projectPath);
    } on MissingAndroidProjectException {
      return null;
    }
  }

  QuicuiYaml _addQuicuiYamlToProject({
    required String appId,
    required Directory projectRoot,
    Map<String, String>? flavors,
  }) {
    const content =
        '''
# This file is used to configure the Quicui updater used by your app.
# Learn more at $docsUrl
# This file does not contain any sensitive information and should be checked into version control.

# Your app_id is the unique identifier assigned to your app.
# It is used to identify your app when requesting patches from Quicui's servers.
# It is not a secret and can be shared publicly.
app_id:

# auto_update controls if Quicui should automatically update in the background on launch.
# If auto_update: false, you will need to use package:quicui_code_push to trigger updates.
# https://pub.dev/packages/quicui_code_push
# Uncomment the following line to disable automatic updates.
# auto_update: false
''';

    final editor = YamlEditor(content)..update(['app_id'], appId);

    if (flavors != null) editor.update(['flavors'], flavors);

    quicuiEnv
        .getQuicuiYamlFile(cwd: projectRoot)
        .writeAsStringSync(editor.toString());

    return QuicuiYaml(appId: appId);
  }
}
