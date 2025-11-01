# SDK Info Detection Implementation Plan

## Objective
Add functionality to the QuicUI Code Push Client to detect and report whether the app is using the custom QuicUI Flutter SDK or the standard Flutter SDK.

## Architecture

### Current State
- QuicUI Code Push Client: Pure Dart package
- Custom Flutter SDK: Located at `forks/flutter-official` with tag `v3.35.7-quicui-0.9.0`
- Test App: Running on Android with custom SDK enabled

### Desired State
- SDK detection class to identify Flutter SDK type
- Methods to get SDK version, branch, and custom modifications
- Integration with Config class for SDK reporting
- Display SDK info in test app UI

## Implementation Plan

### Phase 1: Create SDK Detection Service

#### File: `lib/src/services/sdk_info_service.dart`

**Purpose:** Detect and report SDK information

**Methods:**
1. `Future<String> getFlutterSDKVersion()` - Get Flutter SDK version
2. `Future<String> getFlutterSDKChannel()` - Get Flutter channel (stable, dev, custom, etc.)
3. `Future<String> getDartSDKVersion()` - Get Dart SDK version
4. `Future<bool> isQuicUISDK()` - Detect if using QuicUI custom SDK
5. `Future<String> getSDKBranch()` - Get Git branch (if available)
6. `Future<String> getSDKCommitHash()` - Get Git commit hash (if available)
7. `Future<Map<String, String>> getFullSDKInfo()` - Get all SDK information

**Detection Logic:**
- Check Flutter version string for "QuicUI" or custom markers
- Check for custom patch loading support in SDK
- Parse version number to detect fork version
- Query platform-specific SDK info via method channels (if needed)

### Phase 2: Update Config Model

#### File: `lib/src/models/config.dart`

**Changes:**
1. Add optional `includeSDKInfo` boolean parameter (default: true)
2. Add `sdkInfo` field to store detected SDK information
3. Add `getSDKInfo()` method to Config class
4. Update toString() to include SDK info when available

### Phase 3: Create SDK Info Model

#### File: `lib/src/models/sdk_info.dart` (New)

**Class: SDKInfo**
```dart
class SDKInfo {
  final String flutterVersion;
  final String dartVersion;
  final String channel;
  final bool isQuicUI;
  final String? branch;
  final String? commitHash;
  final Map<String, String> customProperties;
  
  // Methods for reporting
  String toReport();
  Map<String, dynamic> toJson();
}
```

### Phase 4: Update Main Library Export

#### File: `lib/quicui_code_push_client.dart`

**Changes:**
- Export new `sdk_info_service.dart`
- Export new `SDKInfo` model

### Phase 5: Integration with Test App

#### File: Test App's `lib/main.dart`

**Changes:**
1. Use `SDKInfoService` to get SDK information
2. Display SDK info in UI
3. Show custom markers if QuicUI SDK is detected
4. Display version details

## Implementation Steps

### Step 1: Create SDK Info Service
- [ ] Create `lib/src/services/sdk_info_service.dart`
- [ ] Implement all detection methods
- [ ] Add error handling for missing SDK info

### Step 2: Create SDK Info Model
- [ ] Create `lib/src/models/sdk_info.dart`
- [ ] Implement JSON serialization
- [ ] Add toString() and toReport() methods

### Step 3: Update Config
- [ ] Add SDK info fields to Config
- [ ] Update Config constructor
- [ ] Update Config toString()

### Step 4: Update Exports
- [ ] Update `lib/quicui_code_push_client.dart`
- [ ] Ensure all new classes are exported

### Step 5: Update Test App
- [ ] Import new SDK info service
- [ ] Display SDK information in UI
- [ ] Show visual indicator for QuicUI SDK

### Step 6: Testing
- [ ] Run on device with custom SDK
- [ ] Verify SDK detection works
- [ ] Check all SDK info displays correctly
- [ ] Run on device with standard SDK (if possible)
- [ ] Verify fallback behavior

## Expected Output Format

### Terminal Output
```
Flutter SDK Info:
├─ Version: 3.38.0-1.0.pre-350
├─ Channel: [user-branch]
├─ Dart: 3.11.0
├─ QuicUI Custom: ✅ YES
├─ Branch: quicui/main
└─ Commit: c1fc29fea9a

App Config:
├─ App ID: com.quicui.testapp
├─ API URL: http://localhost:8080
├─ App Version: 1.0.0
└─ SDK: QuicUI Fork v3.35.7-0.9.0
```

### UI Display
```
┌─────────────────────────┐
│  QuicUI Code Push Test  │
├─────────────────────────┤
│                         │
│ Welcome to QuicUI       │
│ Code Push               │
│                         │
│ App Version: 1.0.0      │
│ Patch Status: Ready     │
│                         │
│ [Check for Patches]     │
│                         │
│ ✅ Using QuicUI SDK     │
│ Version: 3.38.0-pre     │
│                         │
└─────────────────────────┘
```

## Files to Create/Modify

### New Files
1. `packages/quicui_code_push_client/lib/src/services/sdk_info_service.dart`
2. `packages/quicui_code_push_client/lib/src/models/sdk_info.dart`

### Modified Files
1. `packages/quicui_code_push_client/lib/src/models/config.dart`
2. `packages/quicui_code_push_client/lib/quicui_code_push_client.dart`
3. `test_apps/quicui_test_app_v1/lib/main.dart`

## Success Criteria

✅ **Implementation Complete When:**
1. SDK detection service correctly identifies Flutter SDK type
2. QuicUI SDK is properly detected when running with custom fork
3. All SDK information is collected and available
4. Test app displays SDK info in UI
5. No runtime errors or crashes
6. Fallback to standard SDK info if custom detection unavailable
7. SDK info can be logged/reported to backend

## Dependencies

- `dart:async` - For async operations
- `dart:io` - For file/process access (if needed)
- No new external dependencies required

## Timeline

| Phase | Duration | Status |
|-------|----------|--------|
| 1. SDK Detection Service | 15 min | ⏳ |
| 2. SDK Info Model | 10 min | ⏳ |
| 3. Config Updates | 10 min | ⏳ |
| 4. Library Updates | 5 min | ⏳ |
| 5. Test App Integration | 10 min | ⏳ |
| 6. Testing & Verification | 10 min | ⏳ |
| **Total** | **~60 min** | ⏳ |

---

**Next Step:** Execute Phase 1 - Create SDK Detection Service
