# QuicUI Flutter SDK Modifications

**Repository**: https://github.com/Ikolvi/QuicUIFlutterSDK  
**Base**: Official Flutter SDK with QuicUI Code Push engine patches  
**Status**: ✅ Pushed to main branch (3 commits)

## Overview

The QuicUI Flutter SDK is a modified version of the official Flutter SDK that includes patches for integrating the QuicUI Code Push runtime loader directly into the Flutter engine.

## Key Patches Applied

### 1. Add CodePush Loader C++ Implementation
**Commit**: b22ac414507  
**Changes**: 
- Core C++ loader implementation for QuicUI Code Push
- Async patch verification and loading
- Kernel binary parsing
- Thread-safe caching mechanism

**Files**:
- `engine/src/flutter/runtime/codepush_loader.cc`
- `engine/src/flutter/runtime/codepush_loader.h`

### 2. Integrate CodePushLoader into Flutter Engine
**Commit**: 40304e9b782  
**Changes**:
- Hook CodePush loader into Flutter engine initialization
- Add loader lifecycle management
- Integrate with Dart VM startup
- Handle patch verification during boot

**Files**:
- `engine/src/flutter/runtime/dart_vm.cc`
- `engine/src/flutter/lib/ui/dart_ui.dart`

### 3. Add Dart VM Patch Loading Support
**Commit**: c1fc29fea9a  
**Changes**:
- Dart VM integration for kernel loading
- Patch metadata validation
- Kernel file format detection
- Compiled kernel caching

**Files**:
- `third_party/dart/runtime/vm/kernel_loader.cc`
- `third_party/dart/runtime/vm/kernel_loader.h`

## Benefits

✅ **Seamless Integration**: No need for platform channels for critical operations  
✅ **Performance**: Engine-level integration for faster patch loading  
✅ **Security**: Direct kernel validation before Dart VM execution  
✅ **Reliability**: Built into Flutter's initialization pipeline  

## Using This SDK

### For Development

```bash
# Clone the modified SDK
git clone git@github.com:Ikolvi/QuicUIFlutterSDK.git flutter-sdk

# Use with custom Flutter builds
cd flutter-sdk
./dev/bots/docs.sh
```

### For Building Apps

1. Point your Flutter installation to this SDK:
```bash
export PATH=/path/to/QuicUIFlutterSDK/bin:$PATH
```

2. Or build a custom Flutter distribution:
```bash
cd QuicUIFlutterSDK
./flutter/tools/gn --android --ios --linux --macos --web --windows
ninja -C out/release
```

### Patch Deployment

With this SDK, patches are deployed directly to the engine:

```bash
# Create patch
quicui_compiler build old-kernel.dill new-kernel.dill

# Upload to backend
quicui_compiler upload patch.json

# The engine automatically loads patches on app startup
```

## Architecture Integration

```
┌─────────────────────────────────────────┐
│         Flutter Application             │
├─────────────────────────────────────────┤
│  Modified Flutter Engine (QuicUI SDK)   │
│  ├─ CodePushLoader (C++)                │
│  ├─ Dart VM Integration                 │
│  └─ Kernel Loading Pipeline             │
├─────────────────────────────────────────┤
│  QuicUI Backend (Patch Service)         │
│  └─ Patch Upload, Versioning, Rollout   │
└─────────────────────────────────────────┘
```

## Version Tracking

| Component | Version | Status |
|-----------|---------|--------|
| Flutter Base | 3.16.x | ✅ Current |
| Dart SDK | 3.2.x | ✅ Current |
| QuicUI Patches | 1.0 | ✅ Applied |
| Engine Modifications | 3 commits | ✅ Integrated |

## Building From Source

### Prerequisites
```bash
flutter --version  # 3.16+
dart --version     # 3.2+
cmake --version    # 3.16+
ninja              # Latest
```

### Build Steps

```bash
cd QuicUIFlutterSDK

# Configure build
./flutter/tools/gn \
  --android \
  --ios \
  --linux \
  --macos \
  --web \
  --windows

# Build engine
ninja -C out/release

# Build Flutter tools
cd flutter
dart pub get
dart pub global activate -s path .
```

## Testing

### Unit Tests
```bash
cd engine
ninja -C out/release && ./out/release/dart_vm_test
```

### Integration Tests
```bash
cd flutter
flutter test
```

### E2E Testing
```bash
# Use the QuicUI test app
cd ../packages/quicui_code_push_client/example
flutter run
```

## Maintenance

### Keeping in Sync with Official Flutter

```bash
cd QuicUIFlutterSDK

# Add upstream remote
git remote add upstream https://github.com/flutter/flutter.git

# Fetch latest
git fetch upstream

# Rebase QuicUI patches
git rebase upstream/main
```

### Updating Patches

If Flutter updates core components affected by our patches:

```bash
git rebase -i upstream/main

# Resolve conflicts in:
# - engine/src/flutter/runtime/dart_vm.cc
# - third_party/dart/runtime/vm/kernel_loader.cc

git push quicui main --force
```

## Security Considerations

✅ All patches maintain Flutter's security model  
✅ No reduction in platform security  
✅ Cryptographic verification preserved  
✅ Engine security checks still enforced  

## Troubleshooting

### Build Fails
- Clear build cache: `rm -rf out/`
- Reinstall dependencies: `gclient sync -f`

### Patches Don't Apply
- Check Flutter version matches (3.16.x)
- Verify Dart SDK version (3.2.x)
- Rebuild from scratch

### Runtime Issues
- Check CodePush loader logs in Flutter engine startup
- Verify patch files in `/tmp/codepush/`
- Enable verbose logging in `codepush_loader.cc`

## Support

- **Issues**: GitHub Issues on this repository
- **Questions**: See QuicUI Code Push documentation
- **Contributions**: Submit PRs with patch improvements

## License

This SDK maintains the same license as the official Flutter SDK (BSD 3-Clause).

The QuicUI patches are licensed under the MIT License.

---

**Last Updated**: November 1, 2025  
**Status**: ✅ Production Ready  
**Repository**: https://github.com/Ikolvi/QuicUIFlutterSDK
