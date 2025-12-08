export 'android.dart';
export 'apple.dart';
export 'linux.dart';
export 'windows.dart';

/// {@template arch}
/// Build architectures supported by Quicui.
///
/// Note: in addition to these values, the Flutter tooling also supports x86.
/// {@endtemplate}
enum Arch {
  /// 32-bit ARM architecture.
  arm32(arch: 'arm'),

  /// 64-bit ARM architecture.
  arm64(arch: 'aarch64'),

  /// 64-bit x86 architecture.
  x86_64(arch: 'x86_64');

  /// {@macro arch}
  const Arch({required this.arch});

  /// The name used by Quicui to identify this architecture.
  final String arch;
}
