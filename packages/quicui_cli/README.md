# QuicUI CLI

Command-line interface for QuicUI Code Push - deliver instant updates to your Flutter apps without app store approval.

[![Pub Version](https://img.shields.io/pub/v/quicui_cli)](https://pub.dev/packages/quicui_cli)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- 🚀 **One-command releases** - Build, upload baseline, and register in one step
- 📦 **One-command patches** - Generate and upload patches instantly
- 🔑 **Auto API key generation** - Secure keys generated automatically on init
- 🔧 **Automatic SDK management** - Downloads QuicUI Flutter SDK automatically
- 🔒 **Isolated from system** - Doesn't affect your system Flutter installation
- ⚡ **Fast iteration** - Hot reload-like updates for production apps

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [Server Setup](#server-setup)
- [Commands Reference](#commands-reference)
- [Configuration](#configuration)
- [Architecture](#architecture)
- [Troubleshooting](#troubleshooting)
- [Related Projects](#related-projects)

## Installation

### From pub.dev (recommended)
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

### Verify installation
```bash
quicui --version
quicui --help
```

## Quick Start

### 1. Initialize QuicUI in your Flutter project
```bash
cd your_flutter_app
quicui init
```

This will:
- Detect your app ID from `android/app/build.gradle`
- **Auto-generate a unique API key** from the QuicUI server
- Create `quicui.yaml` with your configuration

### 2. Download QuicUI SDK (first time only)
```bash
quicui engine download
```

Downloads the QuicUI-enabled Flutter SDK to `~/.quicui/flutter/` (completely isolated from your system Flutter).

### 3. Create your first release
```bash
quicui release --version 1.0.0
```

This builds your app with QuicUI support and uploads the baseline binary to the server.

### 4. Publish to Play Store
Build and publish your app normally. The QuicUI client library will handle updates.

### 5. Make changes and create a patch
```bash
# Edit your Flutter code...
quicui patch --version 1.0.1
```

This generates a binary diff patch and uploads it. Users receive the update automatically!

---

## Server Setup

QuicUI uses Supabase as the backend. You have two options:

### Option A: Use the hosted QuicUI server (default)

No setup required! The CLI is pre-configured to use the hosted server at:
```
https://pcaxvanjhtfaeimflgfk.supabase.co/functions/v1
```

API keys are automatically generated when you run `quicui init`.

### Option B: Self-host your own server

1. **Clone the server repository**
   ```bash
   git clone git@github.com:Ikolvi/QuicUiServer.git
   cd QuicUiServer
   ```

2. **Create a Supabase project**
   - Go to [supabase.com](https://supabase.com)
   - Create a new project
   - Note your project URL and keys

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your Supabase credentials:
   # SUPABASE_URL=https://your-project.supabase.co
   # SUPABASE_ANON_KEY=your_anon_key
   # SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
   ```

4. **Link and deploy**
   ```bash
   supabase login
   supabase link --project-ref your-project-ref
   supabase db push
   supabase functions deploy
   ```

5. **Update your CLI config**
   ```yaml
   # quicui.yaml
   server:
     url: "https://your-project.supabase.co/functions/v1"
     api_key: "your-generated-api-key"
   ```

### Server Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Supabase Backend                         │
├─────────────────────────────────────────────────────────────┤
│  Edge Functions                                             │
│  ├── api-keys-cli      # Generate API keys for projects    │
│  ├── patches-check     # Check for available updates       │
│  ├── patches-register  # Register new patches              │
│  └── patches-download  # Serve patch files                 │
├─────────────────────────────────────────────────────────────┤
│  Database (PostgreSQL)                                      │
│  ├── api_keys          # API key hashes and metadata       │
│  ├── baselines         # Released app versions             │
│  ├── patches           # Patch metadata and versions       │
│  └── download_stats    # Analytics and metrics             │
├─────────────────────────────────────────────────────────────┤
│  Storage                                                    │
│  ├── baselines/        # Baseline binaries (libapp.so)     │
│  └── patches/          # Patch files (.quicui, .xz)        │
└─────────────────────────────────────────────────────────────┘
```

---

## Commands Reference

### `quicui init`

Initialize QuicUI in a Flutter project. Creates `quicui.yaml` with auto-generated API key.

```bash
# Initialize in current directory
quicui init

# Initialize in specific project
quicui init --project /path/to/app

# Overwrite existing config
quicui init --force

# Specify app ID manually
quicui init --app-id com.example.app

# Use custom server
quicui init --server-url https://your-server.supabase.co/functions/v1
```

**What happens:**
1. Reads app info from `pubspec.yaml` and `build.gradle`
2. Calls the server to generate a unique API key
3. Creates `quicui.yaml` with all configuration

---

### `quicui engine`

Manage the QuicUI Flutter SDK.

```bash
# Check SDK installation status
quicui engine status

# Download QuicUI Flutter SDK
quicui engine download

# Force re-download (update)
quicui engine download -f

# Remove cached SDK
quicui engine clean
```

**SDK Location:** `~/.quicui/flutter/`

The QuicUI SDK is a modified Flutter that supports runtime code loading. It's completely isolated from your system Flutter installation.

---

### `quicui release`

Create a new release (baseline). This is required before creating patches.

```bash
# Create release with version from pubspec.yaml
quicui release

# Create release with specific version
quicui release --version 1.0.0

# Specify architecture (default: arm64-v8a)
quicui release --arch arm64-v8a

# Specify project path
quicui release --project /path/to/app

# Verbose output
quicui release --version 1.0.0 --verbose
```

**What happens:**
1. Builds release APK using QuicUI SDK
2. Extracts `libapp.so` from the APK
3. Uploads baseline to server storage
4. Registers version in database

---

### `quicui patch`

Create and upload a patch (update).

```bash
# Create patch with version from pubspec.yaml
quicui patch

# Create patch with specific version
quicui patch --version 1.0.1

# Specify base version to patch from
quicui patch --version 1.0.1 --base 1.0.0

# Use different compression (xz, gzip, none)
quicui patch --version 1.0.1 --compression xz

# Mark as critical update
quicui patch --version 1.0.1 --critical

# Add release notes
quicui patch --version 1.0.1 --notes "Bug fixes and improvements"

# Verbose output
quicui patch --version 1.0.1 --verbose
```

**What happens:**
1. Builds new release APK
2. Extracts new `libapp.so`
3. Downloads baseline from server
4. Generates binary diff patch
5. Compresses patch (XZ by default)
6. Uploads patch to server
7. Registers in database

---

### `quicui build-aab`

Build an Android App Bundle for Play Store release.

```bash
# Build AAB
quicui build-aab --project /path/to/app

# With specific version
quicui build-aab --version 1.0.0
```

---

## Configuration

### quicui.yaml

The configuration file is created by `quicui init`:

```yaml
# QuicUI Code Push Configuration
# Generated by: quicui init

# Backend server configuration
server:
  url: "https://pcaxvanjhtfaeimflgfk.supabase.co/functions/v1"
  # API key auto-generated by QuicUI CLI
  api_key: "quicui_abc123..."

# Application configuration
app:
  id: "com.example.myapp"
  name: "My App"

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
  
  # Supported architectures
  architectures:
    - arm64-v8a
    # - armeabi-v7a  # Uncomment for 32-bit ARM support

# Patch configuration
patch:
  compression: xz      # xz (best), gzip (fast), none
  keep_old_patches: 5  # Number of old patches to keep
```

### Environment Variables

You can override configuration with environment variables:

| Variable | Description |
|----------|-------------|
| `QUICUI_API_KEY` | Override API key from yaml |
| `QUICUI_SERVER_URL` | Override server URL |

```bash
export QUICUI_API_KEY="your-api-key"
quicui patch --version 1.0.1
```

---

## Architecture

### How QuicUI Works

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Development Flow                            │
└─────────────────────────────────────────────────────────────────────┘

Developer Machine                    Server                    User Device
┌─────────────────┐           ┌─────────────────┐         ┌─────────────────┐
│                 │           │                 │         │                 │
│  Flutter App    │           │    Supabase     │         │   Flutter App   │
│  Source Code    │           │    Backend      │         │   (Installed)   │
│                 │           │                 │         │                 │
└────────┬────────┘           └────────┬────────┘         └────────┬────────┘
         │                             │                           │
         │ quicui release              │                           │
         │ ─────────────────────────▶  │                           │
         │                             │ Store baseline            │
         │                             │                           │
         │ quicui patch                │                           │
         │ ─────────────────────────▶  │                           │
         │                             │ Store patch               │
         │                             │                           │
         │                             │ ◀──────────────────────── │
         │                             │   Check for updates       │
         │                             │                           │
         │                             │ ────────────────────────▶ │
         │                             │   Download & apply patch  │
         │                             │                           │
         │                             │                     ┌─────┴─────┐
         │                             │                     │  Updated  │
         │                             │                     │    App    │
         │                             │                     └───────────┘
```

### Binary Patching

QuicUI uses binary diff (bsdiff algorithm) to create minimal patches:

```
Original libapp.so (10 MB)
         │
         ▼ bsdiff
┌─────────────────┐
│  Patch File     │  (~100-500 KB typical)
│  .quicui.xz     │
└─────────────────┘
         │
         ▼ bspatch
New libapp.so (10.1 MB)
```

### System Isolation

QuicUI CLI is completely isolated from your system:

| Component | QuicUI Location | System Location | Affected? |
|-----------|-----------------|-----------------|-----------|
| Flutter SDK | `~/.quicui/flutter/` | System Flutter | ❌ No |
| Maven Cache | `~/.quicui/maven/` | `~/.m2/` | ❌ No |
| Pub Cache | `~/.quicui/.pub-cache/` | `~/.pub-cache/` | ❌ No |
| Build Output | `.quicui/` in project | `build/` | ❌ No |

---

## Troubleshooting

### "quicui.yaml not found"

Run `quicui init` in your Flutter project directory first:
```bash
cd your_flutter_app
quicui init
```

### "API key not found"

Either:
1. Run `quicui init` to auto-generate an API key
2. Set the `QUICUI_API_KEY` environment variable
3. Add `api_key` to `quicui.yaml` under `server`

### "Failed to generate API key"

Check your network connection. The CLI needs to reach the QuicUI server:
```bash
curl -X POST https://pcaxvanjhtfaeimflgfk.supabase.co/functions/v1/api-keys-cli \
  -H "Content-Type: application/json" \
  -d '{"app_id": "com.test.app", "app_name": "Test"}'
```

### "No baseline found"

You need to create a release before creating patches:
```bash
quicui release --version 1.0.0
```

### "Flutter SDK not found"

Download the QuicUI SDK:
```bash
quicui engine download
```

### Build failures

1. Check Java version (requires JDK 11+):
   ```bash
   java -version
   ```

2. Check Android SDK:
   ```bash
   echo $ANDROID_HOME
   ```

3. Run with verbose output:
   ```bash
   quicui release --version 1.0.0 --verbose
   ```

---

## Requirements

### System Requirements

| Requirement | Version |
|-------------|---------|
| Dart SDK | 3.0+ |
| Git | Any |
| Java JDK | 11+ |
| Android SDK | 30+ |
| Xcode (macOS) | 14+ (for iOS) |

### Supported Platforms

| Platform | Architecture | Status |
|----------|--------------|--------|
| Android | arm64-v8a | ✅ Supported |
| Android | armeabi-v7a | ✅ Supported |
| Android | x86_64 | ⚠️ Emulator only |
| iOS | arm64 | 🚧 Coming Soon |

---

## Related Projects

| Project | Description | Repository |
|---------|-------------|------------|
| **QuicUI CLI** | This CLI tool | [github.com/Ikolvi/quicui-cli](https://github.com/Ikolvi/quicui-cli) |
| **QuicUI Server** | Supabase backend | [github.com/Ikolvi/QuicUiServer](https://github.com/Ikolvi/QuicUiServer) |
| **Code Push Client** | Flutter client SDK | [github.com/Ikolvi/QuicUICodepush](https://github.com/Ikolvi/QuicUICodepush) |

### Integration in Your App

Add the client library to your Flutter app:

```yaml
# pubspec.yaml
dependencies:
  quicui: ^2.0.6
```

Initialize in your app:

```dart
import 'package:quicui/quicui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await QuicUICodePush.instance.initialize();
  runApp(MyApp());
}
```

---

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please read our [contributing guidelines](CONTRIBUTING.md) before submitting PRs.

## Support

- 📖 [Documentation](https://github.com/Ikolvi/quicui-cli#readme)
- 🐛 [Issue Tracker](https://github.com/Ikolvi/quicui-cli/issues)
- 💬 [Discussions](https://github.com/Ikolvi/quicui-cli/discussions)

---

Made with ❤️ by the QuicUI team
