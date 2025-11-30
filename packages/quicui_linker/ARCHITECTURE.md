# QuicUI Linker Architecture

This document explains the architecture of the QuicUI linker and how it relates to the Flutter engine.

## Overview

The QuicUI code push system requires two components:

1. **Dart CLI Tools** (this package) - Creates differential patches
2. **C++ Runtime** (in Flutter engine) - Applies patches at runtime

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         BUILD TIME (This Package)                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   baseline.app (iOS)         patch.aot (ELF)                            │
│   libapp.so (Android)            │                                       │
│         │                        │                                       │
│         ▼                        ▼                                       │
│   ┌─────────────┐         ┌─────────────┐                               │
│   │ MachoParser │         │  ElfParser  │                               │
│   │ (macho_     │         │ (elf_       │                               │
│   │  parser.dart│         │  parser.dart│                               │
│   └──────┬──────┘         └──────┬──────┘                               │
│          │                       │                                       │
│          ▼                       ▼                                       │
│   ┌──────────────────────────────────────┐                              │
│   │         SnapshotAnalyzer             │                              │
│   │      (snapshot_analyzer.dart)        │                              │
│   └──────────────────┬───────────────────┘                              │
│                      │                                                   │
│                      ▼                                                   │
│   ┌──────────────────────────────────────┐                              │
│   │         DifferentialLinker           │                              │
│   │    (differential_linker.dart)        │                              │
│   │                                       │                              │
│   │  ┌─────────────────────────────────┐ │                              │
│   │  │        LinkInfoGenerator        │ │                              │
│   │  │                                 │ │                              │
│   │  │  • ClassTableMapper            │ │                              │
│   │  │  • FieldTableMapper            │ │                              │
│   │  │  • DispatchTableMapper         │ │                              │
│   │  │  • ObjectPoolMapper            │ │                              │
│   │  └─────────────────────────────────┘ │                              │
│   └──────────────────┬───────────────────┘                              │
│                      │                                                   │
│                      ▼                                                   │
│   ┌──────────────────────────────────────┐                              │
│   │          VmcodeGenerator             │                              │
│   │      (vmcode_generator.dart)         │                              │
│   │                                       │                              │
│   │  Creates .vmcode file:               │                              │
│   │  ┌─────────────────────────────────┐ │                              │
│   │  │ 64KB Header                     │ │                              │
│   │  │  • Magic: "QUIC"                │ │                              │
│   │  │  • Version, Flags               │ │                              │
│   │  │  • LinkInfo (class/field maps)  │ │                              │
│   │  │  • ELF offset/size              │ │                              │
│   │  ├─────────────────────────────────┤ │                              │
│   │  │ ELF Payload                     │ │                              │
│   │  │  • Dart AOT snapshot            │ │                              │
│   │  └─────────────────────────────────┘ │                              │
│   └──────────────────────────────────────┘                              │
│                      │                                                   │
│                      ▼                                                   │
│                 patch.vmcode                                             │
│                      │                                                   │
└──────────────────────┼───────────────────────────────────────────────────┘
                       │
                       │ (Downloaded to device)
                       ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      RUNTIME (In Flutter Engine)                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   ┌──────────────────────────────────────┐                              │
│   │     QuicuiLinker (C++)               │                              │
│   │  (runtime/vm/quicui/linker.cc)       │                              │
│   │                                       │                              │
│   │  • SetBaseSnapshots()                │  ← Called on app start       │
│   │  • LinkPatch(vmcode_data)            │  ← Called when patch ready   │
│   │  • GetLinkPercentage()               │  ← Progress callback         │
│   │                                       │                              │
│   │  Uses LinkInfo to remap:             │                              │
│   │  • Class IDs                         │                              │
│   │  • Field offsets                     │                              │
│   │  • Dispatch table entries            │                              │
│   │  • Object pool indices               │                              │
│   └──────────────────┬───────────────────┘                              │
│                      │                                                   │
│                      ▼                                                   │
│   ┌──────────────────────────────────────┐                              │
│   │     WrapperAllocator (C++)           │                              │
│   │  (runtime/vm/quicui/wrapper_         │                              │
│   │   allocator.cc)                      │                              │
│   │                                       │                              │
│   │  Handles CPU ↔ Interpreter           │                              │
│   │  transitions for iOS                 │                              │
│   └──────────────────────────────────────┘                              │
│                      │                                                   │
│                      ▼                                                   │
│   ┌──────────────────────────────────────┐                              │
│   │         Dart VM                       │                              │
│   │  (runtime/vm/)                        │                              │
│   │                                       │                              │
│   │  Executes patched code using         │                              │
│   │  interpreter when needed             │                              │
│   └──────────────────────────────────────┘                              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## File Layout

### This Package (Dart - Separate Git Repo)

```
packages/quicui_linker/
├── lib/
│   ├── quicui_linker.dart          # Library exports
│   └── src/
│       ├── elf_parser.dart          # Parse ELF files (Android, patches)
│       ├── macho_parser.dart        # Parse Mach-O files (iOS apps)
│       ├── snapshot_analyzer.dart   # Compare baseline/patch snapshots
│       ├── differential_linker.dart # Generate differential patches
│       ├── link_info.dart           # Link table data structures
│       ├── table_mappers.dart       # Generate class/field/dispatch maps
│       └── vmcode_generator.dart    # Create .vmcode files
├── bin/
│   └── link.dart                    # CLI tool
└── pubspec.yaml
```

### Flutter Engine (C++ - In Engine Build)

```
flutter/third_party/dart/runtime/vm/quicui/
├── BUILD.gn                         # Build configuration
├── quicui.h                         # Public API (C exports)
├── quicui.cc                        # API implementation
├── linker.h                         # QuicuiLinker class
├── linker.cc                        # Linker implementation
├── link_info.h                      # LinkInfo C++ structures
├── link_info.cc                     # Link info parsing
├── wrapper_allocator.h              # CPU/Interpreter transitions
└── wrapper_allocator.cc             # Wrapper implementation
```

## Why Split Architecture?

### Dart Tools (This Package) - CAN be separate

✅ Easy to maintain as separate git repo
✅ Can update without rebuilding Flutter engine
✅ Standard Dart package, easy to test
✅ No complex build dependencies

Includes:
- File parsers (ELF, Mach-O)
- Snapshot analysis
- Link info generation
- .vmcode file creation

### C++ Runtime (Engine) - MUST be in engine

⚠️ Must be compiled into Flutter engine
⚠️ Requires engine rebuild for changes
⚠️ Access to Dart VM internals

Includes:
- Runtime linking (applying patches)
- Memory management (WrapperAllocator)
- VM integration (class table, dispatch table)

## vmcode File Format

```
Offset  Size    Description
──────  ────    ───────────
0       4       Magic: "QUIC" (0x51 0x55 0x49 0x43)
4       4       Version (currently 1)
8       4       Flags (bit 0: hasLinkInfo, bit 1: compressed, bit 2: signed)
12      4       Link info offset (typically 256)
16      4       Link info size
20      8       ELF offset (65536)
28      8       ELF size
36      4       Checksum
40-255  -       Reserved
256     varies  Link info data (if present)
...     -       Padding to 64KB
65536   varies  ELF payload (Dart AOT snapshot)
```

## Link Info Format

```
Offset  Size    Description
──────  ────    ───────────
0       4       Version
4       4       Class table entry count
8       4       Field table entry count
12      4       Dispatch table entry count
16      4       Object pool entry count
20      8*N     Class table entries (patchId, baselineId)
...     12*N    Field table entries (patchOffset, baselineOffset, classId)
...     12*N    Dispatch table entries (patchIndex, baselineIndex, selectorId)
...     12*N    Object pool entries (patchIndex, baselineIndex, type)
```

## Building

### Dart Package (This Repo)

```bash
cd packages/quicui_linker
dart pub get
dart analyze
dart test
```

### Flutter Engine

```bash
# After copying C++ files to engine
cd engine/src
./flutter/tools/gn --ios --runtime-mode=release
ninja -C out/ios_release
```

## Usage

```bash
# Generate a patch
dart packages/quicui_linker/bin/link.dart \
  baseline.app/Frameworks/App.framework/App \
  build/patch.aot \
  output/patch.vmcode

# With analysis
dart packages/quicui_linker/bin/link.dart \
  baseline.app \
  patch.aot \
  patch.vmcode \
  --analyze
```

## Integration

The QuicUI client downloads patches and the engine applies them:

```dart
// In Flutter app
import 'package:quicui_client/quicui_client.dart';

void main() async {
  await QuicuiClient.initialize();
  
  // Check for updates
  final update = await QuicuiClient.checkForUpdate();
  if (update != null) {
    await QuicuiClient.applyUpdate(update);
  }
  
  runApp(MyApp());
}
```

The client calls native code that invokes `QuicUI_LinkPatch()` from the engine.
