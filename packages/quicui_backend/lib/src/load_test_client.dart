import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Performance test result
class TestResult {
  final String name;
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final List<int> responseTimes; // in milliseconds
  final DateTime startTime;
  final DateTime endTime;

  TestResult({
    required this.name,
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.responseTimes,
    required this.startTime,
    required this.endTime,
  });

  Duration get duration => endTime.difference(startTime);
  double get throughput => totalRequests / (duration.inSeconds > 0 ? duration.inSeconds : 1);
  int get minResponseTime => responseTimes.isEmpty ? 0 : responseTimes.reduce((a, b) => a < b ? a : b);
  int get maxResponseTime => responseTimes.isEmpty ? 0 : responseTimes.reduce((a, b) => a > b ? a : b);
  double get avgResponseTime => responseTimes.isEmpty ? 0 : responseTimes.reduce((a, b) => a + b) / responseTimes.length;

  int get p50 {
    if (responseTimes.isEmpty) return 0;
    final sorted = List<int>.from(responseTimes)..sort();
    return sorted[(sorted.length * 0.5).toInt()];
  }

  int get p95 {
    if (responseTimes.isEmpty) return 0;
    final sorted = List<int>.from(responseTimes)..sort();
    return sorted[(sorted.length * 0.95).toInt()];
  }

  int get p99 {
    if (responseTimes.isEmpty) return 0;
    final sorted = List<int>.from(responseTimes)..sort();
    return sorted[(sorted.length * 0.99).toInt()];
  }

  double get errorRate => totalRequests == 0 ? 0 : (failedRequests / totalRequests) * 100;
  double get successRate => totalRequests == 0 ? 0 : (successfulRequests / totalRequests) * 100;

  Map<String, dynamic> toJson() => {
    'name': name,
    'total_requests': totalRequests,
    'successful_requests': successfulRequests,
    'failed_requests': failedRequests,
    'duration_seconds': duration.inSeconds,
    'throughput_req_per_sec': throughput.toStringAsFixed(2),
    'response_times': {
      'min_ms': minResponseTime,
      'max_ms': maxResponseTime,
      'average_ms': avgResponseTime.toStringAsFixed(2),
      'p50_ms': p50,
      'p95_ms': p95,
      'p99_ms': p99,
    },
    'success_rate_percent': successRate.toStringAsFixed(2),
    'error_rate_percent': errorRate.toStringAsFixed(2),
  };

  void printResults() {
    print('''
╔════════════════════════════════════════════════════════════════╗
║ Test: $name
╚════════════════════════════════════════════════════════════════╝

📊 Summary:
  Total Requests:     $totalRequests
  Successful:         $successfulRequests
  Failed:             $failedRequests
  Success Rate:       ${successRate.toStringAsFixed(2)}%
  Error Rate:         ${errorRate.toStringAsFixed(2)}%

⏱️  Timing:
  Duration:           ${duration.inSeconds}s
  Throughput:         ${throughput.toStringAsFixed(2)} req/sec

📈 Response Times:
  Min:                ${minResponseTime}ms
  Max:                ${maxResponseTime}ms
  Average:            ${avgResponseTime.toStringAsFixed(2)}ms
  p50:                ${p50}ms
  p95:                ${p95}ms
  p99:                ${p99}ms
''');
  }
}

/// Load testing client
class LoadTestClient {
  final String baseUrl;
  final Duration timeout;

  LoadTestClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
  });

  /// Perform a single HTTP request
  Future<int?> _performRequest(String method, String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final stopwatch = Stopwatch()..start();

      final response = method == 'GET'
          ? await http.get(url).timeout(timeout)
          : await http.post(url).timeout(timeout);

      stopwatch.stop();
      return response.statusCode < 400 ? stopwatch.elapsedMilliseconds : null;
    } catch (e) {
      return null;
    }
  }

  /// Run a load test with specified concurrent requests
  Future<TestResult> runLoadTest({
    required String testName,
    required String endpoint,
    required int totalRequests,
    int concurrentRequests = 10,
    String method = 'GET',
  }) async {
    print('🚀 Starting load test: $testName');
    print('   Endpoint: $endpoint');
    print('   Total Requests: $totalRequests');
    print('   Concurrent: $concurrentRequests');
    print('');

    final startTime = DateTime.now();
    final responseTimes = <int>[];
    var successfulRequests = 0;
    var failedRequests = 0;

    // Create batches of concurrent requests
    for (int i = 0; i < totalRequests; i += concurrentRequests) {
      final batchSize = (i + concurrentRequests) <= totalRequests
          ? concurrentRequests
          : totalRequests - i;

      final futures = <Future<int?>>[];
      for (int j = 0; j < batchSize; j++) {
        futures.add(_performRequest(method, endpoint));
      }

      final results = await Future.wait(futures);
      for (final result in results) {
        if (result != null) {
          responseTimes.add(result);
          successfulRequests++;
        } else {
          failedRequests++;
        }
      }

      // Print progress
      final completed = i + batchSize;
      final progress = (completed / totalRequests * 100).toStringAsFixed(1);
      print('   Progress: $completed/$totalRequests ($progress%)');
    }

    final endTime = DateTime.now();
    return TestResult(
      name: testName,
      totalRequests: totalRequests,
      successfulRequests: successfulRequests,
      failedRequests: failedRequests,
      responseTimes: responseTimes,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Run multiple test scenarios
  Future<List<TestResult>> runFullBenchmark({
    String baseEndpoint = '/api/v1/apps',
  }) async {
    final results = <TestResult>[];

    print('''
╔════════════════════════════════════════════════════════════════╗
║           QuicUI Backend Performance Benchmark Suite           ║
╚════════════════════════════════════════════════════════════════╝
''');

    // Test 1: Baseline - 100 requests with 1 concurrent
    print('📝 Test 1: Baseline (Sequential Requests)');
    var result = await runLoadTest(
      testName: 'Baseline - Sequential',
      endpoint: baseEndpoint,
      totalRequests: 100,
      concurrentRequests: 1,
    );
    result.printResults();
    results.add(result);

    print('\n');

    // Test 2: Light load - 500 requests with 10 concurrent
    print('📝 Test 2: Light Load');
    result = await runLoadTest(
      testName: 'Light Load',
      endpoint: baseEndpoint,
      totalRequests: 500,
      concurrentRequests: 10,
    );
    result.printResults();
    results.add(result);

    print('\n');

    // Test 3: Medium load - 1000 requests with 25 concurrent
    print('📝 Test 3: Medium Load');
    result = await runLoadTest(
      testName: 'Medium Load',
      endpoint: baseEndpoint,
      totalRequests: 1000,
      concurrentRequests: 25,
    );
    result.printResults();
    results.add(result);

    print('\n');

    // Test 4: Heavy load - 2000 requests with 50 concurrent
    print('📝 Test 4: Heavy Load');
    result = await runLoadTest(
      testName: 'Heavy Load',
      endpoint: baseEndpoint,
      totalRequests: 2000,
      concurrentRequests: 50,
    );
    result.printResults();
    results.add(result);

    print('\n');

    // Test 5: Stress test - 5000 requests with 100 concurrent
    print('📝 Test 5: Stress Test');
    result = await runLoadTest(
      testName: 'Stress Test',
      endpoint: baseEndpoint,
      totalRequests: 5000,
      concurrentRequests: 100,
    );
    result.printResults();
    results.add(result);

    return results;
  }

  /// Compare results against targets
  Future<void> compareAgainstTargets(List<TestResult> results) async {
    const targetLatencyP50 = 50; // ms
    const targetLatencyP99 = 200; // ms
    const targetThroughput = 1000; // req/sec
    const targetSuccessRate = 99.5; // percent

    print('''
╔════════════════════════════════════════════════════════════════╗
║                   Performance Target Analysis                  ║
╚════════════════════════════════════════════════════════════════╝

📊 Performance Targets:
  • Latency P50:  < ${targetLatencyP50}ms
  • Latency P99:  < ${targetLatencyP99}ms
  • Throughput:   > ${targetThroughput} req/sec
  • Success Rate: > ${targetSuccessRate}%

📈 Results vs Targets:
''');

    for (final result in results) {
      final p50Status = result.p50 <= targetLatencyP50 ? '✅' : '❌';
      final p99Status = result.p99 <= targetLatencyP99 ? '✅' : '❌';
      final throughputStatus = result.throughput >= targetThroughput ? '✅' : '❌';
      final successStatus = result.successRate >= targetSuccessRate ? '✅' : '❌';

      print('''
${result.name}:
  $p50Status P50: ${result.p50}ms (target: < $targetLatencyP50 ms)
  $p99Status P99: ${result.p99}ms (target: < $targetLatencyP99 ms)
  $throughputStatus Throughput: ${result.throughput.toStringAsFixed(2)} req/sec (target: > $targetThroughput)
  $successStatus Success Rate: ${result.successRate.toStringAsFixed(2)}% (target: > $targetSuccessRate%)
''');
    }
  }

  /// Export results to JSON file
  Future<void> exportResults(List<TestResult> results, String filename) async {
    final file = File(filename);
    final json = results.map((r) => r.toJson()).toList();
    await file.writeAsString(jsonEncode(json));
    print('✅ Results exported to: $filename');
  }
}

/// Main entry point for load testing
Future<void> main(List<String> args) async {
  final baseUrl = Platform.environment['BACKEND_URL'] ?? 'http://localhost:8080';
  final client = LoadTestClient(baseUrl: baseUrl);

  try {
    // Run full benchmark suite
    final results = await client.runFullBenchmark();

    // Compare against targets
    await client.compareAgainstTargets(results);

    // Export results
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    await client.exportResults(results, 'load_test_results_$timestamp.json');
  } catch (e) {
    print('❌ Error running load tests: $e');
    exit(1);
  }
}
