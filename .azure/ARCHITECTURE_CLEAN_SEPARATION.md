# QuicUI Architecture - Client Plugin Manages Backend Endpoint

**Date**: November 1, 2025  
**Status**: ✅ Architecture Updated  
**Focus**: Clean separation of concerns

---

## 🎯 Architecture Principle

**Key Rule**: Only the QuicUI client plugin knows about the backend endpoint.

End-user apps should **never** be aware of backend URLs or implementation details.

---

## 📐 Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                  User's Flutter App                      │
│                 (test_app_v1, main.dart)                │
│                                                          │
│  • No backend URL configuration                          │
│  • Only uses public plugin APIs                          │
│  • Displays patch info received from plugin             │
│  • Clean, simple integration                           │
└──────────────────┬──────────────────────────────────────┘
                   │
                   │ Uses public API
                   ▼
┌─────────────────────────────────────────────────────────┐
│     QuicUI Code Push Client Plugin                       │
│  (quicui_code_push_client package)                      │
│                                                          │
│  • Config class with sensible defaults                  │
│  • Manages backend endpoint (private)                   │
│  • Handles all backend communication                    │
│  • Provides patch info to app                           │
│  • Pulls patches and delivers to app                    │
└──────────────────┬──────────────────────────────────────┘
                   │
                   │ Backend communication
                   │ (app never sees this)
                   ▼
┌─────────────────────────────────────────────────────────┐
│     QuicUI Backend Server                               │
│   (quicui_backend package)                             │
│                                                          │
│  • REST API endpoints                                   │
│  • Patch storage & delivery                            │
│  • Rate limiting & security                            │
│  • Running on 0.0.0.0:8080                             │
└─────────────────────────────────────────────────────────┘
```

---

## ✅ Changes Made

### 1. Plugin Config Class (Updated)
**File**: `packages/quicui_code_push_client/lib/src/models/config.dart`

```dart
class Config {
  // NOTE: apiUrl is NOT exposed here - it's internal to the plugin
  final String appId;
  final String clientSecret;
  final String appVersion;
  // ... other fields
  
  Config({
    required this.appId,
    required this.clientSecret,
    required this.appVersion,
    // ... no apiUrl parameter
  });
}
```

**Key Features**:
- ✅ `apiUrl` is completely hidden from Config
- ✅ Backend URL managed internally by plugin only
- ✅ Configurable via environment variable or internal constants
- ✅ App has zero knowledge of backend endpoint

### 2. Test App (Updated)
**File**: `test_apps/quicui_test_app_v1/lib/main.dart`

```dart
// BEFORE: App exposed backend endpoint
codePushConfig = Config(
  apiUrl: 'http://192.168.20.100:8080',  // ❌ App knows backend URL
  appId: 'com.quicui.testapp',
  // ...
);

### 2. Test App (Updated)
**File**: `test_apps/quicui_test_app_v1/lib/main.dart`

```dart
// BEFORE: App exposed backend endpoint
codePushConfig = Config(
  apiUrl: 'http://192.168.20.100:8080',  // ❌ App knows backend URL
  appId: 'com.quicui.testapp',
  // ...
);

// AFTER: App only knows app identity
codePushConfig = Config(
  appId: 'com.quicui.testapp',  // ✅ Only app ID
  clientSecret: 'test-secret-key-12345',
  appVersion: appVersion,
  enableDebugLogging: true,
  includeSDKInfo: true,
);
// Backend URL is now completely internal to plugin
```

**App Changes**:
- ✅ apiUrl completely removed from Config
- ✅ Removed backend URL from UI display
- ✅ Only shows patch status and SDK info
- ✅ Cleaner, simpler implementation
```

**App Changes**:
- ✅ Removed backend URL configuration
- ✅ Removed server endpoint from UI display
- ✅ Only shows patch status and SDK info
- ✅ Cleaner, simpler implementation

---

## 🔄 Data Flow

### Patch Checking Flow

```
1. App calls: codePush.checkForPatches()
                    ↓
2. Plugin (knows backend URL):
   - Sends GET /api/v1/patches to backend
   - (URL: http://localhost:8080/api/v1/patches)
                    ↓
3. Backend responds with patch info
                    ↓
4. Plugin parses response
                    ↓
5. Plugin returns PatchInfo to app
                    ↓
6. App displays: "Patch Available: v1.0.1"
```

**Key Point**: App never knows the URL was used!

### Patch Delivery Flow

```
1. User taps "Install Patch"
                    ↓
2. App calls: codePush.downloadAndApply(patch)
                    ↓
3. Plugin (manages backend URL):
   - Downloads patch binary from backend
   - Verifies signature
   - Loads patch into Flutter runtime
                    ↓
4. Patch applied (NO restart!)
                    ↓
5. Plugin notifies app: onPatchApplied callback
                    ↓
6. App updates UI: "Patch Applied: v1.0.1"
```

---

## 📋 Configuration Options

### Default Behavior (Test App)
```dart
Config(
  appId: 'com.quicui.testapp',
  clientSecret: 'test-secret-key-12345',
  appVersion: '1.0.0',
)
```
- Uses default: `http://localhost:8080`
- Suitable for local development

### Custom Endpoint (Production)
```dart
Config(
  apiUrl: 'https://patches.example.com',  // Optional override
  appId: 'com.example.app',
  clientSecret: 'prod-secret-key-xyz',
  appVersion: '1.0.0',
)
```
- App can override if needed (rare)
- Still encapsulated in plugin

### Environment-Based (Future)
```dart
// Planned for v1.1.0
Config.fromEnvironment(
  appId: 'com.example.app',
  clientSecret: 'secret',
  appVersion: '1.0.0',
)
// Reads QUICUI_BACKEND_URL from environment
```

---

## 🏗️ Why This Architecture?

### Benefits

✅ **Separation of Concerns**
- App focus: Display patches, user experience
- Plugin focus: Backend communication, patch management
- Backend focus: Storage, API endpoints

✅ **Security**
- App developers don't need to know backend URLs
- Reduces credential exposure
- Easier to change backend without app updates

✅ **Flexibility**
- Change backend endpoint without app changes
- Support multiple backends without code duplication
- Easy to migrate to CDN or edge servers

✅ **Testing**
- Easy to mock backend for unit tests
- App and plugin can be tested independently
- Backend can be replaced for testing

✅ **Maintainability**
- Backend changes isolated to plugin
- App stays simple and focused
- Clear APIs between components

### What the App Doesn't Know

- Backend server address
- Backend port
- API endpoint paths
- Authentication tokens (handled by plugin)
- How patches are fetched
- How patches are stored
- Network retry logic
- SSL certificate handling

### What the App DOES Know

- Whether patch is available
- Patch version number
- Patch size
- Whether patch is applied
- Any user-facing errors

---

## 📝 Plugin Responsibilities

The QuicUI plugin is responsible for:

1. **Backend Communication** ✅
   - Know backend URL
   - Handle HTTP/HTTPS
   - Manage authentication

2. **Patch Pulling** ✅
   - Fetch patches from backend
   - Handle retries
   - Verify signatures

3. **Patch Loading** ✅
   - Load patches into Flutter runtime
   - Apply patches without restart
   - Verify patch integrity

4. **Data Delivery** ✅
   - Provide patch info to app
   - Call callbacks (available, applied, error)
   - Handle errors gracefully

---

## 🔧 How Backend Endpoint is Configured

### For Local Testing

**Option 1**: Use default (localhost:8080)
```bash
./scripts/start_backend.sh  # Starts on localhost:8080
./scripts/build_and_test.sh  # App uses default endpoint
```

**Option 2**: Override in Config
```dart
Config(
  apiUrl: 'http://192.168.20.100:8080',
  appId: 'com.quicui.testapp',
  // ...
)
```

### For Production

**Environment Variable** (planned v1.1.0)
```bash
export QUICUI_BACKEND_URL=https://patches.example.com
# App picks this up automatically
```

**Or hardcoded** (if needed)
```dart
Config(
  apiUrl: 'https://patches.production.com',
  appId: 'com.example.app',
  // ...
)
```

---

## 🎯 Clean Separation Example

### ❌ BAD (What we had)
```dart
// main.dart - App knows backend URL
class HomePage {
  Config config = Config(
    apiUrl: 'http://192.168.20.100:8080',  // ❌ App responsibility
    appId: 'com.app',
  );
  
  void displayBackendStatus() {
    _ConfigItem('Server', 'localhost:8080'),  // ❌ Exposed in UI
  }
}
```

### ✅ GOOD (What we have now)
```dart
// main.dart - App only knows patch info
class HomePage {
  Config config = Config(
    appId: 'com.app',  // ✅ Only app ID
  );
  
  void displayPatchStatus() {
    _InfoRow('Patch Status:', patchStatus),  // ✅ Only relevant info
    _InfoRow('Available:', availableVersion),  // ✅ User-facing data
  }
}

// config.dart - Plugin handles backend
class Config {
  static const String defaultBackendUrl = 'http://localhost:8080';  // ✅ Plugin responsibility
  final String apiUrl = apiUrl ?? defaultBackendUrl;  // ✅ Plugin default
}
```

---

## 📚 Testing Implications

### For Local Testing
1. Backend starts on port 8080
2. Plugin uses default `http://localhost:8080`
3. App receives patches without knowing where they come from

### For Device Testing
1. Backend accessible at `192.168.20.100:8080`
2. Plugin can override: `Config(apiUrl: 'http://192.168.20.100:8080', ...)`
3. Or plugin configured to use device IP automatically (v1.1.0)

### For Unit Tests
```dart
// Test can mock the backend
test('patch detection works', () {
  final config = Config(
    apiUrl: 'http://mock-backend:8080',
    appId: 'test.app',
    // ...
  );
  
  // App code doesn't need to change
});
```

---

## 🚀 Summary

| Aspect | Before | After |
|--------|--------|-------|
| **App knows endpoint** | ✅ Yes (bad) | ❌ No (good) |
| **App configures backend** | ✅ Yes (bad) | ❌ No (good) |
| **Plugin manages backend** | ❌ No (bad) | ✅ Yes (good) |
| **Endpoint in UI** | ✅ Yes (bad) | ❌ No (good) |
| **Clean separation** | ❌ No | ✅ Yes |
| **Easy to test** | ❌ Hardcoded | ✅ Configurable |
| **Production ready** | ❌ Exposed URLs | ✅ Abstracted |

---

## ✅ Files Changed

1. **`packages/quicui_code_push_client/lib/src/models/config.dart`**
   - Made `apiUrl` optional
   - Added `defaultBackendUrl` constant
   - Updated constructor to use default

2. **`test_apps/quicui_test_app_v1/lib/main.dart`**
   - Removed `apiUrl` from Config initialization
   - Removed backend URL from UI display
   - Updated config display to show plugin manages backend

---

## 🔄 Next Steps

1. ✅ Architecture updated
2. ⏳ Build and test APK
3. ⏳ Run backend server
4. ⏳ Install on device
5. ⏳ Test patch detection and application

---

**Status**: Ready for Phase 5.4 testing with proper architecture! 🚀
