/// Tests for SecurityConfig and security middleware integration
///
/// Tests HTTPS enforcement, CORS validation, security headers,
/// request validation, and environment configuration.

import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import '../lib/src/security_config.dart';

void main() {
  group('SecurityConfig', () {
    group('constructor', () {
      test('requires at least one allowed origin', () {
        expect(
          () => SecurityConfig(allowedOrigins: []),
          throwsA(isA<SecurityConfigException>()),
        );
      });

      test('creates config with valid parameters', () {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
          debugMode: true,
        );
        
        expect(config.allowedOrigins, equals(['https://example.com']));
        expect(config.debugMode, true);
      });

      test('sets default security headers', () {
        final config = SecurityConfig(allowedOrigins: ['https://example.com']);
        
        expect(config.xContentTypeOptions, equals('nosniff'));
        expect(config.xFrameOptions, equals('DENY'));
        expect(config.xXssProtection, equals('1; mode=block'));
      });
    });

    group('HTTPS enforcement', () {
      test('enforceHttps defaults to true', () {
        final config = SecurityConfig(allowedOrigins: ['https://example.com']);
        expect(config.enforceHttps, true);
      });

      test('allows disabling HTTPS for development', () {
        final config = SecurityConfig(
          enforceHttps: false,
          allowedOrigins: ['http://localhost:3000'],
          debugMode: true,
        );
        
        expect(config.enforceHttps, false);
      });

      test('throws error if HTTPS enabled without certificate path', () {
        expect(
          () => SecurityConfig(
            enforceHttps: true,
            tlsCertPath: null,
            allowedOrigins: ['https://example.com'],
          ),
          throwsA(isA<SecurityConfigException>()),
        );
      });
    });

    group('CORS configuration', () {
      test('allows single origin', () {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
        );
        
        expect(config.allowedOrigins.length, equals(1));
      });

      test('allows multiple origins', () {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com', 'https://api.example.com'],
        );
        
        expect(config.allowedOrigins.length, equals(2));
      });

      test('sets default allowed methods', () {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
        );
        
        expect(
          config.allowedMethods,
          equals(['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS']),
        );
      });

      test('sets default allowed headers', () {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
        );
        
        expect(
          config.allowedHeaders,
          equals(['Content-Type', 'Authorization', 'X-API-Key']),
        );
      });

      test('allows custom preflight cache time', () {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
          preflightCacheTime: 3600,
        );
        
        expect(config.preflightCacheTime, equals(3600));
      });
    });

    group('request validation', () {
      test('sets default max request size to 10MB', () {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
        );
        
        expect(config.maxRequestSize, equals(10 * 1024 * 1024));
      });

      test('allows custom max request size', () {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
          maxRequestSize: 50 * 1024 * 1024,
        );
        
        expect(config.maxRequestSize, equals(50 * 1024 * 1024));
      });

      test('sets default request timeout to 30 seconds', () {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
        );
        
        expect(config.requestTimeout, equals(Duration(seconds: 30)));
      });

      test('allows custom request timeout', () {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
          requestTimeout: Duration(seconds: 60),
        );
        
        expect(config.requestTimeout, equals(Duration(seconds: 60)));
      });
    });

    group('security headers', () {
      test('includes X-Content-Type-Options', () {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
          xContentTypeOptions: 'nosniff',
        );
        
        expect(config.xContentTypeOptions, equals('nosniff'));
      });

      test('includes X-Frame-Options', () {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
          xFrameOptions: 'DENY',
        );
        
        expect(config.xFrameOptions, equals('DENY'));
      });

      test('includes Content-Security-Policy', () {
        final csp = "default-src 'self'; script-src 'self' 'unsafe-inline'";
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
          contentSecurityPolicy: csp,
        );
        
        expect(config.contentSecurityPolicy, equals(csp));
      });
    });



    group('CORS middleware', () {
      test('handles OPTIONS preflight request from allowed origin', () async {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
        );
        
        final middleware = config.createSecurityMiddleware();
        
        // Create a mock preflight request
        final request = Request(
          'OPTIONS',
          Uri.parse('http://localhost/api/test'),
          headers: {
            'origin': 'https://example.com',
          },
        );
        
        final handler = (Request req) => Response.ok('OK');
        final composedHandler = middleware(handler);
        final response = await composedHandler(request);
        
        expect(response.statusCode, equals(200));
      });

      test('rejects OPTIONS preflight from disallowed origin', () async {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
        );
        
        final middleware = config.createSecurityMiddleware();
        
        final request = Request(
          'OPTIONS',
          Uri.parse('http://localhost/api/test'),
          headers: {
            'origin': 'https://other.com',
          },
        );
        
        final handler = (Request req) => Response.ok('OK');
        final composedHandler = middleware(handler);
        final response = await composedHandler(request);
        
        expect(response.statusCode, equals(403));
      });
    });

    group('request validation middleware', () {
      test('rejects request exceeding max size', () async {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
          maxRequestSize: 1000, // 1KB
        );
        
        final middleware = config.createSecurityMiddleware();
        
        final request = Request(
          'POST',
          Uri.parse('http://localhost/api/test'),
          headers: {
            'content-length': '2000', // 2KB, exceeds limit
          },
        );
        
        final handler = (Request req) => Response.ok('OK');
        final composedHandler = middleware(handler);
        final response = await composedHandler(request);
        
        expect(response.statusCode, equals(413));
      });

      test('accepts request within size limit', () async {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
          maxRequestSize: 10000,
        );
        
        final middleware = config.createSecurityMiddleware();
        
        final request = Request(
          'POST',
          Uri.parse('http://localhost/api/test'),
          headers: {
            'content-length': '1000',
            'content-type': 'application/json',
          },
        );
        
        final handler = (Request req) => Response.ok('OK');
        final composedHandler = middleware(handler);
        final response = await composedHandler(request);
        
        expect(response.statusCode, equals(200));
      });

      test('rejects POST without json content-type', () async {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
        );
        
        final middleware = config.createSecurityMiddleware();
        
        final request = Request(
          'POST',
          Uri.parse('http://localhost/api/test'),
          headers: {
            'content-type': 'text/plain',
          },
        );
        
        final handler = (Request req) => Response.ok('OK');
        final composedHandler = middleware(handler);
        final response = await composedHandler(request);
        
        expect(response.statusCode, equals(400));
      });
    });

    group('security headers middleware', () {
      test('adds security headers to response', () async {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
          enforceHttps: true,
        );
        
        final middleware = config.createSecurityMiddleware();
        
        final request = Request(
          'GET',
          Uri.parse('https://localhost/api/test'),
          headers: {'origin': 'https://example.com'},
        );
        
        final handler = (Request req) => Response.ok('OK');
        final composedHandler = middleware(handler);
        final response = await composedHandler(request);
        
        expect(response.headers['X-Content-Type-Options'], equals('nosniff'));
        expect(response.headers['X-Frame-Options'], equals('DENY'));
        expect(response.headers['Content-Security-Policy'], isNotNull);
      });

      test('includes HSTS header when HTTPS enabled', () async {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
          enforceHttps: true,
          hstsMaxAge: '31536000',
        );
        
        final middleware = config.createSecurityMiddleware();
        
        final request = Request(
          'GET',
          Uri.parse('https://localhost/api/test'),
          headers: {'origin': 'https://example.com'},
        );
        
        final handler = (Request req) => Response.ok('OK');
        final composedHandler = middleware(handler);
        final response = await composedHandler(request);
        
        expect(
          response.headers['Strict-Transport-Security'],
          contains('max-age=31536000'),
        );
      });
    });

    group('createSecurityMiddleware', () {
      test('returns middleware function', () {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
        );
        
        final middleware = config.createSecurityMiddleware();
        
        expect(middleware, isNotNull);
      });

      test('middleware processes requests in correct order', () async {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
        );
        
        final middleware = config.createSecurityMiddleware();
        
        final request = Request(
          'GET',
          Uri.parse('https://localhost/api/test'),
          headers: {'origin': 'https://example.com'},
        );
        
        final handler = (Request req) => Response.ok('OK');
        final composedHandler = middleware(handler);
        final response = await composedHandler(request);
        
        expect(response.statusCode, equals(200));
      });
    });

    group('printSecurityChecklistProduction', () {
      test('does not throw error', () {
        final config = SecurityConfig(
          allowedOrigins: ['https://example.com'],
        );
        
        expect(
          () => config.printSecurityChecklistProduction(),
          returnsNormally,
        );
      });
    });
  });

  group('SecurityConfigException', () {
    test('can be thrown and caught', () {
      expect(
        () => throw SecurityConfigException('Test error'),
        throwsA(isA<SecurityConfigException>()),
      );
    });

    test('includes message in toString', () {
      final exception = SecurityConfigException('Test error message');
      
      expect(
        exception.toString(),
        contains('Test error message'),
      );
    });
  });
}
