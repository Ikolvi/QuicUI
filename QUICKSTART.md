# QuicUI Quick Start Guide

Get up and running with QuicUI in minutes!

## 📦 Installation

### 1. Add to your project

```bash
cd your_flutter_project
flutter pub add quicui flutter_bloc:^9.0.0 equatable:^2.0.5 bloc:^9.0.0
```

Or manually add to `pubspec.yaml`:

```yaml
dependencies:
  quicui: ^0.0.1
  flutter_bloc: ^9.0.0
  equatable: ^2.0.5
  bloc: ^9.0.0
```

### 2. Initialize QuicUI with BLoC

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quicui/quicui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize ObjectBox for local storage
  await QuicUIManager.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider(
        create: (context) => QuicBloc(),
        child: const HomePage(),
      ),
    );
  }
}

---

## 🎯 Basic Examples

### 1. Simple Text & Button

**JSON:**
```json
{
  "type": "column",
  "properties": {
    "padding": "16",
    "mainAxisAlignment": "center",
    "crossAxisAlignment": "center"
  },
  "children": [
    {
      "type": "text",
      "properties": {
        "text": "Hello QuicUI!",
        "fontSize": 24,
        "fontWeight": "bold"
      }
    },
    {
      "type": "button",
      "properties": {
        "label": "Click Me",
        "backgroundColor": "#6366F1"
      },
      "onPressed": {
        "type": "custom",
        "handler": "showSnackbar",
        "message": "Button clicked!"
      }
    }
  ]
}
```

**Dart:**
```dart
import 'package:quicui/quicui.dart';

class SimpleExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return QuicUIScreen(
      jsonData: homeScreenJson,
    );
  }
}
```

---

### 2. User Form with Validation

**JSON:**
```json
{
  "type": "form",
  "formId": "user_form",
  "properties": {
    "padding": "16"
  },
  "fields": [
    {
      "type": "textfield",
      "fieldName": "name",
      "label": "Full Name",
      "hint": "Enter your name",
      "validators": [
        {
          "type": "required",
          "message": "Name is required"
        },
        {
          "type": "minLength",
          "value": 2,
          "message": "Name must be at least 2 characters"
        }
      ]
    },
    {
      "type": "textfield",
      "fieldName": "email",
      "label": "Email",
      "hint": "Enter your email",
      "validators": [
        {
          "type": "required",
          "message": "Email is required"
        },
        {
          "type": "email",
          "message": "Please enter a valid email"
        }
      ]
    },
    {
      "type": "textfield",
      "fieldName": "password",
      "label": "Password",
      "obscureText": true,
      "validators": [
        {
          "type": "required",
          "message": "Password is required"
        },
        {
          "type": "minLength",
          "value": 8,
          "message": "Password must be at least 8 characters"
        }
      ]
    }
  ],
  "submitButton": {
    "label": "Register"
  },
  "submitAction": {
    "type": "api",
    "method": "POST",
    "url": "https://api.example.com/auth/register",
    "body": {
      "name": "${name}",
      "email": "${email}",
      "password": "${password}"
    },
    "onSuccess": {
      "type": "navigate",
      "route": "/home"
    },
    "onError": {
      "type": "custom",
      "handler": "showError"
    }
  }
}
```

**Dart:**
```dart
class FormExample extends StatelessWidget {
  const FormExample({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuicFormBloc(fields: userFormFields),
      child: Scaffold(
        appBar: AppBar(title: const Text('User Registration')),
        body: BlocBuilder<QuicFormBloc, FormBlocState>(
          builder: (context, state) {
            if (state is FormSubmitted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Form submitted successfully')),
                );
                // Navigate to next screen
                Navigator.of(context).pushNamed('/home');
              });
            }
            
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Form fields
                  TextField(
                    onChanged: (value) {
                      context.read<QuicFormBloc>().add(
                        FormFieldChangedEvent('email', value),
                      );
                    },
                  ),
                  // Submit button
                  ElevatedButton(
                    onPressed: () {
                      context.read<QuicFormBloc>().add(
                        const FormSubmitEvent(),
                      );
                    },
                    child: const Text('Register'),
                  ),
                  // Show errors
                  if (state is FormInvalid)
                    ...state.errors.entries.map((e) =>
                      Text('${e.key}: ${e.value.join(', ')}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
```

---

### 3. Dynamic List from API

**JSON:**
```json
{
  "type": "scaffold",
  "appBar": {
    "type": "appbar",
    "title": "Products"
  },
  "body": {
    "type": "listview",
    "dataSource": "${products}",
    "itemBuilder": {
      "type": "container",
      "properties": {
        "margin": "8",
        "padding": "12",
        "backgroundColor": "#F3F4F6",
        "borderRadius": "8"
      },
      "child": {
        "type": "column",
        "children": [
          {
            "type": "text",
            "properties": {
              "text": "${item.name}",
              "fontSize": 16,
              "fontWeight": "bold"
            }
          },
          {
            "type": "text",
            "properties": {
              "text": "$${item.price}",
              "fontSize": 14,
              "color": "#6366F1"
            }
          }
        ]
      },
      "onTap": {
        "type": "navigate",
        "route": "/products/${item.id}"
      }
    }
  }
}
```

**Dart:**
```dart
class ProductListScreen extends StatefulWidget {
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<Product>> _products;

  @override
  void initState() {
    super.initState();
    _products = fetchProducts();
  }

  Future<List<Product>> fetchProducts() async {
    final response = await http.get(
      Uri.parse('https://api.example.com/products'),
    );
    // Parse and cache response
  }

  @override
  Widget build(BuildContext context) {
    return QuicUIScreen(
      jsonData: listJson,
      globalState: {
        'products': _products,
      },
    );
  }
}
```

---

### 4. Conditional UI Based on User State

**JSON:**
```json
{
  "type": "column",
  "children": [
    {
      "type": "conditional",
      "conditions": [
        {
          "condition": "${isLoggedIn}",
          "widget": {
            "type": "column",
            "children": [
              {
                "type": "text",
                "properties": {
                  "text": "Welcome, ${userName}!",
                  "fontSize": 18
                }
              },
              {
                "type": "button",
                "properties": {
                  "label": "Logout"
                },
                "onPressed": {
                  "type": "custom",
                  "handler": "logout"
                }
              }
            ]
          }
        }
      ],
      "defaultWidget": {
        "type": "button",
        "properties": {
          "label": "Login",
          "backgroundColor": "#6366F1"
        },
        "onPressed": {
          "type": "navigate",
          "route": "/login"
        }
      }
    }
  ]
}
```

**Dart:**
```dart
class ConditionalScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<QuicState>(
      builder: (context, state, child) {
        return QuicUIScreen(
          jsonData: conditionalJson,
          globalState: {
            'isLoggedIn': state.get('isLoggedIn') ?? false,
            'userName': state.get('userName') ?? 'Guest',
          },
          onAction: (action) {
            if (action.handler == 'logout') {
              state.set('isLoggedIn', false);
              state.set('userName', null);
            }
          },
        );
      },
    );
  }
}
```

---

### 5. Dynamic Theming

**JSON Theme:**
```json
{
  "type": "theme",
  "colors": {
    "primary": "#6366F1",
    "secondary": "#EC4899",
    "background": "#FFFFFF",
    "surface": "#F3F4F6",
    "error": "#EF4444",
    "success": "#10B981",
    "warning": "#F59E0B"
  },
  "typography": {
    "headingLarge": {
      "fontSize": 32,
      "fontWeight": "bold",
      "letterSpacing": 0.5
    },
    "headingMedium": {
      "fontSize": 24,
      "fontWeight": "bold"
    },
    "bodyMedium": {
      "fontSize": 14,
      "fontWeight": "regular"
    },
    "labelSmall": {
      "fontSize": 12,
      "fontWeight": "medium"
    }
  },
  "spacing": {
    "xs": 4,
    "sm": 8,
    "md": 16,
    "lg": 24,
    "xl": 32
  }
}
```

**Dart:**
```dart
class ThemingSwitchScreen extends StatefulWidget {
  @override
  State<ThemingSwitchScreen> createState() => _ThemingSwitchScreenState();
}

class _ThemingSwitchScreenState extends State<ThemingSwitchScreen> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          theme: buildThemeData(themeManager.theme),
          home: QuicUIScreen(
            jsonData: screenJson,
          ),
        );
      },
    );
  }
}
```

---

## 🔧 Setup & Initialization

### Full App Setup

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quicui/quicui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize QuicUI
  await QuicUIManager.initialize(
    databasePath: null, // Uses default
    enableLogging: true,
    cacheDuration: Duration(hours: 1),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // State management
        ChangeNotifierProvider(create: (_) => QuicState()),
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        
        // API client
        Provider(create: (_) => ApiClient()),
      ],
      child: MaterialApp(
        title: 'QuicUI App',
        theme: ThemeData(useMaterial3: true),
        home: HomeScreen(),
        onGenerateRoute: (settings) => _buildRoute(settings),
      ),
    );
  }

  Route _buildRoute(RouteSettings settings) {
    // Handle dynamic route generation
    return MaterialPageRoute(
      builder: (_) => QuicUIScreen(
        screenId: settings.name,
      ),
    );
  }
}
```

---

## 📊 State Management Example

```dart
// Listen to state changes
class StateExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<QuicState>(
      builder: (context, state, child) {
        return Column(
          children: [
            Text('Counter: ${state.get("counter")}'),
            ElevatedButton(
              onPressed: () {
                final current = state.get("counter") ?? 0;
                state.set("counter", current + 1);
              },
              child: Text('Increment'),
            ),
          ],
        );
      },
    );
  }
}
```

---

## 🗄️ Local Data Caching

```dart
// Cache UI response
await QuicUIManager.cache('home_screen', homeScreenJson);

// Retrieve from cache
final cached = await QuicUIManager.getCache('home_screen');

// Clear cache
await QuicUIManager.clearCache('home_screen');

// Cache with TTL
await QuicUIManager.cache(
  'products',
  productsJson,
  ttl: Duration(hours: 1),
);
```

---

## 🧪 Testing

### Unit Test Example

```dart
void main() {
  group('QuicUI Parser Tests', () {
    test('Parse simple widget', () {
      final json = '{"type":"text","properties":{"text":"Hello"}}';
      final widget = QuicWidget.fromJson(jsonDecode(json));
      
      expect(widget.type, equals('text'));
      expect(widget.properties['text'], equals('Hello'));
    });

    test('Validate schema', () {
      final validator = SchemaValidator();
      final valid = validator.validate({'type': 'text', 'properties': {}});
      
      expect(valid, isTrue);
    });
  });
}
```

### Widget Test Example

```dart
void main() {
  group('QuicUI Widget Tests', () {
    testWidgets('Render QuicText', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuicText(text: 'Hello'),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });
  });
}
```

---

## 🚀 Performance Tips

1. **Use JSON caching** for frequently accessed screens
2. **Lazy load images** with cached_network_image
3. **Batch API requests** to reduce network calls
4. **Enable offline mode** with local storage
5. **Use const widgets** for static content
6. **Implement pagination** for large lists

---

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| iOS | ✅ Full | iOS 11.0+ |
| Android | ✅ Full | Android 5.0+ |
| Web | ✅ Full | All modern browsers |
| Windows | ✅ Full | Windows 10+ |
| macOS | ✅ Full | macOS 10.13+ |
| Linux | ✅ Full | Ubuntu 18.04+ |

---

## 📖 Additional Resources

- [Full API Documentation](./API.md)
- [Architecture Guide](./ARCHITECTURE.md)
- [Implementation Plan](./IMPLEMENTATION_PLAN.md)
- [JSON Schema Reference](./SCHEMA_REFERENCE.md)
- [Examples Repository](./example/)

---

## 🆘 Troubleshooting

### Issue: Widgets not rendering

**Solution:** Verify JSON schema is valid and widget type is registered.

```dart
// Debug: Enable logging
QuicUIManager.enableDebugLogging();

// Check registered widgets
print(WidgetRegistry.registeredTypes);
```

### Issue: State not updating

**Solution:** Ensure you're using `Consumer` or `Provider.of` with `listen: true`.

```dart
// Correct
Consumer<QuicState>(
  builder: (context, state, child) {
    return Text(state.get('value'));
  },
)

// Wrong
Provider.of<QuicState>(context, listen: false) // Won't update UI
```

### Issue: Cache not persisting

**Solution:** Initialize ObjectBox before using cache.

```dart
await QuicUIManager.initialize(); // Must be called first
```

---

## 📞 Support

- 💬 [Discord Community](https://discord.com/invite/quicui)
- 📧 Email: support@quicui.dev
- 🐛 [Report Issues](https://github.com/yourusername/quicui/issues)

---

*Last Updated: October 30, 2025*
*Version: 0.0.1*
