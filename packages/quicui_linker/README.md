# QuicUI Linker

A differential AOT linker for QuicUI code push patches.

## Overview

`quicui_linker` is a core component of the QuicUI code push ecosystem. It links compiled patch artifacts with the runtime environment, resolving symbols and generating the final executable patch format.

## Features

- **Differential Linking**: Links only changed code, minimizing patch size
- **Symbol Resolution**: Resolves references between patched and original code
- **AOT Integration**: Works with Dart's ahead-of-time compilation
- **Platform Support**: Generates patches for iOS and Android

## Installation

```yaml
dependencies:
  quicui_linker: ^1.0.0
```

## Usage

This package is primarily used internally by the QuicUI CLI. For most use cases, use the CLI instead:

```bash
dart pub global activate quicui_cli
quicui patch
```

### Programmatic Usage

```dart
import 'package:quicui_linker/quicui_linker.dart';

// Link compiled patches
final linker = QuicuiLinker();
final result = await linker.link(
  patchArtifacts: 'build/patches/',
  outputFile: 'output/patch.quicui',
);
```

## Architecture

The linker operates in several stages:

1. **Load Phase**: Loads compiled patch artifacts
2. **Resolution Phase**: Resolves symbol references
3. **Relocation Phase**: Adjusts addresses for target platform
4. **Output Phase**: Generates final patch binary

## Related Packages

- [quicui_cli](https://pub.dev/packages/quicui_cli) - Command-line interface
- [quicui_compiler](https://pub.dev/packages/quicui_compiler) - Compiles patches
- [quicui_code_push_client](https://pub.dev/packages/quicui_code_push_client) - Flutter client SDK

## Contributing

Contributions are welcome! Please see our [Contributing Guide](https://github.com/Ikolvi/QuicUI/blob/main/CONTRIBUTING.md).

## License

MIT License - see [LICENSE](LICENSE) for details.
