import 'package:json_serializable/json_serializable.dart';

part 'patch_info.g.dart';

/// Information about a code patch
@JsonSerializable()
class PatchInfo {
  /// Unique patch identifier
  final String patchId;

  /// Version of the patch
  final String version;

  /// Timestamp when patch was created
  final DateTime createdAt;

  /// Size of the patch in bytes
  final int size;

  /// Download URL for the patch
  final String downloadUrl;

  /// Ed25519 signature for verification
  final String signature;

  /// Changelog/description of the patch
  final String? changelog;

  /// Whether this patch is mandatory
  final bool mandatory;

  /// Percentage of users to receive this patch (0-100)
  final int rolloutPercentage;

  /// Minimum app version required
  final String? minAppVersion;

  /// Maximum app version allowed
  final String? maxAppVersion;

  /// Patch download completion percentage (0-100)
  int downloadProgress = 0;

  /// Current patch status
  PatchStatus status = PatchStatus.pending;

  /// Error message if patch failed
  String? errorMessage;

  PatchInfo({
    required this.patchId,
    required this.version,
    required this.createdAt,
    required this.size,
    required this.downloadUrl,
    required this.signature,
    this.changelog,
    this.mandatory = false,
    this.rolloutPercentage = 100,
    this.minAppVersion,
    this.maxAppVersion,
  });

  /// Whether this patch should be applied to current app version
  bool isApplicable(String currentAppVersion) {
    if (minAppVersion != null && _compareVersions(currentAppVersion, minAppVersion!) < 0) {
      return false;
    }
    if (maxAppVersion != null && _compareVersions(currentAppVersion, maxAppVersion!) > 0) {
      return false;
    }
    return true;
  }

  /// Compare two semantic versions
  /// Returns: -1 if v1 < v2, 0 if equal, 1 if v1 > v2
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < (parts1.length > parts2.length ? parts2.length : parts1.length); i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }

    if (parts1.length < parts2.length) return -1;
    if (parts1.length > parts2.length) return 1;
    return 0;
  }

  factory PatchInfo.fromJson(Map<String, dynamic> json) => _$PatchInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PatchInfoToJson(this);

  @override
  String toString() => 'PatchInfo(patchId: $patchId, version: $version, status: $status)';
}

/// Status of a patch
enum PatchStatus {
  pending,     // Waiting to be processed
  downloading, // Currently downloading
  verifying,   // Verifying signature
  applying,    // Applying patch to app
  completed,   // Successfully applied
  failed,      // Failed to apply
  rolled_back, // Rolled back due to errors
}
