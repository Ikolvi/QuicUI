# QuicUI iOS Test App

This is a placeholder directory for the iOS test app.

## Creating the Test App

Run these commands to create a full test app:

```bash
# Create Flutter app
flutter create quicui_ios_test

# Add QuicUI dependency
cd quicui_ios_test
flutter pub add quicui_code_push_client --path=../../packages/quicui_code_push_client

# Configure iOS
cd ios
pod install
```

## Directory Structure

After creation, the structure will be:

```
quicui_ios_test/
├── lib/
│   └── main.dart                 # Flutter app code
├── ios/
│   ├── Runner/
│   │   ├── AppDelegate.swift
│   │   └── Info.plist
│   ├── Podfile
│   └── Runner.xcworkspace
├── test/
└── pubspec.yaml
```

## Configuration

Add to `ios/Runner/Info.plist`:

```xml
<key>QuicUICodePushEnabled</key>
<true/>
<key>QuicUIBackendURL</key>
<string>http://localhost:8080</string>
<key>QuicUIAppId</key>
<string>quicui_ios_test</string>
```

## Building

```bash
# Build for release
flutter build ios --release --no-codesign

# Build for simulator
flutter build ios --simulator
```

## Testing

1. Build base version
2. Make code changes
3. Generate patch: `../../scripts/generate_patch_ios.sh`
4. Install app on device
5. Trigger update from app
6. Restart app to load patch

## Notes

- iOS simulator does not support AOT, use physical device
- Xcode 14+ required
- macOS 12+ required
- Apple Developer account needed for device deployment
