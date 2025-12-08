# QuicUI Engine Modifications - Git Commit Plan

## Overview

This document provides a comprehensive plan for committing all QuicUI code push modifications to version control. These changes enable iOS and Android over-the-air code push updates by modifying the Flutter Engine and Dart VM.

**Engine Source Location:** `/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/`  
**Flutter SDK Version:** 3.38.1  
**Dart SDK Version:** 3.10.0  

---

## Repository Structure

The modifications span **two separate Git repositories**:

| Repository | Path | Base Tag |
|------------|------|----------|
| Flutter Engine | `engine/src/flutter/` | `3.38.1` (stable) |
| Dart SDK | `engine/src/flutter/third_party/dart/` | `3.10.0` (lkgr-stable) |

**Note:** The Dart SDK is a submodule/separate repo within the Flutter engine tree.

---

## Complete File Inventory

### 1. Flutter Engine - NEW Files (Untracked)

These files were **created from scratch** for QuicUI:

```
# Build Configuration
build/quicui.gni                                         # QuicUI GN configuration

# Common Shell - Patch Loader
shell/common/quicui_patch_loader.h                       # Patch loader header
shell/common/quicui_patch_loader.cc                      # Patch loader implementation

# Common Shell - QuicUI Module
shell/common/quicui/BUILD.gn                             # Build configuration
shell/common/quicui/quicui.cc                            # Main QuicUI implementation
shell/common/quicui/quicui.h                             # QuicUI header
shell/common/quicui/quicui_updater.h                     # Updater interface
shell/common/quicui/snapshots_data_handle.cc             # Snapshot handling
shell/common/quicui/snapshots_data_handle.h              # Snapshot header
shell/common/quicui/snapshots_data_handle_unittests.cc   # Unit tests

# Android Platform
shell/platform/android/quicui_patch_loader_jni.cc        # JNI bridge
shell/platform/android/io/flutter/embedding/engine/loader/QuicUICodePushLoader.java  # Java loader

# iOS Platform
shell/platform/darwin/ios/framework/Source/QuicUICodePushLoader.h   # iOS loader header
shell/platform/darwin/ios/framework/Source/QuicUICodePushLoader.mm  # iOS loader impl
```

### 2. Flutter Engine - MODIFIED Files

These existing Flutter engine files were **modified** to integrate QuicUI:

```
# Configuration
common/config.gni                                        # Added QuicUI flags

# Runtime
runtime/dart_snapshot.cc                                 # Modified for patch loading
runtime/dart_snapshot.h                                  # Added QuicUI methods

# Shell Common
shell/common/BUILD.gn                                    # Added QuicUI sources

# Android Platform
shell/platform/android/BUILD.gn                          # Added QuicUI JNI
shell/platform/android/flutter_main.cc                   # Initialize QuicUI
shell/platform/android/flutter_main.h                    # QuicUI initialization
shell/platform/android/io/flutter/embedding/engine/loader/FlutterLoader.java  # Load patches

# iOS Platform
shell/platform/darwin/ios/BUILD.gn                       # Added QuicUI sources
shell/platform/darwin/ios/framework/Source/FlutterDartProject.mm       # Patch integration
shell/platform/darwin/ios/framework/Source/FlutterDartProject_Internal.h  # Internal methods
shell/platform/darwin/ios/framework/Source/FlutterEngine.mm             # Engine integration
```

### 3. Dart VM - NEW Files (Untracked)

These files were **created from scratch** in the Dart VM for QuicUI linker support:

```
# QuicUI Module
runtime/vm/quicui/dispatch_patcher.h                     # Dispatch table patcher
runtime/vm/quicui/interpreter.cc                         # Interpreter modifications
runtime/vm/quicui/link_info_extractor.cc                 # Link info extraction
runtime/vm/quicui/quicui_sources.gni                     # GN sources list
runtime/vm/quicui/vmcode_reader.cc                       # .vmcode file reader
runtime/vm/quicui/vmcode_reader.h                        # Reader header
runtime/vm/quicui/wrapper.cc                             # Function wrapper
runtime/vm/quicui/wrapper.h                              # Wrapper header
```

### 4. Dart VM - MODIFIED Files

These existing Dart VM files were **modified** to integrate QuicUI linker:

```
# Build Configuration
runtime/vm/BUILD.gn                                      # Added quicui module
runtime/vm/vm_sources.gni                                # Added quicui sources

# Core VM Files
runtime/vm/stub_code_list.h                              # Added QuicUI stub codes
runtime/vm/thread.h                                      # Thread-local QuicUI state

# Compiler - Runtime API
runtime/vm/compiler/runtime_api.h                        # QuicUI runtime API
runtime/vm/compiler/runtime_offsets_extracted.h          # Extracted offsets
runtime/vm/compiler/runtime_offsets_list.h               # Offset definitions

# Compiler - Stub Code (Architecture-Specific)
runtime/vm/compiler/stub_code_compiler_arm.cc            # ARM stub code
runtime/vm/compiler/stub_code_compiler_arm64.cc          # ARM64 stub code
runtime/vm/compiler/stub_code_compiler_ia32.cc           # x86 stub code
runtime/vm/compiler/stub_code_compiler_riscv.cc          # RISC-V stub code
runtime/vm/compiler/stub_code_compiler_x64.cc            # x64 stub code

# QuicUI Module (Already tracked but modified)
runtime/vm/quicui/BUILD.gn                               # QuicUI build
runtime/vm/quicui/link_info.cc                           # Link info implementation
runtime/vm/quicui/link_info.h                            # Link info header
runtime/vm/quicui/linker.cc                              # Linker implementation
runtime/vm/quicui/linker.h                               # Linker header
runtime/vm/quicui/quicui.cc                              # Main QuicUI code
runtime/vm/quicui/quicui.h                               # QuicUI header
runtime/vm/quicui/wrapper_allocator.cc                   # Wrapper allocator
```

---

## Git Commit Strategy

### Phase 1: Create Branches

```bash
# Flutter Engine - Create QuicUI branch
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter
git checkout -b quicui-code-push-3.38.1 3.38.1

# Dart VM - Create QuicUI branch (already exists as quicui-linker)
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/third_party/dart
git checkout quicui-linker  # Already on this branch
```

### Phase 2: Commit Dart VM Changes (First - Dependencies)

The Dart VM must be committed first since the Flutter engine depends on it.

```bash
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/third_party/dart

# Commit 1: QuicUI Linker Core Module
git add runtime/vm/quicui/BUILD.gn
git add runtime/vm/quicui/quicui_sources.gni
git add runtime/vm/quicui/quicui.cc
git add runtime/vm/quicui/quicui.h
git add runtime/vm/quicui/link_info.cc
git add runtime/vm/quicui/link_info.h
git add runtime/vm/quicui/linker.cc
git add runtime/vm/quicui/linker.h
git commit -m "feat(quicui): Add QuicUI linker core module

- Add link info parser for .vmcode format
- Add linker for runtime function linking
- Add quicui.cc/h as main entry point
- Supports 64KB header with QUIC magic and link tables"

# Commit 2: VMCode Reader and Wrapper
git add runtime/vm/quicui/vmcode_reader.cc
git add runtime/vm/quicui/vmcode_reader.h
git add runtime/vm/quicui/wrapper.cc
git add runtime/vm/quicui/wrapper.h
git add runtime/vm/quicui/wrapper_allocator.cc
git commit -m "feat(quicui): Add vmcode reader and function wrapper

- VMCode reader parses .vmcode files with link info + ELF payload
- Wrapper handles function trampoline generation
- Wrapper allocator manages memory for linked code"

# Commit 3: Interpreter and Dispatch Patcher
git add runtime/vm/quicui/interpreter.cc
git add runtime/vm/quicui/dispatch_patcher.h
git add runtime/vm/quicui/link_info_extractor.cc
git commit -m "feat(quicui): Add interpreter and dispatch patcher

- Interpreter modifications for QuicUI dispatch
- Dispatch patcher for runtime function patching
- Link info extractor for build-time data extraction"

# Commit 4: VM Core Integration
git add runtime/vm/BUILD.gn
git add runtime/vm/vm_sources.gni
git add runtime/vm/stub_code_list.h
git add runtime/vm/thread.h
git commit -m "feat(quicui): Integrate QuicUI into Dart VM core

- Add quicui module to BUILD.gn
- Add quicui sources to vm_sources.gni
- Add QuicUI stub codes to stub_code_list.h
- Add QuicUI thread-local state to thread.h"

# Commit 5: Compiler Modifications
git add runtime/vm/compiler/runtime_api.h
git add runtime/vm/compiler/runtime_offsets_extracted.h
git add runtime/vm/compiler/runtime_offsets_list.h
git add runtime/vm/compiler/stub_code_compiler_arm.cc
git add runtime/vm/compiler/stub_code_compiler_arm64.cc
git add runtime/vm/compiler/stub_code_compiler_ia32.cc
git add runtime/vm/compiler/stub_code_compiler_riscv.cc
git add runtime/vm/compiler/stub_code_compiler_x64.cc
git commit -m "feat(quicui): Add QuicUI compiler support for all architectures

- Add QuicUI runtime API definitions
- Add QuicUI offsets to runtime_offsets
- Add QuicUI stub code generators for:
  - ARM (32-bit mobile)
  - ARM64 (64-bit mobile/desktop)
  - IA32 (x86 desktop)
  - RISC-V (emerging architectures)
  - X64 (macOS, Linux, Windows)"
```

### Phase 3: Commit Flutter Engine Changes

```bash
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter

# Commit 1: Build Configuration
git add build/quicui.gni
git add common/config.gni
git commit -m "feat(quicui): Add QuicUI build configuration

- Add build/quicui.gni with QuicUI build flags
- Add QuicUI feature flags to common/config.gni"

# Commit 2: Shell Common - Patch Loader
git add shell/common/quicui_patch_loader.h
git add shell/common/quicui_patch_loader.cc
git add shell/common/BUILD.gn
git commit -m "feat(quicui): Add cross-platform patch loader

- Add QuicUI patch loader for hot-patching support
- Integrate into shell/common build"

# Commit 3: Shell Common - QuicUI Module
git add shell/common/quicui/BUILD.gn
git add shell/common/quicui/quicui.cc
git add shell/common/quicui/quicui.h
git add shell/common/quicui/quicui_updater.h
git add shell/common/quicui/snapshots_data_handle.cc
git add shell/common/quicui/snapshots_data_handle.h
git add shell/common/quicui/snapshots_data_handle_unittests.cc
git commit -m "feat(quicui): Add shell QuicUI module

- Add QuicUI updater interface
- Add snapshot data handle for patch management
- Add unit tests for snapshot handling"

# Commit 4: Runtime Integration
git add runtime/dart_snapshot.cc
git add runtime/dart_snapshot.h
git commit -m "feat(quicui): Integrate QuicUI with Dart snapshot loading

- Modify DartSnapshot to support QuicUI patches
- Add methods for patch application"

# Commit 5: Android Platform Integration
git add shell/platform/android/BUILD.gn
git add shell/platform/android/quicui_patch_loader_jni.cc
git add shell/platform/android/flutter_main.cc
git add shell/platform/android/flutter_main.h
git add shell/platform/android/io/flutter/embedding/engine/loader/FlutterLoader.java
git add shell/platform/android/io/flutter/embedding/engine/loader/QuicUICodePushLoader.java
git commit -m "feat(quicui): Add Android code push support

- Add QuicUI JNI bridge (quicui_patch_loader_jni.cc)
- Add QuicUICodePushLoader.java for patch management
- Modify FlutterLoader to check for patches
- Modify flutter_main for initialization"

# Commit 6: iOS Platform Integration
git add shell/platform/darwin/ios/BUILD.gn
git add shell/platform/darwin/ios/framework/Source/QuicUICodePushLoader.h
git add shell/platform/darwin/ios/framework/Source/QuicUICodePushLoader.mm
git add shell/platform/darwin/ios/framework/Source/FlutterDartProject.mm
git add shell/platform/darwin/ios/framework/Source/FlutterDartProject_Internal.h
git add shell/platform/darwin/ios/framework/Source/FlutterEngine.mm
git commit -m "feat(quicui): Add iOS code push support

- Add QuicUICodePushLoader Objective-C class
- Modify FlutterDartProject for patch integration
- Modify FlutterEngine to initialize QuicUI
- Update iOS BUILD.gn for new sources"
```

---

## Patch Generation for Future SDK Upgrades

### Option 1: Generate Git Patches

```bash
# Generate Dart VM patch
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/third_party/dart
git format-patch 3.10.0..HEAD --stdout > ~/quicui_dart_vm_patch_3.10.0.patch

# Generate Flutter Engine patch
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter
git format-patch 3.38.1..HEAD --stdout > ~/quicui_flutter_engine_patch_3.38.1.patch
```

### Option 2: Create Diff Files

```bash
# Dart VM diff (all changes)
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/third_party/dart
git diff 3.10.0 -- runtime/vm/ > ~/quicui_dart_vm_diff.patch

# Flutter Engine diff (all changes)
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter
git diff 3.38.1 -- build/ common/ runtime/ shell/ > ~/quicui_flutter_engine_diff.patch
```

### Option 3: Copy QuicUI-Only Directories (Recommended for NEW files)

```bash
# Archive new QuicUI directories for easy insertion
cd /Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter

# Dart VM QuicUI module
tar -czvf ~/quicui_dart_vm_module.tar.gz third_party/dart/runtime/vm/quicui/

# Flutter Engine QuicUI module  
tar -czvf ~/quicui_flutter_engine_module.tar.gz \
  build/quicui.gni \
  shell/common/quicui/ \
  shell/common/quicui_patch_loader.* \
  shell/platform/android/quicui_patch_loader_jni.cc \
  shell/platform/android/io/flutter/embedding/engine/loader/QuicUICodePushLoader.java \
  shell/platform/darwin/ios/framework/Source/QuicUICodePushLoader.*
```

---

## Applying Changes to New Flutter SDK

When a new Flutter SDK version is released (e.g., 3.39.0):

### Step 1: Sync New SDK
```bash
# Sync Flutter engine to new version
cd engine
gclient sync -D --revision flutter=3.39.0

# Navigate to engine source
cd src/flutter
```

### Step 2: Apply Dart VM Patch
```bash
cd third_party/dart

# Try to apply patch
git apply ~/quicui_dart_vm_patch_3.10.0.patch

# If conflicts occur, manually resolve or use 3-way merge
git apply --3way ~/quicui_dart_vm_patch_3.10.0.patch
```

### Step 3: Apply Flutter Engine Patch
```bash
cd ../../  # Back to flutter engine root

# Apply patch
git apply ~/quicui_flutter_engine_patch_3.38.1.patch

# If conflicts, use 3-way merge
git apply --3way ~/quicui_flutter_engine_patch_3.38.1.patch
```

### Step 4: Rebuild Engine
```bash
# iOS
./flutter/tools/gn --ios --runtime-mode release
ninja -C out/ios_release

# Android
./flutter/tools/gn --android --runtime-mode release
ninja -C out/android_release
```

---

## File Categories Summary

| Category | NEW Files | MODIFIED Files | Total |
|----------|-----------|----------------|-------|
| Flutter Engine - Build | 1 | 1 | 2 |
| Flutter Engine - Shell Common | 8 | 1 | 9 |
| Flutter Engine - Android | 2 | 4 | 6 |
| Flutter Engine - iOS | 2 | 4 | 6 |
| Flutter Engine - Runtime | 0 | 2 | 2 |
| Dart VM - QuicUI Module | 8 | 8 | 16 |
| Dart VM - Core | 0 | 4 | 4 |
| Dart VM - Compiler | 0 | 8 | 8 |
| **TOTAL** | **21** | **32** | **53** |

---

## Backup Files to Exclude

The following backup files should **NOT** be committed:

```
# Flutter Engine backups
shell/common/quicui_patch_loader.cc.backup*
shell/common/quicui_patch_loader.cc.bak
shell/common/quicui_patch_loader.h.backup*
shell/common/quicui_patch_loader.h.bak
shell/platform/darwin/ios/BUILD.gn.quicui_backup
shell/platform/darwin/ios/BUILD.gn.quicui_temp
shell/platform/darwin/ios/framework/Source/FlutterDartProject.mm.quicui_backup
shell/platform/darwin/ios/framework/Source/FlutterEngine.mm.quicui_backup

# Dart VM backups
runtime/vm/BUILD.gn.backup
runtime/vm/compiler/runtime_api.h.bak
runtime/vm/compiler/runtime_offsets_list.h.bak
runtime/vm/compiler/stub_code_compiler_arm64.cc.backup
runtime/vm/quicui/wrapper.cc.bak
runtime/vm/runtime_entry.cc.test
runtime/vm/stub_code_list.h.bak
runtime/vm/thread.h.bak*

# Python scripts (utility)
add_quicui_offsets.py
```

---

## Quick Commands Reference

```bash
# ============================================
# FLUTTER ENGINE
# ============================================
ENGINE_ROOT="/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter"

# Check status
cd "$ENGINE_ROOT" && git status --short | grep -E "quicui|QuicUI|patch_loader" | head -30

# List QuicUI files only
cd "$ENGINE_ROOT" && find . -name "*quicui*" -o -name "*QuicUI*" | grep -v ".backup" | grep -v ".bak"

# Create branch and commit all
cd "$ENGINE_ROOT" && git checkout -b quicui-3.38.1 && git add -A && git commit -m "QuicUI code push"

# ============================================
# DART VM
# ============================================
DART_ROOT="/Volumes/DoWonder2/quicui_engine_build/flutter_3.38.1/engine/src/flutter/third_party/dart"

# Check status
cd "$DART_ROOT" && git status --short runtime/vm/ | head -30

# List QuicUI module
cd "$DART_ROOT" && ls -la runtime/vm/quicui/

# Current branch (should be quicui-linker)
cd "$DART_ROOT" && git branch --show-current
```

---

## Version Information

- **Document Version:** 1.0.0
- **Created:** December 2024
- **Flutter SDK:** 3.38.1
- **Dart SDK:** 3.10.0
- **Target Platforms:** iOS (arm64), Android (arm64-v8a, armeabi-v7a)

---

## Related Documentation

- `/Users/admin/Documents/quicui2/docs/FLUTTER_MODIFICATIONS.md` - Original modification guide
- `/Users/admin/Documents/quicui2/docs/FLUTTERENGINE_IOS_MODIFICATIONS.md` - iOS-specific changes
- `/Users/admin/Documents/quicui2/docs/QUICUI_WORKING_SYSTEM_COMPLETE.md` - Working system overview
