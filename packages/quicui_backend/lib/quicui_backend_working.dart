import 'dart:async';
import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'src/security_config.dart';

// Export security configuration for external use
export 'src/security_config.dart' show SecurityConfig, SecurityConfigException;

/// Simple QuicUI Backend for local development
class CodePushBackend {
  final String host;
  final int port;
  
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
        return shelf.Response.ok(
          '{"status":"healthy"}',
          headers: {'Content-Type': 'application/json'},
        );
      });

      // API v1 endpoints
      router.get('/api/v1/apps', (shelf.Request request) {
        return shelf.Response.ok(
          '{"apps":[]}',
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
          .addMiddleware(securityConfig.createSecurityMiddleware())
          .addMiddleware(_errorHandlingMiddleware)
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

// Error handling middleware
shelf.Middleware _errorHandlingMiddleware = (innerHandler) {
  return (shelf.Request request) async {
    try {
      return await innerHandler(request);
    } catch (e) {
      print('❌ Error: $e');
      return shelf.Response.internalServerError(
        body: '{"error":"Internal server error"}',
        headers: {'Content-Type': 'application/json'},
      );
    }
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
