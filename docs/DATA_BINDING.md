# Data Binding in QuicUI

QuicUI provides a flexible, decoupled data binding system that allows you to display dynamic data in your JSON-based UI without tight coupling between components.

## Overview

Data binding enables you to:
- Display user-entered form data on other screens
- Show passed navigation data in display widgets
- Use dynamic timestamps and field values
- Keep the rendering logic separate from data processing

## Supported Variable Patterns

### 1. Navigation Data: `${navigationData.key}`

Access data passed during screen navigation. When navigating to a new screen, you can pass a data object that becomes available to Text and other widgets.

**Example:**
```json
{
  "type": "Text",
  "properties": {
    "text": "Welcome ${navigationData.username}!",
    "fontSize": 24
  }
}
```

When navigating with:
```dart
onNavigateTo('dashboard', data: {'username': 'John', 'role': 'Admin'})
```

The Text widget will display: `Welcome John!`

### 2. Form Fields: `${fields.fieldId}`

Access values from form fields in the current or previous screens. Field IDs are defined in TextField/TextFormField widgets.

**Example - In Login Screen:**
```json
{
  "type": "TextField",
  "properties": {
    "fieldId": "username",
    "label": "Username"
  }
}
```

**Example - Button Event:**
```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Login",
    "events": {
      "onPressed": {
        "action": "navigateWithData",
        "screen": "dashboard",
        "data": {
          "username": "${fields.username}",
          "sessionId": "session_abc123"
        }
      }
    }
  }
}
```

## How It Works

### Architecture

```
┌─────────────────────────────────────────────┐
│           Screen Config (JSON)              │
│  - navigationData: {username: "John"}       │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│      renderChild() helper function          │
│  - Injects parent config into child         │
│  - Propagates navigationData through tree   │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│   Text Widget Properties (has navigationData)
│  - text: "Welcome ${navigationData.username}"|
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  _processVariableString() helper            │
│  - Regex pattern matching                   │
│  - Variable substitution                    │
│  - Returns processed text                   │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│        Final Rendered Text                  │
│     "Welcome John!"                         │
└─────────────────────────────────────────────┘
```

### Key Design Principles

1. **Decoupled**: Variable processing is separate from rendering logic
2. **Flexible**: Support for multiple variable types without hardcoding
3. **Regex-based**: Pattern matching is extensible for new variable types
4. **Context-driven**: Data flows through the widget tree via parent config injection
5. **Type-safe**: Dart's type system ensures data validity

## Complete Example: Login → Dashboard Flow

### 1. Login Screen (login.json)

```json
{
  "type": "Scaffold",
  "properties": {
    "backgroundColor": "#F8F9FA"
  },
  "children": [
    {
      "type": "Column",
      "properties": {
        "mainAxisAlignment": "center",
        "crossAxisAlignment": "center"
      },
      "children": [
        {
          "type": "TextField",
          "properties": {
            "fieldId": "username",
            "label": "Enter your username"
          }
        },
        {
          "type": "ElevatedButton",
          "properties": {
            "label": "Login",
            "events": {
              "onPressed": {
                "action": "navigateWithData",
                "screen": "dashboard",
                "data": {
                  "username": "${fields.username}"
                }
              }
            }
          }
        }
      ]
    }
  ]
}
```

### 2. Dashboard Screen (dashboard.json)

```json
{
  "type": "Scaffold",
  "properties": {
    "backgroundColor": "#F8F9FA"
  },
  "children": [
    {
      "type": "AppBar",
      "properties": {
        "title": "Dashboard"
      }
    },
    {
      "type": "Column",
      "properties": {
        "crossAxisAlignment": "stretch"
      },
      "children": [
        {
          "type": "Card",
          "properties": {
            "margin": {"all": 16}
          },
          "children": [
            {
              "type": "Padding",
              "properties": {"padding": {"all": 16}},
              "children": [
                {
                  "type": "Text",
                  "properties": {
                    "text": "Hi ${navigationData.username}! 👋",
                    "fontSize": 24,
                    "fontWeight": "bold"
                  }
                },
                {
                  "type": "SizedBox",
                  "properties": {"height": 8}
                },
                {
                  "type": "Text",
                  "properties": {
                    "text": "Login Time: ${navigationData.loginTime}",
                    "fontSize": 12,
                    "color": "#6B7280"
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
```

### 3. Main.dart Setup

```dart
void main() async {
  final config = {...}; // Load from assets
  runApp(QuicUIApp(screenConfig: config));
}

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

## API Reference

### _processVariableString()

```dart
static String _processVariableString(
  String text,
  Map<String, dynamic> context
)
```

**Parameters:**
- `text`: The text string containing variable patterns
- `context`: A map containing `navigationData` and other context

**Returns:** The processed text with all variables substituted

**Supported Patterns:**
- `${navigationData.keyName}` - from navigationData map
- `${fields.fieldId}` - from TextField with given fieldId

### renderChild()

```dart
static Widget renderChild(
  Map<String, dynamic> childData,
  Map<String, dynamic> parentConfig,
  {BuildContext? context}
)
```

**Purpose:** Injects parent config's `navigationData` and `onNavigateTo` into child widget before rendering

**Behavior:** Ensures data context is propagated through the entire widget tree

## Best Practices

1. **Use consistent field IDs**: Use descriptive, consistent IDs in TextFields
   ```json
   {"fieldId": "email"} // Good
   {"fieldId": "f1"}    // Avoid
   ```

2. **Store data in navigationData**: Don't replicate data; pass it once
   ```dart
   // Good
   onNavigateTo('dashboard', data: {'user': userData})
   
   // Avoid duplicating across multiple navigateWithData calls
   ```

3. **Validate data on receipt**: In main.dart, validate navigationData before using
   ```dart
   if (navigationData['username'] == null) {
     // Handle missing data gracefully
   }
   ```

4. **Use meaningful variable names**: Make your JSON readable
   ```json
   "text": "Welcome ${navigationData.userName}!"  // Clear
   "text": "Welcome ${navigationData.a}!"        // Confusing
   ```

5. **Combine with styling**: Use variables with proper styling
   ```json
   {
     "type": "Text",
     "properties": {
       "text": "Hello ${navigationData.name}",
       "fontSize": 20,
       "color": "#1F2937",
       "fontWeight": "bold"
     }
   }
   ```

## Troubleshooting

### Variables Not Being Substituted

**Problem:** Text shows `${navigationData.username}` literally

**Solutions:**
1. Verify `navigationData` is being passed during navigation
2. Check the key name matches exactly (case-sensitive)
3. Ensure Text widget is receiving the properties with navigationData
4. Check console logs for substitution attempts

**Logs to look for:**
```
💡 Replaced ${navigationData.username} with John
💡 Text variable processing: Welcome John!
```

### Field Values Not Extracted

**Problem:** `${fields.fieldId}` shows literally in output

**Solutions:**
1. Verify TextField has `fieldId` property set
2. Confirm fieldId matches in button event data
3. Ensure user entered text before clicking button
4. Check field controller is properly registered

## Design Philosophy: No Magic Variable Names

QuicUI follows a principle of **explicit data management** without magic variable names. Variable interpolation is limited to:
- `${navigationData.key}` - accessing passed data
- `${fields.fieldId}` - accessing form field values

This keeps the system:
- ✅ Simple and predictable
- ✅ Without hidden side effects
- ✅ Easy to understand and debug
- ✅ Type-safe when data is prepared

### Timestamps and Computed Data

For timestamps, dates, and other computed values, handle them explicitly in Dart code:

**Example:**

Instead of trying to add special patterns in JSON, compute in main.dart:

```dart
void _navigateTo(String screen, {Map<String, dynamic>? data}) {
  final enrichedData = {
    ...?data,
    'loginTime': DateTime.now().toIso8601String(),
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'sessionId': _generateSessionId(),
  };
  
  setState(() {
    currentScreen = screen;
    navigationData = enrichedData;
  });
}
```

Then display in JSON:

```json
{
  "type": "Text",
  "properties": {
    "text": "Logged in at: ${navigationData.loginTime}"
  }
}
```

**Benefits:**
- ✅ Clear data flow
- ✅ Type safety in Dart
- ✅ Easy to test
- ✅ No magic strings in JSON

## Future Extensions

Possible future additions to the data binding system:

1. **Nested properties**: `${navigationData.user.firstName}`
2. **Filters**: `${navigationData.date | format:'MM/dd/yyyy'}`
3. **Conditions**: `${navigationData.role == 'admin' ? 'Admin Panel' : 'User Dashboard'}`
4. **Array access**: `${navigationData.items[0].name}`
5. **Global state**: `${global.appName}`

*Note: These are potential future enhancements. Current system focuses on explicit data passing without magic patterns.*

## Related Documentation

- [Callback System](./CALLBACKS.md) - How events trigger navigation
- [JSON Widget Reference](./WIDGETS.md) - Available widgets and properties
- [Navigation Guide](./NAVIGATION.md) - Screen navigation patterns
