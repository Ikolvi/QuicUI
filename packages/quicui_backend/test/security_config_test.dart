import 'package:test/test.dart';
import '../lib/src/security_config.dart';

void main() {
  group('SecurityConfig', () {
    test('creates config with valid parameters', () {
      final config = SecurityConfig(
        allowedOrigins: ['https://example.com'],
        enforceHttps: false,
      );
      expect(config.allowedOrigins, equals(['https://example.com']));
    });

    test('requires at least one allowed origin', () {
      expect(
        () => SecurityConfig(allowedOrigins: []),
        throwsA(isA<SecurityConfigException>()),
      );
    });

    test('allows disabling HTTPS for development', () {
      final config = SecurityConfig(
        enforceHttps: false,
        allowedOrigins: ['http://localhost:8080'],
      );
      expect(config.enforceHttps, false);
    });

    test('throws error if HTTPS enabled without certificate', () {
      expect(
        () => SecurityConfig(
          enforceHttps: true,
          tlsCertPath: null,
          allowedOrigins: ['https://example.com'],
        ),
        throwsA(isA<SecurityConfigException>()),
      );
    });

    test('sets default security headers', () {
      final config = SecurityConfig(
        allowedOrigins: ['https://example.com'],
        enforceHttps: false,
      );
      expect(config.xContentTypeOptions, equals('nosniff'));
      expect(config.xFrameOptions, equals('DENY'));
    });

    test('allows multiple CORS origins', () {
      final config = SecurityConfig(
        allowedOrigins: ['https://example.com', 'https://api.example.com'],
        enforceHttps: false,
      );
      expect(config.allowedOrigins.length, equals(2));
    });

    test('sets default allowed methods', () {
      final config = SecurityConfig(
        allowedOrigins: ['https://example.com'],
        enforceHttps: false,
      );
      expect(
        config.allowedMethods,
        equals(['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS']),
      );
    });

    test('sets default allowed headers', () {
      final config = SecurityConfig(
        allowedOrigins: ['https://example.com'],
        enforceHttps: false,
      );
      expect(
        config.allowedHeaders,
        equals(['Content-Type', 'Authorization', 'X-API-Key']),
      );
    });

    test('allows custom preflight cache time', () {
      final config = SecurityConfig(
        allowedOrigins: ['https://example.com'],
        enforceHttps: false,
        preflightCacheTime: 3600,
      );
      expect(config.preflightCacheTime, equals(3600));
    });

    test('sets default max request size', () {
      final config = SecurityConfig(
        allowedOrigins: ['https://example.com'],
        enforceHttps: false,
      );
      expect(config.maxRequestSize, equals(10 * 1024 * 1024));
    });

    test('allows custom max request size', () {
      final config = SecurityConfig(
        allowedOrigins: ['https://example.com'],
        enforceHttps: false,
        maxRequestSize: 50 * 1024 * 1024,
      );
      expect(config.maxRequestSize, equals(50 * 1024 * 1024));
    });

    test('sets default request timeout', () {
      final config = SecurityConfig(
        allowedOrigins: ['https://example.com'],
        enforceHttps: false,
      );
      expect(config.requestTimeout, equals(Duration(seconds: 30)));
    });

    test('allows custom request timeout', () {
      final config = SecurityConfig(
        allowedOrigins: ['https://example.com'],
        enforceHttps: false,
        requestTimeout: Duration(seconds: 60),
      );
      expect(config.requestTimeout, equals(Duration(seconds: 60)));
    });

    test('includes X-Content-Type-Options', () {
      final config = SecurityConfig(
        allowedOrigins: ['https://example.com'],
        enforceHttps: false,
        xContentTypeOptions: 'nosniff',
      );
      expect(config.xContentTypeOptions, equals('nosniff'));
    });

    test('includes X-Frame-Options', () {
      final config = SecurityConfig(
        allowedOrigins: ['https://example.com'],
        enforceHttps: false,
        xFrameOptions: 'DENY',
      );
      expect(config.xFrameOptions, equals('DENY'));
    });

    test('middleware function is not null', () {
      final config = SecurityConfig(
        allowedOrigins: ['https://example.com'],
        enforceHttps: false,
      );
      final middleware = config.createSecurityMiddleware();
      expect(middleware, isNotNull);
    });

    test('can throw SecurityConfigException', () {
      expect(
        () => throw SecurityConfigException('Test error'),
        throwsA(isA<SecurityConfigException>()),
      );
    });

    test('printSecurityChecklistProduction does not throw', () {
      final config = SecurityConfig(
        allowedOrigins: ['https://example.com'],
        enforceHttps: false,
      );
      expect(
        () => config.printSecurityChecklistProduction(),
        returnsNormally,
      );
    });

    test('allows wildcard origin', () {
      final config = SecurityConfig(
        allowedOrigins: ['*'],
        enforceHttps: false,
      );
      expect(config.allowedOrigins.contains('*'), true);
    });

    test('preserves origin order', () {
      final origins = [
        'https://example.com',
        'https://api.example.com',
        'https://app.example.com',
      ];
      final config = SecurityConfig(
        allowedOrigins: origins,
        enforceHttps: false,
      );
      expect(config.allowedOrigins, equals(origins));
    });

    test('allows debug mode configuration', () {
      final config = SecurityConfig(
        allowedOrigins: ['https://example.com'],
        enforceHttps: false,
        debugMode: true,
      );
      expect(config.debugMode, true);
    });

    test('debug mode defaults to false', () {
      final config = SecurityConfig(
        allowedOrigins: ['https://example.com'],
        enforceHttps: false,
      );
      expect(config.debugMode, false);
    });

    test('custom X-XSS-Protection header', () {
      final config = SecurityConfig(
        allowedOrigins: ['https://example.com'],
        enforceHttps: false,
        xXssProtection: '1; mode=block',
      );
      expect(config.xXssProtection, equals('1; mode=block'));
    });

    test('custom Content-Security-Policy', () {
      final csp = "default-src 'self'";
      final config = SecurityConfig(
        allowedOrigins: ['https://example.com'],
        enforceHttps: false,
        contentSecurityPolicy: csp,
      );
      expect(config.contentSecurityPolicy, equals(csp));
    });
  });
}
