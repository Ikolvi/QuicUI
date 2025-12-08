# QuicUI Smart Compiler - Quick Start Guide

## Installation

No installation needed! The compiler is part of the QuicUI monorepo at `packages/quicui_compiler/`.

## Setup (One-Time)

```bash
# 1. Copy example config to your Flutter project
cd your_flutter_project/
cp /path/to/quicui.yaml.example quicui.yaml

# 2. Edit configuration
nano quicui.yaml

# Required settings:
#   app.id: Your app package name (e.g., com.example.myapp)
#   server.url: Your backend URL (e.g., http://192.168.20.100:8080)
#   version.current: Starting version (e.g., 1.0.0)
```

## Basic Usage

### First Build (Establish Base Version)

```bash
dart run /path/to/packages/quicui_compiler/bin/quicui_compiler.dart auto-deploy --version=1.0.0
```

This will:
- Build your APK
- Extract libapp.so snapshots
- Save them as base version (no patch created on first run)

### Deploy Code Update

```bash
# Make your code changes in lib/
# Then run:

dart run /path/to/packages/quicui_compiler/bin/quicui_compiler.dart auto-deploy
```

This automatically:
1. Builds APK (~90 seconds)
2. Extracts libapp.so snapshots
3. Generates binary patches
4. Compresses with xz (70-80% reduction)
5. Uploads to backend
6. Increments version (1.0.0 → 1.0.1)

## Common Commands

```bash
# Full deploy with auto-increment
dart run .../quicui_compiler.dart auto-deploy

# Specify version manually
dart run .../quicui_compiler.dart auto-deploy --version=2.0.0

# Test without uploading
dart run .../quicui_compiler.dart auto-deploy --dry-run

# Skip build, use existing APK
dart run .../quicui_compiler.dart auto-deploy --skip-build

# Verbose logging
dart run .../quicui_compiler.dart auto-deploy --verbose

# Get help
dart run .../quicui_compiler.dart auto-deploy --help
```

## Expected Output

```
🚀 QuicUI Auto-Deploy
══════════════════════════════════════════════════════════════════════

Base version: 1.0.0
New version:  1.0.1

📦 Step 1/5: Building Flutter APK...
✅ Build completed in 96s
APK size: 42.84 MB

📂 Step 2/5: Extracting AOT snapshots...
✅ Extracted arm64-v8a: 3.50 MB
✅ Extracted armeabi-v7a: 3.84 MB

🔨 Step 3/5: Generating patches...
✅ Patch generated: 3.44 MB (arm64-v8a)
✅ Patch generated: 3.85 MB (armeabi-v7a)

🗜️  Step 4/5: Compressing patches...
✅ Compressed: 3.44 MB → 1.02 MB (70.4% reduction)
✅ Compressed: 3.85 MB → 1.12 MB (70.9% reduction)

📤 Step 5/5: Uploading patches to backend...
✅ Upload successful

══════════════════════════════════════════════════════════════════════
✅ Auto-deploy completed successfully!

Summary:
  Base version:    1.0.0
  New version:     1.0.1
  Patches:         2
  Architectures:   arm64-v8a, armeabi-v7a
```

## Configuration Quick Reference

**Minimal quicui.yaml:**
```yaml
server:
  url: "http://your-server:8080"

app:
  id: "com.your.app"
  name: "Your App"

version:
  current: "1.0.0"
  auto_increment: true

build:
  architectures:
    - arm64-v8a
    - armeabi-v7a

patch:
  compression: xz  # Best compression (70-80%)
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Configuration file not found" | Copy `quicui.yaml.example` to `quicui.yaml` |
| "Flutter command not found" | Add Flutter to PATH: `export PATH="$PATH:~/flutter/bin"` |
| "APK not found" | Run `flutter build apk --release` manually first |
| "Upload failed: Connection refused" | Start backend: `dart run packages/quicui_backend/bin/server.dart` |
| "Compression failed" | Install xz: `brew install xz` (macOS) or `apt install xz-utils` (Linux) |

## Tips

1. **First deploy always sets base version** - No patch created, just saves snapshots
2. **Version auto-increments** - 1.0.0 → 1.0.1 → 1.0.2 automatically
3. **Use dry-run for testing** - `--dry-run` skips upload, lets you test patches
4. **Skip build for speed** - `--skip-build` uses existing APK (saves 90 seconds)
5. **xz gives best compression** - 70-80% reduction, but takes longer
6. **Multiple architectures** - Each gets its own patch, backend serves correct one

## What Gets Created

```
your_flutter_project/
├── quicui.yaml                   # Your configuration
├── .quicui/                      # Generated artifacts
│   ├── base_snapshots/          # Cached base versions
│   │   ├── libapp_arm64-v8a_v1.0.0.so
│   │   ├── libapp_arm64-v8a_v1.0.1.so
│   │   ├── libapp_armeabi-v7a_v1.0.0.so
│   │   └── libapp_armeabi-v7a_v1.0.1.so
│   ├── patches/                 # Generated patches
│   │   ├── patch_1.0.0_to_1.0.1_arm64-v8a.quicui
│   │   ├── patch_1.0.0_to_1.0.1_arm64-v8a.quicui.xz  # Compressed
│   │   ├── patch_1.0.0_to_1.0.1_armeabi-v7a.quicui
│   │   └── patch_1.0.0_to_1.0.1_armeabi-v7a.quicui.xz
│   └── extracted/               # Temporary extraction (auto-cleaned)
└── build/app/outputs/flutter-apk/app-release.apk
```

## Example Workflow

```bash
# Day 1: Initial release
cd my_app/
cp ../quicui.yaml.example quicui.yaml
nano quicui.yaml  # Set app.id, server.url
dart run ../packages/quicui_compiler/bin/quicui_compiler.dart auto-deploy --version=1.0.0
# ✅ Base version 1.0.0 established

# Day 2: Bug fix
# Edit lib/bug_fix.dart
dart run ../packages/quicui_compiler/bin/quicui_compiler.dart auto-deploy
# ✅ Patch 1.0.0 → 1.0.1 deployed (1.02 MB download)

# Day 3: New feature
# Edit lib/new_feature.dart
dart run ../packages/quicui_compiler/bin/quicui_compiler.dart auto-deploy
# ✅ Patch 1.0.1 → 1.0.2 deployed (1.15 MB download)

# Day 4: Test before prod
dart run ../packages/quicui_compiler/bin/quicui_compiler.dart auto-deploy --dry-run
# ✅ Patches generated but not uploaded (safe testing)
```

## Performance

- **Full workflow**: ~110-160 seconds (build + extract + patch + compress + upload)
- **Skip build**: ~20-30 seconds (just patch generation and upload)
- **Compression**: 70-80% reduction with xz (3.5 MB → 1.0 MB typical)
- **Bandwidth saved**: 71% on average

## Next Steps

1. Make code changes
2. Run `auto-deploy`
3. Patches uploaded to backend
4. Users download and apply automatically
5. No app store approval needed!

For detailed documentation, see `SMART_COMPILER_IMPLEMENTATION.md`.
