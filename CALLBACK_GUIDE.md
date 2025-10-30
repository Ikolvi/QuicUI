# QuicUI Callback Action System - Complete Guide

This guide covers the complete callback action system for QuicUI, enabling interactive flows through JSON configuration.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Core Concepts](#core-concepts)
3. [Action Types](#action-types)
4. [Common Patterns](#common-patterns)
5. [Advanced Usage](#advanced-usage)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Quick Start

The simplest callback is a navigation action on button tap:

```json
{
  "type": "button",
  "label": "Go to Dashboard",
  "onPressed": {
    "action": "navigate",
    "target": "dashboard"
  }
}
```

For a login flow with validation and API call:

```json
{
  "type": "button",
  "label": "Sign In",
  "onPressed": {
    "action": "setState",
    "updates": {"loading": true, "error": null},
    "onSuccess": {
      "action": "apiCall",
      "method": "POST",
      "endpoint": "/api/auth/login",
      "body": {"email": "${email_input}", "password": "${password_input}"},
      "onSuccess": {
        "action": "navigate",
        "target": "dashboard",
        "replace": true
      },
      "onError": {
        "action": "setState",
        "updates": {"loading": false, "error": "Invalid credentials"}
      }
    }
  }
}
```

---

## Core Concepts

### Actions

An **action** is a unit of work triggered by a user event (tap, long press, form submission, etc.). Each action:

- Has a **type** (navigate, setState, apiCall, custom)
- May perform side effects (navigate screen, update state, call API, execute handler)
- May have **onSuccess** callback (executed if action succeeds)
- May have **onError** callback (executed if action fails)

### Callbacks

**Callbacks** are actions triggered after another action completes. They enable:

- **Chaining**: Flow from one action to the next
- **Error Handling**: Execute different action on failure
- **Complex Workflows**: Multi-step processes via nested callbacks

### State Binding

QuicUI supports **variable binding** in action configuration:

```json
{
  "action": "apiCall",
  "method": "POST",
  "endpoint": "/api/users",
  "body": {
    "name": "${name_input}",
    "email": "${email_input}",
    "age": "${age_slider}"
  }
}
```

Variables are resolved from:
- Form inputs (e.g., `${email_input}`)
- Checkboxes and switches (e.g., `${agree_checkbox}`)
- Sliders and pickers (e.g., `${age_slider}`)
- App state (e.g., `${userData.id}`)

### Events

Events trigger actions. Common events:

| Event | Triggered By | Typical Actions |
|-------|--------------|-----------------|
| `onPressed` | Button tap | navigate, apiCall |
| `onTap` | Widget tap | setState, navigate |
| `onLongTap` | Long press | custom handler |
| `onChanged` | Input field change | setState |
| `onSubmitted` | Form submission | apiCall, custom |

---

## Action Types

### 1. NavigateAction

Navigate to a different screen.

**Properties:**
- `action` (required): `"navigate"`
- `target` (required): Screen/route name
- `replace` (optional): Replace current route (default: false)
- `arguments` (optional): Data to pass to target screen

**Examples:**

Simple navigation:
```json
{
  "action": "navigate",
  "target": "profile"
}
```

Replace current route (e.g., after login):
```json
{
  "action": "navigate",
  "target": "dashboard",
  "replace": true
}
```

Navigate with data:
```json
{
  "action": "navigate",
  "target": "user_detail",
  "arguments": {
    "userId": "${user_id}",
    "userName": "${user_name}"
  }
}
```

---

### 2. SetStateAction

Update widget state locally (no server communication).

**Properties:**
- `action` (required): `"setState"`
- `updates` (required): Key-value pairs to update

**Examples:**

Toggle loading state:
```json
{
  "action": "setState",
  "updates": {"isLoading": true}
}
```

Update multiple fields:
```json
{
  "action": "setState",
  "updates": {
    "firstName": "John",
    "lastName": "Doe",
    "verified": true,
    "error": null
  }
}
```

Clear errors:
```json
{
  "action": "setState",
  "updates": {"error": null, "validationErrors": {}}
}
```

---

### 3. ApiCallAction

Make HTTP requests to your backend.

**Properties:**
- `action` (required): `"apiCall"`
- `method` (required): HTTP method (GET, POST, PUT, DELETE, PATCH)
- `endpoint` (required): API endpoint path
- `body` (optional): Request body (POST/PUT/PATCH)
- `queryParams` (optional): Query string parameters (GET)
- `headers` (optional): Custom headers
- `timeout` (optional): Request timeout in seconds

**Examples:**

GET request:
```json
{
  "action": "apiCall",
  "method": "GET",
  "endpoint": "/api/user/profile",
  "headers": {
    "Authorization": "Bearer ${sessionToken}"
  }
}
```

POST request with body:
```json
{
  "action": "apiCall",
  "method": "POST",
  "endpoint": "/api/auth/login",
  "body": {
    "email": "${email_input}",
    "password": "${password_input}"
  }
}
```

DELETE with query parameters:
```json
{
  "action": "apiCall",
  "method": "DELETE",
  "endpoint": "/api/posts",
  "queryParams": {
    "id": "${post_id}",
    "userId": "${user_id}"
  }
}
```

---

### 4. CustomAction

Trigger custom Dart handler for app-specific logic.

**Properties:**
- `action` (required): `"custom"`
- `handler` (required): Handler name (must be registered in app)
- `parameters` (optional): Parameters to pass to handler

**Examples:**

Validate form:
```json
{
  "action": "custom",
  "handler": "validateForm",
  "parameters": {
    "requiredFields": ["email", "password"],
    "emailRegex": "^[^@]+@[^@]+\\.[^@]+$"
  }
}
```

Show custom dialog:
```json
{
  "action": "custom",
  "handler": "showDeleteConfirmation",
  "parameters": {
    "itemName": "${item_name}",
    "itemId": "${item_id}"
  }
}
```

Save to local storage:
```json
{
  "action": "custom",
  "handler": "saveToCache",
  "parameters": {
    "key": "user_preferences",
    "value": {"theme": "dark", "language": "en"}
  }
}
```

---

## Common Patterns

### Pattern 1: Login Flow

```json
{
  "type": "button",
  "label": "Sign In",
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
        "updates": {
          "loading": false,
          "error": "Invalid email or password"
        }
      }
    }
  }
}
```

**Flow:**
1. Set `loading=true` and clear error
2. Call API with credentials
3. On success: Clear loading flag, set logged in, navigate
4. On error: Clear loading flag, display error message

### Pattern 2: Form Validation

```json
{
  "type": "button",
  "label": "Register",
  "onPressed": {
    "action": "custom",
    "handler": "validateRegistration",
    "parameters": {
      "requiredFields": ["name", "email", "password", "password_confirm"],
      "passwordMinLength": 8,
      "emailRegex": "^[^@]+@[^@]+\\.[^@]+$"
    },
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

**Flow:**
1. Run custom validation
2. If validation passes: Submit to API
3. On API success: Navigate to verification screen
4. On any error: Display validation message

### Pattern 3: Refresh Data

```json
{
  "type": "button",
  "label": "Refresh",
  "icon": "refresh",
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
          "userData": "${response.data}",
          "lastUpdated": "${now}"
        }
      },
      "onError": {
        "action": "setState",
        "updates": {
          "isRefreshing": false,
          "error": "Failed to refresh. Please try again."
        }
      }
    }
  }
}
```

**Flow:**
1. Show loading indicator
2. Fetch fresh data from API
3. On success: Store data and clear loading
4. On error: Clear loading and show error

### Pattern 4: Toggle/Switch

```json
{
  "type": "switch",
  "id": "dark_mode_switch",
  "onChanged": {
    "action": "custom",
    "handler": "setTheme",
    "parameters": {
      "theme": "${dark_mode_switch}"
    },
    "onSuccess": {
      "action": "custom",
      "handler": "savePreference",
      "parameters": {
        "key": "theme",
        "value": "${dark_mode_switch}"
      }
    }
  }
}
```

**Flow:**
1. Apply theme change immediately
2. On success: Save preference to local storage

### Pattern 5: Delete with Confirmation

```json
{
  "type": "button",
  "label": "Delete Post",
  "onPressed": {
    "action": "custom",
    "handler": "showConfirmDialog",
    "parameters": {
      "title": "Delete Post?",
      "message": "This action cannot be undone.",
      "confirmText": "Delete",
      "cancelText": "Cancel"
    },
    "onSuccess": {
      "action": "setState",
      "updates": {"deleting": true},
      "onSuccess": {
        "action": "apiCall",
        "method": "DELETE",
        "endpoint": "/api/posts/${post_id}",
        "onSuccess": {
          "action": "navigate",
          "target": "posts_list"
        },
        "onError": {
          "action": "setState",
          "updates": {
            "deleting": false,
            "error": "Failed to delete post"
          }
        }
      }
    }
  }
}
```

**Flow:**
1. Show confirmation dialog
2. If user confirms: Set deleting flag
3. Call delete API
4. On success: Navigate away
5. On error: Clear flag and show error

---

## Advanced Usage

### Chaining Multiple Actions

Actions can be arbitrarily deep-nested:

```json
{
  "action": "setState",
  "updates": {"step": 1},
  "onSuccess": {
    "action": "apiCall",
    "method": "POST",
    "endpoint": "/api/step1",
    "onSuccess": {
      "action": "setState",
      "updates": {"step": 2},
      "onSuccess": {
        "action": "apiCall",
        "method": "POST",
        "endpoint": "/api/step2",
        "onSuccess": {
          "action": "navigate",
          "target": "completion"
        }
      }
    }
  }
}
```

### Error Recovery

Handle errors at any level:

```json
{
  "action": "apiCall",
  "method": "GET",
  "endpoint": "/api/data",
  "onError": {
    "action": "custom",
    "handler": "retryWithExponentialBackoff",
    "parameters": {"attempt": 1, "maxAttempts": 3},
    "onSuccess": {
      "action": "setState",
      "updates": {"data": "${response.data}"}
    },
    "onError": {
      "action": "setState",
      "updates": {"error": "Failed after 3 retries"}
    }
  }
}
```

### Conditional Logic in Handlers

Use custom handlers for complex conditions:

```json
{
  "action": "custom",
  "handler": "checkAndNavigate",
  "parameters": {
    "userId": "${user_id}",
    "role": "${user_role}",
    "rules": [
      {"role": "admin", "navigate": "admin_dashboard"},
      {"role": "user", "navigate": "user_dashboard"},
      {"role": "guest", "navigate": "welcome"}
    ]
  }
}
```

### Using Context Variables

Access session tokens and user data:

```json
{
  "action": "apiCall",
  "method": "POST",
  "endpoint": "/api/secure/action",
  "headers": {
    "Authorization": "Bearer ${sessionToken}",
    "X-User-Id": "${userData.id}",
    "X-Request-Id": "${requestId}"
  },
  "body": {
    "userId": "${userData.id}",
    "userEmail": "${userData.email}"
  }
}
```

---

## Best Practices

### 1. Clear State Transitions

Always explicitly set state in transitions:

✅ Good:
```json
{
  "action": "setState",
  "updates": {"loading": true, "error": null}
}
```

❌ Avoid:
```json
{
  "action": "apiCall",
  "endpoint": "/api/data"
}
```

### 2. Descriptive Error Messages

Provide user-friendly error messages:

✅ Good:
```json
{
  "action": "setState",
  "updates": {"error": "Invalid email format. Please check and try again."}
}
```

❌ Avoid:
```json
{
  "action": "setState",
  "updates": {"error": "ERROR_VALIDATION"}
}
```

### 3. Replace Route After Auth Actions

Use `replace: true` after login/logout to prevent back navigation:

✅ Good:
```json
{
  "action": "navigate",
  "target": "dashboard",
  "replace": true
}
```

❌ Avoid:
```json
{
  "action": "navigate",
  "target": "dashboard"
}
```

### 4. Organize Complex Flows

Use custom handlers for business logic, keep JSON simple:

✅ Good:
```json
{
  "action": "custom",
  "handler": "complexValidationAndSubmit",
  "parameters": {"formId": "registration"}
}
```

❌ Avoid:
```json
{
  "action": "custom",
  "handler": "validateStep1",
  "onSuccess": {
    "action": "custom",
    "handler": "validateStep2",
    "onSuccess": {
      "action": "custom",
      "handler": "validateStep3"
    }
  }
}
```

### 5. Handle Loading States

Always show feedback during async operations:

✅ Good:
```json
{
  "action": "setState",
  "updates": {"loading": true},
  "onSuccess": {
    "action": "apiCall",
    "endpoint": "/api/data",
    "onSuccess": {
      "action": "setState",
      "updates": {"loading": false, "data": "${response.data}"}
    },
    "onError": {
      "action": "setState",
      "updates": {"loading": false, "error": "Failed"}
    }
  }
}
```

### 6. Validate Before Submit

Always validate inputs before API calls:

✅ Good:
```json
{
  "action": "custom",
  "handler": "validateForm",
  "onSuccess": {
    "action": "apiCall",
    "method": "POST",
    "endpoint": "/api/submit"
  }
}
```

❌ Avoid:
```json
{
  "action": "apiCall",
  "method": "POST",
  "endpoint": "/api/submit",
  "body": {"email": "${email_input}"}
}
```

---

## Troubleshooting

### Action Not Triggering

**Problem:** Button tap doesn't execute the action.

**Solutions:**
1. Check action type spelling: `navigate`, `setState`, `apiCall`, `custom`
2. Verify JSON syntax is valid
3. Check that all required properties are present
4. Ensure variables like `${email_input}` reference actual widgets

### Variable Binding Not Working

**Problem:** `${variable_name}` not replacing with actual value.

**Solutions:**
1. Verify widget ID matches exactly (case-sensitive)
2. Check that widget exists in the current screen
3. Verify variable is set/has a value before using it

### API Call Failing

**Problem:** apiCall returns error every time.

**Solutions:**
1. Check endpoint URL is correct
2. Verify HTTP method (GET, POST, etc.)
3. Check request body has correct field names
4. Verify Authorization headers if needed
5. Check API timeout (default 30 seconds)

### Navigation Not Working

**Problem:** Navigate action doesn't change screen.

**Solutions:**
1. Check route name is registered in your app router
2. Verify `target` matches route exactly (case-sensitive)
3. Check that screen widget exists
4. Ensure no build errors in target screen

### Custom Handler Not Found

**Problem:** Custom action returns "Handler not found" error.

**Solutions:**
1. Verify handler is registered in app
2. Check handler name spelling matches registration
3. Ensure handler function exists and is properly exported
4. Verify parameters passed match handler signature

---

## API Reference

### Action.fromJson(Map<String, dynamic> json)

Parse action from JSON map.

```dart
final json = {
  'action': 'navigate',
  'target': 'dashboard'
};
final action = Action.fromJson(json);
```

### Action.toJson() → Map<String, dynamic>

Convert action to JSON map.

```dart
final action = NavigateAction(target: 'profile');
final json = action.toJson();
```

### CallbackContext

Execution environment for actions, providing access to:
- BuildContext
- State update callbacks
- Navigation handler
- HTTP client
- User data and session tokens

---

## Next Steps

- See [CALLBACK_ACTIONS_QUICK_REFERENCE.md](CALLBACK_ACTIONS_QUICK_REFERENCE.md) for quick lookup
- See example files: `example/2_login_form.json`, `example/3_registration_form.json`, `example/4_realtime_data.json`
- Check tests in `test/callback_actions_test.dart` for implementation details
