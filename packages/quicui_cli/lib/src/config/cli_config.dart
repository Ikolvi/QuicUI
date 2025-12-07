import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// CLI Configuration
class CliConfig {
  final String appId;
  final String appName;
  final String serverUrl;
  final String apiKey;
  final String compression;
  final int retryCount;
  final int timeout;

  CliConfig({
    required this.appId,
    required this.appName,
    required this.serverUrl,
    required this.apiKey,
    this.compression = 'xz',
    this.retryCount = 3,
    this.timeout = 60,
  });

  static Future<CliConfig> load(String projectPath) async {
    final configFile = File(p.join(projectPath, 'quicui.yaml'));
    
    // Check for environment variable override for API key
    final envApiKey = Platform.environment['QUICUI_API_KEY'];
    final defaultApiKey = envApiKey ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjYXh2YW5qaHRmYWVpbWZsZ2ZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNzE3MzIsImV4cCI6MjA3ODk0NzczMn0.XqPTK5bw2IukeGs-XBv0pfLHKAqkGKRmQUEvE1L14lU';
    
    // Use defaults if config file doesn't exist
    if (!await configFile.exists()) {
      return CliConfig(
        appId: 'unknown',
        appName: 'Unknown App',
        serverUrl: 'https://pcaxvanjhtfaeimflgfk.supabase.co/functions/v1',
        apiKey: defaultApiKey,
        compression: 'xz',
        retryCount: 3,
        timeout: 60,
      );
    }

    final content = await configFile.readAsString();
    final yaml = loadYaml(content) as Map;

    return CliConfig(
      appId: yaml['app']?['id'] ?? 'unknown',
      appName: yaml['app']?['name'] ?? 'Unknown App',
      serverUrl: yaml['server']?['url'] ?? 'https://pcaxvanjhtfaeimflgfk.supabase.co/functions/v1',
      apiKey: defaultApiKey,
      compression: yaml['patch']?['compression'] ?? 'xz',
      retryCount: yaml['upload']?['retryCount'] ?? 3,
      timeout: yaml['upload']?['timeout'] ?? 60,
    );
  }

  Map<String, dynamic> toJson() => {
    'appId': appId,
    'appName': appName,
    'serverUrl': serverUrl,
    'compression': compression,
    'retryCount': retryCount,
    'timeout': timeout,
  };
}
