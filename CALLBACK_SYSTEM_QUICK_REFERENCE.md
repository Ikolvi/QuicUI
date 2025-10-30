# JSON Callbacks - Quick Reference

## 🎯 What We're Building

Turn this:
```json
{
  "type": "button",
  "properties": {
    "label": "Login",
    "onPressed": "login_action"  ← Simple string
  }
}
```

Into this:
```json
{
  "type": "button",
  "properties": {"label": "Login"},
  "events": {
    "onPressed": {
      "action": "login",
      "emailField": "email_id",
      "passwordField": "password_id",
      "onSuccess": {
        "action": "navigate",
        "target": "dashboard_screen"
      },
      "onError": {
        "action": "setState",
        "updates": {"error": "Invalid credentials"}
      }
    }
  }
}
```

---

## 📱 Real Example: Login Screen

```json
{
  "screens": [
    {
      "id": "login_screen",
      "rootWidget": {
        "type": "Scaffold",
        "children": [
          {
            "type": "AppBar",
            "properties": {"title": "Sign In"}
          },
          {
            "type": "Column",
            "children": [
              {
                "id": "email_input",
                "type": "TextField",
                "properties": {
                  "label": "Email",
                  "hint": "your@email.com"
                }
              },
              {
                "id": "password_input",
                "type": "TextField",
                "properties": {
                  "label": "Password",
                  "obscureText": true
                }
              },
              {
                "type": "ElevatedButton",
                "properties": {"label": "Sign In"},
                "events": {
                  "onPressed": {
                    "action": "login",
                    "emailField": "email_input",
                    "passwordField": "password_input",
                    "onSuccess": {
                      "action": "navigate",
                      "target": "dashboard_screen",
                      "replace": true
                    },
                    "onError": {
                      "action": "setState",
                      "updates": {"error": "Invalid credentials"}
                    }
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

## 🎬 Action Types Quick Overview

### 1. Navigate
Move between screens
```json
{
  "action": "navigate",
  "target": "dashboard_screen",
  "replace": true,
  "params": {"user_id": "123"}
}
```

### 2. Login
Authenticate user
```json
{
  "action": "login",
  "emailField": "email_input",
  "passwordField": "password_input",
  "onSuccess": {...},
  "onError": {...}
}
```

### 3. Submit Form
Validate & submit form
```json
{
  "action": "submitForm",
  "formId": "contact_form",
  "endpoint": "/api/contact",
  "method": "POST",
  "onSuccess": {...},
  "onError": {...}
}
```

### 4. Set State
Update UI state
```json
{
  "action": "setState",
  "updates": {
    "loading": true,
    "error": null,
    "counter": 5
  }
}
```

### 5. API Call
Call REST API directly
```json
{
  "action": "apiCall",
  "method": "POST",
  "endpoint": "/api/data",
  "body": {"name": "John"},
  "headers": {"Authorization": "Bearer token"}
}
```

### 6. Logout
Clear session
```json
{
  "action": "logout",
  "onComplete": {
    "action": "navigate",
    "target": "login_screen",
    "replace": true
  }
}
```

---

## 🔗 Action Chaining

Actions can chain with success/error handlers:

```json
{
  "action": "submitForm",
  "formId": "registration",
  "endpoint": "/api/register",
  "onSuccess": {
    "action": "navigate",
    "target": "verify_email_screen"
  },
  "onError": {
    "action": "setState",
    "updates": {"error": "Registration failed"}
  }
}
```

Flow:
1. Submit form
2. If success → navigate to verify_email_screen
3. If error → show error message

---

## 📋 Complete Login Example

Full working example with:
- Email & password inputs
- Sign In button with callback
- Error display
- Sign Up link
- Forgot Password link

See: `example/2_login_form.json`

---

## 🛠️ Implementation Phases

| Phase | What | Files |
|-------|------|-------|
| 1 | Action Models | `models/action.dart` |
| 2 | Event Handler | Update `ui_renderer.dart` |
| 3 | Login Example | `example/2_login_form.json` |
| 4 | Form Example | `example/3_registration_form.json` |
| 5 | Tests | `test/callbacks_test.dart` |
| 6 | Docs | `docs/CALLBACK_SYSTEM_GUIDE.md` |

---

## ✨ Key Features

✅ **Type-Safe Actions** - Define action types in enum  
✅ **Parameters** - Pass data through action config  
✅ **Chaining** - onSuccess & onError callbacks  
✅ **State Updates** - setState action for UI updates  
✅ **Navigation** - navigate action with params  
✅ **Forms** - submitForm with validation  
✅ **API Calls** - Direct HTTP requests  
✅ **Custom Actions** - Extend with custom types  

---

## 💡 Use Cases

1. **Login/Signup** - Validate & authenticate
2. **Forms** - Submit with validation
3. **Navigation** - Move between screens with data
4. **API Integration** - Call backends directly
5. **State Management** - Update UI state
6. **Error Handling** - Show error messages
7. **Loading States** - Show loading indicators
8. **Multi-Step Flows** - Chain actions

---

## 🚀 Ready to Start?

Full detailed plan in: `CALLBACK_SYSTEM_PLAN.md`

Next step: Create action models in `lib/src/models/action.dart`
