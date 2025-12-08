// Copyright (c) 2025 QuicUI Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef RUNTIME_VM_QUICUI_QUICUI_H_
#define RUNTIME_VM_QUICUI_QUICUI_H_

#include "platform/globals.h"
#include "include/dart_api.h"

// QuicUI Code Push Module
//
// This module provides iOS code push functionality for Flutter apps.
// It works by:
// 1. Linking AOT snapshots to identify identical vs changed functions
// 2. Running identical functions natively from the signed IPA
// 3. Interpreting changed functions from downloaded patches
//
// The result is typically 98%+ of code running at native speed,
// with only changed code being interpreted.

namespace dart {
namespace quicui {

// Check if QuicUI code push is enabled for this build
bool IsEnabled();

// Initialize QuicUI code push system
void Initialize();

// Shutdown QuicUI code push system
void Shutdown();

// Print debug info
void PrintInfo();

// Check if a patch is currently loaded
bool HasPatch();

// Get the patch version (returns 0 if no patch)
intptr_t GetPatchVersion();

}  // namespace quicui
}  // namespace dart

// C API for FFI integration
extern "C" {

// Set base snapshots (from signed IPA)
DART_EXPORT void QuicUI_SetBaseSnapshots(const uint8_t* vm_data,
                                         intptr_t vm_data_size,
                                         const uint8_t* vm_instrs,
                                         intptr_t vm_instrs_size,
                                         const uint8_t* isolate_data,
                                         intptr_t isolate_data_size,
                                         const uint8_t* isolate_instrs,
                                         intptr_t isolate_instrs_size);

// Read link header from vmcode file
// Returns true if valid QuicUI vmcode format
DART_EXPORT bool QuicUI_ReadLinkHeader(const uint8_t* data,
                                       intptr_t data_size,
                                       intptr_t* header_size,
                                       intptr_t* link_data_offset);

// Get the base instructions table
DART_EXPORT const uint8_t* QuicUI_GetBaseInstructionsTable();
DART_EXPORT intptr_t QuicUI_GetBaseInstructionsTableSize();

// Check if QuicUI is initialized
DART_EXPORT bool QuicUI_IsInitialized();

// Get linking percentage (0.0-100.0)
DART_EXPORT double QuicUI_GetLinkPercentage();

// Print statistics to stdout (for debugging)
DART_EXPORT void QuicUI_PrintStats();

}  // extern "C"

#endif  // RUNTIME_VM_QUICUI_QUICUI_H_
