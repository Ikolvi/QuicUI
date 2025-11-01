/// RateLimiter - Token Bucket Algorithm for Rate Limiting & DDoS Protection
///
/// Provides comprehensive rate limiting with:
/// - Per-IP rate limiting
/// - Token bucket algorithm (allows burst traffic)
/// - Per-endpoint rate limiting tiers
/// - Configurable limits and reset intervals
/// - DDoS protection with circuit breaker pattern
///
/// Security fixes:
/// - Prevents brute force attacks on auth endpoints
/// - Prevents DDoS attacks via request flooding
/// - Prevents resource exhaustion

import 'dart:async';

/// Token bucket for rate limiting
class TokenBucket {
  final int capacity;
  final Duration refillInterval;
  final int refillAmount;

  double _tokens;
  DateTime _lastRefill;

  TokenBucket({
    required this.capacity,
    required this.refillInterval,
    required this.refillAmount,
  })  : _tokens = capacity.toDouble(),
        _lastRefill = DateTime.now();

  /// Check if tokens are available and consume them
  bool tryConsume(int amount) {
    _refill();

    if (_tokens >= amount) {
      _tokens -= amount;
      return true;
    }
    return false;
  }

  /// Refill tokens based on elapsed time
  void _refill() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefill);
    final intervalsElapsed = elapsed.inMilliseconds / refillInterval.inMilliseconds;

    if (intervalsElapsed >= 1) {
      _tokens = (_tokens + (intervalsElapsed * refillAmount)).toDouble();
      if (_tokens > capacity) {
        _tokens = capacity.toDouble();
      }
      _lastRefill = now;
    }
  }

  /// Get current token count (after refilling)
  double getTokenCount() {
    _refill();
    return _tokens;
  }

  /// Reset bucket to full capacity
  void reset() {
    _tokens = capacity.toDouble();
    _lastRefill = DateTime.now();
  }
}

/// Rate limit tier configuration
class RateLimitTier {
  final String name;
  final int requestsPerMinute;
  final int capacity;
  final Duration refillInterval;

  RateLimitTier({
    required this.name,
    required this.requestsPerMinute,
    this.capacity = 10, // Allow 10 requests burst
    this.refillInterval = const Duration(minutes: 1),
  });

  /// Calculate refill amount per interval
  int get refillAmount => (requestsPerMinute / 60).ceil();

  @override
  String toString() =>
      'RateLimitTier(name: $name, limit: $requestsPerMinute/min)';
}

/// Rate limit status
class RateLimitStatus {
  final bool allowed;
  final int remainingRequests;
  final int resetAfterSeconds;
  final String retryAfter;

  RateLimitStatus({
    required this.allowed,
    required this.remainingRequests,
    required this.resetAfterSeconds,
    required this.retryAfter,
  });

  Map<String, String> toHeaders() => {
    'X-RateLimit-Remaining': remainingRequests.toString(),
    'X-RateLimit-Reset': DateTime.now()
        .add(Duration(seconds: resetAfterSeconds))
        .toIso8601String(),
    'Retry-After': retryAfter,
  };

  @override
  String toString() =>
      'RateLimitStatus(allowed: $allowed, remaining: $remainingRequests, resetIn: ${resetAfterSeconds}s)';
}

/// Main RateLimiter service
class RateLimiter {
  final Map<String, RateLimitTier> tiers;
  final Map<String, TokenBucket> buckets = {};
  final Duration cleanupInterval;
  final int maxIpsTracked;

  late Timer _cleanupTimer;

  RateLimiter({
    Map<String, RateLimitTier>? tiers,
    this.cleanupInterval = const Duration(hours: 1),
    this.maxIpsTracked = 10000,
  }) : tiers = tiers ??
      {
        'public': RateLimitTier(
          name: 'public',
          requestsPerMinute: 100,
        ),
        'auth': RateLimitTier(
          name: 'auth',
          requestsPerMinute: 10,
        ),
        'metrics': RateLimitTier(
          name: 'metrics',
          requestsPerMinute: 1000,
        ),
        'admin': RateLimitTier(
          name: 'admin',
          requestsPerMinute: 500,
        ),
      } {
    _startCleanupTimer();
  }

  /// Check if request is allowed and update rate limit status
  RateLimitStatus checkLimit(
    String clientId,
    String tier, {
    int tokensToConsume = 1,
  }) {
    // Get tier configuration
    final tierConfig = tiers[tier] ?? tiers['public']!;

    // Get or create bucket for this client
    final bucketKey = '$clientId:$tier';
    final bucket = buckets.putIfAbsent(
      bucketKey,
      () => TokenBucket(
        capacity: tierConfig.capacity,
        refillInterval: tierConfig.refillInterval,
        refillAmount: tierConfig.refillAmount,
      ),
    );

    // Enforce maximum IPs tracked (circuit breaker)
    if (buckets.length > maxIpsTracked) {
      _cleanupOldestBuckets();
    }

    // Check if request is allowed
    final allowed = bucket.tryConsume(tokensToConsume);
    final remaining = (bucket.getTokenCount()).toInt();
    final resetSeconds = tierConfig.refillInterval.inSeconds;

    return RateLimitStatus(
      allowed: allowed,
      remainingRequests: remaining,
      resetAfterSeconds: resetSeconds,
      retryAfter: resetSeconds.toString(),
    );
  }

  /// Get rate limit status without consuming tokens
  RateLimitStatus getStatus(String clientId, String tier) {
    final tierConfig = tiers[tier] ?? tiers['public']!;
    final bucketKey = '$clientId:$tier';
    final bucket = buckets[bucketKey];

    if (bucket == null) {
      return RateLimitStatus(
        allowed: true,
        remainingRequests: tierConfig.capacity,
        resetAfterSeconds: tierConfig.refillInterval.inSeconds,
        retryAfter: tierConfig.refillInterval.inSeconds.toString(),
      );
    }

    final remaining = (bucket.getTokenCount()).toInt();
    final resetSeconds = tierConfig.refillInterval.inSeconds;

    return RateLimitStatus(
      allowed: remaining > 0,
      remainingRequests: remaining,
      resetAfterSeconds: resetSeconds,
      retryAfter: resetSeconds.toString(),
    );
  }

  /// Reset rate limit for specific client
  void resetClientLimit(String clientId, String tier) {
    final bucketKey = '$clientId:$tier';
    buckets[bucketKey]?.reset();
  }

  /// Reset all rate limits
  void resetAll() {
    buckets.clear();
  }

  /// Get rate limiter statistics
  Map<String, dynamic> getStats() {
    return {
      'trackedClients': buckets.length,
      'maxTracked': maxIpsTracked,
      'tiers': tiers.entries.fold<Map<String, dynamic>>(
        {},
        (acc, entry) => {
          ...acc,
          entry.key: {
            'requestsPerMinute': entry.value.requestsPerMinute,
            'capacity': entry.value.capacity,
            'refillAmount': entry.value.refillAmount,
          },
        },
      ),
    };
  }

  /// Start periodic cleanup of old buckets
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(cleanupInterval, (_) {
      _cleanupOldBuckets();
    });
  }

  /// Remove old buckets that haven't been used recently
  void _cleanupOldBuckets() {
    // Note: In production, consider adding lastAccessTime tracking
    // For now, this is a simplified implementation
    if (buckets.length > maxIpsTracked) {
      _cleanupOldestBuckets();
    }
  }

  /// Remove oldest buckets when limit is exceeded
  void _cleanupOldestBuckets() {
    final entriesToRemove = (buckets.length * 0.1).toInt(); // Remove 10%
    if (entriesToRemove > 0) {
      final keys = buckets.keys.toList();
      for (int i = 0; i < entriesToRemove && i < keys.length; i++) {
        buckets.remove(keys[i]);
      }
    }
  }

  /// Dispose rate limiter and cleanup resources
  void dispose() {
    _cleanupTimer.cancel();
    buckets.clear();
  }

  @override
  String toString() => 'RateLimiter(tiers: ${tiers.length}, tracked: ${buckets.length})';
}

/// Rate limit middleware helper
class RateLimitMiddlewareHelper {
  final RateLimiter rateLimiter;

  RateLimitMiddlewareHelper({RateLimiter? rateLimiter})
      : rateLimiter = rateLimiter ?? RateLimiter();

  /// Extract client IP from request
  String extractClientIp(Map<String, String> headers, String remoteAddress) {
    // Check for X-Forwarded-For header (proxy)
    final xForwardedFor = headers['x-forwarded-for'];
    if (xForwardedFor != null && xForwardedFor.isNotEmpty) {
      return xForwardedFor.split(',').first.trim();
    }

    // Check for X-Real-IP header
    final xRealIp = headers['x-real-ip'];
    if (xRealIp != null && xRealIp.isNotEmpty) {
      return xRealIp;
    }

    // Use remote address as fallback
    return remoteAddress;
  }

  /// Determine tier based on path
  String determineTier(String path) {
    if (path.startsWith('/api/auth')) return 'auth';
    if (path.startsWith('/api/metrics')) return 'metrics';
    if (path.startsWith('/api/admin')) return 'admin';
    return 'public';
  }

  /// Check rate limit and get response headers
  (bool, Map<String, String>) checkAndGetHeaders(
    String clientId,
    String tier,
  ) {
    final status = rateLimiter.checkLimit(clientId, tier);
    return (status.allowed, status.toHeaders());
  }
}
