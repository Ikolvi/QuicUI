# JSON Callbacks - Visual Plan Summary

## 🎯 The Goal

Enable interactive flows like **login screens** using JSON instead of code:

```
BEFORE (Limited)          AFTER (Powerful)
─────────────────         ─────────────────
Button Press   ──→        Button Press
   │                           │
   └─→ Print message           ├─→ Login Action
                               │   ├─ Validate email/password
                               │   ├─ Call API
                               │   └─ Handle response
                               │
                               ├─ Success: Navigate to Dashboard
                               └─ Error: Show error message
```

---

## 🏗️ Architecture

```
                    ┌─────────────────────┐
                    │   JSON Config       │
                    │  (Button with       │
                    │   onPressed event)  │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │  Parse Action       │
                    │  (fromJson factory) │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │  Execute Action     │
                    │  (LoginAction,      │
                    │   NavigateAction,   │
                    │   etc.)             │
                    └──────────┬──────────┘
                               │
            ┌──────────────────┼──────────────────┐
            │                  │                  │
            ▼                  ▼                  ▼
        ┌────────┐        ┌─────────┐      ┌──────────┐
        │ Success│        │  Error  │      │ Complete │
        │ Action │        │ Action  │      │ Action   │
        └────┬───┘        └────┬────┘      └─────┬────┘
             │                 │                 │
             ▼                 ▼                 ▼
        ┌────────────────────────────────────────────┐
        │         Update UI & Rebuild               │
        └────────────────────────────────────────────┘
```

---

## 🎬 Six Action Types

### 1️⃣ Navigate
```json
{
  "action": "navigate",
  "target": "dashboard_screen"
}
```
→ Move to another screen

### 2️⃣ Login
```json
{
  "action": "login",
  "emailField": "email_id",
  "passwordField": "password_id",
  "onSuccess": {"action": "navigate", "target": "home"},
  "onError": {"action": "setState", "updates": {"error": "..."}}
}
```
→ Authenticate user + chain actions

### 3️⃣ SubmitForm
```json
{
  "action": "submitForm",
  "formId": "contact_form",
  "endpoint": "/api/contact",
  "method": "POST"
}
```
→ Validate & submit form data

### 4️⃣ SetState
```json
{
  "action": "setState",
  "updates": {"loading": true, "error": null}
}
```
→ Update widget state

### 5️⃣ ApiCall
```json
{
  "action": "apiCall",
  "method": "POST",
  "endpoint": "/api/data",
  "body": {"name": "John"}
}
```
→ Direct API call

### 6️⃣ Logout
```json
{
  "action": "logout",
  "onComplete": {"action": "navigate", "target": "login"}
}
```
→ Clear session & navigate

---

## 📱 Real Login Example

```
┌─────────────────────────────┐
│      Login Screen           │
├─────────────────────────────┤
│                             │
│  Email: [_____________]     │
│                             │
│  Password: [__________]     │
│                             │
│      ┌─────────────────┐    │
│      │  [Sign In] ◄────┼────┼─── onPressed Callback
│      └─────────────────┘    │
│                             │
│      Forgot Password?       │
│      Sign Up                │
│                             │
└─────────────────────────────┘
```

**What happens on button press:**
```
1. Callback executes
2. Action: "login" 
3. Email: user enters
4. Password: user enters
5. Submit to API
6. If Success: Go to Dashboard
7. If Error: Show error message
```

---

## 📋 Implementation Plan

```
Week 1:
  Day 1 ─ Phase 1: Core Models
  Day 2 ─ Phase 2: Event System  
  Day 3 ─ Phase 3-4: Examples & Tests
  Day 4 ─ Phase 5: Documentation
  Day 5 ─ Phase 6: Publish v1.0.4
```

**Key Deliverables:**
- ✅ Action enum & models
- ✅ Event parsing & execution
- ✅ 3 working examples
- ✅ Complete test suite
- ✅ User documentation

---

## 💡 Use Case: Login Flow

```json
{
  "type": "Column",
  "children": [
    {
      "id": "email_field",
      "type": "TextField",
      "properties": {"label": "Email"}
    },
    {
      "id": "password_field", 
      "type": "TextField",
      "properties": {"label": "Password", "obscureText": true}
    },
    {
      "type": "ElevatedButton",
      "properties": {"label": "Sign In"},
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
              "showError": true,
              "errorMessage": "Invalid credentials"
            }
          }
        }
      }
    }
  ]
}
```

**Result:**
- User enters email & password
- Clicks "Sign In"
- Email/password validated
- API called to authenticate
- Success → Dashboard appears
- Error → Error message shows

---

## 🔄 Action Chaining

Actions can chain with success/error handlers:

```
Submit Form
    │
    ├─ Success
    │  └─ Navigate to Confirmation
    │
    └─ Error
       └─ Show Error Message

Login
    │
    ├─ Success
    │  └─ Navigate to Dashboard
    │
    └─ Error
       └─ Show Error & Stay on Login
```

---

## 📊 Before vs After

### BEFORE (v1.0.3)
```json
{
  "type": "button",
  "properties": {
    "label": "Login",
    "onPressed": "login_action"
  }
}
```
❌ Just a string  
❌ Limited functionality  
❌ No parameters  
❌ No error handling

### AFTER (v1.0.4)
```json
{
  "type": "button",
  "properties": {"label": "Login"},
  "events": {
    "onPressed": {
      "action": "login",
      "emailField": "email_id",
      "passwordField": "password_id",
      "onSuccess": {"action": "navigate", "target": "dashboard"},
      "onError": {"action": "setState", "updates": {"error": "Failed"}}
    }
  }
}
```
✅ Structured action  
✅ Full functionality  
✅ With parameters  
✅ Error handling included

---

## 🎓 Key Features

```
Type-Safe Actions
    ↓
[ActionType Enum]
    ├─ Navigate
    ├─ Login
    ├─ SubmitForm
    ├─ SetState
    ├─ ApiCall
    └─ Logout

Chainable Callbacks
    ↓
[onSuccess] ──→ Next Action
[onError]   ──→ Error Handler

State Management
    ↓
[SetState] ──→ Update Widget State

API Integration
    ↓
[ApiCall] ──→ Backend Communication
```

---

## ✅ Planning Complete

**Status:** 📋 Ready for Implementation

**Documents Created:**
1. ✅ CALLBACK_SYSTEM_PLAN.md (detailed blueprint)
2. ✅ CALLBACK_SYSTEM_QUICK_REFERENCE.md (quick guide)
3. ✅ CALLBACK_SYSTEM_OVERVIEW.md (executive summary)
4. ✅ CALLBACK_PLAN_FOR_USER.md (user summary)
5. ✅ CALLBACK_SYSTEM_VISUAL_PLAN.md (this document)

**All pushed to GitHub:** ✅

---

## 🚀 Next: Phase 1 Implementation

**Start building:**
1. Create `action.dart` with ActionType enum
2. Implement action classes
3. Add JSON parsing
4. Write tests
5. Build examples

**Timeline:** 6-7 days to v1.0.4 release

**Status:** Ready to go! 🎉
