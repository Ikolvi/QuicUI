import 'package:quicui_aot_cli/src/pubspec_editor.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:quicui_aot_cli/src/validators/validators.dart';

/// Verifies that the quicui.yaml is found in pubspec.yaml assets.
class QuicuiYamlAssetValidator extends Validator {
  @override
  String get description => 'quicui.yaml found in pubspec.yaml assets';

  @override
  bool canRunInCurrentContext() => quicuiEnv.hasPubspecYaml;

  @override
  String get incorrectContextMessage => '''
The pubspec.yaml file does not exist.
The command you are running must be run within a Flutter app project.''';

  @override
  Future<List<ValidationIssue>> validate() async {
    if (!canRunInCurrentContext()) {
      return [
        const ValidationIssue(
          severity: ValidationIssueSeverity.error,
          message: 'No pubspec.yaml file found',
        ),
      ];
    }

    if (quicuiEnv.pubspecContainsQuicuiYaml) {
      return [];
    }

    return [
      ValidationIssue(
        severity: ValidationIssueSeverity.error,
        message: 'No quicui.yaml found in pubspec.yaml assets',
        fix: () => pubspecEditor.addQuicuiYamlToPubspecAssets(),
      ),
    ];
  }
}
