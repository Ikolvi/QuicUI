# Callback System Guide

Complete guide to QuicUI's event and callback system for handling user interactions.

## Overview

QuicUI's callback system enables JSON-based event handling without hardcoding event logic. All user interactions (button clicks, form submissions, etc.) trigger configurable callbacks.

## Basic Callback Structure

### Button with Callback

```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Submit"
  },
  "events": {
    "onPressed": {
      "action": "navigate",
      "screen": "nextScreen"
    }
  }
}
```

### Event Properties

- **Type**: The event type (e.g., `onPressed`, `onChanged`)
- **Action**: What to do when event fires (e.g., `navigate`, `navigateWithData`)
- **Screen**: Target screen for navigation actions
- **Data**: Data to pass with navigation actions

## Supported Actions

### 1. Navigate

Simple screen switching without data:

```json
{
  "type": "ElevatedButton",
  "properties": {"label": "Next"},
  "events": {
    "onPressed": {
      "action": "navigate",
      "screen": "dashboard"
    }
  }
}
```

### 2. NavigateWithData

Navigate while passing data:

```json
{
  "type": "ElevatedButton",
  "properties": {"label": "Login"},
  "events": {
    "onPressed": {
      "action": "navigateWithData",
      "screen": "dashboard",
      "data": {
        "username": "${fields.username}",
        "userId": 123,
        "sessionId": "sess_abc123"
      }
    }
  }
}
```

**Data can include:**
- Static values: `"userId": 123`
- Field values: `"email": "${fields.email}"`
- Passed data: `"role": "${navigationData.role}"`

## Event Types

### Button Events

#### ElevatedButton

```json
{
  "type": "ElevatedButton",
  "properties": {"label": "Click Me"},
  "events": {
    "onPressed": {
      "action": "navigate",
      "screen": "nextScreen"
    }
  }
}
```

#### TextButton

```json
{
  "type": "TextButton",
  "properties": {"label": "Cancel"},
  "events": {
    "onPressed": {
      "action": "navigate",
      "screen": "previousScreen"
    }
  }
}
```

#### OutlinedButton

```json
{
  "type": "OutlinedButton",
  "properties": {"label": "Skip"},
  "events": {
    "onPressed": {
      "action": "navigate",
      "screen": "home"
    }
  }
}
```

#### IconButton

```json
{
  "type": "IconButton",
  "properties": {"icon": "settings"},
  "events": {
    "onPressed": {
      "action": "navigate",
      "screen": "settings"
    }
  }
}
```

### Form Events

#### TextField

```json
{
  "type": "TextField",
  "properties": {
    "fieldId": "email",
    "label": "Email"
  },
  "events": {
    "onChanged": {
      "action": "validateEmail"  // Custom action
    },
    "onSubmitted": {
      "action": "navigateWithData",
      "screen": "confirmEmail",
      "data": {
        "email": "${fields.email}"
      }
    }
  }
}
```

#### Checkbox

```json
{
  "type": "Checkbox",
  "properties": {
    "fieldId": "acceptTerms",
    "label": "I accept terms"
  },
  "events": {
    "onChanged": {
      "action": "updateUI"  // Custom action
    }
  }
}
```

### Interaction Events

#### GestureDetector

```json
{
  "type": "GestureDetector",
  "properties": {
    "onTap": {
      "action": "navigate",
      "screen": "details"
    }
  },
  "children": [...]
}
```

#### ListTile

```json
{
  "type": "ListTile",
  "properties": {
    "title": "Item 1",
    "onTap": {
      "action": "navigateWithData",
      "screen": "itemDetails",
      "data": {
        "itemId": 1
      }
    }
  }
}
```

## Variable Interpolation in Callbacks

### Field Values

Access form field values using `${fields.fieldId}`:

```json
{
  "type": "ElevatedButton",
  "properties": {"label": "Submit"},
  "events": {
    "onPressed": {
      "action": "navigateWithData",
      "screen": "summary",
      "data": {
        "username": "${fields.username}",
        "email": "${fields.email}",
        "message": "${fields.message}"
      }
    }
  }
}
```

### Navigation Data

Access passed data using `${navigationData.key}`:

```json
{
  "type": "ElevatedButton",
  "properties": {"label": "Confirm"},
  "events": {
    "onPressed": {
      "action": "navigateWithData",
      "screen": "processing",
      "data": {
        "previousUsername": "${navigationData.username}",
        "newEmail": "${fields.newEmail}"
      }
    }
  }
}
```

## Complete Callback Examples

### Example 1: Login Flow

```json
{
  "screens": {
    "login": {
      "type": "Scaffold",
      "children": [
        {
          "type": "Column",
          "properties": {"mainAxisAlignment": "center"},
          "children": [
            {
              "type": "TextField",
              "properties": {
                "fieldId": "username",
                "label": "Username"
              }
            },
            {
              "type": "TextField",
              "properties": {
                "fieldId": "password",
                "label": "Password",
                "obscureText": true
              }
            },
            {
              "type": "ElevatedButton",
              "properties": {"label": "Login"},
              "events": {
                "onPressed": {
                  "action": "navigateWithData",
                  "screen": "dashboard",
                  "data": {
                    "username": "${fields.username}",
                    "sessionId": "sess_abc123"
                  }
                }
              }
            },
            {
              "type": "TextButton",
              "properties": {"label": "Create Account"},
              "events": {
                "onPressed": {
                  "action": "navigate",
                  "screen": "signup"
                }
              }
            }
          ]
        }
      ]
    },
    "dashboard": {
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

### Example 2: Form with Validation

```json
{
  "type": "Column",
  "children": [
    {
      "type": "TextField",
      "properties": {
        "fieldId": "email",
        "label": "Email",
        "hint": "user@example.com"
      }
    },
    {
      "type": "TextField",
      "properties": {
        "fieldId": "password",
        "label": "Password",
        "obscureText": true
      }
    },
    {
      "type": "Checkbox",
      "properties": {
        "fieldId": "agreeTerms",
        "label": "I agree to terms and conditions"
      }
    },
    {
      "type": "ElevatedButton",
      "properties": {
        "label": "Register",
        "enabled": true
      },
      "events": {
        "onPressed": {
          "action": "navigateWithData",
          "screen": "verification",
          "data": {
            "email": "${fields.email}",
            "password": "${fields.password}",
            "agreedToTerms": "${fields.agreeTerms}",
            "userId": 12345
          }
        }
      }
    }
  ]
}
```

### Example 3: Multi-Step Wizard

**Step 1:**
```json
{
  "screens": {
    "step1": {
      "type": "Scaffold",
      "children": [
        {
          "type": "Column",
          "children": [
            {
              "type": "Text",
              "properties": {"text": "Step 1: Personal Info"}
            },
            {
              "type": "TextField",
              "properties": {
                "fieldId": "firstName",
                "label": "First Name"
              }
            },
            {
              "type": "TextField",
              "properties": {
                "fieldId": "lastName",
                "label": "Last Name"
              }
            },
            {
              "type": "ElevatedButton",
              "properties": {"label": "Next"},
              "events": {
                "onPressed": {
                  "action": "navigateWithData",
                  "screen": "step2",
                  "data": {
                    "firstName": "${fields.firstName}",
                    "lastName": "${fields.lastName}"
                  }
                }
              }
            }
          ]
        }
      ]
    }
  }
}
```

**Step 2:**
```json
{
  "step2": {
    "type": "Scaffold",
    "children": [
      {
        "type": "Column",
        "children": [
          {
            "type": "Text",
            "properties": {"text": "Step 2: Contact Info"}
          },
          {
            "type": "Text",
            "properties": {
              "text": "Name: ${navigationData.firstName} ${navigationData.lastName}"
            }
          },
          {
            "type": "TextField",
            "properties": {
              "fieldId": "email",
              "label": "Email"
            }
          },
          {
            "type": "ElevatedButton",
            "properties": {"label": "Next"},
            "events": {
              "onPressed": {
                "action": "navigateWithData",
                "screen": "review",
                "data": {
                  "firstName": "${navigationData.firstName}",
                  "lastName": "${navigationData.lastName}",
                  "email": "${fields.email}"
                }
              }
            }
          }
        ]
      }
    ]
  }
}
```

## Callback Flow Diagram

```
┌─────────────────┐
│  User Interaction│
│ (Button Click)  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Event Handler Triggered             │
│ (onPressed, onChanged, etc.)        │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Parse Event Configuration from JSON │
│ - Extract action name               │
│ - Extract target screen             │
│ - Extract data object               │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Process Variable Interpolation      │
│ - Replace ${fields.x} with values   │
│ - Replace ${navigationData.x}       │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Execute Callback Action             │
│ - navigate(screen)                  │
│ - navigateWithData(screen, data)    │
│ - Custom action handlers            │
└────────┬────────────────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Update Application State │
│ - Change screen          │
│ - Update navigationData  │
│ - Trigger re-render      │
└──────────────────────────┘
```

## Best Practices

### 1. Always Use Descriptive Action Names

**❌ Wrong:**
```json
{"action": "nav"}
```

**✅ Correct:**
```json
{"action": "navigate"}  // or "navigateWithData"
```

### 2. Provide Complete Navigation Data

**❌ Wrong:**
```json
{
  "action": "navigateWithData",
  "screen": "dashboard"
  // Missing data object
}
```

**✅ Correct:**
```json
{
  "action": "navigateWithData",
  "screen": "dashboard",
  "data": {
    "username": "${fields.username}",
    "sessionId": "session_abc123"
  }
}
```

### 3. Use Consistent Field IDs

**❌ Wrong:**
```json
{
  "type": "TextField",
  "properties": {
    "fieldId": "user_name",
    "label": "Username"
  }
}
// Later reference:
"username": "${fields.username}"  // Doesn't match!
```

**✅ Correct:**
```json
{
  "type": "TextField",
  "properties": {
    "fieldId": "username",
    "label": "Username"
  }
}
// Reference:
"username": "${fields.username}"  // Matches!
```

### 4. Include Type Safety Where Possible

```json
{
  "data": {
    "username": "${fields.username}",
    "userId": 12345,
    "sessionId": "session_abc123",
    "isAdmin": false
  }
}
```

### 5. Test Variable Interpolation

Always verify that field IDs exist before using them:

```json
{
  "data": {
    "email": "${fields.email}",
    "phone": "${fields.phone ?? 'Not provided'}"
  }
}
```

## Troubleshooting

### Issue: Callback Not Triggering

**Check:**
1. ✅ Event key is correct (e.g., `onPressed` not `on_pressed`)
2. ✅ Action name is spelled correctly
3. ✅ Screen name matches defined screens
4. ✅ Callback is properly injected in parent config

### Issue: Variables Not Interpolating

**Check:**
1. ✅ Field IDs match exactly (case-sensitive)
2. ✅ Using correct syntax: `${fields.fieldId}` not `${fieldId}`
3. ✅ TextField has `fieldId` property defined
4. ✅ User entered text before clicking button

### Issue: Data Not Appearing in Destination Screen

**Check:**
1. ✅ Data is passed in event: `"data": {...}`
2. ✅ Destination screen uses `${navigationData.key}` syntax
3. ✅ Key names match between data object and display widgets
4. ✅ Parent component injects `navigationData` into children

## Advanced Patterns

### Conditional Actions

Choose action based on form state:

```json
{
  "type": "ElevatedButton",
  "properties": {"label": "Submit"},
  "events": {
    "onPressed": {
      "action": "navigateWithData",
      "screen": "${fields.userType == 'admin' ? 'admin_panel' : 'user_dashboard'}",
      "data": {
        "userType": "${fields.userType}"
      }
    }
  }
}
```

### Chained Navigation

Pass data through multiple screens:

```json
{
  "action": "navigateWithData",
  "screen": "confirm",
  "data": {
    "step1Data": "${navigationData.step1Data}",
    "step2Data": "${navigationData.step2Data}",
    "step3Data": "${fields.step3Input}"
  }
}
```

## Related Documentation

- [Navigation Guide](./NAVIGATION.md)
- [Data Binding Guide](./DATA_BINDING.md)
- [Widget Reference](./WIDGETS.md)
- [QuicUI README](../README.md)
