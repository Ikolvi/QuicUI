import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'constants.dart';

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
    
    // Use defaults if config file doesn't exist
    if (!await configFile.exists()) {
      throw Exception(
        'quicui.yaml not found in $projectPath\n'
        'Run "quicui init" to create configuration file.'
      );
    }

    final content = await configFile.readAsString();
    final yaml = loadYaml(content) as Map;

    // Check for environment variable override for API key
    final envApiKey = Platform.environment['QUICUI_API_KEY'];
    final yamlApiKey = yaml['server']?['api_key'] as String?;
    final apiKey = envApiKey ?? yamlApiKey;
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'API key not found!\n'
        'Either set QUICUI_API_KEY environment variable or add server.api_key to quicui.yaml\n'
        'Run "quicui init" to auto-generate an API key.'
      );
    }

    return CliConfig(
      appId: yaml['app']?['id'] ?? 'unknown',
      appName: yaml['app']?['name'] ?? 'Unknown App',
      serverUrl: yaml['server']?['url'] ?? kDefaultServerUrl,
      apiKey: apiKey,
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
