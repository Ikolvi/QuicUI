import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

/// QuicUI compiler configuration
class QuicUIConfig {
  final ServerConfig server;
  final AppConfig app;
  final VersionConfig version;
  final BuildConfig build;
  final PatchConfig patch;
  final UploadConfig upload;
  final AdvancedConfig advanced;

  QuicUIConfig({
    required this.server,
    required this.app,
    required this.version,
    required this.build,
    required this.patch,
    required this.upload,
    required this.advanced,
  });

  /// Load configuration from quicui.yaml file
  static Future<QuicUIConfig> load([String? configPath]) async {
    configPath ??= 'quicui.yaml';

    final file = File(configPath);
    if (!await file.exists()) {
      throw FileSystemException(
        'Configuration file not found: $configPath\n'
        'Copy quicui.yaml.example to quicui.yaml and configure it.',
      );
    }

    final content = await file.readAsString();
    final yaml = loadYaml(content) as YamlMap;

    return QuicUIConfig(
      server: ServerConfig.fromYaml(yaml['server'] as YamlMap),
      app: AppConfig.fromYaml(yaml['app'] as YamlMap),
      version: VersionConfig.fromYaml(yaml['version'] as YamlMap),
      build: BuildConfig.fromYaml(yaml['build'] as YamlMap),
      patch: PatchConfig.fromYaml(yaml['patch'] as YamlMap),
      upload: UploadConfig.fromYaml(yaml['upload'] as YamlMap),
      advanced: AdvancedConfig.fromYaml(yaml['advanced'] as YamlMap),
    );
  }

  /// Save current version back to config file
  Future<void> saveVersion(String newVersion, [String? configPath]) async {
    configPath ??= 'quicui.yaml';
    final file = File(configPath);
    
    if (!await file.exists()) {
      throw FileSystemException('Configuration file not found: $configPath');
    }

    // Read current content
    final lines = await file.readAsLines();
    
    // Find and update the current version line
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim().startsWith('current:')) {
        lines[i] = '  current: "$newVersion"  # Updated: ${DateTime.now()}';
        break;
      }
    }

    // Write back
    await file.writeAsString(lines.join('\n'));
  }
}

/// Server configuration
class ServerConfig {
  final String url;
  final String? apiKey;

  ServerConfig({
    required this.url,
    this.apiKey,
  });

  factory ServerConfig.fromYaml(YamlMap yaml) {
    return ServerConfig(
      url: yaml['url'] as String,
      apiKey: yaml['api_key'] as String?,
    );
  }
}

/// App configuration
class AppConfig {
  final String id;
  final String name;

  AppConfig({
    required this.id,
    required this.name,
  });

  factory AppConfig.fromYaml(YamlMap yaml) {
    return AppConfig(
      id: yaml['id'] as String,
      name: yaml['name'] as String,
    );
  }
}

/// Version configuration
class VersionConfig {
  final String current;
  final bool autoIncrement;
  final String format;

  VersionConfig({
    required this.current,
    required this.autoIncrement,
    required this.format,
  });

  factory VersionConfig.fromYaml(YamlMap yaml) {
    return VersionConfig(
      current: yaml['current'] as String,
      autoIncrement: yaml['auto_increment'] as bool? ?? true,
      format: yaml['format'] as String? ?? 'semantic',
    );
  }

  /// Get next version based on auto_increment and format
  String getNextVersion() {
    if (!autoIncrement) {
      return current;
    }

    if (format == 'semantic') {
      final parts = current.split('.');
      if (parts.length == 3) {
        final major = int.parse(parts[0]);
        final minor = int.parse(parts[1]);
        final patch = int.parse(parts[2]);
        return '$major.$minor.${patch + 1}';
      }
    } else if (format == 'timestamp') {
      final now = DateTime.now();
      final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      return '$current-$timestamp';
    }

    // Fallback: just append +1
    return '$current.1';
  }
}

/// Build configuration
class BuildConfig {
  final String flutterProject;
  final String outputDir;
  final String apkPath;
  final List<String> architectures;

  BuildConfig({
    required this.flutterProject,
    required this.outputDir,
    required this.apkPath,
    required this.architectures,
  });

  factory BuildConfig.fromYaml(YamlMap yaml) {
    return BuildConfig(
      flutterProject: yaml['flutter_project'] as String? ?? '.',
      outputDir: yaml['output_dir'] as String? ?? '.quicui',
      apkPath: yaml['apk_path'] as String? ?? 
          'build/app/outputs/flutter-apk/app-release.apk',
      architectures: (yaml['architectures'] as YamlList?)
              ?.map((e) => e as String)
              .toList() ??
          ['arm64-v8a', 'armeabi-v7a'],
    );
  }

  /// Get absolute path to Flutter project
  String getAbsoluteProjectPath() {
    return p.isAbsolute(flutterProject)
        ? flutterProject
        : p.join(Directory.current.path, flutterProject);
  }

  /// Get absolute path to output directory
  String getAbsoluteOutputPath() {
    return p.isAbsolute(outputDir)
        ? outputDir
        : p.join(getAbsoluteProjectPath(), outputDir);
  }

  /// Get absolute path to APK
  String getAbsoluteApkPath() {
    return p.join(getAbsoluteProjectPath(), apkPath);
  }
}

/// Patch configuration
class PatchConfig {
  final String compression;
  final bool skipIfIdentical;
  final int keepOldPatches;

  PatchConfig({
    required this.compression,
    required this.skipIfIdentical,
    required this.keepOldPatches,
  });

  factory PatchConfig.fromYaml(YamlMap yaml) {
    return PatchConfig(
      compression: yaml['compression'] as String? ?? 'xz',
      skipIfIdentical: yaml['skip_if_identical'] as bool? ?? true,
      keepOldPatches: yaml['keep_old_patches'] as int? ?? 3,
    );
  }
}

/// Upload configuration
class UploadConfig {
  final bool autoUpload;
  final int retryCount;
  final int timeout;

  UploadConfig({
    required this.autoUpload,
    required this.retryCount,
    required this.timeout,
  });

  factory UploadConfig.fromYaml(YamlMap yaml) {
    return UploadConfig(
      autoUpload: yaml['auto_upload'] as bool? ?? true,
      retryCount: yaml['retry_count'] as int? ?? 3,
      timeout: yaml['timeout'] as int? ?? 60,
    );
  }
}

/// Advanced configuration
class AdvancedConfig {
  final bool cacheBaseSnapshots;
  final bool parallelGeneration;
  final bool verbose;
  final bool dryRun;

  AdvancedConfig({
    required this.cacheBaseSnapshots,
    required this.parallelGeneration,
    required this.verbose,
    required this.dryRun,
  });

  factory AdvancedConfig.fromYaml(YamlMap yaml) {
    return AdvancedConfig(
      cacheBaseSnapshots: yaml['cache_base_snapshots'] as bool? ?? true,
      parallelGeneration: yaml['parallel_generation'] as bool? ?? true,
      verbose: yaml['verbose'] as bool? ?? false,
      dryRun: yaml['dry_run'] as bool? ?? false,
    );
  }
}
