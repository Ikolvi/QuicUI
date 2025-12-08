import 'dart:io';

import 'package:quicui_aot_cli/src/quicui_version.dart';
import 'package:quicui_aot_cli/src/validators/validators.dart';

/// Verifies that the currently installed version of Quicui is the latest.
class QuicuiVersionValidator extends Validator {
  /// Creates a new [QuicuiVersionValidator].
  QuicuiVersionValidator();

  @override
  String get description => 'Quicui is up-to-date';

  @override
  Future<List<ValidationIssue>> validate() async {
    final bool isQuicuiUpToDate;

    try {
      isQuicuiUpToDate = await quicuiVersion.isLatest();
    } on ProcessException catch (e) {
      return [
        ValidationIssue(
          severity: ValidationIssueSeverity.error,
          message: 'Failed to get quicui version. Error: ${e.message}',
        ),
      ];
    }

    if (!isQuicuiUpToDate) {
      return [
        const ValidationIssue(
          severity: ValidationIssueSeverity.warning,
          message: '''
A new version of quicui is available! Run `quicui upgrade` to upgrade.''',
        ),
      ];
    }

    return [];
  }
}
