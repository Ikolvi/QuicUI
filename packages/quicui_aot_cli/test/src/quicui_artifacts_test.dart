import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:scoped_deps/scoped_deps.dart';
import 'package:quicui_aot_cli/src/cache.dart';
import 'package:quicui_aot_cli/src/engine_config.dart';
import 'package:quicui_aot_cli/src/quicui_artifacts.dart';
import 'package:quicui_aot_cli/src/quicui_env.dart';
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  group(QuicuiCachedArtifacts, () {
    const engineRevision = 'engine-revision';
    late Cache cache;
    late Directory flutterDirectory;
    late Directory artifactDirectory;
    late QuicuiEnv quicuiEnv;
    late QuicuiCachedArtifacts artifacts;

    R runWithOverrides<R>(R Function() body) {
      return runScoped(
        () => body(),
        values: {
          cacheRef.overrideWith(() => cache),
          quicuiEnvRef.overrideWith(() => quicuiEnv),
        },
      );
    }

    setUp(() {
      cache = MockCache();
      final tmpDir = Directory.systemTemp.createTempSync();
      flutterDirectory = Directory(p.join(tmpDir.path, 'flutter'))
        ..createSync(recursive: true);
      artifactDirectory = Directory(p.join(tmpDir.path, 'artifacts'))
        ..createSync(recursive: true);
      quicuiEnv = MockQuicuiEnv();
      artifacts = const QuicuiCachedArtifacts();

      when(
        () => cache.getArtifactDirectory(any()),
      ).thenReturn(artifactDirectory);
      when(() => quicuiEnv.flutterDirectory).thenReturn(flutterDirectory);
      when(
        () => quicuiEnv.quicuiEngineRevision,
      ).thenReturn(engineRevision);
    });

    group('getArtifactPath', () {
      group('aot-tools', () {
        const aotToolsKernel = 'aot-tools.dill';
        const aotToolsExe = 'aot-tools';
        late String aotToolsKernelPath;
        late String aotToolsExePath;

        setUp(() {
          aotToolsKernelPath = p.join(
            artifactDirectory.path,
            engineRevision,
            aotToolsKernel,
          );
          aotToolsExePath = p.join(
            artifactDirectory.path,
            engineRevision,
            aotToolsExe,
          );
        });

        group('when kernel and executable are present', () {
          setUp(() {
            File(aotToolsKernelPath).createSync(recursive: true);
            File(aotToolsExePath).createSync(recursive: true);
          });

          test('returns path to kernel file', () async {
            expect(
              runWithOverrides(
                () => artifacts.getArtifactPath(
                  artifact: QuicuiArtifact.aotTools,
                ),
              ),
              equals(aotToolsKernelPath),
            );
          });
        });

        group('when only executable is present', () {
          setUp(() {
            File(aotToolsExePath).createSync(recursive: true);
          });

          test('returns path to executable file', () {
            expect(
              runWithOverrides(
                () => artifacts.getArtifactPath(
                  artifact: QuicuiArtifact.aotTools,
                ),
              ),
              equals(aotToolsExePath),
            );
          });
        });
      });

      test('returns correct path for iOS gen_snapshot', () {
        expect(
          runWithOverrides(
            () => artifacts.getArtifactPath(
              artifact: QuicuiArtifact.genSnapshotIos,
            ),
          ),
          equals(
            p.join(
              flutterDirectory.path,
              'bin',
              'cache',
              'artifacts',
              'engine',
              'ios-release',
              'gen_snapshot_arm64',
            ),
          ),
        );
      });

      test('returns correct path for macOS arm64 gen_snapshot', () {
        expect(
          runWithOverrides(
            () => artifacts.getArtifactPath(
              artifact: QuicuiArtifact.genSnapshotMacosArm64,
            ),
          ),
          equals(
            p.join(
              flutterDirectory.path,
              'bin',
              'cache',
              'artifacts',
              'engine',
              'darwin-x64-release',
              'gen_snapshot_arm64',
            ),
          ),
        );
      });

      test('returns correct path for macOS x64 gen_snapshot', () {
        expect(
          runWithOverrides(
            () => artifacts.getArtifactPath(
              artifact: QuicuiArtifact.genSnapshotMacosX64,
            ),
          ),
          equals(
            p.join(
              flutterDirectory.path,
              'bin',
              'cache',
              'artifacts',
              'engine',
              'darwin-x64-release',
              'gen_snapshot_x64',
            ),
          ),
        );
      });

      test('returns correct path for analyze_snapshot on iOS', () {
        expect(
          runWithOverrides(
            () => artifacts.getArtifactPath(
              artifact: QuicuiArtifact.analyzeSnapshotIos,
            ),
          ),
          equals(
            p.join(
              flutterDirectory.path,
              'bin',
              'cache',
              'artifacts',
              'engine',
              'ios-release',
              'analyze_snapshot_arm64',
            ),
          ),
        );
      });

      test('returns correct path for analyze_snapshot on macOS', () {
        expect(
          runWithOverrides(
            () => artifacts.getArtifactPath(
              artifact: QuicuiArtifact.analyzeSnapshotMacOS,
            ),
          ),
          equals(
            p.join(
              flutterDirectory.path,
              'bin',
              'cache',
              'artifacts',
              'engine',
              'darwin-x64-release',
              'analyze_snapshot',
            ),
          ),
        );
      });
    });
  });

  group(QuicuiLocalEngineArtifacts, () {
    late String localEngineSrcPath;
    late String localEngine;
    late EngineConfig engineConfig;
    late QuicuiLocalEngineArtifacts artifacts;

    R runWithOverrides<R>(R Function() body) {
      return runScoped(
        () => body(),
        values: {engineConfigRef.overrideWith(() => engineConfig)},
      );
    }

    setUp(() {
      localEngineSrcPath = 'local_engine_src_path';
      localEngine = 'local_engine';
      engineConfig = MockEngineConfig();
      artifacts = const QuicuiLocalEngineArtifacts();

      when(
        () => engineConfig.localEngineSrcPath,
      ).thenReturn(localEngineSrcPath);
      when(() => engineConfig.localEngine).thenReturn(localEngine);
    });

    group('getArtifactPath', () {
      test('returns correct path for aot tools', () {
        expect(
          runWithOverrides(
            () =>
                artifacts.getArtifactPath(artifact: QuicuiArtifact.aotTools),
          ),
          equals(
            p.join(
              localEngineSrcPath,
              'flutter',
              'third_party',
              'dart',
              'pkg',
              'aot_tools',
              'bin',
              'aot_tools.dart',
            ),
          ),
        );
      });

      test('returns correct path for gen_snapshot on iOS', () {
        expect(
          runWithOverrides(
            () => artifacts.getArtifactPath(
              artifact: QuicuiArtifact.genSnapshotIos,
            ),
          ),
          equals(
            p.join(
              localEngineSrcPath,
              'out',
              localEngine,
              'clang_x64',
              'gen_snapshot_arm64',
            ),
          ),
        );
      });

      test('returns correct path for arm64 gen_snapshot on macOS', () {
        expect(
          runWithOverrides(
            () => artifacts.getArtifactPath(
              artifact: QuicuiArtifact.genSnapshotMacosArm64,
            ),
          ),
          equals(
            p.join(
              localEngineSrcPath,
              'out',
              localEngine,
              'artifacts_arm64',
              'gen_snapshot',
            ),
          ),
        );
      });

      test('returns correct path for x64 gen_snapshot on macOS', () {
        expect(
          runWithOverrides(
            () => artifacts.getArtifactPath(
              artifact: QuicuiArtifact.genSnapshotMacosX64,
            ),
          ),
          equals(
            p.join(
              localEngineSrcPath,
              'out',
              localEngine,
              'artifacts_x64',
              'gen_snapshot',
            ),
          ),
        );
      });

      test('returns correct path for analyze_snapshot on iOS', () {
        expect(
          runWithOverrides(
            () => artifacts.getArtifactPath(
              artifact: QuicuiArtifact.analyzeSnapshotIos,
            ),
          ),
          equals(
            p.join(
              localEngineSrcPath,
              'out',
              localEngine,
              'clang_x64',
              'analyze_snapshot_arm64',
            ),
          ),
        );
      });

      test('returns correct path for analyze_snapshot on macOS', () {
        expect(
          runWithOverrides(
            () => artifacts.getArtifactPath(
              artifact: QuicuiArtifact.analyzeSnapshotMacOS,
            ),
          ),
          equals(
            p.join(
              localEngineSrcPath,
              'out',
              localEngine,
              'clang_x64',
              'analyze_snapshot',
            ),
          ),
        );
      });
    });
  });
}
