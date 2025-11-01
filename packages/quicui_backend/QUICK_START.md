
# Phase 5.2 - Quick Start Guide

## Starting the Backend

```bash
cd packages/quicui_backend
dart run lib/quicui_backend.dart
```

You should see:
```
🚀 Starting QuicUI Code Push Backend...
📝 Configuration:
   Host: localhost
   Port: 8080
   Environment: Development
✅ Server listening on http://localhost:8080
🎉 Backend ready! Test with: curl http://localhost:8080/health
```

## Testing the Backend

### 1. Health Check

```bash
curl http://localhost:8080/health
```

Response:
```json
{
  "status": "healthy",
  "cache_service": true,
  "database_pool": true,
  "uptime_seconds": 123
}
```

### 2. View Metrics (JSON)

```bash
curl http://localhost:8080/metrics/json | jq .
```

Response includes:
- HTTP request metrics (total, success, errors)
- Cache metrics (hits, misses, hit ratio)
- Database metrics (connections, queries)
- Health status of all components

### 3. View Metrics (Prometheus)

```bash
curl http://localhost:8080/metrics/prometheus
```

Response is in Prometheus text format, suitable for scraping with Prometheus.

### 4. Get Cache Stats

```bash
curl http://localhost:8080/metrics/cache
```

Response includes:
- Cache hit/miss count
- Number of cached entries
- TTL configuration
- Cache hit ratio percentage

### 5. Get Database Stats

```bash
curl http://localhost:8080/metrics/database
```

Response includes:
- Active and idle connections
- Connection pool utilization
- Total queries executed

### 6. Get Query Performance

```bash
curl http://localhost:8080/metrics/queries
```

Response includes:
- Slowest queries (top 10)
- Query execution times
- Success/error rates per query

## Running Performance Tests

### Load Testing

Run comprehensive load tests with 5 scenarios:

```bash
bash scripts/run_load_tests.sh
```

This runs:
1. **Baseline** (100 sequential requests)
2. **Light Load** (500 requests at 10 concurrent)
3. **Medium Load** (1000 requests at 25 concurrent)
4. **Heavy Load** (2000 requests at 50 concurrent)
5. **Stress Test** (5000 requests at 100 concurrent)

Output includes:
- Throughput (req/sec)
- Response time percentiles (p50, p95, p99)
- Success/error rates
- Target comparison

### Performance Profiling

Run CPU and memory analysis:

```bash
bash scripts/run_profiler.sh
```

Output includes:
- CPU hotspots (operations consuming most time)
- Memory allocation patterns
- Bottleneck analysis
- Optimization recommendations

Generated files:
- `profiling_report_YYYY-MM-DD...txt` - Detailed report

## Performance Targets

The backend is optimized to achieve:

| Metric | Target |
|--------|--------|
| Latency P50 | < 50ms |
| Latency P99 | < 200ms |
| Throughput | > 1000 req/sec |
| Cache Hit Ratio | > 80% |
| Success Rate | > 99.5% |
| Error Rate | < 0.5% |

## Key Features Implemented

### 🔄 Caching
- Transparent query result caching
- TTL-based expiration (1m - 1h)
- LRU eviction (10K entries max)
- Automatic invalidation on writes
- 80%+ cache hit ratio target

### 🔗 Connection Pooling
- Pool size: 5-20 connections
- Auto-cleanup of idle connections
- Connection reuse optimization
- Per-connection timeout handling

### 📦 Response Optimization
- Gzip compression (saves 50-70%)
- Cache control headers (ETags)
- Smart 304 responses
- Pagination support

### 📊 Monitoring
- Prometheus-compatible metrics
- JSON metrics export
- Per-endpoint latency tracking
- Health status of all components
- Real-time statistics

### 🧪 Load Testing
- Concurrent request simulation
- 5 benchmark scenarios
- Target-based comparison
- Detailed metrics export

### 🔍 Performance Profiling
- CPU hotspot detection
- Memory allocation tracking
- Bottleneck identification
- Optimization recommendations

## Architecture

```
┌─────────────────────────────────────┐
│         HTTP Requests               │
└──────────────┬──────────────────────┘
               │
      ┌────────▼────────┐
      │   Middleware    │
      │  ┌──────────┐   │
      │  │Logging   │   │
      │  ├──────────┤   │
      │  │Compress  │   │
      │  ├──────────┤   │
      │  │Cache Ctrl│   │
      │  ├──────────┤   │
      │  │Optimize  │   │
      │  ├──────────┤   │
      │  │Security  │   │
      │  └──────────┘   │
      └────────┬────────┘
               │
        ┌──────▼──────┐
        │  Router     │
        ├─────────────┤
        │ /health     │
        │ /api/v1/*   │
        │ /metrics/*  │
        └──────┬──────┘
               │
    ┌──────────┼──────────┐
    │          │          │
    │          │          │
┌───▼──┐ ┌────▼────┐ ┌───▼──┐
│Cache │ │Database │ │Metrics│
│Svc   │ │Pool     │ │Svc    │
└──────┘ └─────────┘ └───────┘
```

## Environment Variables

Optional configuration:

```bash
export SERVER_HOST=localhost    # Default: localhost
export SERVER_PORT=8080         # Default: 8080
export BACKEND_URL=http://localhost:8080  # For load tests
```

## Troubleshooting

### Backend won't start
- Check port 8080 is available: `lsof -i :8080`
- Kill existing process: `pkill -9 dart`
- Check dart is installed: `dart --version`

### Load test fails to connect
- Ensure backend is running
- Check port: `curl http://localhost:8080/health`
- Pass custom URL: `bash scripts/run_load_tests.sh http://localhost:8080`

### Metrics endpoint returns empty
- Wait a moment for metrics to populate
- Make some requests to generate metrics
- Check backend is running with `curl /health`

## Next Steps

1. **Testing Phase:**
   - Run load tests: `bash scripts/run_load_tests.sh`
   - Run profiler: `bash scripts/run_profiler.sh`
   - Verify targets are met

2. **Optimization Phase:**
   - Adjust cache TTLs based on hit ratios
   - Tune connection pool size based on load
   - Identify and optimize hot operations

3. **Production Deployment:**
   - Configure Redis for distributed caching
   - Set up Prometheus scraping
   - Create Grafana dashboards
   - Configure alerts

## Files & Documentation

- `PHASE_5_2_COMPLETE.md` - Comprehensive guide
- `lib/src/cache_service.dart` - Caching implementation
- `lib/src/database_pool.dart` - Connection pooling
- `lib/src/metrics_service.dart` - Metrics collection
- `lib/src/load_test_client.dart` - Load testing
- `lib/src/performance_profiler.dart` - Performance profiling

## Support

For more details, see `PHASE_5_2_COMPLETE.md` with:
- Implementation details
- Performance improvement breakdown
- Monitoring setup
- Deployment guidelines

---

**Status:** Phase 5.2 Complete & Ready for Testing ✅
**Next:** Phase 5.3 - Security Hardening & v1.0.0 Release

