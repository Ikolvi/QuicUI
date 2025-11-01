# Flutter SDK Detection - QuicUI vs Standard

## Overview

The QuicUI Code Push plugin automatically detects whether the app is using:
- **QuicUI-modified Flutter SDK** (required for code push) ✅
- **Standard Flutter SDK** (code push disabled) ⚠️

## Detection Mechanism

### Android Side

**File**: `FlutterSdkDetector.kt`

```kotlin
object FlutterSdkDetector {
    fun isQuicUiFlutterSdk(): Boolean {
        try {
            // Try to load QuicUICodePushLoader class
            Class.forName("io.flutter.embedding.engine.loader.QuicUICodePushLoader")
            return true  // QuicUI SDK detected ✅
        } catch (e: ClassNotFoundException) {
            return false  // Standard SDK detected ⚠️
        }
    }
}
```

### Dart Side

**File**: `method_channel.dart`

```dart
static Future<bool> isQuicUiFlutterSdk() async {
  try {
    // Try to call a QuicUI-specific method
    await _channel.invokeMethod<bool>('hasPatch');
    return true;  // QuicUI SDK detected ✅
  } on PlatformException catch (e) {
    if (e.code == 'SDK_NOT_SUPPORTED') {
      return false;  // Standard SDK detected ⚠️
    }
    return true;
  }
}
```

## Behavior

### ✅ With QuicUI Flutter SDK

```dart
final codePush = QuicUICodePush(
  appId: 'com.example.app',
  clientSecret: 'secret',
  appVersion: '1.0.0',
);

await codePush.initialize();
// Output: (no warning)

final patch = await codePush.checkForUpdates();
await codePush.downloadAndInstall(patch);  // ✅ Works!
```

### ⚠️ With Standard Flutter SDK

```dart
final codePush = QuicUICodePush(
  appId: 'com.example.app',
  clientSecret: 'secret',
  appVersion: '1.0.0',
);

await codePush.initialize();
// Output:
// ⚠️  WARNING: QuicUI Code Push requires the modified Flutter SDK!
//    Standard Flutter SDK detected - Code Push features will be disabled.
//    See: https://github.com/Ikolvi/QuicUIFlutterSDK for installation.
//    Tag: quicui-v1.0.0-engine

final patch = await codePush.checkForUpdates();
await codePush.downloadAndInstall(patch);  // ❌ Fails with SDK_NOT_SUPPORTED
```

## Error Handling

When using standard SDK, platform channel methods return errors:

```dart
try {
  await CodePushMethodChannel.installPatch(...);
} on PlatformException catch (e) {
  if (e.code == 'SDK_NOT_SUPPORTED') {
    // Standard Flutter SDK - code push not available
    print('Error: ${e.message}');
    // Error: QuicUI Code Push requires the modified Flutter SDK. 
    //        See https://github.com/Ikolvi/QuicUIFlutterSDK for installation instructions.
    
    final details = e.details as Map<String, dynamic>;
    print('Is QuicUI SDK: ${details['isQuicUiSdk']}');  // false
    print('Repository: ${details['repository']}');
    print('Tag: ${details['tag']}');
  }
}
```

## Detection Points

### 1. Plugin Initialization
**When**: Plugin attaches to Flutter engine  
**Where**: `QuicuiCodePushClientPlugin.onAttachedToEngine()`  
**Action**: Logs warning if standard SDK detected

```kotlin
override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    if (!FlutterSdkDetector.isQuicUiFlutterSdk()) {
        Log.w("QuicuiCodePushClientPlugin", 
            "Code Push functionality disabled - QuicUI Flutter SDK not detected")
    }
    // Still register handler for graceful error responses
}
```

### 2. Client Initialization
**When**: `QuicUICodePush.initialize()` called  
**Where**: Dart client initialization  
**Action**: Prints warning to console

```dart
Future<void> initialize() async {
  final isQuicUiSdk = await CodePushMethodChannel.isQuicUiFlutterSdk();
  if (!isQuicUiSdk) {
    print('⚠️  WARNING: QuicUI Code Push requires the modified Flutter SDK!');
    // ... more details ...
  }
}
```

### 3. Method Execution
**When**: Any platform channel method called  
**Where**: `CodePushMethodHandler.checkQuicUiSdk()`  
**Action**: Returns error via result channel

```kotlin
private fun checkQuicUiSdk(result: MethodChannel.Result): Boolean {
    if (!FlutterSdkDetector.isQuicUiFlutterSdk()) {
        result.error(
            "SDK_NOT_SUPPORTED",
            "QuicUI Code Push requires the modified Flutter SDK...",
            FlutterSdkDetector.getSdkInfo()
        )
        return false
    }
    return true
}
```

## User Experience

### Development Workflow

1. **Developer installs plugin**
   ```yaml
   dependencies:
     quicui_code_push_client: ^0.1.0
   ```

2. **Developer runs app with standard SDK**
   ```bash
   flutter run
   ```
   
   Console output:
   ```
   ⚠️  WARNING: QuicUI Code Push requires the modified Flutter SDK!
      Standard Flutter SDK detected - Code Push features will be disabled.
      See: https://github.com/Ikolvi/QuicUIFlutterSDK for installation.
      Tag: quicui-v1.0.0-engine
   ```

3. **Developer installs QuicUI SDK**
   ```bash
   git clone https://github.com/Ikolvi/QuicUIFlutterSDK
   cd QuicUIFlutterSDK
   git checkout quicui-v1.0.0-engine
   export PATH="$(pwd)/bin:$PATH"
   ```

4. **Developer rebuilds app**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```
   
   Console output:
   ```
   ✅ QuicUI Flutter SDK detected - Code Push enabled
   ```

## SDK Information API

### Dart

```dart
// Check if QuicUI SDK is available
final isQuicUi = await CodePushMethodChannel.isQuicUiFlutterSdk();
print('QuicUI SDK: $isQuicUi');

// Get detailed SDK info
final sdkInfo = await CodePushMethodChannel.getSdkInfo();
print('SDK Info: $sdkInfo');
// Output: {
//   isQuicUiSdk: true,
//   repository: https://github.com/Ikolvi/QuicUIFlutterSDK,
//   tag: quicui-v1.0.0-engine,
//   platform: android
// }
```

### Kotlin

```kotlin
// Check SDK
val isQuicUi = FlutterSdkDetector.isQuicUiFlutterSdk()
Log.i(TAG, "QuicUI SDK: $isQuicUi")

// Get SDK info
val sdkInfo = FlutterSdkDetector.getSdkInfo()
Log.i(TAG, "SDK Info: $sdkInfo")
// Output: {
//   isQuicUiSdk=true,
//   requiredClass=io.flutter.embedding.engine.loader.QuicUICodePushLoader,
//   repository=https://github.com/Ikolvi/QuicUIFlutterSDK,
//   tag=quicui-v1.0.0-engine
// }
```

## Benefits

1. **Early Detection**: Warns at plugin initialization
2. **Graceful Degradation**: Plugin works without crashing
3. **Clear Guidance**: Provides installation instructions
4. **Easy Debugging**: SDK info API for troubleshooting
5. **No False Positives**: Caches detection result for performance

## Testing

### Test with Standard SDK
```bash
# Use system Flutter
which flutter
# /usr/local/bin/flutter (standard)

flutter run
# Should see warning about SDK
```

### Test with QuicUI SDK
```bash
# Use QuicUI Flutter
export PATH="/path/to/QuicUIFlutterSDK/bin:$PATH"
which flutter
# /path/to/QuicUIFlutterSDK/bin/flutter

flutter run
# Should see "Code Push enabled"
```

## Summary

The detection mechanism ensures:
- ✅ Clear feedback when wrong SDK is used
- ✅ Helpful installation instructions
- ✅ No crashes or confusing errors
- ✅ Graceful degradation
- ✅ Easy debugging and troubleshooting
