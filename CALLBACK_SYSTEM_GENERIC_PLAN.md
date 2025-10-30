# Generic Callback Actions System - Updated Plan

## 🎯 Key Change: Generic Actions Instead of Domain-Specific

### BEFORE (Domain-Specific)
```json
{
  "action": "login",
  "emailField": "email_id",
  "passwordField": "password_id"
}
```
❌ Limited to specific use cases  
❌ Tight coupling to UI logic  
❌ Hard to extend

### AFTER (Generic Events + Generic Actions)
```json
{
  "type": "button",
  "properties": {"label": "Sign In"},
  "events": {
    "onPressed": {
      "action": "apiCall",
      "method": "POST",
      "endpoint": "/api/auth/login",
      "body": {
        "email": "${email_input.value}",
        "password": "${password_input.value}"
      },
      "onSuccess": {
        "action": "navigate",
        "target": "dashboard"
      }
    }
  }
}
```
✅ Decoupled event handling  
✅ Reusable actions  
✅ Easy to extend

---

## 📋 Generic Event Types

Events are triggered by user interactions on widgets:

### Button Events
```
onPressed         - Button tapped
```

### Touch Events
```
onTap             - Widget tapped
onLongTap         - Widget long-pressed
onDoubleTap       - Widget double-tapped
```

### Input Events
```
onChanged         - TextField/Checkbox value changed
onSubmitted       - TextField/TextArea submitted
onFocus           - Input gains focus
onBlur            - Input loses focus
```

### List Events
```
onItemTap         - List item tapped
onItemLongTap     - List item long-pressed
```

### Gesture Events
```
onSwipe           - Swipe gesture
onDrag            - Drag gesture
```

---

## 🎬 Generic Action Types (3 Core + Custom)

### 1️⃣ **Navigate**
Navigate to another screen/route.

```json
{
  "action": "navigate",
  "target": "screen_name",
  "replace": false,
  "arguments": {"userId": 123}
}
```

**Parameters:**
- `target` (required): Route name
- `replace` (optional): Replace current route
- `arguments` (optional): Data to pass

---

### 2️⃣ **SetState**
Update widget state locally.

```json
{
  "action": "setState",
  "updates": {
    "loading": true,
    "error": null,
    "itemCount": 5
  }
}
```

**Parameters:**
- `updates` (required): Map of state changes
- Can reference form field values with `${fieldId.value}`

---

### 3️⃣ **ApiCall**
Make HTTP request to backend.

```json
{
  "action": "apiCall",
  "method": "POST",
  "endpoint": "/api/users/login",
  "headers": {"Content-Type": "application/json"},
  "body": {
    "email": "${email_input.value}",
    "password": "${password_input.value}"
  },
  "onSuccess": {
    "action": "navigate",
    "target": "dashboard"
  },
  "onError": {
    "action": "setState",
    "updates": {"error": "Login failed"}
  }
}
```

**Parameters:**
- `method` (required): GET, POST, PUT, DELETE, PATCH
- `endpoint` (required): API URL
- `headers` (optional): HTTP headers
- `body` (optional): Request body
- `queryParams` (optional): URL query params
- `timeout` (optional): Request timeout in seconds

---

### 4️⃣ **Custom**
Call custom Dart function.

```json
{
  "action": "custom",
  "handler": "onLoginButtonPressed",
  "parameters": {
    "email": "${email_input.value}",
    "password": "${password_input.value}"
  }
}
```

**Parameters:**
- `handler` (required): Handler name to call
- `parameters` (optional): Data to pass to handler

---

## 🔗 Action Chaining

All actions support `onSuccess` and `onError` callbacks:

```json
{
  "action": "apiCall",
  "method": "POST",
  "endpoint": "/api/login",
  "body": {"email": "...", "password": "..."},
  
  "onSuccess": {
    "action": "setState",
    "updates": {"loading": false, "loggedIn": true},
    "onSuccess": {
      "action": "navigate",
      "target": "dashboard",
      "replace": true
    }
  },
  
  "onError": {
    "action": "setState",
    "updates": {"loading": false, "error": "Login failed"}
  }
}
```

**Flow:**
1. ApiCall executes
2. If success → setState, then navigate
3. If error → setState with error message

---

## 📱 Real Login Example (Generic)

```json
{
  "type": "column",
  "children": [
    {
      "id": "email_input",
      "type": "textfield",
      "properties": {
        "label": "Email",
        "hint": "Enter your email"
      }
    },
    {
      "id": "password_input",
      "type": "textfield",
      "properties": {
        "label": "Password",
        "obscureText": true
      }
    },
    {
      "id": "error_text",
      "type": "text",
      "properties": {
        "text": "${error}",
        "color": "#FF0000"
      },
      "condition": {"field": "error", "operator": "notEmpty"}
    },
    {
      "type": "button",
      "properties": {"label": "Sign In"},
      "events": {
        "onPressed": {
          "action": "setState",
          "updates": {"loading": true, "error": null},
          "onSuccess": {
            "action": "apiCall",
            "method": "POST",
            "endpoint": "/api/auth/login",
            "body": {
              "email": "${email_input.value}",
              "password": "${password_input.value}"
            },
            "onSuccess": {
              "action": "setState",
              "updates": {"loading": false, "loggedIn": true},
              "onSuccess": {
                "action": "navigate",
                "target": "dashboard",
                "replace": true
              }
            },
            "onError": {
              "action": "setState",
              "updates": {"loading": false, "error": "Invalid credentials"}
            }
          }
        }
      }
    }
  ]
}
```

**Flow:**
1. User enters email & password
2. Clicks "Sign In"
3. Set loading=true
4. Call API to authenticate
5. If success: Set loggedIn=true, navigate to dashboard
6. If error: Show error message

---

## 🔄 Use Cases Enabled

### Login Flow
```
User Input → ApiCall → Success: Navigate
                    ↓
                    Error: Show Error
```

### Form Submission with Validation
```
User Changes Input → onChanged: setState with field value
User Clicks Submit → onPressed: Validate → ApiCall
```

### Multi-Step Forms
```
Step 1 → Step 2 → Step 3 → Submit → Success Screen
Navigate chained with state updates
```

### Real-Time Updates
```
Button Press → ApiCall → setState with response
              ↓
            Rebuild UI with new data
```

---

## 📊 Architecture Overview

```
                  ┌──────────────┐
                  │ Widget Event │
                  │ (onPressed,  │
                  │  onTap, etc) │
                  └───────┬──────┘
                          │
                          ▼
                  ┌──────────────┐
                  │   Parse      │
                  │   Action     │
                  │ from JSON    │
                  └───────┬──────┘
                          │
                          ▼
        ┌─────────────────────────────────────┐
        │    Execute Action in Context        │
        │ (navigate, setState, apiCall, ...) │
        └──────────────┬──────────────────────┘
                       │
            ┌──────────┼──────────┐
            │          │          │
            ▼          ▼          ▼
         Success    Error     Complete
            │          │          │
            ▼          ▼          ▼
        onSuccess  onError    Rebuild
            │          │          │
            └──────────┴──────────┘
                       │
                       ▼
           ┌─────────────────────┐
           │  Next Action or     │
           │  Update UI          │
           └─────────────────────┘
```

---

## 🔧 Implementation Phases

### Phase 1: Core Models
- `CallbackContext` - Execution environment
- Generic `Action` base class with factory
- Specific action classes: Navigate, SetState, ApiCall, Custom
- JSON serialization/deserialization

### Phase 2: UIRenderer Enhancement
- Parse events from WidgetData.events
- Execute actions with callback context
- Handle success/error chains
- State binding and updates

### Phase 3: Examples & Documentation
- Login example (example/2_login_form.json)
- Registration example
- Real-time updates example
- CALLBACK_GUIDE.md

### Phase 4: Testing
- Unit tests for action parsing
- Integration tests for flows
- Edge case tests

### Phase 5: Publishing
- Merge to main
- v1.0.4 release
- pub.dev update

---

## ✅ Benefits of Generic Approach

| Aspect | Before | After |
|--------|--------|-------|
| **Flexibility** | Limited | Unlimited combinations |
| **Extensibility** | Hard to add new actions | Easy - just add new type |
| **Reusability** | Action tied to UI | Actions reusable across widgets |
| **Learning Curve** | Must know each action | Learn 3-4 generic actions |
| **Maintenance** | Many specific actions | Few generic actions |
| **Testability** | Hard to test | Easy to test |

---

## 📝 Event Trigger Mapping

```
Widget Type  →  Event      →  Trigger
─────────────────────────────────────
Button       →  onPressed  →  Tap
TextField    →  onChanged  →  Value change
TextField    →  onSubmitted → Press enter
Checkbox     →  onChanged  →  Toggled
ListTile     →  onTap      →  Tap
Any Widget   →  onTap      →  Tap (via GestureDetector)
Any Widget   →  onLongTap  →  Long press
```

---

## 🎓 Developer Experience

### Simple Action
```json
{"action": "navigate", "target": "home"}
```

### Chained Actions
```json
{
  "action": "setState",
  "updates": {"loading": true},
  "onSuccess": {
    "action": "apiCall",
    "endpoint": "/api/data"
  }
}
```

### Complex Flow
```json
{
  "action": "apiCall",
  "method": "POST",
  "endpoint": "/api/login",
  "body": {"email": "${email.value}"},
  "onSuccess": {
    "action": "navigate",
    "target": "dashboard",
    "replace": true
  },
  "onError": {
    "action": "setState",
    "updates": {"error": "Failed"}
  }
}
```

---

## ⏱️ Timeline

- **Phase 1**: 1-2 days (Core models)
- **Phase 2**: 1-2 days (UIRenderer integration)
- **Phase 3**: 1 day (Examples)
- **Phase 4**: 1 day (Tests)
- **Phase 5**: 0.5 days (Publishing)

**Total: 4-6 days to v1.0.4**

---

## ✨ Success Criteria

- ✅ All 4 action types work correctly
- ✅ Action chaining functions properly
- ✅ JSON parsing handles all cases
- ✅ State updates trigger UI rebuild
- ✅ Navigation works with and without replace
- ✅ API calls handle success/error
- ✅ Custom actions can be registered
- ✅ All tests pass (267+ tests)
- ✅ No breaking changes to existing API
- ✅ Documentation is complete and clear
