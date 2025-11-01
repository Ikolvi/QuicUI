/// Prometheus-style metrics counter
class Counter {
  int value = 0;

  void increment([int amount = 1]) => value += amount;

  Map<String, dynamic> toJson() => {'value': value};
}

/// Prometheus-style metrics gauge
class Gauge {
  double value = 0;

  void set(double val) => value = val;

  void increment([double amount = 1]) => value += amount;

  void decrement([double amount = 1]) => value -= amount;

  Map<String, dynamic> toJson() => {'value': value};
}

/// Prometheus-style metrics histogram
class Histogram {
  final List<double> buckets;
  final Map<double, int> bucketCounts = {};
  late int totalCount;
  late double sum;
  late double min;
  late double max;

  Histogram({
    this.buckets = const [
      0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1.0, 2.5, 5.0, 7.5, 10.0
    ],
  }) {
    totalCount = 0;
    sum = 0;
    min = double.infinity;
    max = 0;
    for (final bucket in buckets) {
      bucketCounts[bucket] = 0;
    }
  }

  void observe(double value) {
    totalCount++;
    sum += value;
    if (value < min) min = value;
    if (value > max) max = value;

    for (final bucket in buckets) {
      if (value <= bucket) {
        bucketCounts[bucket] = (bucketCounts[bucket] ?? 0) + 1;
      }
    }
  }

  double get p50 {
    if (totalCount == 0) return 0;
    final targetIndex = (totalCount * 0.5).toInt();
    int count = 0;
    for (final bucket in buckets) {
      count += bucketCounts[bucket] ?? 0;
      if (count >= targetIndex) return bucket;
    }
    return max;
  }

  double get p95 {
    if (totalCount == 0) return 0;
    final targetIndex = (totalCount * 0.95).toInt();
    int count = 0;
    for (final bucket in buckets) {
      count += bucketCounts[bucket] ?? 0;
      if (count >= targetIndex) return bucket;
    }
    return max;
  }

  double get p99 {
    if (totalCount == 0) return 0;
    final targetIndex = (totalCount * 0.99).toInt();
    int count = 0;
    for (final bucket in buckets) {
      count += bucketCounts[bucket] ?? 0;
      if (count >= targetIndex) return bucket;
    }
    return max;
  }

  double get average => totalCount == 0 ? 0 : sum / totalCount;

  Map<String, dynamic> toJson() => {
    'total': totalCount,
    'sum': sum,
    'average': average,
    'min': min == double.infinity ? 0 : min,
    'max': max,
    'p50': p50,
    'p95': p95,
    'p99': p99,
  };
}

/// Comprehensive metrics service for monitoring application performance
class MetricsService {
  // HTTP Request Metrics
  late Counter httpRequestsTotal;
  late Counter httpRequestsSuccess;
  late Counter httpRequestsError;
  late Histogram httpRequestDuration;
  late Gauge httpRequestsInFlight;

  // Endpoint-specific metrics
  late Map<String, Histogram> endpointLatencies;
  late Map<String, Counter> endpointCounts;

  // Cache Metrics
  late Counter cacheHits;
  late Counter cacheMisses;
  late Gauge cacheEntriesCount;
  late Gauge cacheMemoryBytes;

  // Database Metrics
  late Gauge dbConnectionsActive;
  late Gauge dbConnectionsIdle;
  late Counter dbQueriesTotal;
  late Counter dbQueryErrors;
  late Histogram dbQueryDuration;

  // System Metrics
  late Gauge systemMemoryBytes;
  late Counter systemErrorsTotal;
  late Gauge uptime;

  // Service health indicators
  late Gauge cacheServiceHealthy;
  late Gauge dbPoolHealthy;
  late Gauge apiHealthy;

  MetricsService() {
    _initializeMetrics();
  }

  void _initializeMetrics() {
    // HTTP metrics
    httpRequestsTotal = Counter();
    httpRequestsSuccess = Counter();
    httpRequestsError = Counter();
    httpRequestDuration = Histogram();
    httpRequestsInFlight = Gauge();

    // Endpoint metrics
    endpointLatencies = {};
    endpointCounts = {};

    // Cache metrics
    cacheHits = Counter();
    cacheMisses = Counter();
    cacheEntriesCount = Gauge();
    cacheMemoryBytes = Gauge();

    // Database metrics
    dbConnectionsActive = Gauge();
    dbConnectionsIdle = Gauge();
    dbQueriesTotal = Counter();
    dbQueryErrors = Counter();
    dbQueryDuration = Histogram();

    // System metrics
    systemMemoryBytes = Gauge();
    systemErrorsTotal = Counter();
    uptime = Gauge();

    // Health indicators
    cacheServiceHealthy = Gauge()..set(1);
    dbPoolHealthy = Gauge()..set(1);
    apiHealthy = Gauge()..set(1);
  }

  /// Record HTTP request metrics
  void recordHttpRequest({
    required String endpoint,
    required int statusCode,
    required double durationMs,
  }) {
    httpRequestsTotal.increment();
    httpRequestDuration.observe(durationMs);

    if (statusCode < 400) {
      httpRequestsSuccess.increment();
    } else {
      httpRequestsError.increment();
    }

    // Record endpoint-specific metrics
    endpointLatencies.putIfAbsent(endpoint, () => Histogram());
    endpointLatencies[endpoint]!.observe(durationMs);

    endpointCounts.putIfAbsent(endpoint, () => Counter());
    endpointCounts[endpoint]!.increment();
  }

  /// Record cache operation metrics
  void recordCacheHit(String operation) {
    cacheHits.increment();
  }

  void recordCacheMiss(String operation) {
    cacheMisses.increment();
  }

  void updateCacheStats({required int entries, required int memoryBytes}) {
    cacheEntriesCount.set(entries.toDouble());
    cacheMemoryBytes.set(memoryBytes.toDouble());
  }

  /// Record database query metrics
  void recordDatabaseQuery({
    required String query,
    required double durationMs,
    required bool success,
  }) {
    dbQueriesTotal.increment();
    dbQueryDuration.observe(durationMs);

    if (!success) {
      dbQueryErrors.increment();
    }
  }

  void updateDatabaseConnections({
    required int active,
    required int idle,
  }) {
    dbConnectionsActive.set(active.toDouble());
    dbConnectionsIdle.set(idle.toDouble());
  }

  /// Record system error
  void recordError(String errorType) {
    systemErrorsTotal.increment();
  }

  /// Update health status for service component
  void updateHealth({
    required String component,
    required bool healthy,
  }) {
    final healthValue = healthy ? 1.0 : 0.0;
    switch (component) {
      case 'cache':
        cacheServiceHealthy.set(healthValue);
        break;
      case 'database':
        dbPoolHealthy.set(healthValue);
        break;
      case 'api':
        apiHealthy.set(healthValue);
        break;
    }
  }

  /// Get cache hit ratio percentage
  double getCacheHitRatio() {
    final total = cacheHits.value + cacheMisses.value;
    if (total == 0) return 0;
    return (cacheHits.value / total) * 100;
  }

  /// Get error rate percentage
  double getErrorRate() {
    final total = httpRequestsSuccess.value + httpRequestsError.value;
    if (total == 0) return 0;
    return (httpRequestsError.value / total) * 100;
  }

  /// Export metrics in Prometheus text format
  String exportPrometheus() {
    final buffer = StringBuffer();

    // HTTP metrics
    buffer.writeln('# HELP http_requests_total Total HTTP requests');
    buffer.writeln('# TYPE http_requests_total counter');
    buffer.writeln('http_requests_total ${httpRequestsTotal.value}');

    buffer.writeln('# HELP http_requests_success Successful HTTP requests');
    buffer.writeln('# TYPE http_requests_success counter');
    buffer.writeln('http_requests_success ${httpRequestsSuccess.value}');

    buffer.writeln('# HELP http_requests_error Failed HTTP requests');
    buffer.writeln('# TYPE http_requests_error counter');
    buffer.writeln('http_requests_error ${httpRequestsError.value}');

    buffer.writeln('# HELP http_request_duration_seconds HTTP request duration');
    buffer.writeln('# TYPE http_request_duration_seconds histogram');
    final httpMetrics = httpRequestDuration.toJson();
    for (final entry in httpMetrics.entries) {
      buffer.writeln('http_request_duration_seconds{quantile="$entry.key"} $entry.value');
    }

    buffer.writeln('# HELP http_requests_in_flight In-flight HTTP requests');
    buffer.writeln('# TYPE http_requests_in_flight gauge');
    buffer.writeln('http_requests_in_flight ${httpRequestsInFlight.value}');

    // Cache metrics
    buffer.writeln('# HELP cache_hits Cache hit count');
    buffer.writeln('# TYPE cache_hits counter');
    buffer.writeln('cache_hits ${cacheHits.value}');

    buffer.writeln('# HELP cache_misses Cache miss count');
    buffer.writeln('# TYPE cache_misses counter');
    buffer.writeln('cache_misses ${cacheMisses.value}');

    buffer.writeln('# HELP cache_hit_ratio Cache hit ratio percentage');
    buffer.writeln('# TYPE cache_hit_ratio gauge');
    buffer.writeln('cache_hit_ratio ${getCacheHitRatio().toStringAsFixed(2)}');

    buffer.writeln('# HELP cache_entries Current cache entries');
    buffer.writeln('# TYPE cache_entries gauge');
    buffer.writeln('cache_entries ${cacheEntriesCount.value.toInt()}');

    // Database metrics
    buffer.writeln('# HELP db_connections_active Active database connections');
    buffer.writeln('# TYPE db_connections_active gauge');
    buffer.writeln('db_connections_active ${dbConnectionsActive.value.toInt()}');

    buffer.writeln('# HELP db_queries_total Total database queries');
    buffer.writeln('# TYPE db_queries_total counter');
    buffer.writeln('db_queries_total ${dbQueriesTotal.value}');

    buffer.writeln('# HELP db_query_errors Database query errors');
    buffer.writeln('# TYPE db_query_errors counter');
    buffer.writeln('db_query_errors ${dbQueryErrors.value}');

    buffer.writeln('# HELP db_query_duration_seconds Database query duration');
    buffer.writeln('# TYPE db_query_duration_seconds histogram');
    final dbMetrics = dbQueryDuration.toJson();
    for (final entry in dbMetrics.entries) {
      buffer.writeln('db_query_duration_seconds{quantile="$entry.key"} $entry.value');
    }

    // Health metrics
    buffer.writeln('# HELP service_health Service component health (1=healthy, 0=unhealthy)');
    buffer.writeln('# TYPE service_health gauge');
    buffer.writeln('service_health{component="cache"} ${cacheServiceHealthy.value.toInt()}');
    buffer.writeln('service_health{component="database"} ${dbPoolHealthy.value.toInt()}');
    buffer.writeln('service_health{component="api"} ${apiHealthy.value.toInt()}');

    return buffer.toString();
  }

  /// Export metrics as JSON
  Map<String, dynamic> exportJson() {
    return {
      'http': {
        'requests_total': httpRequestsTotal.value,
        'requests_success': httpRequestsSuccess.value,
        'requests_error': httpRequestsError.value,
        'request_duration': httpRequestDuration.toJson(),
        'requests_in_flight': httpRequestsInFlight.value,
        'error_rate_percent': getErrorRate(),
      },
      'cache': {
        'hits': cacheHits.value,
        'misses': cacheMisses.value,
        'hit_ratio_percent': getCacheHitRatio(),
        'entries': cacheEntriesCount.value.toInt(),
        'memory_bytes': cacheMemoryBytes.value.toInt(),
      },
      'database': {
        'connections_active': dbConnectionsActive.value.toInt(),
        'connections_idle': dbConnectionsIdle.value.toInt(),
        'queries_total': dbQueriesTotal.value,
        'query_errors': dbQueryErrors.value,
        'query_duration': dbQueryDuration.toJson(),
      },
      'health': {
        'cache_service': cacheServiceHealthy.value.toInt() == 1,
        'database_pool': dbPoolHealthy.value.toInt() == 1,
        'api': apiHealthy.value.toInt() == 1,
      },
      'uptime_seconds': uptime.value.toInt(),
    };
  }

  /// Reset all metrics
  void reset() {
    _initializeMetrics();
  }
}
