# Navigation Guide

Comprehensive guide for implementing multi-screen navigation in QuicUI applications.

## Overview

QuicUI provides two primary navigation mechanisms:

1. **`navigate`** - Simple screen switching
2. **`navigateWithData`** - Screen switching with data passing

Both are event-based and callback-driven, making them flexible and composable.

## Basic Navigation

### Simple Navigation

Navigate to a screen without passing data:

```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Go to Next Screen"
  },
  "events": {
    "onPressed": {
      "action": "navigate",
      "screen": "nextScreen"
    }
  }
}
```

**Dart Code:**

```dart
void _navigateTo(String screen, {Map<String, dynamic>? data}) {
  setState(() {
    currentScreen = screen;
    if (data != null) {
      navigationData = data;
    }
  });
}
```

### Navigation with Data

Pass data when navigating to a new screen:

```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Login"
  },
  "events": {
    "onPressed": {
      "action": "navigateWithData",
      "screen": "dashboard",
      "data": {
        "username": "${fields.username}",
        "loginTime": "${now}",
        "userId": 12345
      }
    }
  }
}
```

The data becomes available in the destination screen via `${navigationData.keyName}` syntax.

## Multi-Screen Architecture

### Screen Definition

Define all screens in your configuration:

```json
{
  "screens": {
    "login": {
      "type": "Scaffold",
      "children": [...]
    },
    "dashboard": {
      "type": "Scaffold",
      "children": [...]
    },
    "settings": {
      "type": "Scaffold",
      "children": [...]
    }
  }
}
```

### Screen State Management

Use StatefulWidget to manage screen switching:

```dart
class QuicUIApp extends StatefulWidget {
  @override
  State<QuicUIApp> createState() => _QuicUIAppState();
}

class _QuicUIAppState extends State<QuicUIApp> {
  late String currentScreen = 'login';
  late Map<String, dynamic> navigationData = {};

  void _navigateTo(String screen, {Map<String, dynamic>? data}) {
    setState(() {
      currentScreen = screen;
      if (data != null) {
        navigationData = data;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenConfig = config['screens'][currentScreen];
    final configWithCallbacks = {
      ...screenConfig,
      'onNavigateTo': _navigateTo,
      'navigationData': navigationData,
    };
    
    return MaterialApp(
      home: UIRenderer.render(configWithCallbacks, context: context),
    );
  }
}
```

## Navigation Patterns

### Login Flow

**1. Login Screen**

```json
{
  "type": "Scaffold",
  "children": [
    {
      "type": "Column",
      "properties": {"mainAxisAlignment": "center"},
      "children": [
        {
          "type": "TextField",
          "properties": {
            "fieldId": "email",
            "label": "Email"
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
                "userEmail": "${fields.email}",
                "loginTime": "${now}",
                "sessionId": "session_12345"
              }
            }
          }
        },
        {
          "type": "TextButton",
          "properties": {"label": "Sign Up"},
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
}
```

**2. Dashboard Screen**

```json
{
  "type": "Scaffold",
  "properties": {
    "backgroundColor": "#F8F9FA"
  },
  "children": [
    {
      "type": "AppBar",
      "properties": {"title": "Dashboard"}
    },
    {
      "type": "DataBinding",
      "children": [
        {
          "type": "Column",
          "children": [
            {
              "type": "Card",
              "children": [
                {
                  "type": "Padding",
                  "properties": {"padding": {"all": 16}},
                  "children": [
                    {
                      "type": "Text",
                      "properties": {
                        "text": "Welcome ${navigationData.userEmail}"
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
```

### Multi-Step Form

Create wizard-style forms by passing accumulating data:

```json
{
  "screens": {
    "form_step1": {
      "type": "Scaffold",
      "children": [
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
              "screen": "form_step2",
              "data": {
                "firstName": "${fields.firstName}",
                "lastName": "${fields.lastName}"
              }
            }
          }
        }
      ]
    },
    "form_step2": {
      "type": "Scaffold",
      "children": [
        {
          "type": "Column",
          "children": [
            {
              "type": "Text",
              "properties": {
                "text": "You entered: ${navigationData.firstName} ${navigationData.lastName}"
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
              "properties": {"label": "Submit"},
              "events": {
                "onPressed": {
                  "action": "navigateWithData",
                  "screen": "success",
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
    },
    "success": {
      "type": "Scaffold",
      "children": [
        {
          "type": "DataBinding",
          "children": [
            {
              "type": "Column",
              "properties": {"mainAxisAlignment": "center"},
              "children": [
                {
                  "type": "Text",
                  "properties": {
                    "text": "Registration Complete!"
                  }
                },
                {
                  "type": "Text",
                  "properties": {
                    "text": "Name: ${navigationData.firstName} ${navigationData.lastName}"
                  }
                },
                {
                  "type": "Text",
                  "properties": {
                    "text": "Email: ${navigationData.email}"
                  }
                }
              ]
            }
          ]
        }
      ]
    }
  }
}
```

### Modal/Dialog Navigation

Navigate back to a previous screen:

```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Cancel"
  },
  "events": {
    "onPressed": {
      "action": "navigate",
      "screen": "previousScreen"
    }
  }
}
```

**Note:** Currently, QuicUI uses simple forward navigation. To implement back navigation with history, implement a navigation stack in your state management.

## Advanced Navigation

### Back Navigation with Stack

Implement a navigation history:

```dart
class _QuicUIAppState extends State<QuicUIApp> {
  late List<String> screenStack = ['login'];
  late Map<String, dynamic> navigationData = {};

  void _navigateTo(String screen, {Map<String, dynamic>? data}) {
    setState(() {
      screenStack.add(screen);
      if (data != null) {
        navigationData = data;
      }
    });
  }

  void _goBack() {
    if (screenStack.length > 1) {
      setState(() {
        screenStack.removeLast();
      });
    }
  }

  String get currentScreen => screenStack.last;
}
```

Then add back button to AppBar:

```json
{
  "type": "AppBar",
  "properties": {
    "title": "Screen Title",
    "showBackButton": true
  },
  "events": {
    "onBackPressed": {
      "action": "goBack"
    }
  }
}
```

### Conditional Navigation

Use data values to determine next screen:

```json
{
  "type": "ElevatedButton",
  "properties": {"label": "Continue"},
  "events": {
    "onPressed": {
      "action": "navigateWithData",
      "screen": "${navigationData.userRole == 'admin' ? 'admin_panel' : 'user_dashboard'}",
      "data": {
        "userRole": "${navigationData.userRole}",
        "userId": "${navigationData.userId}"
      }
    }
  }
}
```

**Note:** Conditional screen names currently require preprocessing. Consider using fixed screen names and conditional content instead.

### Deep Linking

Navigate directly to a screen with initial data:

```dart
void _handleDeepLink(String deepLink) {
  // Example: "app://dashboard?username=john&userId=123"
  final uri = Uri.parse(deepLink);
  final data = {
    'username': uri.queryParameters['username'],
    'userId': uri.queryParameters['userId'],
  };
  _navigateTo(uri.path.replaceFirst('/app/', ''), data: data);
}
```

## Best Practices

### 1. Always Include Screen Definitions

Define all screens in your configuration:

```dart
final config = {
  'screens': {
    'login': {...},
    'dashboard': {...},
    'settings': {...},
  }
};
```

### 2. Validate Navigation Data

Always check if expected data exists:

```json
{
  "type": "Text",
  "properties": {
    "text": "${navigationData.username ?? 'Guest'}"
  }
}
```

### 3. Use Consistent Data Structure

Plan your data schema across screens:

```dart
// Define at app level
class UserData {
  final String username;
  final String email;
  final DateTime loginTime;
  
  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'loginTime': loginTime.toIso8601String(),
  };
}
```

### 4. Clear Sensitive Data on Logout

Reset navigationData when user logs out:

```dart
void _logout() {
  setState(() {
    currentScreen = 'login';
    navigationData = {}; // Clear all data
  });
}
```

### 5. Use DataBinding for Complex Screens

Wrap screen content with DataBinding for cleaner code:

```json
{
  "type": "Scaffold",
  "children": [
    {
      "type": "DataBinding",
      "children": [
        {
          "type": "Column",
          "children": [...]
        }
      ]
    }
  ]
}
```

## Common Pitfalls

### 1. Forgetting to Inject Callback

**❌ Wrong:**
```dart
render(screenConfig);  // No navigationData injected
```

**✅ Correct:**
```dart
render({
  ...screenConfig,
  'onNavigateTo': _navigateTo,
  'navigationData': navigationData,
});
```

### 2. Using Wrong Action Names

**❌ Wrong:**
```json
{"action": "goToScreen"}  // Not a valid action
```

**✅ Correct:**
```json
{"action": "navigate"}  // or "navigateWithData"
```

### 3. Missing Data in navigateWithData

**❌ Wrong:**
```json
{
  "action": "navigateWithData",
  "screen": "dashboard"
  // No data provided
}
```

**✅ Correct:**
```json
{
  "action": "navigateWithData",
  "screen": "dashboard",
  "data": {
    "username": "${fields.username}"
  }
}
```

### 4. Incorrect Variable Syntax

**❌ Wrong:**
```json
{"text": "Hello ${user.name}"}     // Should be navigationData
{"text": "Hello ${navigationData}"}  // Missing property access
```

**✅ Correct:**
```json
{"text": "Hello ${navigationData.name}"}
```

## Testing Navigation

### Manual Testing Checklist

- [ ] All screens render without errors
- [ ] Navigation buttons trigger screen changes
- [ ] Data is passed between screens
- [ ] Variables display correctly in destination screen
- [ ] Field values are captured accurately
- [ ] Timestamps are generated correctly
- [ ] Back navigation works (if implemented)
- [ ] No data leaks between sessions

### Example Test Scenario

1. **Launch app** - Verify login screen appears
2. **Enter credentials** - Type test values in fields
3. **Click login** - Verify navigation to dashboard
4. **Check display** - Verify username displays correctly
5. **Check timestamp** - Verify login time displays

## Related Documentation

- [Data Binding Guide](./DATA_BINDING.md)
- [Widget Reference](./WIDGETS.md)
- [Callback System](./CALLBACKS.md)
- [QuicUI README](../README.md)
