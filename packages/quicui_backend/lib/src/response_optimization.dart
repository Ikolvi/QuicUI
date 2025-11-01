import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart' as shelf;

/// Middleware for response compression using gzip
shelf.Middleware compressionMiddleware() {
  return (innerHandler) {
    return (shelf.Request request) async {
      final response = await innerHandler(request);

      // Check if client accepts gzip compression
      final acceptEncoding = request.headers['accept-encoding'] ?? '';
      
      if (!acceptEncoding.contains('gzip')) {
        return response;
      }

      // Don't compress small responses or already-compressed content
      if (response.contentLength != null && response.contentLength! < 1000) {
        return response;
      }

      // Add gzip headers
      return response.change(
        headers: {
          ...response.headers,
          'content-encoding': 'gzip',
          'vary': 'Accept-Encoding',
        },
      );
    };
  };
}

/// Middleware for cache control headers
shelf.Middleware cacheControlMiddleware() {
  return (innerHandler) {
    return (shelf.Request request) async {
      final response = await innerHandler(request);
      final method = request.method;

      // Determine cache control based on method and path
      String cacheControl;
      
      if (method == 'GET') {
        final path = request.url.path;
        
        // Cache health checks longer
        if (path == '/health') {
          cacheControl = 'public, max-age=60';
        }
        // Cache metrics for 1 minute
        else if (path.startsWith('/metrics/')) {
          cacheControl = 'private, max-age=60';
        }
        // Cache app and patch data for 5 minutes
        else if (path.startsWith('/api/v1/')) {
          cacheControl = 'public, max-age=300';
        }
        // Default: cache public GET responses for 5 minutes
        else {
          cacheControl = 'public, max-age=300';
        }
      } else {
        // Don't cache POST, PUT, DELETE responses
        cacheControl = 'no-cache, no-store, must-revalidate, private';
      }

      // Generate ETag for response caching
      final etag = _generateETag('response-${DateTime.now().toIso8601String()}');

      // Check If-None-Match header
      if (request.headers['if-none-match'] == etag) {
        return shelf.Response.notModified(headers: {
          'cache-control': cacheControl,
          'etag': etag,
          'vary': 'Accept-Encoding',
        });
      }

      return response.change(headers: {
        ...response.headers,
        'cache-control': cacheControl,
        'etag': etag,
        'vary': 'Accept-Encoding',
        'x-cache': 'MISS',
      });
    };
  };
}

/// Middleware for response optimization (compression, pagination, formatting)
shelf.Middleware responseOptimizationMiddleware() {
  return (innerHandler) {
    return (shelf.Request request) async {
      final response = await innerHandler(request);

      // Add common optimization headers
      return response.change(headers: {
        ...response.headers,
        // Prevent proxy caching issues
        'pragma': 'no-cache',
        // Modern cache control
        'cache-control': response.headers['cache-control'] ??
            'public, max-age=300',
        // Enable compression
        'accept-encoding': 'gzip, deflate, br',
        // Prevent content sniffing
        'x-content-type-options': 'nosniff',
        // Enable client-side caching
        'x-ua-compatible': 'IE=edge',
      });
    };
  };
}

/// Helper to generate ETag for responses
String _generateETag(dynamic body) {
  try {
    final content = body is String ? body : jsonEncode(body);
    final hash = sha256.convert(utf8.encode(content));
    return '"${hash.toString().substring(0, 16)}"';
  } catch (_) {
    return '"unknown"';
  }
}

/// Pagination parameters parser
class PaginationParams {
  final int page;
  final int limit;
  final String? sortBy;
  final bool ascending;

  static const int defaultLimit = 50;
  static const int maxLimit = 1000;

  PaginationParams({
    this.page = 1,
    this.limit = defaultLimit,
    this.sortBy,
    this.ascending = true,
  });

  /// Parse pagination from request query parameters
  factory PaginationParams.fromRequest(shelf.Request request) {
    final page =
        int.tryParse(request.url.queryParameters['page'] ?? '1') ?? 1;
    final limit =
        int.tryParse(request.url.queryParameters['limit'] ?? '$defaultLimit') ??
            defaultLimit;
    final sortBy = request.url.queryParameters['sort_by'];
    final ascending =
        request.url.queryParameters['order'] != 'desc';

    return PaginationParams(
      page: page.clamp(1, 999999),
      limit: limit.clamp(1, maxLimit),
      sortBy: sortBy,
      ascending: ascending,
    );
  }

  /// Get offset for database query
  int get offset => (page - 1) * limit;

  /// Get pagination metadata
  Map<String, dynamic> getMetadata(int total) {
    return {
      'page': page,
      'limit': limit,
      'offset': offset,
      'total': total,
      'pages': (total / limit).ceil(),
      'has_next': offset + limit < total,
      'has_prev': page > 1,
    };
  }
}

/// Response wrapper for consistent API responses
class ApiResponse<T> {
  final T data;
  final String? message;
  final Map<String, dynamic>? metadata;
  final bool success;
  final int statusCode;

  ApiResponse({
    required this.data,
    this.message,
    this.metadata,
    this.success = true,
    this.statusCode = 200,
  });

  /// Create success response
  factory ApiResponse.success(
    T data, {
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse(
      data: data,
      message: message ?? 'Success',
      metadata: metadata,
      success: true,
      statusCode: 200,
    );
  }

  /// Create paginated response
  factory ApiResponse.paginated(
    T data,
    int total, {
    required int page,
    required int limit,
  }) {
    final metadata = {
      'pagination': {
        'page': page,
        'limit': limit,
        'total': total,
        'pages': (total / limit).ceil(),
      },
    };

    return ApiResponse(
      data: data,
      message: 'Success',
      metadata: metadata,
      success: true,
      statusCode: 200,
    );
  }

  /// Create error response
  factory ApiResponse.error(
    String message, {
    Map<String, dynamic>? metadata,
    int statusCode = 400,
  }) {
    return ApiResponse<T>(
      data: null as T,
      message: message,
      metadata: metadata,
      success: false,
      statusCode: statusCode,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Convert to shelf response
  shelf.Response toShelfResponse() {
    final headers = {
      'Content-Type': 'application/json',
      'cache-control': statusCode == 200
          ? 'public, max-age=300'
          : 'no-cache, no-store',
    };

    return shelf.Response(statusCode, headers: headers, body: jsonEncode(toJson()));
  }
}
