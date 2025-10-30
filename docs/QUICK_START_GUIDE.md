# Quick Start Guide - QuicUI v1.0.3+

Get QuicUI running in your Flutter app in 5 minutes. **Backend is completely optional** - use QuicUI standalone with local JSON data, or add a backend plugin like Supabase.

**What you'll learn:**
- 🚀 Standalone QuicUI (no backend required)
- 🔌 Adding optional backend plugins
- 📱 Fetching and displaying screens
- 🧪 Testing workflows

**Time required:** 5-10 minutes  
**Difficulty:** Beginner

---

## Installation

### Step 1: Add QuicUI Core

```bash
flutter pub add quicui
```

### Step 2 (Optional): Add Backend Plugin

QuicUI works **without any backend**. Add a backend plugin only if you need cloud integration:

**For Supabase backend:**
```bash
flutter pub add quicui_supabase
```

**For Firebase backend (future):**
```bash
flutter pub add quicui_firebase
```

**For custom backend:**
Implement the `DataSource` interface. See [Backend Integration Guide](BACKEND_INTEGRATION.md).

---

## Mode 1: Standalone (No Backend)

### Recommended For:
- ✅ Local/offline-first apps
- ✅ Static screens
- ✅ Testing and development
- ✅ Apps that don't need cloud sync

### Basic Setup

```dart
import 'package:flutter/material.dart';
import 'package:quicui/quicui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StandaloneScreen(),
    );
  }
}

class StandaloneScreen extends StatelessWidget {
  const StandaloneScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define UI as local JSON - no backend needed!
    final screenJson = {
      'type': 'scaffold',
      'appBar': {
        'type': 'appbar',
        'title': 'QuicUI Offline',
      },
      'body': {
        'type': 'center',
        'child': {
          'type': 'column',
          'mainAxisAlignment': 'center',
          'children': [
            {
              'type': 'text',
              'properties': {
                'text': 'Hello from QuicUI!',
                'fontSize': 24,
                'fontWeight': 'bold',
              },
            },
            {
              'type': 'sizedBox',
              'properties': {'height': 16},
            },
            {
              'type': 'text',
              'properties': {
                'text': 'No backend required',
                'fontSize': 16,
              },
            },
          ],
        },
      },
    };

    // Render the screen
    final screen = Screen.fromJson(screenJson);
    final renderer = UIRenderer();
    return renderer.renderScreen(screen);
  }
}
```

**That's it!** No backend, no configuration, no internet required.

---

## Mode 2: With Backend Plugin (Optional)

### Recommended For:
- ✅ Real-time UI updates
- ✅ Dynamic screen management
- ✅ Multi-device sync
- ✅ Collaborative features

### Setup with Supabase

```dart
import 'package:flutter/material.dart';
import 'package:quicui/quicui.dart';
import 'package:quicui_supabase/quicui_supabase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create your backend plugin
  final dataSource = SupabaseDataSource(
    'https://your-project.supabase.co',
    'your-anon-key',
  );
  
  // Connect to backend
  await dataSource.connect();
  
  // Register with QuicUI (optional - for dependency injection)
  DataSourceProvider.instance.register(dataSource);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BackendScreen(),
    );
  }
}

class BackendScreen extends StatefulWidget {
  const BackendScreen({Key? key}) : super(key: key);

  @override
  State<BackendScreen> createState() => _BackendScreenState();
}

class _BackendScreenState extends State<BackendScreen> {
  late Future<Screen> screenFuture;

  @override
  void initState() {
    super.initState();
    final dataSource = DataSourceProvider.instance.get();
    screenFuture = dataSource.fetchScreen('home_screen');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Screen>(
      future: screenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (snapshot.hasData) {
          final screen = snapshot.data!;
          final renderer = UIRenderer();
          return renderer.renderScreen(screen);
        }

        return const Scaffold(
          body: Center(child: Text('No screen found')),
        );
      },
    );
  }
}
```

---

## JSON Schema Reference

### Minimal Widget

The **only required field** is `type`. Everything else is optional:

```json
{
  "type": "text",
  "properties": {
    "text": "Hello World"
  }
}
```

### Widget With Optional ID

The `id` field is **optional** - use it only if you need to reference the widget:

```json
{
  "id": "greeting_text",
  "type": "text",
  "properties": {
    "text": "Hello World"
  }
}
```

### Complete Widget Example

```json
{
  "id": "submit_button",
  "type": "button",
  "properties": {
    "label": "Submit",
    "backgroundColor": "#2196F3"
  },
  "events": {
    "onPressed": {
      "action": "submitForm",
      "formId": "contact_form"
    }
  }
}
```

### Common Widget Types

```json
{
  "type": "scaffold",
  "appBar": {
    "type": "appbar",
    "title": "My App"
  },
  "body": {
    "type": "column",
    "mainAxisAlignment": "start",
    "crossAxisAlignment": "center",
    "children": [
      {
        "type": "text",
        "properties": {
          "text": "Title",
          "fontSize": 24,
          "fontWeight": "bold"
        }
      },
      {
        "type": "textfield",
        "properties": {
          "hint": "Enter text",
          "label": "Input"
        }
      },
      {
        "type": "button",
        "properties": {
          "label": "Click Me"
        },
        "events": {
          "onPressed": {
            "action": "navigate",
            "screen": "detail_screen"
          }
        }
      }
    ]
  }
}
```

---

## Supported Widget Types

### Layout Widgets
- `scaffold` - Full screen with AppBar, body, drawer
- `appbar` - Top app bar
- `column` - Vertical layout
- `row` - Horizontal layout
- `center` - Center content
- `container` - Container with decoration
- `padding` - Add padding
- `sizedbox` - Fixed size box
- `expanded` - Flexible expansion
- `listview` - Scrollable list
- `gridview` - Grid layout
- `stack` - Overlay widgets

### Input Widgets
- `textfield` - Text input
- `checkbox` - Checkbox
- `radiobutton` - Radio button
- `dropdownbutton` - Dropdown menu
- `switch` - Toggle switch

### Display Widgets
- `text` - Static text
- `richtext` - Rich formatted text
- `image` - Display image
- `icon` - Display icon
- `card` - Material card
- `listtile` - List item
- `badge` - Badge display
- `divider` - Divider

### Button Widgets
- `button` - Standard button
- `elevatedbutton` - Elevated button
- `floatingactionbutton` - FAB
- `iconbutton` - Icon button

---

## Common Tasks

### Add State Binding

Bind widget properties to application state:

```json
{
  "type": "text",
  "properties": {
    "text": "${state.userName}"
  }
}
```

### Add Event Handlers

Handle user interactions:

```json
{
  "type": "button",
  "properties": {"label": "Save"},
  "events": {
    "onPressed": {
      "action": "submitForm",
      "formId": "user_form"
    }
  }
}
```

### Conditional Rendering

Show widget only if condition is met:

```json
{
  "type": "text",
  "properties": {"text": "Premium Feature"},
  "condition": {
    "type": "equals",
    "value": true
  }
}
```

### Add Children to Layout

Layout widgets can have children:

```json
{
  "type": "column",
  "children": [
    {
      "type": "text",
      "properties": {"text": "Child 1"}
    },
    {
      "type": "text",
      "properties": {"text": "Child 2"}
    }
  ]
}
```

---

## Testing

### Test Standalone Screens

```dart
test('Render text widget', () {
  final json = {
    'type': 'text',
    'properties': {'text': 'Hello'},
  };
  
  final widget = WidgetData.fromJson(json);
  expect(widget.type, equals('text'));
  expect(widget.properties['text'], equals('Hello'));
});
```

### Test with Backend Mock

```dart
test('Fetch screen from mock backend', () async {
  final mockDataSource = MockDataSource();
  DataSourceProvider.instance.register(mockDataSource);
  
  final screen = await mockDataSource.fetchScreen('test_screen');
  expect(screen.id, equals('test_screen'));
});
```

---

## Next Steps

- 📖 Read [Backend Integration Guide](BACKEND_INTEGRATION.md) to add backend support
- 🔌 Check [Plugin Architecture](PLUGIN_ARCHITECTURE.md) to build custom backends
- 📚 Explore [API Reference](API_REFERENCE.md) for all available methods
- 🧪 See `examples/` directory for complete working apps

---

## Troubleshooting

### Widgets not rendering?
- Verify widget `type` is supported (see list above)
- Check that `properties` is a valid map
- Ensure children use `List<WidgetData>` type

### Backend not connecting?
- Verify credentials are correct
- Check internet connection
- Review backend-specific setup in the plugin README

### State not updating?
- Ensure state binding uses correct `${field}` syntax
- Verify state field names match backend schema

---

## Resources

- **GitHub:** https://github.com/Ikolvi/QuicUI
- **Pub.dev:** https://pub.dev/packages/quicui
- **Issues:** https://github.com/Ikolvi/QuicUI/issues
- **Supabase Plugin:** https://pub.dev/packages/quicui_supabase
