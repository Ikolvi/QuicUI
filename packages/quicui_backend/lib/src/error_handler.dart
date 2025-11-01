/// ErrorHandler - Standardized Error Response Format
///
/// Provides standardized error responses across all endpoints:
/// - Consistent error format with code, message, status, timestamp, trace_id
/// - Stack trace hiding for production
/// - Error categorization and logging
/// - User-friendly error messages
///
/// Security fixes:
/// - Prevents information leakage through error messages
/// - Hides internal stack traces
/// - Standardizes error responses

import 'dart:convert';
import 'package:shelf/shelf.dart';

/// Error severity levels
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}

/// Error categories
enum ErrorCategory {
  validation,
  authentication,
  authorization,
  notFound,
  conflict,
  rateLimit,
  server,
  unknown,
}

/// Standardized error response
class ErrorResponse {
  final String code;
  final String message;
  final int status;
  final String traceId;
  final DateTime timestamp;
  final String? details;
  final Map<String, dynamic>? metadata;
  final ErrorSeverity severity;
  final ErrorCategory category;

  ErrorResponse({
    required this.code,
    required this.message,
    required this.status,
    required this.traceId,
    DateTime? timestamp,
    this.details,
    this.metadata,
    this.severity = ErrorSeverity.medium,
    this.category = ErrorCategory.unknown,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON response body
  String toJson() => jsonEncode(toMap());

  /// Convert to map for JSON serialization
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'error': {
        'code': code,
        'message': message,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
        'trace_id': traceId,
      },
    };

    // Add optional fields only if they exist
    if (details != null && details!.isNotEmpty) {
      map['error']['details'] = details;
    }

    if (metadata != null && metadata!.isNotEmpty) {
      map['error']['metadata'] = metadata;
    }

    return map;
  }

  /// Create HTTP Response
  Response toResponse() {
    return Response(
      status,
      headers: {
        'content-type': 'application/json',
        'X-Trace-ID': traceId,
      },
      body: toJson(),
    );
  }

  @override
  String toString() =>
      'ErrorResponse($code: $message, status: $status, traceId: $traceId)';
}

/// Main ErrorHandler service
class ErrorHandler {
  final bool hideStackTraces;
  final bool logErrors;
  final Function(ErrorResponse)? onError;

  ErrorHandler({
    this.hideStackTraces = true,
    this.logErrors = true,
    this.onError,
  });

  /// Generate unique trace ID
  static String generateTraceId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${(DateTime.now().microsecond).toString().padLeft(6, '0')}';
  }

  /// Handle validation error
  ErrorResponse validationError({
    required String message,
    String? details,
    Map<String, dynamic>? metadata,
  }) {
    final response = ErrorResponse(
      code: 'VALIDATION_ERROR',
      message: message,
      status: 400,
      traceId: generateTraceId(),
      details: details,
      metadata: metadata,
      severity: ErrorSeverity.low,
      category: ErrorCategory.validation,
    );

    _logError(response);
    onError?.call(response);
    return response;
  }

  /// Handle authentication error
  ErrorResponse authenticationError({
    required String message,
    String code = 'AUTHENTICATION_ERROR',
    String? details,
  }) {
    final response = ErrorResponse(
      code: code,
      message: message,
      status: 401,
      traceId: generateTraceId(),
      details: details,
      severity: ErrorSeverity.medium,
      category: ErrorCategory.authentication,
    );

    _logError(response);
    onError?.call(response);
    return response;
  }

  /// Handle authorization error
  ErrorResponse authorizationError({
    required String message,
    String? details,
  }) {
    final response = ErrorResponse(
      code: 'AUTHORIZATION_ERROR',
      message: message,
      status: 403,
      traceId: generateTraceId(),
      details: details,
      severity: ErrorSeverity.medium,
      category: ErrorCategory.authorization,
    );

    _logError(response);
    onError?.call(response);
    return response;
  }

  /// Handle not found error
  ErrorResponse notFoundError({
    required String resource,
    String? details,
  }) {
    final response = ErrorResponse(
      code: 'NOT_FOUND',
      message: 'Resource not found: $resource',
      status: 404,
      traceId: generateTraceId(),
      details: details,
      severity: ErrorSeverity.low,
      category: ErrorCategory.notFound,
    );

    _logError(response);
    onError?.call(response);
    return response;
  }

  /// Handle conflict error
  ErrorResponse conflictError({
    required String message,
    String? details,
    Map<String, dynamic>? metadata,
  }) {
    final response = ErrorResponse(
      code: 'CONFLICT',
      message: message,
      status: 409,
      traceId: generateTraceId(),
      details: details,
      metadata: metadata,
      severity: ErrorSeverity.low,
      category: ErrorCategory.conflict,
    );

    _logError(response);
    onError?.call(response);
    return response;
  }

  /// Handle rate limit error
  ErrorResponse rateLimitError({
    required String message,
    required int retryAfter,
    String? details,
  }) {
    final response = ErrorResponse(
      code: 'RATE_LIMIT_EXCEEDED',
      message: message,
      status: 429,
      traceId: generateTraceId(),
      details: details,
      metadata: {'retry_after': retryAfter},
      severity: ErrorSeverity.medium,
      category: ErrorCategory.rateLimit,
    );

    _logError(response);
    onError?.call(response);
    return response;
  }

  /// Handle server error
  ErrorResponse serverError({
    required String message,
    String? details,
    Exception? exception,
    StackTrace? stackTrace,
  }) {
    // Hide stack trace details in production
    String? detailsToShow = details;
    if (!hideStackTraces && exception != null && stackTrace != null) {
      detailsToShow =
          '${exception.toString()}\n${stackTrace.toString().split('\n').take(5).join('\n')}';
    }

    final response = ErrorResponse(
      code: 'INTERNAL_SERVER_ERROR',
      message: message,
      status: 500,
      traceId: generateTraceId(),
      details: detailsToShow,
      severity: ErrorSeverity.high,
      category: ErrorCategory.server,
    );

    _logError(response);
    onError?.call(response);
    return response;
  }

  /// Handle generic error
  ErrorResponse genericError({
    required String code,
    required String message,
    required int status,
    String? details,
    Map<String, dynamic>? metadata,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) {
    final response = ErrorResponse(
      code: code,
      message: message,
      status: status,
      traceId: generateTraceId(),
      details: details,
      metadata: metadata,
      severity: severity,
    );

    _logError(response);
    onError?.call(response);
    return response;
  }

  /// Create middleware for error handling
  Middleware createMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        try {
          return await innerHandler(request);
        } on FormatException catch (e) {
          final error = validationError(
            message: 'Invalid request format',
            details: e.message,
          );
          return error.toResponse();
        } catch (e, stack) {
          final error = serverError(
            message: 'An unexpected error occurred',
            exception: e as Exception,
            stackTrace: stack,
          );
          return error.toResponse();
        }
      };
    };
  }

  /// Log error (can be overridden for custom logging)
  void _logError(ErrorResponse error) {
    if (!logErrors) return;

    final timestamp = error.timestamp.toIso8601String();
    final severity = error.severity.toString().split('.').last.toUpperCase();

    print(
      '[$timestamp] [$severity] [${error.code}] ${error.message} (TraceID: ${error.traceId})',
    );

    if (error.details != null && error.details!.isNotEmpty) {
      print('  Details: ${error.details}');
    }
  }
}

/// Predefined error responses for common scenarios
class ErrorResponses {
  static ErrorResponse invalidJson(String traceId) => ErrorResponse(
    code: 'INVALID_JSON',
    message: 'Request body is not valid JSON',
    status: 400,
    traceId: traceId,
    severity: ErrorSeverity.low,
    category: ErrorCategory.validation,
  );

  static ErrorResponse missingField(String field, String traceId) =>
      ErrorResponse(
        code: 'MISSING_FIELD',
        message: 'Required field missing: $field',
        status: 400,
        traceId: traceId,
        severity: ErrorSeverity.low,
        category: ErrorCategory.validation,
      );

  static ErrorResponse invalidField(String field, String reason, String traceId) =>
      ErrorResponse(
        code: 'INVALID_FIELD',
        message: 'Invalid value for field: $field',
        status: 400,
        traceId: traceId,
        details: reason,
        severity: ErrorSeverity.low,
        category: ErrorCategory.validation,
      );

  static ErrorResponse invalidToken(String traceId) => ErrorResponse(
    code: 'INVALID_TOKEN',
    message: 'Authentication token is invalid or expired',
    status: 401,
    traceId: traceId,
    severity: ErrorSeverity.medium,
    category: ErrorCategory.authentication,
  );

  static ErrorResponse tokenExpired(String traceId) => ErrorResponse(
    code: 'TOKEN_EXPIRED',
    message: 'Authentication token has expired',
    status: 401,
    traceId: traceId,
    severity: ErrorSeverity.medium,
    category: ErrorCategory.authentication,
  );

  static ErrorResponse noPermission(String traceId) => ErrorResponse(
    code: 'NO_PERMISSION',
    message: 'You do not have permission to access this resource',
    status: 403,
    traceId: traceId,
    severity: ErrorSeverity.medium,
    category: ErrorCategory.authorization,
  );

  static ErrorResponse resourceNotFound(String resource, String traceId) =>
      ErrorResponse(
        code: 'RESOURCE_NOT_FOUND',
        message: 'The requested resource does not exist: $resource',
        status: 404,
        traceId: traceId,
        severity: ErrorSeverity.low,
        category: ErrorCategory.notFound,
      );

  static ErrorResponse methodNotAllowed(String method, String traceId) =>
      ErrorResponse(
        code: 'METHOD_NOT_ALLOWED',
        message: 'HTTP method $method is not allowed for this resource',
        status: 405,
        traceId: traceId,
        severity: ErrorSeverity.low,
        category: ErrorCategory.unknown,
      );

  static ErrorResponse resourceAlreadyExists(String resource, String traceId) =>
      ErrorResponse(
        code: 'RESOURCE_ALREADY_EXISTS',
        message: 'The requested resource already exists: $resource',
        status: 409,
        traceId: traceId,
        severity: ErrorSeverity.low,
        category: ErrorCategory.conflict,
      );

  static ErrorResponse rateLimitExceeded(String tier, int retryAfter, String traceId) =>
      ErrorResponse(
        code: 'RATE_LIMIT_EXCEEDED',
        message: 'Too many requests. Please retry after $retryAfter seconds',
        status: 429,
        traceId: traceId,
        metadata: {
          'tier': tier,
          'retry_after': retryAfter,
        },
        severity: ErrorSeverity.medium,
        category: ErrorCategory.rateLimit,
      );

  static ErrorResponse serverError(String message, String traceId) =>
      ErrorResponse(
        code: 'INTERNAL_SERVER_ERROR',
        message: message,
        status: 500,
        traceId: traceId,
        severity: ErrorSeverity.high,
        category: ErrorCategory.server,
      );

  static ErrorResponse serviceUnavailable(String traceId) => ErrorResponse(
    code: 'SERVICE_UNAVAILABLE',
    message: 'Service is temporarily unavailable. Please try again later',
    status: 503,
    traceId: traceId,
    severity: ErrorSeverity.high,
    category: ErrorCategory.server,
  );
}
