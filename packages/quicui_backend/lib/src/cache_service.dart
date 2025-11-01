import 'dart:async';

/// Exception thrown by cache service operations
class CacheServiceException implements Exception {
  final String message;
  CacheServiceException(this.message);
  
  @override
  String toString() => 'CacheServiceException: $message';
}

/// Simple in-memory cache implementation for development
/// Production should use Redis for distributed caching
class CacheService {
  final Duration defaultTtl;
  final String keyPrefix;
  final int maxEntries;
  
  final Map<String, _CacheEntry> _cache = {};
  late Timer _cleanupTimer;
  bool _initialized = false;
  int _hits = 0;
  int _misses = 0;
  
  CacheService({
    this.defaultTtl = const Duration(minutes: 5),
    this.keyPrefix = 'quicui:',
    this.maxEntries = 10000,
  });

  /// Initialize cache
  Future<void> initialize() async {
    try {
      // Start periodic cleanup of expired entries
      _cleanupTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _cleanupExpired(),
      );
      _initialized = true;
      print('✅ Cache initialized (in-memory, development mode)');
      print('   Max entries: $maxEntries');
      print('   Default TTL: ${defaultTtl.inMinutes}m');
    } catch (e) {
      throw CacheServiceException('Failed to initialize cache: $e');
    }
  }

  /// Get a value from cache
  Future<T?> get<T>(String key) async {
    if (!_initialized) return null;
    
    try {
      final fullKey = _makeKey(key);
      final entry = _cache[fullKey];
      
      if (entry == null) {
        _misses++;
        return null;
      }
      
      if (!entry.isValid) {
        _cache.remove(fullKey);
        _misses++;
        return null;
      }
      
      _hits++;
      entry.lastAccessTime = DateTime.now();
      return entry.value as T?;
    } catch (e) {
      print('⚠️ Cache get error for key "$key": $e');
      _misses++;
      return null;
    }
  }

  /// Set a value in cache with optional TTL
  Future<void> set<T>(
    String key,
    T value, {
    Duration? ttl,
  }) async {
    if (!_initialized) return;
    
    try {
      // Check if we need to evict entries
      if (_cache.length >= maxEntries) {
        _evictLRU();
      }
      
      final fullKey = _makeKey(key);
      final ttlSeconds = (ttl ?? defaultTtl).inSeconds;
      
      _cache[fullKey] = _CacheEntry(
        value: value,
        expiresAt: DateTime.now().add(Duration(seconds: ttlSeconds)),
      );
    } catch (e) {
      print('⚠️ Cache set error for key "$key": $e');
    }
  }

  /// Delete a value from cache
  Future<void> delete(String key) async {
    if (!_initialized) return;
    
    try {
      final fullKey = _makeKey(key);
      _cache.remove(fullKey);
    } catch (e) {
      print('⚠️ Cache delete error for key "$key": $e');
    }
  }

  /// Clear all cache entries with our prefix
  Future<void> clear() async {
    if (!_initialized) return;
    
    try {
      final entriesToRemove = <String>[];
      for (final key in _cache.keys) {
        if (key.startsWith(keyPrefix)) {
          entriesToRemove.add(key);
        }
      }
      
      for (final key in entriesToRemove) {
        _cache.remove(key);
      }
      
      _hits = 0;
      _misses = 0;
    } catch (e) {
      print('⚠️ Cache clear error: $e');
    }
  }

  /// Check if cache is healthy
  Future<bool> isHealthy() async {
    return _initialized;
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    if (!_initialized) {
      return {'status': 'not_initialized'};
    }
    
    try {
      _cleanupExpired(); // Clean before reporting
      
      final total = _hits + _misses;
      final hitRate = total > 0 ? (_hits / total * 100).toStringAsFixed(2) : 'N/A';
      
      return {
        'status': 'healthy',
        'type': 'local-memory',
        'entries': _cache.length,
        'max_entries': maxEntries,
        'hits': _hits,
        'misses': _misses,
        'hit_rate': '$hitRate%',
        'default_ttl_minutes': defaultTtl.inMinutes,
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  /// Invalidate cache by pattern
  Future<int> invalidatePattern(String pattern) async {
    if (!_initialized) return 0;
    
    try {
      final fullPattern = _makeKey(pattern);
      int count = 0;
      
      final entriesToRemove = <String>[];
      for (final key in _cache.keys) {
        if (key.startsWith(fullPattern)) {
          entriesToRemove.add(key);
          count++;
        }
      }
      
      for (final key in entriesToRemove) {
        _cache.remove(key);
      }
      
      return count;
    } catch (e) {
      print('⚠️ Cache invalidate pattern error: $e');
      return 0;
    }
  }

  /// Get or set a value - useful for caching expensive operations
  Future<T> getOrSet<T>(
    String key,
    Future<T> Function() computeValue, {
    Duration? ttl,
  }) async {
    // Try to get from cache first
    final cached = await get<T>(key);
    if (cached != null) {
      return cached;
    }
    
    // Compute value
    final value = await computeValue();
    
    // Store in cache
    await set(key, value, ttl: ttl);
    
    return value;
  }

  /// Warm cache with initial values
  Future<void> warmCache(
    Map<String, dynamic> initialValues, {
    Duration? ttl,
  }) async {
    if (!_initialized) return;
    
    try {
      for (final entry in initialValues.entries) {
        await set(entry.key, entry.value, ttl: ttl);
      }
      print('✅ Cache warmed with ${initialValues.length} entries');
    } catch (e) {
      print('⚠️ Cache warm error: $e');
    }
  }

  /// Close cache and cleanup
  Future<void> close() async {
    if (_initialized) {
      try {
        _cleanupTimer.cancel();
        _cache.clear();
        _initialized = false;
        print('✅ Cache closed');
      } catch (e) {
        print('⚠️ Error closing cache: $e');
      }
    }
  }

  /// Create namespaced key
  String _makeKey(String key) => '$keyPrefix$key';

  /// Clean up expired entries
  void _cleanupExpired() {
    final entriesToRemove = <String>[];
    
    for (final entry in _cache.entries) {
      if (!entry.value.isValid) {
        entriesToRemove.add(entry.key);
      }
    }
    
    for (final key in entriesToRemove) {
      _cache.remove(key);
    }
  }

  /// Evict least recently used entry
  void _evictLRU() {
    if (_cache.isEmpty) return;
    
    String? oldestKey;
    DateTime? oldestTime;
    
    for (final entry in _cache.entries) {
      final lastAccess = entry.value.lastAccessTime;
      if (oldestTime == null || lastAccess.isBefore(oldestTime)) {
        oldestKey = entry.key;
        oldestTime = lastAccess;
      }
    }
    
    if (oldestKey != null) {
      _cache.remove(oldestKey);
      print('🗑️ Cache evicted LRU entry: $oldestKey');
    }
  }
}

/// Cache entry with expiration and access tracking
class _CacheEntry {
  final dynamic value;
  final DateTime createdAt;
  final DateTime expiresAt;
  late DateTime lastAccessTime;

  _CacheEntry({
    required this.value,
    required this.expiresAt,
  })  : createdAt = DateTime.now() {
    lastAccessTime = createdAt;
  }

  /// Check if entry is still valid
  bool get isValid => DateTime.now().isBefore(expiresAt);

  /// Get remaining TTL in seconds
  int get remainingTtl =>
      expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 999999);
}
