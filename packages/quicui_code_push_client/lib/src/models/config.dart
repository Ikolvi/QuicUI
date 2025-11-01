import 'patch_info.dart';
import 'sdk_info.dart';

/// Configuration for QuicUI code push client
class Config {
  /// API server URL (e.g., https://api.quicui.com)
  final String apiUrl;

  /// Application ID (e.g., com.example.app)
  final String appId;

  /// Client secret for authentication
  final String clientSecret;

  /// Current app version (e.g., 1.0.0)
  final String appVersion;

  /// Public key for signature verification (Ed25519)
  final String? publicKey;

  /// Maximum patch size to allow (default: 10MB)
  final int maxPatchSize;

  /// Whether to automatically check for updates on app start
  final bool autoCheckOnStart;

  /// Interval for checking updates in seconds (default: 3600 = 1 hour)
  final int checkIntervalSeconds;

  /// Maximum number of retry attempts for failed downloads
  final int maxRetries;

  /// Enable debug logging
  final bool enableDebugLogging;

  /// Callback when patch is available
  final Function(PatchInfo)? onPatchAvailable;

  /// Callback when patch download progress changes
  final Function(double)? onDownloadProgress;

  /// Callback when patch is applied
  final Function(String)? onPatchApplied;

  /// Callback when error occurs
  final Function(String)? onError;

  /// Whether to include SDK info in requests
  final bool includeSDKInfo;

  /// Cached SDK information
  final SDKInfo? sdkInfo;

  Config({
    required this.apiUrl,
    required this.appId,
    required this.clientSecret,
    required this.appVersion,
    this.publicKey,
    this.maxPatchSize = 10 * 1024 * 1024, // 10MB
    this.autoCheckOnStart = true,
    this.checkIntervalSeconds = 3600,
    this.maxRetries = 3,
    this.enableDebugLogging = false,
    this.includeSDKInfo = true,
    this.sdkInfo,
    this.onPatchAvailable,
    this.onDownloadProgress,
    this.onPatchApplied,
    this.onError,
  });

  @override
  String toString() => 'Config(appId: $appId, apiUrl: $apiUrl, appVersion: $appVersion, '
      'sdk: ${sdkInfo?.sdkStatus ?? "Not loaded"})';
}
