# QuicUI Callback Actions - Quick Start Guide

This is a quick reference for the new **Callback Action System** in QuicUI v1.0.4+.

## What Are Callback Actions?

Callback actions allow you to define interactive flows entirely in JSON. Instead of just describing UI, you can now describe **what happens** when users interact with it.

### Before (v1.0.3)
```json
{
  "type": "button",
  "properties": {"label": "Click me"},
  "events": {"onPressed": "some_action"}
}
```
The app had to handle `some_action` in native code.

### After (v1.0.4+)
```json
{
  "type": "button",
  "properties": {"label": "Sign In"},
  "onPressed": {
    "action": "setState",
    "updates": {"loading": true},
    "onSuccess": {
      "action": "apiCall",
      "method": "POST",
      "endpoint": "/api/login",
      "body": {"email": "${email_input}"},
      "onSuccess": {"action": "navigate", "target": "dashboard"}
    }
  }
}
```
The entire flow happens via JSON!

---

## The 4 Action Types

### 1️⃣ navigate
Go to a different screen.

```json
{
  "action": "navigate",
  "target": "dashboard"
}
```

**Options:**
- `target` (required) - Screen name
- `replace` (optional) - Replace current route (true/false)
- `arguments` (optional) - Data to pass

### 2️⃣ setState
Update widget state locally.

```json
{
  "action": "setState",
  "updates": {"loading": false, "error": null}
}
```

**Use for:**
- Toggle loading indicators
- Clear error messages
- Update UI state

### 3️⃣ apiCall
Make HTTP requests to your API.

```json
{
  "action": "apiCall",
  "method": "POST",
  "endpoint": "/api/login",
  "body": {"email": "${email_input}", "password": "${password_input}"}
}
```

**Supports:**
- All HTTP methods: GET, POST, PUT, DELETE, PATCH
- Query parameters
- Custom headers
- Request body

### 4️⃣ custom
Call custom Dart code.

```json
{
  "action": "custom",
  "handler": "validateForm",
  "parameters": {"requiredFields": ["email", "password"]}
}
```

**Use for:**
- Complex business logic
- Form validation
- Local storage operations
- Custom dialogs

---

## Chaining Actions

Actions can chain together using `onSuccess` and `onError`:

```json
{
  "action": "setState",
  "updates": {"loading": true},
  "onSuccess": {
    "action": "apiCall",
    "method": "GET",
    "endpoint": "/api/user/profile",
    "onSuccess": {
      "action": "setState",
      "updates": {"loading": false, "userData": "${response.data}"}
    },
    "onError": {
      "action": "setState",
      "updates": {"loading": false, "error": "Failed to load"}
    }
  }
}
```

**Flow:**
1. Set `loading=true`
2. Fetch user profile
3. If success: Clear loading and store data
4. If error: Clear loading and show error

---

## Common Patterns

### Pattern 1: Login Form

```json
{
  "type": "button",
  "properties": {"label": "Sign In"},
  "onPressed": {
    "action": "setState",
    "updates": {"loading": true, "error": null},
    "onSuccess": {
      "action": "apiCall",
      "method": "POST",
      "endpoint": "/api/auth/login",
      "body": {
        "email": "${email_input}",
        "password": "${password_input}"
      },
      "onSuccess": {
        "action": "navigate",
        "target": "dashboard",
        "replace": true
      },
      "onError": {
        "action": "setState",
        "updates": {"error": "Invalid email or password"}
      }
    }
  }
}
```

### Pattern 2: Form Validation

```json
{
  "type": "button",
  "properties": {"label": "Register"},
  "onPressed": {
    "action": "custom",
    "handler": "validateForm",
    "parameters": {"requiredFields": ["name", "email", "password"]},
    "onSuccess": {
      "action": "apiCall",
      "method": "POST",
      "endpoint": "/api/auth/register",
      "body": {
        "name": "${name_input}",
        "email": "${email_input}",
        "password": "${password_input}"
      },
      "onSuccess": {
        "action": "navigate",
        "target": "verification"
      }
    },
    "onError": {
      "action": "setState",
      "updates": {"validationError": "${error}"}
    }
  }
}
```

### Pattern 3: Refresh Data

```json
{
  "type": "button",
  "properties": {"label": "Refresh"},
  "onPressed": {
    "action": "setState",
    "updates": {"isRefreshing": true},
    "onSuccess": {
      "action": "apiCall",
      "method": "GET",
      "endpoint": "/api/user/profile",
      "onSuccess": {
        "action": "setState",
        "updates": {
          "isRefreshing": false,
          "userData": "${response.data}"
        }
      },
      "onError": {
        "action": "setState",
        "updates": {"isRefreshing": false, "error": "Failed"}
      }
    }
  }
}
```

### Pattern 4: Delete with Confirmation

```json
{
  "type": "button",
  "properties": {"label": "Delete"},
  "onPressed": {
    "action": "custom",
    "handler": "showConfirmDialog",
    "parameters": {
      "title": "Are you sure?",
      "message": "This cannot be undone"
    },
    "onSuccess": {
      "action": "apiCall",
      "method": "DELETE",
      "endpoint": "/api/posts/${postId}",
      "onSuccess": {
        "action": "navigate",
        "target": "posts_list"
      }
    }
  }
}
```

---

## Variable Binding

Use `${variable_name}` to reference widget values:

```json
"body": {
  "email": "${email_input}",
  "password": "${password_input}",
  "age": "${age_slider}"
}
```

**Available Variables:**
- Input field IDs: `${field_id}`
- Checkbox/switch IDs: `${checkbox_id}`
- Slider/picker IDs: `${slider_id}`
- App state: `${userData.name}`, `${sessionToken}`

---

## Real Examples

### Example 1: Full Login Screen

See **`example/2_login_form.json`** - Complete login form with:
- Email and password inputs
- Error display
- Loading indicator
- Action chaining
- Navigation on success

### Example 2: Registration Form

See **`example/3_registration_form.json`** - Registration with:
- Multiple input fields
- Checkbox for terms
- Custom validation
- Multi-step action chain
- Error handling

### Example 3: User Profile

See **`example/4_realtime_data.json`** - User data display with:
- Real-time data binding
- Multiple buttons
- Different action types
- State management
- Conditional rendering

---

## Events That Support Actions

| Event | Type | Example |
|-------|------|---------|
| `onPressed` | Button, IconButton | Button click |
| `onTap` | Any widget, GestureDetector | Single tap |
| `onLongTap` | Any widget, GestureDetector | Long press |
| `onChanged` | Input, Checkbox, Switch | Value change |
| `onSubmitted` | TextField | Return key pressed |

---

## Testing

All actions are thoroughly tested. See `test/callback_actions_test.dart`:

```bash
flutter test test/callback_actions_test.dart
```

Tests cover:
- ✅ All 4 action types
- ✅ JSON parsing and serialization
- ✅ Action chaining with callbacks
- ✅ Real-world scenarios
- ✅ Edge cases and error handling

---

## Complete Documentation

For comprehensive details, see:
- **[CALLBACK_GUIDE.md](./CALLBACK_GUIDE.md)** - Full reference guide
- **[CALLBACK_ACTIONS_QUICK_REFERENCE.md](./CALLBACK_ACTIONS_QUICK_REFERENCE.md)** - Quick lookup
- **[Test Suite](./test/callback_actions_test.dart)** - Implementation examples

---

## Next Steps

1. **Review** the [Complete Guide](./CALLBACK_GUIDE.md)
2. **Study** the [Example Files](./example/)
3. **Read** the [Implementation Plan](./CALLBACK_SYSTEM_GENERIC_PLAN.md)

Happy coding! 🎉
