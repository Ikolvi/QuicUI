/// QuicUI Backend Server
/// 
/// Shelf-based REST API server for QuicUI
/// 
/// Endpoints:
/// - POST /api/v1/patches/check - Check for available patches
/// - POST /api/v1/patches/download/{patchId} - Download patch
/// - POST /api/v1/patches - Create new patch
/// - GET /api/v1/patches - List patches
/// - DELETE /api/v1/patches/{patchId} - Delete patch
/// - POST /api/v1/releases - Create release
/// - GET /api/v1/analytics - Get analytics

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

Router createRouter() {
  final router = Router();

  // Health check
  router.get('/health', (Request request) {
    return Response.ok('OK', headers: {'content-type': 'application/json'});
  });

  // Check for patches
  router.post('/api/v1/patches/check', (Request request) {
    return Response.ok(
      '{"patchId": null, "message": "No patches available"}',
      headers: {'content-type': 'application/json'},
    );
  });

  // List patches
  router.get('/api/v1/patches', (Request request) {
    return Response.ok(
      '{"patches": []}',
      headers: {'content-type': 'application/json'},
    );
  });

  // Create patch
  router.post('/api/v1/patches', (Request request) {
    return Response.ok(
      '{"patchId": "patch-001", "status": "created"}',
      headers: {'content-type': 'application/json'},
    );
  });

  // Get analytics
  router.get('/api/v1/analytics', (Request request) {
    return Response.ok(
      '{"totalPatches": 0, "successRate": 0}',
      headers: {'content-type': 'application/json'},
    );
  });

  // 404 handler
  router.all('/<ignored|.*>', (Request request) {
    return Response.notFound('Not found');
  });

  return router;
}

void main(List<String> args) async {
  final router = createRouter();
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(router);

  final server = await io.serve(handler, 'localhost', 8080);
  print('Server listening on http://${server.address.host}:${server.port}');
}
