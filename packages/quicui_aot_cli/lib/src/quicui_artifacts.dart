// Allowing one member abstracts for consistency/namespace/ease of testing.
// ignore_for_file: one_member_abstracts

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/cache.dart';
import 'package:quicui_aot_cli/src/engine_config.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';

/// All Quicui artifacts used explicitly by Quicui.
enum QuicuiArtifact {
  /// The iOS analyze_snapshot executable.
  analyzeSnapshotIos,

  /// The macOS analyze_snapshot executable.
  analyzeSnapshotMacOS,

  /// The aot_tools executable or kernel file.
  aotTools,

  /// The gen_snapshot executable for iOS.
  genSnapshotIos,

  /// The gen_snapshot executable for macOS that creates arm64 snapshots.
  genSnapshotMacosArm64,

  /// The gen_snapshot executable for macOS that creates x64 snapshots.
  genSnapshotMacosX64,
}

/// A reference to a [QuicuiArtifacts] instance.
final quicuiArtifactsRef = create<QuicuiArtifacts>(
  QuicuiCachedArtifacts.new,
);

/// The [QuicuiArtifacts] instance available in the current zone.
QuicuiArtifacts get quicuiArtifacts => read(quicuiArtifactsRef);

/// {@template quicui_artifacts}
/// A class that provides access to Quicui artifacts.
/// {@endtemplate}
abstract class QuicuiArtifacts {
  /// Returns the path to the given [artifact].
  String getArtifactPath({required QuicuiArtifact artifact});
}

/// {@template quicui_cached_artifacts}
/// A class that provides access to cached Quicui artifacts.
/// {@endtemplate}
class QuicuiCachedArtifacts implements QuicuiArtifacts {
  /// {@macro quicui_cached_artifacts}
  const QuicuiCachedArtifacts();

  @override
  String getArtifactPath({required QuicuiArtifact artifact}) {
    switch (artifact) {
      case QuicuiArtifact.analyzeSnapshotIos:
        return _analyzeSnapshotIosFile.path;
      case QuicuiArtifact.analyzeSnapshotMacOS:
        return _analyzeSnapshotMacosFile.path;
      case QuicuiArtifact.aotTools:
        return _aotToolsFile.path;
      case QuicuiArtifact.genSnapshotIos:
        return _genSnapshotIosFile.path;
      case QuicuiArtifact.genSnapshotMacosArm64:
        return _genSnapshotMacOsArm64File.path;
      case QuicuiArtifact.genSnapshotMacosX64:
        return _genSnapshotMacOsX64File.path;
    }
  }

  File get _analyzeSnapshotIosFile {
    return File(
      p.join(
        quicuiEnv.flutterDirectory.path,
        'bin',
        'cache',
        'artifacts',
        'engine',
        'ios-release',
        'analyze_snapshot_arm64',
      ),
    );
  }

  File get _analyzeSnapshotMacosFile {
    return File(
      p.join(
        quicuiEnv.flutterDirectory.path,
        'bin',
        'cache',
        'artifacts',
        'engine',
        'darwin-x64-release',
        'analyze_snapshot',
      ),
    );
  }

  File get _aotToolsFile {
    const executableName = 'aot-tools';
    final kernelFile = File(
      p.join(
        cache.getArtifactDirectory(executableName).path,
        quicuiEnv.quicuiEngineRevision,
        '$executableName.dill',
      ),
    );
    if (kernelFile.existsSync()) {
      return kernelFile;
    }

    // We shipped aot-tools as an executable in the past, so we return that if
    // no kernel file is found.
    return File(
      p.join(
        cache.getArtifactDirectory(executableName).path,
        quicuiEnv.quicuiEngineRevision,
        executableName,
      ),
    );
  }

  File get _genSnapshotIosFile {
    return File(
      p.join(
        quicuiEnv.flutterDirectory.path,
        'bin',
        'cache',
        'artifacts',
        'engine',
        'ios-release',
        'gen_snapshot_arm64',
      ),
    );
  }

  File get _genSnapshotMacOsArm64File {
    return File(
      p.join(
        quicuiEnv.flutterDirectory.path,
        'bin',
        'cache',
        'artifacts',
        'engine',
        'darwin-x64-release',
        'gen_snapshot_arm64',
      ),
    );
  }

  File get _genSnapshotMacOsX64File {
    return File(
      p.join(
        quicuiEnv.flutterDirectory.path,
        'bin',
        'cache',
        'artifacts',
        'engine',
        'darwin-x64-release',
        'gen_snapshot_x64',
      ),
    );
  }
}

/// {@template quicui_local_engine_artifacts}
/// A class that provides access to locally built Quicui artifacts.
/// {@endtemplate}
class QuicuiLocalEngineArtifacts implements QuicuiArtifacts {
  /// {@macro quicui_local_engine_artifacts}
  const QuicuiLocalEngineArtifacts();

  @override
  String getArtifactPath({required QuicuiArtifact artifact}) {
    switch (artifact) {
      case QuicuiArtifact.analyzeSnapshotIos:
        return _analyzeSnapshotIosFile.path;
      case QuicuiArtifact.analyzeSnapshotMacOS:
        return _analyzeSnapshotMacosFile.path;
      case QuicuiArtifact.aotTools:
        return _aotToolsFile.path;
      case QuicuiArtifact.genSnapshotIos:
        return _genSnapshotIosFile.path;
      case QuicuiArtifact.genSnapshotMacosArm64:
        return _genSnapshotMacosArm64File.path;
      case QuicuiArtifact.genSnapshotMacosX64:
        return _genSnapshotMacosX64File.path;
    }
  }

  File get _analyzeSnapshotIosFile {
    return File(
      p.join(
        engineConfig.localEngineSrcPath!,
        'out',
        engineConfig.localEngine,
        'clang_x64',
        'analyze_snapshot_arm64',
      ),
    );
  }

  File get _analyzeSnapshotMacosFile {
    return File(
      p.join(
        engineConfig.localEngineSrcPath!,
        'out',
        engineConfig.localEngine,
        'clang_x64',
        'analyze_snapshot',
      ),
    );
  }

  File get _aotToolsFile {
    return File(
      p.join(
        engineConfig.localEngineSrcPath!,
        'flutter',
        'third_party',
        'dart',
        'pkg',
        'aot_tools',
        'bin',
        'aot_tools.dart',
      ),
    );
  }

  File get _genSnapshotIosFile {
    return File(
      p.join(
        engineConfig.localEngineSrcPath!,
        'out',
        engineConfig.localEngine,
        'clang_x64',
        'gen_snapshot_arm64',
      ),
    );
  }

  File get _genSnapshotMacosArm64File {
    return File(
      p.join(
        engineConfig.localEngineSrcPath!,
        'out',
        engineConfig.localEngine,
        'artifacts_arm64',
        'gen_snapshot',
      ),
    );
  }

  File get _genSnapshotMacosX64File {
    return File(
      p.join(
        engineConfig.localEngineSrcPath!,
        'out',
        engineConfig.localEngine,
        'artifacts_x64',
        'gen_snapshot',
      ),
    );
  }
}
