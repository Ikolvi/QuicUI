# QuicUI CLI

Command-line interface for building, patching, and deploying QuicUI-enabled Flutter applications with code push capabilities.

## Overview

The QuicUI CLI automates the process of:
- Building Flutter APKs with custom QuicUI engine
- Extracting native libraries (libapp.so) for patching
- Generating binary diff patches (QUICUI01 format)
- Uploading baselines and patches to Supabase backend
- Managing version control for code push updates

## Installation

```bash
# From the quicui2 root directory
cd packages/quicui_cli
dart pub get

# Add to PATH or use dart run
export PATH="$PATH:$(pwd)/bin"
```

## Configuration

Create a `quicui.yaml` file in your Flutter project root:

```yaml
app_id: com.example.your_app
backend_url: https://your-project.supabase.co/functions/v1
api_key: your_api_key_here
```

## Commands

### 1. Build APK

Build a Flutter APK with the custom QuicUI engine and extract native libraries.

```bash
quicui build-apk --version <version> [options]
```

**Options:**
- `--version, -v`: Version number (required, e.g., "2.0.6")
- `--project, -p`: Path to Flutter project (default: current directory)
- `--output, -o`: Custom output directory
- `--baseline, -b`: Mark as baseline version
- `--architecture, -a`: Target architecture (default: arm64-v8a)
  - `arm64-v8a` (64-bit ARM)
  - `armeabi-v7a` (32-bit ARM)
  - `x86_64` (64-bit Intel)
  - `x86` (32-bit Intel)

**Examples:**

```bash
# Build baseline version
quicui build-apk --version 2.0.6 --baseline

# Build new version for patching
quicui build-apk --version 2.0.8 --project ./test_apps/quicui_production_test

# Build for specific architecture
quicui build-apk --version 2.0.8 --architecture armeabi-v7a
```

**Output:**
- APK file: `app-v{version}.apk`
- Native library: `libapp-{arch}.so`
- Metadata file: `metadata.json`

### 2. Generate Patch

Generate a binary diff patch between two versions using QUICUI01 format.

```bash
quicui generate-patch --from <baseline> --to <target> [options]
```

**Options:**
- `--from`: Baseline version directory (required)
- `--to`: Target version directory (required)
- `--output, -o`: Output directory for patch file
- `--architecture, -a`: Target architecture (default: arm64-v8a)

**Example:**

```bash
# Generate patch from v2.0.6 to v2.0.8
quicui generate-patch --from ./baseline --to ./v2.0.8

# Specify custom output
quicui generate-patch \
  --from ./test_apps/quicui_production_test/baseline \
  --to ./test_apps/quicui_production_test/v2.0.8 \
  --output ./patches
```

**Output:**
- Patch file: `patch-{from}-to-{to}-{arch}.quicui`
- Compressed patch: `patch-{from}-to-{to}-{arch}.quicui.xz`
- Metadata: `patch-metadata.json`

### 3. Upload Baseline

Register a baseline version with the Supabase backend.

```bash
quicui upload-baseline --version <version> [options]
```

**Options:**
- `--version, -v`: Baseline version (required)
- `--baseline-dir`: Path to baseline directory (default: ./baseline)
- `--architecture, -a`: Target architecture (default: arm64-v8a)

**Example:**

```bash
quicui upload-baseline --version 2.0.6
```

### 4. Upload Patch

Upload a patch file to the Supabase backend.

```bash
quicui upload-patch --from <baseline> --to <target> [options]
```

**Options:**
- `--from`: Baseline version (required)
- `--to`: Target version (required)
- `--patch-file, -p`: Path to patch file
- `--architecture, -a`: Target architecture (default: arm64-v8a)

**Example:**

```bash
quicui upload-patch --from 2.0.6 --to 2.0.8
```

## QuicUI Engine Integration

### Engine Requirements

The QuicUI CLI is designed to work with a **custom-built Flutter engine** that includes:

1. **Modified FlutterLoader.java** - Detects and loads patched AOT libraries
2. **Code push support** - Native bridge for patch installation
3. **QUICUI01 format** - Custom binary diff format with XZ compression

### Engine Path Configuration

The CLI expects the QuicUI engine to be built at:

```
/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/
├── out/
│   ├── android_release_arm64/     # Android engine artifacts
│   └── host_release/              # Host build tools
```

**Build parameters used:**
```bash
--local-engine-src-path=/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src
--local-engine=android_release_arm64
--local-engine-host=host_release
```

### Engine Modifications Required

The QuicUI engine must include these modifications in FlutterLoader.java:

**Location:** `engine/src/flutter/shell/platform/android/io/flutter/embedding/engine/loader/FlutterLoader.java`

**Modification:**

```java
// QuicUI Code Push: Check for patched AOT library before loading default
String patchedLibPath = null;
String codeCachePath = applicationContext.getCodeCacheDir().getAbsolutePath();
String[] architectures = {"arm64-v8a", "armeabi-v7a", "x86_64", "x86"};

for (String arch : architectures) {
  String candidatePath = codeCachePath + File.separator + "quicui_patches" + 
                         File.separator + "libapp_patched_" + arch + ".so";
  File candidateFile = new File(candidatePath);
  if (candidateFile.exists()) {
    patchedLibPath = candidatePath;
    Log.i(TAG, "QuicUI: Found patched AOT library at: " + patchedLibPath);
    break;
  }
}

if (patchedLibPath != null) {
  // Use the patched library
  shellArgs.add(aotSharedLibraryNameFlag + patchedLibPath);
  Log.i(TAG, "QuicUI: Using patched AOT library");
} else {
  // Use the default library from APK
  shellArgs.add(aotSharedLibraryNameFlag + flutterApplicationInfo.aotSharedLibraryName);
  shellArgs.add(
      aotSharedLibraryNameFlag
          + flutterApplicationInfo.nativeLibraryDir
          + File.separator
          + flutterApplicationInfo.aotSharedLibraryName);
}
```

### Building the QuicUI Engine

To build the modified engine:

1. **Apply modifications** to FlutterLoader.java in the engine source
2. **Build the engine** for Android:
   ```bash
   cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src
   
   # Build Android engine
   ninja -C out/android_release_arm64
   
   # Build host tools
   ninja -C out/host_release
   ```
3. **Verify build artifacts** exist:
   ```bash
   ls out/android_release_arm64/flutter.jar
   ls out/android_release_arm64/libflutter.so
   ls out/host_release/dart-sdk/
   ```

## Complete Workflow Example

### Initial Setup (One-time)

1. **Build the QuicUI engine** with modifications
2. **Configure your Flutter project** with `quicui.yaml`
3. **Build baseline APK**:
   ```bash
   cd test_apps/quicui_production_test
   quicui build-apk --version 2.0.6 --baseline
   ```
4. **Upload baseline**:
   ```bash
   quicui upload-baseline --version 2.0.6
   ```
5. **Install baseline APK** on test device

### Creating and Deploying Updates

1. **Make code changes** in your Flutter app (UI, logic, assets)

2. **Build new version**:
   ```bash
   quicui build-apk --version 2.0.8
   ```

3. **Generate patch**:
   ```bash
   quicui generate-patch --from ./baseline --to ./v2.0.8
   ```

4. **Upload patch**:
   ```bash
   quicui upload-patch --from 2.0.6 --to 2.0.8
   ```

5. **Test update**: Open the app, it will detect and download the patch

### Debugging

**Check build configuration:**
```bash
# Verify engine path exists
ls /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/out/android_release_arm64

# Check QuicUI SDK
ls forks/flutter-quicui/bin/flutter
```

**Common issues:**

| Issue | Solution |
|-------|----------|
| Engine not found | Verify `/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src` exists |
| Build fails | Ensure engine is built: `ninja -C out/android_release_arm64` |
| Patches don't apply | Verify FlutterLoader.java modifications are in built engine |
| Wrong architecture | Specify `--architecture` matching your test device |

## Architecture

```
┌─────────────────┐
│   QuicUI CLI    │
│  (Dart/Flutter) │
└────────┬────────┘
         │
         ├─► FlutterService ──────► Custom Flutter SDK
         │                          └─► QuicUI Engine (local-engine)
         │
         ├─► ApkExtractorService ─► Extract libapp.so from APK
         │
         ├─► PatchGeneratorService ► BsDiff + QUICUI01 format
         │
         └─► BackendService ────────► Supabase Edge Functions
                                      ├─► patches-check
                                      ├─► patches-register
                                      └─► patches-download
```

## File Structure

```
packages/quicui_cli/
├── bin/
│   └── quicui.dart              # CLI entry point
├── lib/
│   ├── quicui_cli.dart
│   └── src/
│       ├── commands/
│       │   ├── build_apk_command.dart
│       │   ├── generate_patch_command.dart
│       │   ├── upload_baseline_command.dart
│       │   └── upload_patch_command.dart
│       ├── config/
│       │   └── cli_config.dart
│       └── services/
│           ├── apk_extractor_service.dart
│           ├── flutter_service.dart
│           ├── patch_generator_service.dart
│           └── backend_service.dart
├── output/                       # Generated files (gitignored)
└── pubspec.yaml
```

## Technical Details

### QUICUI01 Patch Format

```
[8 bytes]  Magic header: "QUICUI01"
[Variable] BsDiff patch data
```

Compressed with XZ (LZMA2) for optimal size:
- Typical compression ratio: 70-85%
- Example: 3.6 MB → 1.08 MB

### Architecture Mapping

| Flutter Target | Android ABI | CLI Architecture |
|----------------|-------------|------------------|
| android-arm64  | arm64-v8a   | arm64-v8a       |
| android-arm    | armeabi-v7a | armeabi-v7a     |
| android-x64    | x86_64      | x86_64          |
| android-x86    | x86         | x86             |

### Backend Integration

The CLI communicates with Supabase Edge Functions:

- **patches-check**: Check for available updates
- **patches-register**: Register new baseline/patch
- **patches-download**: Download patch file

Authentication: API key + JWT Bearer token

## Development

```bash
# Install dependencies
dart pub get

# Run locally
dart run bin/quicui.dart build-apk --version 1.0.0

# Test
dart test
```

## See Also

- [QuicUI Backend Documentation](../../packages/quicui_backend/README.md)
- [QuicUI Code Push Client](../../packages/quicui_code_push_client/README.md)
- [QuicUI Compiler](../../packages/quicui_compiler/README.md)
- [Deployment Guide](../../DEPLOYMENT_GUIDE.md)
- [Flutter Engine Modifications](../../docs/FLUTTER_ENGINE_MODIFICATIONS.md)

## License

MIT License - See LICENSE file for details
