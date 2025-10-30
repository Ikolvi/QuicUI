/// Logging utilities for QuicUI framework
///
/// This module provides centralized logging functionality through a wrapper
/// around the `package:logger` library. Enables consistent, formatted logging
/// throughout the QuicUI application with support for multiple severity levels.
///
/// ## Architecture
///
/// ```
/// LoggerUtil (Singleton pattern)
///   ├→ debug(): Development-level logs
///   ├→ info(): General information logs
///   ├→ warning(): Warning messages
///   └→ error(): Error messages with stack traces
///        └→ Backed by package:logger
/// ```
///
/// ## Log Levels
///
/// The logger supports four severity levels (highest to lowest):
/// 1. **error**: Critical issues, exceptions, failures
/// 2. **warning**: Potential problems, deprecated usage
/// 3. **info**: Important events, state changes
/// 4. **debug**: Detailed diagnostic information
///
/// ## Usage Examples
///
/// ### Basic Logging
/// ```dart
/// import 'package:quicui/src/utils/logger_util.dart';
///
/// // Information
/// LoggerUtil.info('User logged in successfully');
///
/// // Warning
/// LoggerUtil.warning('API response time exceeded 3 seconds');
///
/// // Debug (during development)
/// LoggerUtil.debug('Loading configuration from cache');
/// ```
///
/// ### Error Logging
/// ```dart
/// try {
///   fetchData();
/// } catch (e, stackTrace) {
///   LoggerUtil.error('Failed to fetch data', e, stackTrace);
/// }
/// ```
///
/// ### Debug with Context
/// ```dart
/// LoggerUtil.debug('Widget rendering', {
///   'duration_ms': 125,
///   'widgets_count': 42
/// });
/// ```
///
/// ## Output Format
///
/// The logger produces formatted output with timestamps and color coding:
/// ```
/// [DEBUG] Loading configuration from cache
/// [INFO]  User logged in successfully
/// [WARN]  API response time exceeded 3 seconds
/// [ERROR] Failed to fetch data: SocketException
///         at SupabaseService.fetchScreens (supabase_service.dart:234)
/// ```
///
/// ## Common Patterns
///
/// ### API Call Logging
/// ```dart
/// LoggerUtil.debug('Fetching screens from server');
/// try {
///   final screens = await repository.listScreens();
///   LoggerUtil.info('Retrieved ${screens.length} screens');
/// } catch (e) {
///   LoggerUtil.error('Screen fetch failed', e);
/// }
/// ```
///
/// ### State Changes
/// ```dart
/// LoggerUtil.info('State changed: Loading → Loaded');
/// ```
///
/// ### Performance Monitoring
/// ```dart
/// final startTime = DateTime.now();
/// await process();
/// final duration = DateTime.now().difference(startTime);
/// LoggerUtil.debug('Process completed in ${duration.inMilliseconds}ms');
/// ```
///
/// ## Best Practices
///
/// - **Use appropriate levels**: Don't log everything at INFO level
/// - **Include context**: Add relevant data to understand the context
/// - **Debug in development**: Use debug() for local investigation only
/// - **Production safety**: Error and warning logs go to production
/// - **Avoid sensitive data**: Don't log passwords, tokens, or PII
///
/// ## Configuration
///
/// The underlying logger can be configured through `package:logger` settings.
/// Default configuration provides colored, timestamped output suitable for
/// both development and production environments.
///
/// See also:
/// - [extensions]: String and collection utilities
/// - [validators]: Data validation helpers
/// - [package:logger](https://pub.dev/packages/logger): Logger library


import 'package:logger/logger.dart';

/// Global logger instance
///
/// Singleton instance of the Logger class from `package:logger`.
/// Used by all [LoggerUtil] methods to perform actual logging.
///
/// ## Note
/// Direct usage is discouraged. Use [LoggerUtil] methods instead for
/// consistent logging patterns across the application.
final log = Logger();

/// Centralized logging utility for QuicUI applications
///
/// Provides static methods for consistent, structured logging with
/// support for multiple severity levels. Acts as a facade over
/// `package:logger` to ensure uniform logging patterns.
///
/// ## Singleton Pattern
/// All methods are static, making this a de-facto singleton.
/// No instantiation needed.
///
/// ## Log Levels Supported
/// - **debug**: Development diagnostics
/// - **info**: General information
/// - **warning**: Potential issues
/// - **error**: Critical failures
///
/// ## Usage
/// ```dart
/// LoggerUtil.info('Application started');
/// LoggerUtil.debug('Initializing services');
/// LoggerUtil.warning('Cache miss detected');
/// LoggerUtil.error('Network timeout', exception, stackTrace);
/// ```
///
/// ## Thread Safety
/// All methods are thread-safe. Safe to call from multiple isolates.
class LoggerUtil {
  /// Log a debug message
  ///
  /// Used for detailed diagnostic information during development.
  /// Typically disabled or filtered in production builds.
  ///
  /// ## Parameters
  /// - [message]: The debug message to log (required)
  /// - [error]: Optional error object for context
  /// - [stackTrace]: Optional stack trace for error context
  ///
  /// ## Returns
  /// void (asynchronous logging, doesn't block)
  ///
  /// ## Example
  /// ```dart
  /// LoggerUtil.debug('Rendering widget tree');
  /// LoggerUtil.debug('Cache hit for key', cacheData);
  /// LoggerUtil.debug('Processing user input', exception, trace);
  /// ```
  ///
  /// ## Best Practices
  /// - Use for temporary debugging during development
  /// - Include relevant context in the message
  /// - Remove or disable before release
  /// - Stack trace optional, included when exception occurs
  ///
  /// ## Performance
  /// Minimal impact in release builds (typically compiled out)
  ///
  /// See also:
  /// - [info]: For general information logging
  /// - [warning]: For potential problems
  /// - [error]: For critical failures
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    log.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log an informational message
  ///
  /// Used for general information about application flow and important
  /// events. These logs are typically kept in production.
  ///
  /// ## Parameters
  /// - [message]: The informational message to log (required)
  ///
  /// ## Returns
  /// void (asynchronous logging, doesn't block)
  ///
  /// ## Example
  /// ```dart
  /// LoggerUtil.info('User authenticated');
  /// LoggerUtil.info('Sync completed: 15 items updated');
  /// LoggerUtil.info('Application initialized successfully');
  /// ```
  ///
  /// ## Use Cases
  /// - User actions (login, logout, etc.)
  /// - State transitions
  /// - Operation completion
  /// - Important milestones
  ///
  /// ## Message Guidelines
  /// - Use past tense (completed, changed, etc.)
  /// - Include relevant metrics
  /// - Keep concise but informative
  ///
  /// ## Production
  /// These logs are valuable for debugging issues in production.
  /// Choose important events that help trace user actions.
  ///
  /// See also:
  /// - [warning]: For potential issues
  /// - [error]: For failures
  /// - [debug]: For development diagnostics
  static void info(String message) {
    log.i(message);
  }

  /// Log a warning message
  ///
  /// Used for potentially problematic conditions that don't prevent
  /// application operation but should be investigated.
  ///
  /// ## Parameters
  /// - [message]: The warning message to log (required)
  /// - [error]: Optional error object providing additional context
  ///
  /// ## Returns
  /// void (asynchronous logging, doesn't block)
  ///
  /// ## Example
  /// ```dart
  /// LoggerUtil.warning('API response time exceeded threshold');
  /// LoggerUtil.warning('Cache size approaching limit', cacheException);
  /// LoggerUtil.warning('Deprecated API used: use newMethod() instead');
  /// ```
  ///
  /// ## Common Warning Scenarios
  /// - Performance degradation
  /// - Resource constraints
  /// - Deprecated API usage
  /// - Unusual but handled conditions
  /// - Fallback being used
  ///
  /// ## vs. Error vs. Debug
  /// - **Warning**: Handled condition needing attention
  /// - **Error**: Unhandled failure requiring action
  /// - **Debug**: Development diagnostic information
  ///
  /// ## Production Impact
  /// Warnings should not crash the app but indicate investigation needed.
  ///
  /// See also:
  /// - [error]: For failures
  /// - [info]: For general information
  /// - [debug]: For diagnostics
  static void warning(String message, [dynamic error]) {
    log.w(message, error: error);
  }

  /// Log an error message
  ///
  /// Used for error conditions and exceptions. These logs are critical
  /// for debugging and should include full context.
  ///
  /// ## Parameters
  /// - [message]: Description of the error (required)
  /// - [error]: Optional error/exception object
  /// - [stackTrace]: Optional stack trace for debugging
  ///
  /// ## Returns
  /// void (asynchronous logging, doesn't block)
  ///
  /// ## Example
  /// ```dart
  /// LoggerUtil.error('Failed to load user profile');
  /// try {
  ///   await fetchData();
  /// } catch (e, stackTrace) {
  ///   LoggerUtil.error('Network error', e, stackTrace);
  /// }
  /// ```
  ///
  /// ## Error Logging Pattern
  /// ```dart
  /// try {
  ///   final result = await operation();
  ///   return result;
  /// } catch (e, stackTrace) {
  ///   LoggerUtil.error(
  ///     'Operation failed: ${e.runtimeType}',
  ///     e,
  ///     stackTrace,
  ///   );
  ///   rethrow; // or handle gracefully
  /// }
  /// ```
  ///
  /// ## Stack Trace Importance
  /// Always include stack trace when available. It shows:
  /// - Exact location of error
  /// - Call chain leading to error
  /// - Relevant frame context
  ///
  /// ## Production Considerations
  /// - Include enough context to reproduce issue
  /// - Don't log sensitive data (passwords, tokens)
  /// - Error logs help post-mortem analysis
  ///
  /// ## Severity Escalation
  /// For critical errors affecting users:
  /// 1. Log error with full context
  /// 2. Consider reporting to crash analytics
  /// 3. Show user-friendly error message
  ///
  /// See also:
  /// - [warning]: For potential issues
  /// - [info]: For general information
  /// - [debug]: For diagnostics
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    log.e(message, error: error, stackTrace: stackTrace);
  }
}
