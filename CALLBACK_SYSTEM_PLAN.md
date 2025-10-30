# JSON Callbacks System - Implementation Plan

**Date:** October 30, 2025  
**Feature:** JSON-based Callbacks & Actions System  
**Goal:** Enable interactive flows like login, form submission, and navigation using JSON configuration

---

## 📋 Overview

Currently, QuicUI has a basic event system where `properties['onPressed']` accepts a string action. We need to enhance this to support:
- ✅ Multiple action types (navigate, submitForm, setState, login, API calls)
- ✅ Action parameters and data passing
- ✅ Action chaining
- ✅ State updates via callbacks
- ✅ Form validation with callbacks
- ✅ Navigation callbacks

---

## 🏗️ Architecture Design

### Current State
```dart
// Current: Simple string action
WidgetData(
  type: 'button',
  properties: {'label': 'Login', 'onPressed': 'login_action'}
)

// Then: _handleButtonPress just prints
static void _handleButtonPress(String action) {
  print('Button pressed: $action');
}
```

### Proposed State
```dart
// New: Structured action with parameters
WidgetData(
  type: 'button',
  properties: {'label': 'Login'},
  events: {
    'onPressed': {
      'action': 'navigate',
      'target': 'login_screen',
      'params': {'from': 'home'}
    }
  }
)

// Or: Login-specific action
WidgetData(
  type: 'button',
  properties: {'label': 'Sign In'},
  events: {
    'onPressed': {
      'action': 'login',
      'email': '\${email.value}',
      'password': '\${password.value}',
      'onSuccess': {
        'action': 'navigate',
        'target': 'dashboard'
      },
      'onError': {
        'action': 'setState',
        'updates': {'error': 'Invalid credentials'}
      }
    }
  }
)
```

---

## 📦 Implementation Phases

### Phase 1: Core Models & Enums (Day 1)

**Files to create:**

1. **`lib/src/models/action.dart`** - Base action models
```dart
enum ActionType {
  navigate,        // Navigate to screen
  submitForm,      // Submit form data
  setState,        // Update state
  login,           // Login action
  logout,          // Logout action
  apiCall,         // Call REST API
  dismiss,         // Dismiss dialog/modal
  customAction,    // Custom action
}

abstract class Action {
  final ActionType type;
  final Map<String, dynamic>? params;
  Action({required this.type, this.params});
  
  factory Action.fromJson(Map<String, dynamic> json);
}

class NavigateAction extends Action {
  final String target;
  final Map<String, dynamic>? navigationParams;
  
  NavigateAction({
    required this.target,
    this.navigationParams,
  }) : super(
    type: ActionType.navigate,
    params: {'target': target, ...?navigationParams},
  );
}

class LoginAction extends Action {
  final String? emailField;
  final String? passwordField;
  final String? emailValue;
  final String? passwordValue;
  final Action? onSuccess;
  final Action? onError;
  
  LoginAction({
    this.emailField,
    this.passwordField,
    this.emailValue,
    this.passwordValue,
    this.onSuccess,
    this.onError,
  }) : super(
    type: ActionType.login,
    params: {
      'emailField': emailField,
      'passwordField': passwordField,
    },
  );
}

class SubmitFormAction extends Action {
  final String formId;
  final Map<String, dynamic>? formData;
  final String? apiEndpoint;
  final Action? onSuccess;
  final Action? onError;
  
  SubmitFormAction({
    required this.formId,
    this.formData,
    this.apiEndpoint,
    this.onSuccess,
    this.onError,
  }) : super(
    type: ActionType.submitForm,
    params: {'formId': formId},
  );
}

class SetStateAction extends Action {
  final Map<String, dynamic> updates;
  
  SetStateAction({required this.updates}) : super(
    type: ActionType.setState,
    params: updates,
  );
}

class ApiCallAction extends Action {
  final String method;    // GET, POST, PUT, DELETE
  final String endpoint;
  final Map<String, dynamic>? body;
  final Map<String, dynamic>? headers;
  final Action? onSuccess;
  final Action? onError;
  
  ApiCallAction({
    required this.method,
    required this.endpoint,
    this.body,
    this.headers,
    this.onSuccess,
    this.onError,
  }) : super(
    type: ActionType.apiCall,
    params: {'method': method, 'endpoint': endpoint},
  );
}
```

2. **`lib/src/models/callback_context.dart`** - Context for action execution
```dart
class CallbackContext {
  final String screenId;
  final Map<String, dynamic> screenState;
  final Map<String, dynamic> formData;
  final BuildContext? widgetContext;
  
  CallbackContext({
    required this.screenId,
    required this.screenState,
    this.formData = const {},
    this.widgetContext,
  });
}

typedef ActionCallback = Future<void> Function(
  Action action,
  CallbackContext context,
);
```

---

### Phase 2: Event System Enhancement (Day 2)

**Update files:**

1. **`lib/src/models/widget_data.dart`** - Already has `events` field, verify structure
   - Update documentation to show new event format
   - Add examples with callbacks

2. **`lib/src/rendering/ui_renderer.dart`** - Enhance event handling
```dart
// Update _buildElevatedButton
static Widget _buildElevatedButton(
  Map<String, dynamic> properties,
  Map<String, dynamic>? config,
  ActionCallback? onAction,
) {
  final events = config?['events'] as Map<String, dynamic>? ?? {};
  final onPressedEvent = events['onPressed'];
  
  return ElevatedButton(
    onPressed: onPressedEvent != null
        ? () => _executeAction(onPressedEvent, onAction)
        : null,
    child: Text(properties['label'] as String? ?? 'Button'),
  );
}

static Future<void> _executeAction(
  dynamic eventConfig,
  ActionCallback? callback,
) async {
  try {
    if (eventConfig is String) {
      // Legacy: simple string action
      _handleButtonPress(eventConfig);
    } else if (eventConfig is Map<String, dynamic>) {
      // New: structured action
      final actionType = eventConfig['action'] as String?;
      final action = _parseAction(eventConfig);
      
      if (callback != null && action != null) {
        await callback(action, CallbackContext(/* ... */));
      } else {
        _handleButtonPress(actionType ?? 'unknown');
      }
    }
  } catch (e) {
    print('Error executing action: $e');
  }
}
```

---

### Phase 3: Login Example (Day 2)

**File: `example/2_login_form.json`**
```json
{
  "version": "1.0",
  "metadata": {
    "name": "Login Screen",
    "description": "User authentication with callbacks"
  },
  "screens": [
    {
      "id": "login_screen",
      "name": "Login",
      "version": 1,
      "rootWidget": {
        "type": "Scaffold",
        "properties": {
          "backgroundColor": "#FFFFFF"
        },
        "children": [
          {
            "type": "AppBar",
            "properties": {
              "title": "Sign In",
              "backgroundColor": "#2196F3",
              "elevation": 0
            }
          },
          {
            "type": "Center",
            "properties": {},
            "children": [
              {
                "type": "SingleChildScrollView",
                "properties": {},
                "children": [
                  {
                    "type": "Container",
                    "properties": {
                      "padding": {
                        "top": 40,
                        "bottom": 40,
                        "left": 24,
                        "right": 24
                      }
                    },
                    "children": [
                      {
                        "id": "email_field",
                        "type": "TextField",
                        "properties": {
                          "label": "Email",
                          "hint": "Enter your email",
                          "keyboardType": "emailAddress",
                          "validation": {
                            "required": true,
                            "pattern": "email"
                          }
                        }
                      },
                      {
                        "type": "SizedBox",
                        "properties": {"height": 16}
                      },
                      {
                        "id": "password_field",
                        "type": "TextField",
                        "properties": {
                          "label": "Password",
                          "hint": "Enter your password",
                          "obscureText": true
                        }
                      },
                      {
                        "type": "SizedBox",
                        "properties": {"height": 8}
                      },
                      {
                        "type": "Align",
                        "properties": {
                          "alignment": "centerRight"
                        },
                        "children": [
                          {
                            "type": "TextButton",
                            "properties": {
                              "label": "Forgot Password?",
                              "textColor": "#2196F3"
                            },
                            "events": {
                              "onPressed": {
                                "action": "navigate",
                                "target": "forgot_password_screen"
                              }
                            }
                          }
                        ]
                      },
                      {
                        "type": "SizedBox",
                        "properties": {"height": 24}
                      },
                      {
                        "type": "ElevatedButton",
                        "properties": {
                          "label": "Sign In",
                          "backgroundColor": "#2196F3",
                          "width": "full"
                        },
                        "events": {
                          "onPressed": {
                            "action": "login",
                            "emailField": "email_field",
                            "passwordField": "password_field",
                            "onSuccess": {
                              "action": "navigate",
                              "target": "dashboard_screen",
                              "replace": true
                            },
                            "onError": {
                              "action": "setState",
                              "updates": {
                                "error": "Invalid email or password",
                                "showError": true
                              }
                            }
                          }
                        }
                      },
                      {
                        "type": "SizedBox",
                        "properties": {"height": 16}
                      },
                      {
                        "type": "Row",
                        "properties": {
                          "mainAxisAlignment": "center"
                        },
                        "children": [
                          {
                            "type": "Text",
                            "properties": {
                              "text": "Don't have an account? "
                            }
                          },
                          {
                            "type": "TextButton",
                            "properties": {
                              "label": "Sign Up",
                              "textColor": "#2196F3"
                            },
                            "events": {
                              "onPressed": {
                                "action": "navigate",
                                "target": "signup_screen"
                              }
                            }
                          }
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ]
      }
    },
    {
      "id": "dashboard_screen",
      "name": "Dashboard",
      "version": 1,
      "rootWidget": {
        "type": "Scaffold",
        "properties": {
          "backgroundColor": "#FAFAFA"
        },
        "children": [
          {
            "type": "AppBar",
            "properties": {
              "title": "Dashboard",
              "backgroundColor": "#2196F3",
              "actions": [
                {
                  "type": "IconButton",
                  "properties": {
                    "icon": "logout"
                  },
                  "events": {
                    "onPressed": {
                      "action": "logout",
                      "onComplete": {
                        "action": "navigate",
                        "target": "login_screen",
                        "replace": true
                      }
                    }
                  }
                }
              ]
            }
          },
          {
            "type": "Center",
            "properties": {},
            "children": [
              {
                "type": "Text",
                "properties": {
                  "text": "Welcome, \${user.name}!",
                  "style": {
                    "fontSize": 24,
                    "fontWeight": "bold"
                  }
                }
              }
            ]
          }
        ]
      }
    }
  ]
}
```

---

### Phase 4: Form Submission with Validation (Day 3)

**File: `example/3_registration_form.json`**
```json
{
  "screens": [
    {
      "id": "registration_screen",
      "rootWidget": {
        "type": "Form",
        "properties": {"id": "registration_form"},
        "children": [
          {
            "id": "username_field",
            "type": "TextFormField",
            "properties": {
              "label": "Username",
              "validator": {
                "required": true,
                "minLength": 3,
                "pattern": "alphanumeric"
              }
            }
          },
          {
            "id": "email_field",
            "type": "TextFormField",
            "properties": {
              "label": "Email",
              "validator": {
                "required": true,
                "pattern": "email"
              }
            }
          },
          {
            "id": "password_field",
            "type": "TextFormField",
            "properties": {
              "label": "Password",
              "obscureText": true,
              "validator": {
                "required": true,
                "minLength": 8,
                "pattern": "strongPassword"
              }
            }
          },
          {
            "type": "ElevatedButton",
            "properties": {"label": "Register"},
            "events": {
              "onPressed": {
                "action": "submitForm",
                "formId": "registration_form",
                "endpoint": "/api/auth/register",
                "method": "POST",
                "onSuccess": {
                  "action": "navigate",
                  "target": "verification_screen"
                },
                "onError": {
                  "action": "setState",
                  "updates": {"error": "\${error.message}"}
                }
              }
            }
          }
        ]
      }
    }
  ]
}
```

---

### Phase 5: Tests (Day 3)

**File: `test/callbacks_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quicui/quicui.dart';

void main() {
  group('Callback Actions', () {
    test('Parse navigate action from JSON', () {
      final json = {
        'action': 'navigate',
        'target': 'dashboard',
        'params': {'user_id': '123'}
      };
      
      final action = Action.fromJson(json) as NavigateAction;
      expect(action.type, equals(ActionType.navigate));
      expect(action.target, equals('dashboard'));
    });

    test('Parse login action from JSON', () {
      final json = {
        'action': 'login',
        'emailField': 'email_input',
        'passwordField': 'password_input',
        'onSuccess': {'action': 'navigate', 'target': 'home'}
      };
      
      final action = Action.fromJson(json) as LoginAction;
      expect(action.type, equals(ActionType.login));
      expect(action.emailField, equals('email_input'));
    });

    test('Parse form submission action', () {
      final json = {
        'action': 'submitForm',
        'formId': 'contact_form',
        'endpoint': '/api/contact',
        'method': 'POST'
      };
      
      final action = Action.fromJson(json) as SubmitFormAction;
      expect(action.formId, equals('contact_form'));
      expect(action.apiEndpoint, equals('/api/contact'));
    });

    test('Chain multiple actions', () {
      final loginAction = {
        'action': 'login',
        'onSuccess': {
          'action': 'navigate',
          'target': 'dashboard'
        },
        'onError': {
          'action': 'setState',
          'updates': {'error': 'Login failed'}
        }
      };
      
      final action = Action.fromJson(loginAction) as LoginAction;
      expect(action.onSuccess, isNotNull);
      expect(action.onError, isNotNull);
    });

    test('Widget can have event with callback', () {
      final widget = WidgetData(
        type: 'button',
        properties: {'label': 'Login'},
        events: {
          'onPressed': {
            'action': 'navigate',
            'target': 'login_screen'
          }
        }
      );
      
      expect(widget.events, isNotNull);
      expect(widget.events!['onPressed'], isNotNull);
    });
  });
}
```

---

### Phase 6: Documentation (Day 4)

**File: `docs/CALLBACK_SYSTEM_GUIDE.md`**

- How to use callbacks in JSON
- Supported action types with examples
- Action chaining patterns
- Error handling patterns
- Best practices

**Update:**
- `QUICK_START_GUIDE.md` - Add callback section
- `README.md` - Add callback feature to overview
- `API_REFERENCE.md` - Add Action types

---

## 📊 JSON Callback Structure

### Basic Structure
```json
{
  "events": {
    "onPressed": {
      "action": "ACTION_TYPE",
      "param1": "value1",
      "param2": "value2"
    }
  }
}
```

### Supported Action Types

| Action | Parameters | Description |
|--------|-----------|-------------|
| `navigate` | `target`, `replace`, `params` | Navigate to screen |
| `login` | `emailField`, `passwordField`, `onSuccess`, `onError` | Authenticate user |
| `logout` | `onComplete` | Clear user session |
| `submitForm` | `formId`, `endpoint`, `method`, `onSuccess`, `onError` | Submit form data |
| `setState` | `updates` | Update widget state |
| `apiCall` | `method`, `endpoint`, `body`, `headers` | Make HTTP request |
| `dismiss` | (none) | Dismiss dialog/modal |
| `customAction` | `name`, `payload` | Custom app action |

---

## 🔄 Data Flow

```
User Action (Button Press)
    ↓
Event Captured: events.onPressed
    ↓
Parse Action: Action.fromJson(eventConfig)
    ↓
Execute Action: executeAction(action, context)
    ↓
Perform Operation:
  - Navigate: Go to target screen
  - Login: Call auth API
  - Submit: Validate & submit form
  - setState: Update UI state
    ↓
Handle Result:
  - Success: Execute onSuccess action (may chain)
  - Error: Execute onError action
    ↓
Update UI (rebuild)
```

---

## 🎯 Success Criteria

- ✅ Actions parsed correctly from JSON
- ✅ Callbacks execute without errors
- ✅ Action chaining works (onSuccess → onError)
- ✅ Login example works end-to-end
- ✅ Form submission works with validation
- ✅ Navigation callbacks work
- ✅ All tests pass
- ✅ Documentation complete

---

## 📅 Timeline

| Phase | Task | Days | Status |
|-------|------|------|--------|
| 1 | Core Models | 1 | Not Started |
| 2 | Event System | 1 | Not Started |
| 3 | Login Example | 1 | Not Started |
| 4 | Form Example | 1 | Not Started |
| 5 | Tests | 1 | Not Started |
| 6 | Documentation | 1 | Not Started |
| 7 | Publication | 1 | Not Started |
| | **Total** | **~7 days** | |

---

## 📦 Deliverables

1. **Code Changes**
   - New callback action system
   - Enhanced event handling in UIRenderer
   - 2+ working examples
   - Comprehensive tests

2. **Documentation**
   - Callback System Guide
   - 3+ complete examples (login, signup, form)
   - API reference updates
   - Best practices guide

3. **Release**
   - Version bump: v1.0.4
   - pub.dev publication
   - GitHub release notes
   - Blog post (optional)

---

## 🚀 Next Step

Ready to start Phase 1? Create callback action models and infrastructure.

**Start with:** `lib/src/models/action.dart`
