/// Authentication & Security Service for QuicUI Code Push Backend
/// 
/// Handles JWT tokens, password hashing, user authentication, and access control

import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// JWT Token management service
class JwtService {
  final String secret;
  final Duration tokenExpiry;

  JwtService({
    required this.secret,
    this.tokenExpiry = const Duration(hours: 24),
  });

  /// Generate JWT token for user
  /// 
  /// Format: header.payload.signature (Base64.header.Base64.payload.signature)
  /// 
  /// Payload includes:
  /// - userId: User identifier
  /// - email: User email
  /// - roles: User roles (user, admin, service)
  /// - iat: Issued at timestamp
  /// - exp: Expiration timestamp
  String generateToken({
    required String userId,
    required String email,
    required List<String> roles,
  }) {
    print('🔐 Generating JWT token for user: $email');

    try {
      final now = DateTime.now();
      final expiry = now.add(tokenExpiry);

      // Create header
      final header = {
        'alg': 'HS256',
        'typ': 'JWT',
      };

      // Create payload
      final payload = {
        'userId': userId,
        'email': email,
        'roles': roles,
        'iat': now.millisecondsSinceEpoch ~/ 1000,
        'exp': expiry.millisecondsSinceEpoch ~/ 1000,
      };

      // Encode header and payload
      final encodedHeader = base64Url.encode(utf8.encode(jsonEncode(header))).replaceAll('=', '');
      final encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');

      // Create signature
      final message = '$encodedHeader.$encodedPayload';
      final signature = _createSignature(message);

      final token = '$message.$signature';

      print('✅ Token generated successfully');
      print('   Expires: ${expiry.toIso8601String()}');
      print('   Roles: ${roles.join(", ")}');

      return token;
    } catch (e) {
      print('❌ Error generating token: $e');
      throw Exception('Token generation failed: $e');
    }
  }

  /// Verify and decode JWT token
  /// 
  /// Returns: Token payload if valid, null if invalid or expired
  Future<Map<String, dynamic>?> verifyToken(String token) async {
    print('🔍 Verifying JWT token');

    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print('❌ Invalid token format');
        return null;
      }

      final headerPart = parts[0];
      final payloadPart = parts[1];
      final signaturePart = parts[2];

      // Verify signature
      final message = '$headerPart.$payloadPart';
      final expectedSignature = _createSignature(message);

      if (signaturePart != expectedSignature) {
        print('❌ Invalid token signature');
        return null;
      }

      // Decode payload
      final paddedPayload = payloadPart.padRight((payloadPart.length + 3) ~/ 4 * 4, '=');
      final decodedPayload = utf8.decode(base64Url.decode(paddedPayload));
      final payload = jsonDecode(decodedPayload) as Map<String, dynamic>;

      // Check expiration
      final expTimestamp = payload['exp'] as int?;
      if (expTimestamp == null) {
        print('❌ No expiration in token');
        return null;
      }

      final expiresAt = DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);
      if (DateTime.now().isAfter(expiresAt)) {
        print('❌ Token has expired');
        return null;
      }

      print('✅ Token verified successfully');
      print('   User ID: ${payload['userId']}');
      print('   Email: ${payload['email']}');
      print('   Roles: ${payload['roles']}');

      return payload;
    } catch (e) {
      print('❌ Token verification failed: $e');
      return null;
    }
  }

  /// Extract user ID from token without verification (use with caution)
  String? extractUserIdUnsafe(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final paddedPayload = parts[1].padRight((parts[1].length + 3) ~/ 4 * 4, '=');
      final decodedPayload = utf8.decode(base64Url.decode(paddedPayload));
      final payload = jsonDecode(decodedPayload) as Map<String, dynamic>;

      return payload['userId'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Create HMAC SHA256 signature
  String _createSignature(String message) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    final digest = hmac.convert(utf8.encode(message));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}

/// Password hashing and verification service
class PasswordService {
  static const int _saltLength = 16;
  static const int _iterations = 100000;

  /// Hash password with salt
  /// 
  /// Format: salt$iterations$hash
  static String hashPassword(String password) {
    print('🔐 Hashing password');

    try {
      // Generate salt (simulate - in production use package:pointycastle)
      final salt = _generateSalt();

      // Hash password (PBKDF2 simulation with simple iteration)
      final hash = _pbkdf2Simulate(password, salt, _iterations);

      final hashed = '$salt\$_iterations\$$hash';

      print('✅ Password hashed successfully');
      return hashed;
    } catch (e) {
      print('❌ Error hashing password: $e');
      throw Exception('Password hashing failed: $e');
    }
  }

  /// Verify password against hash
  static bool verifyPassword(String password, String hash) {
    print('🔐 Verifying password');

    try {
      final parts = hash.split('\$');
      if (parts.length != 3) {
        print('❌ Invalid hash format');
        return false;
      }

      final salt = parts[0];
      final iterations = int.parse(parts[1]);
      final storedHash = parts[2];

      // Re-hash with same salt and iterations
      final computedHash = _pbkdf2Simulate(password, salt, iterations);

      // Constant-time comparison
      final matches = _constantTimeEquals(computedHash, storedHash);

      if (matches) {
        print('✅ Password verified successfully');
      } else {
        print('❌ Password verification failed');
      }

      return matches;
    } catch (e) {
      print('❌ Error verifying password: $e');
      return false;
    }
  }

  /// Generate random salt
  static String _generateSalt() {
    // Simulate salt generation (in production use SecureRandom)
    final random = List<int>.generate(_saltLength, (i) => (i * 17) % 256);
    return base64Url.encode(random).replaceAll('=', '');
  }

  /// PBKDF2 simulation (for development)
  /// In production, use package:pointycastle for actual PBKDF2
  static String _pbkdf2Simulate(String password, String salt, int iterations) {
    var result = password + salt;
    for (int i = 0; i < iterations; i++) {
      result = sha256.convert(utf8.encode(result)).toString();
    }
    return result;
  }

  /// Constant-time string comparison
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return result == 0;
  }
}

/// API Key management service
class ApiKeyService {
  final Map<String, ApiKey> _apiKeys = {};
  final String secret;

  ApiKeyService({required this.secret});

  /// Generate new API key
  String generateApiKey({
    required String name,
    required String userId,
    required List<String> scopes,
    required bool isActive,
  }) {
    print('🔑 Generating API key: $name');

    try {
      final key = _generateSecureKey();
      final hashedKey = sha256.convert(utf8.encode(key)).toString();

      final apiKey = ApiKey(
        id: _generateKeyId(),
        name: name,
        userId: userId,
        hashedKey: hashedKey,
        scopes: scopes,
        isActive: isActive,
        createdAt: DateTime.now(),
        lastUsedAt: null,
      );

      _apiKeys[hashedKey] = apiKey;

      print('✅ API key generated successfully');
      print('   Key ID: ${apiKey.id}');
      print('   Scopes: ${scopes.join(", ")}');

      return key;
    } catch (e) {
      print('❌ Error generating API key: $e');
      throw Exception('API key generation failed: $e');
    }
  }

  /// Verify API key
  Future<ApiKey?> verifyApiKey(String key) async {
    print('🔑 Verifying API key');

    try {
      final hashedKey = sha256.convert(utf8.encode(key)).toString();

      final apiKey = _apiKeys[hashedKey];
      if (apiKey == null) {
        print('❌ API key not found');
        return null;
      }

      if (!apiKey.isActive) {
        print('❌ API key is inactive');
        return null;
      }

      // Update last used time
      apiKey.lastUsedAt = DateTime.now();

      print('✅ API key verified successfully');
      print('   User ID: ${apiKey.userId}');
      print('   Scopes: ${apiKey.scopes.join(", ")}');

      return apiKey;
    } catch (e) {
      print('❌ Error verifying API key: $e');
      return null;
    }
  }

  /// Revoke API key
  Future<bool> revokeApiKey(String keyId, String userId) async {
    print('🚫 Revoking API key: $keyId');

    try {
      final apiKey = _apiKeys.values.firstWhere(
        (k) => k.id == keyId && k.userId == userId,
        orElse: () => throw Exception('API key not found'),
      );

      apiKey.isActive = false;
      apiKey.revokedAt = DateTime.now();

      print('✅ API key revoked successfully');
      return true;
    } catch (e) {
      print('❌ Error revoking API key: $e');
      return false;
    }
  }

  /// List API keys for user
  Future<List<ApiKey>> listApiKeys(String userId) async {
    print('📋 Listing API keys for user: $userId');

    try {
      final keys = _apiKeys.values
          .where((k) => k.userId == userId)
          .toList();

      print('✅ Found ${keys.length} API keys');
      return keys;
    } catch (e) {
      print('❌ Error listing API keys: $e');
      return [];
    }
  }

  String _generateSecureKey() {
    final random = List<int>.generate(32, (i) => (i * 19) % 256);
    return base64Url.encode(random).replaceAll('=', '');
  }

  String _generateKeyId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = List<int>.generate(8, (i) => (i * 23) % 256);
    return '${timestamp}_${base64Url.encode(random).replaceAll('=', '')}';
  }
}

/// Role-based access control service
class RbacService {
  /// Define role permissions
  static const Map<String, List<String>> rolePermissions = {
    'user': [
      'patch:read',
      'patch:download',
      'app:read',
    ],
    'developer': [
      'patch:read',
      'patch:download',
      'patch:create',
      'patch:delete',
      'app:read',
      'app:create',
      'app:delete',
      'metrics:read',
    ],
    'admin': [
      '*', // All permissions
    ],
    'service': [
      'patch:read',
      'patch:download',
      'patch:create',
      'metrics:read',
      'metrics:write',
    ],
  };

  /// Check if role has permission
  static bool hasPermission(String role, String permission) {
    final permissions = rolePermissions[role] ?? [];

    // Admin has all permissions
    if (permissions.contains('*')) {
      return true;
    }

    // Exact permission match
    if (permissions.contains(permission)) {
      return true;
    }

    // Wildcard permission match (e.g., 'patch:*' matches 'patch:read')
    for (final perm in permissions) {
      if (perm.endsWith(':*')) {
        final prefix = perm.substring(0, perm.length - 2);
        if (permission.startsWith('$prefix:')) {
          return true;
        }
      }
    }

    return false;
  }

  /// Check if user has permission
  static bool userHasPermission(List<String> roles, String permission) {
    return roles.any((role) => hasPermission(role, permission));
  }

  /// Get all permissions for role
  static List<String> getPermissions(String role) {
    return rolePermissions[role] ?? [];
  }

  /// Get all permissions for user
  static List<String> getUserPermissions(List<String> roles) {
    final permissions = <String>{};
    for (final role in roles) {
      permissions.addAll(getPermissions(role));
    }
    return permissions.toList();
  }
}

/// Rate limiting service
class RateLimitService {
  final Duration windowDuration;
  final int maxRequests;
  final Map<String, List<DateTime>> _requestHistory = {};

  RateLimitService({
    this.windowDuration = const Duration(minutes: 1),
    this.maxRequests = 100,
  });

  /// Check if request is allowed
  bool isRequestAllowed(String clientId) {
    print('⏱️ Checking rate limit for: $clientId');

    try {
      final now = DateTime.now();
      final windowStart = now.subtract(windowDuration);

      // Get or create request history for client
      if (!_requestHistory.containsKey(clientId)) {
        _requestHistory[clientId] = [];
      }

      final history = _requestHistory[clientId]!;

      // Remove requests outside the window
      history.removeWhere((time) => time.isBefore(windowStart));

      // Check if within limit
      if (history.length < maxRequests) {
        history.add(now);
        print('✅ Request allowed');
        print('   Requests in window: ${history.length}/$maxRequests');
        return true;
      } else {
        print('❌ Rate limit exceeded');
        print('   Requests in window: ${history.length}/$maxRequests');
        return false;
      }
    } catch (e) {
      print('❌ Error checking rate limit: $e');
      return false;
    }
  }

  /// Get remaining requests
  int getRemainingRequests(String clientId) {
    final now = DateTime.now();
    final windowStart = now.subtract(windowDuration);

    final history = _requestHistory[clientId] ?? [];
    final validRequests = history.where((time) => time.isAfter(windowStart)).length;

    return maxRequests - validRequests;
  }

  /// Get reset time (when next request will be allowed)
  DateTime? getResetTime(String clientId) {
    final history = _requestHistory[clientId];
    if (history == null || history.isEmpty) {
      return null;
    }

    final oldest = history.first;
    return oldest.add(windowDuration);
  }
}

/// Audit logging service
class AuditLogService {
  final List<AuditLog> _logs = [];

  /// Log security event
  void logSecurityEvent({
    required String userId,
    required String eventType,
    required String action,
    required String resource,
    required String status, // success, failure, unknown
    String? details,
  }) {
    final log = AuditLog(
      id: _generateLogId(),
      userId: userId,
      eventType: eventType,
      action: action,
      resource: resource,
      status: status,
      details: details,
      timestamp: DateTime.now(),
    );

    _logs.add(log);

    print('📝 Audit log recorded');
    print('   Event: $eventType');
    print('   Action: $action');
    print('   User: $userId');
    print('   Status: $status');
  }

  /// Get audit logs
  List<AuditLog> getAuditLogs({
    String? userId,
    String? eventType,
    DateTime? startTime,
    DateTime? endTime,
    int limit = 100,
  }) {
    var filtered = _logs.toList();

    if (userId != null) {
      filtered = filtered.where((log) => log.userId == userId).toList();
    }

    if (eventType != null) {
      filtered = filtered.where((log) => log.eventType == eventType).toList();
    }

    if (startTime != null) {
      filtered = filtered.where((log) => log.timestamp.isAfter(startTime)).toList();
    }

    if (endTime != null) {
      filtered = filtered.where((log) => log.timestamp.isBefore(endTime)).toList();
    }

    // Sort by timestamp descending and limit
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered.take(limit).toList();
  }

  String _generateLogId() {
    return 'log_${DateTime.now().millisecondsSinceEpoch}';
  }
}

// ==================== Data Models ====================

/// API Key model
class ApiKey {
  final String id;
  final String name;
  final String userId;
  final String hashedKey;
  final List<String> scopes;
  bool isActive;
  final DateTime createdAt;
  DateTime? lastUsedAt;
  DateTime? revokedAt;

  ApiKey({
    required this.id,
    required this.name,
    required this.userId,
    required this.hashedKey,
    required this.scopes,
    required this.isActive,
    required this.createdAt,
    this.lastUsedAt,
    this.revokedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'userId': userId,
        'scopes': scopes,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'lastUsedAt': lastUsedAt?.toIso8601String(),
        'revokedAt': revokedAt?.toIso8601String(),
      };
}

/// Audit log model
class AuditLog {
  final String id;
  final String userId;
  final String eventType;
  final String action;
  final String resource;
  final String status;
  final String? details;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.action,
    required this.resource,
    required this.status,
    this.details,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'eventType': eventType,
        'action': action,
        'resource': resource,
        'status': status,
        'details': details,
        'timestamp': timestamp.toIso8601String(),
      };
}
