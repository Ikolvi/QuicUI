import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'src/security_config.dart';
import 'src/cache_service.dart';
import 'src/cached_database.dart';
import 'src/database_pool.dart';
import 'src/response_optimization.dart';
import 'src/metrics_service.dart';
import 'src/request_validator.dart';
import 'src/rate_limiter.dart';
import 'src/security_headers.dart';
import 'src/error_handler.dart';

// Export security configuration for external use
export 'src/security_config.dart' show SecurityConfig, SecurityConfigException;
export 'src/cache_service.dart' show CacheService;
export 'src/cached_database.dart' show CachedDatabase;
export 'src/request_validator.dart' show RequestValidator, ParameterRule, BodySchema;
export 'src/rate_limiter.dart' show RateLimiter, RateLimitTier, RateLimitStatus;
export 'src/security_headers.dart' show SecurityHeaders, CorsConfig, SecurityHeadersConfig;
export 'src/error_handler.dart' show ErrorHandler, ErrorResponse, ErrorResponses;

/// Simple QuicUI Backend for local development
class CodePushBackend {
  final String host;
  final int port;
  
  late CacheService cacheService;
  late CachedDatabase cachedDb;
  late DatabasePool databasePool;
  late QueryOptimizer queryOptimizer;
  late MetricsService metricsService;
  late RequestValidator requestValidator;
  late RateLimiter rateLimiter;
  late SecurityHeaders securityHeaders;
  late ErrorHandler errorHandler;
  late RateLimitMiddlewareHelper rateLimitHelper;
  
  CodePushBackend({
    this.host = 'localhost',
    this.port = 8080,
  });

  /// Start the backend server
  Future<void> start() async {
    try {
      print('🚀 Starting QuicUI Code Push Backend...');
      print('📝 Configuration:');
      print('   Host: $host');
      print('   Port: $port');
      print('   Environment: Development');

      // Initialize cache service
      cacheService = CacheService();
      await cacheService.initialize();

      // Initialize database pool
      databasePool = DatabasePool(
        minConnections: 5,
        maxConnections: 20,
        idleTimeout: const Duration(minutes: 5),
      );
      await databasePool.initialize();

      // Initialize query optimizer
      queryOptimizer = QueryOptimizer();

      // Initialize metrics service
      metricsService = MetricsService();

      // Initialize cached database
      cachedDb = CachedDatabase(cache: cacheService);

      // Initialize security services (Phase 5.3)
      requestValidator = RequestValidator();
      rateLimiter = RateLimiter();
      rateLimitHelper = RateLimitMiddlewareHelper(rateLimiter: rateLimiter);
      _rateLimitHelperInstance = rateLimitHelper;
      securityHeaders = SecurityHeaders(
        securityConfig: SecurityHeadersConfig(),
        corsConfig: CorsConfig(
          allowedOrigins: ['http://localhost:3000', 'http://localhost:3001'],
        ),
      );
      errorHandler = ErrorHandler(hideStackTraces: true, logErrors: true);

      print('✅ Security services initialized (Phase 5.3)');
      print('   - Input validation & sanitization');
      print('   - Rate limiting (100-1000 req/min per tier)');
      print('   - Security headers & CORS');
      print('   - Standardized error handling');

      // Load security configuration
      late SecurityConfig securityConfig;
      try {
        securityConfig = SecurityConfig.fromEnvironment();
        print('✅ Security configuration loaded');
      } catch (e) {
        print('⚠️ Security configuration warning: $e');
        // In development, use default config
        securityConfig = SecurityConfig(
          allowedOrigins: ['http://localhost:3000', 'http://localhost:3001'],
          debugMode: true,
        );
        print('✅ Using default development security config');
      }

      // Print security checklist
      securityConfig.printSecurityChecklistProduction();

      // Create router
      final router = Router();

      // Health check endpoint
      router.get('/health', (shelf.Request request) {
        metricsService.updateHealth(component: 'api', healthy: true);
        final health = {
          'status': 'healthy',
          'cache_service': metricsService.cacheServiceHealthy.value.toInt() == 1,
          'database_pool': metricsService.dbPoolHealthy.value.toInt() == 1,
          'uptime_seconds': metricsService.uptime.value.toInt(),
        };
        return shelf.Response.ok(
          jsonEncode(health),
          headers: {'Content-Type': 'application/json'},
        );
      });

      // Prometheus metrics endpoint
      router.get('/metrics/prometheus', (shelf.Request request) {
        return shelf.Response.ok(
          metricsService.exportPrometheus(),
          headers: {'Content-Type': 'text/plain; charset=utf-8'},
        );
      });

      // JSON metrics endpoint
      router.get('/metrics/json', (shelf.Request request) {
        return shelf.Response.ok(
          jsonEncode(metricsService.exportJson()),
          headers: {'Content-Type': 'application/json'},
        );
      });

      // Cache stats endpoint
      router.get('/metrics/cache', (shelf.Request request) async {
        final stats = await cacheService.getStats();
        return shelf.Response.ok(
          jsonEncode(stats),
          headers: {'Content-Type': 'application/json'},
        );
      });

      // Database pool stats endpoint
      router.get('/metrics/database', (shelf.Request request) {
        final stats = databasePool.getStats();
        return shelf.Response.ok(
          jsonEncode(stats),
          headers: {'Content-Type': 'application/json'},
        );
      });

      // Database query stats endpoint
      router.get('/metrics/queries', (shelf.Request request) {
        final stats = queryOptimizer.getQueryStats();
        return shelf.Response.ok(
          jsonEncode(stats),
          headers: {'Content-Type': 'application/json'},
        );
      });

      // API v1 endpoints
      router.get('/api/v1/apps', (shelf.Request request) async {
        final apps = await cachedDb.listApps();
        return shelf.Response.ok(
          jsonEncode({'apps': apps}),
          headers: {'Content-Type': 'application/json'},
        );
      });

      router.post('/api/v1/auth/login', (shelf.Request request) {
        return shelf.Response.ok(
          '{"token":"jwt.token.here"}',
          headers: {'Content-Type': 'application/json'},
        );
      });

      // 404 handler
      router.all('/<path|.*>', (shelf.Request request) {
        return shelf.Response.notFound('{"error":"Not found"}',
          headers: {'Content-Type': 'application/json'},
        );
      });

      // Create handler with security middleware
      var handler = shelf.Pipeline()
          .addMiddleware(_loggingMiddleware)
          .addMiddleware(errorHandler.createMiddleware())
          .addMiddleware(_rateLimitMiddleware)
          .addMiddleware(securityHeaders.createMiddleware())
          .addMiddleware(compressionMiddleware())
          .addMiddleware(cacheControlMiddleware())
          .addMiddleware(responseOptimizationMiddleware())
          .addMiddleware(securityConfig.createSecurityMiddleware())
          .addHandler(router);

      // Start server
      final server = await shelf_io.serve(handler, host, port);
      print('✅ Server listening on http://${server.address.host}:${server.port}');
      print('🎉 Backend ready! Test with: curl http://localhost:$port/health');
    } catch (e) {
      print('❌ Error starting server: $e');
      rethrow;
    }
  }

  /// Stop the backend server
  Future<void> stop() async {
    print('🛑 Server stopped');
  }
}

// Logging middleware
shelf.Middleware _loggingMiddleware = (innerHandler) {
  return (shelf.Request request) async {
    print('📨 ${request.method} ${request.url.path}');
    final response = await innerHandler(request);
    print('📤 ${response.statusCode} ${request.method} ${request.url.path}');
    return response;
  };
};

// Rate limiting middleware
late RateLimitMiddlewareHelper _rateLimitHelperInstance;
shelf.Middleware get _rateLimitMiddleware => (innerHandler) {
  return (shelf.Request request) async {
    final clientIp = _rateLimitHelperInstance.extractClientIp(
      request.headers,
      request.context['remote_address'].toString(),
    );
    final tier = _rateLimitHelperInstance.determineTier(request.url.path);
    
    final (allowed, headers) = _rateLimitHelperInstance.checkAndGetHeaders(clientIp, tier);
    
    if (!allowed) {
      final error = ErrorResponses.rateLimitExceeded(
        tier,
        headers['Retry-After'] != null ? int.parse(headers['Retry-After']!) : 60,
        ErrorHandler.generateTraceId(),
      );
      return error.toResponse().change(headers: headers);
    }
    
    var response = await innerHandler(request);
    return response.change(headers: {...response.headers, ...headers});
  };
};

// Main entry point
Future<void> main(List<String> arguments) async {
  final backend = CodePushBackend(
    host: Platform.environment['SERVER_HOST'] ?? 'localhost',
    port: int.parse(Platform.environment['SERVER_PORT'] ?? '8080'),
  );

  // Handle shutdown signals
  ProcessSignal.sigint.watch().listen((_) {
    print('\n🛑 Shutting down gracefully...');
    backend.stop();
    exit(0);
  });

  await backend.start();
}
