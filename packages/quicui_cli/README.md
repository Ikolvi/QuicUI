# QuicUI CLI

Command-line interface for QuicUI Code Push - deliver instant updates to your Flutter apps without app store approval.

## Features

- 🚀 **One-command releases** - Build, upload baseline, and register in one step
- 📦 **One-command patches** - Generate and upload patches instantly
- 🔧 **Automatic SDK management** - Downloads QuicUI Flutter SDK automatically
- 🔒 **Isolated from system** - Doesn't affect your system Flutter installation
- ⚡ **Fast iteration** - Hot reload-like updates for production apps

## Installation

### From pub.dev (coming soon)
```bash
dart pub global activate quicui_cli
```

### From source
```bash
git clone https://github.com/Ikolvi/quicui-cli.git
cd quicui-cli
dart pub get
dart pub global activate --source path .
```

## Quick Start

### 1. Initialize QuicUI in your Flutter project
```bash
cd your_flutter_app
quicui init
```

This creates a `quicui.yaml` configuration file with your app settings.

### 2. Download QuicUI SDK (first time only)
```bash
quicui engine download
```

This downloads the QuicUI-enabled Flutter SDK to `~/.quicui/flutter/` (isolated from your system Flutter).

### 3. Create your first release
```bash
quicui release --version 1.0.0
```

This builds your app with QuicUI support and uploads the baseline to the server.

### 4. Make changes and create a patch
```bash
# Edit your Flutter code...
quicui patch --version 1.0.1
```

This generates a binary diff patch and uploads it. Users will receive the update automatically!

## Commands

### `quicui init`
Initialize QuicUI in a Flutter project. Creates `quicui.yaml` with auto-detected settings.

```bash
quicui init                          # Initialize in current directory
quicui init --project /path/to/app   # Initialize in specific project
quicui init --force                  # Overwrite existing config
quicui init --app-id com.example.app # Specify app ID manually
```

### `quicui engine`
Manage the QuicUI Flutter SDK.

```bash
quicui engine status     # Check SDK installation status
quicui engine download   # Download QuicUI Flutter SDK
quicui engine download -f # Force re-download
quicui engine clean      # Remove cached SDK
```

### `quicui release`
Create a new release (build + upload baseline).

```bash
quicui release --version 1.0.0              # Create release v1.0.0
quicui release --version 1.0.0 --arch arm64-v8a  # Specific architecture
```

### `quicui patch`
Create and upload a patch.

```bash
quicui patch --version 1.0.1                # Create patch v1.0.1
quicui patch --version 1.0.1 --base 1.0.0   # Patch from specific base version
```

## Configuration

The `quicui.yaml` file contains all project settings:

```yaml
# Backend server configuration
server:
  url: "https://your-server.supabase.co/functions/v1"
  # api_key: Set via QUICUI_API_KEY environment variable

# Application configuration
app:
  id: "com.example.myapp"
  name: "My App"

# Build configuration
build:
  architectures:
    - arm64-v8a
    # - armeabi-v7a  # Uncomment for 32-bit ARM

# Patch configuration
patch:
  compression: xz  # Best compression
  keep_old_patches: 3
```

## How It Works

1. **QuicUI SDK**: A modified Flutter SDK that supports runtime code loading
2. **Baseline**: The original compiled app (libapp.so) uploaded to server
3. **Patch**: Binary diff between old and new versions
4. **Client**: The app checks for updates and applies patches at runtime

### Architecture
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  quicui CLI │────▶│   Server    │◀────│  Mobile App │
└─────────────┘     └─────────────┘     └─────────────┘
      │                   │                    │
      │ upload baseline   │ store patches     │ download
      │ upload patch      │ version info      │ apply patch
      ▼                   ▼                    ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ QuicUI SDK  │     │  Supabase   │     │ Code Push   │
│ (isolated)  │     │  Database   │     │   Client    │
└─────────────┘     └─────────────┘     └─────────────┘
```

## System Isolation

QuicUI CLI is completely isolated from your system:

| Component | QuicUI Location | System Location | Affected? |
|-----------|----------------|-----------------|-----------|
| Flutter SDK | `~/.quicui/flutter/` | System Flutter | ❌ No |
| Maven Cache | `~/.quicui/maven/` | `~/.m2/` | ❌ No |
| Pub Cache | `~/.quicui/.pub-cache/` | `~/.pub-cache/` | ❌ No |

## Requirements

- Dart SDK 3.0+
- Git
- For Android: Android SDK, Java 11+
- For iOS: Xcode 14+ (macOS only)

## Related Packages

- [quicui_code_push_client](https://github.com/Ikolvi/quicui-code-push-client) - Flutter client SDK
- [quicui_compiler](https://github.com/Ikolvi/quicui-compiler) - AOT snapshot compiler
- [quicui_linker](https://github.com/Ikolvi/quicui-linker) - Binary linker

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.
