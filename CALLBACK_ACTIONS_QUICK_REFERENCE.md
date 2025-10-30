# Generic Callback Actions - Quick Reference

## 🎯 4 Generic Action Types

### 1. Navigate
Go to another screen.

**JSON:**
```json
{"action": "navigate", "target": "dashboard"}
```

**With replace:**
```json
{"action": "navigate", "target": "login", "replace": true}
```

**With arguments:**
```json
{
  "action": "navigate",
  "target": "user_detail",
  "arguments": {"userId": 123}
}
```

---

### 2. SetState
Update widget state.

**JSON:**
```json
{
  "action": "setState",
  "updates": {"loading": false, "error": null}
}
```

---

### 3. ApiCall
Make HTTP request.

**JSON:**
```json
{
  "action": "apiCall",
  "method": "POST",
  "endpoint": "/api/login",
  "body": {"email": "${email_input.value}", "password": "..."},
  "onSuccess": {"action": "navigate", "target": "dashboard"},
  "onError": {"action": "setState", "updates": {"error": "Failed"}}
}
```

---

### 4. Custom
Call custom handler.

**JSON:**
```json
{
  "action": "custom",
  "handler": "validateForm",
  "parameters": {"fields": ["email", "password"]}
}
```

---

## 🔗 Action Chaining

```json
{
  "action": "setState",
  "updates": {"loading": true},
  "onSuccess": {
    "action": "apiCall",
    "method": "POST",
    "endpoint": "/api/data",
    "onSuccess": {
      "action": "setState",
      "updates": {"loading": false, "success": true}
    },
    "onError": {
      "action": "setState",
      "updates": {"loading": false, "error": "Failed"}
    }
  }
}
```

---

## 📱 Event Types (Generic)

Events trigger actions on widgets:

| Event | Widget | Trigger |
|-------|--------|---------|
| `onPressed` | Button | Tap |
| `onTap` | Any | Tap |
| `onLongTap` | Any | Long press |
| `onChanged` | Input, Checkbox | Value change |
| `onSubmitted` | TextField | Enter key |

---

## 💡 Common Patterns

### Login Flow
```json
{
  "type": "button",
  "events": {
    "onPressed": {
      "action": "setState",
      "updates": {"loading": true},
      "onSuccess": {
        "action": "apiCall",
        "method": "POST",
        "endpoint": "/api/auth/login",
        "body": {
          "email": "${email_field.value}",
          "password": "${password_field.value}"
        },
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
}
```

### Form Validation
```json
{
  "type": "button",
  "events": {
    "onPressed": {
      "action": "custom",
      "handler": "validateForm",
      "parameters": {"required": ["email", "password"]},
      "onSuccess": {
        "action": "apiCall",
        "method": "POST",
        "endpoint": "/api/submit"
      }
    }
  }
}
```

### Toggle State
```json
{
  "type": "checkbox",
  "events": {
    "onChanged": {
      "action": "setState",
      "updates": {"agreeToTerms": "${this.value}"}
    }
  }
}
```

---

## 🎓 Comparison: Before vs After

### BEFORE (Current - Limited)
```json
{
  "type": "button",
  "events": {
    "onPressed": "login_action"
  }
}
```
❌ Just a string  
❌ Can't pass parameters  
❌ No chaining  
❌ Limited functionality

### AFTER (Generic - Powerful)
```json
{
  "type": "button",
  "events": {
    "onPressed": {
      "action": "apiCall",
      "method": "POST",
      "endpoint": "/api/login",
      "body": {"email": "${email.value}", "password": "..."},
      "onSuccess": {"action": "navigate", "target": "dashboard"},
      "onError": {"action": "setState", "updates": {"error": "Failed"}}
    }
  }
}
```
✅ Structured action  
✅ Full parameters  
✅ Action chaining  
✅ Unlimited flexibility

---

## 📊 Action Type Comparison

| Feature | Navigate | SetState | ApiCall | Custom |
|---------|----------|----------|---------|--------|
| **Purpose** | Go to screen | Update state | HTTP request | Custom logic |
| **No args** | ❌ Need target | ❌ Need updates | ❌ Need method/endpoint | ❌ Need handler |
| **Chaining** | ✅ onSuccess/Error | ✅ onSuccess/Error | ✅ onSuccess/Error | ✅ onSuccess/Error |
| **Complexity** | Low | Low | Medium | High |
| **Use Case** | Navigation | UI state | Backend | Custom |

---

## 🔄 Event → Action Flow

```
Widget Event (onPressed, onTap, etc)
         ↓
    Parse JSON Action
         ↓
Create Action object (Navigate, SetState, ApiCall, Custom)
         ↓
    Execute action
         ↓
    ┌─────────────────┐
    │  Success?       │
    └────────┬────────┘
             │
    ┌────────┴────────┐
    │                 │
   YES               NO
    │                 │
    ▼                 ▼
onSuccess          onError
  action            action
```

---

## ✨ Benefits

✅ **Generic** - 4 actions, unlimited combinations  
✅ **Reusable** - Same actions across widgets  
✅ **Extensible** - Easy to add more actions  
✅ **Chainable** - Complex flows with simple JSON  
✅ **Type-Safe** - Factory pattern with validation  
✅ **Testable** - Easy to unit test  
✅ **Declarative** - JSON describes behavior  
✅ **Flexible** - No coupling to UI logic

---

## 📝 Summary

Instead of domain-specific actions (login, logout, etc.):
- We use **generic events** (onPressed, onTap, etc.)
- We use **generic actions** (navigate, setState, apiCall, custom)
- We **chain actions** with onSuccess/onError
- We **reuse actions** across different widgets

Result: **Infinite possibilities with just 4 actions!**
