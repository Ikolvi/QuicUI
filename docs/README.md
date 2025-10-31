# QuicUI Documentation

Complete documentation for QuicUI - A Flutter framework for JSON-based UI rendering with callback-driven interactions.

## Quick Start

New to QuicUI? Start here:

1. **[QuicUI README](../README.md)** - Overview and basic setup
2. **[Widgets Reference](./WIDGETS.md)** - Available widgets and their JSON configurations
3. **[Navigation Guide](./NAVIGATION.md)** - Building multi-screen applications
4. **[Data Binding Guide](./DATA_BINDING.md)** - Passing and displaying dynamic data
5. **[Callbacks Documentation](./CALLBACKS.md)** - Event handling and interactions

## Documentation Structure

### Core Guides

| Document | Purpose | Audience |
|----------|---------|----------|
| [Widgets Reference](./WIDGETS.md) | Complete widget catalog with examples | All levels |
| [Navigation Guide](./NAVIGATION.md) | Multi-screen apps and navigation patterns | All levels |
| [Data Binding Guide](./DATA_BINDING.md) | Dynamic data display and context passing | Intermediate+ |
| [Callbacks Documentation](./CALLBACKS.md) | Event handling and JSON-based interactions | Intermediate+ |

### Key Concepts

#### 1. **Pure JSON UI Definition**

Define your entire UI in JSON without writing widget code:

```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Click Me"
  },
  "events": {
    "onPressed": {
      "action": "navigate",
      "screen": "nextScreen"
    }
  }
}
```

#### 2. **Callback-Driven Architecture**

Handle all interactions through JSON-configured callbacks:

```json
{
  "events": {
    "onPressed": {
      "action": "navigateWithData",
      "screen": "dashboard",
      "data": {
        "username": "${fields.username}",
        "userId": 12345
      }
    }
  }
}
```

#### 3. **Data Binding System**

Display dynamic data using simple variable patterns:

```json
{
  "type": "Text",
  "properties": {
    "text": "Welcome ${navigationData.username}!"
  }
}
```

#### 4. **Elegant Context Propagation**

Use DataBinding widget to provide context without coupling:

```json
{
  "type": "DataBinding",
  "children": [
    {
      "type": "Text",
      "properties": {
        "text": "Hello ${navigationData.name}"
      }
    }
  ]
}
```

## Feature Matrix

| Feature | Status | Guide |
|---------|--------|-------|
| 70+ Flutter Widgets | ✅ Full Support | [Widgets](./WIDGETS.md) |
| Multi-Screen Navigation | ✅ Full Support | [Navigation](./NAVIGATION.md) |
| Data Passing Between Screens | ✅ Full Support | [Data Binding](./DATA_BINDING.md) |
| JSON Event Handling | ✅ Full Support | [Callbacks](./CALLBACKS.md) |
| Form Field Management | ✅ Full Support | [Widgets](./WIDGETS.md) |
| Dynamic Variable Interpolation | ✅ Full Support | [Data Binding](./DATA_BINDING.md) |
| DataBinding Widget | ✅ Latest | [Data Binding](./DATA_BINDING.md) |

## Example: Complete Login App

### Directory Structure

```
my_app/
├── assets/
│   └── screens.json
├── lib/
│   └── main.dart
└── pubspec.yaml
```

### main.dart

```dart
import 'package:flutter/material.dart';
import 'package:quicui/quicui.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

void main() {
  runApp(const QuicUIApp());
}

class QuicUIApp extends StatefulWidget {
  const QuicUIApp({Key? key}) : super(key: key);

  @override
  State<QuicUIApp> createState() => _QuicUIAppState();
}

class _QuicUIAppState extends State<QuicUIApp> {
  late String currentScreen = 'login';
  late Map<String, dynamic> navigationData = {};
  late Map<String, dynamic> screensConfig = {};

  @override
  void initState() {
    super.initState();
    _loadScreens();
  }

  Future<void> _loadScreens() async {
    final jsonString = await rootBundle.loadString('assets/screens.json');
    final config = jsonDecode(jsonString) as Map<String, dynamic>;
    setState(() {
      screensConfig = config['screens'] ?? {};
    });
  }

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
    if (screensConfig.isEmpty) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final screenConfig = screensConfig[currentScreen] ?? {};
    final configWithCallbacks = {
      ...screenConfig,
      'onNavigateTo': _navigateTo,
      'navigationData': navigationData,
    };

    return MaterialApp(
      title: 'QuicUI App',
      debugShowCheckedModeBanner: false,
      home: UIRenderer.render(configWithCallbacks, context: context),
    );
  }
}
```

### assets/screens.json

```json
{
  "screens": {
    "login": {
      "type": "Scaffold",
      "properties": {"backgroundColor": "#F8F9FA"},
      "children": [
        {
          "type": "Column",
          "properties": {
            "mainAxisAlignment": "center",
            "crossAxisAlignment": "center"
          },
          "children": [
            {
              "type": "Text",
              "properties": {
                "text": "Welcome to QuicUI",
                "fontSize": 28,
                "fontWeight": "bold"
              }
            },
            {
              "type": "SizedBox",
              "properties": {"height": 32}
            },
            {
              "type": "Container",
              "properties": {
                "width": 320,
                "padding": {"all": 24},
                "backgroundColor": "#FFFFFF",
                "borderRadius": 12
              },
              "children": [
                {
                  "type": "TextField",
                  "properties": {
                    "fieldId": "username",
                    "label": "Username"
                  }
                },
                {
                  "type": "SizedBox",
                  "properties": {"height": 16}
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
                  "type": "SizedBox",
                  "properties": {"height": 24}
                },
                {
                  "type": "ElevatedButton",
                  "properties": {
                    "label": "Login",
                    "backgroundColor": "#6366F1"
                  },
                  "events": {
                    "onPressed": {
                      "action": "navigateWithData",
                      "screen": "dashboard",
                      "data": {
                        "username": "${fields.username}",
                        "userId": 12345
                      }
                    }
                  }
                }
              ]
            }
          ]
        }
      ]
    },
    "dashboard": {
      "type": "Scaffold",
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
                  "properties": {"margin": {"all": 16}},
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
                            "text": "Logged in: ${navigationData.loginTime}",
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
      ]
    }
  }
}
```

## Common Patterns

### Pattern 1: Form with Validation

```json
{
  "type": "Column",
  "children": [
    {
      "type": "TextField",
      "properties": {
        "fieldId": "email",
        "label": "Email"
      }
    },
    {
      "type": "Checkbox",
      "properties": {
        "fieldId": "agreeTerms",
        "label": "I agree to terms"
      }
    },
    {
      "type": "ElevatedButton",
      "properties": {"label": "Register"},
      "events": {
        "onPressed": {
          "action": "navigateWithData",
          "screen": "verification",
          "data": {
            "email": "${fields.email}",
            "agreedToTerms": "${fields.agreeTerms}"
          }
        }
      }
    }
  ]
}
```

### Pattern 2: Multi-Step Wizard

Each step passes its data to the next:

```json
{
  "action": "navigateWithData",
  "screen": "step2",
  "data": {
    "name": "${fields.name}",
    "email": "${fields.email}"
  }
}
```

Then in step 2, display and pass forward:

```json
{
  "data": {
    "name": "${navigationData.name}",
    "email": "${navigationData.email}",
    "phone": "${fields.phone}"
  }
}
```

### Pattern 3: Data Display

Use DataBinding for clean data presentation:

```json
{
  "type": "DataBinding",
  "children": [
    {
      "type": "Card",
      "children": [
        {
          "type": "Text",
          "properties": {
            "text": "User: ${navigationData.name}"
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
```

## Variable Reference

| Pattern | Example | Use Case |
|---------|---------|----------|
| `${fields.fieldId}` | `${fields.email}` | Get form field value |
| `${navigationData.key}` | `${navigationData.username}` | Access passed data |

## Best Practices

### 1. Structure Your Screens

```dart
final config = {
  'screens': {
    'login': {...},
    'dashboard': {...},
    'settings': {...},
  }
};
```

### 2. Always Inject Callbacks

```dart
final configWithCallbacks = {
  ...screenConfig,
  'onNavigateTo': _navigateTo,
  'navigationData': navigationData,
};
render(configWithCallbacks);
```

### 3. Use Consistent Field IDs

```json
{
  "fieldId": "username",  // Use snake_case
  "label": "Username"
}
```

Then reference:
```json
"value": "${fields.username}"  // Must match exactly
```

### 4. Validate Data Reception

```dart
// In destination screen
if (navigationData['username'] == null) {
  // Handle gracefully
}
```

### 5. Use DataBinding for Complex Screens

Wrap content with DataBinding for cleaner architecture:

```json
{
  "type": "DataBinding",
  "children": [...]
}
```

## Troubleshooting Guide

### Issue: Buttons Don't Respond

**Solution:** Verify callback is injected in parent config:

```dart
// ✅ Correct
render({
  ...screenConfig,
  'onNavigateTo': _navigateTo,  // Injected
});

// ❌ Wrong
render(screenConfig);  // No callback
```

### Issue: Variables Show Literally

**Solution:** Check syntax:

```json
// ❌ Wrong
"text": "${username}"
"text": "${navigationData}"

// ✅ Correct
"text": "${fields.username}"
"text": "${navigationData.username}"
```

### Issue: Data Not Displayed

**Solution:** Verify data passing chain:

1. ✅ Data sent: `"data": {...}`
2. ✅ Key names match between steps
3. ✅ Destination uses correct syntax: `${navigationData.key}`

## Architecture Overview

```
┌─────────────────────────────────┐
│  Application (main.dart)        │
│  - Manages screen state         │
│  - Injects navigationData       │
│  - Handles navigation callback  │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│  UIRenderer                     │
│  - Parses JSON config           │
│  - Creates Flutter widgets      │
│  - Injects callbacks into tree  │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│  Layout & Display Widgets       │
│  - Column, Row, Container       │
│  - Text, Card, Image            │
│  - Propagate context via        │
│    renderChild() helper         │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│  Input & Event Widgets          │
│  - Button, TextField            │
│  - DataBinding                  │
│  - Trigger callbacks on events  │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│  Event Handler                  │
│  - Parse JSON event config      │
│  - Interpolate variables        │
│  - Call navigation callback     │
└──────────────┬──────────────────┘
               │
               ▼
┌─────────────────────────────────┐
│  Navigation Callback            │
│  - Update currentScreen         │
│  - Update navigationData        │
│  - Trigger state rebuild        │
└─────────────────────────────────┘
```

## Advanced Topics

For more advanced topics, see:

- **Custom Widgets** - Extending QuicUI
- **Performance Optimization** - Rendering large lists
- **State Management** - Advanced data flow patterns
- **API Integration** - Backend communication

## API Reference

Quick links to specific widget documentation:

### Layout
- [Column/Row](./WIDGETS.md#column)
- [Container](./WIDGETS.md#container)
- [Stack](./WIDGETS.md#stack)
- [Padding/Margin](./WIDGETS.md#padding--margin)

### Display
- [Text](./WIDGETS.md#text)
- [Card](./WIDGETS.md#card)
- [Image](./WIDGETS.md#image)

### Input
- [TextField](./WIDGETS.md#textfield)
- [Buttons](./WIDGETS.md#buttons)
- [Checkbox/Radio](./WIDGETS.md#checkboxradio)

### Navigation
- [AppBar](./WIDGETS.md#appbar)
- [Scaffold](./WIDGETS.md#scaffold)

### Data Binding
- [DataBinding](./WIDGETS.md#databinding-widget)

## Contributing

To contribute to QuicUI documentation:

1. Make changes to documentation files
2. Test examples thoroughly
3. Follow existing formatting conventions
4. Submit pull request with clear description

## Support

- **GitHub Issues** - Report bugs or request features
- **Documentation** - See guides above
- **Examples** - Check example app

## Version Info

- **QuicUI Version** - See [pubspec.yaml](../pubspec.yaml)
- **Flutter Version** - 3.x or later
- **Dart Version** - 2.18 or later

## License

See [LICENSE](../LICENSE) file.

---

**Last Updated**: 2025
**Documentation Version**: 1.0
