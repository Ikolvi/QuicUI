# Multi-JSON Flows Guide

Complete guide to using QuicUI's multi-JSON flow architecture for building complex, modular applications.

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Flow Architecture](#flow-architecture)
4. [Configuration](#configuration)
5. [Navigation Between Flows](#navigation-between-flows)
6. [Data Passing](#data-passing)
7. [Custom Callbacks](#custom-callbacks)
8. [Advanced Patterns](#advanced-patterns)
9. [API Reference](#api-reference)

---

## Overview

QuicUI's multi-JSON flow system allows you to:

- **Split UIs** into separate JSON files (flows) organized by feature
- **Navigate** between flows with automatic data passing
- **Manage state** across screens and flows
- **Define custom callbacks** for business logic
- **Cache flows** for optimal performance
- **Build modular** applications that scale easily

### What is a Flow?

A flow is a JSON file containing one or more related screens. Each flow represents a feature or section of your app.

```
Your App
├── Auth Flow (auth.json)
│   ├── Login Screen
│   ├── Sign Up Screen
│   └── Forgot Password Screen
├── Dashboard Flow (dashboard.json)
│   ├── Home Screen
│   ├── Profile Screen
│   └── Settings Screen
└── Tasks Flow (tasks.json)
    ├── Task List Screen
    ├── Task Detail Screen
    └── Task Create Screen
```

---

## Quick Start

### 1. Create Flow Configuration

Create `assets/flow_config.json`:

```json
{
  "version": "2.0.0",
  "initialFlow": "auth",
  "flows": {
    "auth": "flows/auth.json",
    "dashboard": "flows/dashboard.json",
    "tasks": "flows/tasks.json"
  },
  "globalCallbacks": {}
}
```

### 2. Create Flow JSON Files

Create `assets/flows/auth.json`:

```json
{
  "type": "MaterialApp",
  "flowId": "auth",
  "properties": {
    "title": "Login"
  },
  "screens": {
    "login": {
      "type": "Scaffold",
      "children": [
        {
          "type": "ElevatedButton",
          "properties": {
            "label": "Login",
            "events": {
              "onPressed": {
                "action": "navigateToFlow",
                "targetFlow": "dashboard",
                "targetScreen": "home",
                "data": {
                  "userId": "${fields.userId}",
                  "token": "${fields.token}"
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

### 3. Initialize App

In `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final configJson = await rootBundle.loadString('assets/flow_config.json');
  final config = jsonDecode(configJson);

  runApp(
    QuicUIMultiFlowApp(
      initialFlowId: config['initialFlow'],
      flowConfigs: Map<String, String>.from(config['flows']),
    ),
  );
}
```

---

## Flow Architecture

### Directory Structure

```
assets/
├── flow_config.json          # Main configuration
├── flows/                    # All flow JSON files
│   ├── auth.json            # Authentication flow
│   ├── dashboard.json       # Dashboard flow
│   ├── tasks.json           # Tasks flow
│   └── settings.json        # Settings flow
└── (legacy files can coexist)
```

### Flow JSON Structure

```json
{
  "type": "MaterialApp",
  "flowId": "unique_flow_id",
  "properties": {
    "title": "Flow Title",
    "requiresAuth": false,
    "description": "Optional description"
  },
  "screens": {
    "screen_id": {
      // Screen configuration
    }
  }
}
```

### Flow Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | string | Yes | Must be "MaterialApp" |
| `flowId` | string | Yes | Unique flow identifier |
| `properties` | object | No | Flow metadata |
| `screens` | object | Yes | Map of screens in flow |

---

## Configuration

### Flow Config JSON

Master configuration file mapping flows to files:

```json
{
  "version": "2.0.0",
  "initialFlow": "auth",
  "flows": {
    "auth": "flows/auth.json",
    "dashboard": "flows/dashboard.json",
    "tasks": "flows/tasks.json",
    "profile": "flows/profile.json"
  },
  "globalCallbacks": {
    "onLogout": "handleLogout",
    "onSessionExpired": "handleSessionExpired"
  }
}
```

### Global Callbacks

Register callbacks that work across all flows:

```dart
runApp(
  QuicUIMultiFlowApp(
    initialFlowId: 'auth',
    flowConfigs: flowConfigs,
    globalCallbacks: {
      'onLogout': (params) async {
        // Handle logout
        NavigationDataManager.clearAll();
      },
      'onSessionExpired': (params) async {
        // Handle session expiry
        flowManager.navigateToFlow('auth', 'login');
      },
    },
  ),
);
```

---

## Navigation Between Flows

### navigateToFlow Action

Navigate to a different flow with data passing:

```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Go to Dashboard",
    "events": {
      "onPressed": {
        "action": "navigateToFlow",
        "targetFlow": "dashboard",
        "targetScreen": "home",
        "data": {
          "userId": "user123",
          "username": "${fields.username}"
        }
      }
    }
  }
}
```

### Navigate Within Same Flow

Use the original `navigate` action for same-flow navigation:

```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Go to Settings",
    "events": {
      "onPressed": {
        "action": "navigate",
        "screen": "settings"
      }
    }
  }
}
```

### Navigation Stack & Go Back

Navigation automatically maintains a stack:

```json
{
  "type": "IconButton",
  "properties": {
    "icon": "arrow_back",
    "events": {
      "onPressed": {
        "action": "goBack",
        "steps": 1,
        "clearData": false
      }
    }
  }
}
```

---

## Data Passing

### Passing Data Between Screens

#### From Login to Dashboard:

**auth.json (login screen):**
```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Login",
    "events": {
      "onPressed": {
        "action": "navigateToFlow",
        "targetFlow": "dashboard",
        "targetScreen": "home",
        "data": {
          "userId": "${fields.userId}",
          "username": "${fields.username}",
          "token": "${fields.token}",
          "loginTime": "${now}"
        }
      }
    }
  }
}
```

**dashboard.json (home screen):**
```json
{
  "type": "Text",
  "properties": {
    "text": "Welcome ${navigationData.username}!"
  }
}
```

### Accessing Navigation Data

In any screen, access data via `${navigationData.key}`:

```json
{
  "type": "Column",
  "children": [
    {
      "type": "Text",
      "properties": {
        "text": "User: ${navigationData.username}"
      }
    },
    {
      "type": "Text",
      "properties": {
        "text": "ID: ${navigationData.userId}"
      }
    },
    {
      "type": "Text",
      "properties": {
        "text": "Logged in at: ${navigationData.loginTime}"
      }
    }
  ]
}
```

### Updating Navigation Data

Use `updateNavigationData` action to modify session data:

```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Save Preferences",
    "events": {
      "onPressed": {
        "action": "updateNavigationData",
        "merge": true,
        "data": {
          "preferences": {
            "theme": "dark",
            "language": "en"
          },
          "lastUpdated": "${now}"
        }
      }
    }
  }
}
```

---

## Custom Callbacks

### Defining Custom Callbacks

Register callbacks in app initialization:

```dart
CallbackRegistry.registerCallback('validateAndLogin', (params) async {
  final email = params?['email'];
  final password = params?['password'];
  
  // Validate credentials
  if (email == null || password == null) {
    throw Exception('Email and password required');
  }
  
  // Make API call
  final result = await api.login(email, password);
  
  // Update navigation data
  NavigationDataManager.mergeSessionData({
    'userId': result.userId,
    'token': result.token,
    'username': result.username,
  });
  
  return result;
});
```

### Using Custom Callbacks in JSON

```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Login",
    "events": {
      "onPressed": {
        "action": "executeCallback",
        "callbackName": "validateAndLogin",
        "params": {
          "email": "${fields.email}",
          "password": "${fields.password}"
        }
      }
    }
  }
}
```

### Multi-Step Callback with Navigation

Callbacks can trigger flow navigation:

```dart
CallbackRegistry.registerCallback('completeSignup', (params) async {
  try {
    // Validate form
    final result = await createUser(params);
    
    // Navigate to next flow after success
    FlowManager.navigateToFlow('dashboard', 'onboarding', data: {
      'newUserId': result.userId,
      'onboardingStep': 1,
    });
  } catch (e) {
    // Show error
    throw Exception('Signup failed: $e');
  }
});
```

---

## Advanced Patterns

### Chained Navigation

Navigate through multiple flows with data accumulation:

```
auth.json (login)
  ↓ pass {userId, token}
dashboard.json (home)
  ↓ pass {userId, token, selectedTask}
tasks.json (detail)
  ↓ pass {userId, token, selectedTask, comment}
tasks.json (comment-edit)
```

### Conditional Navigation

Use custom callbacks for conditional flow:

```dart
CallbackRegistry.registerCallback('checkPermissions', (params) async {
  final userId = params?['userId'];
  final userRole = await api.getUserRole(userId);
  
  if (userRole == 'admin') {
    FlowManager.navigateToFlow('admin', 'dashboard');
  } else {
    FlowManager.navigateToFlow('dashboard', 'home');
  }
});
```

### State Preservation

Data persists in session until cleared:

```dart
// Access persisted data from any screen
final sessionData = NavigationDataManager.getFullSessionData();

// Clear specific data
NavigationDataManager.clearSessionDataKey('temporaryData');

// Clear all session data
NavigationDataManager.clearAllSessionData();
```

### Flow History Management

View and manage navigation history:

```dart
// Get navigation stack
final stack = NavigationDataManager.getNavigationStack();

// Check if can go back
if (NavigationDataManager.canGoBack()) {
  FlowManager.goBack(steps: 1);
}

// Go back multiple steps
FlowManager.goBack(steps: 2, clearData: true);
```

### Preloading Flows

For faster navigation, preload frequently used flows:

```dart
QuicUIMultiFlowApp(
  initialFlowId: 'auth',
  flowConfigs: flowConfigs,
  // Flows are preloaded automatically, but you can manually preload:
)

// In code, after initialization
await flowManager.preloadFlows(['dashboard', 'tasks', 'profile']);
```

---

## API Reference

### JSONFlowManager

Main service for managing flows and navigation.

#### Methods

```dart
// Initialize
Future<void> initializeApp(
  String initialFlowId,
  String initialJsonPath,
  {Map<String, String>? additionalFlowConfigs}
)

// Load a flow
Future<Map<String, dynamic>> loadFlow(String flowId, String jsonPath)

// Navigate within same flow
void navigateToScreen(String screenId, {Map<String, dynamic>? data})

// Navigate to different flow
Future<void> navigateToFlow(
  String targetFlowId,
  String targetScreenId,
  {Map<String, dynamic>? data}
)

// Go back in history
Future<void> goBack({int steps = 1, bool clearData = true})

// Get current state
String getCurrentFlowId()
String getCurrentScreenId()
Map<String, dynamic> getNavigationData()

// Execute custom callback
Future<dynamic> executeCallback(
  String callbackName,
  {Map<String, dynamic>? params}
)
```

### NavigationDataManager

Manages session data and navigation history.

```dart
// Set/Get data
void setSessionData(String key, dynamic value)
dynamic getSessionData(String key)
void mergeSessionData(Map<String, dynamic> data)
Map<String, dynamic> getFullSessionData()

// Navigation stack
void pushNavigation(String flowId, String screenId)
Map<String, String>? popNavigation()
bool canGoBack()

// Clear data
void clearSessionDataKey(String key)
void clearAllSessionData()
void clearAll()
```

### CallbackRegistry

Manages named callbacks.

```dart
// Register/Execute
void registerCallback(String name, Function callback)
Future<dynamic> executeCallback(String name, {Map<String, dynamic>? params})

// Query
Function? getCallback(String name)
bool isCallbackRegistered(String name)
List<String> getRegisteredCallbackNames()
```

### JSONLoader

Loads and caches JSON files.

```dart
// Load
Future<Map<String, dynamic>> loadJsonFromAssets(String path)
Future<void> preloadJsons(List<String> paths)

// Cache
void cacheJson(String key, Map<String, dynamic> json)
Map<String, dynamic>? getCachedJson(String key)
void clearCache({String? key})
```

---

## Best Practices

### 1. Flow Organization

- One flow per feature/domain
- Keep screens in same flow related
- Use clear naming (auth, dashboard, tasks, etc.)

### 2. Data Management

- Pass only necessary data between flows
- Use session data for global context
- Clear sensitive data when logging out

### 3. Error Handling

- Always handle errors in custom callbacks
- Validate required parameters
- Provide user-friendly error messages

### 4. Performance

- Preload frequently used flows
- Cache frequently accessed data
- Clear unused cache periodically

### 5. State Management

- Use navigationData for screen-to-screen passing
- Use sessionData for app-wide state
- Restore state on app restart (optional)

---

## Examples

### Example 1: Simple Auth Flow

See `example/task_manager_runner/assets/flows/` for complete examples of:
- `auth.json`: Login flow
- `dashboard.json`: Main dashboard

### Example 2: Multi-Flow App

To add more flows (tasks, settings, profile):

1. Create `flows/tasks.json` with task screens
2. Update `flow_config.json` to include new flows
3. Add navigation buttons in existing flows

### Example 3: Custom Callbacks

Register async callbacks for API integration:

```dart
CallbackRegistry.registerCallback('fetchUserData', (params) async {
  final userId = params?['userId'];
  final userData = await api.getUser(userId);
  NavigationDataManager.mergeSessionData({'userData': userData});
  return userData;
});
```

---

## Troubleshooting

### Flow Not Found

**Problem:** "Flow not configured: xyz"

**Solution:** Add flow to `flow_config.json` and ensure JSON file exists

### Navigation Data Not Appearing

**Problem:** `${navigationData.key}` shows literal text instead of value

**Solution:** Ensure data is passed in `navigateToFlow` action and access in target screen

### Callback Not Executing

**Problem:** Custom callback doesn't run

**Solution:** Register callback before app initialization with matching name

### Performance Issues

**Problem:** App is slow when switching flows

**Solution:** Preload flows during initialization and use flow caching

---

## Migration from Single JSON

If you have an existing single `screens.json`:

1. Create `flow_config.json` with initial flow mapping
2. Split `screens.json` by feature into separate JSONs in `flows/` directory
3. Update button actions from `navigate` to `navigateToFlow`
4. Refactor `main.dart` to use `QuicUIMultiFlowApp`
5. Test each flow independently

Example migration:
```
Before: screens.json (all screens mixed)
After:
  - flow_config.json (master config)
  - flows/auth.json
  - flows/dashboard.json
  - flows/tasks.json
```

