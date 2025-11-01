/// Production Security Configuration for QuicUI Code Push Backend
/// 
/// Handles HTTPS/TLS, CORS, security headers, and environment configuration
/// 
/// Usage:
/// ```dart
/// final config = SecurityConfig.fromEnvironment();
/// final middleware = config.createSecurityMiddleware();
/// ```

import 'package:shelf/shelf.dart';
import 'dart:io';

/// Production security configuration
class SecurityConfig {
  // HTTPS/TLS Configuration
  final bool enforceHttps;
  final String? tlsCertPath;
  final String? tlsKeyPath;
  final String hstsMaxAge;
  final bool includeSubdomains;

  // CORS Configuration
  final List<String> allowedOrigins;
  final List<String> allowedMethods;
  final List<String> allowedHeaders;
  final bool allowCredentials;
  final int preflightCacheTime;

  // Security Headers
  final String contentSecurityPolicy;
  final String xContentTypeOptions;
  final String xFrameOptions;
  final String xXssProtection;
  final String referrerPolicy;

  // Application Security
  final bool debugMode;
  final int maxRequestSize;
  final Duration requestTimeout;

  SecurityConfig({
    // HTTPS/TLS defaults
    this.enforceHttps = true,
    this.tlsCertPath,
    this.tlsKeyPath,
    this.hstsMaxAge = '31536000', // 1 year
    this.includeSubdomains = true,

    // CORS defaults - MUST be configured in production
    required this.allowedOrigins,
    this.allowedMethods = const ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    this.allowedHeaders = const ['Content-Type', 'Authorization', 'X-API-Key'],
    this.allowCredentials = false,
    this.preflightCacheTime = 86400, // 24 hours

    // Security headers
    this.contentSecurityPolicy = "default-src 'self'",
    this.xContentTypeOptions = 'nosniff',
    this.xFrameOptions = 'DENY',
    this.xXssProtection = '1; mode=block',
    this.referrerPolicy = 'strict-origin-when-cross-origin',

    // Application security
    this.debugMode = false,
    this.maxRequestSize = 10 * 1024 * 1024, // 10MB
    this.requestTimeout = const Duration(seconds: 30),
  }) {
    _validate();
  }

  /// Create security config from environment variables
  factory SecurityConfig.fromEnvironment() {
    final env = Platform.environment;
    
    // Verify critical variables are set
    if (env['QUICUI_ALLOWED_ORIGINS']?.isEmpty ?? true) {
      throw SecurityConfigException(
        'CRITICAL: Environment variable QUICUI_ALLOWED_ORIGINS is not set. '
        'Set this to comma-separated list of allowed origins, e.g., "https://example.com,https://app.example.com"'
      );
    }

    if (env['QUICUI_ENVIRONMENT']?.isEmpty ?? true) {
      throw SecurityConfigException(
        'CRITICAL: Environment variable QUICUI_ENVIRONMENT is not set. '
        'Set to: development, staging, or production'
      );
    }

    final environment = env['QUICUI_ENVIRONMENT']!;
    final debugMode = environment == 'development';
    final isProduction = environment == 'production';

    // Parse CORS allowed origins
    final allowedOrigins = (env['QUICUI_ALLOWED_ORIGINS'] ?? '')
        .split(',')
        .map((o) => o.trim())
        .where((o) => o.isNotEmpty)
        .toList();

    if (allowedOrigins.isEmpty) {
      throw SecurityConfigException(
        'CRITICAL: No allowed origins configured. '
        'QUICUI_ALLOWED_ORIGINS must contain at least one origin.'
      );
    }

    // Warn about wildcard origins in production
    if (isProduction && allowedOrigins.contains('*')) {
      throw SecurityConfigException(
        'CRITICAL: Wildcard CORS origin (*) not allowed in production. '
        'Configure specific allowed origins instead.'
      );
    }

    // TLS configuration required in production
    final tlsCertPath = env['QUICUI_TLS_CERT_PATH'];
    final tlsKeyPath = env['QUICUI_TLS_KEY_PATH'];

    if (isProduction && (tlsCertPath?.isEmpty ?? true)) {
      throw SecurityConfigException(
        'CRITICAL: HTTPS/TLS is required in production. '
        'Set QUICUI_TLS_CERT_PATH and QUICUI_TLS_KEY_PATH environment variables.'
      );
    }

    return SecurityConfig(
      enforceHttps: isProduction,
      tlsCertPath: tlsCertPath,
      tlsKeyPath: tlsKeyPath,
      allowedOrigins: allowedOrigins,
      debugMode: debugMode,
    );
  }

  /// Validate configuration
  void _validate() {
    // Validate HTTPS configuration
    if (enforceHttps) {
      if (tlsCertPath == null || tlsCertPath!.isEmpty) {
        throw SecurityConfigException(
          'HTTPS is enabled but tlsCertPath is not provided'
        );
      }
      if (tlsKeyPath == null || tlsKeyPath!.isEmpty) {
        throw SecurityConfigException(
          'HTTPS is enabled but tlsKeyPath is not provided'
        );
      }

      // Verify certificate and key files exist
      try {
        if (!File(tlsCertPath!).existsSync()) {
          throw SecurityConfigException(
            'TLS certificate file not found: $tlsCertPath'
          );
        }
        if (!File(tlsKeyPath!).existsSync()) {
          throw SecurityConfigException(
            'TLS key file not found: $tlsKeyPath'
          );
        }
      } catch (e) {
        throw SecurityConfigException('TLS file validation failed: $e');
      }
    }

    // Validate CORS configuration
    if (allowedOrigins.isEmpty) {
      throw SecurityConfigException('At least one allowed origin must be configured');
    }

    // Warn about credential allowance
    if (allowCredentials && !debugMode) {
      print('⚠️ WARNING: CORS credentials are allowed. Ensure this is intentional.');
    }

    // Validate security headers
    if (contentSecurityPolicy.isEmpty) {
      throw SecurityConfigException('Content-Security-Policy cannot be empty');
    }
  }

  /// Create comprehensive security middleware pipeline
  Middleware createSecurityMiddleware() {
    return (Handler handler) {
      var pipeline = handler;
      
      // Add request validation first (early termination possible)
      pipeline = _requestValidationMiddleware(pipeline);
      
      // Add CORS next (needs to allow cross-origin requests)
      pipeline = _corsMiddleware(pipeline);
      
      // Add security headers (modifies response)
      pipeline = _securityHeadersMiddleware(pipeline);
      
      // Add HTTPS enforcement (may redirect)
      pipeline = _httpsEnforcementMiddleware(pipeline);
      
      return pipeline;
    };
  }

  /// HTTPS enforcement middleware
  Handler _httpsEnforcementMiddleware(Handler innerHandler) {
    return (Request request) {
      if (enforceHttps && request.url.scheme != 'https' && !debugMode) {
        return Response.movedPermanently(
          Uri(
            scheme: 'https',
            host: request.headers['host'],
            path: request.url.path,
            query: request.url.query,
          ).toString(),
        );
      }
      return innerHandler(request);
    };
  }

  /// Security headers middleware
  Handler _securityHeadersMiddleware(Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);
      
      final headers = <String, String>{
        // Prevent MIME type sniffing
        'X-Content-Type-Options': xContentTypeOptions,
        
        // Prevent clickjacking
        'X-Frame-Options': xFrameOptions,
        
        // Enable XSS protection
        'X-XSS-Protection': xXssProtection,
        
        // Control referrer information
        'Referrer-Policy': referrerPolicy,
        
        // Content Security Policy
        'Content-Security-Policy': contentSecurityPolicy,
      };
      
      // HSTS (HTTP Strict Transport Security)
      if (enforceHttps) {
        headers['Strict-Transport-Security'] = 
          'max-age=$hstsMaxAge${includeSubdomains ? "; includeSubdomains" : ""}';
      }
      
      return response.change(headers: headers);
    };
  }

  /// CORS middleware
  Handler _corsMiddleware(Handler innerHandler) {
    return (Request request) async {
      final origin = request.headers['origin'];
      
      // Handle preflight requests
      if (request.method == 'OPTIONS') {
        if (origin != null && _isOriginAllowed(origin)) {
          return Response.ok(
            '',
            headers: _getCorsHeaders(origin),
          );
        }
        // Reject preflight request with forbidden origin
        return Response.forbidden('CORS: Origin not allowed');
      }
      
      // Add CORS headers to response
      final response = await innerHandler(request);
      if (origin != null && _isOriginAllowed(origin)) {
        return response.change(headers: _getCorsHeaders(origin));
      }
      
      return response;
    };
  }

  /// Request validation middleware
  Handler _requestValidationMiddleware(Handler innerHandler) {
    return (Request request) async {
      // Check request size
      final contentLength = int.tryParse(request.headers['content-length'] ?? '0') ?? 0;
      if (contentLength > maxRequestSize) {
        return Response(413); // Payload Too Large
      }
      
      // Validate content type for POST/PUT/PATCH
      if (const ['POST', 'PUT', 'PATCH'].contains(request.method)) {
        final contentType = request.headers['content-type'];
        if (contentType == null || !contentType.startsWith('application/json')) {
          return Response(400, body: 'Content-Type must be application/json');
        }
      }
      
      return innerHandler(request);
    };
  }

  /// Check if origin is allowed
  bool _isOriginAllowed(String origin) {
    // Exact match
    if (allowedOrigins.contains(origin)) {
      return true;
    }
    
    // Wildcard match (only in non-production)
    if (allowedOrigins.contains('*') && debugMode) {
      return true;
    }
    
    return false;
  }

  /// Get CORS headers for response
  Map<String, String> _getCorsHeaders(String origin) => {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': allowedMethods.join(', '),
    'Access-Control-Allow-Headers': allowedHeaders.join(', '),
    if (allowCredentials) 'Access-Control-Allow-Credentials': 'true',
    'Access-Control-Max-Age': preflightCacheTime.toString(),
  };

  /// Production environment checklist
  void printSecurityChecklistProduction() {
    print('\n🔒 PRODUCTION SECURITY CHECKLIST:');
    print('├─ HTTPS/TLS: ${enforceHttps ? "✅ Enabled" : "❌ DISABLED"}');
    print('├─ CORS Origins: ${allowedOrigins.length} configured');
    if (allowedOrigins.contains('*')) {
      print('│  └─ ⚠️ WARNING: Wildcard origin allowed');
    }
    print('├─ Security Headers: ✅ Enabled');
    print('├─ HSTS: ${enforceHttps ? "✅ Enabled (max-age=$hstsMaxAge)" : "ℹ️ Not applicable"}');
    print('├─ Debug Mode: ${debugMode ? "⚠️ ENABLED - PRODUCTION RISK" : "✅ Disabled"}');
    print('├─ Max Request Size: ${(maxRequestSize / 1024 / 1024).toStringAsFixed(1)}MB');
    print('└─ Request Timeout: ${requestTimeout.inSeconds}s');
    print('');
  }
}

/// Security configuration exception
class SecurityConfigException implements Exception {
  final String message;
  
  SecurityConfigException(this.message);
  
  @override
  String toString() => 'SecurityConfigException: $message';
}

/// Environment variable documentation
const String environmentVariableDocumentation = '''
REQUIRED ENVIRONMENT VARIABLES FOR PRODUCTION:

1. QUICUI_ENVIRONMENT (Required)
   - Values: "development", "staging", "production"
   - Default: None (must be set)
   - Example: production

2. QUICUI_ALLOWED_ORIGINS (Required)
   - Format: Comma-separated list of allowed origins
   - Default: None (must be set)
   - Example: https://example.com,https://api.example.com
   - WARNING: Do NOT use * in production

3. QUICUI_TLS_CERT_PATH (Required in production)
   - Format: File path to TLS certificate file
   - Default: None (required for HTTPS)
   - Example: /etc/ssl/certs/server.crt

4. QUICUI_TLS_KEY_PATH (Required in production)
   - Format: File path to TLS private key file
   - Default: None (required for HTTPS)
   - Example: /etc/ssl/private/server.key

OPTIONAL ENVIRONMENT VARIABLES:

5. QUICUI_MAX_REQUEST_SIZE (Optional)
   - Format: Size in bytes
   - Default: 10485760 (10MB)
   - Example: 52428800 (50MB)

6. QUICUI_REQUEST_TIMEOUT (Optional)
   - Format: Seconds
   - Default: 30
   - Example: 60

7. QUICUI_CORS_ALLOW_CREDENTIALS (Optional)
   - Values: "true", "false"
   - Default: false
   - Example: true

8. QUICUI_CSP_POLICY (Optional)
   - Format: Content Security Policy string
   - Default: "default-src 'self'"
   - Example: "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"

DEPLOYMENT INSTRUCTIONS:

1. Create .env.production file with required variables:
   ```
   QUICUI_ENVIRONMENT=production
   QUICUI_ALLOWED_ORIGINS=https://app.example.com,https://api.example.com
   QUICUI_TLS_CERT_PATH=/etc/ssl/certs/server.crt
   QUICUI_TLS_KEY_PATH=/etc/ssl/private/server.key
   ```

2. Load environment variables before starting application:
   ```
   source .env.production
   dart run quicui_backend
   ```

3. Verify configuration with:
   ```
   dart run bin/verify_security_config.dart
   ```

SECURITY NOTES:

- All environment variables should be managed by your infrastructure
  (Docker secrets, Kubernetes secrets, environment management system)
  
- Never commit .env files to version control

- TLS certificates should be auto-renewed (e.g., with Let's Encrypt)

- CORS origins should be whitelist-based, not wildcard

- In development, QUICUI_ENVIRONMENT=development to disable strict checks

- For local testing, QUICUI_ENVIRONMENT=development allows:
  - Wildcard CORS origins (*)
  - HTTP connections
  - Debug output
''';
