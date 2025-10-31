# Cross-JSON Navigation Guide

Complete guide to navigating between different JSON flows with data passing and state management.

## Table of Contents

1. [Overview](#overview)
2. [Navigation Models](#navigation-models)
3. [Data Flow Patterns](#data-flow-patterns)
4. [State Management](#state-management)
5. [History and Backtracking](#history-and-backtracking)
6. [Complex Scenarios](#complex-scenarios)
7. [Performance Optimization](#performance-optimization)

---

## Overview

Cross-JSON navigation enables:

- **Seamless transitions** between different feature flows
- **Data preservation** across flow boundaries
- **Automatic caching** for performance
- **Navigation history** tracking
- **Conditional routing** based on user state

### Why Cross-JSON Navigation?

**Single Monolithic JSON:**
- ❌ All screens in one file
- ❌ Difficult to maintain
- ❌ Slow to load
- ❌ Mixed concerns

**Multi-JSON Flows:**
- ✅ Organized by feature
- ✅ Easy to maintain and update
- ✅ Lazy loaded on demand
- ✅ Separation of concerns

---

## Navigation Models

### Model 1: Linear Flow

Simple progression through flows: A → B → C

```
auth (login)
  ↓
dashboard (home)
  ↓
tasks (list)
```

**JSON Example:**

```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Go to Dashboard",
    "events": {
      "onPressed": {
        "action": "navigateToFlow",
        "targetFlow": "dashboard",
        "targetScreen": "home"
      }
    }
  }
}
```

### Model 2: Branching Flow

Different paths based on conditions: A → B or C

```
auth (login)
  ├→ dashboard (user)
  └→ admin (admin)
```

**Implementation:**

```dart
CallbackRegistry.registerCallback('routeByRole', (params) async {
  final role = params?['role'];
  
  if (role == 'admin') {
    FlowManager.navigateToFlow('admin', 'dashboard');
  } else {
    FlowManager.navigateToFlow('dashboard', 'home');
  }
});
```

### Model 3: Hub-and-Spoke

Central flow connected to multiple sub-flows:

```
       settings
         ↑ ↓
auth → dashboard ← profile
         ↓ ↑
        tasks
```

**Structure:**

```
- auth.json: Entry point
- dashboard.json: Hub (home, nav)
- tasks.json: Task management
- profile.json: User profile
- settings.json: App settings
```

### Model 4: Nested Flows

Deep flow hierarchies with multiple levels:

```
auth
  ├ tasks
  │   ├ task-detail
  │   │   ├ task-edit
  │   │   └ task-comments
  │   └ task-create
  └ dashboard
      ├ profile
      │   └ profile-edit
      └ settings
          ├ preferences
          └ notifications
```

---

## Data Flow Patterns

### Pattern 1: Pass on Navigate

Data passed when navigating to next flow:

```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Open Task",
    "events": {
      "onPressed": {
        "action": "navigateToFlow",
        "targetFlow": "tasks",
        "targetScreen": "detail",
        "data": {
          "taskId": "${navigationData.selectedTaskId}",
          "taskName": "${navigationData.selectedTaskName}",
          "userId": "${navigationData.userId}"
        }
      }
    }
  }
}
```

### Pattern 2: Update and Navigate

Update session data before navigating:

```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Save and Continue",
    "events": {
      "onPressed": [
        {
          "action": "updateNavigationData",
          "data": {
            "formData": {
              "name": "${fields.name}",
              "email": "${fields.email}"
            },
            "lastUpdated": "${now}"
          }
        },
        {
          "action": "navigateToFlow",
          "targetFlow": "confirmation",
          "targetScreen": "review"
        }
      ]
    }
  }
}
```

### Pattern 3: Fetch and Navigate

Callback fetches data, then navigates:

```dart
CallbackRegistry.registerCallback('loadAndNavigate', (params) async {
  // Fetch data
  final data = await apiClient.getData();
  
  // Store in session
  NavigationDataManager.mergeSessionData({'fetchedData': data});
  
  // Navigate
  FlowManager.navigateToFlow('results', 'display', data: {
    'itemCount': data['items'].length,
  });
});
```

### Pattern 4: Accumulate Data

Each flow adds more data to session:

```
Flow 1 (Signup)
└→ Create user object
   └→ Navigate to Flow 2, pass {userId}

Flow 2 (Profile)
└→ Add profile info
   └→ Navigate to Flow 3, pass {userId, profile}

Flow 3 (Verification)
└→ Add email verification
   └→ Navigate to Flow 4, pass {userId, profile, email}
```

**Implementation:**

```dart
// Flow 1
CallbackRegistry.registerCallback('createUser', (params) async {
  final user = await apiClient.createUser(params);
  NavigationDataManager.setSessionData('userId', user['id']);
  FlowManager.navigateToFlow('profile', 'edit', data: {
    'userId': user['id'],
  });
});

// Flow 2
CallbackRegistry.registerCallback('saveProfile', (params) async {
  final userId = NavigationDataManager.getSessionData('userId');
  final profile = await apiClient.updateProfile(userId, params);
  NavigationDataManager.mergeSessionData({'profile': profile});
  FlowManager.navigateToFlow('email', 'verify', data: {
    'email': profile['email'],
  });
});
```

---

## State Management

### Session Data Across Flows

Data persists in `NavigationDataManager` throughout app lifecycle:

```
User Input
    ↓
NavigationDataManager.setSessionData()
    ↓
Available in ALL flows/screens
    ↓
Accessed via ${navigationData.key}
```

### Structured Session Data

Organize related data together:

```dart
// Navigation Data Structure
{
  "userId": "user123",
  "token": "eyJ...",
  "username": "john_doe",
  
  // User Profile
  "profile": {
    "name": "John Doe",
    "email": "john@example.com",
    "avatar": "https://..."
  },
  
  // App State
  "appState": {
    "theme": "dark",
    "language": "en"
  },
  
  // Current Context
  "currentTask": {
    "id": "task123",
    "name": "Build feature"
  }
}
```

### Accessing Nested Data

```json
{
  "type": "Text",
  "properties": {
    "text": "User: ${navigationData.profile.name}"
  }
}
```

### Clearing Sensitive Data

```dart
// Clear specific sensitive data
NavigationDataManager.clearSessionDataKey('token');
NavigationDataManager.clearSessionDataKey('password');

// Clear all data (e.g., on logout)
NavigationDataManager.clearAllSessionData();

// Clear specific flow data
NavigationDataManager.clearFlowHistory(flowId: 'auth');
```

---

## History and Backtracking

### Navigation Stack

Automatically tracked by framework:

```dart
// View navigation history
final stack = NavigationDataManager.getNavigationStack();
// Returns: [
//   {"flowId": "auth", "screenId": "login"},
//   {"flowId": "dashboard", "screenId": "home"},
//   {"flowId": "tasks", "screenId": "list"},
// ]

// Check if can go back
if (NavigationDataManager.canGoBack()) {
  FlowManager.goBack();
}
```

### Simple Back Navigation

Go back one flow:

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

### Multi-Step Backtracking

Go back multiple steps:

```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Cancel All Changes",
    "events": {
      "onPressed": {
        "action": "goBack",
        "steps": 3,
        "clearData": true
      }
    }
  }
}
```

### Backtracking with Data Preservation

Go back but keep session data:

```dart
// Go back 1 step, keep data
FlowManager.goBack(steps: 1, clearData: false);

// Go back 2 steps, clear form data but keep auth
FlowManager.goBack(steps: 2, clearData: true);
NavigationDataManager.setSessionData('userId', previousUserId);
```

---

## Complex Scenarios

### Scenario 1: Multi-Step Onboarding

```
auth/login
  ↓
onboarding/welcome
  ↓
profile/setup
  ↓
preferences/settings
  ↓
dashboard/home
```

**Implementation:**

```dart
// Step 1: Login
CallbackRegistry.registerCallback('handleLogin', (params) async {
  final user = await auth.login(params);
  NavigationDataManager.mergeSessionData({
    'userId': user['id'],
    'token': user['token'],
  });
  FlowManager.navigateToFlow('onboarding', 'welcome');
});

// Step 2: Welcome
CallbackRegistry.registerCallback('startOnboarding', (params) async {
  FlowManager.navigateToFlow('profile', 'setup');
});

// Step 3: Profile Setup
CallbackRegistry.registerCallback('completeProfile', (params) async {
  final profile = await api.updateProfile(params);
  NavigationDataManager.setSessionData('profile', profile);
  FlowManager.navigateToFlow('preferences', 'settings');
});

// Step 4: Preferences
CallbackRegistry.registerCallback('savePreferences', (params) async {
  await api.savePreferences(params);
  FlowManager.navigateToFlow('dashboard', 'home');
});
```

### Scenario 2: Conditional Navigation

```
login
  ├→ [admin role] → admin/dashboard
  ├→ [user role] → dashboard/home
  └→ [guest] → guest/welcome
```

**Implementation:**

```dart
CallbackRegistry.registerCallback('routeByUserRole', (params) async {
  final user = await auth.getCurrentUser();
  
  switch (user['role']) {
    case 'admin':
      FlowManager.navigateToFlow('admin', 'dashboard');
      break;
    case 'user':
      FlowManager.navigateToFlow('dashboard', 'home');
      break;
    default:
      FlowManager.navigateToFlow('guest', 'welcome');
  }
});
```

### Scenario 3: Deep Linking

Direct navigation to specific screen from external link:

```dart
// From deep link: "app://tasks/123"
CallbackRegistry.registerCallback('handleDeepLink', (params) async {
  final taskId = params?['taskId'];
  
  // Ensure user is authenticated
  if (!isAuthenticated()) {
    FlowManager.navigateToFlow('auth', 'login', data: {
      'redirectFlow': 'tasks',
      'redirectScreen': 'detail',
      'redirectData': {'taskId': taskId},
    });
    return;
  }
  
  // Navigate directly to target
  FlowManager.navigateToFlow('tasks', 'detail', data: {
    'taskId': taskId,
  });
});
```

### Scenario 4: Modal-Like Flow

Open flow but remember return point:

```dart
CallbackRegistry.registerCallback('showSettings', (params) async {
  // Save current location
  final currentFlow = FlowManager.getCurrentFlowId();
  final currentScreen = FlowManager.getCurrentScreenId();
  
  NavigationDataManager.setSessionData('returnFlow', currentFlow);
  NavigationDataManager.setSessionData('returnScreen', currentScreen);
  
  // Open settings
  FlowManager.navigateToFlow('settings', 'main');
});

// In settings, close to return
CallbackRegistry.registerCallback('closeSettings', (params) async {
  final returnFlow = NavigationDataManager.getSessionData('returnFlow');
  final returnScreen = NavigationDataManager.getSessionData('returnScreen');
  
  FlowManager.navigateToFlow(returnFlow, returnScreen);
});
```

### Scenario 5: Error Recovery

Navigate to error flow, then back to safe state:

```dart
CallbackRegistry.registerCallback('handleCriticalError', (params) async {
  try {
    await performCriticalOperation();
  } catch (e) {
    LoggerUtil.error('Critical error', e);
    
    // Navigate to error screen
    FlowManager.navigateToFlow('errors', 'critical', data: {
      'errorMessage': e.toString(),
      'errorType': 'critical',
    });
    
    // Offer recovery options in error screen
    // User can click "Go Home" or "Retry"
  }
});

CallbackRegistry.registerCallback('recoverFromError', (params) async {
  // Clear error state
  NavigationDataManager.clearAllSessionData();
  
  // Return to safe state
  FlowManager.navigateToFlow('auth', 'login');
});
```

---

## Performance Optimization

### Flow Preloading

Preload commonly accessed flows:

```dart
QuicUIMultiFlowApp(
  initialFlowId: 'auth',
  flowConfigs: flowConfigs,
)

// After initialization
await flowManager.preloadFlows(['dashboard', 'tasks', 'profile']);
```

### Lazy Loading

Load flows on demand:

```dart
// Only load when user navigates to it
FlowManager.navigateToFlow('tasks', 'list');
// tasks.json is loaded here if not already cached
```

### Cache Management

```dart
// Check cache stats
final stats = JSONLoader.getCacheStats();
print('Cached flows: ${stats['cachedFlows']}');

// Clear specific flow cache if memory is tight
JSONLoader.clearCache(key: 'settings');

// Clear all cache (only if necessary)
JSONLoader.clearCache();
```

### Optimize Data Passing

Pass only necessary data:

```dart
// ❌ Avoid: Passing entire user object
navigateToFlow('profile', 'view', data: {
  'user': entireUserObject, // Could be large
});

// ✅ Better: Pass only needed IDs
navigateToFlow('profile', 'view', data: {
  'userId': user['id'],
  'username': user['name'],
});
```

---

## Best Practices

### 1. Clear Naming

```
Good:
- auth → dashboard → tasks
- login → onboarding → home
- settings → notifications → sounds

Avoid:
- flow1 → flow2 → flow3
- page_a → page_b → page_c
```

### 2. Consistent Navigation Patterns

```dart
// Always follow same pattern
FlowManager.navigateToFlow(
  targetFlowId,
  targetScreenId,
  data: dataToPass,
);

// With callbacks
FlowManager.navigateToFlow(
  targetFlowId,
  targetScreenId,
  data: dataToPass,
).then((_) {
  // Handle after navigation
});
```

### 3. Error Handling

Always handle navigation errors:

```dart
try {
  FlowManager.navigateToFlow('tasks', 'list');
} catch (e) {
  LoggerUtil.error('Navigation failed', e);
  // Fall back to safe state
  FlowManager.navigateToFlow('dashboard', 'home');
}
```

### 4. State Consistency

Ensure data consistency across flows:

```dart
// Before navigating away from a flow, validate state
if (!isFormValid()) {
  throw Exception('Form has validation errors');
}

// Persist important data
NavigationDataManager.setSessionData('savedData', formData);
```

### 5. Testing Navigation Paths

```dart
// Test common navigation paths
test('auth → dashboard → tasks', () async {
  // Start at auth
  expect(flowManager.getCurrentFlowId(), 'auth');
  
  // Navigate to dashboard
  await flowManager.navigateToFlow('dashboard', 'home');
  expect(flowManager.getCurrentFlowId(), 'dashboard');
  
  // Navigate to tasks
  await flowManager.navigateToFlow('tasks', 'list');
  expect(flowManager.getCurrentFlowId(), 'tasks');
  
  // Can go back
  await flowManager.goBack();
  expect(flowManager.getCurrentFlowId(), 'dashboard');
});
```

