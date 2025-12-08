// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_QUICUI_QUICUI_UPDATER_H_
#define FLUTTER_SHELL_COMMON_QUICUI_QUICUI_UPDATER_H_

// QuicUI updater wrapper - maps QuicUI function names to underlying updater library
// The updater library uses "shorebird" prefixed names, but we wrap them with "quicui" names

#include "third_party/updater/library/include/updater.h"

// Map QuicUI function names to shorebird updater functions
#define quicui_init shorebird_init
#define quicui_should_auto_update shorebird_should_auto_update
#define quicui_current_boot_patch_number shorebird_current_boot_patch_number
#define quicui_next_boot_patch_number shorebird_next_boot_patch_number
#define quicui_next_boot_patch_path shorebird_next_boot_patch_path
#define quicui_free_string shorebird_free_string
#define quicui_free_update_result shorebird_free_update_result
#define quicui_check_for_update shorebird_check_for_update
#define quicui_update shorebird_update
#define quicui_start_update_thread shorebird_start_update_thread
#define quicui_report_launch_start shorebird_report_launch_start
#define quicui_report_launch_failure shorebird_report_launch_failure
#define quicui_report_launch_success shorebird_report_launch_success
#define QuicUI_SetBaseSnapshots Shorebird_SetBaseSnapshots

#endif  // FLUTTER_SHELL_COMMON_QUICUI_QUICUI_UPDATER_H_
