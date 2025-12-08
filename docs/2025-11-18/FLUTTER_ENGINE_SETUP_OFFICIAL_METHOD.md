# Flutter Engine Setup - Official Method (2025)

**Date:** November 18, 2025  
**Reference:** https://github.com/flutter/flutter/blob/main/docs/engine/contributing/Setting-up-the-Engine-development-environment.md

## Overview

As of late 2024, the Flutter engine source is now part of the main `flutter/flutter` repository (no longer a separate `flutter/engine` repo). This document describes the official process for setting up the engine development environment.

## Prerequisites

- A Linux, macOS, or Windows host
- `git` (for source version control)
- An SSH client (for GitHub authentication)
- `python3` (used by many tools, including gclient)
- Chromium's `depot_tools` (includes gclient)
  - Add `depot_tools` directory to the front of your `PATH`
- On macOS and Linux: `curl` and `unzip` (used by gclient sync)
- On macOS: Latest Xcode installed

## Official Setup Process

### Step 1: Clone/Fork the Flutter Framework Repository

```bash
# Clone the Flutter framework repository
git clone https://github.com/flutter/flutter.git
cd flutter

# Or if using your own fork:
git clone https://github.com/YOUR_USERNAME/flutter.git
cd flutter
```

**Important:** The engine source is now integrated into the flutter/flutter repository, not a separate repo.

### Step 2: Copy gclient Configuration File

Copy one of the `engine/scripts/*.gclient` files to the repository root as `.gclient`:

**For non-Googlers (standard setup):**
```bash
cp engine/scripts/standard.gclient .gclient
```

**For Googlers with RBE access:**
```bash
cp engine/scripts/rbe.gclient .gclient
# Then follow RBE Getting Started guide
```

**Content of standard.gclient:**
```python
# Copy this file to the root of your flutter checkout to bootstrap gclient
# or just run gclient sync in an empty directory with this file.
solutions = [
  {
    "custom_deps": {},
    "deps_file": "DEPS",
    "managed": False,
    "name": ".",
    "safesync_url": "",
    "url": "https://github.com/flutter/flutter.git",
    
    # Uncomment the custom_vars section below if you plan to build the web engine.
    # "custom_vars": {
    #   "download_emsdk": True,
    # },
  },
]
```

### Step 3: Run gclient sync

From the Flutter repository root (where `.gclient` is located):

```bash
# Make sure depot_tools is in your PATH
export PATH="/path/to/depot_tools:$PATH"

# Run gclient sync to fetch all engine dependencies
gclient sync
```

**What this does:**
- Downloads ~100+ third-party dependencies into `engine/src/flutter/third_party/`
- Downloads the Dart SDK
- Downloads all build tools (GN, Ninja, Clang, etc.)
- Sets up the complete engine build environment
- Total download size: ~8-12 GB
- Time required: 15-45 minutes (depending on network speed)

### Step 4: Verify Setup

After gclient sync completes, verify the structure:

```bash
# Check engine source location
ls engine/src/flutter/

# Expected directories:
# - shell/         (platform embeddings)
# - lib/           (Dart engine)
# - third_party/   (dependencies)
# - tools/         (build tools)
# - BUILD.gn       (main build file)
```

## Directory Structure

After successful setup:

```
flutter/                          # Flutter framework repo root
├── .gclient                      # gclient configuration
├── DEPS                          # Dependency specifications
├── bin/                          # Flutter tools
├── packages/                     # Flutter packages
├── engine/                       # Engine directory
│   ├── .gclient                  # (optional) engine-specific config
│   ├── scripts/
│   │   ├── standard.gclient      # Template for non-Googlers
│   │   └── rbe.gclient           # Template for Googlers
│   └── src/                      # Engine source (populated by gclient sync)
│       ├── flutter/              # Main engine source
│       │   ├── shell/
│       │   ├── lib/
│       │   ├── third_party/      # ~100+ dependencies
│       │   ├── tools/
│       │   └── BUILD.gn
│       ├── build/                # Build system
│       ├── buildtools/           # Build tools
│       └── third_party/          # Additional dependencies
└── ...
```

## Next Steps

After setup is complete:

1. **Use Engine Tool (`et`)**: Add `engine/src/flutter/bin` to your PATH
2. **Configure Build**: Use `gn` to configure your build
3. **Build Engine**: Use `ninja` to build the engine
4. **Run Tests**: Use engine testing tools

## Common Issues

### Issue: "client not configured"

**Cause:** Running gclient sync from wrong directory  
**Solution:** Must run from Flutter repository root where `.gclient` file exists

### Issue: Network timeouts during sync

**Cause:** Large repositories or slow network  
**Solution:** gclient automatically retries. Just wait for completion.

### Issue: Low disk space

**Cause:** Engine dependencies are large (~8-12 GB)  
**Solution:** Ensure sufficient disk space before running gclient sync

## Background Process Setup

To run gclient sync in background:

```bash
# Start in background
cd /path/to/flutter
export PATH="/path/to/depot_tools:$PATH"
nohup gclient sync > /tmp/gclient_sync.log 2>&1 &

# Monitor progress
tail -f /tmp/gclient_sync.log

# Check if running
ps aux | grep "gclient sync"

# Check downloaded size
du -sh engine/src
```

## Monitoring Script

Create `/tmp/monitor_gclient.sh`:

```bash
#!/bin/bash
while ps aux | grep -q "[g]client sync"; do
    clear
    echo "=== gclient sync Progress ==="
    echo "Time: $(date '+%H:%M:%S')"
    echo "Size: $(du -sh engine/src 2>/dev/null | cut -f1)"
    echo "Deps: $(ls engine/src/flutter/third_party/ 2>/dev/null | grep -v "^_gclient" | wc -l)"
    tail -5 /tmp/gclient_sync.log
    sleep 15
done
echo "=== Completed ==="
```

## Key Changes from Old Process

**Before (pre-2024):**
- Separate `flutter/engine` repository
- Engine had its own independent structure
- Used `fetch flutter` command

**Now (late 2024/early 2025+):**
- Engine integrated into `flutter/flutter` repository
- Single unified repository structure
- Use `gclient sync` from framework root
- Simpler setup and maintenance

## References

- [Official Setup Guide](https://github.com/flutter/flutter/blob/main/docs/engine/contributing/Setting-up-the-Engine-development-environment.md)
- [Compiling the Engine](https://github.com/flutter/flutter/blob/main/docs/engine/contributing/Compiling-the-engine.md)
- [Engine Documentation Index](https://github.com/flutter/flutter/tree/main/docs/engine)

## Related Documentation

- See `QUICUI_ENGINE_MODIFICATIONS.md` for QuicUI-specific engine changes
- See `ENGINE_BUILD_PROCESS.md` for detailed build instructions
- See `DEPLOYMENT_GUIDE.md` for engine deployment process

---

**Last Updated:** November 18, 2025  
**Status:** Official method as of late 2024/early 2025
