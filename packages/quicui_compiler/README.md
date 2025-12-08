# QuicUI Compiler

A Dart patch compiler for analyzing and building code patches for the QuicUI code push system.

## Overview

`quicui_compiler` is a core component of the QuicUI code push ecosystem. It analyzes Dart source code to detect changes between versions and generates optimized patch artifacts.

## Features

- **Source Code Analysis**: Uses the Dart analyzer to parse and understand code structure
- **Change Detection**: Identifies modified classes, functions, and methods
- **Patch Generation**: Creates minimal, optimized patches containing only changed code
- **Symbol Resolution**: Tracks symbol dependencies across files

## Installation

```yaml
dependencies:
  quicui_compiler: ^1.0.0
```

## Usage

This package is primarily used internally by the QuicUI CLI. For most use cases, use the CLI instead:

```bash
dart pub global activate quicui_cli
quicui patch
```

### Programmatic Usage

```dart
import 'package:quicui_compiler/quicui_compiler.dart';

// Analyze source files
final compiler = QuicuiCompiler();
final result = await compiler.compile(
  sourceDir: 'lib/',
  outputDir: 'build/patches/',
);
```

## Architecture

The compiler works in several phases:

1. **Parse Phase**: Reads and parses all Dart source files
2. **Analysis Phase**: Builds symbol tables and dependency graphs
3. **Diff Phase**: Compares against baseline to detect changes
4. **Generation Phase**: Outputs patch artifacts

## Related Packages

- [quicui_cli](https://pub.dev/packages/quicui_cli) - Command-line interface
- [quicui_linker](https://pub.dev/packages/quicui_linker) - Links compiled patches
- [quicui_code_push_client](https://pub.dev/packages/quicui_code_push_client) - Flutter client SDK

## Contributing

Contributions are welcome! Please see our [Contributing Guide](https://github.com/Ikolvi/QuicUI/blob/main/CONTRIBUTING.md).

## License

MIT License - see [LICENSE](LICENSE) for details.
