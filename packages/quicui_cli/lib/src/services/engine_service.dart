import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

/// Service for managing QuicUI Flutter SDK (with embedded engine)
class EngineService {
  static const String _sdkVersion = 'v1.0.0-quicui';
  static const String _engineVersion = 'v1.0.1';
  static const String _githubRepo = 'https://github.com/Ikolvi/QuicUIEngine.git';
  static const String _githubReleaseUrl = 'https://github.com/Ikolvi/QuicUIEngine/releases/download/$_engineVersion';

  /// Get the QuicUI Flutter SDK cache directory
  static String get sdkCacheDir {
    final homeDir = Platform.environment['HOME'] ?? '/tmp';
    return p.join(homeDir, '.quicui', 'flutter');
  }

  /// Get the QuicUI-specific Maven repository path (isolated from system ~/.m2)
  static String get quicuiMavenDir {
    final homeDir = Platform.environment['HOME'] ?? '/tmp';
    return p.join(homeDir, '.quicui', 'maven');
  }

  /// Get the flutter executable path
  static String get flutterPath {
    return p.join(sdkCacheDir, 'bin', 'flutter');
  }

  /// Check if SDK is already cloned and on correct version
  static Future<bool> isSdkCached() async {
    final sdkDir = Directory(sdkCacheDir);
    if (!await sdkDir.exists()) return false;

    final flutterBin = File(flutterPath);
    if (!await flutterBin.exists()) return false;

    // Check if we're on the correct tag
    final result = await Process.run(
      'git',
      ['describe', '--tags', '--exact-match'],
      workingDirectory: sdkCacheDir,
    );
    
    return result.exitCode == 0 && result.stdout.toString().trim() == _sdkVersion;
  }

  /// Clone or update QuicUI Flutter SDK from GitHub
  static Future<void> downloadSdk({bool force = false}) async {
    if (!force && await isSdkCached()) {
      print('✅ QuicUI Flutter SDK already installed at: $sdkCacheDir');
      return;
    }

    final sdkDir = Directory(sdkCacheDir);
    
    if (await sdkDir.exists()) {
      if (force) {
        print('🧹 Removing existing SDK...');
        await sdkDir.delete(recursive: true);
      } else {
        // Try to checkout correct version
        print('📥 Switching to QuicUI version $_sdkVersion...');
        final result = await Process.run(
          'git',
          ['checkout', _sdkVersion],
          workingDirectory: sdkCacheDir,
        );
        
        if (result.exitCode == 0) {
          print('✅ Switched to $_sdkVersion');
          await _runFlutterDoctor();
          return;
        } else {
          print('⚠️  Failed to checkout $_sdkVersion, re-cloning...');
          await sdkDir.delete(recursive: true);
        }
      }
    }

    print('📥 Cloning QuicUI Flutter SDK (this may take a few minutes)...');
    print('   Repository: $_githubRepo');
    print('   Version: $_sdkVersion');

    // Create parent directory
    final parentDir = Directory(p.dirname(sdkCacheDir));
    await parentDir.create(recursive: true);

    // Clone with depth 1 for faster download
    final cloneResult = await Process.run(
      'git',
      [
        'clone',
        '--depth', '1',
        '--branch', _sdkVersion,
        _githubRepo,
        sdkCacheDir,
      ],
      workingDirectory: parentDir.path,
    );

    if (cloneResult.exitCode != 0) {
      throw Exception('Failed to clone QuicUI SDK: ${cloneResult.stderr}');
    }

    print('✅ QuicUI Flutter SDK cloned to: $sdkCacheDir');
    
    // Download engine JARs and set up QuicUI-specific Maven repository
    await _setupQuicuiMaven();
    
    // Modify Gradle files to use QuicUI Maven
    await _patchGradleFiles();
    
    // Run flutter doctor to initialize
    await _runFlutterDoctor();
  }

  /// Download engine JARs to QuicUI-specific Maven repository
  static Future<void> _setupQuicuiMaven() async {
    print('📥 Downloading QuicUI engine artifacts...');
    
    // Get engine version from the SDK
    final engineVersionFile = File(p.join(sdkCacheDir, 'bin', 'internal', 'engine.version'));
    if (!await engineVersionFile.exists()) {
      print('⚠️  Could not find engine.version, skipping Maven setup');
      return;
    }
    
    final engineHash = (await engineVersionFile.readAsString()).trim();
    print('   Engine version: $engineHash');
    
    // Create Maven directory structure
    final artifacts = [
      'arm64_v8a_release',
      'armeabi_v7a_release',
      'x86_64_release',
      'flutter_embedding_release',
    ];
    
    for (final artifact in artifacts) {
      final artifactDir = p.join(
        quicuiMavenDir, 
        'io', 'flutter', artifact, 
        '1.0.0-$engineHash'
      );
      await Directory(artifactDir).create(recursive: true);
      
      // Download JAR from GitHub Releases
      final jarFileName = '$artifact.jar';
      
      final jarPath = p.join(artifactDir, '$artifact-1.0.0-$engineHash.jar');
      
      if (await File(jarPath).exists()) {
        print('   ✅ $artifact already cached');
        continue;
      }
      
      print('   Downloading $jarFileName...');
      final url = '$_githubReleaseUrl/$jarFileName';
      
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await File(jarPath).writeAsBytes(response.bodyBytes);
          print('   ✅ $artifact (${(response.bodyBytes.length / 1024 / 1024).toStringAsFixed(1)} MB)');
          
          // Create POM file
          await _createPomFile(artifactDir, artifact, engineHash);
        } else if (response.statusCode == 302) {
          // Follow redirect
          final redirectUrl = response.headers['location'];
          if (redirectUrl != null) {
            final redirectResponse = await http.get(Uri.parse(redirectUrl));
            if (redirectResponse.statusCode == 200) {
              await File(jarPath).writeAsBytes(redirectResponse.bodyBytes);
              print('   ✅ $artifact (${(redirectResponse.bodyBytes.length / 1024 / 1024).toStringAsFixed(1)} MB)');
              await _createPomFile(artifactDir, artifact, engineHash);
            }
          }
        } else {
          print('   ⚠️  Failed to download $artifact: ${response.statusCode}');
        }
      } catch (e) {
        print('   ⚠️  Failed to download $artifact: $e');
      }
    }
    
    print('✅ QuicUI Maven repository ready at: $quicuiMavenDir');
  }

  /// Create POM file for Maven artifact
  static Future<void> _createPomFile(String artifactDir, String artifact, String engineHash) async {
    final pomContent = '''<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <groupId>io.flutter</groupId>
  <artifactId>$artifact</artifactId>
  <version>1.0.0-$engineHash</version>
  <packaging>jar</packaging>
</project>
''';
    await File(p.join(artifactDir, '$artifact-1.0.0-$engineHash.pom')).writeAsString(pomContent);
  }

  /// Patch Gradle files to use QuicUI-specific Maven repository
  static Future<void> _patchGradleFiles() async {
    print('🔧 Configuring Gradle to use QuicUI engine...');
    await patchSdkGradleFiles(sdkCacheDir);
  }

  /// Patch Gradle files in any Flutter SDK to use QuicUI Maven repository
  static Future<void> patchSdkGradleFiles(String sdkPath) async {
    // Patch resolve_dependencies.gradle.kts
    final gradleFile = File(p.join(
      sdkPath, 
      'packages', 'flutter_tools', 'gradle', 
      'resolve_dependencies.gradle.kts'
    ));
    
    if (await gradleFile.exists()) {
      var content = await gradleFile.readAsString();
      
      // Add QuicUI Maven repository BEFORE other repositories
      if (!content.contains('quicuiMaven')) {
        content = content.replaceFirst(
          'repositories {',
          '''repositories {
    // QuicUI engine artifacts (isolated from system Maven)
    val quicuiMaven = file(System.getProperty("user.home") + "/.quicui/maven")
    if (quicuiMaven.exists()) {
        maven {
            url = quicuiMaven.toURI()
            name = "quicuiLocal"
        }
    }'''
        );
        await gradleFile.writeAsString(content);
        print('   ✅ Patched resolve_dependencies.gradle.kts');
      }
    }
    
    // Patch aar_init_script.gradle
    final aarFile = File(p.join(
      sdkPath,
      'packages', 'flutter_tools', 'gradle',
      'aar_init_script.gradle'
    ));
    
    if (await aarFile.exists()) {
      var content = await aarFile.readAsString();
      
      if (!content.contains('quicuiMaven')) {
        content = content.replaceFirst(
          'project.repositories {',
          '''project.repositories {
        // QuicUI engine artifacts (isolated from system Maven)
        def quicuiMaven = new File(System.getProperty("user.home") + "/.quicui/maven")
        if (quicuiMaven.exists()) {
            maven {
                url = quicuiMaven.toURI()
                name = "quicuiLocal"
            }
        }'''
        );
        await aarFile.writeAsString(content);
        print('   ✅ Patched aar_init_script.gradle');
      }
    }
    
    // Patch flutter.gradle (main Gradle plugin)
    final flutterGradleFile = File(p.join(
      sdkPath,
      'packages', 'flutter_tools', 'gradle',
      'flutter.gradle'
    ));
    
    if (await flutterGradleFile.exists()) {
      var content = await flutterGradleFile.readAsString();
      
      if (!content.contains('quicuiMaven')) {
        // Find repositories block in buildscript or allprojects
        content = content.replaceFirst(
          RegExp(r'repositories\s*\{'),
          '''repositories {
        // QuicUI engine artifacts
        def quicuiMaven = new File(System.getProperty("user.home") + "/.quicui/maven")
        if (quicuiMaven.exists()) {
            maven {
                url = quicuiMaven.toURI()
                name = "quicuiLocal"
            }
        }'''
        );
        await flutterGradleFile.writeAsString(content);
        print('   ✅ Patched flutter.gradle');
      }
    }
  }

  /// Patch app's android/build.gradle to include QuicUI Maven repository
  static Future<void> patchAppGradleFiles(String projectPath) async {
    print('🔧 Patching app Gradle files for QuicUI...');
    
    // Patch android/build.gradle or android/build.gradle.kts
    final buildGradleKts = File(p.join(projectPath, 'android', 'build.gradle.kts'));
    final buildGradle = File(p.join(projectPath, 'android', 'build.gradle'));
    
    if (await buildGradleKts.exists()) {
      var content = await buildGradleKts.readAsString();
      
      if (!content.contains('quicuiMaven')) {
        // Find allprojects { repositories { and add QuicUI Maven
        if (content.contains('allprojects {')) {
          content = content.replaceFirst(
            RegExp(r'allprojects\s*\{\s*repositories\s*\{'),
            '''allprojects {
    repositories {
        // QuicUI engine artifacts
        val quicuiMaven = file(System.getProperty("user.home") + "/.quicui/maven")
        if (quicuiMaven.exists()) {
            maven {
                url = quicuiMaven.toURI()
                name = "quicuiLocal"
            }
        }'''
          );
        }
        await buildGradleKts.writeAsString(content);
        print('   ✅ Patched android/build.gradle.kts');
      }
    } else if (await buildGradle.exists()) {
      var content = await buildGradle.readAsString();
      
      if (!content.contains('quicuiMaven')) {
        if (content.contains('allprojects {')) {
          content = content.replaceFirst(
            RegExp(r'allprojects\s*\{\s*repositories\s*\{'),
            '''allprojects {
    repositories {
        // QuicUI engine artifacts
        def quicuiMaven = new File(System.getProperty("user.home") + "/.quicui/maven")
        if (quicuiMaven.exists()) {
            maven {
                url = quicuiMaven.toURI()
                name = "quicuiLocal"
            }
        }'''
          );
        }
        await buildGradle.writeAsString(content);
        print('   ✅ Patched android/build.gradle');
      }
    }
    
    // Also patch settings.gradle.kts or settings.gradle
    final settingsGradleKts = File(p.join(projectPath, 'android', 'settings.gradle.kts'));
    final settingsGradle = File(p.join(projectPath, 'android', 'settings.gradle'));
    
    if (await settingsGradleKts.exists()) {
      var content = await settingsGradleKts.readAsString();
      
      if (!content.contains('quicuiMaven')) {
        // Add to pluginManagement repositories
        if (content.contains('pluginManagement {')) {
          content = content.replaceFirst(
            RegExp(r'pluginManagement\s*\{\s*repositories\s*\{'),
            '''pluginManagement {
    repositories {
        // QuicUI engine artifacts
        val quicuiMaven = file(System.getProperty("user.home") + "/.quicui/maven")
        if (quicuiMaven.exists()) {
            maven {
                url = quicuiMaven.toURI()
                name = "quicuiLocal"
            }
        }'''
          );
        }
        await settingsGradleKts.writeAsString(content);
        print('   ✅ Patched android/settings.gradle.kts');
      }
    }
  }

  /// Run flutter doctor to initialize the SDK
  static Future<void> _runFlutterDoctor() async {
    print('🔧 Initializing Flutter SDK...');
    
    final result = await Process.run(
      flutterPath,
      ['doctor', '-v'],
      environment: {
        ...Platform.environment,
        'PUB_CACHE': p.join(sdkCacheDir, '.pub-cache'),
      },
    );

    if (result.exitCode != 0) {
      print('⚠️  Flutter doctor returned warnings (this is usually OK)');
    }
    
    print('✅ Flutter SDK initialized');
  }

  /// Check if we should use local project SDK, cached SDK, or need to download
  static Future<String?> getFlutterPath({String? projectPath}) async {
    // Priority 1: Check for cached QuicUI SDK (has matching engine artifacts)
    if (await isSdkCached()) {
      return flutterPath;
    }

    // Priority 2: Check for custom SDK in forks/flutter-quicui (relative to project)
    // Only use this if cached SDK is not available
    if (projectPath != null) {
      final customSdkPath = p.join(projectPath, '..', '..', 'forks', 'flutter-quicui');
      final customFlutterPath = p.absolute(p.join(customSdkPath, 'bin', 'flutter'));
      if (await File(customFlutterPath).exists()) {
        return customFlutterPath;
      }
    }

    // Priority 3: Return null (need to download)
    return null;
  }

  /// Get local development engine path (for --local-engine builds)
  /// Only used when QUICUI_LOCAL_ENGINE=1 environment variable is set
  static Future<String?> getLocalEnginePath() async {
    // Only use local engine if explicitly requested via environment variable
    final useLocalEngine = Platform.environment['QUICUI_LOCAL_ENGINE'] == '1';
    if (!useLocalEngine) {
      return null;
    }
    
    // Check for local development engine
    const localEnginePath = '/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src';
    if (await Directory(localEnginePath).exists()) {
      return localEnginePath;
    }
    return null;
  }

  /// Ensure SDK is available (download if needed) and patch Gradle files
  static Future<String> ensureSdk({String? projectPath}) async {
    // First check if we already have a usable Flutter
    final existingFlutter = await getFlutterPath(projectPath: projectPath);
    
    if (existingFlutter != null) {
      // Determine SDK root from flutter path (bin/flutter -> root)
      final sdkRoot = p.dirname(p.dirname(existingFlutter));
      
      // Ensure SDK and app Gradle files are patched for QuicUI Maven
      await patchSdkGradleFiles(sdkRoot);
      
      // Also patch the app's Gradle files if project path is provided
      if (projectPath != null) {
        await patchAppGradleFiles(projectPath);
      }
      
      return existingFlutter;
    }

    // Otherwise download from GitHub
    await downloadSdk();
    
    // Patch app Gradle files if project path provided
    if (projectPath != null) {
      await patchAppGradleFiles(projectPath);
    }
    
    return flutterPath;
  }

  /// Get SDK status info
  static Future<Map<String, dynamic>> getStatus({String? projectPath}) async {
    final status = <String, dynamic>{};
    
    // Check local project SDK
    if (projectPath != null) {
      final customSdkPath = p.join(projectPath, '..', '..', 'forks', 'flutter-quicui');
      final customFlutterPath = p.absolute(p.join(customSdkPath, 'bin', 'flutter'));
      status['localProjectSdk'] = await File(customFlutterPath).exists() ? customFlutterPath : null;
    }
    
    // Check cached SDK
    status['cachedSdk'] = await isSdkCached() ? sdkCacheDir : null;
    status['cachedSdkPath'] = sdkCacheDir;
    
    // Check local development engine
    status['localEngine'] = await getLocalEnginePath();
    
    return status;
  }

  // Legacy compatibility - keep old property names
  static String get engineCacheDir => sdkCacheDir;
  
  static Future<bool> isEngineCached() => isSdkCached();
  
  static Future<void> downloadEngine({bool force = false}) => downloadSdk(force: force);
  
  static Future<void> ensureEngine() async {
    await ensureSdk();
  }
}
