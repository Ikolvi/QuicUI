/// QuicUI Code Push Exceptions

/// Base exception for all QuicUI errors
class QuicUIException implements Exception {
  final String message;
  final String? code;
  
  const QuicUIException(this.message, {this.code});
  
  @override
  String toString() => 'QuicUIException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception thrown when quicui.yaml configuration file is missing
class QuicUIConfigNotFoundException extends QuicUIException {
  QuicUIConfigNotFoundException([String? path])
      : super(
          'quicui.yaml configuration file not found${path != null ? ' at: $path' : ''}.\n'
          'Run "quicui init" to create the configuration file.',
          code: 'CONFIG_NOT_FOUND',
        );
}

/// Exception thrown when quicui.yaml is invalid or has missing required fields
class QuicUIConfigInvalidException extends QuicUIException {
  final List<String> missingFields;
  
  QuicUIConfigInvalidException(String message, {this.missingFields = const []})
      : super(
          'Invalid quicui.yaml configuration: $message'
          '${missingFields.isNotEmpty ? '\nMissing required fields: ${missingFields.join(", ")}' : ''}',
          code: 'CONFIG_INVALID',
        );
}

/// Exception thrown when server URL is not configured
class QuicUIServerUrlMissingException extends QuicUIException {
  QuicUIServerUrlMissingException()
      : super(
          'Server URL not configured in quicui.yaml.\n'
          'Add server.url to your quicui.yaml file.',
          code: 'SERVER_URL_MISSING',
        );
}

/// Exception thrown when API key is not configured
class QuicUIApiKeyMissingException extends QuicUIException {
  QuicUIApiKeyMissingException()
      : super(
          'API key not configured.\n'
          'Set QUICUI_API_KEY environment variable or add server.api_key to quicui.yaml.',
          code: 'API_KEY_MISSING',
        );
}

/// Exception thrown when app ID is not configured
class QuicUIAppIdMissingException extends QuicUIException {
  QuicUIAppIdMissingException()
      : super(
          'App ID not configured in quicui.yaml.\n'
          'Add app.id to your quicui.yaml file.',
          code: 'APP_ID_MISSING',
        );
}

/// Exception thrown when patch download or installation fails
class QuicUIPatchException extends QuicUIException {
  QuicUIPatchException(String message)
      : super(message, code: 'PATCH_ERROR');
}

/// Exception thrown when SDK is not compatible
class QuicUISDKIncompatibleException extends QuicUIException {
  QuicUISDKIncompatibleException()
      : super(
          'QuicUI Code Push requires the modified Flutter SDK.\n'
          'Standard Flutter SDK detected - Code Push features are disabled.\n'
          'See: https://github.com/Ikolvi/QuicUIFlutterSDK for installation.',
          code: 'SDK_INCOMPATIBLE',
        );
}
