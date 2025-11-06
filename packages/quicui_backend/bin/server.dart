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

import 'dart:convert';
import 'dart:io' as io_file;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

// Storage for patches (in-memory for demo)
final Map<String, PatchInfo> _patches = {
  'patch-v9.0.0': PatchInfo(
    patchId: 'patch-v9.0.0',
    version: '9.0.0',
    appId: 'com.example.quicui_production_test',
    uncompressedPath: '/Users/admin/Documents/quicui2/test_apps/quicui_production_test/patch_v9.0.0.quicui',
    compressedPaths: {},
    uncompressedSize: 1024,
    compressedSizes: {},
    hash: 'test-hash-123',
    createdAt: DateTime.now(),
  ),
};

class PatchInfo {
  final String patchId;
  final String version;
  final String appId;
  final String uncompressedPath;
  final Map<String, String> compressedPaths; // compression -> path
  final int uncompressedSize;
  final Map<String, int> compressedSizes;
  final String hash;
  final DateTime createdAt;

  PatchInfo({
    required this.patchId,
    required this.version,
    required this.appId,
    required this.uncompressedPath,
    required this.compressedPaths,
    required this.uncompressedSize,
    required this.compressedSizes,
    required this.hash,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'patchId': patchId,
        'version': version,
        'appId': appId,
        'uncompressedSize': uncompressedSize,
        'compressedSizes': compressedSizes,
        'compressionAvailable': compressedPaths.keys.toList(),
        'hash': hash,
        'createdAt': createdAt.toIso8601String(),
      };
}

Router createRouter() {
  final router = Router();

  // Health check
  router.get('/health', (Request request) {
    return Response.ok('OK', headers: {'content-type': 'application/json'});
  });

  // Check for patches - with compression support
  router.post('/api/v1/patches/check', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body);
      
      final appId = data['appId'] as String?;
      final currentVersion = data['currentVersion'] as String?;
      final acceptCompression = data['acceptCompression'] as List?;
      
      if (appId == null || currentVersion == null) {
        return Response.badRequest(
          body: json.encode({'error': 'appId and currentVersion required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      // Find available patches for this app
      final availablePatches = _patches.values.where((p) => 
        p.appId == appId && p.version != currentVersion
      ).toList();

      if (availablePatches.isEmpty) {
        return Response.ok(
          json.encode({
            'patchAvailable': false,
            'message': 'No patches available'
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      // Sort patches by version and get the latest (highest version number)
      availablePatches.sort((a, b) {
        // Simple version comparison for x.y.z format
        final aParts = a.version.split('.').map(int.parse).toList();
        final bParts = b.version.split('.').map(int.parse).toList();
        
        for (int i = 0; i < 3; i++) {
          final aVal = i < aParts.length ? aParts[i] : 0;
          final bVal = i < bParts.length ? bParts[i] : 0;
          if (aVal != bVal) return bVal.compareTo(aVal); // Descending order (latest first)
        }
        return 0;
      });

      final patch = availablePatches.first; // Latest version
      
      // Determine best compression format
      String? compressionFormat;
      int downloadSize = patch.uncompressedSize;
      
      if (acceptCompression != null && acceptCompression.isNotEmpty) {
        // Client supports compression - prefer xz > bz2 > gz
        for (final format in ['xz', 'bz2', 'gz']) {
          if (acceptCompression.contains(format) && 
              patch.compressedPaths.containsKey(format)) {
            compressionFormat = format;
            downloadSize = patch.compressedSizes[format]!;
            break;
          }
        }
      }

      return Response.ok(
        json.encode({
          'patchAvailable': true,
          'patchId': patch.patchId,
          'version': patch.version,
          'downloadSize': downloadSize,
          'uncompressedSize': patch.uncompressedSize,
          'compression': compressionFormat,
          'hash': patch.hash,
          'downloadUrl': '/api/v1/patches/download/${patch.patchId}',
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Server error: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  // Download patch - serves compressed or uncompressed
  router.get('/api/v1/patches/download/<patchId>', (Request request, String patchId) async {
    try {
      final patch = _patches[patchId];
      if (patch == null) {
        return Response.notFound(
          json.encode({'error': 'Patch not found'}),
          headers: {'content-type': 'application/json'},
        );
      }

      // Check Accept-Encoding header for compression preference
      final acceptEncoding = request.headers['accept-encoding'] ?? '';
      String? compressionFormat;
      String filePath = patch.uncompressedPath;

      // Prefer xz > bz2 > gz based on client support
      for (final format in ['xz', 'bz2', 'gz']) {
        if (acceptEncoding.contains(format) && 
            patch.compressedPaths.containsKey(format)) {
          compressionFormat = format;
          filePath = patch.compressedPaths[format]!;
          break;
        }
      }

      // In production, read actual file
      final file = io_file.File(filePath);
      if (!await file.exists()) {
        return Response.notFound(
          json.encode({'error': 'Patch file not found on disk'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final bytes = await file.readAsBytes();
      final headers = {
        'content-type': 'application/octet-stream',
        'content-length': '${bytes.length}',
        'x-patch-version': patch.version,
        'x-patch-hash': patch.hash,
        'x-uncompressed-size': '${patch.uncompressedSize}',
      };

      if (compressionFormat != null) {
        headers['content-encoding'] = compressionFormat;
        headers['x-compression-format'] = compressionFormat;
      }

      print('📥 Serving patch: ${patch.patchId}');
      print('   Version: ${patch.version}');
      print('   Size: ${bytes.length} bytes');
      print('   Compression: ${compressionFormat ?? "none"}');

      return Response.ok(bytes, headers: headers);
    } catch (e) {
      return Response.internalServerError(
        body: json.encode({'error': 'Download error: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  // List patches
  router.get('/api/v1/patches', (Request request) {
    final patchList = _patches.values.map((p) => p.toJson()).toList();
    return Response.ok(
      json.encode({
        'patches': patchList,
        'total': patchList.length,
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  // Register patch - for testing/demo
  router.post('/api/v1/patches/register', (Request request) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body);

      final patchId = data['patchId'] as String;
      final version = data['version'] as String;
      final appId = data['appId'] as String;
      final uncompressedPath = data['uncompressedPath'] as String;
      final compressedPaths = Map<String, String>.from(data['compressedPaths'] ?? {});
      final uncompressedSize = data['uncompressedSize'] as int;
      final compressedSizes = Map<String, int>.from(data['compressedSizes'] ?? {});
      final hash = data['hash'] as String;

      final patch = PatchInfo(
        patchId: patchId,
        version: version,
        appId: appId,
        uncompressedPath: uncompressedPath,
        compressedPaths: compressedPaths,
        uncompressedSize: uncompressedSize,
        compressedSizes: compressedSizes,
        hash: hash,
        createdAt: DateTime.now(),
      );

      _patches[patchId] = patch;

      print('✅ Patch registered: $patchId');
      print('   Version: $version');
      print('   App: $appId');
      print('   Uncompressed: $uncompressedSize bytes');
      print('   Compressed formats: ${compressedPaths.keys.join(", ")}');

      return Response.ok(
        json.encode({
          'success': true,
          'patchId': patchId,
          'message': 'Patch registered successfully',
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.badRequest(
        body: json.encode({'error': 'Registration error: $e'}),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  // Create patch (legacy endpoint)
  router.post('/api/v1/patches', (Request request) {
    return Response.ok(
      '{"patchId": "patch-001", "status": "created"}',
      headers: {'content-type': 'application/json'},
    );
  });

  // Get analytics
  router.get('/api/v1/analytics', (Request request) {
    int totalUncompressed = 0;
    int totalCompressed = 0;
    int patchesWithCompression = 0;

    for (final patch in _patches.values) {
      totalUncompressed += patch.uncompressedSize;
      if (patch.compressedPaths.containsKey('xz')) {
        totalCompressed += patch.compressedSizes['xz']!;
        patchesWithCompression++;
      } else {
        totalCompressed += patch.uncompressedSize;
      }
    }

    final compressionRatio = totalUncompressed > 0
        ? (1 - totalCompressed / totalUncompressed) * 100
        : 0.0;

    return Response.ok(
      json.encode({
        'totalPatches': _patches.length,
        'patchesWithCompression': patchesWithCompression,
        'totalUncompressedSize': totalUncompressed,
        'totalCompressedSize': totalCompressed,
        'compressionRatio': compressionRatio.toStringAsFixed(2),
        'bandwidthSaved': totalUncompressed - totalCompressed,
      }),
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

  // Listen on all network interfaces (0.0.0.0) to accept connections from devices
  final server = await io.serve(handler, io_file.InternetAddress.anyIPv4, 8080);
  print('Server listening on http://0.0.0.0:${server.port}');
  print('Accessible at http://192.168.20.100:${server.port} from devices');
}
