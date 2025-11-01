/// Integration tests for Phase 5.3 security hardening
/// Tests all security services: validation, rate limiting, headers, error handling

import 'dart:convert';
import 'package:test/test.dart';
import 'package:shelf/shelf.dart' as shelf;
import '../lib/src/request_validator.dart';
import '../lib/src/rate_limiter.dart';
import '../lib/src/security_headers.dart';
import '../lib/src/error_handler.dart';

void main() {
  group('Phase 5.3: Security Hardening Tests', () {
    // ==================== REQUEST VALIDATION TESTS ====================
    group('RequestValidator - Input Validation & Sanitization', () {
      setUp(() {
        // Validator instance used in each test
      });

      test('Valid email parameter passes validation', () {
        final rule = ParameterRule(
          name: 'email',
          type: 'string',
          format: 'email',
          required: true,
        );
        final result = rule.validate('user@example.com');
        expect(result.isValid, true);
      });

      test('Invalid email parameter fails validation', () {
        final rule = ParameterRule(
          name: 'email',
          type: 'string',
          format: 'email',
          required: true,
        );
        final result = rule.validate('invalid-email');
        expect(result.isValid, false);
      });

      test('Missing required parameter fails validation', () {
        final rule = ParameterRule(
          name: 'username',
          required: true,
        );
        final result = rule.validate(null);
        expect(result.isValid, false);
        expect(result.errors.first, contains('required'));
      });

      test('SQL injection pattern detected in parameter', () {
        final rule = ParameterRule(
          name: 'search',
          type: 'string',
        );
        final result = rule.validate("'; DROP TABLE users; --");
        expect(result.isValid, false);
      });

      test('Command injection pattern detected', () {
        final rule = ParameterRule(
          name: 'command',
          type: 'string',
        );
        final result = rule.validate('ls; rm -rf /');
        expect(result.isValid, false);
      });

      test('UUID format validation works', () {
        final rule = ParameterRule(
          name: 'id',
          type: 'string',
          format: 'uuid',
        );
        final validUuid = rule.validate('550e8400-e29b-41d4-a716-446655440000');
        expect(validUuid.isValid, true);

        final invalidUuid = rule.validate('not-a-uuid');
        expect(invalidUuid.isValid, false);
      });

      test('String sanitization removes dangerous characters', () {
        final input = '<script>alert("xss")</script>';
        final sanitized = RequestValidator.sanitize(input);
        expect(sanitized, isNot(contains('<')));
        expect(sanitized, isNot(contains('>')));
      });

      test('Body validation with schema works', () async {
        final schema = BodySchema(
          contentType: 'application/json',
          requiredFields: ['email', 'password'],
          schema: {
            'type': 'object',
            'properties': {
              'email': {'type': 'string'},
              'password': {'type': 'string'},
            },
          },
        );

        final validBody = jsonEncode({'email': 'user@example.com', 'password': 'secret'});
        final result1 = await schema.validateJson(validBody);
        expect(result1.isValid, true);

        final invalidBody = jsonEncode({'email': 'user@example.com'});
        final result2 = await schema.validateJson(invalidBody);
        expect(result2.isValid, false);
      });
    });

    // ==================== RATE LIMITING TESTS ====================
    group('RateLimiter - DDoS Protection', () {
      late RateLimiter rateLimiter;

      setUp(() {
        rateLimiter = RateLimiter();
      });

      tearDown(() {
        rateLimiter.dispose();
      });

      test('Rate limiter allows requests within limit', () {
        final status = rateLimiter.checkLimit('192.168.1.1', 'public');
        expect(status.allowed, true);
      });

      test('Rate limiter blocks requests exceeding limit', () {
        // Exhaust the public tier limit (100 req/min)
        for (int i = 0; i < 100; i++) {
          rateLimiter.checkLimit('192.168.1.2', 'public');
        }

        // Next request should be blocked
        final status = rateLimiter.checkLimit('192.168.1.2', 'public');
        expect(status.allowed, false);
      });

      test('Auth tier has stricter limits than public', () {
        final status1 = rateLimiter.checkLimit('192.168.1.3', 'auth');
        final status2 = rateLimiter.checkLimit('192.168.1.3', 'public');
        
        expect(status1.remainingRequests, lessThan(status2.remainingRequests));
      });

      test('Rate limit status includes correct headers', () {
        final status = rateLimiter.checkLimit('192.168.1.4', 'public');
        final headers = status.toHeaders();
        
        expect(headers, containsPair('X-RateLimit-Remaining', isNotNull));
        expect(headers, containsPair('X-RateLimit-Reset', isNotNull));
        expect(headers, containsPair('Retry-After', isNotNull));
      });

      test('Different IPs have separate rate limit buckets', () {
        final status1 = rateLimiter.checkLimit('192.168.1.5', 'public', tokensToConsume: 50);
        final status2 = rateLimiter.checkLimit('192.168.1.6', 'public', tokensToConsume: 50);
        
        // Both should succeed as they're different IPs
        expect(status1.allowed, true);
        expect(status2.allowed, true);
      });

      test('Rate limit can be reset for specific client', () {
        final ip = '192.168.1.7';
        
        // Exhaust limit
        for (int i = 0; i < 100; i++) {
          rateLimiter.checkLimit(ip, 'public');
        }

        // Should be blocked
        var status = rateLimiter.checkLimit(ip, 'public');
        expect(status.allowed, false);

        // Reset
        rateLimiter.resetClientLimit(ip, 'public');

        // Should be allowed again
        status = rateLimiter.checkLimit(ip, 'public');
        expect(status.allowed, true);
      });
    });

    // ==================== SECURITY HEADERS TESTS ====================
    group('SecurityHeaders - CORS & Security Headers', () {
      late SecurityHeaders securityHeaders;

      setUp(() {
        securityHeaders = SecurityHeaders();
      });

      test('Security headers are present in response', () {
        final headers = securityHeaders.securityConfig.toHeaders();
        
        expect(headers, containsPair('X-Frame-Options', 'DENY'));
        expect(headers, containsPair('X-Content-Type-Options', 'nosniff'));
        expect(headers, containsPair('Strict-Transport-Security', isNotNull));
        expect(headers, containsPair('Content-Security-Policy', isNotNull));
      });

      test('CORS allows configured origins', () {
        const origin = 'http://localhost:3000';
        expect(securityHeaders.corsConfig.isOriginAllowed(origin), true);
      });

      test('CORS denies unconfigured origins', () {
        const origin = 'https://malicious.example.com';
        expect(securityHeaders.corsConfig.isOriginAllowed(origin), false);
      });

      test('CORS preflight headers include correct methods', () {
        const origin = 'http://localhost:3000';
        final headers = securityHeaders.corsConfig.getPreflightResponseHeaders(origin);
        
        expect(headers, containsPair('Access-Control-Allow-Methods', contains('GET')));
        expect(headers, containsPair('Access-Control-Allow-Methods', contains('POST')));
        expect(headers, containsPair('Access-Control-Allow-Methods', contains('DELETE')));
      });

      test('Strict security preset denies inline scripts', () {
        final strict = SecurityHeadersPresets.strict();
        final csp = strict.contentSecurityPolicy;
        
        expect(csp, isNot(contains("'unsafe-inline'")));
      });

      test('Development CORS allows multiple local origins', () {
        final devCors = SecurityHeadersPresets.localDevelopment();
        
        expect(devCors.isOriginAllowed('http://localhost:3000'), true);
        expect(devCors.isOriginAllowed('http://localhost:8080'), true);
        expect(devCors.isOriginAllowed('http://127.0.0.1:3000'), true);
      });
    });

    // ==================== ERROR HANDLING TESTS ====================
    group('ErrorHandler - Standardized Error Responses', () {
      late ErrorHandler errorHandler;

      setUp(() {
        errorHandler = ErrorHandler(hideStackTraces: true);
      });

      test('Validation error has correct format', () {
        final error = errorHandler.validationError(
          message: 'Email is required',
          details: 'Field "email" is missing from request body',
        );

        expect(error.code, equals('VALIDATION_ERROR'));
        expect(error.status, equals(400));
        expect(error.message, equals('Email is required'));
        expect(error.traceId, isNotNull);
        expect(error.timestamp, isNotNull);
      });

      test('Authentication error returns 401', () {
        final error = errorHandler.authenticationError(
          message: 'Invalid credentials',
        );

        expect(error.status, equals(401));
        expect(error.code, equals('AUTHENTICATION_ERROR'));
      });

      test('Authorization error returns 403', () {
        final error = errorHandler.authorizationError(
          message: 'Insufficient permissions',
        );

        expect(error.status, equals(403));
        expect(error.code, equals('AUTHORIZATION_ERROR'));
      });

      test('Not found error returns 404', () {
        final error = errorHandler.notFoundError(
          resource: 'User with ID 123',
        );

        expect(error.status, equals(404));
        expect(error.code, equals('NOT_FOUND'));
      });

      test('Rate limit error returns 429', () {
        final error = errorHandler.rateLimitError(
          message: 'Too many requests',
          retryAfter: 60,
        );

        expect(error.status, equals(429));
        expect(error.code, equals('RATE_LIMIT_EXCEEDED'));
        expect(error.metadata?['retry_after'], equals(60));
      });

      test('Server error hides stack trace in production', () {
        final error = errorHandler.serverError(
          message: 'An error occurred',
          exception: Exception('Database connection failed'),
          stackTrace: StackTrace.current,
        );

        expect(error.status, equals(500));
        expect(error.code, equals('INTERNAL_SERVER_ERROR'));
        // Details should be null or not contain the actual error
        expect(error.details, anyOf(isNull, isNot(contains('Database'))));
      });

      test('Error JSON serialization works', () {
        final error = errorHandler.validationError(
          message: 'Invalid input',
        );

        final json = jsonDecode(error.toJson());
        expect(json, containsPair('error', isNotNull));
        expect(json['error']['code'], equals('VALIDATION_ERROR'));
        expect(json['error']['timestamp'], isNotNull);
        expect(json['error']['trace_id'], isNotNull);
      });

      test('Error response middleware catches exceptions', () async {
        final middleware = errorHandler.createMiddleware();
        final handler = middleware((request) {
          throw Exception('Test error');
        });

        final request = shelf.Request('GET', Uri.parse('http://localhost/test'));
        final response = await handler(request);

        expect(response.statusCode, equals(500));
      });

      test('Predefined errors have correct formats', () {
        final invalidJsonError = ErrorResponses.invalidJson('trace-123');
        expect(invalidJsonError.code, equals('INVALID_JSON'));
        expect(invalidJsonError.status, equals(400));

        final notFoundError = ErrorResponses.resourceNotFound('users/123', 'trace-456');
        expect(notFoundError.code, equals('RESOURCE_NOT_FOUND'));
        expect(notFoundError.status, equals(404));

        final rateLimitError = ErrorResponses.rateLimitExceeded('public', 60, 'trace-789');
        expect(rateLimitError.code, equals('RATE_LIMIT_EXCEEDED'));
        expect(rateLimitError.status, equals(429));
      });
    });

    // ==================== INTEGRATION TESTS ====================
    group('Phase 5.3: End-to-End Integration', () {
      late RateLimiter rateLimiter;
      late SecurityHeaders securityHeaders;
      late ErrorHandler errorHandler;

      setUp(() {
        rateLimiter = RateLimiter();
        securityHeaders = SecurityHeaders();
        errorHandler = ErrorHandler();
      });

      tearDown(() {
        rateLimiter.dispose();
      });

      test('Request with validation, rate limit, and security headers', () {
        // Simulate request validation
        final emailRule = ParameterRule(
          name: 'email',
          format: 'email',
          required: true,
        );
        final validationResult = emailRule.validate('user@example.com');
        expect(validationResult.isValid, true);

        // Check rate limit
        final rateLimitStatus = rateLimiter.checkLimit('192.168.1.100', 'public');
        expect(rateLimitStatus.allowed, true);

        // Get security headers
        final headers = securityHeaders.securityConfig.toHeaders();
        expect(headers, isNotEmpty);
      });

      test('Blocked request returns proper error with headers', () {
        // Exhaust rate limit
        for (int i = 0; i < 100; i++) {
          rateLimiter.checkLimit('192.168.1.200', 'public');
        }

        // Check rate limit (should fail)
        final rateLimitStatus = rateLimiter.checkLimit('192.168.1.200', 'public');
        expect(rateLimitStatus.allowed, false);

        // Create error response
        final error = errorHandler.rateLimitError(
          message: 'Too many requests',
          retryAfter: int.parse(rateLimitStatus.retryAfter),
        );

        expect(error.status, equals(429));
        final headers = error.toResponse().headers;
        expect(headers, containsPair('X-Trace-ID', isNotNull));
      });

      test('All security services work together', () {
        const clientIp = '192.168.1.150';
        const tier = 'public';

        // Request 1: Valid request
        final validation1 = RequestValidator.isValidEmail('user@example.com');
        expect(validation1, true);

        final rateLimitStatus1 = rateLimiter.checkLimit(clientIp, tier);
        expect(rateLimitStatus1.allowed, true);

        // Request 2: Invalid request with injection
        final rule = ParameterRule(
          name: 'id',
          type: 'string',
        );
        final validation2 = rule.validate("'; DROP TABLE users; --");
        expect(validation2.isValid, false);

        // Request 3: Rate limit exceeded
        for (int i = 0; i < 100; i++) {
          rateLimiter.checkLimit(clientIp, tier);
        }
        final rateLimitStatus3 = rateLimiter.checkLimit(clientIp, tier);
        expect(rateLimitStatus3.allowed, false);
      });
    });
  });
}
