# Quick Start Guide: Initialize QuicUI with Backend Plugins

Get QuicUI running in your Flutter app in 5 minutes. QuicUI uses a backend-agnostic plugin architecture - choose your backend and initialize.

**What you'll learn:**
- 🚀 Basic QuicUI initialization
- 🔌 Choosing a backend plugin
- 📱 Fetching and displaying screens
- 🧪 Testing with mock backends

**Time required:** 5-10 minutes  
**Prerequisites:** Flutter project, backend credentials (Supabase, Firebase, or custom)

---

## Installation

### 1. Add QuicUI Core

```bash
flutter pub add quicui
```

### 2. Choose Your Backend Plugin

**Option A: Supabase Backend**
```bash
flutter pub add quicui_supabase
```

**Option B: Firebase Backend**
```bash
flutter pub add quicui_firebase
```

**Option C: REST API Backend**
```bash
flutter pub add quicui_rest
```

**Option D: Custom Backend**
See [Backend Integration Guide](BACKEND_INTEGRATION.md) to implement your own DataSource.

---

## 5-Minute Quickstart

### Step 1: Import Required Packages

```dart
import 'package:flutter/material.dart';
import 'package:quicui/quicui.dart';
import 'package:quicui_supabase/quicui_supabase.dart';  // or your chosen backend
```

### Step 2: Initialize in main()

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create your backend plugin
  final dataSource = SupabaseDataSource(
    'https://your-project.supabase.co',
    'your-anon-key',
  );
  
  // Initialize QuicUI with the plugin
  await QuicUIService().initializeWithDataSource(dataSource);
  
  runApp(const MyApp());
}
```

### Step 3: Fetch and Display Screens

```dart
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ScreenDisplay(),
    );
  }
}

class ScreenDisplay extends StatefulWidget {
  const ScreenDisplay({Key? key}) : super(key: key);

  @override
  State<ScreenDisplay> createState() => _ScreenDisplayState();
}

class _ScreenDisplayState extends State<ScreenDisplay> {
  late Future<dynamic> screenFuture;

  @override
  void initState() {
    super.initState();
    screenFuture = QuicUIService().fetchScreen('home-screen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QuicUI Screen')),
      body: FutureBuilder(
        future: screenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final screen = snapshot.data;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(screen.toString()),  // Render screen content
            ),
          );
        },
      ),
    );
  }
}
```

That's it! Your app is now running QuicUI with a backend plugin. ✅

---

## Backend Setup

### Supabase Backend

**Prerequisites:** Supabase project, table with screen data

```dart
import 'package:quicui_supabase/quicui_supabase.dart';

final dataSource = SupabaseDataSource(
  supabaseUrl: 'https://your-project.supabase.co',
  supabaseAnonKey: 'your-anon-key',
);

await QuicUIService().initializeWithDataSource(dataSource);
```

**Configuration:** See [Supabase Integration](BACKEND_INTEGRATION.md#supabase) for table schema.

---

### Firebase Backend

**Prerequisites:** Firebase project, Firestore collection with screen data

```dart
import 'package:quicui_firebase/quicui_firebase.dart';

final dataSource = FirebaseDataSource(
  projectId: 'your-firebase-project',
  // Optional: custom configuration
);

await QuicUIService().initializeWithDataSource(dataSource);
```

**Configuration:** See [Firebase Integration](BACKEND_INTEGRATION.md#firebase) for collection structure.

---

### REST API Backend

**Prerequisites:** REST API endpoint returning screen data

```dart
import 'package:quicui_rest/quicui_rest.dart';

final dataSource = RestApiDataSource(
  baseUrl: 'https://api.example.com',
  apiKey: 'your-api-key',
);

await QuicUIService().initializeWithDataSource(dataSource);
```

**Configuration:** See [REST API Integration](BACKEND_INTEGRATION.md#rest-api) for endpoint requirements.

---

### Custom Backend

**For proprietary or specialized systems:**

```dart
import 'package:quicui/quicui.dart';

class MyCustomDataSource extends DataSource {
  @override
  Future<dynamic> fetchScreen(String screenId) async {
    // Your custom implementation
  }

  @override
  Future<dynamic> fetchData(String dataId) async {
    // Your custom implementation
  }

  // ... implement other required methods
}

final dataSource = MyCustomDataSource();
await QuicUIService().initializeWithDataSource(dataSource);
```

See [Custom Backend Integration](BACKEND_INTEGRATION.md#custom-backend) for complete DataSource interface.

---

## Common Setups

### Setup 1: Simple App with Supabase

Most common starting point - Supabase as backend.

**main.dart:**
```dart
import 'package:flutter/material.dart';
import 'package:quicui/quicui.dart';
import 'package:quicui_supabase/quicui_supabase.dart';

const SUPABASE_URL = 'https://xyzabc.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dataSource = SupabaseDataSource(SUPABASE_URL, SUPABASE_KEY);
  await QuicUIService().initializeWithDataSource(dataSource);
  
  runApp(const MyApp());
}
```

### Setup 2: Environment-Specific Configuration

Different backends for dev/staging/prod environments.

**config.dart:**
```dart
class Config {
  static const prod = _ProdConfig();
  static const staging = _StagingConfig();
  static const dev = _DevConfig();
}

abstract class _BaseConfig {
  String get supabaseUrl;
  String get supabaseKey;
  
  DataSource createDataSource() => SupabaseDataSource(supabaseUrl, supabaseKey);
}

class _ProdConfig extends _BaseConfig {
  const _ProdConfig();
  
  @override
  String get supabaseUrl => 'https://prod.supabase.co';
  @override
  String get supabaseKey => 'prod-key';
}

class _StagingConfig extends _BaseConfig {
  const _StagingConfig();
  
  @override
  String get supabaseUrl => 'https://staging.supabase.co';
  @override
  String get supabaseKey => 'staging-key';
}

class _DevConfig extends _BaseConfig {
  const _DevConfig();
  
  @override
  String get supabaseUrl => 'https://dev.supabase.co';
  @override
  String get supabaseKey => 'dev-key';
}
```

**main.dart:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use environment-specific config
  const environment = String.fromEnvironment('ENV', defaultValue: 'dev');
  final config = environment == 'prod' 
      ? Config.prod
      : environment == 'staging'
          ? Config.staging
          : Config.dev;
  
  await QuicUIService().initializeWithDataSource(config.createDataSource());
  
  runApp(const MyApp());
}
```

### Setup 3: Testing with Mock Backend

Write tests without external dependencies.

**test/screens_test.dart:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quicui/quicui.dart';

class MockDataSource extends Mock implements DataSource {}

void main() {
  test('Screen fetching works correctly', () async {
    final mockDataSource = MockDataSource();
    
    // Mock the behavior
    when(() => mockDataSource.fetchScreen('home'))
        .thenAnswer((_) async => {'id': 'home', 'title': 'Home'});
    
    // Initialize with mock
    await QuicUIService().initializeWithDataSource(mockDataSource);
    
    // Test
    final screen = await QuicUIService().fetchScreen('home');
    expect(screen['title'], equals('Home'));
  });
}
```

### Setup 4: Multi-Backend Support

Switch backends based on feature flags or user preferences.

**backend_manager.dart:**
```dart
enum BackendType { supabase, firebase, restApi }

class BackendManager {
  static DataSource createDataSource(BackendType type) {
    switch (type) {
      case BackendType.supabase:
        return SupabaseDataSource(
          'https://xyzabc.supabase.co',
          'anon-key',
        );
      case BackendType.firebase:
        return FirebaseDataSource(projectId: 'my-project');
      case BackendType.restApi:
        return RestApiDataSource(baseUrl: 'https://api.example.com');
    }
  }
}
```

**main.dart:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Determine backend based on config or feature flag
  final backendType = getBackendFromConfig();
  final dataSource = BackendManager.createDataSource(backendType);
  
  await QuicUIService().initializeWithDataSource(dataSource);
  runApp(const MyApp());
}
```

---

## Common Tasks

### Fetch a Single Screen

```dart
try {
  final screen = await QuicUIService().fetchScreen('screen-id');
  print('Screen fetched: $screen');
} catch (e) {
  print('Error: $e');
}
```

### Fetch Multiple Screens

```dart
Future<List<dynamic>> fetchMultipleScreens(List<String> ids) async {
  final futures = ids.map((id) => QuicUIService().fetchScreen(id));
  return await Future.wait(futures);
}

// Usage
final screens = await fetchMultipleScreens(['home', 'profile', 'settings']);
```

### Subscribe to Real-Time Updates

```dart
// Get the active DataSource
final dataSource = DataSourceProvider.instance.get();

// Subscribe to changes
final stream = dataSource.subscribeToScreen('screen-id');
stream.listen((screen) {
  print('Screen updated: $screen');
});
```

### Handle Initialization Errors

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    final dataSource = SupabaseDataSource(url, key);
    await QuicUIService().initializeWithDataSource(dataSource);
  } on SupabaseException catch (e) {
    print('Supabase error: ${e.message}');
    // Handle Supabase-specific errors
  } on DataSourceException catch (e) {
    print('DataSource error: ${e.message}');
    // Handle DataSource errors
  } catch (e) {
    print('Unexpected error: $e');
    // Handle other errors
  }
}
```

---

## Troubleshooting

### "DataSourceProvider is null"
**Cause:** Tried to use QuicUIService before initialization  
**Solution:** Always call `initializeWithDataSource()` in `main()` before `runApp()`

```dart
// ✓ Correct
await QuicUIService().initializeWithDataSource(dataSource);
runApp(const MyApp());

// ✗ Wrong - forgot initialization
runApp(const MyApp());
```

### "fetchScreen failed"
**Cause:** Connection error or invalid screen ID  
**Solution:** Verify credentials and screen ID in your backend

```dart
// Debug: Check if backend is accessible
try {
  final screen = await QuicUIService().fetchScreen('test-screen');
} catch (e) {
  print('Debug: $e');
  // Check credentials, network, and screen ID
}
```

### "Import not found"
**Cause:** Didn't install backend plugin  
**Solution:** Install the plugin for your chosen backend

```bash
# For Supabase
flutter pub add quicui_supabase

# For Firebase
flutter pub add quicui_firebase

# For REST API
flutter pub add quicui_rest
```

### "Performance is slow"
**Cause:** Network latency or large screen data  
**Solution:** See [Performance Guide](PERFORMANCE.md) for optimization tips

---

## Next Steps

1. **Explore Your Backend**
   - Review [Backend Integration Guide](BACKEND_INTEGRATION.md)
   - Learn about your chosen backend's data structure

2. **Learn Architecture**
   - Study [Plugin Architecture](PLUGIN_ARCHITECTURE.md)
   - Understand how backends are abstracted

3. **Advanced Usage**
   - Check [API Reference](API_REFERENCE.md) for detailed method docs
   - Implement custom error handling and logging

4. **Optimize Performance**
   - See [Performance Guide](PERFORMANCE.md)
   - Implement caching and pagination

5. **Build Custom Backend**
   - Read [Custom Backend Integration](BACKEND_INTEGRATION.md#custom-backend)
   - Implement DataSource for your system

---

## Examples

Complete examples are available in the `examples/` directory:

- `examples/supabase_basic/` - Simple Supabase setup
- `examples/firebase_setup/` - Firebase initialization
- `examples/custom_backend/` - Custom DataSource implementation
- `examples/testing/` - Mock backend for tests

See [Examples README](../examples/README.md) for detailed walkthrough.

---

## Support

- 📖 **API Reference:** [API_REFERENCE.md](API_REFERENCE.md)
- 🏗️ **Architecture:** [PLUGIN_ARCHITECTURE.md](PLUGIN_ARCHITECTURE.md)
- 🔌 **Backends:** [BACKEND_INTEGRATION.md](BACKEND_INTEGRATION.md)
- 💨 **Performance:** [PERFORMANCE.md](PERFORMANCE.md)
- 🧪 **Testing:** [TESTING.md](TESTING.md)

---

## Summary

QuicUI is ready to use in 3 steps:

1. **Choose backend** (Supabase, Firebase, REST, or custom)
2. **Install plugin** (`flutter pub add quicui_<backend>`)
3. **Initialize** in `main()` with `initializeWithDataSource()`

Your app can now fetch screens with `QuicUIService().fetchScreen(id)`.

**Happy building! 🚀**
