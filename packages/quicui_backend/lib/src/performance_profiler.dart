import 'dart:async';
import 'dart:io';
import 'dart:convert';

/// Profiling data for a single operation
class ProfileSample {
  final String operation;
  final int memoryBytes;
  final int durationMs;
  final DateTime timestamp;

  ProfileSample({
    required this.operation,
    required this.memoryBytes,
    required this.durationMs,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'operation': operation,
    'memory_bytes': memoryBytes,
    'duration_ms': durationMs,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Memory profile result
class MemoryProfile {
  final String name;
  final List<ProfileSample> samples;
  final DateTime startTime;
  final DateTime endTime;

  MemoryProfile({
    required this.name,
    required this.samples,
    required this.startTime,
    required this.endTime,
  });

  Duration get duration => endTime.difference(startTime);
  int get minMemory => samples.isEmpty ? 0 : samples.map((s) => s.memoryBytes).reduce((a, b) => a < b ? a : b);
  int get maxMemory => samples.isEmpty ? 0 : samples.map((s) => s.memoryBytes).reduce((a, b) => a > b ? a : b);
  int get avgMemory => samples.isEmpty ? 0 : samples.map((s) => s.memoryBytes).reduce((a, b) => a + b) ~/ samples.length;
  int get peakMemory => maxMemory;

  Map<String, dynamic> toJson() => {
    'name': name,
    'duration_seconds': duration.inSeconds,
    'sample_count': samples.length,
    'memory': {
      'min_mb': (minMemory / 1024 / 1024).toStringAsFixed(2),
      'max_mb': (maxMemory / 1024 / 1024).toStringAsFixed(2),
      'average_mb': (avgMemory / 1024 / 1024).toStringAsFixed(2),
      'peak_mb': (peakMemory / 1024 / 1024).toStringAsFixed(2),
    },
  };

  void printResults() {
    print('''
╔════════════════════════════════════════════════════════════════╗
║ Memory Profile: $name
╚════════════════════════════════════════════════════════════════╝

📊 Summary:
  Duration:           ${duration.inSeconds}s
  Sample Count:       ${samples.length}
  Sampling Interval:  ${duration.inSeconds > 0 ? (duration.inMilliseconds ~/ samples.length) : 0}ms

🧠 Memory Usage:
  Minimum:            ${(minMemory / 1024 / 1024).toStringAsFixed(2)} MB
  Maximum:            ${(maxMemory / 1024 / 1024).toStringAsFixed(2)} MB
  Average:            ${(avgMemory / 1024 / 1024).toStringAsFixed(2)} MB
  Peak:               ${(peakMemory / 1024 / 1024).toStringAsFixed(2)} MB
''');
  }
}

/// CPU profile result
class CpuProfile {
  final String name;
  final Map<String, int> operationCounts;
  final Map<String, int> operationDurations; // total ms per operation
  final DateTime startTime;
  final DateTime endTime;

  CpuProfile({
    required this.name,
    required this.operationCounts,
    required this.operationDurations,
    required this.startTime,
    required this.endTime,
  });

  Duration get duration => endTime.difference(startTime);

  List<MapEntry<String, double>> get hotspots {
    final result = <MapEntry<String, double>>[];
    for (final op in operationDurations.keys) {
      final percentage = (operationDurations[op]! / duration.inMilliseconds * 100);
      result.add(MapEntry(op, percentage));
    }
    result.sort((a, b) => b.value.compareTo(a.value));
    return result;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'duration_seconds': duration.inSeconds,
    'operations': operationCounts,
    'durations_ms': operationDurations,
    'hotspots': {
      for (final entry in hotspots)
        entry.key: '${entry.value.toStringAsFixed(2)}%'
    },
  };

  void printResults() {
    print('''
╔════════════════════════════════════════════════════════════════╗
║ CPU Profile: $name
╚════════════════════════════════════════════════════════════════╝

📊 Summary:
  Duration:           ${duration.inSeconds}s
  Total Operations:   ${operationCounts.values.reduce((a, b) => a + b)}

🔥 Hotspots (by CPU time %):
''');

    for (final entry in hotspots.take(10)) {
      final op = entry.key;
      final percentage = entry.value;
      final count = operationCounts[op] ?? 0;
      final totalDuration = operationDurations[op] ?? 0;
      final avgDuration = count > 0 ? totalDuration / count : 0;

      print('''  $op:
      Time: ${percentage.toStringAsFixed(2)}%
      Calls: $count
      Total: ${totalDuration}ms
      Avg: ${avgDuration.toStringAsFixed(2)}ms''');
    }
    print('');
  }
}

/// Performance profiler
class PerformanceProfiler {
  final Map<String, List<ProfileSample>> memoryProfiles = {};
  final Map<String, CpuProfile> cpuProfiles = {};
  final Map<String, int> operationCounts = {};
  final Map<String, int> operationDurations = {};
  final Map<String, List<int>> operationLatencies = {};

  late DateTime profileStartTime;

  /// Start profiling
  void startProfiling() {
    profileStartTime = DateTime.now();
    operationCounts.clear();
    operationDurations.clear();
    operationLatencies.clear();
  }

  /// Record operation timing
  void recordOperation(String name, int durationMs) {
    operationCounts[name] = (operationCounts[name] ?? 0) + 1;
    operationDurations[name] = (operationDurations[name] ?? 0) + durationMs;
    operationLatencies.putIfAbsent(name, () => []).add(durationMs);
  }

  /// Record memory sample
  void recordMemorySample(String profileName, int memoryBytes, String operation) {
    memoryProfiles.putIfAbsent(profileName, () => []).add(
      ProfileSample(
        operation: operation,
        memoryBytes: memoryBytes,
        durationMs: DateTime.now().difference(profileStartTime).inMilliseconds,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Stop profiling and generate report
  CpuProfile stopProfiling(String profileName) {
    final profile = CpuProfile(
      name: profileName,
      operationCounts: Map.from(operationCounts),
      operationDurations: Map.from(operationDurations),
      startTime: profileStartTime,
      endTime: DateTime.now(),
    );
    cpuProfiles[profileName] = profile;
    return profile;
  }

  /// Get memory profile results
  MemoryProfile? getMemoryProfile(String profileName) {
    final samples = memoryProfiles[profileName];
    if (samples == null || samples.isEmpty) return null;

    return MemoryProfile(
      name: profileName,
      samples: samples,
      startTime: samples.first.timestamp,
      endTime: samples.last.timestamp,
    );
  }

  /// Analyze bottlenecks
  Map<String, dynamic> analyzeBottlenecks() {
    final bottlenecks = <String, dynamic>{};

    // Find slowest operations
    final slowestOps = <MapEntry<String, double>>[];
    for (final op in operationDurations.keys) {
      final count = operationCounts[op] ?? 1;
      final avgDuration = operationDurations[op]! / count;
      slowestOps.add(MapEntry(op, avgDuration));
    }
    slowestOps.sort((a, b) => b.value.compareTo(a.value));

    bottlenecks['slowest_operations'] = {
      for (final entry in slowestOps.take(5))
        entry.key: '${entry.value.toStringAsFixed(2)}ms avg'
    };

    // Find most called operations
    final mostCalledOps = <MapEntry<String, int>>[];
    for (final op in operationCounts.keys) {
      mostCalledOps.add(MapEntry(op, operationCounts[op]!));
    }
    mostCalledOps.sort((a, b) => b.value.compareTo(a.value));

    bottlenecks['most_called_operations'] = {
      for (final entry in mostCalledOps.take(5))
        entry.key: '${entry.value} calls'
    };

    // Calculate time distribution
    final totalTime = operationDurations.values.reduce((a, b) => a + b);
    bottlenecks['time_distribution'] = {
      for (final op in operationDurations.keys)
        op: '${((operationDurations[op]! / totalTime * 100)).toStringAsFixed(2)}%'
    };

    return bottlenecks;
  }

  /// Export profile data
  Map<String, dynamic> exportData() {
    return {
      'cpu_profiles': {
        for (final entry in cpuProfiles.entries)
          entry.key: entry.value.toJson()
      },
      'memory_profiles': {
        for (final profileName in memoryProfiles.keys)
          profileName: getMemoryProfile(profileName)?.toJson()
      },
      'bottlenecks': analyzeBottlenecks(),
    };
  }

  /// Generate recommendations
  List<String> generateRecommendations() {
    final recommendations = <String>[];
    final bottlenecks = analyzeBottlenecks();

    // Analyze slowest operations
    if (bottlenecks['slowest_operations'] != null) {
      recommendations.add(
        '⚡ Optimize slowest operations: ${bottlenecks['slowest_operations'].keys.first}',
      );
    }

    // Analyze most called operations
    if (bottlenecks['most_called_operations'] != null) {
      final mostCalled = bottlenecks['most_called_operations'].entries.first;
      if (mostCalled.value > 100) {
        recommendations.add(
          '🔄 Reduce calls to: ${mostCalled.key} (called frequently)',
        );
      }
    }

    // Memory recommendations
    final totalMemory = operationCounts.values.reduce((a, b) => a + b);
    if (totalMemory > 10000) {
      recommendations.add('💾 Consider caching frequently accessed data');
    }

    // Concurrency recommendations
    recommendations.add('⚙️ Consider increasing connection pool size based on throughput');

    // General recommendations
    recommendations.add('📊 Review /metrics/prometheus endpoint for detailed performance metrics');
    recommendations.add('🧪 Run load tests with: bash scripts/run_load_tests.sh');

    return recommendations;
  }
}

/// Generate profiling report
void generateProfilingReport(PerformanceProfiler profiler, String filename) {
  final report = StringBuffer();

  report.writeln('''
╔════════════════════════════════════════════════════════════════╗
║         QuicUI Backend Performance Profiling Report             ║
╚════════════════════════════════════════════════════════════════╝

Generated: ${DateTime.now().toIso8601String()}

## Executive Summary

This report analyzes the performance characteristics of the QuicUI backend,
including CPU usage, memory allocation, and operation latencies.

## CPU Profiling Results

''');

  for (final profile in profiler.cpuProfiles.values) {
    report.writeln(profile.toJson().toString());
  }

  report.writeln('''
## Bottleneck Analysis

${const JsonEncoder.withIndent('  ').convert(profiler.analyzeBottlenecks())}

## Recommendations

${profiler.generateRecommendations().map((r) => '• $r').join('\n')}

## Detailed Data

${const JsonEncoder.withIndent('  ').convert(profiler.exportData())}
''');

  File(filename).writeAsStringSync(report.toString());
  print('✅ Profiling report exported to: $filename');
}

/// Example usage and main entry point
Future<void> main() async {
  final profiler = PerformanceProfiler();

  print('''
╔════════════════════════════════════════════════════════════════╗
║      QuicUI Backend Performance Profiling Tool                 ║
╚════════════════════════════════════════════════════════════════╝

📊 This tool analyzes the performance characteristics of the backend:
   • CPU usage and hotspots
   • Memory allocation patterns
   • Operation latencies
   • Bottleneck identification
   • Optimization recommendations

🚀 Running performance simulation...
''');

  profiler.startProfiling();

  // Simulate various operations
  for (int i = 0; i < 100; i++) {
    profiler.recordOperation('list_apps', 5 + (i % 10));
    profiler.recordOperation('get_patches', 8 + (i % 15));
    profiler.recordOperation('cache_lookup', 2 + (i % 5));
    profiler.recordOperation('db_query', 12 + (i % 20));
    profiler.recordMemorySample('main', 50000000 + (i * 10000), 'list_apps');
  }

  final cpuProfile = profiler.stopProfiling('benchmark');
  cpuProfile.printResults();

  final memProfile = profiler.getMemoryProfile('main');
  if (memProfile != null) {
    memProfile.printResults();
  }

  // Analyze bottlenecks
  print('''
╔════════════════════════════════════════════════════════════════╗
║                   Bottleneck Analysis                          ║
╚════════════════════════════════════════════════════════════════╝
''');

  final bottlenecks = profiler.analyzeBottlenecks();
  print(JsonEncoder.withIndent('  ').convert(bottlenecks));

  // Generate recommendations
  print('''
╔════════════════════════════════════════════════════════════════╗
║                  Performance Recommendations                   ║
╚════════════════════════════════════════════════════════════════╝
''');

  for (final rec in profiler.generateRecommendations()) {
    print(rec);
  }

  // Generate report
  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  generateProfilingReport(profiler, 'profiling_report_$timestamp.txt');

  print('\n✅ Profiling analysis complete!');
}
