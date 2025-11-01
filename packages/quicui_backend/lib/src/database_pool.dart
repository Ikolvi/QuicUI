import 'dart:async';

/// Exception for database pool errors
class DatabasePoolException implements Exception {
  final String message;
  DatabasePoolException(this.message);

  @override
  String toString() => 'DatabasePoolException: $message';
}

/// Mock database connection for pooling demonstration
class DbConnection {
  final int connectionId;
  final DateTime createdAt;
  late DateTime lastUsedAt;
  bool _isOpen = true;

  DbConnection({required this.connectionId})
      : createdAt = DateTime.now() {
    lastUsedAt = createdAt;
  }

  bool get isOpen => _isOpen;

  Future<T> execute<T>(String query, [List<dynamic>? params]) async {
    if (!_isOpen) {
      throw DatabasePoolException('Connection $connectionId is closed');
    }

    lastUsedAt = DateTime.now();

    // Simulate query execution time (10-50ms)
    await Future.delayed(
      Duration(milliseconds: 10 + DateTime.now().millisecondsSinceEpoch % 40),
    );

    // Return mock data
    return {} as T;
  }

  Future<void> close() async {
    _isOpen = false;
  }

  int get idleTimeSeconds =>
      DateTime.now().difference(lastUsedAt).inSeconds;
}

/// Database connection pool for managing database connections efficiently
class DatabasePool {
  final int minConnections;
  final int maxConnections;
  final Duration idleTimeout;
  final Duration connectionTimeout;

  late Timer _maintenanceTimer;
  int _nextConnectionId = 1;
  final List<DbConnection> _availableConnections = [];
  final List<DbConnection> _usedConnections = [];
  bool _initialized = false;

  // Statistics
  int _totalConnectionsCreated = 0;
  int _totalQueriesExecuted = 0;
  int _totalConnectionsClosed = 0;

  DatabasePool({
    this.minConnections = 10,
    this.maxConnections = 50,
    this.idleTimeout = const Duration(minutes: 5),
    this.connectionTimeout = const Duration(seconds: 30),
  }) {
    if (minConnections > maxConnections) {
      throw DatabasePoolException(
        'minConnections ($minConnections) cannot exceed maxConnections ($maxConnections)',
      );
    }
  }

  /// Initialize the pool and create minimum connections
  Future<void> initialize() async {
    try {
      // Create minimum connections
      for (int i = 0; i < minConnections; i++) {
        final conn = DbConnection(connectionId: _nextConnectionId++);
        _availableConnections.add(conn);
        _totalConnectionsCreated++;
      }

      // Start maintenance timer
      _maintenanceTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _performMaintenance(),
      );

      _initialized = true;
      print(
        '✅ Database pool initialized: '
        '$minConnections-$maxConnections connections',
      );
    } catch (e) {
      throw DatabasePoolException('Failed to initialize pool: $e');
    }
  }

  /// Get a connection from the pool
  Future<DbConnection> getConnection() async {
    if (!_initialized) {
      throw DatabasePoolException('Pool not initialized');
    }

    // Try to get available connection
    if (_availableConnections.isNotEmpty) {
      final conn = _availableConnections.removeAt(0);
      _usedConnections.add(conn);
      return conn;
    }

    // Create new connection if we haven't reached max
    if (_usedConnections.length + _availableConnections.length < maxConnections) {
      final conn = DbConnection(connectionId: _nextConnectionId++);
      _usedConnections.add(conn);
      _totalConnectionsCreated++;
      return conn;
    }

    // Wait for a connection to be available
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < connectionTimeout) {
      await Future.delayed(const Duration(milliseconds: 100));

      if (_availableConnections.isNotEmpty) {
        final conn = _availableConnections.removeAt(0);
        _usedConnections.add(conn);
        return conn;
      }
    }

    throw DatabasePoolException('Failed to acquire connection within timeout');
  }

  /// Release a connection back to the pool
  Future<void> releaseConnection(DbConnection conn) async {
    if (!_initialized) return;

    _usedConnections.removeWhere((c) => c.connectionId == conn.connectionId);
    _availableConnections.add(conn);
  }

  /// Execute a query using a pooled connection
  Future<T> query<T>(String sql, [List<dynamic>? params]) async {
    final conn = await getConnection();
    try {
      _totalQueriesExecuted++;
      return await conn.execute<T>(sql, params);
    } finally {
      await releaseConnection(conn);
    }
  }

  /// Get pool statistics
  Map<String, dynamic> getStats() {
    final total =
        _usedConnections.length + _availableConnections.length;
    final utilization = total > 0
        ? (_usedConnections.length / total * 100).toStringAsFixed(2)
        : '0.00';

    return {
      'status': 'healthy',
      'total_connections': total,
      'available_connections': _availableConnections.length,
      'used_connections': _usedConnections.length,
      'pool_utilization_percent': utilization,
      'min_connections': minConnections,
      'max_connections': maxConnections,
      'total_created': _totalConnectionsCreated,
      'total_queries': _totalQueriesExecuted,
      'total_closed': _totalConnectionsClosed,
      'connection_timeout_seconds': connectionTimeout.inSeconds,
      'idle_timeout_minutes': idleTimeout.inMinutes,
    };
  }

  /// Close all connections and shutdown the pool
  Future<void> shutdown() async {
    if (!_initialized) return;

    try {
      _maintenanceTimer.cancel();

      // Close all connections
      for (final conn in _availableConnections) {
        await conn.close();
        _totalConnectionsClosed++;
      }

      for (final conn in _usedConnections) {
        await conn.close();
        _totalConnectionsClosed++;
      }

      _availableConnections.clear();
      _usedConnections.clear();
      _initialized = false;

      print('✅ Database pool shutdown complete');
    } catch (e) {
      print('⚠️ Error during pool shutdown: $e');
    }
  }

  /// Perform maintenance on the pool
  void _performMaintenance() {
    // Remove idle connections
    final toRemove = <DbConnection>[];
    for (final conn in _availableConnections) {
      if (conn.idleTimeSeconds > idleTimeout.inSeconds &&
          _availableConnections.length + _usedConnections.length > minConnections) {
        toRemove.add(conn);
      }
    }

    for (final conn in toRemove) {
      _availableConnections.remove(conn);
      conn.close().ignore();
      _totalConnectionsClosed++;
    }

    if (toRemove.isNotEmpty) {
      print(
        '🧹 Connection pool maintenance: removed ${toRemove.length} idle connections',
      );
    }
  }
}

/// Query optimizer for analyzing and improving query performance
class QueryOptimizer {
  final Duration defaultCacheTtl;
  final int defaultFetchSize;

  final Map<String, _QueryStats> _queryStats = {};

  QueryOptimizer({
    this.defaultCacheTtl = const Duration(minutes: 5),
    this.defaultFetchSize = 100,
  });

  /// Execute a query with optimization analysis
  Future<List<Map<String, dynamic>>> executQuery(
    DatabasePool pool,
    String query, {
    List<dynamic>? params,
    Duration? cacheTtl,
    int? fetchSize,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await pool.query<Map<String, dynamic>>(query, params);
      stopwatch.stop();

      // Record statistics
      _recordQueryStat(query, stopwatch.elapsedMilliseconds, true);

      return [result];
    } catch (e) {
      stopwatch.stop();
      _recordQueryStat(query, stopwatch.elapsedMilliseconds, false);
      rethrow;
    }
  }

  /// Get query performance statistics
  Map<String, dynamic> getQueryStats() {
    final entries = _queryStats.entries.toList();

    // Sort by slowest queries
    entries.sort((a, b) =>
        b.value.avgTimeMs.compareTo(a.value.avgTimeMs));

    final slowestQueries = entries
        .take(10)
        .map((e) => {
          'query': e.key,
          'avg_time_ms': e.value.avgTimeMs,
          'count': e.value.count,
          'success_rate': '${(e.value.successRate * 100).toStringAsFixed(2)}%',
        })
        .toList();

    return {
      'total_queries': _queryStats.length,
      'total_executions': _queryStats.values.fold<int>(
        0,
        (sum, stat) => sum + stat.count,
      ),
      'avg_query_time_ms': _queryStats.values.isEmpty
          ? 0
          : _queryStats.values.fold<double>(0, (sum, stat) => sum + stat.avgTimeMs) /
              _queryStats.length,
      'slowest_queries': slowestQueries,
    };
  }

  /// Record query statistics
  void _recordQueryStat(String query, int timeMs, bool success) {
    final key = _normalizeQuery(query);

    if (!_queryStats.containsKey(key)) {
      _queryStats[key] = _QueryStats();
    }

    final stat = _queryStats[key]!;
    stat.count++;
    stat.totalTimeMs += timeMs;
    if (success) {
      stat.successCount++;
    }
  }

  /// Normalize query for grouping (remove params)
  String _normalizeQuery(String query) {
    return query
        .replaceAll(RegExp(r"'[^']*'"), '?')
        .replaceAll(RegExp(r'"\w+"'), '?')
        .replaceAll(RegExp(r'\d+'), '?');
  }
}

/// Query statistics tracking
class _QueryStats {
  int count = 0;
  int totalTimeMs = 0;
  int successCount = 0;

  int get failureCount => count - successCount;

  double get avgTimeMs => count > 0 ? totalTimeMs / count : 0;

  double get successRate => count > 0 ? successCount / count : 0;
}
