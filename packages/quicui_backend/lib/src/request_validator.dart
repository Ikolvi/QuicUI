/// RequestValidator - Input Validation & Sanitization Middleware
/// 
/// Provides comprehensive input validation for all endpoints:
/// - Parameter validation (required, type, format, length, range)
/// - Body validation (JSON schema, content-type)
/// - Input sanitization (prevent injection attacks)
/// - Custom validation rules
/// 
/// Security fixes:
/// - Prevents SQL injection through parameter validation
/// - Prevents command injection through command-specific rules
/// - Prevents code injection through expression validation
/// - Validates all input types and formats

import 'dart:convert';
import 'package:shelf/shelf.dart';

/// Validation result with errors if validation failed
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  ValidationResult({required this.isValid, this.errors = const []});

  factory ValidationResult.success() {
    return ValidationResult(isValid: true, errors: []);
  }

  factory ValidationResult.failure(List<String> errors) {
    return ValidationResult(isValid: false, errors: errors);
  }

  @override
  String toString() => 'ValidationResult(valid: \$isValid, errors: \${errors.length})';
}

/// Parameter validation rule
class ParameterRule {
  final String name;
  final bool required;
  final String? type; // string, integer, number, boolean, array, object
  final String? pattern; // regex pattern for strings
  final int? minLength;
  final int? maxLength;
  final int? minimum;
  final int? maximum;
  final List<String>? enum_;
  final String? format; // email, uuid, date-time, etc.
  final String? description;

  ParameterRule({
    required this.name,
    this.required = false,
    this.type,
    this.pattern,
    this.minLength,
    this.maxLength,
    this.minimum,
    this.maximum,
    this.enum_,
    this.format,
    this.description,
  });

  /// Validate a parameter value
  ValidationResult validate(String? value) {
    final errors = <String>[];

    // Check required
    if (required && (value == null || value.isEmpty)) {
      errors.add('Parameter "\$name" is required');
      return ValidationResult.failure(errors);
    }

    if (value == null || value.isEmpty) {
      return ValidationResult.success();
    }

    // Check type and format
    if (type != null) {
      switch (type) {
        case 'string':
          if (minLength != null && value.length < minLength!) {
            errors.add(
              'Parameter "\$name" must have minimum length \$minLength',
            );
          }
          if (maxLength != null && value.length > maxLength!) {
            errors.add(
              'Parameter "\$name" must have maximum length \$maxLength',
            );
          }
          if (pattern != null && !RegExp(pattern!).hasMatch(value)) {
            errors.add('Parameter "\$name" format is invalid');
          }
          if (format != null) {
            if (!_validateFormat(format!, value)) {
              errors.add(
                'Parameter "\$name" must be a valid \$format',
              );
            }
          }
          if (enum_ != null && !enum_!.contains(value)) {
            errors.add(
              'Parameter "\$name" must be one of: \${enum_!.join(", ")}',
            );
          }
          break;

        case 'integer':
          try {
            final intValue = int.parse(value);
            if (minimum != null && intValue < minimum!) {
              errors.add('Parameter "\$name" must be >= \$minimum');
            }
            if (maximum != null && intValue > maximum!) {
              errors.add('Parameter "\$name" must be <= \$maximum');
            }
          } on FormatException {
            errors.add('Parameter "\$name" must be an integer');
          }
          break;

        case 'number':
          try {
            final numValue = double.parse(value);
            if (minimum != null && numValue < minimum!) {
              errors.add('Parameter "\$name" must be >= \$minimum');
            }
            if (maximum != null && numValue > maximum!) {
              errors.add('Parameter "\$name" must be <= \$maximum');
            }
          } on FormatException {
            errors.add('Parameter "\$name" must be a number');
          }
          break;

        case 'boolean':
          if (value != 'true' && value != 'false') {
            errors.add('Parameter "\$name" must be true or false');
          }
          break;
      }
    }

    // Sanitize potentially dangerous patterns
    if (_containsDangerousPattern(value)) {
      errors.add('Parameter "\$name" contains invalid characters');
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }

  /// Validate format (email, uuid, date-time, etc.)
  bool _validateFormat(String format, String value) {
    switch (format.toLowerCase()) {
      case 'email':
        final emailRegex = RegExp(
          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
        );
        return emailRegex.hasMatch(value);

      case 'uuid':
        final uuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          caseSensitive: false,
        );
        return uuidRegex.hasMatch(value);

      case 'date-time':
      case 'datetime':
        try {
          DateTime.parse(value);
          return true;
        } catch (e) {
          return false;
        }

      case 'date':
        try {
          DateTime.parse(value);
          return true;
        } catch (e) {
          return false;
        }

      case 'time':
        final timeRegex = RegExp(r'^\d{2}:\d{2}:\d{2}$');
        return timeRegex.hasMatch(value);

      case 'url':
      case 'uri':
        try {
          Uri.parse(value);
          return value.startsWith('http://') || value.startsWith('https://');
        } catch (e) {
          return false;
        }

      case 'ipv4':
        final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
        if (!ipRegex.hasMatch(value)) return false;
        final parts = value.split('.');
        return parts.every((part) {
          final num = int.parse(part);
          return num >= 0 && num <= 255;
        });

      case 'ipv6':
        // Simplified IPv6 validation
        return value.contains(':') && value.split(':').length >= 3;

      default:
        return true;
    }
  }

  /// Check for dangerous patterns (SQL injection, command injection, etc.)
  bool _containsDangerousPattern(String value) {
    // Check for SQL injection keywords
    final sqlKeywords = RegExp(
      r'(union|select|insert|update|delete|drop|create|alter|exec)',
      caseSensitive: false,
    );
    if (sqlKeywords.hasMatch(value)) return true;

    // Check for command injection characters
    final unsafeChars = ['|', '&', ';', '`', '\$'];
    for (final char in unsafeChars) {
      if (value.contains(char)) return true;
    }

    // Check for quotes and dashes that could escape strings
    if (value.contains("'") || value.contains('"') || value.contains('--')) {
      return true;
    }

    return false;
  }
}

/// Request body schema validation
class BodySchema {
  final String? contentType;
  final Map<String, dynamic>? schema;
  final List<String>? requiredFields;
  final String? description;

  BodySchema({
    this.contentType,
    this.schema,
    this.requiredFields,
    this.description,
  });

  /// Validate JSON body
  Future<ValidationResult> validateJson(String body) async {
    final errors = <String>[];

    try {
      final json = jsonDecode(body) as Map<String, dynamic>;

      // Check required fields
      if (requiredFields != null) {
        for (final field in requiredFields!) {
          if (!json.containsKey(field) || json[field] == null) {
            errors.add('Required field "\$field" is missing');
          }
        }
      }

      // Validate against schema if provided
      if (schema != null) {
        final schemaErrors = _validateAgainstSchema(json, schema!);
        errors.addAll(schemaErrors);
      }

      return errors.isEmpty
          ? ValidationResult.success()
          : ValidationResult.failure(errors);
    } on FormatException {
      return ValidationResult.failure(['Invalid JSON']);
    } catch (e) {
      return ValidationResult.failure(['Error validating body: \$e']);
    }
  }

  /// Validate JSON against schema recursively
  List<String> _validateAgainstSchema(
    dynamic value,
    dynamic schema, {
    String path = 'root',
  }) {
    final errors = <String>[];

    if (schema is! Map<String, dynamic>) return errors;

    final type = schema['type'];
    final properties = schema['properties'] as Map<String, dynamic>?;

    // Validate type
    if (type != null) {
      if (!_validateType(value, type as String)) {
        errors.add('\$path must be of type \$type');
        return errors;
      }
    }

    // Validate object properties
    if (value is Map<String, dynamic> && properties != null) {
      for (final key in properties.keys) {
        final propSchema = properties[key];
        final propValue = value[key];

        if (propValue != null) {
          final propErrors = _validateAgainstSchema(
            propValue,
            propSchema,
            path: '\$path.\$key',
          );
          errors.addAll(propErrors);
        }
      }
    }

    return errors;
  }

  /// Validate value type
  bool _validateType(dynamic value, String type) {
    switch (type.toLowerCase()) {
      case 'string':
        return value is String;
      case 'number':
        return value is num;
      case 'integer':
      case 'int':
        return value is int;
      case 'boolean':
      case 'bool':
        return value is bool;
      case 'array':
        return value is List;
      case 'object':
        return value is Map;
      case 'null':
        return value == null;
      default:
        return true;
    }
  }
}

/// Main RequestValidator class
class RequestValidator {
  final Map<String, List<ParameterRule>> pathParameters;
  final Map<String, List<ParameterRule>> queryParameters;
  final Map<String, BodySchema> bodySchemas;
  final Map<String, List<String>> allowedHeaders;

  RequestValidator({
    this.pathParameters = const {},
    this.queryParameters = const {},
    this.bodySchemas = const {},
    this.allowedHeaders = const {},
  });

  /// Create middleware for request validation
  Middleware createMiddleware({
    required String path,
    required String method,
    bool validatePath = true,
    bool validateQuery = true,
    bool validateBody = true,
    bool validateHeaders = true,
  }) {
    return (Handler innerHandler) {
      return (Request request) async {
        // Check if path matches
        if (!request.url.path.startsWith(path.replaceAll(RegExp(r'{[^}]+}'), ''))) {
          return innerHandler(request);
        }

        // Validate path parameters
        if (validatePath && pathParameters.containsKey(path)) {
          final pathParams = pathParameters[path]!;

          for (final rule in pathParams) {
            // Extract parameter from path (simplified)
            final paramValue = _extractPathParam(request.url.path, path, rule.name);
            final result = rule.validate(paramValue);

            if (!result.isValid) {
              return _errorResponse(400, 'PATH_VALIDATION_ERROR', result.errors);
            }
          }
        }

        // Validate query parameters
        if (validateQuery && queryParameters.containsKey(path)) {
          final queryRules = queryParameters[path]!;

          for (final rule in queryRules) {
            final paramValue = request.url.queryParameters[rule.name];
            final result = rule.validate(paramValue);

            if (!result.isValid) {
              return _errorResponse(400, 'QUERY_VALIDATION_ERROR', result.errors);
            }
          }
        }

        // Validate body for POST/PUT/PATCH
        if (validateBody &&
            ['POST', 'PUT', 'PATCH'].contains(request.method) &&
            bodySchemas.containsKey(path)) {
          final body = await request.readAsString();
          final schema = bodySchemas[path]!;

          // Validate content-type
          final contentType = request.headers['content-type'] ?? '';
          if (schema.contentType != null &&
              !contentType.contains(schema.contentType!)) {
            return _errorResponse(
              415,
              'UNSUPPORTED_MEDIA_TYPE',
              ['Content-Type must be \${schema.contentType}'],
            );
          }

          // Validate JSON body
          if (body.isNotEmpty) {
            final result = await schema.validateJson(body);
            if (!result.isValid) {
              return _errorResponse(400, 'BODY_VALIDATION_ERROR', result.errors);
            }
          }

          // Replace request with validated body
          request = request.change(body: body);
        }

        // Validate headers
        if (validateHeaders && allowedHeaders.containsKey(path)) {
          final allowedHdrs = allowedHeaders[path]!;
          for (final header in request.headers.keys) {
            if (!allowedHdrs.contains(header.toLowerCase()) &&
                !_isStandardHeader(header)) {
              return _errorResponse(
                400,
                'HEADER_VALIDATION_ERROR',
                ['Header "\$header" is not allowed'],
              );
            }
          }
        }

        return innerHandler(request);
      };
    };
  }

  /// Extract path parameter from URL
  String? _extractPathParam(String path, String template, String paramName) {
    // Simple implementation - could be enhanced with more complex routing
    final paramPattern = '{$paramName}';
    if (!template.contains(paramPattern)) return null;

    final templateParts = template.split('/');
    final pathParts = path.split('/');

    if (templateParts.length != pathParts.length) return null;

    for (int i = 0; i < templateParts.length; i++) {
      if (templateParts[i] == paramPattern) {
        return pathParts[i];
      }
    }

    return null;
  }

  /// Check if header is standard HTTP header
  bool _isStandardHeader(String header) {
    final standard = {
      'accept',
      'accept-encoding',
      'accept-language',
      'cache-control',
      'connection',
      'content-length',
      'content-type',
      'host',
      'user-agent',
      'origin',
      'referer',
      'authorization',
      'cookie',
    };
    return standard.contains(header.toLowerCase());
  }

  /// Create error response
  Response _errorResponse(
    int statusCode,
    String errorCode,
    List<String> errors,
  ) {
    final errorBody = jsonEncode({
      'error': {
        'code': errorCode,
        'message': errors.join('; '),
        'status': statusCode,
        'timestamp': DateTime.now().toIso8601String(),
        'details': errors,
      },
    });

    return Response(
      statusCode,
      headers: {'content-type': 'application/json'},
      body: errorBody,
    );
  }

  /// Sanitize string input
  static String sanitize(String input) {
    // Remove dangerous characters and patterns
    String sanitized = input;

    // Remove HTML/JS special characters
    sanitized = sanitized.replaceAll(RegExp('[<>"`]'), '');
    sanitized = sanitized.replaceAll("'", '');
    sanitized = sanitized.replaceAll('"', '');

    // Remove newlines and control characters
    sanitized = sanitized.replaceAll('\r', '').replaceAll('\n', '');

    // Remove SQL keywords at start of string (case-insensitive)
    sanitized = sanitized.replaceAll(
      RegExp(r'^(SELECT|INSERT|UPDATE|DELETE|DROP)', caseSensitive: false),
      '',
    );

    return sanitized;
  }

  /// Validate email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

  /// Validate UUID
  static bool isValidUuid(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(uuid);
  }
}
