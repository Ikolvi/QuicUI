import 'dart:io';
import 'package:args/command_runner.dart';
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

    // Generate quicui.yaml
    final yamlContent = _generateYamlContent(
      appId: appId,
      appName: appName,
      serverUrl: serverUrl,
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

  String _generateYamlContent({
    required String appId,
    required String appName,
    required String serverUrl,
  }) {
    return '''# QuicUI Code Push Configuration
# Generated by: quicui init

# Backend server configuration
server:
  url: "$serverUrl"
  # API key can be set via QUICUI_API_KEY environment variable
  # api_key: "your-api-key-here"

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
