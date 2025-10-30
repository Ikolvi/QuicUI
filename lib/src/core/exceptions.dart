/// Custom exceptions for the QuicUI framework


/// Base exception class for QuicUI
abstract class QuicUIException implements Exception {
  final String message;

  QuicUIException(this.message);

  @override
  String toString() => message;
}

/// Thrown when a network request fails
class NetworkException extends QuicUIException {
  NetworkException(String message) : super('Network Error: $message');
}

/// Thrown when a local database operation fails
class StorageException extends QuicUIException {
  StorageException(String message) : super('Storage Error: $message');
}

/// Thrown when JSON parsing or validation fails
class ParseException extends QuicUIException {
  ParseException(String message) : super('Parse Error: $message');
}

/// Thrown when a required configuration is missing
class ConfigurationException extends QuicUIException {
  ConfigurationException(String message) : super('Configuration Error: $message');
}

/// Thrown when a widget is not found or unsupported
class WidgetException extends QuicUIException {
  WidgetException(String message) : super('Widget Error: $message');
}

/// Thrown when authentication fails
class AuthenticationException extends QuicUIException {
  AuthenticationException(String message) : super('Authentication Error: $message');
}

/// Thrown when synchronization fails
class SyncException extends QuicUIException {
  SyncException(String message) : super('Sync Error: $message');
}

/// Thrown when validation fails
class ValidationException extends QuicUIException {
  ValidationException(String message) : super('Validation Error: $message');
}
