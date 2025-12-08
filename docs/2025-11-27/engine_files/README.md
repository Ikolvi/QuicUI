# QuicUI Engine Modified Files

This directory contains all files modified or created for the QuicUI interpreter implementation in the Flutter engine.

## Directory Structure

```
engine_files/
├── quicui/                           # QuicUI integration code
│   ├── BUILD.gn                      # Build configuration for QuicUI
│   ├── quicui.h                      # Main QuicUI API header
│   ├── quicui.cc                     # Main QuicUI implementation
│   ├── quicui_updater.h              # Wrapper mapping quicui_* to shorebird_* functions
│   ├── snapshots_data_handle.h       # Snapshot data management header
│   ├── snapshots_data_handle.cc      # Snapshot data management implementation
│   └── snapshots_data_handle_unittests.cc  # Unit tests
├── runtime/
│   ├── dart_snapshot.cc              # Modified: Added .vmcode detection and Dart_LoadELF
│   └── dart_snapshot.cc.backup       # Original before modifications
├── build/
│   └── quicui.gni                    # QuicUI build flag configuration
└── shell/
    ├── common/
    │   └── BUILD.gn                  # Modified: Added quicui.gni import
    └── platform/darwin/ios/
        └── BUILD.gn                  # Modified: Added QuicUI deps and QUICUI_USE_INTERPRETER

```

## Files Created (New)

### quicui/
All files in this directory are new, adapted from Shorebird's implementation:

1. **quicui.h** - Main API for QuicUI configuration
2. **quicui.cc** - Implementation with updater integration
3. **quicui_updater.h** - Wrapper header that maps QuicUI function names to updater library
4. **snapshots_data_handle.{h,cc}** - Handles snapshot data for ELF loading
5. **BUILD.gn** - Build configuration

### build/
- **quicui.gni** - Global flag: `quicui_enabled` (default: false)

## Files Modified

### runtime/dart_snapshot.cc
**Changes**:
1. Added includes for QUICUI_USE_INTERPRETER
2. Added .vmcode file detection before line 80
3. Implemented Dart_LoadELF loading for interpreter mode
4. Returns NonOwnedMapping for .vmcode isolate instructions

**Backup**: `dart_snapshot.cc.backup` contains original

### shell/common/BUILD.gn
**Changes**:
- Added import of `//flutter/build/quicui.gni` (line 9)

### shell/platform/darwin/ios/BUILD.gn
**Changes**:
1. Added import of `//flutter/build/quicui.gni` (line 14)
2. Added `QUICUI_USE_INTERPRETER=1` define when `quicui_enabled=true` (after line 69)
3. Added QuicUI dependency: `//flutter/shell/common/quicui` (after line 216)

## Key Implementation Details

### quicui_updater.h
This wrapper header solves the naming mismatch between QuicUI and the updater library:
```cpp
#define quicui_init shorebird_init
#define quicui_should_auto_update shorebird_should_auto_update
#define quicui_next_boot_patch_path shorebird_next_boot_patch_path
// ... etc
```

### dart_snapshot.cc - .vmcode Loading
Added interpreter support that detects `.vmcode` files and loads them via `Dart_LoadELF`:
```cpp
#if QUICUI_USE_INTERPRETER
  auto patch_path = native_library_paths.front();
  bool is_patch = patch_path.find(".vmcode") != std::string::npos;
  
  if (is_patch) {
    // Load ELF and extract isolate_instrs
    leaked_elf = Dart_LoadELF(patch_path.c_str(), ...);
    return std::make_unique<const fml::NonOwnedMapping>(isolate_instrs, 0);
  }
#endif
```

### Workarounds Applied

1. **SetBaseSnapshots**: Commented out (function not available in updater library version)
2. **Snapshot Sizes**: Using size 0 instead of `Dart_SnapshotDataSize/InstrSize` (not available)
3. **Function Names**: Created wrapper header to map quicui_* to shorebird_* functions

## Build Instructions

To build the engine with QuicUI enabled:

```bash
export PATH="/path/to/depot_tools:$PATH"
cd /path/to/engine/src

# Configure
./flutter/tools/gn --runtime-mode=release --ios --gn-args='quicui_enabled=true'

# Build
ninja -C out/ios_release
```

## Dependencies

### Updater Library
The updater library must be cloned to `third_party/updater/`:
```bash
cd third_party
git clone https://github.com/shorebirdtech/updater.git
cd updater
git checkout 78c84e5bf72266da07df536e98d431782cb39a6d
```

## Testing

After building, verify QuicUI symbols are present:
```bash
nm out/ios_release/Flutter.framework/Flutter | grep -i quicui
```

Expected output should include:
- `QuicUICodePushLoader` class symbols
- QuicUI-related function symbols

## Integration

To use this engine in a Flutter app:
```bash
# Copy to local Flutter installation
cp -r out/ios_release/Flutter.framework \
  ~/flutter/bin/cache/artifacts/engine/ios-release/

# Or use --local-engine flag
flutter run --local-engine=ios_release \
  --local-engine-src-path=/path/to/engine/src
```

## References

- Build Success: `../BUILD_SUCCESS.md`
- Implementation Plan: `../IOS_INTERPRETER_IMPLEMENTATION_PLAN.md`
- Engine Modifications: `../ENGINE_MODIFICATIONS_COMPLETE.md`
