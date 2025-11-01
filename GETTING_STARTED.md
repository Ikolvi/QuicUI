# QuicUI Getting Started Guide

**Status**: Quick Start Reference
**Date**: November 1, 2025

---

## Quick Start: Setting Up QuicUI Development Environment

### Prerequisites

```bash
# Required tools
- Git
- Dart SDK (v3.0+)
- Flutter SDK (latest stable)
- Python 3.8+
- Docker (for local backend development)
- PostgreSQL 14+

# Optional but recommended
- VS Code or IntelliJ IDEA
- Android Studio (for Android testing)
- Xcode (for iOS testing)
- GCP/AWS Account (for production backend)
```

### Step 1: Repository Structure Setup

```bash
# Navigate to your workspace
cd /Users/admin/Documents/quicui2

# Create main project structure
mkdir -p quicui-platform
cd quicui-platform

# Initialize Git repo
git init
git config user.email "dev@quicui.dev"
git config user.name "QuicUI Dev"

# Create directory structure
mkdir -p {packages,forks,docs,scripts,infrastructure}

# Create subdirectories for packages
mkdir -p packages/{quicui_cli,quicui_compiler,quicui_code_push_client,quicui_backend}

# Create forks directory
mkdir -p forks/{flutter,engine}

# Create infrastructure
mkdir -p infrastructure/{docker,kubernetes,terraform}

# Create documentation
mkdir -p docs/{architecture,guides,api}

# Create scripts
mkdir -p scripts/{ci,deploy,util}

echo "✅ Directory structure created"
```

### Step 2: Setup Monorepo Configuration

Create root `pubspec.yaml`:

```yaml
# /Users/admin/Documents/quicui2/quicui-platform/pubspec.yaml

name: quicui_platform
description: QuicUI - Flutter Code Push Service Platform
version: 0.1.0
environment:
  sdk: ^3.0.0

# This is a monorepo - individual packages are in packages/
# Use `melos` or `pub` workspaces

dev_dependencies:
  # Testing
  test: ^1.25.0
  very_good_analysis: ^6.0.0
  coverage: ^7.0.0
  
  # Dev tools
  build_runner: ^2.4.0
  
  # Linting
  pedantic: ^1.11.1
```

Create `analysis_options.yaml`:

```yaml
# /Users/admin/Documents/quicui2/quicui-platform/analysis_options.yaml

include: package:very_good_analysis/analysis_options.6.0.0
```

### Step 3: Clone and Analyze Shorebird

```bash
# Clone both repositories for reference
cd forks

# Clone Flutter fork
git clone --depth 1 --branch shorebird/dev \
  https://github.com/shorebirdtech/flutter.git

# Clone main Shorebird repo for reference
cd ..
git clone --depth 1 \
  https://github.com/shorebirdtech/shorebird.git \
  shorebird-reference

# Analyze differences
cd forks/flutter
git remote add upstream https://github.com/flutter/flutter.git
git fetch upstream main --depth=1

# Find key changes
git diff upstream/main --stat | head -20

echo "✅ Repositories cloned for analysis"
```

### Step 4: Create First Package - Code Push Client

```bash
cd packages

# Create quicui_code_push_client package
mkdir -p quicui_code_push_client
cd quicui_code_push_client

cat > pubspec.yaml << 'EOF'
name: quicui_code_push_client
description: Client library for QuicUI code push functionality
version: 0.1.0

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  crypto: ^3.0.0
  path_provider: ^2.1.0
  shared_preferences: ^2.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  test: ^1.25.0
  mockito: ^5.4.0
  build_runner: ^2.4.0

flutter:
  # No native code yet
EOF

# Create basic structure
mkdir -p {lib,test,lib/src/{models,services,utils}}

# Create main entry point
cat > lib/quicui_code_push_client.dart << 'EOF'
library quicui_code_push_client;

export 'src/code_push.dart';
export 'src/models/patch_info.dart';
export 'src/models/code_push_config.dart';
EOF

cat > lib/src/code_push.dart << 'EOF'
import 'package:http/http.dart' as http;
import 'models/patch_info.dart';
import 'models/code_push_config.dart';

/// Main class for QuicUI Code Push functionality
class QuicUICodePush {
  static QuicUICodePush? _instance;
  static late QuicUICodePushConfig _config;
  
  /// Get singleton instance
  static QuicUICodePush get instance {
    _instance ??= QuicUICodePush._();
    return _instance;
  }
  
  QuicUICodePush._();
  
  /// Initialize code push with configuration
  static Future<void> initialize({
    required QuicUICodePushConfig config,
  }) async {
    _config = config;
    // TODO: Initialize code push
  }
  
  /// Check for available patches
  Future<PatchInfo?> checkForUpdates() async {
    // TODO: Implement patch checking
    return null;
  }
  
  /// Download and apply patch
  Future<void> downloadAndApply(PatchInfo patch) async {
    // TODO: Implement patch downloading and application
  }
  
  /// Get current patch version
  String getCurrentPatchVersion() {
    // TODO: Implement
    return '';
  }
  
  /// Rollback to previous version
  Future<void> rollback() async {
    // TODO: Implement rollback
  }
}
EOF

cat > lib/src/models/code_push_config.dart << 'EOF'
/// Configuration for QuicUI Code Push
class QuicUICodePushConfig {
  final String appId;
  final String backendUrl;
  final String? publicKeyPath;
  final Duration checkInterval;
  final bool enableAutoUpdate;
  final int maxPatchSizeBytes;
  
  const QuicUICodePushConfig({
    required this.appId,
    required this.backendUrl,
    this.publicKeyPath,
    this.checkInterval = const Duration(hours: 1),
    this.enableAutoUpdate = true,
    this.maxPatchSizeBytes = 52428800, // 50MB default
  });
}
EOF

cat > lib/src/models/patch_info.dart << 'EOF'
/// Information about available patch
class PatchInfo {
  final String patchId;
  final String fromVersion;
  final String toVersion;
  final int sizeBytes;
  final String downloadUrl;
  final String signature;
  final bool requiresRestart;
  
  PatchInfo({
    required this.patchId,
    required this.fromVersion,
    required this.toVersion,
    required this.sizeBytes,
    required this.downloadUrl,
    required this.signature,
    this.requiresRestart = true,
  });
  
  factory PatchInfo.fromJson(Map<String, dynamic> json) {
    return PatchInfo(
      patchId: json['patch_id'] as String,
      fromVersion: json['from_version'] as String,
      toVersion: json['to_version'] as String,
      sizeBytes: json['size_bytes'] as int,
      downloadUrl: json['download_url'] as String,
      signature: json['signature'] as String,
      requiresRestart: json['requires_restart'] as bool? ?? true,
    );
  }
}
EOF

# Create test file
mkdir -p test
cat > test/quicui_code_push_client_test.dart << 'EOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:quicui_code_push_client/quicui_code_push_client.dart';

void main() {
  group('QuicUICodePush', () {
    test('singleton instance works', () {
      final instance1 = QuicUICodePush.instance;
      final instance2 = QuicUICodePush.instance;
      expect(identical(instance1, instance2), true);
    });
  });
}
EOF

echo "✅ quicui_code_push_client package created"
```

### Step 5: Create CLI Package Skeleton

```bash
cd packages

# Create CLI package
mkdir -p quicui_cli
cd quicui_cli

cat > pubspec.yaml << 'EOF'
name: quicui_cli
description: Command-line interface for QuicUI code push service
version: 0.1.0

environment:
  sdk: ^3.0.0

dependencies:
  args: ^2.4.0
  http: ^1.1.0
  path: ^1.8.0
  yaml: ^3.1.0
  crypto: ^3.0.0
  
dev_dependencies:
  test: ^1.25.0
  test_process: ^2.1.0

executables:
  quicui: quicui
EOF

# Create basic structure
mkdir -p {lib,bin,lib/src/{commands,services,models,utils}}

cat > bin/quicui.dart << 'EOF'
import 'package:args/args.dart';
import 'package:quicui_cli/src/commands/root_command.dart';

void main(List<String> arguments) async {
  final command = RootCommand();
  exitCode = await command.run(arguments);
}
EOF

cat > lib/src/commands/root_command.dart << 'EOF'
import 'package:args/command_runner.dart';
import 'auth_command.dart';
import 'build_command.dart';

class RootCommand extends CommandRunner<int> {
  RootCommand() : super('quicui', 'QuicUI Code Push CLI') {
    addCommand(AuthCommand());
    addCommand(BuildCommand());
  }
  
  @override
  Future<int> run(Iterable<String> args) async {
    try {
      return await super.run(args) ?? 0;
    } catch (error) {
      print('Error: $error');
      return 1;
    }
  }
}
EOF

cat > lib/src/commands/auth_command.dart << 'EOF'
import 'package:args/command_runner.dart';

class AuthCommand extends Command<int> {
  @override
  String get name => 'auth';
  
  @override
  String get description => 'Manage authentication';
  
  AuthCommand() {
    addSubcommand(LoginCommand());
    addSubcommand(LogoutCommand());
  }
  
  @override
  Future<int?> run() => null;
}

class LoginCommand extends Command<int> {
  @override
  String get name => 'login';
  
  @override
  String get description => 'Login to QuicUI service';
  
  @override
  Future<int> run() async {
    print('TODO: Implement login');
    return 0;
  }
}

class LogoutCommand extends Command<int> {
  @override
  String get name => 'logout';
  
  @override
  String get description => 'Logout from QuicUI service';
  
  @override
  Future<int> run() async {
    print('TODO: Implement logout');
    return 0;
  }
}
EOF

cat > lib/src/commands/build_command.dart << 'EOF'
import 'package:args/command_runner.dart';

class BuildCommand extends Command<int> {
  @override
  String get name => 'build';
  
  @override
  String get description => 'Build patches';
  
  @override
  Future<int> run() async {
    print('TODO: Implement build');
    return 0;
  }
}
EOF

echo "✅ quicui_cli package created"
```

### Step 6: Create Compiler Package Skeleton

```bash
cd packages

mkdir -p quicui_compiler
cd quicui_compiler

cat > pubspec.yaml << 'EOF'
name: quicui_compiler
description: Code compiler and differ for QuicUI patches
version: 0.1.0

environment:
  sdk: ^3.0.0

dependencies:
  analyzer: ^6.0.0
  path: ^1.8.0
  crypto: ^3.0.0
  
dev_dependencies:
  test: ^1.25.0
EOF

# Create structure
mkdir -p {lib,test,lib/src/{analyzer,compiler,signer}}

cat > lib/quicui_compiler.dart << 'EOF'
library quicui_compiler;

export 'src/compiler/patch_compiler.dart';
export 'src/analyzer/kernel_analyzer.dart';
export 'src/signer/code_signer.dart';
EOF

cat > lib/src/compiler/patch_compiler.dart << 'EOF'
/// Compiles Dart code changes into patches
class PatchCompiler {
  Future<PatchBundle> compilePatch({
    required String fromVersion,
    required String toVersion,
    required String sourceDir,
  }) async {
    // TODO: Implement patch compilation
    throw UnimplementedError();
  }
}

class PatchBundle {
  final String metadata;
  final List<int> patchData;
  final String signature;
}
EOF

echo "✅ quicui_compiler package created"
```

### Step 7: Test Installation

```bash
# Go back to root
cd /Users/admin/Documents/quicui2/quicui-platform

# Try running pub get on each package
cd packages/quicui_code_push_client
flutter pub get

cd ../quicui_cli
dart pub get

cd ../quicui_compiler
dart pub get

echo "✅ All packages ready"
```

### Step 8: Create Initial CI/CD

Create `.github/workflows/test.yaml`:

```yaml
name: Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: dart-lang/setup-dart@v1
        with:
          sdk: 3.0.0
      
      - name: Get dependencies
        run: |
          cd packages/quicui_code_push_client && dart pub get
          cd ../quicui_cli && dart pub get
          cd ../quicui_compiler && dart pub get
      
      - name: Run tests
        run: |
          cd packages/quicui_code_push_client && dart test
          cd ../quicui_cli && dart test
          cd ../quicui_compiler && dart test
```

### Step 9: Create Development Roadmap

Create `ROADMAP.md`:

```markdown
# QuicUI Development Roadmap

## Week 1-2: Foundation
- [ ] Setup monorepo structure
- [ ] Create package scaffolding
- [ ] Analyze Shorebird architecture
- [ ] Document API specifications

## Week 3-4: Runtime & Compilation
- [ ] Fork Flutter SDK
- [ ] Add basic patch loader hook
- [ ] Implement kernel analyzer
- [ ] Implement basic compiler

## Week 5-6: CLI & Backend
- [ ] Implement CLI commands
- [ ] Create backend API server
- [ ] Setup database models
- [ ] Implement authentication

## Week 7-8: Integration
- [ ] End-to-end testing
- [ ] Sample app implementation
- [ ] Documentation

## Week 9-10: Production Ready
- [ ] Performance optimization
- [ ] Security hardening
- [ ] Monitoring & analytics

## Week 11-12: Release
- [ ] Public beta testing
- [ ] Documentation completion
- [ ] Release v0.1.0
```

### Step 10: Create README

Create `README.md`:

```markdown
# QuicUI - Flutter Code Push Service

Open-source alternative to Shorebird for over-the-air Flutter app updates.

## Quick Start

```bash
# Install
dart pub global activate quicui_cli

# Initialize project
cd your_flutter_app
quicui init

# Build and push patch
quicui build
quicui patch create
quicui release push
```

## Documentation

- [Architecture](docs/architecture/)
- [API Reference](docs/api/)
- [Contributing](CONTRIBUTING.md)
- [Implementation Plan](QUICUI_IMPLEMENTATION_PLAN.md)

## Status

**Phase**: Planning & Setup
**Current Version**: 0.1.0-dev

## License

Dual licensed under Apache 2.0 and MIT
```

---

## Phase 1 Checklist

### Week 1 Tasks

- [ ] Directory structure created
- [ ] Git repository initialized
- [ ] `quicui_code_push_client` package created with basic structure
- [ ] `quicui_cli` package created with command skeleton
- [ ] `quicui_compiler` package created
- [ ] All packages can run `pub get` successfully
- [ ] GitHub Actions CI/CD configured
- [ ] Analysis documents completed
- [ ] README and ROADMAP created
- [ ] Team has access to repository

### Before Week 2

- [ ] All team members cloned repository
- [ ] Everyone can run tests locally
- [ ] Development environment validated
- [ ] Shorebird analysis completed
- [ ] Architecture finalized

---

## Running Tests

```bash
# Test individual packages
cd packages/quicui_code_push_client
dart test

# Or all packages
for dir in packages/*/; do
  cd "$dir"
  dart test
  cd -
done

# With coverage
dart pub global activate coverage
dart test --coverage=coverage
dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json
```

---

## Next Steps After Setup

1. **Week 2**: Deep dive into Shorebird source code
2. **Week 3**: Begin Flutter SDK fork modifications
3. **Week 4**: Complete kernel analyzer and compiler
4. **Week 5**: Finish backend API basic endpoints
5. **Week 6+**: Integration and testing

---

