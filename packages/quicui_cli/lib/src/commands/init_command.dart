import 'dart:io';
import 'dart:convert';
import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Command to initialize QuicUI in a Flutter project
class InitCommand extends Command<void> {
  @override
  final name = 'init';

  @override
  final description = 'Initialize QuicUI in a Flutter project (creates quicui.yaml)';

  InitCommand() {
    argParser.addOption(
      'project',
      abbr: 'p',
      help: 'Path to Flutter project (defaults to current directory)',
      defaultsTo: '.',
    );
    argParser.addOption(
      'app-id',
      help: 'Application ID (e.g., com.example.myapp)',
    );
    argParser.addOption(
      'app-name',
      help: 'Application name',
    );
    argParser.addOption(
      'server-url',
      help: 'QuicUI server URL',
      defaultsTo: 'https://pcaxvanjhtfaeimflgfk.supabase.co/functions/v1',
    );
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Overwrite existing quicui.yaml',
      defaultsTo: false,
    );
  }

  @override
  Future<void> run() async {
    final projectPath = argResults?['project'] as String? ?? '.';
    final force = argResults?['force'] as bool? ?? false;
    
    print('🚀 QuicUI Initialization');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    // Check if it's a Flutter project
    final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));
    if (!await pubspecFile.exists()) {
      print('❌ Error: Not a Flutter project (pubspec.yaml not found)');
      print('   Run this command from your Flutter project directory.');
      exit(1);
    }

    // Check if quicui.yaml already exists
    final configFile = File(p.join(projectPath, 'quicui.yaml'));
    if (await configFile.exists() && !force) {
      print('⚠️  quicui.yaml already exists!');
      print('   Use --force to overwrite.');
      exit(1);
    }

    // Read app info from pubspec.yaml
    final pubspecContent = await pubspecFile.readAsString();
    final pubspec = loadYaml(pubspecContent) as Map;
    
    // Get app ID from Android manifest or use pubspec name
    String appId = argResults?['app-id'] as String? ?? '';
    String appName = argResults?['app-name'] as String? ?? '';
    
    if (appId.isEmpty) {
      appId = await _detectAppId(projectPath, pubspec['name'] as String? ?? 'unknown');
    }
    
    if (appName.isEmpty) {
      appName = pubspec['description'] as String? ?? pubspec['name'] as String? ?? 'My App';
    }

    final serverUrl = argResults?['server-url'] as String? ?? 
        'https://pcaxvanjhtfaeimflgfk.supabase.co/functions/v1';

    // Auto-generate API key from server
    print('🔑 Generating API key...');
    String? apiKey;
    try {
      apiKey = await _generateApiKey(serverUrl, appId, appName);
      print('   ✅ API key generated successfully');
    } catch (e) {
      print('   ⚠️  Could not auto-generate API key: $e');
      print('   Using default anon key (limited functionality)');
      // Fallback to anon key
      apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjYXh2YW5qaHRmYWVpbWZsZ2ZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNzE3MzIsImV4cCI6MjA3ODk0NzczMn0.XqPTK5bw2IukeGs-XBv0pfLHKAqkGKRmQUEvE1L14lU';
    }

    // Generate quicui.yaml
    final yamlContent = _generateYamlContent(
      appId: appId,
      appName: appName,
      serverUrl: serverUrl,
      apiKey: apiKey,
    );

    await configFile.writeAsString(yamlContent);

    print('✅ Created quicui.yaml\n');
    print('📋 Configuration:');
    print('   App ID: $appId');
    print('   App Name: $appName');
    print('   Server: $serverUrl');
    print('');
    print('📝 Next steps:');
    print('   1. Review and edit quicui.yaml as needed');
    print('   2. Add quicui_code_push_client to your pubspec.yaml');
    print('   3. Initialize QuicUI in your app:');
    print('      await QuicUICodePush.instance.initialize();');
    print('   4. Create your first release:');
    print('      quicui release --version 1.0.0');
  }

  Future<String> _detectAppId(String projectPath, String defaultName) async {
    // Try to read from Android build.gradle
    final buildGradle = File(p.join(projectPath, 'android', 'app', 'build.gradle'));
    if (await buildGradle.exists()) {
      final content = await buildGradle.readAsString();
      // Match: applicationId "com.example.app" or applicationId = "com.example.app"
      final appIdPattern = RegExp(r'''applicationId\s*[=:]?\s*["']([^"']+)["']''');
      final match = appIdPattern.firstMatch(content);
      if (match != null) {
        return match.group(1)!;
      }
      
      // Try namespace
      final namespacePattern = RegExp(r'''namespace\s*[=:]?\s*["']([^"']+)["']''');
      final namespaceMatch = namespacePattern.firstMatch(content);
      if (namespaceMatch != null) {
        return namespaceMatch.group(1)!;
      }
    }

    // Try build.gradle.kts
    final buildGradleKts = File(p.join(projectPath, 'android', 'app', 'build.gradle.kts'));
    if (await buildGradleKts.exists()) {
      final content = await buildGradleKts.readAsString();
      final appIdPattern = RegExp(r'applicationId\s*=\s*"([^"]+)"');
      final match = appIdPattern.firstMatch(content);
      if (match != null) {
        return match.group(1)!;
      }
    }

    // Fallback to pubspec name
    return 'com.example.$defaultName';
  }

  /// Generate API key from QuicUI server
  Future<String> _generateApiKey(String serverUrl, String appId, String appName) async {
    final uri = Uri.parse('$serverUrl/api-keys-cli');
    
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjYXh2YW5qaHRmYWVpbWZsZ2ZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMzNzE3MzIsImV4cCI6MjA3ODk0NzczMn0.XqPTK5bw2IukeGs-XBv0pfLHKAqkGKRmQUEvE1L14lU',
      },
      body: jsonEncode({
        'app_id': appId,
        'app_name': appName,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    
    if (json['success'] != true) {
      throw Exception(json['error'] ?? 'Unknown error');
    }

    return json['api_key'] as String;
  }

  String _generateYamlContent({
    required String appId,
    required String appName,
    required String serverUrl,
    required String apiKey,
  }) {
    return '''# QuicUI Code Push Configuration
# Generated by: quicui init

# Backend server configuration
server:
  url: "$serverUrl"
  # API key auto-generated by QuicUI CLI
  api_key: "$apiKey"

# Application configuration
app:
  id: "$appId"
  name: "$appName"

# Version management
version:
  current: "1.0.0"
  auto_increment: true
  format: "semantic"

# Build configuration
build:
  flutter_project: "."
  output_dir: ".quicui"
  apk_path: "build/app/outputs/flutter-apk/app-release.apk"
  
  # Target architectures for patch generation
  architectures:
    - arm64-v8a
    # - armeabi-v7a  # Uncomment for 32-bit ARM support

# Patch configuration
patch:
  compression: xz  # Best compression for minimal download size
  skip_if_identical: true
  keep_old_patches: 3

# Upload configuration
upload:
  auto_upload: true
  retry_count: 3
  timeout: 60

# Advanced options
advanced:
  cache_base_snapshots: true
  parallel_generation: true
  verbose: false
  dry_run: false

# Notification configuration (optional)
notifications:
  enabled: false
  webhook_url: null
  notify_on_success: true
  notify_on_failure: true
''';
  }
}
