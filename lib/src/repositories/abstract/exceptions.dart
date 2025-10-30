/// Base exception for data source operations
class DataSourceException implements Exception {
  /// Error message
  final String message;

  /// Whether this error is retryable (transient)
  final bool isRetryable;

  /// Original exception (if any)
  final Object? originalException;

  /// Stack trace (if available)
  final StackTrace? stackTrace;

  DataSourceException(
    this.message, {
    this.isRetryable = true,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => 'DataSourceException: $message';
}

/// Screen not found exception
class ScreenNotFoundException extends DataSourceException {
  /// The screen ID that was not found
  final String screenId;

  ScreenNotFoundException(this.screenId)
      : super(
          'Screen not found: $screenId',
          isRetryable: false,
        );
}

/// Data source authentication error exception
class DataSourceAuthException extends DataSourceException {
  /// The specific auth error
  final String authError;

  DataSourceAuthException(this.authError)
      : super(
          'Data source authentication failed: $authError',
          isRetryable: false,
        );
}

/// Data source authorization error exception
class DataSourceAuthorizationException extends DataSourceException {
  /// The specific auth error
  final String authError;

  DataSourceAuthorizationException(this.authError)
      : super(
          'Data source authorization failed: $authError',
          isRetryable: false,
        );
}

/// Network connectivity exception
class DataSourceNetworkException extends DataSourceException {
  DataSourceNetworkException(String message)
      : super(
          message,
          isRetryable: true,
        );
}

/// Timeout exception
class DataSourceTimeoutException extends DataSourceException {
  /// Duration that timed out
  final Duration duration;

  DataSourceTimeoutException(this.duration)
      : super(
          'Data source operation timed out after ${duration.inSeconds}s',
          isRetryable: true,
        );
}

/// Sync conflict exception
class SyncConflictException extends DataSourceException {
  /// The conflicting screen ID
  final String screenId;

  SyncConflictException(this.screenId)
      : super(
          'Sync conflict for screen: $screenId',
          isRetryable: false,
        );
}

/// Invalid state exception
class DataSourceInvalidStateException extends DataSourceException {
  DataSourceInvalidStateException(String message)
      : super(
          message,
          isRetryable: false,
        );
}
