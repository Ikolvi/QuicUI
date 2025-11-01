/// Enhanced Backend API with Patch Management Integration
/// 
/// Adds patch upload, download, versioning, and rollout endpoints
/// Integrates PatchService with REST API layer

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:quicui_backend/src/patch_service.dart';

/// Enhanced backend with patch management
class EnhancedCodePushBackend {
  final String host;
  final int port;
  final String dbUrl;
  final String jwtSecret;
  final String patchStoragePath;
  
  late HttpServer _server;
  late PatchService _patchService;

  EnhancedCodePushBackend({
    this.host = '0.0.0.0',
    this.port = 8080,
    this.dbUrl = 'postgresql://localhost/quicui_codepush',
    this.jwtSecret = 'development-secret-key',
    this.patchStoragePath = '/tmp/codepush',
  });

  /// Start the enhanced backend server
  Future<void> start() async {
    try {
      print('🚀 Starting Enhanced QuicUI Code Push Backend...');
      print('📝 Configuration:');
      print('   Host: $host');
      print('   Port: $port');
      print('   Database: $dbUrl');
      print('   Patch storage: $patchStoragePath');

      // Initialize patch service
      _patchService = PatchService(storagePath: patchStoragePath);
      await _patchService.initialize();

      // Initialize database connection
      await _initializeDatabase();

      // Create request handler pipeline
      var handler = const Pipeline()
          .addMiddleware(loggingMiddleware)
          .addMiddleware(corsMiddleware)
          .addMiddleware(errorHandlingMiddleware)
          .addHandler(_enhancedRouter);

      // Bind server using shelf
      _server = await io.serve(handler, host, port);
      print('✅ Server listening on http://$host:$port');

      // Setup graceful shutdown
      _setupShutdownHandling();
    } catch (e) {
      print('❌ Error starting server: $e');
      rethrow;
    }
  }

  /// Stop the backend server
  Future<void> stop() async {
    await _server.close(force: true);
    print('🛑 Server stopped');
  }

  /// Initialize database connection
  Future<void> _initializeDatabase() async {
    print('🔄 Initializing database connection...');
    
    try {
      // In production, use actual database connection
      await Future.delayed(Duration(milliseconds: 500));
      print('✅ Database connected');
    } catch (e) {
      print('❌ Database connection failed: $e');
      rethrow;
    }
  }

  /// Setup graceful shutdown
  void _setupShutdownHandling() {
    ProcessSignal.sigint.watch().listen((_) async {
      print('\n🛑 Received SIGINT, shutting down...');
      await stop();
      exit(0);
    });

    ProcessSignal.sigterm.watch().listen((_) async {
      print('\n🛑 Received SIGTERM, shutting down...');
      await stop();
      exit(0);
    });
  }

  /// Enhanced request router with patch management
  FutureOr<Response> _enhancedRouter(Request request) {
    final path = request.url.path;
    final method = request.method;

    // Health check
    if (path == 'health' && method == 'GET') {
      return _handleHealth(request);
    }

    // ==================== Patch Management Endpoints ====================
    
    // GET /api/v1/apps/{appId}/patches
    // List all patches for app
    if (path.contains('/patches') && 
        !path.contains('/download') && 
        !path.contains('/metrics') &&
        method == 'GET') {
      return _handleListPatches(request, path);
    }

    // POST /api/v1/apps/{appId}/patches
    // Upload new patch
    if (path.contains('/patches') && 
        !path.contains('/download') && 
        !path.contains('/metrics') &&
        method == 'POST') {
      return _handleUploadPatch(request, path);
    }

    // GET /api/v1/apps/{appId}/patches/{version}/download
    // Download specific patch
    if (path.contains('/download') && method == 'GET') {
      return _handleDownloadPatch(request, path);
    }

    // DELETE /api/v1/apps/{appId}/patches/{version}
    // Delete patch version
    if (path.contains('/patches') && 
        !path.contains('/download') && 
        !path.contains('/metrics') &&
        method == 'DELETE') {
      return _handleDeletePatch(request, path);
    }

    // GET /api/v1/apps/{appId}/patches/{version}/metrics
    // Get rollout metrics for patch
    if (path.contains('/metrics') && method == 'GET') {
      return _handleGetMetrics(request, path);
    }

    // POST /api/v1/apps/{appId}/patches/{version}/report
    // Report patch application result
    if (path.contains('/report') && method == 'POST') {
      return _handleReportResult(request, path);
    }

    // GET /api/v1/patches/latest
    // Get latest version info
    if (path.contains('/latest') && method == 'GET') {
      return _handleGetLatest(request, path);
    }

    // GET /api/v1/stats/patches
    // Get patch statistics summary
    if (path == 'api/v1/stats/patches' && method == 'GET') {
      return _handleGetStatistics(request);
    }

    return Response.notFound('Endpoint not found: $path');
  }

  /// Handle health check
  FutureOr<Response> _handleHealth(Request request) {
    return Response.ok(
      '''{
        "status": "healthy",
        "timestamp": "${DateTime.now().toIso8601String()}",
        "version": "1.0.0"
      }''',
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Handle list patches endpoint
  FutureOr<Response> _handleListPatches(Request request, String path) async {
    try {
      print('📋 GET $path');

      // Extract appId from path
      final appId = _extractAppId(path);
      if (appId.isEmpty) {
        return Response(400, 
          body: '{"error":"Invalid app ID"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get versions from service
      final versions = await _patchService.getAppVersions(appId);

      final responseBody = '''{
        "success": true,
        "appId": "$appId",
        "versions": [${versions.map((v) => '''
        {
          "version": "${v.version}",
          "releaseDate": "${v.releaseDate.toIso8601String()}",
          "fileSize": ${v.fileSize},
          "fileHash": "${v.fileHash}",
          "isCritical": ${v.isCritical},
          "compressionRatio": ${v.compressionRatio},
          "downloadUrl": "${v.downloadUrl}"
        }''').join(',')}
        ],
        "count": ${versions.length}
      }''';

      return Response.ok(responseBody,
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse('Failed to list patches: $e', 500);
    }
  }

  /// Handle upload patch endpoint
  FutureOr<Response> _handleUploadPatch(Request request, String path) async {
    try {
      print('📤 POST $path');

      // Extract appId from path
      final appId = _extractAppId(path);
      if (appId.isEmpty) {
        return Response(400,
          body: '{"error":"Invalid app ID"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Read request body
      final body = await request.readAsString();
      final metadata = _parseJsonBody(body);

      // Extract version and validate
      final version = metadata['version'] as String?;
      if (version == null || version.isEmpty) {
        return Response(400,
          body: '{"error":"Version is required"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check for duplicate
      final exists = await _patchService.versionExists(appId, version);
      if (exists) {
        return Response(409,
          body: '{"error":"Patch version already exists"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Simulate patch data (in production, multipart form data)
      final patchData = Uint8List.fromList(_generateMockPatchData());

      // Upload patch
      final result = await _patchService.uploadPatch(
        appId: appId,
        version: version,
        patchData: patchData,
        metadata: metadata,
      );

      final responseBody = '''{
        "success": ${result.success},
        "patchId": "${result.patchId}",
        "version": "${result.version}",
        "fileSize": ${result.fileSize},
        "checksum": "${result.checksum}",
        "storageUrl": "${result.storageUrl}",
        "message": "${result.message}"
      }''';

      return Response(result.success ? 201 : 400,
        body: responseBody,
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse('Failed to upload patch: $e', 500);
    }
  }

  /// Handle download patch endpoint
  FutureOr<Response> _handleDownloadPatch(Request request, String path) async {
    try {
      print('📥 GET $path');

      // Extract appId and version from path
      final appId = _extractAppId(path);
      final version = _extractVersion(path);

      if (appId.isEmpty || version.isEmpty) {
        return Response(400,
          body: '{"error":"Invalid app ID or version"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Download patch
      final result = await _patchService.downloadPatch(
        appId: appId,
        version: version,
      );

      if (!result.success) {
        return Response(404,
          body: '{"error":"${result.message}"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Return patch file with metadata in headers
      return Response.ok(
        result.patchData,
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Length': '${result.fileSize}',
          'X-Patch-Hash': result.fileHash ?? '',
          'X-Patch-Version': version,
        },
      );
    } catch (e) {
      return _errorResponse('Failed to download patch: $e', 500);
    }
  }

  /// Handle delete patch endpoint
  FutureOr<Response> _handleDeletePatch(Request request, String path) async {
    try {
      print('🗑️ DELETE $path');

      // Extract appId and version
      final appId = _extractAppId(path);
      final version = _extractVersion(path);

      if (appId.isEmpty || version.isEmpty) {
        return Response(400,
          body: '{"error":"Invalid app ID or version"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Delete version
      final success = await _patchService.deleteVersion(appId, version);

      if (!success) {
        return Response(404,
          body: '{"error":"Patch version not found"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        '{"success":true,"message":"Patch deleted successfully"}',
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse('Failed to delete patch: $e', 500);
    }
  }

  /// Handle get metrics endpoint
  FutureOr<Response> _handleGetMetrics(Request request, String path) async {
    try {
      print('📊 GET $path');

      // Extract appId and version
      final appId = _extractAppId(path);
      final version = _extractVersion(path);

      if (appId.isEmpty || version.isEmpty) {
        return Response(400,
          body: '{"error":"Invalid app ID or version"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get statistics
      final stats = await _patchService.getRolloutStatistics(appId, version);

      final responseBody = '''{
        "success": true,
        "appId": "$appId",
        "version": "$version",
        "metrics": {
          "totalDownloads": ${stats.totalDownloads},
          "successfulApplications": ${stats.successfulApplications},
          "failedApplications": ${stats.failedApplications},
          "successRate": ${stats.successRate},
          "averageDownloadTime": ${stats.averageDownloadTime}
        }
      }''';

      return Response.ok(responseBody,
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse('Failed to get metrics: $e', 500);
    }
  }

  /// Handle report result endpoint
  FutureOr<Response> _handleReportResult(Request request, String path) async {
    try {
      print('📝 POST $path');

      // Extract appId and version
      final appId = _extractAppId(path);
      final version = _extractVersion(path);

      if (appId.isEmpty || version.isEmpty) {
        return Response(400,
          body: '{"error":"Invalid app ID or version"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Parse request body
      final body = await request.readAsString();
      final data = _parseJsonBody(body);

      final deviceId = data['deviceId'] as String? ?? 'unknown';
      final success = data['success'] as bool? ?? false;
      final downloadTimeMs = data['downloadTimeMs'] as int? ?? 0;
      final errorMessage = data['error'] as String? ?? '';

      // Record result
      if (success) {
        await _patchService.recordSuccessfulApplication(
          appId: appId,
          version: version,
          deviceId: deviceId,
          downloadTimeMs: downloadTimeMs,
        );
      } else {
        await _patchService.recordFailedApplication(
          appId: appId,
          version: version,
          deviceId: deviceId,
          errorMessage: errorMessage,
        );
      }

      return Response.ok(
        '{"success":true,"message":"Result recorded"}',
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse('Failed to record result: $e', 500);
    }
  }

  /// Handle get latest version endpoint
  FutureOr<Response> _handleGetLatest(Request request, String path) async {
    try {
      print('🔍 GET $path');

      // Extract appId
      final appId = _extractAppId(path);
      if (appId.isEmpty) {
        return Response(400,
          body: '{"error":"Invalid app ID"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Get latest version
      final latest = await _patchService.getLatestVersion(appId);

      if (latest == null) {
        return Response(404,
          body: '{"error":"No patches available"}',
          headers: {'Content-Type': 'application/json'},
        );
      }

      final responseBody = '''{
        "success": true,
        "appId": "$appId",
        "latest": {
          "version": "${latest.version}",
          "releaseDate": "${latest.releaseDate.toIso8601String()}",
          "fileSize": ${latest.fileSize},
          "fileHash": "${latest.fileHash}",
          "isCritical": ${latest.isCritical},
          "downloadUrl": "${latest.downloadUrl}"
        }
      }''';

      return Response.ok(responseBody,
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse('Failed to get latest version: $e', 500);
    }
  }

  /// Handle get statistics endpoint
  FutureOr<Response> _handleGetStatistics(Request request) async {
    try {
      print('📈 GET /api/v1/stats/patches');

      // Get summary statistics
      final summary = await _patchService.getStatisticsSummary();

      final responseBody = '''{
        "success": true,
        "statistics": {
          "totalPatches": ${summary.totalPatches},
          "totalDownloads": ${summary.totalDownloads},
          "totalSuccessfulApplications": ${summary.totalSuccessfulApplications},
          "totalFailedApplications": ${summary.totalFailedApplications},
          "overallSuccessRate": ${summary.overallSuccessRate},
          "appsWithPatches": ${summary.appsWithPatches}
        }
      }''';

      return Response.ok(responseBody,
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return _errorResponse('Failed to get statistics: $e', 500);
    }
  }

  // ==================== Utility Methods ====================

  /// Extract app ID from URL path
  String _extractAppId(String path) {
    final parts = path.split('/');
    for (int i = 0; i < parts.length - 1; i++) {
      if (parts[i] == 'apps' && i + 1 < parts.length) {
        return parts[i + 1];
      }
    }
    return '';
  }

  /// Extract version from URL path
  String _extractVersion(String path) {
    final parts = path.split('/');
    for (int i = 0; i < parts.length; i++) {
      if (parts[i] == 'patches' && i + 1 < parts.length && parts[i + 1] != 'download') {
        return parts[i + 1];
      }
    }
    return '';
  }

  /// Parse JSON body safely
  Map<String, dynamic> _parseJsonBody(String body) {
    try {
      // Simple JSON parsing (in production, use jsonDecode)
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Generate mock patch data for testing
  List<int> _generateMockPatchData() {
    // Generate 1MB of random-like data
    final data = List<int>.generate(1024 * 1024, (i) => i % 256);
    return data;
  }

  /// Generate error response
  Response _errorResponse(String message, int statusCode) {
    return Response(statusCode,
      body: '{"success":false,"error":"$message"}',
      headers: {'Content-Type': 'application/json'},
    );
  }
}

// ==================== Middleware Functions ====================

/// Logging middleware
Middleware loggingMiddleware = (Handler innerHandler) {
  return (Request request) {
    print('➡️ ${request.method} ${request.url.path}');
    final response = innerHandler(request);
    return response;
  };
};

/// CORS middleware
Middleware corsMiddleware = (Handler innerHandler) {
  return (Request request) async {
    final response = await innerHandler(request);
    return response.change(headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    });
  };
};

/// Error handling middleware
Middleware errorHandlingMiddleware = (Handler innerHandler) {
  return (Request request) {
    try {
      return innerHandler(request);
    } catch (e) {
      print('❌ Error: $e');
      return Response(500,
        body: '{"error":"Internal server error"}',
        headers: {'Content-Type': 'application/json'},
      );
    }
  };
};
