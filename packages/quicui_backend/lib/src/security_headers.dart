/// SecurityHeaders - CORS & Security Headers Middleware
///
/// Provides comprehensive security headers:
/// - X-Frame-Options (clickjacking protection)
/// - X-Content-Type-Options (MIME sniffing protection)
/// - Content-Security-Policy (XSS protection)
/// - Strict-Transport-Security (HTTPS enforcement)
/// - X-XSS-Protection (legacy XSS protection)
/// - Referrer-Policy (referrer control)
/// - Permissions-Policy (feature control)
/// - CORS configuration with origin whitelisting
///
/// Security fixes:
/// - Prevents clickjacking attacks
/// - Prevents MIME type sniffing
/// - Prevents cross-origin requests
/// - Enforces HTTPS connections

import 'package:shelf/shelf.dart';

/// CORS configuration
class CorsConfig {
  final List<String> allowedOrigins;
  final List<String> allowedMethods;
  final List<String> allowedHeaders;
  final List<String> exposedHeaders;
  final Duration maxAge;
  final bool allowCredentials;

  CorsConfig({
    List<String>? allowedOrigins,
    this.allowedMethods = const [
      'GET',
      'POST',
      'PUT',
      'DELETE',
      'PATCH',
      'HEAD',
      'OPTIONS'
    ],
    this.allowedHeaders = const [
      'Content-Type',
      'Authorization',
      'X-Requested-With',
      'Accept',
      'Access-Control-Allow-Origin',
    ],
    this.exposedHeaders = const [
      'Content-Length',
      'X-RateLimit-Remaining',
      'X-RateLimit-Reset',
    ],
    this.maxAge = const Duration(hours: 24),
    this.allowCredentials = false,
  }) : allowedOrigins = allowedOrigins ?? ['http://localhost:3000'];

  /// Check if origin is allowed
  bool isOriginAllowed(String? origin) {
    if (origin == null) return false;
    return allowedOrigins.contains(origin) ||
        allowedOrigins.contains('*');
  }

  /// Get CORS response headers for preflight request
  Map<String, String> getPreflightResponseHeaders(String? origin) {
    final headers = <String, String>{
      'Access-Control-Allow-Methods': allowedMethods.join(', '),
      'Access-Control-Allow-Headers': allowedHeaders.join(', '),
      'Access-Control-Max-Age': maxAge.inSeconds.toString(),
    };

    if (origin != null && isOriginAllowed(origin)) {
      headers['Access-Control-Allow-Origin'] = origin;
      if (allowCredentials) {
        headers['Access-Control-Allow-Credentials'] = 'true';
      }
    }

    return headers;
  }

  /// Get CORS response headers for actual request
  Map<String, String> getCorsResponseHeaders(String? origin) {
    final headers = <String, String>{
      'Access-Control-Expose-Headers': exposedHeaders.join(', '),
    };

    if (origin != null && isOriginAllowed(origin)) {
      headers['Access-Control-Allow-Origin'] = origin;
      if (allowCredentials) {
        headers['Access-Control-Allow-Credentials'] = 'true';
      }
    }

    return headers;
  }
}

/// Security headers configuration
class SecurityHeadersConfig {
  final String frameOptions;
  final String contentTypeOptions;
  final String contentSecurityPolicy;
  final String strictTransportSecurity;
  final String xxssProtection;
  final String referrerPolicy;
  final String permissionsPolicy;

  SecurityHeadersConfig({
    this.frameOptions = 'DENY',
    this.contentTypeOptions = 'nosniff',
    this.contentSecurityPolicy =
        "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'",
    this.strictTransportSecurity =
        'max-age=31536000; includeSubDomains; preload',
    this.xxssProtection = '1; mode=block',
    this.referrerPolicy = 'strict-origin-when-cross-origin',
    this.permissionsPolicy =
        'accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()',
  });

  /// Get all security headers as map
  Map<String, String> toHeaders() => {
    'X-Frame-Options': frameOptions,
    'X-Content-Type-Options': contentTypeOptions,
    'Content-Security-Policy': contentSecurityPolicy,
    'Strict-Transport-Security': strictTransportSecurity,
    'X-XSS-Protection': xxssProtection,
    'Referrer-Policy': referrerPolicy,
    'Permissions-Policy': permissionsPolicy,
  };

  @override
  String toString() => 'SecurityHeadersConfig(frameOptions: $frameOptions)';
}

/// Main SecurityHeaders middleware
class SecurityHeaders {
  final SecurityHeadersConfig securityConfig;
  final CorsConfig corsConfig;

  SecurityHeaders({
    SecurityHeadersConfig? securityConfig,
    CorsConfig? corsConfig,
  })  : securityConfig = securityConfig ?? SecurityHeadersConfig(),
        corsConfig = corsConfig ?? CorsConfig();

  /// Create middleware for adding security headers
  Middleware createMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        // Handle CORS preflight requests
        if (request.method == 'OPTIONS') {
          return _handlePreflight(request);
        }

        // Get response from inner handler
        var response = await innerHandler(request);

        // Add security headers
        response = _addSecurityHeaders(response, request);

        return response;
      };
    };
  }

  /// Handle CORS preflight (OPTIONS) requests
  Response _handlePreflight(Request request) {
    final origin = request.headers['origin'];
    final requestMethod = request.headers['access-control-request-method'];

    // Check if origin and method are allowed
    if (!corsConfig.isOriginAllowed(origin) || requestMethod == null) {
      return Response.forbidden('Preflight request not allowed');
    }

    // Return preflight response
    final headers = corsConfig.getPreflightResponseHeaders(origin);
    headers['Content-Length'] = '0';

    return Response(204, headers: headers);
  }

  /// Add security headers to response
  Response _addSecurityHeaders(Response response, Request request) {
    final headers = Map<String, String>.from(response.headers);

    // Add security headers
    headers.addAll(securityConfig.toHeaders());

    // Add CORS headers
    final origin = request.headers['origin'];
    if (origin != null) {
      headers.addAll(corsConfig.getCorsResponseHeaders(origin));
    }

    // Add additional security headers
    headers['X-Powered-By'] = 'QuicUI/1.0';
    headers['Server'] = 'QuicUI'; // Don't expose Dart/Shelf version

    return response.change(headers: headers);
  }

  /// Create simple middleware without CORS (for same-origin only)
  Middleware createSimpleMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        var response = await innerHandler(request);
        final headers = Map<String, String>.from(response.headers);

        // Add security headers only (no CORS)
        headers.addAll(securityConfig.toHeaders());
        headers['X-Powered-By'] = 'QuicUI/1.0';
        headers['Server'] = 'QuicUI';

        return response.change(headers: headers);
      };
    };
  }
}

/// Predefined security header configurations
class SecurityHeadersPresets {
  /// Strict security headers (recommended for production)
  static SecurityHeadersConfig strict() => SecurityHeadersConfig(
    frameOptions: 'DENY',
    contentTypeOptions: 'nosniff',
    contentSecurityPolicy:
        "default-src 'none'; script-src 'self'; style-src 'self'; img-src 'self'; font-src 'self'; connect-src 'self'",
    strictTransportSecurity:
        'max-age=31536000; includeSubDomains; preload',
    xxssProtection: '1; mode=block',
    referrerPolicy: 'no-referrer',
    permissionsPolicy:
        'accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()',
  );

  /// Moderate security headers (for development/testing)
  static SecurityHeadersConfig moderate() => SecurityHeadersConfig(
    frameOptions: 'SAMEORIGIN',
    contentTypeOptions: 'nosniff',
    contentSecurityPolicy:
        "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:",
    strictTransportSecurity: 'max-age=63072000; includeSubDomains',
    xxssProtection: '1; mode=block',
    referrerPolicy: 'strict-origin-when-cross-origin',
  );

  /// CORS configuration for local development
  static CorsConfig localDevelopment() => CorsConfig(
    allowedOrigins: [
      'http://localhost:3000',
      'http://localhost:8080',
      'http://127.0.0.1:3000',
    ],
    allowedMethods: const [
      'GET',
      'POST',
      'PUT',
      'DELETE',
      'PATCH',
      'HEAD',
      'OPTIONS'
    ],
    allowedHeaders: const [
      'Content-Type',
      'Authorization',
      'X-Requested-With',
      'Accept',
    ],
    allowCredentials: true,
  );

  /// CORS configuration for production
  static CorsConfig production(String domain) => CorsConfig(
    allowedOrigins: [
      'https://$domain',
      'https://www.$domain',
    ],
    allowedMethods: const ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: const [
      'Content-Type',
      'Authorization',
    ],
    allowCredentials: false,
  );
}
