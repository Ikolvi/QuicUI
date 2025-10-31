/// Comprehensive error handling system for QuicUI framework
///
/// This module provides a multi-layered error handling approach that includes:
/// - Build-time JSON validation
/// - Runtime error recovery
/// - Detailed debug information
/// - User-friendly error messages
/// - Performance-optimized error reporting
///
/// ## Architecture
///
/// ```
/// ErrorHandler (Central Manager)
///   ├→ JsonValidator: Schema validation & syntax checking
///   ├→ ErrorReporter: Structured error reporting with context
///   ├→ DebugInfoCollector: Detailed debugging information
///   └→ RuntimeRecovery: Graceful error recovery mechanisms
/// ```
///
/// ## Error Categories
///
/// 1. **JSON Syntax Errors**: Invalid JSON structure
/// 2. **Schema Validation**: Missing required fields, invalid types
/// 3. **Widget Rendering**: Unsupported widgets, invalid properties
/// 4. **Runtime Errors**: Network failures, data inconsistencies
/// 5. **Build-time Validation**: Pre-compilation checks
///
/// ## Usage Examples
///
/// ### Basic Error Handling
/// ```dart
/// try {
///   final widget = UIRenderer.buildWidget(jsonData);
/// } catch (e) {
///   ErrorHandler.handleRenderingError(e, jsonData, context: {
///     'screen_id': screenId,
///     'widget_type': jsonData['type'],
///   });
/// }
/// ```
///
/// ### JSON Validation
/// ```dart
/// final validation = JsonValidator.validateWidgetJson(jsonData);
/// if (!validation.isValid) {
///   ErrorHandler.reportValidationErrors(validation.errors);
/// }
/// ```
///
/// ### Debug Information Collection
/// ```dart
/// final debugInfo = DebugInfoCollector.collect(
///   json: jsonData,
///   context: buildContext,
///   stackTrace: StackTrace.current,
/// );
/// LoggerUtil.debug('Widget build failed', debugInfo.toMap());
/// ```
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quicui/src/utils/logger_util.dart';

/// Central error handling manager for QuicUI framework
///
/// Provides comprehensive error handling with structured reporting,
/// debug information collection, and runtime recovery mechanisms.
///
/// ## Error Flow
/// 1. Error occurs in UIRenderer
/// 2. ErrorHandler captures with context
/// 3. Error is logged with detailed information
/// 4. Recovery mechanism attempts graceful fallback
/// 5. User sees appropriate error message or fallback UI
class ErrorHandler {
  /// Handle widget rendering errors with full context
  ///
  /// Captures rendering failures and provides detailed debugging information
  /// including JSON context, widget hierarchy, and runtime state.
  ///
  /// ## Parameters
  /// - [error]: The original error/exception
  /// - [jsonData]: The JSON that caused the error
  /// - [context]: Additional context information
  /// - [stackTrace]: Optional stack trace for debugging
  ///
  /// ## Returns
  /// [Widget] A fallback error widget to display to user
  ///
  /// ## Example
  /// ```dart
  /// try {
  ///   return UIRenderer.buildWidget(widgetJson);
  /// } catch (e, stackTrace) {
  ///   return ErrorHandler.handleRenderingError(
  ///     e,
  ///     widgetJson,
  ///     context: {'screen_id': screenId},
  ///     stackTrace: stackTrace,
  ///   );
  /// }
  /// ```
  static Widget handleRenderingError(
    dynamic error,
    Map<String, dynamic>? jsonData, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    final errorInfo = _collectErrorInformation(
      error: error,
      jsonData: jsonData,
      context: context,
      stackTrace: stackTrace,
    );

    // Log detailed error information
    LoggerUtil.error(
      'Widget rendering failed: ${errorInfo.summary}',
      errorInfo.toMap(),
      stackTrace,
    );

    // Return appropriate fallback widget
    return _buildErrorWidget(errorInfo);
  }

  /// Handle JSON validation errors
  ///
  /// Processes validation errors from JSON schema validation and logs
  /// detailed information for debugging.
  ///
  /// ## Parameters
  /// - [errors]: List of validation errors
  /// - [jsonData]: The JSON that failed validation
  /// - [context]: Additional context information
  static void handleValidationErrors(
    List<ValidationError> errors,
    Map<String, dynamic>? jsonData, {
    Map<String, dynamic>? context,
  }) {
    for (final error in errors) {
      final errorInfo = ValidationErrorInfo(
        error: error,
        jsonData: jsonData,
        context: context ?? {},
      );

      LoggerUtil.warning(
        'JSON validation failed: ${error.message}',
        errorInfo.toMap(),
      );
    }
  }

  /// Handle runtime errors with recovery
  ///
  /// Manages runtime errors that occur during app execution, providing
  /// recovery mechanisms and user-friendly error states.
  ///
  /// ## Parameters
  /// - [error]: The runtime error
  /// - [recoveryCallback]: Optional recovery function
  /// - [context]: Additional context information
  static Future<T?> handleRuntimeError<T>(
    dynamic error, {
    Future<T> Function()? recoveryCallback,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) async {
    final errorInfo = RuntimeErrorInfo(
      error: error,
      context: context ?? {},
      stackTrace: stackTrace,
    );

    LoggerUtil.error(
      'Runtime error occurred: ${errorInfo.summary}',
      errorInfo.toMap(),
      stackTrace,
    );

    // Attempt recovery if callback provided
    if (recoveryCallback != null) {
      try {
        LoggerUtil.debug('Attempting error recovery');
        final result = await recoveryCallback();
        LoggerUtil.info('Error recovery successful');
        return result;
      } catch (recoveryError, recoveryStackTrace) {
        LoggerUtil.error(
          'Error recovery failed',
          recoveryError,
          recoveryStackTrace,
        );
      }
    }

    return null;
  }

  /// Collect comprehensive error information
  ///
  /// Gathers detailed debugging information including JSON context,
  /// system state, and error details for comprehensive logging.
  static ErrorInformation _collectErrorInformation({
    required dynamic error,
    Map<String, dynamic>? jsonData,
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    return ErrorInformation(
      error: error,
      jsonData: jsonData,
      context: context ?? {},
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );
  }

  /// Build error fallback widget
  ///
  /// Creates appropriate error widget based on error type and debug mode.
  /// In debug mode, shows detailed error information. In release mode,
  /// shows user-friendly error message.
  static Widget _buildErrorWidget(ErrorInformation errorInfo) {
    if (kDebugMode) {
      return _DebugErrorWidget(errorInfo: errorInfo);
    } else {
      return _UserErrorWidget(errorInfo: errorInfo);
    }
  }
}

/// JSON validation utility
///
/// Provides comprehensive JSON schema validation for QuicUI widget
/// configurations with detailed error reporting.
class JsonValidator {
  /// Validate widget JSON structure
  ///
  /// Performs comprehensive validation of widget JSON including:
  /// - Required fields presence
  /// - Data type validation
  /// - Enum value validation
  /// - Nested structure validation
  ///
  /// ## Parameters
  /// - [jsonData]: The JSON data to validate
  /// - [widgetType]: Optional widget type for specific validation
  ///
  /// ## Returns
  /// [ValidationResult] containing validation status and errors
  static ValidationResult validateWidgetJson(
    Map<String, dynamic>? jsonData, {
    String? widgetType,
  }) {
    final errors = <ValidationError>[];

    if (jsonData == null) {
      errors.add(ValidationError(
        field: 'root',
        message: 'JSON data is null',
        severity: ErrorSeverity.critical,
      ));
      return ValidationResult(errors: errors);
    }

    // Validate basic structure
    _validateBasicStructure(jsonData, errors);

    // Validate widget type specific requirements
    if (widgetType != null) {
      _validateWidgetSpecific(jsonData, widgetType, errors);
    }

    // Validate nested children
    _validateChildren(jsonData, errors);

    return ValidationResult(errors: errors);
  }

  /// Validate basic JSON structure requirements
  static void _validateBasicStructure(
    Map<String, dynamic> jsonData,
    List<ValidationError> errors,
  ) {
    // Check for required 'type' field
    if (!jsonData.containsKey('type')) {
      errors.add(ValidationError(
        field: 'type',
        message: 'Widget type is required',
        severity: ErrorSeverity.critical,
      ));
    } else if (jsonData['type'] is! String) {
      errors.add(ValidationError(
        field: 'type',
        message: 'Widget type must be a string',
        severity: ErrorSeverity.critical,
      ));
    }
  }

  /// Validate widget-specific requirements
  static void _validateWidgetSpecific(
    Map<String, dynamic> jsonData,
    String widgetType,
    List<ValidationError> errors,
  ) {
    switch (widgetType.toLowerCase()) {
      case 'text':
        _validateTextField(jsonData, errors);
        break;
      case 'button':
      case 'elevatedbutton':
      case 'textbutton':
        _validateButtonField(jsonData, errors);
        break;
      case 'column':
      case 'row':
        _validateLayoutField(jsonData, errors);
        break;
      default:
        // Generic validation for unknown widgets
        break;
    }
  }

  /// Validate text widget requirements
  static void _validateTextField(
    Map<String, dynamic> jsonData,
    List<ValidationError> errors,
  ) {
    if (!jsonData.containsKey('text') && !jsonData.containsKey('data')) {
      errors.add(ValidationError(
        field: 'text',
        message: 'Text widget requires either "text" or "data" field',
        severity: ErrorSeverity.major,
      ));
    }
  }

  /// Validate button widget requirements
  static void _validateButtonField(
    Map<String, dynamic> jsonData,
    List<ValidationError> errors,
  ) {
    if (!jsonData.containsKey('text') && !jsonData.containsKey('child')) {
      errors.add(ValidationError(
        field: 'text',
        message: 'Button widget requires either "text" or "child" field',
        severity: ErrorSeverity.major,
      ));
    }
  }

  /// Validate layout widget requirements
  static void _validateLayoutField(
    Map<String, dynamic> jsonData,
    List<ValidationError> errors,
  ) {
    if (jsonData.containsKey('children')) {
      final children = jsonData['children'];
      if (children is! List) {
        errors.add(ValidationError(
          field: 'children',
          message: 'Layout widget children must be a list',
          severity: ErrorSeverity.major,
        ));
      }
    }
  }

  /// Validate nested children recursively
  static void _validateChildren(
    Map<String, dynamic> jsonData,
    List<ValidationError> errors,
  ) {
    if (jsonData.containsKey('children')) {
      final children = jsonData['children'];
      if (children is List) {
        for (int i = 0; i < children.length; i++) {
          final child = children[i];
          if (child is Map<String, dynamic>) {
            final childErrors = validateWidgetJson(child).errors;
            for (final error in childErrors) {
              errors.add(ValidationError(
                field: 'children[$i].${error.field}',
                message: error.message,
                severity: error.severity,
              ));
            }
          }
        }
      }
    }

    // Validate single child
    if (jsonData.containsKey('child')) {
      final child = jsonData['child'];
      if (child is Map<String, dynamic>) {
        final childErrors = validateWidgetJson(child).errors;
        for (final error in childErrors) {
          errors.add(ValidationError(
            field: 'child.${error.field}',
            message: error.message,
            severity: error.severity,
          ));
        }
      }
    }
  }
}

/// Debug information collector
///
/// Collects comprehensive debugging information for error analysis
/// and troubleshooting including system state, JSON context, and
/// runtime information.
class DebugInfoCollector {
  /// Collect comprehensive debug information
  ///
  /// Gathers all relevant debugging information for error analysis
  /// including JSON data, system state, and runtime context.
  ///
  /// ## Parameters
  /// - [json]: The JSON data involved in the error
  /// - [context]: Build context for widget information
  /// - [stackTrace]: Stack trace of the error
  /// - [additionalInfo]: Any additional debug information
  ///
  /// ## Returns
  /// [DebugInfo] containing all collected debugging information
  static DebugInfo collect({
    Map<String, dynamic>? json,
    BuildContext? context,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalInfo,
  }) {
    return DebugInfo(
      jsonData: json,
      contextInfo: _collectContextInfo(context),
      systemInfo: _collectSystemInfo(),
      stackTrace: stackTrace,
      additionalInfo: additionalInfo ?? {},
      timestamp: DateTime.now(),
    );
  }

  /// Collect build context information
  static Map<String, dynamic> _collectContextInfo(BuildContext? context) {
    if (context == null) return {};

    return {
      'widget_type': context.widget.runtimeType.toString(),
      'mounted': context.mounted,
      'debug_label': context.widget.toStringShort(),
    };
  }

  /// Collect system information
  static Map<String, dynamic> _collectSystemInfo() {
    return {
      'platform': defaultTargetPlatform.name,
      'debug_mode': kDebugMode,
      'profile_mode': kProfileMode,
      'release_mode': kReleaseMode,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Error information container
///
/// Holds comprehensive error information for logging and debugging.
class ErrorInformation {
  final dynamic error;
  final Map<String, dynamic>? jsonData;
  final Map<String, dynamic> context;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  const ErrorInformation({
    required this.error,
    this.jsonData,
    required this.context,
    this.stackTrace,
    required this.timestamp,
  });

  /// Get error summary for logging
  String get summary {
    final errorType = error.runtimeType.toString();
    final errorMessage = error.toString();
    return '$errorType: $errorMessage';
  }

  /// Convert to map for structured logging
  Map<String, dynamic> toMap() {
    return {
      'error_type': error.runtimeType.toString(),
      'error_message': error.toString(),
      'json_data': jsonData,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
      'stack_trace': stackTrace?.toString(),
    };
  }
}

/// Validation error details
class ValidationError {
  final String field;
  final String message;
  final ErrorSeverity severity;

  const ValidationError({
    required this.field,
    required this.message,
    required this.severity,
  });
}

/// Validation result container
class ValidationResult {
  final List<ValidationError> errors;

  const ValidationResult({required this.errors});

  /// Check if validation passed
  bool get isValid => errors.isEmpty;

  /// Get errors by severity
  List<ValidationError> getErrorsBySeverity(ErrorSeverity severity) {
    return errors.where((error) => error.severity == severity).toList();
  }
}

/// Validation error information for logging
class ValidationErrorInfo {
  final ValidationError error;
  final Map<String, dynamic>? jsonData;
  final Map<String, dynamic> context;

  const ValidationErrorInfo({
    required this.error,
    this.jsonData,
    required this.context,
  });

  Map<String, dynamic> toMap() {
    return {
      'field': error.field,
      'message': error.message,
      'severity': error.severity.name,
      'json_data': jsonData,
      'context': context,
    };
  }
}

/// Runtime error information container
class RuntimeErrorInfo {
  final dynamic error;
  final Map<String, dynamic> context;
  final StackTrace? stackTrace;

  const RuntimeErrorInfo({
    required this.error,
    required this.context,
    this.stackTrace,
  });

  String get summary {
    final errorType = error.runtimeType.toString();
    final errorMessage = error.toString();
    return '$errorType: $errorMessage';
  }

  Map<String, dynamic> toMap() {
    return {
      'error_type': error.runtimeType.toString(),
      'error_message': error.toString(),
      'context': context,
      'stack_trace': stackTrace?.toString(),
    };
  }
}

/// Debug information container
class DebugInfo {
  final Map<String, dynamic>? jsonData;
  final Map<String, dynamic> contextInfo;
  final Map<String, dynamic> systemInfo;
  final StackTrace? stackTrace;
  final Map<String, dynamic> additionalInfo;
  final DateTime timestamp;

  const DebugInfo({
    this.jsonData,
    required this.contextInfo,
    required this.systemInfo,
    this.stackTrace,
    required this.additionalInfo,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'json_data': jsonData,
      'context_info': contextInfo,
      'system_info': systemInfo,
      'additional_info': additionalInfo,
      'timestamp': timestamp.toIso8601String(),
      'stack_trace': stackTrace?.toString(),
    };
  }
}

/// Error severity levels
enum ErrorSeverity {
  /// Critical errors that prevent functionality
  critical,
  
  /// Major errors that significantly impact functionality  
  major,
  
  /// Minor errors that have minimal impact
  minor,
  
  /// Warning-level issues that should be addressed
  warning,
}

/// Debug error widget for development mode
class _DebugErrorWidget extends StatelessWidget {
  final ErrorInformation errorInfo;

  const _DebugErrorWidget({required this.errorInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        border: Border.all(color: const Color(0xFFF44336), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFF44336),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'Widget Rendering Error',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF44336),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorInfo.summary,
            style: const TextStyle(fontSize: 14),
          ),
          if (errorInfo.jsonData != null) ...[
            const SizedBox(height: 8),
            Text(
              'JSON Data: ${errorInfo.jsonData}',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
          if (errorInfo.context.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Context: ${errorInfo.context}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

/// User-friendly error widget for production mode
class _UserErrorWidget extends StatelessWidget {
  final ErrorInformation errorInfo;

  const _UserErrorWidget({required this.errorInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF757575),
            size: 24,
          ),
          const SizedBox(height: 8),
          const Text(
            'Content temporarily unavailable',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }
}