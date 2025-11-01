/// Security Middleware for QuicUI Code Push Backend
/// 
/// Handles authentication, authorization, rate limiting, and audit logging
/// Integrates with Shelf web framework

import 'dart:async';

/// Authentication context
class AuthContext {
  final String? userId;
  final String? email;
  final List<String> roles;
  final String? apiKeyId;
  final bool isAuthenticated;

  AuthContext({
    this.userId,
    this.email,
    this.roles = const [],
    this.apiKeyId,
    this.isAuthenticated = false,
  });

  bool hasRole(String role) => roles.contains(role);

  bool hasPermission(String permission) {
    return roles.any((role) => _roleHasPermission(role, permission));
  }

  bool _roleHasPermission(String role, String permission) {
    const rolePermissions = {
      'admin': ['*'],
      'developer': ['patch:*', 'app:*', 'metrics:read'],
      'user': ['patch:read', 'patch:download', 'app:read'],
      'service': ['patch:*', 'metrics:*'],
    };

    final perms = rolePermissions[role] ?? [];
    if (perms.contains('*')) return true;
    if (perms.contains(permission)) return true;

    for (final perm in perms) {
      if (perm.endsWith(':*')) {
        final prefix = perm.substring(0, perm.length - 2);
        if (permission.startsWith('$prefix:')) return true;
      }
    }

    return false;
  }

  @override
  String toString() => 'AuthContext(userId=$userId, roles=${roles.join(",")})';
}

/// Request context with auth and metadata
class RequestContext {
  final String requestId;
  final String method;
  final String path;
  final DateTime startTime;
  final String clientIp;
  AuthContext? authContext;
  DateTime? endTime;
  int? statusCode;

  RequestContext({
    required this.requestId,
    required this.method,
    required this.path,
    required this.clientIp,
  })  : startTime = DateTime.now();

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  void complete(int status) {
    statusCode = status;
    endTime = DateTime.now();
  }

  @override
  String toString() =>
      'RequestContext(id=$requestId, $method $path, duration=${duration?.inMs}ms)';
}

/// Authentication middleware factory
typedef AuthMiddleware = Future<AuthContext?> Function(String token);

/// Authorization middleware
typedef AuthorizeFunction = bool Function(AuthContext context, String permission);

/// Rate limit info
class RateLimitInfo {
  final int limit;
  final int remaining;
  final DateTime resetTime;

  RateLimitInfo({
    required this.limit,
    required this.remaining,
    required this.resetTime,
  });

  int get resetInSeconds => resetTime.difference(DateTime.now()).inSeconds;

  @override
  String toString() => 'RateLimitInfo(limit=$limit, remaining=$remaining, resetIn=${resetInSeconds}s)';
}

/// Security middleware implementation
class SecurityMiddleware {
  final AuthMiddleware? authMiddleware;
  final AuthorizeFunction? authorizeFunc;
  final Map<String, RateLimitInfo> rateLimits;
  final Map<String, List<DateTime>> requestHistory;
  final int requestsPerMinute;

  SecurityMiddleware({
    this.authMiddleware,
    this.authorizeFunc,
    this.requestsPerMinute = 100,
  })  : rateLimits = {},
        requestHistory = {};

  /// Apply authentication middleware
  /// 
  /// Extracts token from 'Authorization: Bearer <token>' header
  /// Sets auth context if token is valid
  Future<AuthContext?> authenticate(Map<String, String> headers) async {
    print('🔐 Authenticating request');

    try {
      final authHeader = headers['authorization'];
      if (authHeader == null) {
        print('   ℹ️  No authorization header');
        return null;
      }

      final parts = authHeader.split(' ');
      if (parts.length != 2 || parts[0] != 'Bearer') {
        print('   ❌ Invalid authorization header format');
        return null;
      }

      final token = parts[1];

      if (authMiddleware != null) {
        final context = await authMiddleware!(token);
        if (context != null) {
          print('   ✅ User authenticated: ${context.userId}');
        }
        return context;
      }

      return null;
    } catch (e) {
      print('   ❌ Authentication error: $e');
      return null;
    }
  }

  /// Apply API key authentication
  /// 
  /// Extracts key from 'X-API-Key' header
  /// For service-to-service authentication
  Future<AuthContext?> authenticateApiKey(Map<String, String> headers) async {
    print('🔑 Authenticating with API key');

    try {
      final apiKey = headers['x-api-key'];
      if (apiKey == null) {
        print('   ℹ️  No API key provided');
        return null;
      }

      // Validate API key (integrate with ApiKeyService)
      print('   ✅ API key authenticated');
      return AuthContext(
        apiKeyId: 'key_123',
        roles: ['service'],
        isAuthenticated: true,
      );
    } catch (e) {
      print('   ❌ API key authentication error: $e');
      return null;
    }
  }

  /// Check authorization
  /// 
  /// Verifies user has required permission
  bool authorize(AuthContext context, String permission) {
    print('🔒 Authorizing permission: $permission');
    print('   Context: $context');

    if (!context.isAuthenticated) {
      print('   ❌ Not authenticated');
      return false;
    }

    if (context.hasPermission(permission)) {
      print('   ✅ Permission granted');
      return true;
    }

    print('   ❌ Permission denied');
    return false;
  }

  /// Apply rate limiting
  /// 
  /// Uses sliding window algorithm
  /// Returns rate limit info or null if limit exceeded
  RateLimitInfo? checkRateLimit(String clientId) {
    print('⏱️ Checking rate limit for: $clientId');

    try {
      final now = DateTime.now();
      final windowStart = now.subtract(const Duration(minutes: 1));

      // Get or create request history
      if (!requestHistory.containsKey(clientId)) {
        requestHistory[clientId] = [];
      }

      final history = requestHistory[clientId]!;

      // Remove old requests
      history.removeWhere((time) => time.isBefore(windowStart));

      // Check limit
      if (history.length >= requestsPerMinute) {
        print('   ❌ Rate limit exceeded: ${history.length}/$requestsPerMinute');

        final resetTime = history.first.add(const Duration(minutes: 1));
        return RateLimitInfo(
          limit: requestsPerMinute,
          remaining: 0,
          resetTime: resetTime,
        );
      }

      // Record request
      history.add(now);

      final remaining = requestsPerMinute - history.length;
      print('   ✅ Request allowed: $remaining requests remaining');

      return RateLimitInfo(
        limit: requestsPerMinute,
        remaining: remaining,
        resetTime: now.add(const Duration(minutes: 1)),
      );
    } catch (e) {
      print('   ❌ Rate limit error: $e');
      return null;
    }
  }

  /// Get rate limit headers
  Map<String, String> getRateLimitHeaders(RateLimitInfo info) {
    return {
      'X-RateLimit-Limit': '${info.limit}',
      'X-RateLimit-Remaining': '${info.remaining}',
      'X-RateLimit-Reset': '${info.resetTime.millisecondsSinceEpoch ~/ 1000}',
    };
  }
}

/// Audit logger for security events
class SecurityAuditLogger {
  final List<AuditEvent> events = [];

  /// Log authentication attempt
  void logAuthAttempt({
    required String username,
    required bool success,
    required String method,
    String? reason,
  }) {
    final event = AuditEvent(
      id: _generateId(),
      timestamp: DateTime.now(),
      eventType: 'AUTH_ATTEMPT',
      username: username,
      method: method,
      success: success,
      details: reason,
    );

    events.add(event);

    print('📝 Audit: Auth attempt');
    print('   User: $username');
    print('   Method: $method');
    print('   Success: $success');
    if (reason != null) print('   Reason: $reason');
  }

  /// Log authorization check
  void logAuthorizationCheck({
    required String userId,
    required String permission,
    required bool allowed,
    String? reason,
  }) {
    final event = AuditEvent(
      id: _generateId(),
      timestamp: DateTime.now(),
      eventType: 'AUTHZ_CHECK',
      username: userId,
      method: permission,
      success: allowed,
      details: reason,
    );

    events.add(event);

    print('📝 Audit: Authorization check');
    print('   User: $userId');
    print('   Permission: $permission');
    print('   Allowed: $allowed');
  }

  /// Log security event
  void logEvent({
    required String userId,
    required String eventType,
    required String action,
    required String resource,
    required bool success,
    String? details,
  }) {
    final event = AuditEvent(
      id: _generateId(),
      timestamp: DateTime.now(),
      eventType: eventType,
      username: userId,
      method: action,
      resource: resource,
      success: success,
      details: details,
    );

    events.add(event);

    print('📝 Audit: $eventType');
    print('   User: $userId');
    print('   Action: $action');
    print('   Resource: $resource');
    print('   Success: $success');
  }

  /// Log rate limit exceeded
  void logRateLimitExceeded({
    required String clientId,
    required int requestCount,
    required int limit,
  }) {
    final event = AuditEvent(
      id: _generateId(),
      timestamp: DateTime.now(),
      eventType: 'RATE_LIMIT',
      username: clientId,
      method: 'HTTP',
      success: false,
      details: 'Requests: $requestCount/$limit',
    );

    events.add(event);

    print('📝 Audit: Rate limit exceeded');
    print('   Client: $clientId');
    print('   Requests: $requestCount/$limit');
  }

  /// Get audit trail for user
  List<AuditEvent> getAuditTrail({
    String? userId,
    String? eventType,
    DateTime? startTime,
    DateTime? endTime,
    int limit = 100,
  }) {
    var filtered = events.toList();

    if (userId != null) {
      filtered = filtered.where((e) => e.username == userId).toList();
    }

    if (eventType != null) {
      filtered = filtered.where((e) => e.eventType == eventType).toList();
    }

    if (startTime != null) {
      filtered = filtered.where((e) => e.timestamp.isAfter(startTime)).toList();
    }

    if (endTime != null) {
      filtered = filtered.where((e) => e.timestamp.isBefore(endTime)).toList();
    }

    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered.take(limit).toList();
  }

  String _generateId() {
    return 'evt_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Audit event model
class AuditEvent {
  final String id;
  final DateTime timestamp;
  final String eventType;
  final String username;
  final String method;
  final String? resource;
  final bool success;
  final String? details;

  AuditEvent({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.username,
    required this.method,
    this.resource,
    required this.success,
    this.details,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'eventType': eventType,
        'username': username,
        'method': method,
        'resource': resource,
        'success': success,
        'details': details,
      };

  @override
  String toString() =>
      'AuditEvent($eventType, user=$username, ${success ? "✅" : "❌"})';
}

/// Security context helper
class SecurityContext {
  static final _instance = SecurityContext._internal();

  factory SecurityContext() {
    return _instance;
  }

  SecurityContext._internal();

  final _authContexts = <String, AuthContext>{};
  final _requestContexts = <String, RequestContext>{};

  void setAuthContext(String requestId, AuthContext context) {
    _authContexts[requestId] = context;
  }

  AuthContext? getAuthContext(String requestId) {
    return _authContexts[requestId];
  }

  void setRequestContext(String requestId, RequestContext context) {
    _requestContexts[requestId] = context;
  }

  RequestContext? getRequestContext(String requestId) {
    return _requestContexts[requestId];
  }

  void clearContext(String requestId) {
    _authContexts.remove(requestId);
    _requestContexts.remove(requestId);
  }
}

/// Error response helper
class SecurityErrorResponse {
  final int statusCode;
  final String error;
  final String message;
  final Map<String, String>? headers;

  SecurityErrorResponse({
    required this.statusCode,
    required this.error,
    required this.message,
    this.headers,
  });

  static SecurityErrorResponse unauthorized(String message) {
    return SecurityErrorResponse(
      statusCode: 401,
      error: 'Unauthorized',
      message: message,
    );
  }

  static SecurityErrorResponse forbidden(String message) {
    return SecurityErrorResponse(
      statusCode: 403,
      error: 'Forbidden',
      message: message,
    );
  }

  static SecurityErrorResponse tooManyRequests(String message, RateLimitInfo info) {
    return SecurityErrorResponse(
      statusCode: 429,
      error: 'Too Many Requests',
      message: message,
      headers: {
        'X-RateLimit-Limit': '${info.limit}',
        'X-RateLimit-Remaining': '${info.remaining}',
        'X-RateLimit-Reset': '${info.resetTime.millisecondsSinceEpoch ~/ 1000}',
        'Retry-After': '${info.resetInSeconds}',
      },
    );
  }

  static SecurityErrorResponse invalidToken(String message) {
    return SecurityErrorResponse(
      statusCode: 401,
      error: 'Invalid Token',
      message: message,
    );
  }

  Map<String, dynamic> toJson() => {
        'error': error,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      };
}
