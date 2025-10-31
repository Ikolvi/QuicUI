# Multi-JSON Architecture Plan for QuicUI

## Overview
Enable QuicUI to load and manage multiple JSON files, each containing different screens/flows, with support for:
- Named custom callbacks
- Screen navigation between different JSON contexts
- Data passing between screens across multiple JSON files
- Dynamic JSON loading and caching

---

## Phase 1: Architecture Design

### 1.1 Core Concepts

**JSON Structure Hierarchy:**
```
QuicUI App
├── JSON File 1 (auth.json)
│   ├── login screen
│   ├── signup screen
│   └── forgot-password screen
├── JSON File 2 (dashboard.json)
│   ├── home screen
│   ├── profile screen
│   └── settings screen
└── JSON File 3 (tasks.json)
    ├── task-list screen
    ├── task-detail screen
    └── task-create screen
```

**Navigation Model:**
```
┌─────────────────────────────────┐
│ JSON Context Layer              │
│ - Manages which JSON is active  │
│ - Holds global app state        │
│ - Tracks navigation history     │
└─────────────────────────────────┘
         ↓
┌─────────────────────────────────┐
│ Screen Layer                    │
│ - Individual screens in JSON    │
│ - Local state management        │
└─────────────────────────────────┘
         ↓
┌─────────────────────────────────┐
│ Widget Rendering Layer          │
│ - UIRenderer (existing)         │
│ - Variable interpolation        │
└─────────────────────────────────┘
```

### 1.2 Data Flow

**Inter-JSON Navigation:**
```
JSON1 (auth.json)
  ↓ [Login successful, navigateToFlow('dashboard')]
  └→ Load JSON2 (dashboard.json) with data: {userId, token, username}
       ↓ [Click profile]
       └→ Screen in same JSON: renderWithData(navigationData)
            ↓ [Edit profile → Save]
            └→ navigateToFlow('settings', data) → Load JSON3 (settings.json)
```

---

## Phase 2: Implementation Architecture

### 2.1 New Classes and Services

#### A. JSONFlowManager (New Service)
**Purpose:** Central manager for multi-JSON flow orchestration

```dart
class JSONFlowManager {
  // Properties
  static final Map<String, dynamic> _loadedFlows = {}; // Cache
  late String _currentFlowId;
  late String _currentScreenId;
  Map<String, dynamic> _globalNavigationData = {};
  
  // Methods
  Future<void> initializeApp(String initialFlowId, String initialJson);
  Future<void> loadFlow(String flowId, String jsonPath);
  Future<Map<String, dynamic>> getFlow(String flowId);
  void navigateToScreen(String screenId, {Map<String, dynamic>? data});
  void navigateToFlow(String flowId, String screenId, {Map<String, dynamic>? data});
  void registerCallback(String callbackName, Function callback);
  dynamic executeCallback(String callbackName, {Map<String, dynamic>? data});
  Map<String, dynamic> getNavigationData();
  void updateNavigationData(Map<String, dynamic> data);
  String getCurrentFlowId();
  String getCurrentScreenId();
}
```

#### B. JSONLoader (New Service)
**Purpose:** Handle JSON loading, caching, and validation

```dart
class JSONLoader {
  // Methods
  static Future<Map<String, dynamic>> loadJsonFromAssets(String path);
  static Future<Map<String, dynamic>> loadJsonFromUrl(String url);
  static Future<Map<String, dynamic>> loadJsonFromFile(String filePath);
  static void cacheJson(String flowId, Map<String, dynamic> json);
  static Map<String, dynamic>? getCachedJson(String flowId);
  static void clearCache({String? flowId});
  static void preloadJsons(List<String> jsonPaths);
  static Map<String, dynamic> validateJsonStructure(Map<String, dynamic> json);
}
```

#### C. CallbackRegistry (New Service)
**Purpose:** Manage named callbacks with custom handlers

```dart
class CallbackRegistry {
  static final Map<String, dynamic> _registeredCallbacks = {};
  
  // Methods
  static void registerCallback(String name, dynamic callback);
  static dynamic getCallback(String name);
  static Future<dynamic> executeCallback(
    String name, 
    {Map<String, dynamic>? params}
  );
  static void unregisterCallback(String name);
  static List<String> getRegisteredCallbackNames();
  static bool isCallbackRegistered(String name);
}
```

#### D. NavigationDataManager (Enhancement)
**Purpose:** Extend existing to support cross-JSON data passing

```dart
class NavigationDataManager {
  static Map<String, dynamic> _sessionData = {};
  static Map<String, dynamic> _flowHistory = {};
  
  // Methods
  static void setSessionData(String key, dynamic value);
  static dynamic getSessionData(String key);
  static void mergeSessionData(Map<String, dynamic> data);
  static Map<String, dynamic> getFullSessionData();
  static void saveFlowState(String flowId, Map<String, dynamic> state);
  static Map<String, dynamic>? getFlowState(String flowId);
  static void clearFlowHistory({String? flowId});
}
```

### 2.2 Enhanced Main App Structure

**Updated main.dart:**
```dart
class QuicUIApp extends StatefulWidget {
  const QuicUIApp({
    required this.initialFlowId,
    required this.flowConfigs,
    this.globalCallbacks = const {},
    super.key,
  });

  final String initialFlowId;
  final Map<String, String> flowConfigs; // {flowId: jsonPath}
  final Map<String, dynamic> globalCallbacks;

  @override
  State<QuicUIApp> createState() => _QuicUIAppState();
}

class _QuicUIAppState extends State<QuicUIApp> {
  late JSONFlowManager _flowManager;
  
  @override
  void initState() {
    super.initState();
    _initializeFlowManager();
  }

  Future<void> _initializeFlowManager() async {
    _flowManager = JSONFlowManager();
    
    // Register global callbacks
    widget.globalCallbacks.forEach((name, callback) {
      CallbackRegistry.registerCallback(name, callback);
    });
    
    // Initialize with first flow
    await _flowManager.initializeApp(
      widget.initialFlowId,
      widget.flowConfigs[widget.initialFlowId]!,
    );
    
    // Preload other flows
    final otherFlows = widget.flowConfigs.entries
        .where((e) => e.key != widget.initialFlowId)
        .map((e) => e.value)
        .toList();
    await JSONLoader.preloadJsons(otherFlows);
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentFlowId = _flowManager.getCurrentFlowId();
    final currentScreenId = _flowManager.getCurrentScreenId();
    final flow = _flowManager.getFlow(currentFlowId);
    final screen = flow['screens']?[currentScreenId];
    
    if (screen == null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Screen not found')),
        ),
      );
    }

    final enhancedConfig = Map<String, dynamic>.from(screen);
    enhancedConfig['onNavigateTo'] = _onNavigate;
    enhancedConfig['navigationData'] = _flowManager.getNavigationData();

    return MaterialApp(
      title: flow['properties']?['title'] ?? 'QuicUI App',
      home: UIRenderer.render(enhancedConfig, context: context),
    );
  }

  void _onNavigate(String screenId, {Map<String, dynamic>? data}) {
    setState(() {
      _flowManager.navigateToScreen(screenId, data: data);
    });
  }
}
```

---

## Phase 3: JSON Configuration Formats

### 3.1 Base JSON Structure (Enhanced)

**auth.json:**
```json
{
  "type": "MaterialApp",
  "flowId": "auth",
  "properties": {
    "title": "Authentication Flow",
    "description": "Handles user authentication"
  },
  "globalCallbacks": {
    "onAuthSuccess": {
      "type": "navigateToFlow",
      "targetFlow": "dashboard",
      "targetScreen": "home",
      "passData": ["userId", "token", "username"]
    },
    "onSignupSuccess": {
      "type": "callback",
      "name": "customSignupHandler",
      "nextAction": {
        "type": "navigateToFlow",
        "targetFlow": "dashboard",
        "targetScreen": "onboarding"
      }
    }
  },
  "screens": {
    "login": {
      "type": "Scaffold",
      "children": [...]
    },
    "signup": {
      "type": "Scaffold",
      "children": [...]
    }
  }
}
```

**dashboard.json:**
```json
{
  "type": "MaterialApp",
  "flowId": "dashboard",
  "properties": {
    "title": "Dashboard",
    "requiresAuth": true
  },
  "screens": {
    "home": {
      "type": "Scaffold",
      "children": [
        {
          "type": "ElevatedButton",
          "properties": {
            "label": "Go to Settings",
            "events": {
              "onPressed": {
                "action": "navigateToFlow",
                "targetFlow": "settings",
                "targetScreen": "main",
                "data": {
                  "userId": "${navigationData.userId}",
                  "returnFlow": "dashboard",
                  "returnScreen": "home"
                }
              }
            }
          }
        }
      ]
    }
  }
}
```

### 3.2 Named Callback Pattern

**Callback Definition (in app code or JSON):**
```json
{
  "namedCallbacks": {
    "handleLoginSubmit": {
      "handler": "customLoginHandler",
      "onSuccess": {
        "action": "navigateToFlow",
        "targetFlow": "dashboard",
        "targetScreen": "home"
      },
      "onError": {
        "action": "showDialog",
        "message": "Login failed"
      }
    },
    "syncUserProfile": {
      "handler": "apiCall",
      "endpoint": "/api/user/profile",
      "method": "POST",
      "onSuccess": {
        "action": "updateNavigationData",
        "data": {
          "profile": "${responseData}"
        }
      }
    }
  }
}
```

### 3.3 Action Types for Cross-JSON Navigation

```json
{
  "actions": [
    {
      "type": "navigate",
      "screen": "otherScreen"  // Within same JSON
    },
    {
      "type": "navigateToFlow",
      "targetFlow": "dashboard",
      "targetScreen": "home",
      "data": {
        "userId": "${fields.userId}",
        "returnFlow": "auth",
        "returnScreen": "login"
      }
    },
    {
      "type": "executeCallback",
      "callbackName": "customHandler",
      "params": {
        "action": "logout"
      }
    },
    {
      "type": "updateNavigationData",
      "merge": true,
      "data": {
        "lastScreen": "${navigationData.currentScreen}",
        "timestamp": "computed"
      }
    },
    {
      "type": "goBack",
      "steps": 1,
      "clearData": false
    }
  ]
}
```

---

## Phase 4: Implementation Steps

### Step 1: Create Service Layer
1. Create `lib/src/services/json_flow_manager.dart`
2. Create `lib/src/services/json_loader.dart`
3. Create `lib/src/services/callback_registry.dart`
4. Create `lib/src/services/navigation_data_manager.dart`

**Files:**
- `quicui/lib/src/services/` (new directory)
  - `json_flow_manager.dart`
  - `json_loader.dart`
  - `callback_registry.dart`
  - `navigation_data_manager.dart`

### Step 2: Extend UIRenderer
1. Add support for new action types in `_handleCallback()`
2. Add `navigateToFlow` action handler
3. Add `executeCallback` action handler
4. Add `updateNavigationData` action handler
5. Add `goBack` action handler with history tracking

**Changes to:**
- `lib/src/rendering/ui_renderer.dart`

### Step 3: Update Main App
1. Refactor main.dart to use JSONFlowManager
2. Support flow configuration
3. Handle global callbacks registration
4. Implement flow preloading

**Files to modify:**
- `example/task_manager_runner/lib/main.dart`

### Step 4: Create Flow Config Files
1. Split single screens.json into multiple flows
2. Define callbacks and actions
3. Set up flow dependencies

**New files:**
```
example/task_manager_runner/assets/
├── flows/
│   ├── auth.json
│   ├── dashboard.json
│   ├── settings.json
│   └── tasks.json
└── flow_config.json (master config)
```

### Step 5: Update Documentation
1. Multi-JSON architecture guide
2. Flow configuration examples
3. Custom callback patterns
4. Data passing between JSONs
5. Error handling patterns

**New docs:**
- `docs/MULTI_JSON_FLOWS.md`
- `docs/CUSTOM_CALLBACKS.md`
- `docs/CROSS_JSON_NAVIGATION.md`

---

## Phase 5: Usage Examples

### Example 1: Basic Multi-Flow App

**flow_config.json:**
```json
{
  "initialFlow": "auth",
  "flows": {
    "auth": "assets/flows/auth.json",
    "dashboard": "assets/flows/dashboard.json",
    "settings": "assets/flows/settings.json"
  }
}
```

**main.dart:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final configJson = await rootBundle.loadString('assets/flow_config.json');
  final config = jsonDecode(configJson);
  
  runApp(
    QuicUIApp(
      initialFlowId: config['initialFlow'],
      flowConfigs: Map<String, String>.from(config['flows']),
      globalCallbacks: {
        'onLogout': _handleLogout,
        'onSessionExpired': _handleSessionExpired,
      },
    ),
  );
}

void _handleLogout() {
  // Navigate to auth flow
  // Clear session data
}

void _handleSessionExpired() {
  // Show dialog
  // Return to login
}
```

### Example 2: Named Callback Pattern

**Button Click → Custom Callback → Flow Navigation:**
```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Submit Profile",
    "events": {
      "onPressed": {
        "action": "executeCallback",
        "callbackName": "validateAndSubmitProfile",
        "params": {
          "data": {
            "name": "${fields.fullName}",
            "email": "${fields.email}",
            "bio": "${fields.bio}"
          }
        }
      }
    }
  }
}
```

**App code:**
```dart
CallbackRegistry.registerCallback(
  'validateAndSubmitProfile',
  (params) async {
    final data = params['data'] as Map;
    
    // Validation
    if (data['name'].isEmpty) {
      throw Exception('Name required');
    }
    
    // API call
    final result = await apiClient.updateProfile(data);
    
    // Navigate to next flow with result
    navigationManager.navigateToFlow(
      'dashboard',
      'profile',
      data: {'updatedProfile': result}
    );
  }
);
```

### Example 3: Data Passing Chain

**Flow: Auth → Dashboard → Settings → Profile**
```
login.json
  ↓ [Login] {userId, token}
  ├→ dashboard.json {userId, token, username}
      ├→ [Settings] {userId, token, username}
          └→ settings.json {userId, token, username, returnFlow}
               ├→ [Save] {userId, token, username, preferences}
               └→ Go back to {returnFlow, returnScreen}
```

---

## Phase 6: Advanced Features (Future)

### 6.1 Flow Middleware
```dart
class FlowMiddleware {
  Future<bool> beforeNavigateToFlow(String flowId, String screenId);
  Future<void> afterNavigateToFlow(String flowId, String screenId);
  Future<bool> beforeScreenRender(Map<String, dynamic> screenConfig);
}
```

### 6.2 Offline Support
- Cache JSON files locally
- Sync navigation history
- Persist flow state

### 6.3 Analytics Integration
- Track flow navigation
- Monitor callback execution
- Measure flow completion rates

### 6.4 Hot Reload for JSONs
- Update JSON without app restart
- Preserve navigation state
- Smooth transitions

### 6.5 Flow Validation & Testing
- JSON schema validation
- Flow dependency checker
- Navigation path testing

---

## Phase 7: Testing Strategy

### Unit Tests
```dart
// Test JSONLoader
test('loadJsonFromAssets loads valid JSON', () async {
  final json = await JSONLoader.loadJsonFromAssets('assets/auth.json');
  expect(json, isNotNull);
  expect(json['flowId'], equals('auth'));
});

// Test CallbackRegistry
test('registerCallback and executeCallback', () async {
  CallbackRegistry.registerCallback('testCallback', (params) {
    return 'result: ${params['value']}';
  });
  
  final result = await CallbackRegistry.executeCallback(
    'testCallback',
    params: {'value': 'test'}
  );
  expect(result, equals('result: test'));
});
```

### Integration Tests
```dart
// Test flow navigation
testWidgets('Navigate from auth to dashboard flow', (tester) async {
  await tester.pumpWidget(
    QuicUIApp(
      initialFlowId: 'auth',
      flowConfigs: {
        'auth': 'assets/flows/auth.json',
        'dashboard': 'assets/flows/dashboard.json',
      },
    ),
  );
  
  // Fill login form
  await tester.enterText(find.byType(TextField), 'testuser');
  // Click login
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle();
  
  // Verify dashboard loaded
  expect(find.text('Dashboard'), findsOneWidget);
});
```

---

## Implementation Timeline

| Phase | Tasks | Estimate |
|-------|-------|----------|
| 1 | Design & Architecture | 2 days |
| 2 | Core Services | 5 days |
| 3 | UIRenderer Extensions | 3 days |
| 4 | Example App | 3 days |
| 5 | Documentation | 2 days |
| 6 | Testing | 3 days |
| 7 | Advanced Features | 5 days |

**Total: ~23 days**

---

## Key Benefits

✅ **Modularity**: Split complex apps into logical flows  
✅ **Reusability**: Flows can be shared between projects  
✅ **Scalability**: Easy to add new flows without modifying core  
✅ **Maintainability**: Smaller JSONs are easier to manage  
✅ **Flexibility**: Custom callbacks for app-specific logic  
✅ **Type Safety**: Proper data passing with validation  
✅ **Performance**: JSON preloading and caching  
✅ **User Experience**: Smooth transitions between flows  

---

## Migration Path (From Single JSON)

**Before:**
```
screens.json (1 big file with all screens)
  → Single MaterialApp
  → All screens mixed together
```

**After (Gradual):**
```
Step 1: Keep screens.json, add JSONFlowManager
Step 2: Extract auth screens to auth.json
Step 3: Extract dashboard screens to dashboard.json
Step 4: Full multi-flow architecture
```

---

## Next Steps

1. **Review & Feedback** - Validate this architecture with team
2. **Start Phase 1** - Core service implementations
3. **Parallel Development** - UIRenderer extensions
4. **Testing** - Comprehensive test coverage
5. **Documentation** - Create guides and examples
6. **Release** - v2.0 with multi-JSON support

