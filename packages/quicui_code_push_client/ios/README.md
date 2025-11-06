# QuicUI Code Push Client - iOS

iOS implementation of QuicUI Code Push client.

## Features

- ✅ Over-the-air code updates
- ✅ Binary diff patches (bsdiff)
- ✅ LZMA compression
- ✅ Patch validation (SHA-256, ELF verification)
- ✅ Automatic rollback on failure
- ✅ App Store compliant

## Requirements

- iOS 12.0+
- Swift 5.0+
- Flutter 2.0+

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  quicui_code_push_client: ^1.0.0
```

## iOS Setup

### 1. Update Podfile

No special configuration needed. Just run:

```bash
cd ios
pod install
```

### 2. Info.plist Configuration

Add QuicUI configuration to `ios/Runner/Info.plist`:

```xml
<key>QuicUICodePushEnabled</key>
<true/>
<key>QuicUIBackendURL</key>
<string>https://your-quicui-backend.com</string>
<key>QuicUIAppId</key>
<string>com.yourcompany.yourapp</string>
```

### 3. Permissions

No special permissions required. QuicUI stores patches in the app's document directory.

## Usage

See main README.md for Dart usage examples.

## Architecture

```
iOS App
├── FlutterEngine (Modified)
│   └── QuicUICodePushLoader.mm
│       └── Checks for patches on startup
├── QuicUICodePushPlugin.swift
│   ├── Downloads patches
│   └── Applies patches
└── BSDiffPatcher.swift
    └── Binary patch algorithm
```

## File Structure

```
ios/
├── Classes/
│   ├── QuicUICodePushPlugin.swift    # Method channel handler
│   ├── QuicUIPatcher.swift            # High-level patcher
│   └── BSDiffPatcher.swift            # bsdiff implementation
└── quicui_code_push_client.podspec
```

## Patch Storage

Patches are stored in:
```
NSDocumentDirectory/quicui_patches/
├── libapp.so           # Patched executable
├── libapp.so.sha256    # Checksum
└── patch_metadata.json # Metadata
```

## App Store Compliance

✅ **QuicUI is App Store compliant**

- Only updates Dart code (interpreted)
- No native code changes
- Bug fixes and minor updates only
- Follows Apple's guidelines (Section 3.3.2)

See `docs/2025-11-06/PLAY_STORE_COMPLIANCE.md` for details.

## Troubleshooting

### Patch not loading

1. Check logs: `[QuicUI]` prefix
2. Verify patch file exists: `NSDocumentDirectory/quicui_patches/libapp.so`
3. Check patch validation (checksum, ELF magic)
4. Ensure engine modification is applied

### Build errors

```bash
cd ios
rm -rf Pods Podfile.lock
pod install
```

### Runtime errors

Enable debug logging:
```swift
// In AppDelegate.swift
print("[QuicUI] Debug mode enabled")
```

## Performance

- Patch download: ~2-5 seconds (2MB patch)
- Patch application: ~3-5 seconds
- Patch validation: <1 second
- App restart required: Yes

## License

Commercial - See LICENSE file

## Support

- Email: support@quicui.com
- Docs: https://docs.quicui.com
- Issues: https://github.com/quicui/quicui/issues
