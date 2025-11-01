# QuicUI SDK Detection Implementation

## Overview
Automatic detection system to identify whether app is built with QuicUI fork or standard Flutter, enabling proper code push functionality.

## Changes Made

### Main Repository (quicui2)
**Commit:** `5302481` - feat: Implement automatic QuicUI SDK detection for code push client

#### Key Files Modified:
1. **BuildSDKInfo** (`packages/quicui_code_push_client/lib/src/constants/build_sdk_info.dart`)
   - Auto-detects SDK type by checking if FlutterVersion contains "quicui"
   - Reads Flutter version, Dart version, and channel from FlutterVersion
   - Returns `isQuicUI = true` only when built with QuicUI fork
   - No hardcoded dart-define flags or path-based detection

2. **_SDKInfoDetector** (`packages/quicui_code_push_client/lib/src/quicui_code_push.dart`)
   - Updated to use BuildSDKInfo instead of async SDKInfoService
   - Handles nullable Flutter version strings safely
   - Passes real SDK info to SDKInfo model

3. **Test App** (`test_apps/quicui_test_app_v1/lib/main.dart`)
   - Displays SDK detection status on screen
   - Shows "QuicUI (Custom Fork) ✅" or "Flutter (Standard) ❌"
   - Uses BuildSDKInfo for build-time detection

4. **Build Scripts**
   - `scripts/build_with_quicui_fork.sh` - Builds with QuicUI fork
   - `scripts/build_with_standard_flutter.sh` - Builds with standard Flutter
   - No dart-define flags or path checking needed

### QuicUI Fork (flutter-official)
**Commit:** `15f629c8e3f` - feat: Add QuicUI SDK identification and marker

#### Key Files Modified:
1. **FlutterVersion** (`packages/flutter/lib/src/services/flutter_version.dart`)
   - Modified version constant to append `• quicui` marker
   - Automatically identifies fork through version string
   - Non-breaking: standard Flutter doesn't have this marker
   - Example output: `3.38.0-1.0.pre-350 • quicui`

2. **Marker Files**
   - `.quicui_marker` - File-based marker in fork root
   - `packages/flutter/lib/src/quicui_sdk_marker.dart` - Dart marker constants

## Detection Logic

### How It Works:
```
1. App is built with Flutter SDK (QuicUI fork or standard)
2. FlutterVersion.version is compiled at build time
3. BuildSDKInfo reads FlutterVersion.version
4. If version string contains "quicui" → isQuicUI = true
5. If version string doesn't contain "quicui" → isQuicUI = false
```

### Why This Approach:

✅ **Automatic** - No manual dart-define flags needed
✅ **Non-Breaking** - Standard Flutter unaffected
✅ **Build-Time** - Works in mobile app (no runtime SDK queries)
✅ **Portable** - No path dependencies
✅ **Clear Intent** - Fork explicitly marks itself

## Testing

### QuicUI Fork Build:
```bash
cd /Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1
bash ../../scripts/build_with_quicui_fork.sh
# APK shows: QuicUI 3.38.0-1.0.pre-350 • quicui (user-branch)
```

### Standard Flutter Build:
```bash
cd /Users/admin/Documents/quicui2/test_apps/quicui_test_app_v1
bash ../../scripts/build_with_standard_flutter.sh
# APK shows: Flutter 3.35.7 (stable)
```

## Installation & Launch

```bash
bash /Users/admin/Documents/quicui2/scripts/install_and_launch.sh
```

This script:
1. Verifies Android SDK
2. Detects connected device
3. Installs APK (uninstalls previous version)
4. Launches app
5. Streams logs with QuicUI/patch filters

## Benefits for Code Push

1. **Patch Application** - Only applies patches on QuicUI fork (has kernel modifications)
2. **Safety** - Standard Flutter apps won't attempt patch application
3. **Auto-Detection** - No user configuration needed
4. **Compatibility** - Works with both SDK types transparently

## File Structure

```
Main Repo (quicui2):
├── packages/quicui_code_push_client/
│   ├── lib/src/constants/build_sdk_info.dart (Detection logic)
│   └── lib/src/quicui_code_push.dart (Uses BuildSDKInfo)
├── test_apps/quicui_test_app_v1/
│   └── lib/main.dart (Display SDK status)
└── scripts/
    ├── build_with_quicui_fork.sh
    └── build_with_standard_flutter.sh

Flutter Fork (flutter-official):
├── .quicui_marker (Marker file)
├── packages/flutter/lib/src/
│   ├── flutter_version.dart (Modified - appends "• quicui")
│   └── quicui_sdk_marker.dart (Marker constants)
```

## Commits

**Main Repository:**
- `5302481` - Implement automatic QuicUI SDK detection

**Flutter Fork:**
- `15f629c8e3f` - Add QuicUI SDK identification and marker

## Next Steps

1. Test on device with both build variants
2. Verify patch application only works with QuicUI fork
3. Integrate into Phase 5.5 patch testing workflow
4. Document for developers using the code push client
