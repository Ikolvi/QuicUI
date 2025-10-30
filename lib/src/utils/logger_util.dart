/// Logger utility


import 'package:logger/logger.dart';

/// Logger instance
final log = Logger();

/// Logging utility
class LoggerUtil {
  /// Log debug message
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    log.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  static void info(String message) {
    log.i(message);
  }

  /// Log warning message
  static void warning(String message, [dynamic error]) {
    log.w(message, error: error);
  }

  /// Log error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    log.e(message, error: error, stackTrace: stackTrace);
  }
}
